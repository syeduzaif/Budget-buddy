import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
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

  /// The category name the last saved transaction used, or null if none has
  /// been saved yet.
  ///
  /// Deliberately NOT an `Rx`, unlike every other setting on this service: it is
  /// read exactly once, when the Add sheet opens, and nothing on screen should
  /// rebuild when it changes. An observable here would invite an `Obx` to depend
  /// on a preference (F-06).
  ///
  /// Read straight from the box, so the value survives process death for free
  /// and `resetToDefaults` wipes it with everything else.
  String? get lastUsedCategoryName {
    final stored = HiveStorage.getLastUsedCategoryName();
    return stored.isEmpty ? null : stored;
  }

  /// Remembers [name] as the category the next Add sheet should open on.
  ///
  /// The reserved bucket is never stored — the row that exists to REPORT a data
  /// problem must not become the default that creates one (palwasha 8c). The
  /// guard lives here rather than at the call site so it holds for every future
  /// caller.
  ///
  /// A name, not an id: month clones mint fresh Uuids, so a stored id goes stale
  /// at the first rollover by construction.
  Future<void> rememberLastUsedCategory(String name) async {
    if (isReservedCategoryName(name)) return;
    await HiveStorage.setLastUsedCategoryName(name);
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// Wipe every stored preference and drop the reactive values back to their
  /// first-run defaults. Controllers must come through here rather than
  /// touching HiveStorage.
  Future<void> resetToDefaults() async {
    await clearStoredSettings();
    _load();
    // Republished, not just reset: [_load] puts `themeMode` back to 'system'
    // but only Get.changeThemeMode makes a theme change take effect in the
    // running app (see [setThemeMode]). Without this, "Erase all data"
    // promises to delete every preference while the erased theme stays on
    // screen for the rest of the session (N3).
    //
    // This line is what made BUG-100 reachable — a theme change here animates
    // while the caller resets the route stack — but the defect was never the
    // ordering: it was that light's and dark's button text styles disagreed
    // about `inherit`, so `TextStyle.lerp` asserted. Fixed at that source, in
    // `AppTheme._buttonTextStyle`. Deferring this republish by a frame was tried
    // and rejected: it moved the crash from the onboarding button to the dialog's
    // (both measured in `test/erase_flow_test.dart`), which is how the real cause
    // was found.
    Get.changeThemeMode(flutterThemeMode);
  }

  /// Just the box wipe inside [resetToDefaults], as its own overridable step.
  ///
  /// A seam, and a deliberately narrow one: a Hive write is real disk I/O and
  /// only completes under `tester.runAsync`, which in a widget test also lets
  /// `AppFonts`' font downloads fail loudly. Overriding this one method lets
  /// `test/erase_flow_test.dart` drive the REST of the reset — the reload and the
  /// theme republish that BUG-100 travelled through — as shipped, instead of
  /// re-implementing it in the test and pinning nothing.
  @visibleForTesting
  Future<void> clearStoredSettings() => HiveStorage.clearSettings();

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
