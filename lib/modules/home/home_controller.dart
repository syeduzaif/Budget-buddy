import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

/// Owns the bottom-nav selection, and the warm-app half of the month rollover.
///
/// The launch path is handled on the splash (`SplashController.prepareForHome`).
/// This covers the other boundary: an app left open across midnight on the
/// 1st, which resumes into a new month that has no categories yet.
///
/// The observer lives HERE rather than on a service for a structural reason —
/// `HomeController` cannot exist during onboarding, so the rollover can never
/// race the flow that seeds the very categories it would clone. The
/// onboarding-complete check below is the belt to that braces.
/// [PROPOSED convention: this is the app's first `WidgetsBindingObserver`.]
class HomeController extends GetxController with WidgetsBindingObserver {
  final SettingsService settings;
  final CategoryRepository categoryRepo;

  HomeController({required this.settings, required this.categoryRepo});

  final currentIndex = 0.obs;

  void changeTab(int index) => currentIndex.value = index;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    // Lifecycle callbacks are synchronous; the work is awaited inside
    // [handleResume], whose failures are logged rather than thrown into the
    // framework's callback (H2).
    handleResume();
  }

  /// Rolls the app into the real current month on resume, when — and only
  /// when — the month has actually changed since the app was backgrounded
  /// (F-02 rule 4). The roll-then-ensure pair is the one the splash and the
  /// month chevrons already run.
  ///
  /// [nowMonthKey] is a test seam, not a clock dependency — the default reads
  /// the real clock.
  Future<void> handleResume({
    String Function() nowMonthKey = AppDateUtils.getCurrentMonthKey,
  }) async {
    if (!settings.onboardingComplete.value) return;
    final now = nowMonthKey();
    if (settings.currentMonth.value == now) return;
    try {
      await settings.setCurrentMonth(now);
      await categoryRepo.ensureMonth(now);
    } catch (e, stack) {
      // Nothing the user asked for failed, so there is nothing to tell them:
      // the month simply stays where it was and the chevrons still work.
      debugPrint('[HomeController] resume rollover failed: $e\n$stack');
    }
  }
}
