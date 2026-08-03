import 'dart:io';

import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/utils/budget_status.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/categories/widgets/category_card.dart';
import 'package:budget_buddy/modules/category_form/category_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:budget_buddy/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// BUG-001 — a limit of 0 is F-09's "No limit" state, and users could not reach
/// it.
///
/// The category form validated its budget field with `Validators.amount`, whose
/// rule is `> 0`, so typing 0 turned the field red ("Enter a valid amount") and
/// emptying it said "Amount is required". The only 0-limit category that could
/// exist was therefore the system's own Uncategorised bucket: a rendering path
/// with no way in, while F-09's spec table lists "No limit" as one of four
/// first-class states.
///
/// The three things that had to change together — what the field accepts, what
/// the write accepts, and that the row then renders as No-limit — are the three
/// groups below. Transaction amounts are checked here too, because they must NOT
/// have moved: a ₨0 expense is still nothing to log.
void main() {
  final usd = CurrencyUtils.usd;
  final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');
  final jpy = CurrencyUtils.currencies.firstWhere((c) => c.code == 'JPY');

  group('the limit field accepts an explicit zero', () {
    test('0 is a value; blank is still a mistake', () {
      final validate = Validators.budgetLimit(usd);
      expect(validate('0'), isNull, reason: 'this IS the No-limit state');
      expect(validate('0.00'), isNull);
      expect(validate('7500'), isNull);
      expect(validate('1,234.56'), isNull);

      expect(validate(''), 'Amount is required',
          reason: 'an empty field is an omission, not a decision');
      expect(validate(null), 'Amount is required');
      expect(validate('-5'), 'Enter a valid amount');
      expect(validate('abc'), 'Enter a valid amount');
      expect(validate('12.345'), 'Use at most 2 decimal places');
    });

    test('still currency-aware: a zero-decimal currency refuses decimals', () {
      expect(Validators.budgetLimit(jpy)('0'), isNull);
      expect(Validators.budgetLimit(jpy)('12.5'),
          'JPY amounts have no decimal places');
    });

    test('transaction amounts are untouched — 0 is still refused there', () {
      // The two fields mean different things: a limit of 0 says "do not budget
      // this", a transaction of 0 says nothing at all.
      expect(Validators.amount(usd)('0'), 'Enter a valid amount');
      expect(Validators.amount(usd)('0.00'), 'Enter a valid amount');
      expect(Validators.amount(usd)('0.01'), isNull);
    });
  });

  group('the save path stores it', () {
    late Directory tempDir;
    late CategoryRepository categories;
    late SettingsService settings;

    final thisMonth = AppDateUtils.getCurrentMonthKey();

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_zerolimit');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      categories = Get.put(CategoryRepository());
      settings = Get.put(SettingsService());
      await settings.setCurrency('PKR', '₨');
      await settings.setCurrentMonth(thisMonth);
      // Get.testMode covers the contextless Get.back() at the end of save().
      Get.testMode = true;
    });

    tearDown(() async {
      Get.testMode = false;
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// A form controller with its category stream settled. [editing] stands in
    /// for the route argument the Categories tab passes.
    Future<CategoryFormController> openForm({Category? editing}) async {
      if (Get.isRegistered<CategoryFormController>()) {
        Get.delete<CategoryFormController>();
      }
      final ctrl =
          CategoryFormController(categoryRepo: categories, settings: settings);
      if (editing != null) {
        ctrl.editingCategory = editing;
        ctrl.nameController.text = editing.name;
        ctrl.budgetController.text = CurrencyUtils.formatForInput(
            editing.budgetLimitMinor, settings.currency);
      }
      Get.put(ctrl);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ctrl;
    }

    test('a new category can be created with no limit', () async {
      final ctrl = await openForm();
      ctrl.nameController.text = 'Gifts';
      ctrl.budgetController.text = '0';
      await ctrl.save();

      final stored = Get.find<LocalStoreService>().readCategories();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'Gifts');
      expect(stored.single.budgetLimitMinor, 0);
    });

    test('an existing limit can be edited down to no limit', () async {
      final education = Category(
        id: 'education',
        name: 'Education',
        budgetLimitMinor: 750000, // ₨7,500 — danish's repro
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.school.codePoint,
        month: thisMonth,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await categories.addCategory(education);

      final ctrl = await openForm(editing: education);
      expect(ctrl.budgetController.text, '7500', reason: 'prefill unchanged');
      ctrl.budgetController.text = '0';
      await ctrl.save();

      final stored = Get.find<LocalStoreService>().readCategories();
      expect(stored.single.budgetLimitMinor, 0);
      expect(stored.single.id, 'education', reason: 'edited, not replaced');
    });

    test('an empty field still writes nothing', () async {
      final ctrl = await openForm();
      ctrl.nameController.text = 'Gifts';
      ctrl.budgetController.text = '   ';
      await ctrl.save();

      expect(Get.find<LocalStoreService>().readCategories(), isEmpty);
    });

    test('a negative limit still writes nothing', () async {
      final ctrl = await openForm();
      ctrl.nameController.text = 'Gifts';
      ctrl.budgetController.text = '-100';
      await ctrl.save();

      expect(Get.find<LocalStoreService>().readCategories(), isEmpty);
    });
  });

  group('and the row renders as F-09 No-limit', () {
    testWidgets('a USER category with limit 0: no bar, muted "No limit set"',
        (tester) async {
      // The state was always reachable for the reserved bucket. What BUG-001
      // was about is this row: an ordinary category the user made.
      final gifts = Category(
        id: 'gifts',
        name: 'Gifts',
        budgetLimitMinor: 0,
        colorValue: 0xFF6B7F4E,
        month: '2026-08',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: CategoryCard(
            category: gifts,
            spentMinor: 45000, // ₨450 spent against no budget
            currency: pkr,
            onTap: () {},
            onEdit: () {},
          ),
        ),
      ));

      expect(find.text('No limit set'), findsOneWidget);
      expect(tester.widget<Text>(find.text('No limit set')).style!.color,
          AppSemanticColors.light.textMuted);
      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'zero of zero must not render as a full rail');
      // Spending against no budget is never "over budget" (F-09).
      expect(
          BudgetStatus.of(spentMinor: 45000, limitMinor: 0).state,
          BudgetState.noLimit);
    });
  });
}
