import 'dart:io';

import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/modules/dashboard/widgets/category_budget_list.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-10.3 — copy that stops claiming the viewed month is this month.
///
/// Browsing back to July left "This Month's Budgets" over July's numbers and
/// "Remaining ₨150,000" over a month that already ended — the first is simply
/// wrong about which month it is, and the second is a promise about a future
/// that is gone.
void main() {
  final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');

  group('budgets card title (pure widget)', () {
    Future<void> pumpTitle(
      WidgetTester tester, {
      required String monthKey,
      required bool isCurrentMonth,
    }) =>
        tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CategoryBudgetList(
              categories: const [],
              spentMinorByCategory: const {},
              currency: pkr,
              monthKey: monthKey,
              isCurrentMonth: isCurrentMonth,
              onSeeAll: () {},
            ),
          ),
        ));

    testWidgets('the current month keeps the familiar title', (tester) async {
      await pumpTitle(tester, monthKey: '2026-08', isCurrentMonth: true);
      expect(find.text("This Month's Budgets"), findsOneWidget);
    });

    testWidgets('any other month is named', (tester) async {
      await pumpTitle(tester, monthKey: '2026-07', isCurrentMonth: false);
      expect(find.text("July's Budgets"), findsOneWidget);
      expect(find.text("This Month's Budgets"), findsNothing);
    });

    testWidgets('the action names its destination in every month',
        (tester) async {
      // It tab-switches away from the dashboard, which is the disorienting
      // kind of navigation (FD-3).
      await pumpTitle(tester, monthKey: '2026-08', isCurrentMonth: true);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('See All'), findsNothing);

      await pumpTitle(tester, monthKey: '2026-07', isCurrentMonth: false);
      expect(find.text('All Categories'), findsOneWidget);
    });
  });

  group('dashboard, live', () {
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_month');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      Get.put(SettingsService());
      Get.put(DashboardController(
        categoryRepo: Get.find<CategoryRepository>(),
        transactionRepo: Get.find<TransactionRepository>(),
        settings: Get.find<SettingsService>(),
      ));
    });

    tearDown(() async {
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets('walking back a month rewrites both pieces of copy',
        (tester) async {
      // The device's real current month, so this does not rot at a boundary.
      final thisMonth = AppDateUtils.getCurrentMonthKey();
      final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const DashboardView()));
      await tester.pumpAndSettle();

      // Last month has to HOLD something for its summary cards to render at
      // all: since BUG-102 a non-current month with no records shows the
      // two-line empty state instead, and "Unspent" is a claim about real
      // spend. Hive is disk I/O, hence runAsync.
      await tester.runAsync(() =>
          Get.find<TransactionRepository>().addTransaction(TransactionItem(
            id: 'old-1',
            categoryId: 'anything',
            amountMinor: 10000,
            note: 'Chai',
            date: DateTime(int.parse(lastMonth.split('-')[0]),
                int.parse(lastMonth.split('-')[1]), 9, 12),
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          )));
      await tester.pumpAndSettle();

      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Unspent'), findsNothing);
      expect(find.text("This Month's Budgets"), findsOneWidget);

      // Exactly what the back chevron does.
      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(lastMonth));
      await tester.pumpAndSettle();

      expect(find.text('Unspent'), findsOneWidget,
          reason: 'on a closed month the figure is what went unspent, not '
              'what is left to spend');
      expect(find.text('Remaining'), findsNothing);
      expect(find.text("${AppDateUtils.formatMonthName(lastMonth)}'s Budgets"),
          findsOneWidget);

      // And back again — neither label is a one-way door.
      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(thisMonth));
      await tester.pumpAndSettle();

      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text("This Month's Budgets"), findsOneWidget);
    });
  });

  /// BUG-102 / F-10.3 spec (d) — a month the app holds no records for gets no
  /// totals.
  ///
  /// A fresh install browsing one month back read "Monthly Income ₨45,000 ·
  /// Spent ₨0 · Unspent ₨45,000": today's income figure applied to a period the
  /// app has never seen, with the whole of it volunteered as "Unspent". Spent ₨0
  /// was honest; the other two were claims about nothing.
  group('BUG-102 — an empty past month', () {
    late Directory tempDir;

    final thisMonth = AppDateUtils.getCurrentMonthKey();
    final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

    DateTime dayIn(String monthKey, int day) => DateTime(
        int.parse(monthKey.split('-')[0]),
        int.parse(monthKey.split('-')[1]),
        day,
        12);

    TransactionItem txn(String id, DateTime date) => TransactionItem(
          id: id,
          categoryId: 'anything',
          amountMinor: 45000,
          note: 'Chai',
          date: date,
          createdAt: date,
          updatedAt: date,
        );

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_norecords');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      final settings = Get.put(SettingsService());
      await settings.setCurrency('PKR', '₨');
      await settings.setCurrentMonth(thisMonth);
      // waqas's repro figure.
      await settings.setMonthlyIncomeMinor(4500000);
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

    const line1Prefix = 'No records for ';
    const line2 = 'Nothing was logged here, so there are no totals to show.';

    test('the predicate spares the current month at zero records', () async {
      // The month the user is living in is never suppressed — an empty August
      // on the 1st is the normal state of a new install, not a void.
      expect(dashboard().transactions, isEmpty);
      expect(dashboard().isViewingCurrentMonth, isTrue);
      expect(dashboard().viewedMonthHasNoRecords, isFalse);

      await Get.find<SettingsService>().setCurrentMonth(lastMonth);
      expect(dashboard().viewedMonthHasNoRecords, isTrue);
    });

    test('it counts records, never sums them', () async {
      await Get.find<TransactionRepository>()
          .addTransaction(txn('old-1', dayIn(lastMonth, 9)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await Get.find<SettingsService>().setCurrentMonth(lastMonth);

      expect(dashboard().viewedMonthHasNoRecords, isFalse,
          reason: 'a month that holds a row is not an empty month, whatever '
              'the rows add up to');
      // And a row in ANOTHER month does not populate this one.
      await Get.find<SettingsService>()
          .setCurrentMonth(AppDateUtils.getPreviousMonthKey(lastMonth));
      expect(dashboard().viewedMonthHasNoRecords, isTrue);
    });

    // Both themes, per AC-10.3. The ThemeData is built INSIDE the test body:
    // touching `AppTheme` while the group is being collected runs google_fonts
    // outside any test zone, which fails the whole file at load.
    for (final name in ['light', 'dark']) {
      testWidgets('$name: the three cards go, two muted lines take their place',
          (tester) async {
        final theme = name == 'dark' ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          // A second pumpWidget in one test otherwise reads the previous theme
          // mid-lerp.
          themeAnimationDuration: Duration.zero,
          home: const DashboardView(),
        ));
        await tester.pumpAndSettle();

        // August, the month being lived in: everything renders.
        expect(find.text('Monthly Income'), findsOneWidget);
        expect(find.text('Remaining'), findsOneWidget);

        await tester.runAsync(
            () => Get.find<SettingsService>().setCurrentMonth(lastMonth));
        await tester.pumpAndSettle();

        expect(find.text('Monthly Income'), findsNothing,
            reason: 'today\'s income is not July\'s income');
        expect(find.text('Spent'), findsNothing);
        expect(find.text('Unspent'), findsNothing,
            reason: 'the whole block goes, so no partial arithmetic is left');
        expect(find.text('₨45,000.00'), findsNothing);

        expect(
            find.text(
                '$line1Prefix${AppDateUtils.formatMonthName(lastMonth)}.'),
            findsOneWidget);
        expect(find.text(line2), findsOneWidget);

        final muted = name == 'dark'
            ? AppSemanticColors.dark.textMuted
            : AppSemanticColors.light.textMuted;
        final title = tester.widget<Text>(find.textContaining(line1Prefix));
        expect(title.style?.color, muted);
        expect(title.maxLines, 1,
            reason: 'one line at any text scale, ellipsized');
        expect(title.overflow, TextOverflow.ellipsis);
        expect(tester.widget<Text>(find.text(line2)).style?.color, muted);

        // Nothing BELOW the block is suppressed.
        expect(find.text("${AppDateUtils.formatMonthName(lastMonth)}'s Budgets"),
            findsOneWidget);
        expect(find.text('All Categories'), findsNothing,
            reason: 'that action appears only with more than four categories, '
                'and this month has none — the card itself is what must be '
                'present');
      });
    }

    testWidgets('a past month holding one transaction keeps all three cards',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          themeAnimationDuration: Duration.zero,
          home: const DashboardView()));
      await tester.pumpAndSettle();

      await tester.runAsync(() => Get.find<TransactionRepository>()
          .addTransaction(txn('old-1', dayIn(lastMonth, 9))));
      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(lastMonth));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Income'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Unspent'), findsOneWidget,
          reason: 'the relabel is RETAINED where real spend exists');
      expect(find.textContaining(line1Prefix), findsNothing);
      expect(find.text(line2), findsNothing);
    });

    testWidgets('the predicate is live in both directions', (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          themeAnimationDuration: Duration.zero,
          home: const DashboardView()));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(lastMonth));
      await tester.pumpAndSettle();
      expect(find.text(line2), findsOneWidget);

      // Back-dating a transaction INTO the month on screen restores its cards…
      await tester.runAsync(() => Get.find<TransactionRepository>()
          .addTransaction(txn('old-1', dayIn(lastMonth, 9))));
      await tester.pumpAndSettle();
      expect(find.text(line2), findsNothing);
      expect(find.text('Unspent'), findsOneWidget);

      // …and deleting it returns the empty state.
      await tester.runAsync(
          () => Get.find<TransactionRepository>().deleteTransaction('old-1'));
      await tester.pumpAndSettle();
      expect(find.text(line2), findsOneWidget);
      expect(find.text('Unspent'), findsNothing);
    });

    testWidgets('returning to the current month restores everything',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          themeAnimationDuration: Duration.zero,
          home: const DashboardView()));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(lastMonth));
      await tester.pumpAndSettle();
      expect(find.text(line2), findsOneWidget);

      await tester.runAsync(
          () => Get.find<SettingsService>().setCurrentMonth(thisMonth));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Income'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text("This Month's Budgets"), findsOneWidget);
      expect(find.textContaining(line1Prefix), findsNothing);
    });
  });
}
