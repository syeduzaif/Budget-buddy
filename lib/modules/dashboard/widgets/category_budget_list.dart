import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/animations/animations.dart';
import '../../../core/widgets/category_icon.dart';
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
                  style:
                      AppFonts.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          )
        else
          ...shown.map((cat) {
            final spent = spentMap[cat.id] ?? 0.0;
            final pct = cat.budgetLimit > 0
                ? (spent / cat.budgetLimit).clamp(0.0, 1.0)
                : 0.0;
            final isOver = spent > cat.budgetLimit && cat.budgetLimit > 0;
            final color = Color(cat.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryIcon(category: cat, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: AppFonts.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOver)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xxs),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.error),
                        ),
                      Text(
                        '${CurrencyUtils.formatAmountCompact(spent, currencySymbol)} / ${CurrencyUtils.formatAmountCompact(cat.budgetLimit, currencySymbol)}',
                        style: AppFonts.labelSmall.copyWith(
                          color: isOver ? AppColors.error : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AnimatedProgressBar(
                    value: pct,
                    color: isOver ? AppColors.error : color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
