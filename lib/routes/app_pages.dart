import 'package:get/get.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/signup_view.dart';
import '../modules/onboarding/onboarding_controller.dart';
import '../modules/onboarding/onboarding_view.dart';
import '../modules/home/home_view.dart';
import '../modules/category_form/category_form_view.dart';
import '../modules/transactions/transactions_view.dart';
import '../modules/settings/settings_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),
    GetPage(
      name: AppRoutes.categoryForm,
      page: () => const CategoryFormView(),
    ),
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsView(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
    ),
  ];
}

// Initial binding — registers AuthController at startup
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
  }
}
