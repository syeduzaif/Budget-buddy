import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_legend.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';

class SpendingDonutChart extends StatelessWidget {
  final List<Category> categories;

  /// Spend per category id, in minor units.
  final Map<String, int> spentMinorByCategory;

  /// Needed by the legend below the donut, which states exact amounts. The
  /// slices themselves are unit-invariant: minor units go in as relative
  /// weights and only the share is ever drawn.
  final Currency currency;

  const SpendingDonutChart({
    super.key,
    required this.categories,
    required this.spentMinorByCategory,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final data = categories
        .map((c) => MapEntry(c, spentMinorByCategory[c.id] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    if (data.isEmpty) {
      // The house empty-state pattern (icon 64 · h6 · muted line), as used on
      // Categories and Transactions — this was a bare line of text in a 160px
      // void (UI-14). No CTA: the Add tab is already in the thumb zone.
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.donut_large_outlined,
                  size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.m),
              Text('Nothing logged yet', style: AppFonts.h6),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Spending shows up here once you add a transaction',
                style:
                    AppFonts.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: data.map((e) {
                return PieChartSectionData(
                  color: Color(e.key.colorValue),
                  value: e.value.toDouble(),
                  // No in-slice percentage: it was hardcoded white (~2:1 on
                  // the amber slice) and said nothing about *what* the slice
                  // was. The legend below names it and gives the exact
                  // amount (UI-09).
                  showTitle: false,
                  radius: 40,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        CategoryLegend(
          entries: data
              .map((e) =>
                  CategoryLegendEntry(category: e.key, spentMinor: e.value))
              .toList(),
          currency: currency,
        ),
      ],
    );
  }
}
