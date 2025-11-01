import 'package:get/get.dart';
import '../../services/budget_service.dart';
import '../../routes/app_routes.dart';
import 'set_income_dialog.dart';

/// Controller for Dashboard view
class DashboardController extends GetxController {
  final BudgetService budgetService = Get.find<BudgetService>();

  // Reactive variables
  final RxBool isIncomeSet = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkIncome();
    refreshData();
  }

  /// Check if income is set
  void checkIncome() {
    isIncomeSet.value = budgetService.monthlyIncome.value > 0;
  }

  /// Refresh dashboard data
  void refreshData() {
    budgetService.loadData();
    checkIncome();
  }

  /// Get formatted month display
  String getFormattedMonth() {
    return budgetService.getFormattedMonth();
  }

  /// Navigate to previous month
  void goToPreviousMonth() {
    budgetService.goToPreviousMonth();
  }

  /// Navigate to next month
  void goToNextMonth() {
    budgetService.goToNextMonth();
  }

  /// Navigate to categories view
  void goToCategories() {
    Get.toNamed(AppRoutes.categories);
  }

  /// Navigate to all transactions view
  void goToAllTransactions() {
    Get.toNamed(AppRoutes.allTransactions);
  }

  /// Navigate to set income dialog
  void showSetIncomeDialog() {
    Get.dialog(
      SetIncomeDialog(
        initialAmount: budgetService.monthlyIncome.value,
      ),
    ).then((result) {
      if (result == true) {
        checkIncome();
      }
    });
  }
}

