import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/predefined_categories.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/home/home_controller.dart';
import 'package:budget_buddy/modules/splash/splash_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-02 — the categories of a new month exist before the user sees the month.
///
/// Every launch already rolled the stored month forward; only the two month
/// chevrons ever cloned categories into a month. So on the 1st, the app opened
/// to "No categories yet", the Spending Breakdown vanished, and the repair was
/// an undocumented ‹ then ›.
///
/// Tested through the two shipped call sites — `SplashController.prepareForHome`
/// (launch) and `HomeController.handleResume` (warm app) — rather than through a
/// helper of the test's own, so a call site that stops rolling or stops
/// ensuring fails here.
///
/// Month-key based throughout: not one test reads the wall clock, because a
/// test that only passes in some months is not a test.
void main() {
  late Directory tempDir;
  late LocalStoreService store;
  late CategoryRepository categories;
  late SettingsService settings;

  const july = '2026-07';
  const august = '2026-08';

  Category category({
    required String id,
    required String name,
    required String month,
    int limitMinor = 10000,
  }) {
    final stamp = DateTime(2026, 7, 1, 9);
    return Category(
      id: id,
      name: name,
      budgetLimitMinor: limitMinor,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: 0xe56c,
      month: month,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  Future<void> seedJuly() => categories.addCategories([
        category(id: 'food', name: 'Food', month: july, limitMinor: 2250000),
        category(id: 'rent', name: 'Rent', month: july, limitMinor: 3750000),
        category(id: 'gym', name: 'Gym', month: july, limitMinor: 500000),
      ]);

  /// The onboarding seed, in shape and in count: whatever the preset list
  /// holds, once.
  Future<void> seedLikeOnboarding(String month) => categories.addCategories([
        for (var i = 0; i < kPredefinedCategories.length; i++)
          category(
            id: 'seed-$i',
            name: kPredefinedCategories[i].name,
            month: month,
            limitMinor: 100000,
          ),
      ]);

  List<Category> userCategoriesIn(String month) => store
      .readCategories()
      .where((c) => c.month == month && !isReservedCategoryName(c.name))
      .toList();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_rollover');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
    categories = Get.put(CategoryRepository());
    settings = Get.put(SettingsService());
    await settings.completeOnboarding();
    // `SplashController.routeToNextScreen` navigates; without a GetMaterialApp
    // GetX throws on contextless navigation unless it is told it is a test.
    Get.testMode = true;
  });

  tearDown(() async {
    Get.testMode = false;
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('the launch path', () {
    test('R1: a new month opens with last month\'s categories and limits',
        () async {
      await seedJuly();
      await settings.setCurrentMonth(july);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      expect(settings.currentMonth.value, august);
      final augustCats = await categories.getCategoriesForMonth(august);
      expect(augustCats.map((c) => c.name).toSet(), {'Food', 'Rent', 'Gym'});
      expect(augustCats.firstWhere((c) => c.name == 'Rent').budgetLimitMinor,
          3750000,
          reason: 'forward rollover carries limits (FD-1)');
      expect(
          augustCats.map((c) => c.id).toSet().intersection(
              {'food', 'rent', 'gym'}),
          isEmpty,
          reason: 'clones get fresh ids');
    });

    test('R2: the month rolled out of is untouched', () async {
      await seedJuly();
      await settings.setCurrentMonth(july);
      final before = await categories.getCategoriesForMonth(july);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      final after = await categories.getCategoriesForMonth(july);
      expect(after.length, before.length);
      expect(after.map((c) => c.id).toSet(), before.map((c) => c.id).toSet());
      expect(after.map((c) => c.budgetLimitMinor).toList(),
          before.map((c) => c.budgetLimitMinor).toList());
    });

    test('R3: relaunching in the same month creates nothing (idempotent)',
        () async {
      await seedJuly();
      await settings.setCurrentMonth(july);
      final splash = SplashController();

      await splash.prepareForHome(nowMonthKey: () => august);
      await splash.prepareForHome(nowMonthKey: () => august);
      await splash.prepareForHome(nowMonthKey: () => august);

      expect((await categories.getCategoriesForMonth(august)).length, 3);
    });

    test('R3b: concurrent ensures produce ONE set of clones, not two',
        () async {
      // The defect this closes is real without the in-flight map: both calls
      // pass the emptiness check before either writes, and the month ends up
      // with six categories where three belong.
      await seedJuly();

      await Future.wait([
        categories.ensureMonth(august),
        categories.ensureMonth(august),
      ]);

      expect((await categories.getCategoriesForMonth(august)).length, 3);
    });

    test('R4: a fresh install seeds nothing — onboarding still owns that',
        () async {
      // Nothing anywhere to clone from: the ensure must be a no-op, not an
      // invention, or a first launch could reach Home with categories that
      // onboarding is about to seed a second time.
      await SplashController().prepareForHome(nowMonthKey: () => august);

      expect(settings.currentMonth.value, august);
      expect(store.readCategories(), isEmpty);
    });

    test('R4b: a first-ever launch routes to onboarding and rolls nothing',
        () async {
      await HiveStorage.setOnboardingComplete(false);
      settings.onboardingComplete.value = false;
      await settings.setCurrentMonth(july);

      await SplashController().routeToNextScreen();

      expect(settings.currentMonth.value, july,
          reason: 'the onboarding path returns before any rollover work');
      expect(store.readCategories(), isEmpty);
    });

    test('R4c: onboarding seeds once — the next launch adds no second set',
        () async {
      await seedLikeOnboarding(august);
      await settings.setCurrentMonth(august);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      expect(userCategoriesIn(august).length, kPredefinedCategories.length,
          reason: 'AC-4: 9 categories after a fresh setup, not 18');
    });

    test('R5: the year boundary rolls to January of the next year', () async {
      await categories
          .addCategory(category(id: 'dec', name: 'Food', month: '2026-12'));
      await settings.setCurrentMonth('2026-12');

      await SplashController().prepareForHome(nowMonthKey: () => '2027-01');

      expect(settings.currentMonth.value, '2027-01');
      expect((await categories.getCategoriesForMonth('2027-01')).single.name,
          'Food');
    });

    test('R6: the reserved bucket is not carried into the new month', () async {
      await seedJuly();
      await categories.ensureUncategorised(july);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      final augustCats = await categories.getCategoriesForMonth(august);
      expect(augustCats.any((c) => isReservedCategoryName(c.name)), isFalse);
      expect(augustCats.length, 3);
    });

    test('R7: a month holding only the bucket still re-populates', () async {
      // Without a reserved-aware emptiness check this month would be frozen
      // empty forever — the unstated half of the Uncategorised bundle.
      await seedJuly();
      await categories.ensureUncategorised(august);
      await settings.setCurrentMonth(july);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      expect(userCategoriesIn(august).length, 3);
    });

    test('R8: both the roll and the ensure are done when the future completes',
        () async {
      await seedJuly();
      await settings.setCurrentMonth(july);

      final pending =
          SplashController().prepareForHome(nowMonthKey: () => august);
      // Read synchronously — no await in between, so nothing has had a chance
      // to run. The work is genuinely asynchronous, which is exactly the window
      // a caller that forgot to await would race, and Home would build into.
      expect(userCategoriesIn(august), isEmpty);

      await pending;

      expect(settings.currentMonth.value, august);
      expect((await categories.getCategoriesForMonth(august)).length, 3);
    });

    test('R9: a launch inside the same month still repairs an emptied month',
        () async {
      // The ensure is not gated on the month having moved: deleting a month's
      // last real category must not freeze it empty until the next rollover.
      await seedJuly();
      await categories.ensureUncategorised(august);
      await settings.setCurrentMonth(august);

      await SplashController().prepareForHome(nowMonthKey: () => august);

      expect(settings.currentMonth.value, august);
      expect(userCategoriesIn(august).length, 3);
    });
  });

  group('the warm-resume hook', () {
    HomeController homeController() =>
        HomeController(settings: settings, categoryRepo: categories);

    test('R10: resuming into a new month rolls and ensures', () async {
      await seedJuly();
      await settings.setCurrentMonth(july);

      await homeController().handleResume(nowMonthKey: () => august);

      expect(settings.currentMonth.value, august);
      expect((await categories.getCategoriesForMonth(august)).length, 3);
    });

    test('R11: resuming inside the same month does nothing', () async {
      await seedJuly();
      await settings.setCurrentMonth(july);

      await homeController().handleResume(nowMonthKey: () => july);

      expect(settings.currentMonth.value, july);
      expect(await categories.getCategoriesForMonth(august), isEmpty);
    });

    test('R12: the hook is gated on onboarding being complete', () async {
      // Structurally HomeController cannot exist during onboarding; this is
      // the belt to that braces — a rollover must never race the flow that
      // seeds the categories it would otherwise clone.
      await seedJuly();
      await settings.setCurrentMonth(july);
      await HiveStorage.setOnboardingComplete(false);
      settings.onboardingComplete.value = false;

      await homeController().handleResume(nowMonthKey: () => august);

      expect(settings.currentMonth.value, july);
      expect(await categories.getCategoriesForMonth(august), isEmpty);
    });
  });
}
