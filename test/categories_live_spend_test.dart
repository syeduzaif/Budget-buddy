import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/categories/categories_controller.dart';
import 'package:budget_buddy/modules/categories/categories_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// UI-02 regression guard.
///
/// The Categories tab showed 0 spend for a category the user had just spent in
/// until the tab was left and re-entered, because the only read of
/// `transactions` happened inside `ListView.builder`'s `itemBuilder` — after
/// the `Obx` observer scope had closed. On a money screen that reads as "the
/// save failed", and the natural response is to save again.
///
/// This test writes a transaction while the screen is mounted, which is the
/// exact situation that failed.
///
/// NOTE: Hive writes are real disk I/O, so they go through `tester.runAsync`.
/// Awaiting them directly inside `testWidgets` deadlocks against the fake
/// async clock.
void main() {
  late Directory tempDir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_categories');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    Get.put(SettingsService());
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('spend updates while the Categories tab stays on screen',
      (tester) async {
    // The device's real current month, so the test does not rot at a month
    // boundary; the controller filters on exactly this key.
    final now = DateTime.now();
    final month = AppDateUtils.monthKey(now);

    await tester.runAsync(() => Get.find<CategoryRepository>().addCategory(
          Category(
            id: 'cat-1',
            name: 'Transport',
            budgetLimitMinor: 100000, // $1,000.00 — well above the spend below
            colorValue: 0xFF3498DB,
            month: month,
            createdAt: now,
            updatedAt: now,
          ),
        ));

    Get.put(CategoriesController(
      categoryRepo: Get.find<CategoryRepository>(),
      transactionRepo: Get.find<TransactionRepository>(),
      settings: Get.find<SettingsService>(),
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const CategoriesView(),
    ));
    // Fixed pumps rather than pumpAndSettle: the list items animate in on a
    // staggered delay, and this test cares about the value, not the motion.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget, reason: 'nothing spent yet');

    // The write the user makes from the Add sheet, with this tab on screen.
    await tester.runAsync(
      () => Get.find<TransactionRepository>().addTransaction(TransactionItem(
        id: 'tx-1',
        categoryId: 'cat-1',
        amountMinor: 45000, // $450.00
        note: 'Careem ride',
        date: now,
        createdAt: now,
        updatedAt: now,
      )),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('\$450.00'), findsOneWidget,
        reason: 'the spend map must be a dependency of the Obx (UI-02)');
    expect(find.text('\$0.00'), findsNothing);
  });
}
