import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  /// Spend against this category, in minor units.
  final int spentMinor;
  final Currency currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const CategoryCard({
    super.key,
    required this.category,
    required this.spentMinor,
    required this.currency,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // The dark scheme defines a lighter error (#E89088) that the raw token
    // never used; #C25D4E on dark sits at ~4.3:1 (UI-20).
    final errorColor = Theme.of(context).colorScheme.error;
    final color = Color(category.colorValue);
    // int / int is a double in Dart, so the ratio needs no conversion.
    final pct = category.budgetLimitMinor > 0
        ? (spentMinor / category.budgetLimitMinor).clamp(0.0, 1.0)
        : 0.0;
    final isOver = spentMinor > category.budgetLimitMinor &&
        category.budgetLimitMinor > 0;

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
                  CategoryIcon(category: category, size: 28),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(category.name,
                        style: AppFonts.labelLarge,
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    // The overrides that used to be here (zero padding, empty
                    // constraints) stripped the 48dp minimum target off an
                    // 18dp glyph (UI-07). The glyph stays small; the target
                    // does not.
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyUtils.formatAmount(spentMinor, currency),
                    style:
                        AppFonts.h6.copyWith(color: isOver ? errorColor : null),
                  ),
                  Text(
                    'of ${CurrencyUtils.formatAmount(category.budgetLimitMinor, currency)}',
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
                  color: isOver ? errorColor : color,
                  minHeight: 6,
                ),
              ),
              if (isOver) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text('Over budget!',
                    style: AppFonts.labelSmall.copyWith(color: errorColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
