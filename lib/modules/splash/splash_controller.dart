// `show debugPrint` only: foundation also exports a `Category` annotation,
// which would collide with the model this controller's repository deals in.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import '../../data/repositories/category_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/app/settings_service.dart';
import '../../utils/app_clock.dart';

class SplashController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();
  final CategoryRepository _categories = Get.find<CategoryRepository>();

  /// Everything that has to be true before Home builds.
  ///
  /// Rolls to the real current month AND gives that month its categories — the
  /// same roll-then-ensure pair the month chevrons already run
  /// (`DashboardController.goToPreviousMonth`/`goToNextMonth`). Awaited by
  /// [routeToNextScreen] so the dashboard's first frame already has them:
  /// arriving first and populating afterwards is the "app looks wiped on the
  /// 1st" flash this fixes (F-02).
  ///
  /// The ensure runs on every launch, not only when the month moved. A month
  /// whose last real category was deleted has to be able to re-populate from a
  /// neighbour, or it stays empty forever (F-02 rule 5); the call is idempotent
  /// and costs one box read when there is nothing to do.
  ///
  /// [nowMonthKey] is a test seam, not a clock dependency — the default is
  /// [AppClock.nowMonthKey] (the real clock in any release build; substitutable
  /// in a debug build via `--dart-define=BB_NOW_MONTH`, which is how F-02's
  /// AC-1/2/3 are exercised by hand), and `CategoryRepository.ensureMonth`
  /// reads no clock at all
  /// [PROPOSED convention: inject the clock as a defaulted function parameter].
  Future<void> prepareForHome({
    String Function() nowMonthKey = AppClock.nowMonthKey,
  }) async {
    final now = nowMonthKey();
    await _settings.setCurrentMonth(now);
    // The seam goes down with the call: the ensure now decides limits by
    // direction (FD-1/BUG-120), so a simulated-clock test must not have its
    // rollover measured against the machine's real date.
    await _categories.ensureMonth(now, nowMonthKey: nowMonthKey);
  }

  /// Where the app lands once the splash animation has had its minimum run.
  ///
  /// There are no accounts, so onboarding is the only gate — and a first-ever
  /// launch returns here BEFORE any rollover work, so onboarding remains the
  /// only thing that seeds categories. That `return` is why a first-ever launch
  /// cannot hang: nothing is awaited on that branch (D-025).
  ///
  /// **The routing is not conditional on the preparation succeeding.** On every
  /// launch after onboarding, for the life of the install, a failing Hive write
  /// inside [prepareForHome] used to leave the app on the splash forever —
  /// dots animating, no route out, and no in-app recovery of any kind. The
  /// identical roll-then-ensure pair is already guarded on the path where
  /// failure is harmless (`HomeController.handleResume`), which makes the
  /// unguarded fatal path an omission rather than a decision.
  ///
  /// Two shapes were considered and refused (CTO × PM, 2026-08-05):
  /// a watchdog timer — a second mechanism with a timing dependency doing a job
  /// try/catch does deterministically, and it masks the failure so the user is
  /// never told; and a fallback to onboarding — it shows a fresh-install
  /// experience to a user whose data is intact, and `finish()` would then
  /// overwrite their currency and income and seed nine more categories, i.e.
  /// the fallback for a data-access failure would itself corrupt the data.
  ///
  /// The snackbar is owed here (unlike on resume, which stays silent) because
  /// the consequence is visible on the very next frame: a failed
  /// `setCurrentMonth` opens the dashboard on last month, and a failed
  /// `ensureMonth` opens the current month showing "No categories yet" on a
  /// populated app. The copy therefore states what is true NOW and never asks
  /// the user to try again later (L2).
  ///
  /// The copy first shipped saying the month chevrons "rebuilds it", and that
  /// was rejected (PM, 2026-08-05): a full disk is exactly the trigger here,
  /// and switching months re-runs the same failing write. Promising a remedy
  /// that only works when the failure was transient is L2's ban in disguise —
  /// not time-based, but implying a condition the user's action will change.
  /// The shipped form names what the control DOES ("tries again"), never what
  /// it will achieve.
  Future<void> routeToNextScreen() async {
    if (!_settings.onboardingComplete.value) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    try {
      await prepareForHome();
    } catch (e, stack) {
      debugPrint('[SplashController] prepareForHome failed: $e\n$stack');
      // Owner-approved mobile convention (2026-07-28): user-visible failures
      // surface via Get.snackbar. A screen the app could not finish preparing
      // must not be presented as if it were prepared (H3).
      Get.snackbar(
        'Could not finish loading',
        'Your records are still saved. The dashboard may open on the wrong '
            'month or show no categories — switching months at the top tries '
            'again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    Get.offAllNamed(AppRoutes.home);
  }
}
