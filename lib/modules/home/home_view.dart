import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../categories/categories_controller.dart';
import '../categories/categories_view.dart';
import '../analytics/analytics_controller.dart';
import '../analytics/analytics_view.dart';
import '../ai_chat/ai_chat_controller.dart';
import '../ai_chat/ai_chat_view.dart';
import '../transaction_form/transaction_form_controller.dart';
import '../transaction_form/transaction_form_view.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeController());

    Get.lazyPut(() => DashboardController(
          categoryRepo: Get.find<CategoryRepository>(),
          transactionRepo: Get.find<TransactionRepository>(),
          settings: Get.find<SettingsService>(),
        ));
    Get.lazyPut(() => CategoriesController(
          categoryRepo: Get.find<CategoryRepository>(),
          transactionRepo: Get.find<TransactionRepository>(),
          settings: Get.find<SettingsService>(),
        ));
    Get.lazyPut(() => AnalyticsController(
          transactionRepo: Get.find<TransactionRepository>(),
          categoryRepo: Get.find<CategoryRepository>(),
          settings: Get.find<SettingsService>(),
        ));
    Get.lazyPut(() => AiChatController());

    // Tab index mapping: nav 0→Dashboard, 1→Categories, 2→(Add, handled separately),
    // 3→Analytics, 4→AiChat. IndexedStack uses 0-3.
    int stackIndex(int navIdx) {
      if (navIdx <= 1) return navIdx;
      if (navIdx >= 3) return navIdx - 1;
      return 0;
    }

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: stackIndex(ctrl.currentIndex.value),
            children: const [
              DashboardView(),
              CategoriesView(),
              AnalyticsView(),
              AiChatView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: ctrl.currentIndex.value,
            onDestinationSelected: (i) {
              if (i == 2) {
                _openTransactionForm(context);
              } else {
                ctrl.changeTab(i);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Add',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'AI',
              ),
            ],
          ),
        ));
  }

  void _openTransactionForm(BuildContext context) {
    // Always create a fresh instance for the form
    if (Get.isRegistered<TransactionFormController>()) {
      Get.delete<TransactionFormController>();
    }
    Get.put(TransactionFormController(
      categoryRepo: Get.find<CategoryRepository>(),
      transactionRepo: Get.find<TransactionRepository>(),
      settings: Get.find<SettingsService>(),
    ));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TransactionFormView(),
    );
  }
}
