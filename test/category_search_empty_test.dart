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

/// BUG-002 — a search that matched nothing claimed the app was empty.
///
/// Typing a string no category answers to replaced the list with the FIRST-RUN
/// empty state: "No categories yet / Tap + to create your first budget
/// category" and a filled Add Category button — all of it false with eleven
/// categories on file, and the button aimed the user at creating a duplicate of
/// whatever the search had merely failed to match (a typo'd "Fod" invites a
/// second Food).
///
/// The two states are tested together on purpose: the genuine first-run one has
/// to survive untouched, because it is the only place that copy IS true.
///
/// NOTE: Hive writes are real disk I/O, so they go through `tester.runAsync` —
/// awaiting them directly inside `testWidgets` deadlocks the fake clock.
void main() {
  group('the words (pure)', () {
    test('the no-results title names what was searched for', () {
      expect(CategoriesController.searchEmptyTitleFor('gym'),
          'No categories match "gym"');
      expect(CategoriesController.searchEmptyTitleFor('  Fod  '),
          'No categories match "Fod"',
          reason: 'the quoted text is what the user meant, not their spacing');
    });

    test('a whitespace-only query is still a search', () {
      // Nothing worth quoting, but the state is a search result and must not
      // fall back to the first-run copy — that IS the bug.
      expect(CategoriesController.searchEmptyTitleFor('   '),
          'No categories match your search');
      expect(CategoriesController.searchEmptyTitleFor(''),
          'No categories match your search');
    });

    test('neither line instructs, invites or promises a first category', () {
      final both = '${CategoriesController.searchEmptyTitleFor('gym')} '
              '${CategoriesController.searchEmptyLine}'
          .toLowerCase();
      expect(both, isNot(contains('+')));
      expect(both, isNot(contains('button')));
      expect(both, isNot(contains('first')));
      expect(both, isNot(contains('yet')),
          reason: '"No categories yet" is the claim that was false');
      expect(CategoriesController.searchEmptyLine, 'Try a different search.');
    });
  });

  group('the screen shows the right nothing', () {
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_catsearch');
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

    final now = DateTime.now();
    final month = AppDateUtils.monthKey(now);

    Category category(String id, String name) => Category(
          id: id,
          name: name,
          budgetLimitMinor: 100000,
          colorValue: 0xFF3498DB,
          month: month,
          createdAt: now,
          updatedAt: now,
        );

    /// The tab as the user meets it, with [seed] already on file.
    Future<void> pumpTab(WidgetTester tester,
        {List<Category> seed = const []}) async {
      if (seed.isNotEmpty) {
        await tester
            .runAsync(() => Get.find<CategoryRepository>().addCategories(seed));
      }
      Get.put(CategoriesController(
        categoryRepo: Get.find<CategoryRepository>(),
        transactionRepo: Get.find<TransactionRepository>(),
        settings: Get.find<SettingsService>(),
      ));
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const CategoriesView(),
      ));
      // Fixed pumps, not pumpAndSettle: the rows animate in on a staggered
      // delay and these tests care about the words, not the motion.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('a search that matches nothing names the search and offers no '
        'way to create', (tester) async {
      await pumpTab(tester,
          seed: [category('c1', 'Food'), category('c2', 'Transport')]);
      expect(find.text('Food'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ZZ');
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No categories match "ZZ"'), findsOneWidget);
      expect(find.text('Try a different search.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      expect(find.text('No categories yet'), findsNothing,
          reason: 'two categories are on file — the claim was simply untrue');
      expect(find.text('Tap + to create your first budget category'),
          findsNothing);
      expect(find.widgetWithText(FilledButton, 'Add Category'), findsNothing,
          reason: 'the button invited a duplicate of the category the search '
              'had failed to match (BUG-002)');
    });

    testWidgets('clearing the query brings the list back', (tester) async {
      await pumpTab(tester, seed: [category('c1', 'Food')]);

      await tester.enterText(find.byType(TextField), 'ZZ');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Food'), findsNothing);

      // The × the muted line points at.
      await tester.tap(find.byIcon(Icons.clear));
      // Twice: a pump advances the clock and THEN builds, so the returning
      // row's staggered entrance timer is created by the first frame and only
      // fires on the second. A test that leaves it pending fails on teardown.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Food'), findsOneWidget);
      expect(find.textContaining('No categories match'), findsNothing);
    });

    testWidgets('the genuine first run is untouched — copy and CTA both stay',
        (tester) async {
      await pumpTab(tester);

      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('Tap + to create your first budget category'),
          findsOneWidget,
          reason: 'the + this names is the app bar action, which IS on this '
              'screen — unlike BUG-021\'s pushed list');
      expect(find.widgetWithText(FilledButton, 'Add Category'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsNothing);
      expect(find.textContaining('No categories match'), findsNothing);
    });
  });
}
