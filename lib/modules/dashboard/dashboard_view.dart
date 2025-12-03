import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/cards.dart';
import '../../utils/currency_helper.dart';

/// Dashboard view showing income, spending, and remaining budget
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Buddy'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settings),
            onPressed: controller.showSetIncomeDialog,
            tooltip: 'Set Income',
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.isIncomeSet.value) {
          return EmptyState(
            icon: AppIcons.wallet,
            title: 'Set Your Monthly Income',
            message:
                'Get started by setting your monthly income to track your budget',
            actionText: 'Set Income',
            onAction: controller.showSetIncomeDialog,
          );
        }

        final budgetService = controller.budgetService;
        final income = budgetService.monthlyIncome.value;
        final totalSpent = budgetService.getTotalSpent();
        final totalRemaining = budgetService.getTotalRemaining();
        final unallocated = budgetService.getUnallocatedBudget();

        return RefreshIndicator(
          onRefresh: () async => controller.refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selector
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.chevronLeft),
                        onPressed: controller.goToPreviousMonth,
                      ),
                      Text(
                        budgetService.getFormattedMonth(),
                        style: AppFonts.h5,
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.chevronRight),
                        onPressed: controller.goToNextMonth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Income card
                StatCard(
                  title: 'Monthly Income',
                  value: CurrencyHelper.formatAmount(income, compact: true),
                  icon: AppIcons.wallet,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.m),

                // Total Spent card
                StatCard(
                  title: 'Total Spent',
                  value: CurrencyHelper.formatAmount(totalSpent, compact: true),
                  icon: AppIcons.expense,
                  color: AppColors.error,
                  onTap: controller.goToAllTransactions,
                ),
                const SizedBox(height: AppSpacing.m),

                // Total Remaining card
                StatCard(
                  title: 'Total Remaining',
                  value: CurrencyHelper.formatAmount(totalRemaining,
                      compact: true),
                  icon: AppIcons.money,
                  color:
                      totalRemaining >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.m),

                // Unallocated Budget card
                StatCard(
                  title: 'Unallocated Budget',
                  value:
                      CurrencyHelper.formatAmount(unallocated, compact: true),
                  icon: AppIcons.add,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Categories button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.goToCategories,
                    icon: const Icon(AppIcons.categories),
                    label: const Text('Manage Categories'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSpacing.m),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.goToAiChat,
        backgroundColor: AppColors.primary,
        child: const Icon(AppIcons.ai, color: AppColors.textWhite),
      ),
    );
  }
}
