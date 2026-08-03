import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-06 — the Add sheet opens on the category you last used.
///
/// It used to open on the month's FIRST category — seed order, so Housing — which
/// with nine categories is wrong about eight times in nine, at two taps and a
/// modal per log.
///
/// Plain `test`s, not `testWidgets`: the whole feature is a preference read at
/// sheet-open time, so it can be exercised through the controller on a real
/// clock, where Hive writes simply complete. `Get.testMode` covers the
/// contextless `Get.back()` inside `save()`; its confirmation snackbar is
/// scheduled on a post-frame callback that never runs here, which is exactly
/// what makes this shape possible.
void main() {
  late Directory tempDir;
  late LocalStoreService store;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late SettingsService settings;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final nextMonth = AppDateUtils.getNextMonthKey(thisMonth);

  /// `createdAt` USED to decide the picker's order — the store hands categories
  /// back newest-first — which for a month's clones (one batch, one timestamp)
  /// was arbitrary, and `List.sort` is not stable. BUG-020: the reserved bucket
  /// could win that lottery and become the default. The picker now sorts by
  /// name with the bucket last, so the fallback below is the alphabetically
  /// first NON-reserved category and the stamps no longer decide anything.
  Category category({
    required String id,
    required String name,
    String? month,
    DateTime? createdAt,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: 500000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: month ?? thisMonth,
        createdAt: createdAt ?? DateTime(2026, 1, 1, 9),
        updatedAt: createdAt ?? DateTime(2026, 1, 1, 9),
      );

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_lastused');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
    categories = Get.put(CategoryRepository());
    transactions = Get.put(TransactionRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrentMonth(thisMonth);
    // Descending stamps on purpose: they are the order the store emits, so a
    // fallback that still answered "Housing" would prove the picker sort was
    // not applied. Alphabetically the answer is Food.
    await categories.addCategories([
      category(
          id: 'housing', name: 'Housing', createdAt: DateTime(2026, 1, 3, 9)),
      category(id: 'food', name: 'Food', createdAt: DateTime(2026, 1, 2, 9)),
      category(
          id: 'transport', name: 'Transport', createdAt: DateTime(2026, 1, 1, 9)),
    ]);
    Get.testMode = true;
  });

  tearDown(() async {
    Get.testMode = false;
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Opens a sheet's worth of controller and lets its category stream arrive.
  Future<TransactionFormController> openSheet({
    String? preselectedCategoryId,
    TransactionItem? editing,
  }) async {
    if (Get.isRegistered<TransactionFormController>()) {
      Get.delete<TransactionFormController>();
    }
    final ctrl = Get.put(TransactionFormController(
      categoryRepo: categories,
      transactionRepo: transactions,
      settings: settings,
      preselectedCategoryId: preselectedCategoryId,
      editing: editing,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ctrl;
  }

  /// Saves [amount] against [category] the way the sheet does.
  Future<void> logAgainst(Category category, {String amount = '100'}) async {
    final ctrl = await openSheet();
    ctrl.selectCategory(category);
    ctrl.amountController.text = amount;
    await ctrl.save();
  }

  group('what gets remembered', () {
    test('AC-1/AC-2: the most recent save wins, not the most frequent',
        () async {
      await logAgainst(category(id: 'food', name: 'Food'));
      expect(settings.lastUsedCategoryName, 'Food');
      expect((await openSheet()).selectedCategory.value?.id, 'food');

      await logAgainst(category(id: 'transport', name: 'Transport'));
      expect(settings.lastUsedCategoryName, 'Transport');
      expect((await openSheet()).selectedCategory.value?.id, 'transport');
    });

    test('AC-3: it is on disk, so it survives process death', () async {
      await logAgainst(category(id: 'food', name: 'Food'));

      // A fresh service over the same box is what a relaunch looks like.
      final relaunched = SettingsService();
      expect(relaunched.lastUsedCategoryName, 'Food');
    });

    test('the reserved bucket is never remembered', () async {
      await logAgainst(category(id: 'food', name: 'Food'));
      // Saving with no category picked lands in the bucket (F-01).
      final ctrl = await openSheet();
      ctrl.selectedCategory.value = null;
      ctrl.amountController.text = '250';
      await ctrl.save();

      final bucket = store
          .readCategories()
          .where((c) => isReservedCategoryName(c.name))
          .toList();
      expect(bucket, hasLength(1), reason: 'the amount did land in the bucket');
      expect(settings.lastUsedCategoryName, 'Food',
          reason: 'the row that reports a data problem must not become the '
              'default that creates one (palwasha 8c)');
    });

    test('a failed save remembers nothing', () async {
      final ctrl = await openSheet();
      ctrl.selectCategory(category(id: 'food', name: 'Food'));
      // Not a number: save() returns before touching the store.
      ctrl.amountController.text = 'abc';
      await ctrl.save();

      expect(store.readTransactions(), isEmpty);
      expect(settings.lastUsedCategoryName, isNull);
    });

    test('erasing everything erases the default too', () async {
      await logAgainst(category(id: 'food', name: 'Food'));
      expect(settings.lastUsedCategoryName, 'Food');

      await settings.resetToDefaults();
      expect(settings.lastUsedCategoryName, isNull);
    });
  });

  group('what the sheet opens on', () {
    test('with nothing remembered it is the first category in picker order',
        () async {
      expect((await openSheet()).selectedCategory.value?.id, 'food',
          reason: 'by name, not by whichever clone was written last (BUG-020)');
    });

    test('AC-4: a remembered name that no longer exists falls back silently',
        () async {
      await settings.rememberLastUsedCategory('Gym');
      expect((await openSheet()).selectedCategory.value?.id, 'food');
    });

    test('matching is exact — "transport" is not "Transport"', () async {
      await settings.rememberLastUsedCategory('transport');
      expect((await openSheet()).selectedCategory.value?.id, 'food',
          reason: 'names are user-typed and displayed verbatim (F-06 rule 4), '
              'so this falls back rather than matching');
    });

    test('AC-5: after a rollover it resolves to the new month\'s clone',
        () async {
      await settings.rememberLastUsedCategory('Food');
      // What F-02's rollover leaves behind: same names, fresh ids, new month.
      await categories.addCategories([
        category(id: 'housing-next', name: 'Housing', month: nextMonth),
        category(id: 'food-next', name: 'Food', month: nextMonth),
      ]);
      await settings.setCurrentMonth(nextMonth);

      expect((await openSheet()).selectedCategory.value?.id, 'food-next',
          reason: 'a stored ID would have gone stale here by construction');
    });

    test('AC-5b: a next-month clone set is answered by name, not by stamp',
        () async {
      // Same shape as AC-5 above but with nothing remembered: the fallback must
      // still be a category, and the same one, in a month whose clones were all
      // written at once.
      await categories.addCategories([
        category(id: 'housing-next', name: 'Housing', month: nextMonth),
        category(id: 'food-next', name: 'Food', month: nextMonth),
      ]);
      await settings.setCurrentMonth(nextMonth);

      expect((await openSheet()).selectedCategory.value?.id, 'food-next');
    });

    test('an explicit preselection outranks the remembered default', () async {
      await settings.rememberLastUsedCategory('Food');
      final ctrl = await openSheet(preselectedCategoryId: 'transport');
      expect(ctrl.selectedCategory.value?.id, 'transport');
    });

    test('editing opens on the row\'s own category, not the remembered one',
        () async {
      await settings.rememberLastUsedCategory('Food');
      final row = TransactionItem(
        id: 'txn-1',
        categoryId: 'transport',
        amountMinor: 5000,
        note: 'Bus',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await transactions.addTransaction(row);

      final ctrl = await openSheet(editing: row);
      expect(ctrl.selectedCategory.value?.id, 'transport');
    });
  });

  /// BUG-020 — the fallback could hand new spend to the reserved bucket.
  ///
  /// Delete a category and its transactions re-point to Uncategorised, which
  /// creates the bucket in that month; the stored last-used name then matches
  /// nothing, the fallback took "the month's first category", and the bucket
  /// sorted first. So the Add sheet opened on the row that exists to REPORT a
  /// mis-attribution and quietly became the one creating them.
  group('the reserved bucket is never the default (BUG-020)', () {
    Future<Category> addBucket({String? month}) async {
      final bucket = await categories.ensureUncategorised(month ?? thisMonth);
      return bucket;
    }

    test('with a bucket present and nothing remembered, Food still wins',
        () async {
      await addBucket();
      expect((await openSheet()).selectedCategory.value?.id, 'food');
    });

    test('palwasha\'s recipe: an unresolvable last-used name skips the bucket',
        () async {
      // "Temp" was logged against, then deleted — its transaction re-pointed to
      // the bucket, and the remembered name now matches nothing.
      await settings.rememberLastUsedCategory('Temp');
      await addBucket();

      final ctrl = await openSheet();
      expect(isReservedCategoryName(ctrl.selectedCategory.value!.name), isFalse,
          reason: 'the bucket that reports a data problem must not become the '
              'default that creates one (palwasha 8c)');
      expect(ctrl.selectedCategory.value?.id, 'food');
    });

    test('a preselection that no longer resolves also skips the bucket',
        () async {
      await addBucket();
      final ctrl = await openSheet(preselectedCategoryId: 'deleted-id');
      expect(isReservedCategoryName(ctrl.selectedCategory.value!.name), isFalse);
    });

    test('but the bucket IS the default when it is all the month has', () async {
      // A month holding nothing else: an empty picker would be worse than the
      // one row that exists, and saving would land there anyway (F-01).
      final emptyMonth = AppDateUtils.getNextMonthKey(nextMonth);
      final bucket = await addBucket(month: emptyMonth);
      await settings.setCurrentMonth(emptyMonth);

      final ctrl = await openSheet();
      expect(ctrl.selectedCategory.value?.id, bucket.id);
    });

    test('the picker order is by name, deterministic, bucket last', () async {
      await addBucket();
      final ctrl = await openSheet();
      expect(ctrl.categories.map((c) => c.name).toList(),
          ['Food', 'Housing', 'Transport', kUncategorisedCategoryName]);
    });

    test('order is a pure function of the list, not of the store\'s emission',
        () async {
      // The same set in three different input orders must produce one output —
      // this is what the old newest-first list could not promise.
      Category cat(String id, String name) => category(id: id, name: name);
      final bucket = cat('bucket', kUncategorisedCategoryName);
      final food = cat('f', 'Food');
      final apples = cat('a', 'apples'); // lower-case: compare is folded
      final zoo = cat('z', 'Zoo');

      for (final input in [
        [bucket, food, apples, zoo],
        [zoo, apples, food, bucket],
        [food, bucket, zoo, apples],
      ]) {
        expect(
            TransactionFormController.orderForPicker(input)
                .map((c) => c.id)
                .toList(),
            ['a', 'f', 'z', 'bucket']);
      }
    });
  });
}
