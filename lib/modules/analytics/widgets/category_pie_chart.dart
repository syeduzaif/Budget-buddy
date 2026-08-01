import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_legend.dart';
import '../../../utils/currency_utils.dart';
import '../analytics_controller.dart';

class CategoryPieChart extends StatelessWidget {
  /// Biggest spend first. Amounts are minor units; they are converted to major
  /// units once, here, because fl_chart takes doubles.
  final List<CategorySpend> data;
  final Currency currency;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = data.where((e) => e.spentMinor > 0).toList();
    if (nonZero.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No spending data',
              style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: nonZero.map((e) {
                final cat = e.category;
                final color =
                    cat != null ? Color(cat.colorValue) : AppColors.primary;
                return PieChartSectionData(
                  color: color,
                  value: CurrencyUtils.toMajor(e.spentMinor, currency),
                  // No in-slice label: it was hardcoded white, ~2:1 on the
                  // amber slice, and the legend below states the exact amount
                  // anyway (UI-09).
                  showTitle: false,
                  radius: 32,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        // These rows now live in core/widgets so the dashboard donut can show
        // the same legend (UI-09).
        CategoryLegend(
          entries: nonZero
              .map((e) => CategoryLegendEntry(
                  category: e.category, spentMinor: e.spentMinor))
              .toList(),
          currency: currency,
        ),
      ],
    );
  }
}
