import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

/// Manages Hive initialization and the device-local settings box.
///
/// Settings (currency, income, theme, onboarding) live here. Categories and
/// transactions live in their own boxes, owned by `LocalStoreService`.
class HiveStorage {
  /// Fixed, account-free box name. The app has no sign-in, so there is no uid
  /// to key the box on — deliberately not shaped like one.
  static const String settingsBoxName = 'settings_local';

  static Box? _settingsBox;

  // Settings keys
  static const String _keyCurrencyCode = 'currency_code';
  static const String _keyCurrencySymbol = 'currency_symbol';
  static const String _keyMonthlyIncome = 'monthly_income';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyCurrentMonth = 'current_month';

  /// Register Hive adapters. Called once at app startup before runApp.
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(TransactionItemAdapter());
  }

  /// Open the settings box. Call once at startup, after [init].
  static Future<void> openSettings() async {
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  /// Wipe every stored setting, returning the app to its first-run state.
  /// The box stays open; accessors fall back to their defaults.
  static Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }

  // --- Settings Accessors ---

  static String getCurrencyCode() => _settingsBox?.get(_keyCurrencyCode, defaultValue: 'USD') ?? 'USD';
  static String getCurrencySymbol() => _settingsBox?.get(_keyCurrencySymbol, defaultValue: '\$') ?? '\$';
  static double getMonthlyIncome() => (_settingsBox?.get(_keyMonthlyIncome, defaultValue: 0.0) ?? 0.0).toDouble();
  static String getThemeMode() => _settingsBox?.get(_keyThemeMode, defaultValue: 'system') ?? 'system';
  static bool isOnboardingComplete() => _settingsBox?.get(_keyOnboardingComplete, defaultValue: false) ?? false;
  static String getCurrentMonth() => _settingsBox?.get(_keyCurrentMonth, defaultValue: '') ?? '';

  static Future<void> setCurrencyCode(String code) async => _settingsBox?.put(_keyCurrencyCode, code);
  static Future<void> setCurrencySymbol(String symbol) async => _settingsBox?.put(_keyCurrencySymbol, symbol);
  static Future<void> setMonthlyIncome(double amount) async => _settingsBox?.put(_keyMonthlyIncome, amount);
  static Future<void> setThemeMode(String mode) async => _settingsBox?.put(_keyThemeMode, mode);
  static Future<void> setOnboardingComplete(bool value) async => _settingsBox?.put(_keyOnboardingComplete, value);
  static Future<void> setCurrentMonth(String month) async => _settingsBox?.put(_keyCurrentMonth, month);
}
