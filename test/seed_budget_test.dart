import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/predefined_categories.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/onboarding/onboarding_controller.dart';
import 'package:budget_buddy/routes/app_pages.dart';
import 'package:budget_buddy/routes/app_routes.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// How long each faked settings write and the faked seed pretend to take, so
/// the window between "the user taps" and "the writes finish" is a real,
/// controllable window under the fake clock.
const Duration _writeDelay = Duration(milliseconds: 20);

/// [SettingsService] with the disk taken out.
///
/// The same seam `erase_flow_test.dart` uses and for the same reason: a Hive
/// write is real disk I/O and only completes under `tester.runAsync`, which
/// cannot be mixed with `tester.tap`. Each override keeps the shipped
/// persist-then-publish ORDER and drops only the persist, so `finish()` still
/// runs five sequential awaits — which is the entire mechanism under test.
/// Only the four WRITES are faked. `onInit`'s `_load()` is left alone — those
/// are synchronous box reads, which the fake clock has no quarrel with.
class _SlowSettingsService extends SettingsService {
  @override
  Future<void> setCurrency(String code, String symbol) async {
    await Future<void>.delayed(_writeDelay);
    currencyCode.value = code;
    currencySymbol.value = symbol;
  }

  @override
  Future<void> setMonthlyIncomeMinor(int minorUnits) async {
    await Future<void>.delayed(_writeDelay);
    monthlyIncomeMinor.value = minorUnits;
  }

  @override
  Future<void> setCurrentMonth(String month) async {
    await Future<void>.delayed(_writeDelay);
    currentMonth.value = month;
  }

  @override
  Future<void> completeOnboarding() async {
    await Future<void>.delayed(_writeDelay);
    onboardingComplete.value = true;
  }
}

/// Counts what reaches the store without touching it.
///
/// `addCategories` is the only path onboarding has into the category box, so
/// the length of [seeded] is the number of categories the install would end up
/// with. The sibling real-Hive test below proves the same number against the
/// actual box.
class _CountingCategoryRepository extends CategoryRepository {
  final List<Category> seeded = [];
  int calls = 0;

  @override
  Future<void> addCategories(List<Category> categories) async {
    calls++;
    await Future<void>.delayed(_writeDelay);
    seeded.addAll(categories);
  }
}

