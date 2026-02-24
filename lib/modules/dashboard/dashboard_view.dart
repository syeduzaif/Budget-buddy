import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/animations/animations.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';
import 'dashboard_controller.dart';
import 'widgets/summary_card.dart';
import 'widgets/category_budget_list.dart';
import 'widgets/spending_donut_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: ctrl.goToPreviousMonth,
                  padding: EdgeInsets.zero,
                ),
                Text(
                  AppDateUtils.formatMonthKey(ctrl.settings.currentMonth.value),
                  style: AppFonts.h6,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: ctrl.goToNextMonth,
                  padding: EdgeInsets.zero,
                ),
              ],
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 18, color: AppColors.primaryDark),
            ),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final sym = ctrl.settings.currencySymbol.value;
        final spentMap = {
          for (final cat in ctrl.categories)
            cat.id: ctrl.spentForCategory(cat.id)
        };

        return RefreshIndicator(
          onRefresh: () async {
            ctrl.categories.refresh();
            ctrl.transactions.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Income card
                FadeSlideItem(
                  index: 0,
                  child: SummaryCard(
                    label: 'Monthly Income',
                    amount: CurrencyUtils.formatAmount(
                        ctrl.settings.monthlyIncome.value, sym),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    isLarge: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                // Spent + Remaining row
                FadeSlideItem(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: 'Spent',
                          amount:
                              CurrencyUtils.formatAmount(ctrl.totalSpent, sym),
                          icon: Icons.trending_up,
                          color: ctrl.totalSpent >
                                  ctrl.settings.monthlyIncome.value
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: SummaryCard(
                          label: 'Remaining',
                          amount:
                              CurrencyUtils.formatAmount(ctrl.remaining, sym),
                          icon: Icons.savings_outlined,
                          color: ctrl.remaining >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Spending donut chart
                if (ctrl.categories.isNotEmpty) ...[
                  FadeSlideItem(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spending Breakdown', style: AppFonts.h6),
                        const SizedBox(height: AppSpacing.s),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: SpendingDonutChart(
                              categories: ctrl.categories,
                              spentMap: spentMap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],

                // Category budget list
                FadeSlideItem(
                  index: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: CategoryBudgetList(
                        categories: ctrl.categories,
                        spentMap: spentMap,
                        currencySymbol: sym,
                        onSeeAll: ctrl.categories.length > 4
                            ? () => Get.toNamed(AppRoutes.categoryForm)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
