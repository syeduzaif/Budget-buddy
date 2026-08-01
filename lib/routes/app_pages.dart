import 'package:get/get.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../modules/onboarding/onboarding_controller.dart';
import '../modules/onboarding/onboarding_view.dart';
import '../modules/splash/splash_controller.dart';
import '../modules/splash/splash_view.dart';
import '../modules/home/home_view.dart';
import '../modules/category_form/category_form_view.dart';
import '../modules/transactions/transactions_view.dart';
import '../modules/settings/settings_view.dart';
import '../services/app/settings_service.dart';
import '../services/local/local_store_service.dart';
import 'app_routes.dart';

class AppPages {
  static const _duration = Duration(milliseconds: 250);
  static const _transition = Transition.fadeIn;

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
      transition: _transition,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      transition: _transition,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.categoryForm,
      page: () => const CategoryFormView(),
      transition: Transition.rightToLeft,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsView(),
      transition: Transition.rightToLeft,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.rightToLeft,
      transitionDuration: _duration,
    ),
  ];
}

/// Process-wide dependency registration.
///
/// The app is local-only, so nothing here is gated on a sign-in event: every
/// service and repository exists for the whole process lifetime. Awaited in
/// `main()` before `runApp`, because [LocalStoreService] has to finish opening
/// its Hive boxes before any repository reads from it.
class AppBindings {
  static Future<void> register() async {
    await Get.putAsync(() => LocalStoreService().init(), permanent: true);
    Get.put(SettingsService(), permanent: true);
    Get.put(CategoryRepository(), permanent: true);
    Get.put(TransactionRepository(), permanent: true);
  }
}
