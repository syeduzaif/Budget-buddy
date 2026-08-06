import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category.dart';
import '../../data/predefined_categories.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_clock.dart';
import '../../utils/currency_utils.dart';
import '../../utils/validators.dart';

class OnboardingController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();

  final pageController = PageController();
  final currentPage = 0.obs;

  /// D-009. The whole of the decision: the picker opens on PKR instead of USD,
  /// because that is the market this app is being built for. The resolver
  /// fallback for an absent or corrupt stored code stays USD
  /// (`hive_storage.dart:92`) — that is a data-interpretation rule, not a
  /// market choice, and the two must not be confused for one setting.
  final selectedCurrency = CurrencyUtils.pkr.obs;
  final incomeController = TextEditingController();

  /// True while [finish] is running. Drives the primary button's spinner and
  /// disables BOTH controls that call [finish] — see `onboarding_view.dart`.
  final isLoading = false.obs;

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

  /// Persists the answers and seeds the nine preset categories, exactly once.
  ///
  /// The re-entrancy latch is not defensive tidiness, it is the fix for
  /// D-026/5(b). TWO live controls call this bare — "Start Budgeting" and
  /// "Skip for now", `onboarding_view.dart:252,257` before this change — and
  /// the reachable path was never a mistimed double tap. It was a user tapping
  /// the primary button, seeing nothing at all for five awaited Hive writes,
  /// and tapping the control sitting underneath it, which is the expected
  /// behaviour of a button that appears not to have worked.
  ///
  /// A second entry seeds nine MORE categories. `ensureMonth` then clones the
  /// duplicated set forward with fresh UUIDs every month
  /// (`category_repository.dart:364-379`), so month one's duplication
  /// propagates for the life of the install and every rung of F-09's warning
  /// ladder reads 2× limits against 1× income — permanently. Recovery is nine
  /// manual deletes by a user with no way to know that is the problem, or Erase
  /// All Data. The latch is the truth; the disabled controls in the view are
  /// what stop the second tap being made at all.
  ///
  /// The whole method is inside the latch, validation included: the validator
  /// is synchronous, so a rejected amount releases it before any frame is
  /// built.
  Future<void> finish() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
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
      final month = AppClock.nowMonthKey();
      await _settings.setCurrency(currency.code, currency.symbol);
      await _settings.setMonthlyIncomeMinor(incomeMinor);
      await _settings.setCurrentMonth(month);
      await _seedDefaultCategories(month, currency, incomeMinor);
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
    } finally {
      // Released before navigating, like `SettingsController.eraseAllData`:
      // `offAllNamed` disposes this route and this controller, so the flag must
      // settle first. Nothing can slip through the gap — there is no `await`
      // between the release and the navigation below, so no tap can be
      // delivered in between.
      isLoading.value = false;
    }
    Get.offAllNamed(AppRoutes.home);
  }

  /// Seeds the preset categories, sizing each limit to the income just
  /// entered (`PredefinedCategory.seedLimitMinor`) in the chosen currency's
  /// minor units. Skipped/zero income falls back to the presets' own
  /// major-unit figures.
  Future<void> _seedDefaultCategories(
      String month, Currency currency, int incomeMinor) async {
    final categoryRepo = Get.find<CategoryRepository>();
    const uuid = Uuid();
    final now = DateTime.now();

    final categories = kPredefinedCategories
        .map((preset) => Category(
              id: uuid.v4(),
              name: preset.name,
              budgetLimitMinor: preset.seedLimitMinor(incomeMinor, currency),
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
