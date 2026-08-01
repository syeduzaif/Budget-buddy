import 'package:flutter/foundation.dart' show debugPrint;
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

  /// Monthly income in integer MINOR UNITS.
  ///
  /// Deliberately a NEW key: the pre-C4 `monthly_income` held a major-unit
  /// `double` in an untyped box, and `12.5` vs `1250` are both plausible
  /// readings of the same slot. A new name makes the unit unambiguous on disk
  /// and makes a stale value impossible to misread. [_keyLegacyMonthlyIncome]
  /// is deleted on open.
  static const String _keyMonthlyIncomeMinor = 'monthly_income_minor';
  static const String _keyLegacyMonthlyIncome = 'monthly_income';

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
    final box = await Hive.openBox(settingsBoxName);
    _settingsBox = box;

    // Drop the pre-C4 major-unit income left behind on a developer's device.
    // Nothing reads it any more; removing it stops it lingering in an untyped
    // box where a future reader could mistake it for minor units.
    if (box.containsKey(_keyLegacyMonthlyIncome)) {
      debugPrint('[HiveStorage] removing pre-C4 "$_keyLegacyMonthlyIncome"');
      await box.delete(_keyLegacyMonthlyIncome);
    }
  }

  /// Wipe every stored setting, returning the app to its first-run state.
  /// The box stays open; accessors fall back to their defaults.
  static Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }

  /// The open settings box, or a failure.
  ///
  /// Every write goes through this. The old `_settingsBox?.put(...)` completed
  /// successfully when the box was not open, so the caller happily reported
  /// "Saved" for a value that was never written — the H3 defect, at its
  /// source. Throwing instead lets the controllers' error handling do its job.
  static Box get _box {
    final box = _settingsBox;
    if (box == null) {
      throw StateError(
          'HiveStorage.openSettings() must run before settings are written');
    }
    return box;
  }

  // --- Settings Accessors ---
  //
  // Reads are guarded by type rather than cast (H2): the box is untyped, so a
  // value of the wrong type must fall back to the default instead of throwing
  // on the startup path. Writes are not guarded — they must fail loudly.

  static String getCurrencyCode() => _read<String>(_keyCurrencyCode, 'USD');
  static String getCurrencySymbol() => _read<String>(_keyCurrencySymbol, '\$');

  /// Monthly income in minor units.
  static int getMonthlyIncomeMinor() => _read<int>(_keyMonthlyIncomeMinor, 0);

  static String getThemeMode() => _read<String>(_keyThemeMode, 'system');
  static bool isOnboardingComplete() =>
      _read<bool>(_keyOnboardingComplete, false);
  static String getCurrentMonth() => _read<String>(_keyCurrentMonth, '');

  static T _read<T>(String key, T fallback) {
    final stored = _settingsBox?.get(key);
    return stored is T ? stored : fallback;
  }

  static Future<void> setCurrencyCode(String code) => _box.put(_keyCurrencyCode, code);
  static Future<void> setCurrencySymbol(String symbol) => _box.put(_keyCurrencySymbol, symbol);
  static Future<void> setMonthlyIncomeMinor(int minorUnits) => _box.put(_keyMonthlyIncomeMinor, minorUnits);
  static Future<void> setThemeMode(String mode) => _box.put(_keyThemeMode, mode);
  static Future<void> setOnboardingComplete(bool value) => _box.put(_keyOnboardingComplete, value);
  static Future<void> setCurrentMonth(String month) => _box.put(_keyCurrentMonth, month);
}
