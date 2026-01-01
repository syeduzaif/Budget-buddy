import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../services/budget_service.dart';

import '../../routes/app_routes.dart';

/// Controller for Category view
class CategoryController extends GetxController {
  final BudgetService budgetService = Get.find<BudgetService>();

  // Reactive variables
  final Rx<Category?> selectedCategory = Rx<Category?>(null);
  final RxList<TransactionItem> transactions = <TransactionItem>[].obs;
  final RxBool showTransactions = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if category ID is passed via arguments
    final categoryId = Get.arguments as String?;
    if (categoryId != null) {
      loadCategory(categoryId);
    }

    // Listen for transaction updates
    ever(budgetService.transactionUpdateTrigger, (_) {
      if (selectedCategory.value != null) {
        loadTransactions();
      }
    });
  }

  /// Load category and its transactions
  void loadCategory(String categoryId) {
    final category = budgetService.getCategoryById(categoryId);
    if (category != null) {
      selectedCategory.value = category;
      loadTransactions();
      showTransactions.value = true;
    }
  }

  /// Load transactions for selected category
  void loadTransactions() {
    if (selectedCategory.value != null) {
      // Get expenses from BudgetService which has current month context
      final allExpenses = budgetService.expensesForCurrentMonth;
      transactions.value = allExpenses
          .where((t) => t.categoryId == selectedCategory.value!.id)
          .toList();
      transactions.refresh();
    }
  }

  /// Refresh categories list
  void refreshCategories() {
    budgetService.refreshCategories();
  }

  /// Navigate to add category
  void goToAddCategory() {
    Get.toNamed(AppRoutes.addCategory);
  }

  /// Navigate to category transactions
  void goToTransactions(Category category) {
    loadCategory(category.id);
  }

  /// Navigate to add transaction
  void goToAddTransaction(Category category) {
    Get.toNamed(
      AppRoutes.addTransaction,
      arguments: category.id,
    );
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await budgetService.deleteTransaction(transactionId);
    // UI updates automatically via listener
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    await budgetService.deleteCategory(categoryId);

    if (selectedCategory.value?.id == categoryId) {
      selectedCategory.value = null;
      showTransactions.value = false;
      transactions.clear();
    }
  }

  /// Get category spending
  double getCategorySpending(String categoryId) {
    return budgetService.getCategorySpending(categoryId);
  }
}
