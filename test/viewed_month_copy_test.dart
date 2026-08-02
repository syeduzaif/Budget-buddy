import 'dart:io';

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
}
