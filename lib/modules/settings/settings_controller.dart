import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/validators.dart';

class SettingsController extends GetxController {
  final SettingsService settings = Get.find<SettingsService>();
  final CategoryRepository _categoryRepo = Get.find<CategoryRepository>();
  final TransactionRepository _transactionRepo =
      Get.find<TransactionRepository>();

  final incomeInputController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Minor units are never shown raw: back to major-unit text for editing.
    incomeInputController.text = CurrencyUtils.formatForInput(
        settings.monthlyIncomeMinor.value, settings.currency);
  }

  @override
  void onClose() {
    incomeInputController.dispose();
    super.onClose();
  }

  Future<void> saveIncome() async {
    final currency = settings.currency;
    // Text → minor units directly (C4). A value we cannot read is reported,
    // never silently stored as zero.
    final problem = Validators.amountOrZero(currency)(incomeInputController.text);
    if (problem != null) {
      Get.snackbar('Check the amount', problem,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final incomeMinor =
        CurrencyUtils.tryParseToMinor(incomeInputController.text, currency) ?? 0;
    await settings.setMonthlyIncomeMinor(incomeMinor);
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

  /// Wipes every local box — categories, transactions and settings — and sends
  /// the user back through onboarding. Nothing is stored off-device, so this is
  /// the whole of the user's data.
  Future<void> eraseAllData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _transactionRepo.deleteAll();
      await _categoryRepo.deleteAll();
      await settings.resetToDefaults();
    } catch (e) {
      // Owner-approved mobile convention (2026-07-28): user-visible failures
      // surface via Get.snackbar. Stay on this screen — a partial wipe must
      // not be reported as success.
      Get.snackbar(
        'Could not erase data',
        'Something went wrong. Some data may not have been erased — '
            'please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('[SettingsController] eraseAllData failed: $e');
      return;
    } finally {
      isLoading.value = false;
    }

    // Navigate only after the loading state is settled: this route (and this
    // controller) are disposed by offAllNamed.
    Get.offAllNamed(AppRoutes.onboarding);
  }
}
