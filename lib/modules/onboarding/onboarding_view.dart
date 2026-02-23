import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../utils/currency_utils.dart';
import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Obx(() => LinearProgressIndicator(
              value: (controller.currentPage.value + 1) / 3,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 3,
            )),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _WelcomePage(),
                  _CurrencyPage(),
                  _IncomePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 64, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Welcome to Budget Buddy', style: AppFonts.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Smart budgeting made simple. Track your spending, manage categories, and reach your financial goals.',
            style: AppFonts.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            onPressed: ctrl.nextPage,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatelessWidget {
  const _CurrencyPage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Pick Your Currency', style: AppFonts.h3),
          const SizedBox(height: AppSpacing.s),
          Text('Choose the currency you use for your budget.',
              style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Obx(() => GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: AppSpacing.s,
                mainAxisSpacing: AppSpacing.s,
              ),
              itemCount: CurrencyUtils.currencies.length,
              itemBuilder: (context, i) {
                final currency = CurrencyUtils.currencies[i];
                final selected = ctrl.selectedCurrency.value.code == currency.code;
                return InkWell(
                  onTap: () => ctrl.selectCurrency(currency),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Text(currency.symbol,
                            style: AppFonts.labelLarge.copyWith(
                                color: selected ? Colors.white : AppColors.textPrimary)),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(currency.code,
                              style: AppFonts.labelMedium.copyWith(
                                  color: selected ? Colors.white70 : AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: ctrl.nextPage,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _IncomePage extends StatelessWidget {
  const _IncomePage();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Set Monthly Income', style: AppFonts.h3),
          const SizedBox(height: AppSpacing.s),
          Text(
            'What is your approximate monthly income? You can change this later.',
            style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Obx(() => TextFormField(
            controller: ctrl.incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppFonts.h3,
            decoration: InputDecoration(
              labelText: 'Monthly Income',
              prefixText: '${ctrl.selectedCurrency.value.symbol} ',
              prefixStyle: AppFonts.h4.copyWith(color: AppColors.primary),
              hintText: '0.00',
            ),
          )),
          const Spacer(),
          FilledButton(
            onPressed: ctrl.finish,
            child: const Text('Start Budgeting'),
          ),
          const SizedBox(height: AppSpacing.m),
          TextButton(
            onPressed: ctrl.finish,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
