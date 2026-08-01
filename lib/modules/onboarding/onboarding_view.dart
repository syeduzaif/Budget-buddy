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
          Text('Welcome to BuddgetBuddy',
              style: AppFonts.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.m),
          Text(
            // Describes what ships. The old copy promised "financial goals",
            // a feature that does not exist (UI-24).
            'Track your spending, set a budget per category, and see where the '
            'month went.',
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
              style:
                  AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: Obx(() {
              // Read the observable directly in the Obx scope so GetX can track it
              final selectedCode = ctrl.selectedCurrency.value.code;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: AppSpacing.s,
                  mainAxisSpacing: AppSpacing.s,
                ),
                itemCount: CurrencyUtils.currencies.length,
                itemBuilder: (context, i) {
                  final currency = CurrencyUtils.currencies[i];
                  final selected = selectedCode == currency.code;
                  return InkWell(
                    onTap: () => ctrl.selectCurrency(currency),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    child: Container(
                      decoration: BoxDecoration(
                        // primaryDark, not primary: white on #4E5E38 is 6.9:1,
                        // where white70 on #6B7F4E was 3.04:1 — below AA for
                        // 14px text (UI-13).
                        color: selected
                            ? AppColors.primaryDark
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.border,
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
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(currency.code,
                                style: AppFonts.labelMedium.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
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
          // Centred rather than pinned to the top with ~700px of dead space
          // below the field, and the space spent on the "why" instead (UI-25).
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set Monthly Income', style: AppFonts.h3),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'What is your approximate monthly income? You can change '
                  'this later.',
                  style: AppFonts.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Obx(() => TextFormField(
                      controller: ctrl.incomeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: AppFonts.h3,
                      decoration: InputDecoration(
                        labelText: 'Monthly Income',
                        prefixText: '${ctrl.selectedCurrency.value.symbol} ',
                        prefixStyle:
                            AppFonts.h4.copyWith(color: AppColors.primary),
                        // Flutter hides prefixText until focus, so at rest the
                        // field has to say the unit itself — and it has to say
                        // it in the user's currency, never a literal '0.00'
                        // (UI-17).
                        hintText: CurrencyUtils.formatAmount(
                            0, ctrl.selectedCurrency.value),
                      ),
                    )),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Used to work out what\'s left this month. You can change it '
                  'any time.',
                  style: AppFonts.caption,
                ),
              ],
            ),
          ),
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
