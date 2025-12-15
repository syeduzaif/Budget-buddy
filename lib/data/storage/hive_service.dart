import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/chat_message_model.dart';
import 'hive_boxes.dart';
import '../../utils/helpers.dart';

/// Service to handle all Hive database operations
class HiveService {
  /// Initialize Hive and register adapters
  /// Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }

    // Boxes are now opened by UserSessionService based on authenticated user
  }

  // ============ SETTINGS ============

  /// Get monthly income
  static double getMonthlyIncome() {
    final box = HiveBoxes.getSettingsBox();
    return box.get(HiveBoxes.incomeKey, defaultValue: 0.0) as double;
  }

  /// Set monthly income
  static Future<void> setMonthlyIncome(double amount) async {
    final box = HiveBoxes.getSettingsBox();
    await box.put(HiveBoxes.incomeKey, amount);
  }

  /// Get current selected month
  static String getCurrentMonth() {
    final box = HiveBoxes.getSettingsBox();
    return box.get(
      HiveBoxes.currentMonthKey,
      defaultValue: Helpers.getCurrentMonthKey(),
    ) as String;
  }

  /// Set current month
  static Future<void> setCurrentMonth(String month) async {
    final box = HiveBoxes.getSettingsBox();
    await box.put(HiveBoxes.currentMonthKey, month);
  }

  /// Get selected currency code
  static String getSelectedCurrency() {
    final box = HiveBoxes.getSettingsBox();
    return box.get(HiveBoxes.currencyKey, defaultValue: 'INR') as String;
  }

  /// Set selected currency code
  static Future<void> setSelectedCurrency(String currencyCode) async {
    final box = HiveBoxes.getSettingsBox();
    await box.put(HiveBoxes.currencyKey, currencyCode);
    await box.put(
        HiveBoxes.currencySymbolKey, _getCurrencySymbol(currencyCode));
    await box.put(HiveBoxes.hasSelectedCurrencyKey, true);
  }

  /// Get currency symbol
  static String getCurrencySymbol() {
    final box = HiveBoxes.getSettingsBox();
    final symbol = box.get(HiveBoxes.currencySymbolKey);
    if (symbol != null) {
      return symbol as String;
    }
    return _getCurrencySymbol(getSelectedCurrency());
  }

  /// Check if user has selected currency
  static bool hasSelectedCurrency() {
    final box = HiveBoxes.getSettingsBox();
    return box.get(HiveBoxes.hasSelectedCurrencyKey, defaultValue: false)
        as bool;
  }

  /// Get currency symbol for currency code
  static String _getCurrencySymbol(String currencyCode) {
    const currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'INR': '₹',
      'JPY': '¥',
      'CNY': '¥',
      'AUD': '\$',
      'CAD': '\$',
      'CHF': 'Fr',
      'SGD': '\$',
      'MYR': 'RM',
      'AED': 'د.إ',
      'PKR': '₨',
      'BDT': '৳',
      'NZD': '\$',
      'ZAR': 'R',
      'BRL': 'R\$',
      'MXN': '\$',
      'KRW': '₩',
      'THB': '฿',
      'IDR': 'Rp',
      'PHP': '₱',
      'VND': '₫',
    };
    return currencySymbols[currencyCode] ?? currencyCode;
  }

  // ============ CATEGORIES ============

  /// Get all categories
  static List<Category> getAllCategories() {
    final box = HiveBoxes.getCategoriesBox();
    return box.values.toList();
  }

  /// Get categories for a specific month
  static List<Category> getCategoriesForMonth(String month) {
    final box = HiveBoxes.getCategoriesBox();
    return box.values.where((cat) => cat.month == month).toList();
  }

  /// Add a new category
  static Future<void> addCategory(Category category) async {
    final box = HiveBoxes.getCategoriesBox();
    await box.put(category.id, category);
  }

  /// Update a category
  static Future<void> updateCategory(Category category) async {
    final box = HiveBoxes.getCategoriesBox();
    await box.put(category.id, category);
  }

  /// Delete a category
  static Future<void> deleteCategory(String id) async {
    final box = HiveBoxes.getCategoriesBox();
    await box.delete(id);
  }

  /// Get category by ID
  static Category? getCategoryById(String id) {
    final box = HiveBoxes.getCategoriesBox();
    return box.get(id);
  }

  // ============ TRANSACTIONS ============

  /// Get all transactions
  static List<TransactionItem> getAllTransactions() {
    final box = HiveBoxes.getTransactionsBox();
    return box.values.toList();
  }

  /// Get transactions for a specific category
  static List<TransactionItem> getTransactionsByCategory(String categoryId) {
    final box = HiveBoxes.getTransactionsBox();
    return box.values
        .where((transaction) => transaction.categoryId == categoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  /// Add a new transaction
  static Future<void> addTransaction(TransactionItem transaction) async {
    final box = HiveBoxes.getTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  /// Update a transaction
  static Future<void> updateTransaction(TransactionItem transaction) async {
    final box = HiveBoxes.getTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  /// Delete a transaction
  static Future<void> deleteTransaction(String id) async {
    final box = HiveBoxes.getTransactionsBox();
    await box.delete(id);
  }

  /// Get transaction by ID
  static TransactionItem? getTransactionById(String id) {
    final box = HiveBoxes.getTransactionsBox();
    return box.get(id);
  }

  // ============ UTILITY ============

  /// Clear all data (useful for testing)
  static Future<void> clearAllData() async {
    await HiveBoxes.getCategoriesBox().clear();
    await HiveBoxes.getTransactionsBox().clear();
    await HiveBoxes.getSettingsBox().clear();
  }

  /// Close all boxes
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}
