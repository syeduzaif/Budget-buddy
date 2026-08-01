import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

class SplashController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();

  /// Where the app lands once the splash animation has had its minimum run.
  ///
  /// There are no accounts, so onboarding is the only gate.
  Future<void> routeToNextScreen() async {
    if (!_settings.onboardingComplete.value) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    // Roll the app forward to the real current month on every launch.
    await _settings.setCurrentMonth(AppDateUtils.getCurrentMonthKey());
    Get.offAllNamed(AppRoutes.home);
  }
}
