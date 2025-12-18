import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../data/models/category.dart';
import '../data/models/transaction_item.dart';
import '../data/models/income_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/income_repository.dart';
import '../utils/helpers.dart';

/// Service to manage budget calculations and category operations
class BudgetService extends GetxService {
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final IncomeRepository _incomeRepository = Get.find<IncomeRepository>();

  // Reactive variables
  final RxList<Category> categories = <Category>[].obs;
  final RxDouble monthlyIncome = 0.0.obs;
  final RxString currentMonth = ''.obs;
  final RxInt transactionUpdateTrigger =
      0.obs; // Trigger updates when transactions change

  // Local state of all data (fetched from Firestore)
  final RxList<Category> _allCategories = <Category>[].obs;
  final RxList<TransactionItem> _allExpenses = <TransactionItem>[].obs;
  final RxList<IncomeModel> _allIncomes = <IncomeModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initStreams();
    currentMonth.value = Helpers.getCurrentMonthKey();
  }

  void _initStreams() {
    // Subscribe to Categories
    _categoryRepository.getCategories().listen((list) {
      _allCategories.assignAll(list);
      refreshCategories();
    });

    // Subscribe to Expenses
    _expenseRepository.getExpenses().listen((list) {
      _allExpenses.assignAll(list);
      notifyTransactionsChanged();
      // Also should create triggers for calculations
      refreshCategories();
    });

    // Subscribe to Income
    _incomeRepository.getIncomes().listen((list) {
      _allIncomes.assignAll(list);
      _calculateMonthlyIncome();
    });
  }

  // Kept for compatibility but now mostly handled by streams
  void loadData() {
    if (currentMonth.value.isEmpty) {
      currentMonth.value = Helpers.getCurrentMonthKey();
    }
    refreshCategories();
    _calculateMonthlyIncome();
  }

  /// Refresh categories list based on current month
  void refreshCategories() {
    categories.value =
        _allCategories.where((cat) => cat.month == currentMonth.value).toList();
    if (categories.isEmpty && _allCategories.isNotEmpty) {
      // Optional: Logic to migrate or copy categories?
      // For now just show empty.
    }
    categories.refresh();
  }

  void _calculateMonthlyIncome() {
    // Filter incomes by current month
    // IncomeModel has 'date'. currentMonth is "YYYY-MM"
    final monthIncomes = _allIncomes.where((inc) {
      final key =
          "${inc.date.year}-${inc.date.month.toString().padLeft(2, '0')}";
      return key == currentMonth.value;
    }).toList();

    double total = monthIncomes.fold(0.0, (sum, item) => sum + item.amount);
    monthlyIncome.value = total;
  }

  /// Calculate total spent across all categories
  double getTotalSpent() {
    // Filter expenses by current month AND category match
    // Or just use categories logic

    // Expenses don't store "month" string usually? TransactionItem has 'date'.
    // We should filter expenses by date matching currentMonth
    final monthExpenses = _getExpensesForCurrentMonth();

    return monthExpenses.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
  }

  List<TransactionItem> _getExpensesForCurrentMonth() {
    return _allExpenses.where((t) {
      final key = "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}";
      return key == currentMonth.value;
    }).toList();
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
    // Current month expenses for this category
    final expenses =
        _getExpensesForCurrentMonth().where((t) => t.categoryId == categoryId);
    return expenses.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  /// Add a new category
  Future<void> addCategory(Category category) async {
    // Ensure category has correct fields for Firestore
    // category.id should be set by sender or we set it?
    // Existing code passes 'category' with ID likely.
    await _categoryRepository.addCategory(category);
    // Refresh happens automatically via stream
  }

  /// Update a category
  Future<void> updateCategory(Category category) async {
    await _categoryRepository.updateCategory(category);
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _categoryRepository.deleteCategory(categoryId);
  }

  /// Notify that transactions have changed
  void notifyTransactionsChanged() {
    transactionUpdateTrigger.value++;
  }

  /// Add a new transaction (Expense)
  Future<void> addTransaction(TransactionItem transaction) async {
    await _expenseRepository.addExpense(transaction);
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _expenseRepository.deleteExpense(id);
  }

  /// Change current month
  Future<void> changeMonth(String newMonth) async {
    // HiveService.setCurrentMonth(newMonth); // No longer needed or maybe store in Prefs?
    // For now, just update local state.
    currentMonth.value = newMonth;
    refreshCategories();
    _calculateMonthlyIncome();
  }

  /// Set monthly income
  Future<void> setIncome(double amount) async {
    // Logic: Find existing income for this month and update, or create new.
    // Simplifying: Just assume one income per month for "Set Income" feature.

    final existingIncomes = _allIncomes.where((inc) {
      final key =
          "${inc.date.year}-${inc.date.month.toString().padLeft(2, '0')}";
      return key == currentMonth.value;
    }).toList();

    // Split currentMonth to year/month
    final parts = currentMonth.value.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month, 1);

    if (existingIncomes.isNotEmpty) {
      // Update first one
      final income = existingIncomes.first;
      income.amount = amount;
      income.updatedAt = DateTime.now();
      await _incomeRepository.updateIncome(income);
    } else {
      // Create new
      final income = IncomeModel(
        id: const Uuid().v4(),
        amount: amount,
        date: date,
        description: 'Monthly Income',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        synced: false,
      );
      await _incomeRepository.addIncome(income);
    }
  }

  /// Get formatted month display
  String getFormattedMonth() {
    return Helpers.formatMonthKey(currentMonth.value);
  }

  /// Get category by ID (from all loaded categories)
  Category? getCategoryById(String id) {
    return _allCategories.firstWhereOrNull((cat) => cat.id == id);
  }

  /// Get expenses for current month
  List<TransactionItem> get expensesForCurrentMonth {
    return _getExpensesForCurrentMonth();
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