/// UI-35 — seed budgets follow the income the user just entered.
///
/// The presets used to seed currency-blind whole numbers (Housing 1200, Food
/// 500, Transport 200 …), which read as dollars and gave a PKR user a ₨200
/// monthly transport budget. Shares are integer percent, rounded DOWN to a
/// clean step, so the nine seeds always total less than the stated income.
///
/// Since 2026-08-05 this file also owns **AC-D026-1**: the seeder runs once per
/// onboarding, whichever of the two controls is tapped and however fast.
void main() {
  final pkr = CurrencyUtils.resolve('PKR'); // 2 decimals
  final jpy = CurrencyUtils.resolve('JPY'); // 0 decimals
  final usd = CurrencyUtils.resolve('USD');

  PredefinedCategory preset(String name) =>
      kPredefinedCategories.firstWhere((p) => p.name == name);

  int seedTotal(int incomeMinor, Currency currency) => kPredefinedCategories
      .fold(0, (sum, p) => sum + p.seedLimitMinor(incomeMinor, currency));

  test('PKR: a ₨150,000 income seeds round rupee budgets under the income',
      () {
    const income = 15000000; // ₨150,000.00 in minor units

    expect(preset('Housing').seedLimitMinor(income, pkr), 3750000); // ₨37,500
    expect(preset('Food').seedLimitMinor(income, pkr), 2250000); // ₨22,500
    expect(preset('Transport').seedLimitMinor(income, pkr), 1500000); // ₨15,000

    expect(CurrencyUtils.formatAmount(3750000, pkr), '₨37,500.00');
    expect(seedTotal(income, pkr), lessThan(income));

    // Rounds DOWN to the nearest 100 major units, never up: 10% of
    // ₨123,456.78 is ₨12,345.678 → ₨12,300.
    expect(preset('Transport').seedLimitMinor(12345678, pkr), 1230000);
  });

  test('JPY: zero-decimal currency rounds in whole yen, not in sen', () {
    const income = 300000; // ¥300,000 — minor unit IS the yen

    expect(preset('Housing').seedLimitMinor(income, jpy), 75000); // ¥75,000
    expect(preset('Utilities').seedLimitMinor(income, jpy), 24000); // ¥24,000
    expect(CurrencyUtils.formatAmount(75000, jpy), '¥75,000');
    expect(seedTotal(income, jpy), lessThan(income));

    // 15% of ¥333,333 is ¥49,999.95 → floored to ¥49,999 → step 100 → ¥49,900.
    expect(preset('Food').seedLimitMinor(333333, jpy), 49900);

    // A share below one major unit stays proportional and never lands on 0 —
    // a 0 limit is read as "no budget" by the bars and the over-budget flag.
    expect(preset('Health').seedLimitMinor(10, jpy), greaterThan(0));
  });

  test('no income falls back to the presets, never to zero limits', () {
    for (final p in kPredefinedCategories) {
      expect(p.seedLimitMinor(0, usd),
          CurrencyUtils.fromMajor(p.defaultBudgetMajor, usd),
          reason: '${p.name} with no income');
      expect(p.seedLimitMinor(-1, jpy),
          CurrencyUtils.fromMajor(p.defaultBudgetMajor, jpy));
      expect(p.seedLimitMinor(0, usd), greaterThan(0), reason: p.name);
    }
    // Food: 500 major units → 50000 cents, 500 yen.
    expect(preset('Food').seedLimitMinor(0, usd), 50000);
    expect(preset('Food').seedLimitMinor(0, jpy), 500);

    // The share-less "Other" preset that used to be asserted here is gone:
    // the auto-created bucket it fed was merged into the reserved
    // "Uncategorised" category (FD-2), which is minted with a 0 limit by
    // `CategoryRepository.ensureUncategorised` and never by a preset.
  });

  // ─── AC-D026-1 ────────────────────────────────────────────────────────────
  //
  // D-026/5(b). `finish()` awaited five writes with no re-entrancy guard while
  // BOTH "Start Budgeting" and "Skip for now" called it bare, so the reachable
  // path was never a mistimed double tap: it was a user tapping the primary,
  // seeing nothing at all, and tapping the control underneath it. The second
  // run seeded nine more categories, `ensureMonth` cloned the doubled set
  // forward every month for the life of the install, and every rung of F-09's
  // ladder then read 2× limits against 1× income. Recovery: nine manual
  // deletes, or Erase All Data.

  group('AC-D026-1: two rapid taps seed nine categories, not eighteen', () {
    late Directory tempDir;
    late _CountingCategoryRepository repo;

    /// The primary while it is busy — its label is replaced by the spinner, so
    /// it cannot be found by text once it has been tapped.
    final busyPrimary = find.ancestor(
      of: find.byType(CircularProgressIndicator),
      matching: find.byType(FilledButton),
    );
    final idlePrimary = find.widgetWithText(FilledButton, 'Start Budgeting');
    // The secondary's label never changes, busy or not.
    final secondary = find.widgetWithText(TextButton, 'Skip for now');

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    // A real store is registered because CategoryRepository's constructor
    // requires one and SettingsService reads the settings box on init — both
    // synchronous. Nothing in this group ever WRITES to it: the spy intercepts
    // the one write onboarding makes.
    setUp(() async {
      Get.testMode = true;
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_seedtap');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      repo = _CountingCategoryRepository();
      Get.put<CategoryRepository>(repo);
      Get.put<SettingsService>(_SlowSettingsService());
    });

    tearDown(() async {
      Get.reset();
      Get.testMode = false;
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// Pumps the real onboarding page and its real binding, walks to the income
    /// step the way a user does, and stubs only the destination.
    Future<void> pumpToIncomePage(WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        getPages: [
          AppPages.pages.firstWhere((p) => p.name == AppRoutes.onboarding),
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Center(child: Text('HOME'))),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(idlePrimary, findsOneWidget);
    }

    testWidgets('while the first tap is in flight, both controls are dead',
        (tester) async {
      await pumpToIncomePage(tester);
      await tester.tap(idlePrimary);
      // One frame: enough for the Obx to rebuild, far short of the ~100ms of
      // faked writes.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'the primary says the tap was received — the absence of any '
              'feedback is what invited the second tap');
      expect(tester.widget<FilledButton>(busyPrimary).onPressed, isNull);
      expect(tester.widget<TextButton>(secondary).onPressed, isNull,
          reason: 'the control DIRECTLY UNDERNEATH the unresponsive-looking '
              'button is the one that actually got tapped');

      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    for (final combo in [
      ('Start Budgeting', 'Start Budgeting'),
      ('Start Budgeting', 'Skip for now'),
      ('Skip for now', 'Start Budgeting'),
      ('Skip for now', 'Skip for now'),
    ]) {
      testWidgets('tap ${combo.$1} then ${combo.$2}', (tester) async {
        await pumpToIncomePage(tester);

        await tester
            .tap(combo.$1 == 'Start Budgeting' ? idlePrimary : secondary);
        // 5ms into ~100ms of writes: the window a real user's second tap lands
        // in.
        await tester.pump(const Duration(milliseconds: 5));
        await tester.tap(
          combo.$2 == 'Start Budgeting' ? busyPrimary : secondary,
          // Deliberately tapping a control that must NOT respond; a "missed"
          // tap is the pass condition, not a defect in the finder.
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(repo.calls, 1, reason: 'the seeder ran once');
        expect(repo.seeded, hasLength(kPredefinedCategories.length));
        expect(repo.seeded, hasLength(9));
        expect(repo.seeded.map((c) => c.name).toSet(), hasLength(9),
            reason: 'nine DISTINCT categories — eighteen would be each preset '
                'twice, with the same names and doubled total limits');
        expect(find.text('HOME'), findsOneWidget,
            reason: 'and the flow still completes');
      });
    }

    testWidgets('the latch alone holds, with no button state to help it',
        (tester) async {
      // Isolates mechanism 1. The disabled controls are what stop the second
      // tap being made; this is the guarantee underneath them, and it is the
      // half that would still be needed if a third caller of finish() were
      // ever added.
      await pumpToIncomePage(tester);
      final ctrl = Get.find<OnboardingController>();

      final first = ctrl.finish();
      final second = ctrl.finish();
      await tester.pumpAndSettle();
      await first;
      await second;

      expect(repo.calls, 1);
      expect(repo.seeded, hasLength(9));
    });
  });

  group('AC-D026-1: against the real category box', () {
    // The group above counts what reaches the repository, because tapping and
    // real disk I/O cannot share a test. This one gives up the taps to get the
    // actual store back: two overlapping finish() calls, real Hive, real
    // CategoryRepository, and the box read back at the end.
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionItemAdapter());
      }
    });

    setUp(() async {
      Get.testMode = true; // finish() ends in a contextless Get.offAllNamed
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_seed');
      Hive.init(tempDir.path);
      await HiveStorage.openSettings();
      Get.put<LocalStoreService>(await LocalStoreService().init());
      Get.put(CategoryRepository());
      Get.put(SettingsService());
    });

    tearDown(() async {
      Get.reset();
      Get.testMode = false;
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('two overlapping finishes leave nine categories in the box', () async {
      final ctrl = OnboardingController();
      ctrl.selectCurrency(CurrencyUtils.resolve('PKR'));
      ctrl.incomeController.text = '150000';

      // Not awaited between calls — the second lands while the first is still
      // inside its five writes.
      final first = ctrl.finish();
      final second = ctrl.finish();
      await Future.wait([first, second]);

      final stored = await Get.find<CategoryRepository>().getAllCategories();
      expect(stored, hasLength(9));
      expect(stored.map((c) => c.name).toSet(), hasLength(9));
      // The consequence the duplicate would have had: F-09's ladder divides
      // spend by these limits, so a doubled set mis-reads every rung forever.
      expect(stored.fold<int>(0, (s, c) => s + c.budgetLimitMinor),
          lessThan(15000000),
          reason: 'the nine seeds total less than the income — eighteen would '
              'not');
    });
  });
}
