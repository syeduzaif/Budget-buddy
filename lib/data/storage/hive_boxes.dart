import 'package:hive/hive.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/chat_message_model.dart';

/// Central place to manage Hive box names and access
class HiveBoxes {
  static const String categoriesBox = 'categories';
  static const String transactionsBox = 'transactions';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String incomeKey = 'monthly_income';
  static const String currentMonthKey = 'current_month';
  static const String currencyKey = 'selected_currency';
  static const String currencySymbolKey = 'currency_symbol';
  static const String hasSelectedCurrencyKey = 'has_selected_currency';

  static const String chatBox = 'chat_messages';

  /// Get Categories Box
  static Box<Category> getCategoriesBox() {
    return Hive.box<Category>(categoriesBox);
  }

  /// Get Transactions Box
  static Box<TransactionItem> getTransactionsBox() {
    return Hive.box<TransactionItem>(transactionsBox);
  }

  /// Get Chat Box
  static Box<ChatMessageModel> getChatBox() {
    return Hive.box<ChatMessageModel>(chatBox);
  }

  /// Get Settings Box
  static Box getSettingsBox() {
    return Hive.box(settingsBox);
  }

  /// Check if all boxes are open
  static bool isInitialized() {
    return Hive.isBoxOpen(categoriesBox) &&
        Hive.isBoxOpen(transactionsBox) &&
        Hive.isBoxOpen(chatBox) &&
        Hive.isBoxOpen(settingsBox);
  }
}
