import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/local/hive_storage.dart';
import '../../utils/date_utils.dart';

/// Reactive wrapper over HiveStorage settings.
/// All controllers read from this service, never from HiveStorage directly.
class SettingsService extends GetxService {
  final RxString currencyCode = 'USD'.obs;
  final RxString currencySymbol = '\$'.obs;
  final RxDouble monthlyIncome = 0.0.obs;
  final RxString themeMode = 'system'.obs;
  final RxString currentMonth = ''.obs;
  final RxBool onboardingComplete = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    currencyCode.value = HiveStorage.getCurrencyCode();
    currencySymbol.value = HiveStorage.getCurrencySymbol();
    monthlyIncome.value = HiveStorage.getMonthlyIncome();
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

  Future<void> setCurrency(String code, String symbol) async {
    currencyCode.value = code;
    currencySymbol.value = symbol;
    await HiveStorage.setCurrencyCode(code);
    await HiveStorage.setCurrencySymbol(symbol);
  }

  Future<void> setMonthlyIncome(double amount) async {
    monthlyIncome.value = amount;
    await HiveStorage.setMonthlyIncome(amount);
  }

  Future<void> setThemeMode(String mode) async {
    themeMode.value = mode;
    await HiveStorage.setThemeMode(mode);
    Get.changeThemeMode(flutterThemeMode);
  }

  Future<void> setCurrentMonth(String month) async {
    currentMonth.value = month;
    await HiveStorage.setCurrentMonth(month);
  }

  Future<void> completeOnboarding() async {
    onboardingComplete.value = true;
    await HiveStorage.setOnboardingComplete(true);
  }
}
