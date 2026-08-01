import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';
import '../analytics_controller.dart';

class MonthlyBarChart extends StatelessWidget {
  /// Oldest→newest. Amounts are minor units; they are converted to major units
  /// once, here, because fl_chart takes doubles.
  final List<MonthlyTotal> data;
  final Currency currency;

  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data',
              style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    final maxMinor = data.fold(0, (m, e) => e.totalMinor > m ? e.totalMinor : m);
    final maxY = CurrencyUtils.toMajor(maxMinor, currency);
    final safeMax = maxY > 0 ? maxY * 1.2 : 100.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: safeMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = data[groupIndex];
                // Formatted from the exact minor-unit value, not from the
                // chart's geometry.
                return BarTooltipItem(
                  '${AppDateUtils.formatMonthShort(entry.month)}\n'
                  '${CurrencyUtils.formatAmountCompact(entry.totalMinor, currency)}',
                  AppFonts.labelSmall.copyWith(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      AppDateUtils.formatMonthShort(data[i].month),
                      style: AppFonts.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: CurrencyUtils.toMajor(data[i].totalMinor, currency),
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
