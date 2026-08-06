import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/utils/category_order.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/categories/categories_controller.dart';
import 'package:budget_buddy/modules/categories/categories_view.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-09 AC-5 — every FULL list of categories is ordered by name, with the
/// reserved bucket last (BUG-R2-main-01).
///
/// The AC was restated on 2026-08-04 (D-003) and named the file that would hold
/// the comparator; no ticket was cut, so the file did not exist and the
/// Categories tab applied no sort at all — it fell through to the store's
/// `createdAt`-descending emission, which for one month's clones (one batch,
/// one timestamp) is arbitrary. On the device that read as: Uncategorised,
/// Health, Transportation, Housing, … The picker had the right comparator all
/// along, as a private static on its own controller — so this file also guards
/// the "single-sourced" half of the AC, which is the half that would rot
/// silently.
///
/// The dashboard preview is deliberately NOT covered here: it sorts by budget
/// pressure (F-09 AC-4) and `dashboard_order_test.dart` owns it.
void main() {
  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final nextMonth = AppDateUtils.getNextMonthKey(thisMonth);

  Category cat({
    required String id,
    required String name,
    String? month,
    int limitMinor = 500000,
    DateTime? createdAt,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: limitMinor,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: month ?? thisMonth,
        createdAt: createdAt ?? DateTime(2026, 1, 1, 9),
        updatedAt: createdAt ?? DateTime(2026, 1, 1, 9),
      );

  group('the comparator', () {
    test('AC-5: ascending by name, trimmed and case-folded, bucket last', () {
      // Deliberately scrambled input, and deliberately awkward names: leading
      // and trailing spaces, mixed case, and a bucket whose own name sorts
      // BEFORE "Zoo" alphabetically — so "last" can only come from the reserved
      // rule and not from the letters.
      final ordered = CategoryOrder.sortedByName([
        cat(id: 'z', name: '  Zoo'),
        cat(id: 'u', name: kUncategorisedCategoryName),
        cat(id: 'b', name: 'banana  '),
        cat(id: 'a', name: 'apples'),
        cat(id: 'f', name: 'Food'),
      ]);

      expect(ordered.map((c) => c.name).toList(), [
        'apples',
        'banana  ',
        'Food',
        '  Zoo',
        kUncategorisedCategoryName,
      ]);
    });

    test('one answer whatever order the store emits', () {
      // What the old newest-first list could not promise: the same set in any
      // input order produces one output.
      final bucket = cat(id: 'bucket', name: kUncategorisedCategoryName);
      final food = cat(id: 'f', name: 'Food');
      final apples = cat(id: 'a', name: 'apples');
      final zoo = cat(id: 'z', name: 'Zoo');

      for (final input in [
        [bucket, food, apples, zoo],
        [zoo, apples, food, bucket],
        [food, bucket, zoo, apples],
        [apples, zoo, bucket, food],
      ]) {
        expect(CategoryOrder.sortedByName(input).map((c) => c.id).toList(),
            ['a', 'f', 'z', 'bucket']);
      }
    });

    test('a name tie is broken by id, so the order is TOTAL', () {
      // F-08 forbids two categories of one name in a month, but a box written
      // before that rule can hold them — and `List.sort` is not stable, so
      // without the id tail the two rows could swap between rebuilds.
      final ordered = CategoryOrder.sortedByName([
        cat(id: 'zzz', name: 'Food'),
        cat(id: 'aaa', name: 'Food'),
        cat(id: 'mmm', name: 'food'),
      ]);

      expect(ordered.map((c) => c.id).toList(), ['aaa', 'mmm', 'zzz']);
    });

    test('the bucket is recognised however it is cased or spaced', () {
      // The bucket's stored name is a plain string; the reserved test is the
      // trimmed, case-folded one the whole app uses (`isReservedCategoryName`).
      final ordered = CategoryOrder.sortedByName([
        cat(id: 'u', name: '  UNCATEGORISED '),
        cat(id: 'z', name: 'Zoo'),
        cat(id: 'a', name: 'Apples'),
      ]);

      expect(ordered.map((c) => c.id).toList(), ['a', 'z', 'u']);
    });

    test('sorting returns a COPY — the list handed in is never touched', () {
      // Both callers pass a list derived from an RxList read inside an Obx.
      // Sorting in place there is a rebuild loop (F-09 §5), so the guarantee
      // belongs to the comparator's own API, not to each call site.
      final input = [
        cat(id: 'z', name: 'Zoo'),
        cat(id: 'a', name: 'apples'),
      ];

      final ordered = CategoryOrder.sortedByName(input);

      expect(input.map((c) => c.id).toList(), ['z', 'a'],
          reason: 'the input must be exactly as it was handed over');
      expect(ordered.map((c) => c.id).toList(), ['a', 'z']);
      expect(identical(ordered, input), isFalse);
    });
  });

  group('the surfaces that list categories', () {
    late Directory tempDir;
    late CategoryRepository categories;
    late TransactionRepository transactions;
    late SettingsService settings;

    /// The month's user categories, seeded NEWEST-FIRST in the wrong order on
    /// purpose: the store emits by `createdAt` descending, so an unsorted
    /// screen shows exactly this list, and any test below that passes has
    /// proved the sort ran rather than that the fixture happened to be
    /// alphabetical.
    ///
    /// Alphabetically: apples, Food, Transport, Zoo, then the bucket — which is
    /// minted separately by [seedMonth] because `addCategories` refuses the
    /// reserved name outright (only `ensureUncategorised` may create it).
    List<Category> userCategoriesFor(String month) => [
          cat(
              id: 'zoo-$month',
              name: 'Zoo',
              month: month,
              createdAt: DateTime(2026, 1, 4, 9)),
          cat(
              id: 'food-$month',
              name: 'Food',
              month: month,
              createdAt: DateTime(2026, 1, 3, 9)),
          cat(
              id: 'transport-$month',
              name: '  Transport  ',
              month: month,
              createdAt: DateTime(2026, 1, 2, 9)),
          cat(
              id: 'apples-$month',
              name: 'apples',
              month: month,
              createdAt: DateTime(2026, 1, 1, 9)),
        ];

    /// One month's worth of fixture. The bucket goes in LAST, so it carries the
    /// newest `createdAt` of the set and the store emits it FIRST — which is
    /// precisely what the device showed (BUG-R2-main-01: "Uncategorised" at the
    /// top of the tab), and what the comparator has to undo.
    Future<void> seedMonth(String month) async {
      await categories.addCategories(userCategoriesFor(month));
      await categories.ensureUncategorised(month);
    }

    /// Names, not ids: the bucket's id is minted inside the repository, and the
    /// names are what a reader of the AC would write down off the screen.
    const expectedNames = [
      'apples',
      'Food',
      '  Transport  ',
      'Zoo',
      kUncategorisedCategoryName,
    ];

    List<String> namesOf(Iterable<Category> list) =>
        list.map((c) => c.name).toList(growable: false);

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_catorder');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      categories = Get.put(CategoryRepository());
      transactions = Get.put(TransactionRepository());
      settings = Get.put(SettingsService());
      await settings.setCurrency('PKR', '₨');
      await settings.setCurrentMonth(thisMonth);
      await seedMonth(thisMonth);
      Get.testMode = true;
    });

    tearDown(() async {
      Get.testMode = false;
      Get.reset();
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// A controller with its first stream emission delivered. Plain `test`s run
    /// on the real clock, so a short delay is all a Hive read needs.
    Future<CategoriesController> openTab() async {
      final ctrl = Get.put(CategoriesController(
        categoryRepo: categories,
        transactionRepo: transactions,
        settings: settings,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ctrl;
    }

    test('AC-5(i): the Categories tab lists the month by name, bucket last',
        () async {
      final ctrl = await openTab();

      expect(namesOf(ctrl.filtered), expectedNames);
    });

    test('AC-5(ii): the rule survives a month change', () async {
      // A second code path entirely: the month switch re-reads through
      // `ever(settings.currentMonth)`, not through the stream listener. A sort
      // applied on one path only would pass the case above and fail here.
      await seedMonth(nextMonth);
      final ctrl = await openTab();

      await settings.setCurrentMonth(nextMonth);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(ctrl.categories.every((c) => c.month == nextMonth), isTrue,
          reason: 'the month filter must still be doing its job');
      expect(namesOf(ctrl.filtered), expectedNames);
    });

    test('AC-5(iii): going over budget does not move a category', () async {
      final ctrl = await openTab();
      expect(namesOf(ctrl.filtered), expectedNames);

      // Zoo is last-but-the-bucket alphabetically and now the most pressured
      // category in the month. On the dashboard preview that would send it to
      // the top (AC-4); on this tab the ratio is not a sort key at all.
      await transactions.addTransaction(TransactionItem(
        id: 'tx-1',
        categoryId: 'zoo-$thisMonth',
        amountMinor: 900000, // 180% of the 500000 limit
        note: 'Snow leopard adoption',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(ctrl.spentForCategoryMinor('zoo-$thisMonth'), 900000,
          reason: 'the fixture must actually be over budget');
      expect(namesOf(ctrl.filtered), expectedNames);
    });

    test('a search narrows the list without reordering it', () async {
      final ctrl = await openTab();

      ctrl.searchQuery.value = 'o';

      // Food, Transport, Zoo and the bucket all contain an "o"; apples does
      // not. The survivors keep their places.
      expect(namesOf(ctrl.filtered), [
        'Food',
        '  Transport  ',
        'Zoo',
        kUncategorisedCategoryName,
      ]);
    });

    test('AC-5: the Add picker and the Categories tab agree, one comparator',
        () async {
      // The "single-sourced" clause, tested as a behaviour rather than as an
      // import: two independent controllers, one store, one order.
      final tab = await openTab();
      final picker = Get.put(TransactionFormController(
        categoryRepo: categories,
        transactionRepo: transactions,
        settings: settings,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(namesOf(picker.categories), expectedNames);
      expect(namesOf(picker.categories), namesOf(tab.filtered));
    });

    testWidgets('AC-5: the rendered cards are in that order, top to bottom',
        (tester) async {
      // The order is the whole point of this fix, and it is a VISUAL property:
      // a list assertion on the controller cannot see a view that re-sorts, and
      // `find.text` alone resolves off-screen widgets, so the assertion is on Y
      // offsets (the lesson `dashboard_order_test.dart` was written for).
      //
      // A viewport tall enough to build all five cards — `ListView.builder` is
      // lazy, so an off-screen card is not merely invisible, it does not exist.
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // NOT `openTab()`: its 20 ms settle is a real-clock delay, and awaiting
      // one inside `testWidgets` deadlocks against the fake async clock (it
      // costs the full 10-minute default, measured). The fixture is already on
      // disk from `setUp`, so the controller is registered synchronously here
      // and the store's first emission arrives on the pump below.
      Get.put(CategoriesController(
        categoryRepo: categories,
        transactionRepo: transactions,
        settings: settings,
      ));
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const CategoriesView(),
      ));
      // Settles the staggered entrance; until it ends each row sits under a
      // Transform.translate and a Y reading would measure the animation.
      await tester.pumpAndSettle();

      double topOf(String name) {
        final finder = find.text(name);
        expect(finder, findsOneWidget, reason: '"$name" must be on screen');
        return tester.getTopLeft(finder).dy;
      }

      // Trimmed in the comparator, but rendered verbatim — the card shows the
      // stored name, spaces and all.
      final ys = [
        topOf('apples'),
        topOf('Food'),
        topOf('  Transport  '),
        topOf('Zoo'),
        topOf(kUncategorisedCategoryName),
      ];

      expect(ys, orderedEquals(<double>[...ys]..sort()),
          reason: 'cards must descend the screen in the comparator\'s order; '
              'measured tops: $ys');
    });
  });
}
