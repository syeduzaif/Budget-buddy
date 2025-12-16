import 'package:get/get.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../modules/dashboard/dashboard_view.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/signup_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/category/category_controller.dart';
import '../modules/category/category_view.dart';
import '../modules/category/add_transaction_view.dart';
import '../modules/add_category/add_category_controller.dart';
import '../modules/add_category/add_category_view.dart';
import '../modules/transactions/transactions_controller.dart';
import '../modules/transactions/transactions_view.dart';
import '../modules/currency_selection/currency_selection_controller.dart';
import '../modules/currency_selection/currency_selection_view.dart';
import '../modules/ai_chat/ai_chat_view.dart';
import '../modules/ai_chat/ai_chat_controller.dart';
import 'app_routes.dart';

/// App route pages configuration
class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
      }),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CategoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.categoryTransactions,
      page: () => const CategoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CategoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.addCategory,
      page: () => const AddCategoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AddCategoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.addTransaction,
      page: () => AddTransactionView(),
      binding: BindingsBuilder(() {
        // Controller is created by the parent view
      }),
    ),
    GetPage(
      name: AppRoutes.allTransactions,
      page: () => const TransactionsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TransactionsController());
      }),
    ),
    GetPage(
      name: AppRoutes.currencySelection,
      page: () => const CurrencySelectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CurrencySelectionController());
      }),
    ),
    GetPage(
      name: AppRoutes.aiChat,
      page: () => const AiChatView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AiChatController());
      }),
    ),
  ];
}
