import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/auth/auth_controller.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';

class SettingsController extends GetxController {
  final SettingsService settings = Get.find<SettingsService>();

  final incomeInputController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    incomeInputController.text =
        settings.monthlyIncome.value.toStringAsFixed(0);
  }

  @override
  void onClose() {
    incomeInputController.dispose();
    super.onClose();
  }

  Future<void> saveIncome() async {
    final v = double.tryParse(incomeInputController.text.trim()) ?? 0.0;
    await settings.setMonthlyIncome(v);
    Get.back();
    Get.snackbar('Saved', 'Monthly income updated',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> selectCurrency(Currency currency) async {
    await settings.setCurrency(currency.code, currency.symbol);
    Get.snackbar('Currency updated', '${currency.name} (${currency.symbol})',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> setTheme(String mode) async {
    await settings.setThemeMode(mode);
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await Get.find<AuthController>().signOut();
    } finally {
      isLoading.value = false;
    }
  }
}
