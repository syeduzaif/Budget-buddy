import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/local/hive_storage.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

/// Reactive wrapper over HiveStorage settings.
/// All controllers read from this service, never from HiveStorage directly.
class SettingsService extends GetxService {
  final RxString currencyCode = 'USD'.obs;
  /// Persisted copy of the selected currency's symbol. [currency] is the
  /// display source of truth — read `currency.symbol`, not this — but the
  /// stored value is kept so the settings box stays self-describing.
  final RxString currencySymbol = '\$'.obs;

  /// Monthly income in integer MINOR UNITS of [currency].
  final RxInt monthlyIncomeMinor = 0.obs;

  final RxString themeMode = 'system'.obs;
  final RxString currentMonth = ''.obs;
  final RxBool onboardingComplete = false.obs;

  /// The selected currency, resolved from the stored code (falls back to USD).
  ///
  /// The single source of `decimalDigits` for every format, parse and
  /// conversion in the app — read this, not the bare symbol. Reading it inside
  /// an `Obx` tracks [currencyCode], so the UI reformats when it changes.
  Currency get currency => CurrencyUtils.resolve(currencyCode.value);

  /// The month key writes should be stamped with. One place, so a stamped
  /// month and a derived month can never disagree.
  String get effectiveMonth => currentMonth.value.isNotEmpty
      ? currentMonth.value
      : AppDateUtils.getCurrentMonthKey();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// Wipe every stored preference and drop the reactive values back to their
  /// first-run defaults. Controllers must come through here rather than
  /// touching HiveStorage.
  Future<void> resetToDefaults() async {
    await HiveStorage.clearSettings();
    _load();
  }

  void _load() {
    currencyCode.value = HiveStorage.getCurrencyCode();
    currencySymbol.value = HiveStorage.getCurrencySymbol();
    monthlyIncomeMinor.value = HiveStorage.getMonthlyIncomeMinor();
    themeMode.value = HiveStorage.getThemeMode();
    onboardingComplete.value = HiveStorage.isOnboardingComplete();
    final stored = HiveStorage.getCurrentMonth();
    currentMonth.value = stored.isNotEmpty ? stored : AppDateUtils.getCurrentMonthKey();
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Persist first, then publish. If a write fails the reactive value must not
  // already be showing the change: a screen that displays what was never
  // saved is the same lie as a success message for a failed write (H3).

  Future<void> setCurrency(String code, String symbol) async {
    await HiveStorage.setCurrencyCode(code);
    await HiveStorage.setCurrencySymbol(symbol);
    currencyCode.value = code;
    currencySymbol.value = symbol;
  }

  Future<void> setMonthlyIncomeMinor(int minorUnits) async {
    await HiveStorage.setMonthlyIncomeMinor(minorUnits);
    monthlyIncomeMinor.value = minorUnits;
  }

  Future<void> setThemeMode(String mode) async {
    await HiveStorage.setThemeMode(mode);
    themeMode.value = mode;
    Get.changeThemeMode(flutterThemeMode);
  }

  Future<void> setCurrentMonth(String month) async {
    await HiveStorage.setCurrentMonth(month);
    currentMonth.value = month;
  }

  Future<void> completeOnboarding() async {
    await HiveStorage.setOnboardingComplete(true);
    onboardingComplete.value = true;
  }
}
