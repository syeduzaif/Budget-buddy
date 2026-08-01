import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category.dart';
import '../../data/predefined_categories.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';
import '../../utils/validators.dart';

class OnboardingController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();

  final pageController = PageController();
  final currentPage = 0.obs;

  final selectedCurrency = CurrencyUtils.usd.obs;
  final incomeController = TextEditingController();

  @override
  void onClose() {
    pageController.dispose();
    incomeController.dispose();
    super.onClose();
  }

  void nextPage() {
    if (currentPage.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int index) => currentPage.value = index;

  void selectCurrency(Currency currency) => selectedCurrency.value = currency;

  Future<void> finish() async {
    final currency = selectedCurrency.value;
    // Text → minor units in the currency just chosen (C4). "Skip for now"
    // leaves the field empty — a deliberate zero. Anything else that will not
    // parse is shown to the user, never silently stored as zero income.
    final problem = Validators.amountOrZero(currency)(incomeController.text);
    if (problem != null) {
      Get.snackbar('Check the amount', problem,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final incomeMinor =
        CurrencyUtils.tryParseToMinor(incomeController.text, currency) ?? 0;
    final month = AppDateUtils.getCurrentMonthKey();
    try {
      await _settings.setCurrency(currency.code, currency.symbol);
      await _settings.setMonthlyIncomeMinor(incomeMinor);
      await _settings.setCurrentMonth(month);
      await _seedDefaultCategories(month, currency);
      // Last, and only once the rest landed: this is the flag that stops the
      // app ever showing onboarding again, so a half-finished setup must not
      // set it.
      await _settings.completeOnboarding();
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. A write that threw must
      // never be followed by a success message (H3).
      debugPrint('[OnboardingController] finish failed: $e\n$stack');
      Get.snackbar(
        'Could not finish setup',
        'Setup did not complete. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }

  /// Seeds the preset categories, converting each preset's whole-major-unit
  /// budget into the chosen currency's minor units.
  Future<void> _seedDefaultCategories(String month, Currency currency) async {
    final categoryRepo = Get.find<CategoryRepository>();
    const uuid = Uuid();
    final now = DateTime.now();

    final categories = kPredefinedCategories
        .map((preset) => Category(
              id: uuid.v4(),
              name: preset.name,
              budgetLimitMinor:
                  CurrencyUtils.fromMajor(preset.defaultBudgetMajor, currency),
              colorValue: preset.colorValue,
              iconCodePoint: preset.iconCodePoint,
              month: month,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();

    await categoryRepo.addCategories(categories);
  }
}
