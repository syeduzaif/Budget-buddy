import 'package:get/get.dart';
import '../../data/repositories/category_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

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
  /// [nowMonthKey] is a test seam, not a clock dependency — the default reads
  /// the real clock, and `CategoryRepository.ensureMonth` reads no clock at all
  /// [PROPOSED convention: inject the clock as a defaulted function parameter].
  Future<void> prepareForHome({
    String Function() nowMonthKey = AppDateUtils.getCurrentMonthKey,
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
  /// only thing that seeds categories.
  Future<void> routeToNextScreen() async {
    if (!_settings.onboardingComplete.value) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    await prepareForHome();
    Get.offAllNamed(AppRoutes.home);
  }
}
