import 'dart:io';
import 'dart:math';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/categories/categories_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-01 — transaction attribution integrity.
///
/// INV-1, the requirement everything here serves: for every month M,
/// `Spent(M) == Σ per-category spend shown for M`. Three reachable paths broke
/// it (back-dating, past-month add, delete-orphans) because every month holds
/// its own category clones with fresh ids, and attribution was decided in
/// three places against the VIEWED month.
///
/// The manifest below is adil's T1–T13 dry-run list plus bilal's property
/// test. NOTE for the record: the enumerated T1–T13 text was referenced by
/// DECISIONS-2026-08-02 ("goes verbatim into the F-01 ticket") but never
/// written into a frozen doc — only T3b, T8, T11 and T13 are described there.
/// These thirteen are reconstructed from the behaviour spec and those four
/// anchors, and each carries its T-id so the list can be reconciled.
void main() {
  late Directory tempDir;
  late LocalStoreService store;
  late CategoryRepository categories;
  late TransactionRepository transactions;

  const august = '2026-08';
  const july = '2026-07';
  const september = '2026-09';

  Category category({
    required String id,
    required String name,
    required String month,
    int limitMinor = 10000,
    DateTime? createdAt,
    int colorValue = 0xFF2D8B8B,
  }) {
    final stamp = createdAt ?? DateTime(2026, 8, 1, 9);
    return Category(
      id: id,
      name: name,
      budgetLimitMinor: limitMinor,
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
    int amountMinor = 1000,
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

  /// The dashboard, populated exactly the way its own stream listener
  /// populates it: categories filtered to [month], every transaction kept.
  /// Reading INV-1 through the shipped getters is the point — a private copy
  /// of the predicate in the test could pass while the app was wrong.
  DashboardController dashboardFor(String month) {
    final settings = SettingsService();
    settings.currentMonth.value = month;
    final ctrl = DashboardController(
      categoryRepo: categories,
      transactionRepo: transactions,
      settings: settings,
    );
    ctrl.categories.assignAll(
        store.readCategories().where((c) => c.month == month).toList());
    ctrl.transactions.assignAll(store.readTransactions());
    return ctrl;
  }

  CategoriesController categoriesTabFor(String month) {
    final settings = SettingsService();
    settings.currentMonth.value = month;
    final ctrl = CategoriesController(
      categoryRepo: categories,
      transactionRepo: transactions,
      settings: settings,
    );
    ctrl.categories.assignAll(
        store.readCategories().where((c) => c.month == month).toList());
    ctrl.transactions.assignAll(store.readTransactions());
    return ctrl;
  }

  /// INV-1 through the shipped predicates, for one month.
  void expectInvariant(String month, {String? because}) {
    final dashboard = dashboardFor(month);
    final rows = dashboard.categories
        .map((c) => dashboard.spentForCategoryMinor(c.id))
        .fold(0, (int sum, int spent) => sum + spent);
    expect(dashboard.totalSpentMinor, rows,
        reason: 'INV-1 broken in $month${because == null ? '' : ' — $because'}');

    // The Categories tab is the enumeration surface AC-3 names, and it must
    // agree with the dashboard row for row.
    final tab = categoriesTabFor(month);
    for (final c in tab.categories) {
      expect(tab.spentForCategoryMinor(c.id),
          dashboard.spentForCategoryMinor(c.id),
          reason: 'tab and dashboard disagree on "${c.name}" in $month');
    }
  }

  /// Every transaction sits in a category stamped with the transaction's own
  /// date-month (the structural corollary of INV-1).
  void expectStructuralCorollary() {
    final byId = {for (final c in store.readCategories()) c.id: c};
    for (final t in store.readTransactions()) {
      final cat = byId[t.categoryId];
      expect(cat, isNotNull,
          reason: 'transaction ${t.id} points at a category that is gone');
      expect(cat!.month, AppDateUtils.getMonthKeyFromDate(t.date),
          reason: 'transaction ${t.id} dated ${t.date} sits in ${cat.month}');
    }
  }

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_attr');
    Hive.init(tempDir.path);
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
    categories = CategoryRepository();
    transactions = TransactionRepository();
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('the resolver', () {
    test('T1: a back-dated expense lands in ITS month\'s same-named category',
        () async {
      await categories.addCategories([
        category(id: 'food-jul', name: 'Food', month: july),
        category(id: 'food-aug', name: 'Food', month: august),
      ]);
      final pickedInAugust = (await categories.getCategoriesForMonth(august))
          .firstWhere((c) => c.id == 'food-aug');

      final resolved = await categories.resolveForMonth(pickedInAugust, july);

      expect(resolved.category.id, 'food-jul');
      expect(resolved.pickedWasDeleted, isFalse);
      expect(store.readCategories().length, 2, reason: 'no new clone needed');

      await transactions.addTransaction(transaction(
          id: 't1',
          categoryId: resolved.category.id,
          date: DateTime(2026, 7, 14),
          amountMinor: 250000));
      expectInvariant(july);
      expectInvariant(august);
      expect(dashboardFor(august).totalSpentMinor, 0,
          reason: "the month the user was viewing must not count it");
      expect(dashboardFor(july).totalSpentMinor, 250000);
    });

    test('T2: same-month pick is a fast path — resolved, nothing written',
        () async {
      await categories.addCategory(
          category(id: 'food-aug', name: 'Food', month: august));
      final picked = store.readCategories().single;

      final resolved = await categories.resolveForMonth(picked, august);

      expect(resolved.category.id, 'food-aug');
      expect(store.readCategories().length, 1);
      expect(store.readCategories().single.updatedAt, picked.updatedAt);
    });

    test('T3: back-dating into an unvisited month clones the WHOLE structure',
        () async {
      await categories.addCategories([
        for (final name in ['Food', 'Transport', 'Housing'])
          category(id: '$name-aug', name: name, month: august),
      ]);
      final picked = store.readCategories().firstWhere((c) => c.name == 'Food');

      final resolved = await categories.resolveForMonth(picked, july);

      final julyCats = await categories.getCategoriesForMonth(july);
      expect(julyCats.map((c) => c.name).toSet(),
          {'Food', 'Transport', 'Housing'},
          reason: 'AC-6: the whole month is created, not one lonely row');
      expect(resolved.category.month, july);
      expect(resolved.category.name, 'Food');
      expect(julyCats.map((c) => c.id), isNot(contains('Food-aug')));
    });

    test('T3b: beyond the 13-month walk it degrades to ONE back-fill clone',
        () async {
      await categories.addCategories([
        for (final name in ['Food', 'Transport', 'Housing'])
          category(id: '$name-aug', name: name, month: august),
      ]);
      final picked = store.readCategories().firstWhere((c) => c.name == 'Food');

      final resolved = await categories.resolveForMonth(picked, '2024-01');

      final old = await categories.getCategoriesForMonth('2024-01');
      expect(old.length, 1, reason: 'no source month within the walk');
      expect(old.single.name, 'Food');
      expect(resolved.category.id, old.single.id);
      expect(old.single.budgetLimitMinor, 0, reason: 'FD-1: back-fill is 0');
    });

    test('T4: the name match is trimmed and case-insensitive', () async {
      await categories.addCategories([
        category(id: 'food-jul', name: 'FOOD ', month: july),
        category(id: 'food-aug', name: ' food', month: august),
      ]);
      final picked =
          store.readCategories().firstWhere((c) => c.id == 'food-aug');

      final resolved = await categories.resolveForMonth(picked, july);

      expect(resolved.category.id, 'food-jul');
      expect(store.readCategories().length, 2);
    });

    test('T5: when a month holds duplicates, the oldest createdAt wins',
        () async {
      await categories.addCategories([
        category(
            id: 'food-jul-new',
            name: 'Food',
            month: july,
            createdAt: DateTime(2026, 7, 20)),
        category(
            id: 'food-jul-old',
            name: 'Food',
            month: july,
            createdAt: DateTime(2026, 7, 2)),
        category(id: 'food-aug', name: 'Food', month: august),
      ]);
      final picked =
          store.readCategories().firstWhere((c) => c.id == 'food-aug');

      final resolved = await categories.resolveForMonth(picked, july);

      expect(resolved.category.id, 'food-jul-old');
    });

    test('T6: FD-1 — back-fill into a past month carries 0, into the current '
        'month carries the limit', () async {
      await categories.addCategory(category(
          id: 'gym-aug', name: 'Gym', month: august, limitMinor: 500000));
      final picked = store.readCategories().single;

      // A past month: the app must not invent a budget for a month that has
      // already happened. Another category exists in July, so the whole-month
      // ensure is a no-op and this is the single-clone path.
      await categories.addCategory(
          category(id: 'other-jul', name: 'Rent', month: july));
      final backfill = await categories.resolveForMonth(picked, july,
          nowMonthKey: () => august);
      expect(backfill.category.budgetLimitMinor, 0);

      // The current month is contemporaneous: the limit is real there.
      await categories.addCategory(
          category(id: 'other-sep', name: 'Rent', month: september));
      final contemporaneous = await categories
          .resolveForMonth(picked, september, nowMonthKey: () => september);
      expect(contemporaneous.category.budgetLimitMinor, 500000);
    });

    test('T8: no category selected lands in the bucket of the DATE-month',
        () async {
      // The 4th path adil confirmed: the old auto-"Other" used the VIEWED
      // month, so browsing July and dating August broke INV-1 in August.
      final resolved = await categories.resolveForMonth(null, august);

      expect(resolved.category.name, kUncategorisedCategoryName);
      expect(resolved.category.month, august);
      expect(resolved.category.budgetLimitMinor, 0);
      expect(await categories.getCategoriesForMonth(july), isEmpty,
          reason: 'the viewed month is never involved in attribution');

      // Second uncategorised save in the same month reuses the one bucket.
      final again = await categories.resolveForMonth(null, august);
      expect(again.category.id, resolved.category.id);
      expect(store.readCategories().length, 1);
    });

    test('T12: a category deleted while the sheet was open is never '
        'resurrected', () async {
      await categories
          .addCategory(category(id: 'gym-aug', name: 'Gym', month: august));
      final stale = store.readCategories().single;
      await categories.deleteCategory('gym-aug');

      final resolved = await categories.resolveForMonth(stale, august);

      expect(resolved.pickedWasDeleted, isTrue);
      expect(resolved.category.name, kUncategorisedCategoryName);
      expect(store.readCategories().any((c) => c.id == 'gym-aug'), isFalse);
    });

    test('T13: a back-filled clone keeps createdAt ≠ its month (provenance)',
        () async {
      await categories.addCategories([
        category(id: 'food-aug', name: 'Food', month: august),
        category(id: 'rent-jul', name: 'Rent', month: july),
      ]);
      final picked =
          store.readCategories().firstWhere((c) => c.id == 'food-aug');

      final resolved = await categories.resolveForMonth(picked, july);

      // The ONLY forensic trail that a category was back-filled rather than
      // budgeted at the time. Do not "tidy" this into the target month.
      expect(resolved.category.month, july);
      expect(AppDateUtils.getMonthKeyFromDate(resolved.category.createdAt),
          isNot(july));
    });
  });

  /// BUG-120 — FD-1 is a rule about DIRECTION, not about which function does
  /// the cloning: "forward rollover clones carry limits; backward back-fill
  /// does not". It shipped on `resolveForMonth`'s single back-fill (T6) and was
  /// missing from `ensureMonth`'s whole-month clone, so merely tapping '‹' into
  /// an unvisited past month handed that month a complete budget structure the
  /// user never set (live: `₨0 / ₨9,000` rows in a month that had never been
  /// budgeted). The manifest missed it because T3 asserted WHICH rows a
  /// backward ensure creates, never with WHAT limit.
  group('FD-1 clone direction (BUG-120)', () {
    test('a backward whole-month ensure carries names/colours/icons but NOT '
        'limits', () async {
      await categories.addCategories([
        category(id: 'food-aug', name: 'Food', month: august, limitMinor: 900000),
        category(id: 'rent-aug', name: 'Rent', month: august, limitMinor: 3750000),
        category(
            id: 'gym-aug',
            name: 'Gym',
            month: august,
            limitMinor: 500000,
            colorValue: 0xFFB4471F),
      ]);

      // What the dashboard's '‹' handler does, with the clock injected.
      await categories.ensureMonth(july, nowMonthKey: () => august);

      final julyCats = await categories.getCategoriesForMonth(july);
      expect(julyCats.map((c) => c.name).toSet(), {'Food', 'Rent', 'Gym'});
      expect(julyCats.map((c) => c.budgetLimitMinor).toSet(), {0},
          reason: 'FD-1: a month that already happened gains no budget');
      final gym = julyCats.firstWhere((c) => c.name == 'Gym');
      expect(gym.colorValue, 0xFFB4471F, reason: 'identity still carried');
      expect(gym.iconCodePoint, 0xe56c);
      expect(gym.id, isNot('gym-aug'), reason: 'clones get fresh ids');
    });

    test('a forward whole-month ensure still carries limits — F-02 untouched',
        () async {
      await categories.addCategories([
        category(id: 'food-jul', name: 'Food', month: july, limitMinor: 900000),
        category(id: 'rent-jul', name: 'Rent', month: july, limitMinor: 3750000),
      ]);

      // The current month: the rollover F-02 AC-1 promises.
      await categories.ensureMonth(august, nowMonthKey: () => august);
      final augustCats = await categories.getCategoriesForMonth(august);
      expect(
          augustCats.map((c) => c.budgetLimitMinor).toList()..sort(),
          [900000, 3750000],
          reason: 'forward rollover carries limits (F-02 rule 1)');

      // And ahead of it: still forward, still carried.
      await categories.ensureMonth(september, nowMonthKey: () => august);
      final septemberCats = await categories.getCategoriesForMonth(september);
      expect(
          septemberCats.map((c) => c.budgetLimitMinor).toList()..sort(),
          [900000, 3750000],
          reason: 'a month that has not happened yet is not a back-fill');
    });

    test('both clone paths agree in one past month: nine rows or one, all 0',
        () async {
      // The live BUG-120 shape: an August structure, a Cricket category that
      // only exists in August, and a ₨100 expense dated into a July nobody has
      // visited. Path (ii) creates July wholesale; the row the transaction
      // lands on is one of those clones.
      await categories.addCategories([
        for (final name in ['Food', 'Rent', 'Transport'])
          category(id: '$name-aug', name: name, month: august, limitMinor: 900000),
        category(
            id: 'cricket-aug', name: 'Cricket', month: august, limitMinor: 200000),
      ]);
      final cricket =
          store.readCategories().firstWhere((c) => c.id == 'cricket-aug');

      final resolved = await categories.resolveForMonth(cricket, july,
          nowMonthKey: () => august);

      expect(resolved.category.budgetLimitMinor, 0,
          reason: 'the row a back-dated expense lands on claims no budget');
      final julyCats = await categories.getCategoriesForMonth(july);
      expect(julyCats.length, 4, reason: 'AC-6: the whole structure, not one row');
      expect(julyCats.map((c) => c.budgetLimitMinor).toSet(), {0});

      // Now the OTHER path in the same month: July is populated, so a category
      // absent from it takes the single back-fill branch.
      await categories.addCategory(category(
          id: 'gym-aug', name: 'Gym', month: august, limitMinor: 500000));
      final gym = store.readCategories().firstWhere((c) => c.id == 'gym-aug');
      final backfilled = await categories.resolveForMonth(gym, july,
          nowMonthKey: () => august);
      expect(backfilled.category.budgetLimitMinor, 0);
      expect((await categories.getCategoriesForMonth(july)).length, 5);

      // The point of the whole feature still holds in both months.
      await transactions.addTransaction(transaction(
          id: 'bug120',
          categoryId: resolved.category.id,
          date: DateTime(2026, 7, 15),
          amountMinor: 10000));
      expectInvariant(july, because: 'the back-dated ₨100 must be enumerable');
      expectInvariant(august);
      expectStructuralCorollary();
      expect(dashboardFor(july).totalSpentMinor, 10000);
      expect(dashboardFor(august).totalSpentMinor, 0);
    });

    test('August keeps its own limits when July is filled in behind it',
        () async {
      await categories.addCategory(category(
          id: 'cricket-aug', name: 'Cricket', month: august, limitMinor: 200000));
      final cricket = store.readCategories().single;

      await categories.resolveForMonth(cricket, july, nowMonthKey: () => august);

      final augustCats = await categories.getCategoriesForMonth(august);
      expect(augustCats.single.id, 'cricket-aug');
      expect(augustCats.single.budgetLimitMinor, 200000,
          reason: 'a back-fill must not reach back into the source month');
    });
  });

  group('the reserved bucket', () {
    test('T7: deleting a category re-points its transactions to the bucket of '
        'each transaction\'s own month, then deletes', () async {
      await categories
          .addCategory(category(id: 'gym-aug', name: 'Gym', month: august));
      await transactions.addTransaction(transaction(
          id: 'aug-tx',
          categoryId: 'gym-aug',
          date: DateTime(2026, 8, 9),
          amountMinor: 150000));
      // A back-dated one, already attributed to July by an earlier save.
      await categories.addCategory(
          category(id: 'gym-jul', name: 'Gym', month: july));
      await transactions.addTransaction(transaction(
          id: 'jul-tx',
          categoryId: 'gym-jul',
          date: DateTime(2026, 7, 3),
          amountMinor: 90000));

      final augustSpentBefore = dashboardFor(august).totalSpentMinor;
      await categories.deleteCategory('gym-aug');

      expect(store.readCategories().any((c) => c.id == 'gym-aug'), isFalse);
      expect(store.readTransactions().length, 2, reason: 'nothing lost');
      expect(dashboardFor(august).totalSpentMinor, augustSpentBefore,
          reason: 'AC-3: the month total is unchanged by a delete');

      final augustRows = await categories.getCategoriesForMonth(august);
      expect(augustRows.single.name, kUncategorisedCategoryName);
      expect(store.readTransactions().firstWhere((t) => t.id == 'aug-tx')
          .categoryId, augustRows.single.id);

      expectInvariant(august);
      expectStructuralCorollary();

      // July's category is untouched — only the deleted one's rows move.
      expect(store.readTransactions().firstWhere((t) => t.id == 'jul-tx')
          .categoryId, 'gym-jul');
    });

    test('T7b: transactions spread across months each go to their OWN month\'s '
        'bucket', () async {
      await categories
          .addCategory(category(id: 'gym-aug', name: 'Gym', month: august));
      await transactions.addTransaction(transaction(
          id: 'a', categoryId: 'gym-aug', date: DateTime(2026, 8, 9)));
      await transactions.addTransaction(transaction(
          id: 'b', categoryId: 'gym-aug', date: DateTime(2026, 7, 9)));

      await categories.deleteCategory('gym-aug');

      final buckets = store
          .readCategories()
          .where((c) => isReservedCategoryName(c.name))
          .toList();
      expect(buckets.map((c) => c.month).toSet(), {july, august});
      expectStructuralCorollary();
      expectInvariant(july);
      expectInvariant(august);
    });

    test('T7c: re-point runs FIRST — a failure loses nothing', () async {
      // The order is the guarantee: with the box closed, the whole operation
      // throws and both the category and its transaction are still there.
      await categories
          .addCategory(category(id: 'gym-aug', name: 'Gym', month: august));
      await transactions.addTransaction(transaction(
          id: 'tx', categoryId: 'gym-aug', date: DateTime(2026, 8, 9)));

      await Hive.box<Category>(LocalStoreService.categoriesBoxName).close();

      await expectLater(categories.deleteCategory('gym-aug'), throwsA(anything));

      final reopened = await LocalStoreService().init();
      expect(reopened.readCategories().any((c) => c.id == 'gym-aug'), isTrue);
      expect(reopened.readTransactions().single.categoryId, 'gym-aug');
    });

    test('T9: the bucket is never cloned forward by the month ensure',
        () async {
      await categories
          .addCategory(category(id: 'food-aug', name: 'Food', month: august));
      await categories.ensureUncategorised(august);

      await categories.ensureMonth(september);

      final sept = await categories.getCategoriesForMonth(september);
      expect(sept.map((c) => c.name), ['Food']);
    });

    test('T10: a month holding ONLY the bucket still re-populates', () async {
      // Without a reserved-aware emptiness check, deleting a month's last real
      // category freezes that month empty forever.
      await categories.addCategories([
        category(id: 'food-jul', name: 'Food', month: july),
        category(id: 'rent-jul', name: 'Rent', month: july),
      ]);
      await categories.ensureUncategorised(august);

      await categories.ensureMonth(august);

      final aug = await categories.getCategoriesForMonth(august);
      expect(aug.map((c) => c.name).toSet(),
          {'Food', 'Rent', kUncategorisedCategoryName});
    });

    test('T11: the bucket is pickable, un-renamable and un-deletable',
        () async {
      final bucket = await categories.ensureUncategorised(august);

      // Pickable: the add-sheet's list is exactly this month filter.
      expect((await categories.getCategoriesForMonth(august)).map((c) => c.id),
          contains(bucket.id));

      await expectLater(categories.deleteCategory(bucket.id),
          throwsA(isA<ReservedCategoryException>()));
      expect(store.readCategories().any((c) => c.id == bucket.id), isTrue);

      await expectLater(
          categories.updateCategory(category(
              id: bucket.id, name: 'Renamed', month: august)),
          throwsA(isA<ReservedCategoryException>()));

      await expectLater(
          categories.addCategory(category(
              id: 'x', name: ' uncategorised ', month: august)),
          throwsA(isA<ReservedCategoryException>()),
          reason: 'no second bucket, whatever the spelling');

      await categories
          .addCategory(category(id: 'food', name: 'Food', month: august));
      await expectLater(
          categories.updateCategory(category(
              id: 'food', name: kUncategorisedCategoryName, month: august)),
          throwsA(isA<ReservedCategoryException>()),
          reason: 'and no renaming into the reserved name');

      // Re-colouring it IS allowed — only the name is reserved.
      await categories.updateCategory(category(
          id: bucket.id,
          name: kUncategorisedCategoryName,
          month: august,
          limitMinor: 0,
          colorValue: 0xFF123456));
      expect(
          store.readCategories().firstWhere((c) => c.id == bucket.id).colorValue,
          0xFF123456);
    });

    test('concurrent bucket creation yields ONE bucket', () async {
      final both = await Future.wait([
        categories.ensureUncategorised(august),
        categories.ensureUncategorised(august),
      ]);

      expect(both[0].id, both[1].id);
      expect((await categories.getCategoriesForMonth(august)).length, 1);
    });
  });

  group('the form date default (path A′)', () {
    final now = DateTime(2026, 8, 17, 14, 30);

    test('viewing the current month keeps today', () {
      expect(TransactionFormController.defaultDateForMonth('2026-08', now),
          now);
    });

    test('viewing a past month starts on the 1st of that month', () {
      expect(TransactionFormController.defaultDateForMonth('2026-07', now),
          DateTime(2026, 7, 1));
      expect(TransactionFormController.defaultDateForMonth('2025-12', now),
          DateTime(2025, 12, 1));
    });

    test('viewing a future month keeps today (the chevron is unbounded)', () {
      // adil's gap: goToNextMonth is only view-gated, and F-02's resume hook
      // adds a second caller — a future month must not default to its 1st.
      expect(TransactionFormController.defaultDateForMonth('2026-09', now),
          now);
    });

    test('an unparseable stored month falls back to today', () {
      expect(TransactionFormController.defaultDateForMonth('not-a-month', now),
          now);
    });
  });

  group('INV-1 holds under a random walk', () {
    test('200 seeded operations through the shipped write paths', () async {
      // Seeded so a failure is reproducible. Every operation goes through the
      // code the app calls; the invariant is then read through the shipped
      // controller getters, so this test cannot drift away from the app.
      final random = Random(42);
      const months = ['2026-05', '2026-06', '2026-07', '2026-08', '2026-09'];
      const currentMonth = '2026-08';

      await categories.addCategories([
        for (final name in ['Food', 'Transport', 'Housing'])
          category(id: '$name-seed', name: name, month: currentMonth),
      ]);

      var txCounter = 0;
      var catCounter = 0;

      for (var step = 0; step < 200; step++) {
        final roll = random.nextInt(100);
        final month = months[random.nextInt(months.length)];
        final date = DateTime(int.parse(month.split('-')[0]),
            int.parse(month.split('-')[1]), 1 + random.nextInt(28));

        if (roll < 55) {
          // Save a transaction: sometimes with a category picked from a
          // DIFFERENT month (the back-dating path), sometimes with none.
          final all = store.readCategories();
          final picked = all.isEmpty || random.nextInt(5) == 0
              ? null
              : all[random.nextInt(all.length)];
          final resolved = await categories.resolveForMonth(
              picked, AppDateUtils.getMonthKeyFromDate(date),
              nowMonthKey: () => currentMonth);
          await transactions.addTransaction(transaction(
            id: 'tx-${txCounter++}',
            categoryId: resolved.category.id,
            date: date,
            amountMinor: 100 + random.nextInt(500000),
          ));
        } else if (roll < 70) {
          // Add a user category to some month.
          await categories.addCategory(category(
            id: 'cat-${catCounter++}',
            name: ['Food', 'Gym', 'Coffee', 'Rent'][random.nextInt(4)],
            month: month,
            createdAt: DateTime(2026, 8, 1).add(Duration(minutes: step)),
          ));
        } else if (roll < 85) {
          // Delete a user category (the orphan path).
          final deletable = store
              .readCategories()
              .where((c) => !isReservedCategoryName(c.name))
              .toList();
          if (deletable.isNotEmpty) {
            await categories
                .deleteCategory(deletable[random.nextInt(deletable.length)].id);
          }
        } else {
          // Browse to a month (the chevron / launch-roll path).
          await categories.ensureMonth(month);
        }

        for (final m in months) {
          expectInvariant(m, because: 'after step $step (roll $roll)');
        }
        expectStructuralCorollary();
      }

      // The walk has to have actually exercised the machinery.
      expect(store.readTransactions().length, greaterThan(50));
      expect(
          store.readCategories().any((c) => isReservedCategoryName(c.name)),
          isTrue,
          reason: 'deletes should have produced at least one bucket');
    });
  });
}
