import 'package:get/get.dart';
import '../../data/models/transaction_item.dart';
import '../../data/storage/hive_service.dart';
import '../../services/budget_service.dart';
import '../../utils/helpers.dart';

/// Controller for All Transactions view
class TransactionsController extends GetxController {
  final BudgetService budgetService = Get.find<BudgetService>();

  // Reactive variables
  final RxList<TransactionItem> allTransactions = <TransactionItem>[].obs;
  final RxString currentMonth = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
    // Listen to transaction changes
    ever(budgetService.transactionUpdateTrigger, (_) {
      loadTransactions();
    });
  }

  /// Load all transactions
  void loadTransactions() {
    currentMonth.value = budgetService.currentMonth.value;
    final transactions = HiveService.getAllTransactions();
    
    // Filter transactions for current month's categories
    final monthCategories = budgetService.categories
        .map((c) => c.id)
        .toSet();
    
    // Filter and sort transactions
    allTransactions.value = transactions
        .where((t) => monthCategories.contains(t.categoryId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    
    allTransactions.refresh();
  }

  /// Get category name for a transaction
  String getCategoryName(String categoryId) {
    final category = HiveService.getCategoryById(categoryId);
    return category?.name ?? 'Unknown';
  }

  /// Get category color for a transaction
  int getCategoryColor(String categoryId) {
    final category = HiveService.getCategoryById(categoryId);
    return category?.colorValue ?? 0xFF757575;
  }

  /// Get formatted month display
  String getFormattedMonth() {
    return Helpers.formatMonthKey(currentMonth.value);
  }

  /// Refresh transactions
  void refreshTransactions() {
    budgetService.loadData();
    loadTransactions();
  }
}

