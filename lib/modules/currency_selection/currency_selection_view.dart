import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'currency_selection_controller.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';

/// View for selecting currency on first launch
class CurrencySelectionView extends StatelessWidget {
  const CurrencySelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CurrencySelectionController>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.paddingXL),
              // Title
              Icon(
                Icons.currency_exchange,
                size: 64,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingL),
              Text(
                'Select Your Currency',
                style: AppConstants.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Choose the currency you want to use for your budget',
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingXL),
              // Currency list
              Expanded(
                child: ListView.builder(
                  itemCount: CurrencyHelper.currencies.length,
                  itemBuilder: (context, index) {
                    final currency = CurrencyHelper.currencies[index];
                    return Obx(() => _buildCurrencyTile(
                      currency: currency,
                      isSelected: controller.isCurrencySelected(currency),
                      onTap: () => controller.selectCurrency(currency),
                    ));
                  },
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              // Continue button
              Obx(() => ElevatedButton(
                onPressed: controller.selectedCurrency.value != null
                    ? controller.saveCurrency
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyTile({
    required Currency currency,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        side: BorderSide(
          color: isSelected
              ? AppConstants.primaryColor
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              // Currency symbol
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: Center(
                  child: Text(
                    currency.symbol,
                    style: AppConstants.headingMedium.copyWith(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              // Currency info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.name,
                      style: AppConstants.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.code,
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppConstants.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

