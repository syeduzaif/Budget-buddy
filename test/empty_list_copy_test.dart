import 'dart:io';

import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/transactions/transactions_controller.dart';
import 'package:budget_buddy/modules/transactions/transactions_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// BUG-021 — the empty transactions list pointed at a button that is not there.
///
/// "No transactions yet — Add your first transaction using the + button": this
/// screen is a pushed route, so the home tab bar (whose Add tab is the only door
/// to the form) is off screen, and the list has no FAB. The copy also read as
/// "this app is empty" on a month-scoped list, when the truth was only that July
/// was.
void main() {
  group('copy for each scope', () {
    test('a month-scoped list names the month and promises, not instructs', () {
      final copy = TransactionsController.emptyCopyFor(month: '2026-08');
      expect(copy.title, 'Nothing logged in August 2026');
      expect(copy.line, 'Expenses you add will appear here.');
    });

    test('a category-scoped list names the category', () {
      final both = TransactionsController.emptyCopyFor(
          categoryName: 'Health', month: '2026-08');
      expect(both.title, 'Nothing logged in Health for August 2026');
      expect(both.line, 'Expenses you add to Health will appear here.');

      final categoryOnly =
          TransactionsController.emptyCopyFor(categoryName: 'Health');
      expect(categoryOnly.title, 'Nothing logged in Health');
      expect(categoryOnly.line, 'Expenses you add to Health will appear here.');
    });

    test('the all-time list says nothing about a month', () {
      final copy = TransactionsController.emptyCopyFor();
      expect(copy.title, 'Nothing logged yet');
      expect(copy.line, 'Expenses you add will appear here.');
    });

    test('no scope mentions a "+" — the whole point', () {
      for (final copy in [
        TransactionsController.emptyCopyFor(),
        TransactionsController.emptyCopyFor(month: '2026-07'),
        TransactionsController.emptyCopyFor(categoryName: 'Health'),
        TransactionsController.emptyCopyFor(
            categoryName: 'Health', month: '2026-07'),
      ]) {
        expect(copy.title, isNot(contains('+')));
        expect(copy.line, isNot(contains('+')));
        // Nor any other affordance this screen does not have.
        expect('${copy.title} ${copy.line}'.toLowerCase(),
            isNot(contains('button')));
      }
    });

    test('an unparseable month key degrades to itself, never to a crash', () {
      expect(TransactionsController.emptyCopyFor(month: 'nonsense').title,
          'Nothing logged in nonsense');
    });
  });

  group('the screen uses it', () {
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_emptycopy');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      Get.put(SettingsService());
      Get.testMode = true;
    });

    tearDown(() async {
      Get.testMode = false;
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets('July, opened from the dashboard with nothing in it',
        (tester) async {
      // The store stays empty, so there is no Hive write to wait for.
      await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(body: Center(child: Text('dashboard'))),
      ));
      // The screen is only ever reached by a push carrying its scope — the
      // dashboard's Spent-card chevron passes exactly this map — and the
      // controller reads it from `Get.arguments`, so the push is the test.
      Get.to(() => const TransactionsView(), arguments: {'month': '2026-07'});
      await tester.pumpAndSettle();

      expect(find.text('Nothing logged in July 2026'), findsOneWidget);
      expect(find.text('Expenses you add will appear here.'), findsOneWidget);
      expect(find.textContaining('+ button'), findsNothing);
      expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets,
          reason: 'the house empty state is icon + title + one muted line');
    });
  });
}
