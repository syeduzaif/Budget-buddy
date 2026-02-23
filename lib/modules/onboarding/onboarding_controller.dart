import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/app/settings_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

class OnboardingController extends GetxController {
  final SettingsService _settings = Get.find<SettingsService>();

  final pageController = PageController();
  final currentPage = 0.obs;

  final selectedCurrency = const Currency(code: 'USD', name: 'US Dollar', symbol: '\$').obs;
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
    final income = double.tryParse(incomeController.text.trim()) ?? 0.0;
    await _settings.setCurrency(selectedCurrency.value.code, selectedCurrency.value.symbol);
    await _settings.setMonthlyIncome(income);
    await _settings.setCurrentMonth(AppDateUtils.getCurrentMonthKey());
    await _settings.completeOnboarding();
    Get.offAllNamed(AppRoutes.home);
  }
}
