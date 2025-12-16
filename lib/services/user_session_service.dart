import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/category.dart';
import '../data/models/transaction_item.dart';
import '../data/models/chat_message_model.dart';

/// Service to manage user-specific data and session
class UserSessionService extends GetxService {
  String? _currentUserId;

  // User-specific box references
  Box<Category>? _categoriesBox;
  Box<TransactionItem>? _transactionsBox;
  Box<ChatMessageModel>? _chatBox;
  Box? _settingsBox;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Initialize user session with user-specific data
  Future<void> initializeUserSession(String userId) async {
    _currentUserId = userId;

    // Open user-specific boxes
    _categoriesBox = await Hive.openBox<Category>('categories_$userId');
    _transactionsBox =
        await Hive.openBox<TransactionItem>('transactions_$userId');
    _chatBox = await Hive.openBox<ChatMessageModel>('chat_$userId');
    _settingsBox = await Hive.openBox('settings_$userId');
  }

  /// Clear user session (on logout)
  Future<void> clearUserSession() async {
    // Close user-specific boxes
    await _categoriesBox?.close();
    await _transactionsBox?.close();
    await _chatBox?.close();
    await _settingsBox?.close();

    // Clear references
    _categoriesBox = null;
    _transactionsBox = null;
    _chatBox = null;
    _settingsBox = null;
    _currentUserId = null;
  }

  /// Get user-specific categories box
  Box<Category> getCategoriesBox() {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw Exception('Categories box not initialized. Please login first.');
    }
    return _categoriesBox!;
  }

  /// Get user-specific transactions box
  Box<TransactionItem> getTransactionsBox() {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      throw Exception('Transactions box not initialized. Please login first.');
    }
    return _transactionsBox!;
  }

  /// Get user-specific chat box
  Box<ChatMessageModel> getChatBox() {
    if (_chatBox == null || !_chatBox!.isOpen) {
      throw Exception('Chat box not initialized. Please login first.');
    }
    return _chatBox!;
  }

  /// Get user-specific settings box
  Box getSettingsBox() {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box not initialized. Please login first.');
    }
    return _settingsBox!;
  }

  /// Check if user session is active
  bool get isSessionActive =>
      _currentUserId != null &&
      _categoriesBox != null &&
      _categoriesBox!.isOpen;
}
