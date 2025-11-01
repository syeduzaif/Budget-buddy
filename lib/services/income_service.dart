import 'package:get/get.dart';
import 'budget_service.dart';

/// Service to manage income operations
class IncomeService extends GetxService {
  final BudgetService budgetService = Get.find<BudgetService>();

  /// Set monthly income
  Future<void> setMonthlyIncome(double amount) async {
    await budgetService.setIncome(amount);
  }

  /// Get monthly income
  double getMonthlyIncome() {
    return budgetService.monthlyIncome.value;
  }
}

