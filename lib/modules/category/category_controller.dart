import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../services/budget_service.dart';
import '../../data/storage/hive_service.dart';
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
  }

  /// Load category and its transactions
  void loadCategory(String categoryId) {
    final category = HiveService.getCategoryById(categoryId);
    if (category != null) {
      selectedCategory.value = category;
      loadTransactions();
      showTransactions.value = true;
    }
  }

  /// Load transactions for selected category
  void loadTransactions() {
    if (selectedCategory.value != null) {
      transactions.value = HiveService.getTransactionsByCategory(
        selectedCategory.value!.id,
      );
      transactions.refresh();
    }
  }

  /// Refresh categories list
  void refreshCategories() {
    budgetService.refreshCategories();
  }

  /// Navigate to add category
  void goToAddCategory() {
    Get.toNamed(AppRoutes.addCategory)?.then((_) {
      refreshCategories();
    });
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
    )?.then((_) {
      loadTransactions();
      refreshCategories();
    });
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await HiveService.deleteTransaction(transactionId);
    budgetService.notifyTransactionsChanged();
    loadTransactions();
    refreshCategories();
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    // Delete all transactions first
    final categoryTransactions = HiveService.getTransactionsByCategory(categoryId);
    for (final transaction in categoryTransactions) {
      await HiveService.deleteTransaction(transaction.id);
    }
    
    // Delete category
    await budgetService.deleteCategory(categoryId);
    refreshCategories();
    
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

