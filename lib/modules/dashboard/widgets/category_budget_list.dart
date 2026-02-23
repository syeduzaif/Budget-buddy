import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';

class CategoryBudgetList extends StatelessWidget {
  final List<Category> categories;
  final Map<String, double> spentMap;
  final String currencySymbol;
  final VoidCallback? onSeeAll;

  const CategoryBudgetList({
    super.key,
    required this.categories,
    required this.spentMap,
    required this.currencySymbol,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final shown = categories.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("This Month's Budgets", style: AppFonts.h6),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            child: Center(
              child: Text('No categories yet.',
                  style: AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          )
        else
          ...shown.map((cat) {
            final spent = spentMap[cat.id] ?? 0.0;
            final pct = cat.budgetLimit > 0 ? (spent / cat.budgetLimit).clamp(0.0, 1.0) : 0.0;
            final color = Color(cat.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(cat.name, style: AppFonts.labelLarge),
                        ],
                      ),
                      Text(
                        '${CurrencyUtils.formatAmountCompact(spent, currencySymbol)} / ${CurrencyUtils.formatAmountCompact(cat.budgetLimit, currencySymbol)}',
                        style: AppFonts.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: pct >= 1.0 ? AppColors.error : color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
