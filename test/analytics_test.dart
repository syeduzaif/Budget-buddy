import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/analytics/analytics_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-03 — the savings rate divides a range's spend by that range's income, and
/// the by-category breakdown counts a category once.
///
/// The reported defect: ₨12,650 spent against ₨150,000/month income showed
/// 91.6% for "This month" AND for "Last 3 months" — range-scoped spend over ONE
/// month's income. Since the period labels landed, the two cards contradict
/// each other on screen, which is how a user catches it.
///
/// The rider: every month holds fresh clones of the user's categories, so a
/// multi-month breakdown grouped by `categoryId` drew the same category as
/// several partial slices. One month of install age hid it; the launch
/// rollover (F-02) guarantees it.
void main() {
  const july = '2026-07';
  const august = '2026-08';

  // The screenshot's numbers, in minor units: ₨150,000.00 income, ₨12,650.00
  // spent.
  const incomeMinor = 15000000;
  const spentMinor = 1265000;

  group('savingsRatePercent — pure arithmetic', () {
    test('AC-1: one month of data reads differently over 1, 3 and 6 months',
        () {
      double rate(int months) => AnalyticsController.savingsRatePercent(
            incomeMinorPerMonth: incomeMinor,
            months: months,
            spentMinor: spentMinor,
          );

      // (150,000 − 12,650) / 150,000 — the figure the app already showed.
      expect(rate(1).toStringAsFixed(1), '91.6');
      // (450,000 − 12,650) / 450,000 — the figure it should have shown.
      expect(rate(3).toStringAsFixed(1), '97.2');
      expect(rate(6).toStringAsFixed(1), '98.6');
      expect({rate(1), rate(3), rate(6)}.length, 3,
          reason: 'three periods, three answers');
    });

    test('AC-2: spending more than the range earns reads 0%, never negative',
        () {
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: 10000, months: 3, spentMinor: 90000),
          0);
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: 10000, months: 1, spentMinor: 10001),
          0);
    });

    test('zero income is 0%, not a division by zero', () {
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: 0, months: 3, spentMinor: 500),
          0);
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: -1, months: 3, spentMinor: 500),
          0);
    });

    test('a range with no spend is 100% in every period', () {
      for (final months in [1, 3, 6]) {
        expect(
            AnalyticsController.savingsRatePercent(
                incomeMinorPerMonth: incomeMinor,
                months: months,
                spentMinor: 0),
            100,
            reason: '$months-month range');
      }
    });

    test('a zero-month range is 0%, not an infinity', () {
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: incomeMinor, months: 0, spentMinor: 100),
          0);
    });

    test('the exact case: spend equal to the range income is 0%', () {
      // Integer minor units, so this lands on 0.0 exactly — the same sum in
      // floating-point major units is where "0.00000001% saved" comes from.
      expect(
          AnalyticsController.savingsRatePercent(
              incomeMinorPerMonth: 333333, months: 3, spentMinor: 999999),
          0);
    });
  });

  group('the controller', () {
    late Directory tempDir;
    late LocalStoreService store;
    late CategoryRepository categoryRepo;
    late TransactionRepository transactionRepo;

    Category category({
      required String id,
      required String name,
      required String month,
      DateTime? createdAt,
      int colorValue = 0xFF2D8B8B,
    }) {
      final stamp = createdAt ?? DateTime(2026, 8, 1, 9);
      return Category(
        id: id,
        name: name,
        budgetLimitMinor: 100000,
        colorValue: colorValue,
        iconCodePoint: 0xe56c,
        month: month,
        createdAt: stamp,
        updatedAt: stamp,
      );
    }

    TransactionItem transaction({
      required String id,
      required String categoryId,
      required DateTime date,
      required int amountMinor,
    }) =>
        TransactionItem(
          id: id,
          categoryId: categoryId,
          amountMinor: amountMinor,
          note: '',
          date: date,
          createdAt: date,
          updatedAt: date,
        );

    /// The analytics screen, populated the way its own stream listeners
    /// populate it — reading through the shipped getters, not a copy of them.
    AnalyticsController analyticsFor({
      required String month,
      int income = incomeMinor,
      List<Category> categories = const [],
      List<TransactionItem> transactions = const [],
    }) {
      final settings = SettingsService();
      settings.currentMonth.value = month;
      settings.monthlyIncomeMinor.value = income;
      final ctrl = AnalyticsController(
        transactionRepo: transactionRepo,
        categoryRepo: categoryRepo,
        settings: settings,
      );
      ctrl.categories.assignAll(categories);
      ctrl.transactions.assignAll(transactions);
      return ctrl;
    }

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_analytics');
      Hive.init(tempDir.path);
      store = await LocalStoreService().init();
      Get.put<LocalStoreService>(store);
      categoryRepo = CategoryRepository();
      transactionRepo = TransactionRepository();
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('AC-3: changing the range changes the rate, live', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [category(id: 'food-aug', name: 'Food', month: august)],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 12),
              amountMinor: spentMinor),
        ],
      );

      expect(ctrl.savingsRate.toStringAsFixed(1), '91.6');
      ctrl.setRange(1);
      expect(ctrl.savingsRate.toStringAsFixed(1), '97.2');
      ctrl.setRange(2);
      expect(ctrl.savingsRate.toStringAsFixed(1), '98.6');
      // The period label still names what is being measured (UI-10).
      expect(ctrl.rangePeriodLabel, 'Last 6 months');
    });

    test('the spend total itself is unchanged by the range fix', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [category(id: 'food-aug', name: 'Food', month: august)],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 12),
              amountMinor: spentMinor),
        ],
      );

      expect(ctrl.totalSpentMinor, spentMinor);
      ctrl.setRange(1);
      expect(ctrl.totalSpentMinor, spentMinor);
    });

    test('AC-R2: a category spanning two months is ONE row carrying the sum',
        () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          // What a rollover leaves behind: same name, fresh id, per month.
          category(
              id: 'food-jul',
              name: 'Food',
              month: july,
              createdAt: DateTime(2026, 7, 1)),
          category(
              id: 'food-aug',
              name: 'Food',
              month: august,
              createdAt: DateTime(2026, 8, 1),
              colorValue: 0xFFAA3333),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'food-jul',
              date: DateTime(2026, 7, 14),
              amountMinor: 250000),
          transaction(
              id: 't2',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 3),
              amountMinor: 150000),
        ],
      );
      ctrl.setRange(1); // Last 3M — spans both months.

      final totals = ctrl.categoryTotals;
      expect(totals.length, 1, reason: 'one category, one slice, one legend row');
      expect(totals.single.name, 'Food');
      expect(totals.single.spentMinor, 400000);
      expect(totals.single.category?.id, 'food-aug',
          reason: 'the newest clone supplies colour and icon');
      expect(totals.single.category?.colorValue, 0xFFAA3333);
    });

    test('This Month still shows only this month\'s share', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          category(id: 'food-jul', name: 'Food', month: july),
          category(id: 'food-aug', name: 'Food', month: august),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'food-jul',
              date: DateTime(2026, 7, 14),
              amountMinor: 250000),
          transaction(
              id: 't2',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 3),
              amountMinor: 150000),
        ],
      );

      expect(ctrl.categoryTotals.single.spentMinor, 150000);
    });

    test('names group the way attribution matches them: trimmed, any case', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          category(
              id: 'a',
              name: 'Food',
              month: july,
              createdAt: DateTime(2026, 7, 1)),
          category(
              id: 'b',
              name: ' food ',
              month: august,
              createdAt: DateTime(2026, 8, 1)),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'a',
              date: DateTime(2026, 7, 14),
              amountMinor: 100),
          transaction(
              id: 't2',
              categoryId: 'b',
              date: DateTime(2026, 8, 14),
              amountMinor: 200),
        ],
      );
      ctrl.setRange(1);

      expect(ctrl.categoryTotals.length, 1);
      expect(ctrl.categoryTotals.single.spentMinor, 300);
    });

    test('spend whose category is gone joins the reserved bucket\'s row', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          category(
              id: 'bucket-aug',
              name: kUncategorisedCategoryName,
              month: august),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'bucket-aug',
              date: DateTime(2026, 8, 4),
              amountMinor: 500),
          // A pre-F-01 orphan: its category was deleted without re-pointing.
          transaction(
              id: 't2',
              categoryId: 'deleted-forever',
              date: DateTime(2026, 8, 5),
              amountMinor: 700),
        ],
      );

      final totals = ctrl.categoryTotals;
      expect(totals.length, 1);
      expect(totals.single.name, kUncategorisedCategoryName);
      expect(totals.single.spentMinor, 1200);
      expect(totals.single.category?.id, 'bucket-aug');
    });

    test('an orphan with no bucket anywhere still names itself', () {
      final ctrl = analyticsFor(
        month: august,
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'deleted-forever',
              date: DateTime(2026, 8, 5),
              amountMinor: 700),
        ],
      );

      // Nothing to take colour from, but the row is not "Unknown".
      expect(ctrl.categoryTotals.single.category, isNull);
      expect(ctrl.categoryTotals.single.name, kUncategorisedCategoryName);
    });

    test('rows are biggest first, and ties break by name rather than by luck',
        () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          category(id: 'z', name: 'Zakat', month: august),
          category(id: 'a', name: 'Auto', month: august),
          category(id: 'big', name: 'Rent', month: august),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'z',
              date: DateTime(2026, 8, 4),
              amountMinor: 500),
          transaction(
              id: 't2',
              categoryId: 'a',
              date: DateTime(2026, 8, 5),
              amountMinor: 500),
          transaction(
              id: 't3',
              categoryId: 'big',
              date: DateTime(2026, 8, 6),
              amountMinor: 900),
        ],
      );

      expect(ctrl.categoryTotals.map((e) => e.name).toList(),
          ['Rent', 'Auto', 'Zakat']);
    });

    test('the monthly bars are untouched by the grouping change', () {
      final ctrl = analyticsFor(
        month: august,
        categories: [
          category(id: 'food-jul', name: 'Food', month: july),
          category(id: 'food-aug', name: 'Food', month: august),
        ],
        transactions: [
          transaction(
              id: 't1',
              categoryId: 'food-jul',
              date: DateTime(2026, 7, 14),
              amountMinor: 250000),
          transaction(
              id: 't2',
              categoryId: 'food-aug',
              date: DateTime(2026, 8, 3),
              amountMinor: 150000),
        ],
      );
      ctrl.setRange(1);

      final bars = ctrl.monthlyTotals;
      expect(bars.map((b) => b.month).toList(), ['2026-06', july, august]);
      expect(bars.map((b) => b.totalMinor).toList(), [0, 250000, 150000]);
    });
  });
}
