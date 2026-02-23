import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/category.dart';

class SpendingDonutChart extends StatelessWidget {
  final List<Category> categories;
  final Map<String, double> spentMap;

  const SpendingDonutChart({
    super.key,
    required this.categories,
    required this.spentMap,
  });

  @override
  Widget build(BuildContext context) {
    final data = categories
        .map((c) => MapEntry(c, spentMap[c.id] ?? 0.0))
        .where((e) => e.value > 0)
        .toList();

    if (data.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No spending data',
              style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    final total = data.fold(0.0, (s, e) => s + e.value);

    return SizedBox(
      height: 160,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 48,
          sections: data.map((e) {
            final pct = total > 0 ? e.value / total * 100 : 0.0;
            return PieChartSectionData(
              color: Color(e.key.colorValue),
              value: e.value,
              title: '${pct.toStringAsFixed(0)}%',
              radius: 32,
              titleStyle: AppFonts.labelSmall.copyWith(color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }
}
