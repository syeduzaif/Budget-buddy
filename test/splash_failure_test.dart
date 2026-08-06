import 'dart:io';

import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/splash/splash_controller.dart';
import 'package:budget_buddy/routes/app_routes.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// D-025 — the splash cannot hang, and it says so when it could not finish.
///
/// `routeToNextScreen` awaited `prepareForHome` with no try/catch, and
/// `splash_view.dart` calls it from a `void` method, so the future was
/// discarded and the error could not propagate anywhere. A Hive write failure
/// therefore left the app on the splash forever — dots animating, no route out.
/// It was the only state in the app with no in-app recovery.
///
/// Three things about the shape of these tests are deliberate, and each is a
/// ruling rather than a preference (CTO × PM, 2026-08-05):
///
/// 1. **Every test launches an ONBOARDED app.** `routeToNextScreen` returns at
///    the onboarding branch BEFORE any await, so a first-ever launch cannot
///    hang; an AC phrased against a first run would be vacuously true and
///    would pin nothing.
/// 2. **The injected failure is a WRITE.** `nowMonthKey()` is pure integer
///    maths and cannot throw, and a box that will not open is handled before
///    `runApp` and never reaches the splash. The two realistic triggers are
///    `settings_service.dart:150` → `hive_storage.dart:118` (`_box.put`) and
///    `local_store_service.dart:95` (`putAll`) — one test each, injected at
///    exactly those two methods with the rest of the app running as shipped.
/// 3. **Routing to onboarding on failure is asserted AGAINST**, not for. That
///    fallback was refused because it shows a fresh-install experience to a
///    user whose data is intact, and `finish()` would then overwrite their
///    currency and income and seed nine more categories — the fallback for a
///    data-access failure would itself corrupt the data.
///
/// No test here reads which month it is: expectations are derived from
/// `AppDateUtils`, because a test that only passes in some months is not a test.
void main() {
  late Directory tempDir;
  late _FailingCategoryWriteStore store;
  late _FailingMonthWriteSettings settings;
  late CategoryRepository categories;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  Category category(String id, String name) {
    final stamp = DateTime(2026, 1, 1, 9);
    return Category(
      id: id,
      name: name,
      budgetLimitMinor: 2250000,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: Icons.restaurant.codePoint,
      month: lastMonth,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  List<Category> categoriesIn(String month) =>
      store.readCategories().where((c) => c.month == month).toList();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  // Real Hive I/O, deliberately in `setUp`: setUp runs on the real event loop,
  // where a box write completes. Inside a `testWidgets` body it would not —
  // hence the `runAsync` in [launch].
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_splash_fail');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await _FailingCategoryWriteStore().init()
        as _FailingCategoryWriteStore;
    Get.put<LocalStoreService>(store);
    categories = Get.put(CategoryRepository());
    settings = _FailingMonthWriteSettings();
    Get.put<SettingsService>(settings);

    // An onboarded install with a real history, sitting on last month — so the
    // launch has a genuine roll AND a genuine ensure to perform, and a failure
    // of either is observable.
    await settings.completeOnboarding();
    await categories.addCategories([
      category('food', 'Food'),
      category('rent', 'Rent'),
      category('gym', 'Gym'),
    ]);
    await settings.setCurrentMonth(lastMonth);
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// A navigator that really resolves the app's route names, so "lands on Home"
  /// is a fact about the route stack rather than about a mock.
  ///
  /// Stub pages, not the real views: this file is about what the splash does
  /// when a write fails, and pumping `HomeView` would drag its bindings, its
  /// `AppFonts` google-font downloads (answered with 400 under
  /// `TestWidgetsFlutterBinding`) and four tabs of unrelated surface into a
  /// routing assertion.
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const _Stub('splash-stub')),
        GetPage(name: AppRoutes.home, page: () => const _Stub('home-stub')),
        GetPage(
            name: AppRoutes.onboarding,
            page: () => const _Stub('onboarding-stub')),
      ],
    ));
    await tester.pumpAndSettle();
  }

  /// Runs the shipped launch path.
  ///
  /// `runAsync` because a Hive write started on the test's fake clock only
  /// advances while frames are pumped, and one left unfinished deadlocks
  /// `tearDown`'s `Hive.close()`. Bounded pumps afterwards, not
  /// `pumpAndSettle`: a snackbar on screen keeps scheduling frames, so
  /// "settled" is not a state this reaches.
  Future<void> launch(WidgetTester tester) async {
    await tester.runAsync(() async {
      await SplashController().routeToNextScreen();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Closes the failure snackbar and lets GetX finish with it.
  ///
  /// Cancelled rather than waited out, for a measured reason: a `Get.snackbar`
  /// raised inside `runAsync` builds its 3 s dismissal `Timer` on the REAL
  /// event loop, where `tester.pump`'s fake clock cannot reach it. GetX's
  /// snackbar queue is `static` and strictly serial (`_SnackBarQueue`), and a
  /// job only leaves it when its transition completer fires — so one bar left
  /// hanging blocks every later test IN THE WHOLE FILE from ever showing one.
  /// That is not a hypothetical: it is what these tests did before this drain
  /// existed, and it fails as "no snackbar" in a test whose subject is the
  /// snackbar.
  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.runAsync(() async {
      Get.closeAllSnackbars();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    // The dismissal animation needs frames; the completer fires at its end.
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Every word the snackbar is showing, lowercased.
  String snackbarCopy(WidgetTester tester) => tester
      .widgetList<Text>(find.descendant(
          of: find.byType(GetSnackBar), matching: find.byType(Text)))
      .map((t) => t.data ?? '')
      .join(' ')
      .toLowerCase();

  group('AC-D025-1 — a failing write still lands on Home', () {
    testWidgets('the month write fails (settings_service.dart:150)',
        (tester) async {
      await pumpHost(tester);
      settings.failWrites = true;

      await launch(tester);

      expect(Get.currentRoute, AppRoutes.home);
      expect(find.text('home-stub'), findsOneWidget);
      expect(find.text('splash-stub'), findsNothing,
          reason: 'the splash is what the user was stuck on');

      // The injected failure was real, and its consequence is exactly the one
      // the snackbar copy names: the dashboard opens on last month.
      expect(settings.currentMonth.value, lastMonth);

      await drainSnackbar(tester);
    });

    testWidgets('the category batch write fails (local_store_service.dart:95)',
        (tester) async {
      await pumpHost(tester);
      store.failWrites = true;

      await launch(tester);

      expect(Get.currentRoute, AppRoutes.home);
      expect(find.text('home-stub'), findsOneWidget);

      // Here the roll landed and only the clone failed — the other consequence
      // the copy names: the current month, with no categories in it, on an
      // install that has three.
      expect(settings.currentMonth.value, thisMonth);
      expect(categoriesIn(thisMonth), isEmpty);
      expect(categoriesIn(lastMonth), hasLength(3),
          reason: 'nothing was lost — only the new month was not built');

      await drainSnackbar(tester);
    });

    testWidgets('a failed launch never routes to onboarding (the refused '
        'fallback)', (tester) async {
      await pumpHost(tester);
      settings.failWrites = true;

      await launch(tester);

      expect(find.text('onboarding-stub'), findsNothing);
      expect(Get.currentRoute, isNot(AppRoutes.onboarding),
          reason: 'onboarding would re-seed nine categories and overwrite the '
              'currency and income of a user whose data is intact');

      await drainSnackbar(tester);
    });

    testWidgets('the guard did not change the healthy launch', (tester) async {
      await pumpHost(tester);

      await launch(tester);

      expect(Get.currentRoute, AppRoutes.home);
      expect(settings.currentMonth.value, thisMonth);
      expect(categoriesIn(thisMonth).map((c) => c.name).toSet(),
          {'Food', 'Rent', 'Gym'});
    });

    testWidgets('a first-ever launch still goes to onboarding', (tester) async {
      // The branch that returns before any await — the reason D-025 begins at
      // launch #2 and not at launch #1.
      await tester.runAsync(() async {
        await HiveStorage.setOnboardingComplete(false);
      });
      settings.onboardingComplete.value = false;
      await pumpHost(tester);

      await launch(tester);

      expect(Get.currentRoute, AppRoutes.onboarding);
      expect(settings.currentMonth.value, lastMonth,
          reason: 'the onboarding path rolls nothing');
    });
  });

  group('AC-D025-2 — the failure is surfaced, in words that are true now', () {
    testWidgets('a failing month write raises a snackbar', (tester) async {
      await pumpHost(tester);
      settings.failWrites = true;

      await launch(tester);

      expect(find.byType(GetSnackBar), findsOneWidget);
      expect(find.text('Could not finish loading'), findsOneWidget);

      await drainSnackbar(tester);
    });

    testWidgets('a failing category batch write raises a snackbar',
        (tester) async {
      await pumpHost(tester);
      store.failWrites = true;

      await launch(tester);

      expect(find.byType(GetSnackBar), findsOneWidget);

      await drainSnackbar(tester);
    });

    testWidgets('the copy states what is true now — no "try again later"',
        (tester) async {
      await pumpHost(tester);
      settings.failWrites = true;

      await launch(tester);

      final copy = snackbarCopy(tester);
      expect(copy, contains('your records are still saved'),
          reason: 'the first thing a user needs to know is what they still '
              'have, in the vocabulary the rest of the app already uses');
      expect(copy.contains('try again'), isFalse,
          reason: 'L2: the user cannot retry a launch, and nothing about the '
              'state will change by waiting — say what is true now');
      expect(copy.contains('later'), isFalse, reason: 'L2');

      await drainSnackbar(tester);
    });

    testWidgets('the copy promises no remedy — it names what the control does',
        (tester) async {
      // The amendment (PM, 2026-08-05): the first shipped string said the
      // chevrons "rebuilds it". A full disk is exactly this failure's trigger,
      // and switching months re-runs the same write, so that sentence is a
      // remedy that only holds when the failure was transient — L2's ban in
      // disguise. Pinned by word, because the tempting edit is to put an
      // outcome back in.
      await pumpHost(tester);
      settings.failWrites = true;

      await launch(tester);

      final copy = snackbarCopy(tester);
      expect(copy, contains('tries again'),
          reason: 'state what the month chevrons DO');
      expect(copy.contains('rebuild'), isFalse,
          reason: 'a promised outcome the app cannot keep when the disk is '
              'full — the exact trigger');
      expect(copy.contains('will fix'), isFalse, reason: 'same class');
      expect(copy.contains('restore'), isFalse, reason: 'same class');

      await drainSnackbar(tester);
    });

    testWidgets('a healthy launch raises no snackbar', (tester) async {
      // The other half of "surfaces failure": it must not cry wolf, or the
      // signal is worth nothing on the launch that matters.
      await pumpHost(tester);

      await launch(tester);

      expect(find.byType(GetSnackBar), findsNothing);
    });
  });
}

/// A store whose batch category write fails on demand — the `putAll` at
/// `local_store_service.dart:95`, reached from `CategoryRepository.ensureMonth`.
///
/// A flag rather than an always-throwing override, so `setUp` can build a real
/// history through the shipped code path and the failure begins exactly where
/// the test says it does.
class _FailingCategoryWriteStore extends LocalStoreService {
  bool failWrites = false;

  @override
  Future<void> putCategories(List<Category> categories) async {
    if (failWrites) {
      throw StateError('simulated Hive putAll failure');
    }
    return super.putCategories(categories);
  }
}

/// Settings whose month write fails on demand — `setCurrentMonth`
/// (`settings_service.dart:150`), whose `HiveStorage.setCurrentMonth` is the
/// `_box.put` at `hive_storage.dart:118`. That call is static, so the seam is
/// taken one level up; a throwing `_box.put` produces exactly this.
class _FailingMonthWriteSettings extends SettingsService {
  bool failWrites = false;

  @override
  Future<void> setCurrentMonth(String month) async {
    if (failWrites) {
      throw StateError('simulated Hive put failure');
    }
    return super.setCurrentMonth(month);
  }
}

class _Stub extends StatelessWidget {
  final String label;
  const _Stub(this.label);

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}
