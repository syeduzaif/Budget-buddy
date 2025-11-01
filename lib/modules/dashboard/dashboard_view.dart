import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';

/// Dashboard view showing income, spending, and remaining budget
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Budget Buddy'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: controller.showSetIncomeDialog,
            tooltip: 'Set Income',
          ),
        ],
      ),
      body: Obx(() {
        if (!controller.isIncomeSet.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: AppConstants.paddingL),
                Text(
                  'Set Your Monthly Income',
                  style: AppConstants.headingMedium,
                ),
                const SizedBox(height: AppConstants.paddingM),
                ElevatedButton(
                  onPressed: controller.showSetIncomeDialog,
                  child: const Text('Set Income'),
                ),
              ],
            ),
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
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: controller.goToPreviousMonth,
                        ),
                        Text(
                          budgetService.getFormattedMonth(),
                          style: AppConstants.headingMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: controller.goToNextMonth,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Income card
                _buildStatCard(
                  title: 'Monthly Income',
                  amount: income,
                  icon: Icons.account_balance_wallet,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Total Spent card
                InkWell(
                  onTap: () => controller.goToAllTransactions(),
                  child: _buildStatCard(
                    title: 'Total Spent',
                    amount: totalSpent,
                    icon: Icons.shopping_cart,
                    color: AppConstants.errorColor,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Total Remaining card
                _buildStatCard(
                  title: 'Total Remaining',
                  amount: totalRemaining,
                  icon: Icons.wallet,
                  color: totalRemaining >= 0
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Unallocated Budget card
                _buildStatCard(
                  title: 'Unallocated Budget',
                  amount: unallocated,
                  icon: Icons.add_circle_outline,
                  color: AppConstants.warningColor,
                ),
                const SizedBox(height: AppConstants.paddingXL),

                // Categories button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.goToCategories,
                    icon: const Icon(Icons.category),
                    label: const Text('Manage Categories'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
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

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppConstants.bodyMedium.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Text(
                    CurrencyHelper.formatAmount(amount, compact: true),
                    style: AppConstants.headingLarge.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

