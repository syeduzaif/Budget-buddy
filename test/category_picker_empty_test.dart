import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-06 AC-D028-1 (D-028) — the category picker says where the money will go
/// when there is nothing to pick.
///
/// Reachable by deleting every category in every month: `ensureMonth` then has
/// nothing to clone from, and the dialog was a title over blank space — a dead
/// end on this app's rank-1 job — while the save path beneath it already
/// handled the case correctly and said so.
///
/// The month name is built here from a literal table rather than from
/// `AppDateUtils.formatMonthName`, deliberately: an assertion that formats the
/// month through the same function the widget uses would pass even if both were
/// wrong.
void main() {
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String nameOfMonth(String monthKey) =>
      monthNames[int.parse(monthKey.split('-')[1]) - 1];

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  String expectedLine(String monthKey) =>
      'No categories in ${nameOfMonth(monthKey)}. '
      'Saving will file this under Uncategorised.';

  late Directory tempDir;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late SettingsService settings;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_picker');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    categories = Get.put(CategoryRepository());
    transactions = Get.put(TransactionRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    // No categories anywhere: the state a user reaches by deleting the last
    // one in every month.
  });

  tearDown(() async {
    Get.testMode = false;
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> openForm(WidgetTester tester) async {
    Get.put(TransactionFormController(
      categoryRepo: categories,
      transactionRepo: transactions,
      settings: settings,
    ));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
          body: SingleChildScrollView(
        child: TransactionFormView(),
      )),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    expect(find.text('Select Category'), findsOneWidget,
        reason: 'the dialog is open');
  }

  group('AC-D028-1 — the empty picker names the month and the destination', () {
    testWidgets('the current month', (tester) async {
      await openForm(tester);
      await openPicker(tester);

      expect(find.text(expectedLine(thisMonth)), findsOneWidget);
    });

    testWidgets('a PAST month — it names the month being viewed',
        (tester) async {
      // Proves the line reads the viewed month rather than hardcoding "this
      // month", which is the shortcut that would look right in every test
      // written on the 1st.
      await tester.runAsync(() async {
        await settings.setCurrentMonth(lastMonth);
      });
      await openForm(tester);
      await openPicker(tester);

      expect(find.text(expectedLine(lastMonth)), findsOneWidget);
      expect(find.text(expectedLine(thisMonth)), findsNothing);
    });

    testWidgets('it uses the reserved bucket\'s own noun', (tester) async {
      // The copy must match what the save path actually says afterwards
      // ("Saved to Uncategorised"), or the app names the same bucket two ways.
      await openForm(tester);
      await openPicker(tester);

      expect(find.textContaining(kUncategorisedCategoryName), findsOneWidget);
    });

    testWidgets('a month WITH categories shows the list, not the line',
        (tester) async {
      // The negative control. A line that renders unconditionally would pass
      // every assertion above.
      await tester.runAsync(() async {
        await categories.addCategory(Category(
          id: 'food',
          name: 'Food',
          budgetLimitMinor: 500000,
          colorValue: 0xFF2D8B8B,
          iconCodePoint: Icons.restaurant.codePoint,
          month: thisMonth,
          createdAt: DateTime(2026, 1, 1, 9),
          updatedAt: DateTime(2026, 1, 1, 9),
        ));
      });
      await openForm(tester);

      await tester.tap(find.text('Food').first);
      await tester.pumpAndSettle();

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.textContaining('No categories in'), findsNothing);
      expect(find.text('Food'), findsWidgets);
    });
  });

  /// The second half of AC-D028-1, and the reason it is a plain `test`: `save()`
  /// awaits real Hive writes, which complete on the real clock and not under
  /// `tester.pump`'s fake one. `Get.testMode` covers the contextless
  /// `Get.back()`; the confirmation snackbar rides a post-frame callback that
  /// never runs here.
  group('AC-D028-1 — saving from the empty picker', () {
    Future<TransactionFormController> openSheet() async {
      final ctrl = Get.put(TransactionFormController(
        categoryRepo: categories,
        transactionRepo: transactions,
        settings: settings,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ctrl;
    }

    test('the transaction lands under Uncategorised, in the viewed month',
        () async {
      Get.testMode = true;
      await settings.setCurrentMonth(lastMonth);
      final ctrl = await openSheet();

      expect(ctrl.selectedCategory.value, isNull,
          reason: 'nothing to preselect — this is the state the new line '
              'describes');

      ctrl.amountController.text = '450';
      await ctrl.save();

      final saved = await transactions.getTransactions().first;
      expect(saved, hasLength(1));

      final all = await categories.getCategories().first;
      final bucket = all.firstWhere((c) => c.id == saved.single.categoryId);
      expect(bucket.name, kUncategorisedCategoryName);
      expect(bucket.month, lastMonth,
          reason: 'the month the line named, not the calendar month');
      expect(AppDateUtils.getMonthKeyFromDate(saved.single.date), lastMonth);
    });
  });
}
