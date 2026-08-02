import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/modules/dashboard/widgets/recent_transactions_card.dart';
import 'package:budget_buddy/modules/dashboard/widgets/summary_card.dart';
import 'package:budget_buddy/modules/transactions/transactions_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-04 — the dashboard shows the thing you just logged, and the list it opens
/// holds the month it was tapped from.
///
/// Before this, saving an expense changed only the totals: nothing on the
/// landing screen named the transaction, and the one entrance to the full list
/// was an unmarked tap on the Spent card that opened an ALL-TIME list under a
/// month-scoped number.
void main() {
  final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');
  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  int yearOf(String monthKey) => int.parse(monthKey.split('-')[0]);
  int monthOf(String monthKey) => int.parse(monthKey.split('-')[1]);
  DateTime dayIn(String monthKey, int day) =>
      DateTime(yearOf(monthKey), monthOf(monthKey), day, 12);

  Category category({
    required String id,
    required String name,
    required String month,
    int limitMinor = 500000,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: limitMinor,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: month,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

  TransactionItem txn({
    required String id,
    required DateTime date,
    int amountMinor = 10000,
    String note = '',
    String categoryId = 'food-now',
  }) =>
      TransactionItem(
        id: id,
        categoryId: categoryId,
        amountMinor: amountMinor,
        note: note,
        date: date,
        createdAt: date,
        updatedAt: date,
      );

  group('the list title carries every scope it is under (pure)', () {
    test('month alone', () {
      expect(TransactionsController.titleFor(month: '2026-08'), 'August 2026');
    });

    test('category and month', () {
      // RULING-C: the category does not stop the list being one month's.
      expect(
          TransactionsController.titleFor(
              categoryName: 'Health', month: '2026-08'),
          'Health · August 2026');
    });

    test('category alone keeps its old wording', () {
      expect(TransactionsController.titleFor(categoryName: 'Health'), 'Health');
    });

    test('neither is the all-time list', () {
      expect(TransactionsController.titleFor(), 'All Transactions');
    });
  });

  group('the Recent card (pure widget)', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required List<TransactionItem> transactions,
      void Function(TransactionItem)? onTap,
      VoidCallback? onSeeAll,
    }) =>
        tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RecentTransactionsCard(
              transactions: transactions,
              categories: [
                category(id: 'food-now', name: 'Food', month: thisMonth),
              ],
              currency: pkr,
              onSeeAll: onSeeAll ?? () {},
              onTapTransaction: onTap ?? (_) {},
            ),
          ),
        ));

    testWidgets('a row is titled by its note, and by its category without one',
        (tester) async {
      await pumpCard(tester, transactions: [
        txn(id: 'a', date: dayIn(thisMonth, 14), note: 'Biryani'),
        txn(id: 'b', date: dayIn(thisMonth, 13)),
      ]);

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('Biryani'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget,
          reason: 'the same fallback the full list uses');
    });

    testWidgets('rows carry no chevron — the ripple is the affordance',
        (tester) async {
      await pumpCard(tester, transactions: [
        txn(id: 'a', date: dayIn(thisMonth, 14), note: 'Biryani'),
      ]);

      expect(find.byIcon(Icons.chevron_right), findsNothing,
          reason: 'a chevron per row is noise and steals amount width '
              '(danish, D7)');
    });

    testWidgets('tapping a row hands back that transaction', (tester) async {
      TransactionItem? tapped;
      await pumpCard(
        tester,
        transactions: [
          txn(id: 'a', date: dayIn(thisMonth, 14), note: 'Biryani'),
          txn(id: 'b', date: dayIn(thisMonth, 13), note: 'Chai'),
        ],
        onTap: (t) => tapped = t,
      );

      await tester.tap(find.text('Chai'));
      expect(tapped?.id, 'b');
    });

    testWidgets('the amount is exact and never red', (tester) async {
      await pumpCard(tester, transactions: [
        txn(id: 'a', date: dayIn(thisMonth, 14), amountMinor: 245000),
      ]);

      final amount = tester.widget<Text>(find.text('₨2,450.00'));
      expect(amount.style?.color,
          AppTheme.light.colorScheme.onSurface,
          reason: 'every row here is an expense, so red would say nothing and '
              'would collide with the over-budget signal (UI-29)');
    });
  });

  group('live dashboard', () {
    late Directory tempDir;
    late LocalStoreService store;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_recent');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      store = await LocalStoreService().init();
      Get.put<LocalStoreService>(store);
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      final settings = Get.put(SettingsService());
      await settings.setCurrency('PKR', '₨');
      await settings.setCurrentMonth(thisMonth);
      await settings.setMonthlyIncomeMinor(15000000);
      await Get.find<CategoryRepository>().addCategories([
        category(id: 'food-now', name: 'Food', month: thisMonth),
        category(id: 'food-last', name: 'Food', month: lastMonth),
      ]);
      Get.put(DashboardController(
        categoryRepo: Get.find<CategoryRepository>(),
        transactionRepo: Get.find<TransactionRepository>(),
        settings: settings,
      ));
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    DashboardController dashboard() => Get.find<DashboardController>();

    test('recentTransactions: newest first, this month only, five at most',
        () async {
      final repo = Get.find<TransactionRepository>();
      for (var day = 1; day <= 7; day++) {
        await repo.addTransaction(txn(id: 'now-$day', date: dayIn(thisMonth, day)));
      }
      await repo.addTransaction(txn(
          id: 'old-1', date: dayIn(lastMonth, 20), categoryId: 'food-last'));
      // The store's stream is what the controller reads; give it a beat.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final recent = dashboard().recentTransactions;
      expect(recent, hasLength(DashboardController.recentLimit));
      expect(recent.map((t) => t.id).toList(),
          ['now-7', 'now-6', 'now-5', 'now-4', 'now-3'],
          reason: 'newest first, and never the previous month\'s row');
      expect(recent.any((t) => t.id == 'old-1'), isFalse);
    });

    test('recentTransactions follows the viewed month backwards', () async {
      final repo = Get.find<TransactionRepository>();
      await repo.addTransaction(txn(id: 'now-1', date: dayIn(thisMonth, 5)));
      await repo.addTransaction(txn(
          id: 'old-1', date: dayIn(lastMonth, 20), categoryId: 'food-last'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(dashboard().recentTransactions.single.id, 'now-1');

      await Get.find<SettingsService>().setCurrentMonth(lastMonth);
      expect(dashboard().recentTransactions.single.id, 'old-1',
          reason: 'a back-dated row belongs to ITS month\'s dashboard '
              '(F-04 AC-2)');
    });

    testWidgets('AC-3: a month with nothing logged renders no Recent card',
        (tester) async {
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const DashboardView()));
      await tester.pumpAndSettle();

      expect(find.text('Recent'), findsNothing);
      expect(find.byType(RecentTransactionsCard), findsNothing,
          reason: 'no empty shell — the donut already says "nothing logged yet"');
      expect(find.text('Nothing logged yet'), findsOneWidget);
    });

    testWidgets('AC-1: a logged expense appears on the dashboard',
        (tester) async {
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const DashboardView()));
      await tester.pumpAndSettle();

      await tester.runAsync(() => Get.find<TransactionRepository>()
          .addTransaction(txn(
              id: 'now-1',
              date: dayIn(thisMonth, 9),
              amountMinor: 245000,
              note: 'Biryani')));
      // Twice: `pump` advances the clock and THEN builds, so the card's
      // staggered entrance timer is created by the first frame and only fires
      // on the second. A test that leaves it pending fails on teardown.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(RecentTransactionsCard), findsOneWidget);
      expect(find.text('Biryani'), findsOneWidget);
      expect(find.text('₨2,450.00'), findsWidgets);
    });

    testWidgets('AC-5: the Spent card shows its tap, the Remaining card does not',
        (tester) async {
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const DashboardView()));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
            of: find.widgetWithText(SummaryCard, 'Spent'),
            matching: find.byIcon(Icons.chevron_right),
          ),
          findsOneWidget,
          reason: 'summary cards have no conventional tap shape, so the one '
              'that opens something says so');
      expect(
          find.descendant(
            of: find.widgetWithText(SummaryCard, 'Remaining'),
            matching: find.byIcon(Icons.chevron_right),
          ),
          findsNothing,
          reason: 'there is no list of "remaining" to open');
    });
  });

  group('the month-scoped list', () {
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_scoped');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      await Get.find<TransactionRepository>()
          .addTransaction(txn(id: 'now-1', date: dayIn(thisMonth, 9)));
      await Get.find<TransactionRepository>().addTransaction(
          txn(id: 'old-1', date: dayIn(lastMonth, 9), categoryId: 'food-last'));
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('holds exactly the month it was opened for', () async {
      final ctrl = Get.put(TransactionsController(
        transactionRepo: Get.find<TransactionRepository>(),
        categoryRepo: Get.find<CategoryRepository>(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl.filtered.map((t) => t.id).toSet(), {'now-1', 'old-1'},
          reason: 'unscoped is still all time — only a caller that asks for '
              'that gets it');

      ctrl.filterMonth = thisMonth;
      expect(ctrl.filtered.map((t) => t.id).toSet(), {'now-1'});
      expect(ctrl.screenTitle, AppDateUtils.formatMonthKey(thisMonth));

      ctrl.filterMonth = lastMonth;
      expect(ctrl.filtered.map((t) => t.id).toSet(), {'old-1'});
    });
  });
}
