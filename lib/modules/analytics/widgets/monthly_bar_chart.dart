import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../utils/date_utils.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{month: String, total: double}]
  final String currencySymbol;

  const MonthlyBarChart({
    super.key,
    required this.data,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text('No data', style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    final maxY = data.fold(0.0, (m, e) => e['total'] > m ? e['total'] as double : m);
    final safeMax = maxY > 0 ? maxY * 1.2 : 100.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: safeMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = data[groupIndex]['month'] as String;
                final amount = rod.toY;
                return BarTooltipItem(
                  '${AppDateUtils.formatMonthShort(month)}\n$currencySymbol${amount.toStringAsFixed(0)}',
                  AppFonts.labelSmall.copyWith(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      AppDateUtils.formatMonthShort(data[i]['month'] as String),
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
            final total = data[i]['total'] as double;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
