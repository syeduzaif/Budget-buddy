import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../categories/categories_controller.dart';
import '../categories/categories_view.dart';
import '../analytics/analytics_controller.dart';
import '../analytics/analytics_view.dart';
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
    // Delete-then-put, the pattern `_openTransactionForm` below already uses:
    // HomeController now registers a WidgetsBindingObserver, and a plain
    // `Get.put` over an existing registration would leave the previous
    // instance's observer attached with nothing to dispose it. One Home entry,
    // one controller, one observer.
    if (Get.isRegistered<HomeController>()) Get.delete<HomeController>();
    final ctrl = Get.put(HomeController(
      settings: Get.find<SettingsService>(),
      categoryRepo: Get.find<CategoryRepository>(),
    ));

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

    // Nav bar has 4 destinations: 0→Dashboard, 1→Categories,
    // 2→Add (opens a sheet, never a tab), 3→Analytics.
    // `views` holds only the three real tabs, so nav 3 maps to view 2.
    int stackIndex(int navIdx) => navIdx >= 3 ? navIdx - 1 : navIdx;

    const views = [
      DashboardView(),
      CategoriesView(),
      AnalyticsView(),
    ];

    return Obx(() => Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(ctrl.currentIndex.value),
              child: views[stackIndex(ctrl.currentIndex.value)],
            ),
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
