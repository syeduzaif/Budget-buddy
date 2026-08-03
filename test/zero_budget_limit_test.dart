import 'dart:io';

import 'package:budget_buddy/core/theme/app_fonts.dart';
import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/utils/budget_status.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/categories/widgets/category_card.dart';
import 'package:budget_buddy/modules/category_form/category_form_controller.dart';
import 'package:budget_buddy/modules/category_form/category_form_view.dart';
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

  group('the form says what 0 means (discoverability, palwasha 2026-08-03)', () {
    late Directory tempDir;
    late SettingsService settings;

    final thisMonth = AppDateUtils.getCurrentMonthKey();

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_helper');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      settings = Get.put(SettingsService());
      await settings.setCurrency('PKR', '₨');
      await settings.setCurrentMonth(thisMonth);
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// The form as it is reached from the app: `Get.to` with the category as the
    /// route argument is what puts it in edit mode (onInit reads Get.arguments).
    Future<void> pumpForm(
      WidgetTester tester, {
      Category? editing,
      ThemeData? theme,
    }) async {
      // `GetMaterialApp` takes no `themeAnimationDuration`, so the theme lerp is
      // settled the honest way: every pump below ends in `pumpAndSettle`, which
      // is what stops a second pump in one test from reading the previous theme
      // mid-lerp.
      await tester.pumpWidget(GetMaterialApp(
        theme: theme ?? AppTheme.light,
        home: const Scaffold(body: Center(child: Text('home'))),
      ));
      Get.to(() => const CategoryFormView(), arguments: editing);
      await tester.pumpAndSettle();
    }

    const helper = 'Enter 0 for no limit';

    testWidgets('the NEW category form carries the copy, verbatim',
        (tester) async {
      await pumpForm(tester);

      expect(find.text('New Category'), findsOneWidget);
      expect(find.text(helper), findsOneWidget,
          reason: 'a first-time user gets no signal that 0 means anything at '
              'all without it (danish, BUG-001 discoverability)');
    });

    testWidgets('so does the EDIT form — one widget, both routes',
        (tester) async {
      final education = Category(
        id: 'education',
        name: 'Education',
        budgetLimitMinor: 750000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.school.codePoint,
        month: thisMonth,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      // Not written to the store first: edit mode comes from the route
      // argument, and a real Hive write inside `testWidgets` awaits real I/O
      // under a fake clock, which never completes.
      await pumpForm(tester, editing: education);

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.text(helper), findsOneWidget,
          reason: '"Enter" rather than "Leave" is chosen for exactly this '
              'form, where the field arrives populated');
    });

    testWidgets('muted caption, in whichever theme it renders', (tester) async {
      await pumpForm(tester);
      var line = tester.widget<Text>(find.text(helper));
      expect(line.style?.color, AppSemanticColors.light.textMuted);
      expect(line.style?.fontSize, AppFonts.caption.fontSize,
          reason: 'the same voice as the card\'s "No limit set" caption');
      expect(line.maxLines, 1);

      await pumpForm(tester, theme: AppTheme.dark);
      line = tester.widget<Text>(find.text(helper));
      expect(line.style?.color, AppSemanticColors.dark.textMuted,
          reason: 'muted has two values; the accessor picks per brightness');
    });

    testWidgets('an error REPLACES the helper and moves nothing',
        (tester) async {
      await pumpForm(tester);
      // A valid name, so the only field that can fail is the limit — otherwise
      // the name\'s own error line moves everything below it anyway.
      Get.find<CategoryFormController>().nameController.text = 'Gifts';
      await tester.pump();

      // The section header directly under the limit field: it moves if and only
      // if that field changed height. Read through the Form rather than tapping
      // Save, because tapping would scroll the page and move it for real.
      final before = tester.getTopLeft(find.text('Pick an Icon')).dy;
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isFalse, reason: 'blank limit is still refused');
      // Settled, not a single pump: Material cross-fades the two lines, so
      // mid-animation BOTH Texts are in the tree — the replacement is what the
      // finished frame shows.
      await tester.pumpAndSettle();

      expect(find.text('Amount is required'), findsOneWidget);
      expect(find.text(helper), findsNothing,
          reason: 'one line of guidance at a time — the errorText takes the '
              'helper\'s slot rather than stacking under it');
      expect(tester.getTopLeft(find.text('Pick an Icon')).dy, before,
          reason: 'the line is permanently reserved: danish measured "Save '
              'Changes" dropping ~20pt when the error appeared');
    });

    test('the transaction Amount field never gets this string', () {
      // 0 is invalid there, and the two fields sharing one mental model is
      // exactly how a user comes to expect ₨0 expenses to be legal (danish).
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('for no limit'))
          .map((f) => f.path)
          .toList();
      expect(offenders,
          ['lib/modules/category_form/category_form_view.dart'.replaceAll('/', Platform.pathSeparator)]);
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
