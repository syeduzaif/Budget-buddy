import 'package:get/get.dart';
import '../data/models/category.dart';
import '../data/storage/hive_service.dart';
import '../utils/helpers.dart';

/// Service to manage budget calculations and category operations
class BudgetService extends GetxService {
  // Reactive variables
  final RxList<Category> categories = <Category>[].obs;
  final RxDouble monthlyIncome = 0.0.obs;
  final RxString currentMonth = ''.obs;
  final RxInt transactionUpdateTrigger = 0.obs; // Trigger updates when transactions change

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// Load all data for current month
  void loadData() {
    currentMonth.value = HiveService.getCurrentMonth();
    monthlyIncome.value = HiveService.getMonthlyIncome();
    refreshCategories();
  }

  /// Refresh categories list
  void refreshCategories() {
    categories.value = HiveService.getCategoriesForMonth(currentMonth.value);
    categories.refresh();
  }

  /// Calculate total spent across all categories
  double getTotalSpent() {
    final allTransactions = HiveService.getAllTransactions();
    double total = 0.0;

    for (final category in categories) {
      final categoryTransactions = allTransactions
          .where((t) => t.categoryId == category.id)
          .toList();
      total += categoryTransactions.fold(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );
    }

    return total;
  }

  /// Calculate total budget allocated across all categories
  double getTotalBudgetAllocated() {
    return categories.fold(
      0.0,
      (sum, category) => sum + category.budgetLimit,
    );
  }

  /// Calculate unallocated budget
  double getUnallocatedBudget() {
    return monthlyIncome.value - getTotalBudgetAllocated();
  }

  /// Calculate total remaining (income - spent)
  double getTotalRemaining() {
    return monthlyIncome.value - getTotalSpent();
  }

  /// Get spending for a specific category
  double getCategorySpending(String categoryId) {
    final transactions = HiveService.getTransactionsByCategory(categoryId);
    return transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  /// Add a new category
  Future<void> addCategory(Category category) async {
    await HiveService.addCategory(category);
    refreshCategories();
    transactionUpdateTrigger.value++;
  }

  /// Update a category
  Future<void> updateCategory(Category category) async {
    await HiveService.updateCategory(category);
    refreshCategories();
    transactionUpdateTrigger.value++;
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await HiveService.deleteCategory(categoryId);
    refreshCategories();
    transactionUpdateTrigger.value++;
  }
  
  /// Notify that transactions have changed
  void notifyTransactionsChanged() {
    transactionUpdateTrigger.value++;
  }

  /// Change current month
  Future<void> changeMonth(String newMonth) async {
    await HiveService.setCurrentMonth(newMonth);
    currentMonth.value = newMonth;
    refreshCategories();
  }

  /// Set monthly income
  Future<void> setIncome(double amount) async {
    await HiveService.setMonthlyIncome(amount);
    monthlyIncome.value = amount;
  }

  /// Get formatted month display
  String getFormattedMonth() {
    return Helpers.formatMonthKey(currentMonth.value);
  }

  /// Navigate to previous month
  void goToPreviousMonth() {
    final previousMonth = Helpers.getPreviousMonthKey(currentMonth.value);
    changeMonth(previousMonth);
  }

  /// Navigate to next month
  void goToNextMonth() {
    final nextMonth = Helpers.getNextMonthKey(currentMonth.value);
    changeMonth(nextMonth);
  }
}

