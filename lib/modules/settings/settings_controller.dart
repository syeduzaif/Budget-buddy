import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/app/csv_export.dart';
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

  /// Separate from [isLoading]: an export in flight must not make the erase
  /// row look busy, and vice versa.
  final isExporting = false.obs;

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
    try {
      await settings.setMonthlyIncomeMinor(incomeMinor);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. A write that threw must
      // never be followed by a success message (H3).
      debugPrint('[SettingsController] saveIncome failed: $e\n$stack');
      Get.snackbar('Could not save', 'Your income was not changed.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.back();
    Get.snackbar('Saved', 'Monthly income updated',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> selectCurrency(Currency currency) async {
    try {
      await settings.setCurrency(currency.code, currency.symbol);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. A write that threw must
      // never be followed by a success message (H3).
      debugPrint('[SettingsController] selectCurrency failed: $e\n$stack');
      Get.snackbar('Could not save', 'Your currency was not changed.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.snackbar('Currency updated', '${currency.name} (${currency.symbol})',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> setTheme(String mode) async {
    try {
      await settings.setThemeMode(mode);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. A write that threw must
      // never be followed by a success message (H3).
      debugPrint('[SettingsController] setTheme failed: $e\n$stack');
      Get.snackbar('Could not save', 'Your theme was not changed.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Writes every transaction to a CSV in the temp directory and opens the
  /// share sheet (F-13).
  ///
  /// Nothing to export is not a failure: the row stays tappable and says so,
  /// rather than opening an empty share sheet. Success needs no snackbar — the
  /// share sheet is the feedback.
  ///
  /// [sharePositionOrigin] comes from the tapped row and only matters on iPad
  /// and Mac, where the sheet is a popover anchored to something.
  Future<void> exportCsv({Rect? sharePositionOrigin}) async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final transactions = await _transactionRepo.getAllTransactions();
      if (transactions.isEmpty) {
        Get.snackbar('Nothing to export yet',
            'Add a transaction and it will appear in the file.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final categories = await _categoryRepo.getAllCategories();
      final csv = CsvExport.buildCsv(
        transactions: transactions,
        categories: categories,
        currency: settings.currency,
      );
      final file = await CsvExport.writeToTemp(csv, now: DateTime.now());
      await CsvExport.share(file, sharePositionOrigin: sharePositionOrigin);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible failures
      // surface via Get.snackbar. A share sheet that never opened must not be
      // followed by silence (H3).
      debugPrint('[SettingsController] exportCsv failed: $e\n$stack');
      Get.snackbar('Could not export',
          'The file was not created. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isExporting.value = false;
    }
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
