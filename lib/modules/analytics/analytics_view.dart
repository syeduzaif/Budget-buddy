import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../utils/currency_utils.dart';
import 'analytics_controller.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/category_pie_chart.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AnalyticsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: AppFonts.h6),
      ),
      body: Obx(() {
        final sym = ctrl.settings.currencySymbol.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Range selector
              SegmentedButton<int>(
                segments: AnalyticsController.ranges
                    .asMap()
                    .entries
                    .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                    .toList(),
                selected: {ctrl.selectedRange.value},
                onSelectionChanged: (s) => ctrl.setRange(s.first),
              ),
              const SizedBox(height: AppSpacing.l),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Spent',
                      value: CurrencyUtils.formatAmount(ctrl.totalSpent, sym),
                      icon: Icons.trending_up,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: _StatCard(
                      label: 'Savings Rate',
                      value: '${ctrl.savingsRate.toStringAsFixed(1)}%',
                      icon: Icons.savings_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),

              // Monthly trend
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Spending', style: AppFonts.h6),
                      const SizedBox(height: AppSpacing.m),
                      MonthlyBarChart(
                        data: ctrl.monthlyTotals,
                        currencySymbol: sym,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Category breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By Category', style: AppFonts.h6),
                      const SizedBox(height: AppSpacing.m),
                      CategoryPieChart(
                        data: ctrl.categoryTotals,
                        currencySymbol: sym,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSpacing.iconS),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: AppFonts.labelSmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xxs),
            Text(value,
                style: AppFonts.h5, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
