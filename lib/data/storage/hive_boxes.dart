import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../services/user_session_service.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/chat_message_model.dart';

/// Central place to manage Hive box names and access
class HiveBoxes {
  // Box names are now dynamic based on user ID, managed by UserSessionService
  // Keeping keys for usage in UserSessionService and Settings

  // Settings keys
  static const String incomeKey = 'monthly_income';
  static const String currentMonthKey = 'current_month';
  static const String currencyKey = 'selected_currency';
  static const String currencySymbolKey = 'currency_symbol';
  static const String hasSelectedCurrencyKey = 'has_selected_currency';

  // These might act as prefixes now, but the actual box name includes the UID
  static const String categoriesBoxPrefix = 'categories';
  static const String transactionsBoxPrefix = 'transactions';
  static const String settingsBoxPrefix = 'settings';
  static const String chatBoxPrefix = 'chat';

  /// Get Categories Box for current user
  static Box<Category> getCategoriesBox() {
    return Get.find<UserSessionService>().getCategoriesBox();
  }

  /// Get Transactions Box for current user
  static Box<TransactionItem> getTransactionsBox() {
    return Get.find<UserSessionService>().getTransactionsBox();
  }

  /// Get Chat Box for current user
  static Box<ChatMessageModel> getChatBox() {
    return Get.find<UserSessionService>().getChatBox();
  }

  /// Get Settings Box for current user
  static Box getSettingsBox() {
    return Get.find<UserSessionService>().getSettingsBox();
  }

  /// Check if user session and boxes are initialized
  static bool isInitialized() {
    try {
      final session = Get.find<UserSessionService>();
      return session.isSessionActive;
    } catch (_) {
      return false;
    }
  }
}
