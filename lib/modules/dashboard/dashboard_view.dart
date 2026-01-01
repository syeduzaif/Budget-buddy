import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../auth/auth_controller.dart';
import '../../core/constants/app_icons.dart';
import '../../utils/currency_helper.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (!controller.isIncomeSet.value) {
            return _buildEmptyState(controller, theme);
          }

          final budgetService = controller.budgetService;
          final income = budgetService.monthlyIncome.value;
          final totalSpent = budgetService.getTotalSpent();
          final totalRemaining = budgetService.getTotalRemaining();
          final spendingPercentage = income > 0 ? (totalSpent / income) : 0.0;

          return RefreshIndicator(
            onRefresh: () async => controller.refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(controller, budgetService, theme),
                  const SizedBox(height: 24),
                  _buildSummaryCards(income, totalSpent, totalRemaining, theme),
                  const SizedBox(height: 24),
                  _buildSpendingProgress(spendingPercentage, theme),
                  const SizedBox(height: 24),
                  _buildCategoriesShortcut(controller, theme),
                ],
              ),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller
            .goToCategories, // As per "Add Category" implies managing categories or adding new one
        label: const Text('Add Category'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(DashboardController controller, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'Welcome to Budget Buddy',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Set your monthly income to start tracking your budget effectively.',
              style:
                  theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: controller.showSetIncomeDialog,
              child: const Text('Set Monthly Income'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      DashboardController controller, dynamic budgetService, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.goToPreviousMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  budgetService.getFormattedMonth(),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: controller.goToNextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(AppIcons.ai),
              onPressed: controller.goToAiChat, // Keep AI Chat access
              tooltip: 'AI Assistant',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: controller.showSetIncomeDialog,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Get.find<AuthController>().logout();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
      double income, double spent, double remaining, ThemeData theme) {
    return Column(
      children: [
        _buildInfoCard(
          title: 'Total Income',
          amount: income,
          icon: Icons.arrow_downward,
          color: Colors.green,
          theme: theme,
          isLarge: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Spent',
                amount: spent,
                icon: Icons.arrow_upward,
                color: Colors.red,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                title: 'Remaining',
                amount: remaining,
                icon: Icons.wallet,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: isLarge ? 24 : 20),
              ),
              if (isLarge) Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          SizedBox(height: isLarge ? 24 : 16),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyHelper.formatAmount(amount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 32 : 20,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingProgress(double percentage, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Goal',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(percentage * 100).clamp(0, 100).toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      percentage > 1 ? Colors.red : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[100],
              color: percentage > 1 ? Colors.red : theme.colorScheme.primary,
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesShortcut(
      DashboardController controller, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.goToCategories,
        icon: const Icon(Icons.category),
        label: const Text('Manage Categories'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
