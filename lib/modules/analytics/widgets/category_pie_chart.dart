import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';

class CategoryPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{category, categoryId, spent}]
  final String currencySymbol;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = data.where((e) => (e['spent'] as double) > 0).toList();
    if (nonZero.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No spending data',
              style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    final total = nonZero.fold(0.0, (s, e) => s + (e['spent'] as double));

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: nonZero.map((e) {
                final cat = e['category'] as Category?;
                final spent = e['spent'] as double;
                final pct = total > 0 ? spent / total * 100 : 0.0;
                final color = cat != null
                    ? Color(cat.colorValue)
                    : AppColors.primary;
                return PieChartSectionData(
                  color: color,
                  value: spent,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 32,
                  titleStyle: AppFonts.labelSmall.copyWith(color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        ...nonZero.map((e) {
          final cat = e['category'] as Category?;
          final spent = e['spent'] as double;
          final color = cat != null ? Color(cat.colorValue) : AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                if (cat != null)
                  CategoryIcon(category: cat, size: 20)
                else
                  Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(cat?.name ?? 'Unknown',
                      style: AppFonts.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(CurrencyUtils.formatAmount(spent, currencySymbol),
                    style: AppFonts.labelMedium),
              ],
            ),
          );
        }),
      ],
    );
  }
}
