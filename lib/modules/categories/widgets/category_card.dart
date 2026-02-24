import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final double spent;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const CategoryCard({
    super.key,
    required this.category,
    required this.spent,
    required this.currencySymbol,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final pct = category.budgetLimit > 0
        ? (spent / category.budgetLimit).clamp(0.0, 1.0)
        : 0.0;
    final isOver = spent > category.budgetLimit && category.budgetLimit > 0;

    return Card(
      elevation: AppSpacing.elevationS,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(category.name,
                        style: AppFonts.labelLarge,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyUtils.formatAmount(spent, currencySymbol),
                    style: AppFonts.h6
                        .copyWith(color: isOver ? AppColors.error : null),
                  ),
                  Text(
                    'of ${CurrencyUtils.formatAmount(category.budgetLimit, currencySymbol)}',
                    style: AppFonts.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: isOver ? AppColors.error : color,
                  minHeight: 6,
                ),
              ),
              if (isOver) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text('Over budget!',
                    style:
                        AppFonts.labelSmall.copyWith(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
