import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/utils/budget_status.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final color = Color(category.colorValue);
    // Which rung of the ladder this category is on, decided in one place and
    // rendered identically on the dashboard preview (F-09). The scheme's error
    // and the semantic warning both come out of it — never the raw tokens,
    // which measure 3.22:1 and 2.32:1 on these cards (UI-20).
    final status = BudgetStatus.of(
        spentMinor: spentMinor, limitMinor: category.budgetLimitMinor);
    // Exact amounts here — the card has the width the dashboard preview does
    // not, and this is the screen a user comes to to read the number.
    final caption = status.caption(currency, compact: false);

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
                    color: context.semanticColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Two unflexible children in a spaceBetween Row overflowed at
              // 1.3x text scale — measured 105px on a 360dp card, ~83px of
              // which predates the triangle this ticket adds. Both sides are
              // Flexible now, so a long amount ellipsizes instead of striping
              // the card.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status.showsOverIcon) ...[
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: status.amountColor(context)),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Flexible(
                          child: Text(
                            CurrencyUtils.formatAmount(spentMinor, currency),
                            style: AppFonts.h6
                                .copyWith(color: status.amountColor(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'of ${CurrencyUtils.formatAmount(category.budgetLimitMinor, currency)}',
                      // AppFonts.bodySmall BAKES textSecondary, a light-theme
                      // token: 2.21:1 on a dark card. Same defect class as
                      // UI-01, one layer down — there the colour was null,
                      // here it is baked (N6).
                      style: AppFonts.bodySmall
                          .copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              if (status.showsBar) ...[
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: status.barValue,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: status.barColor(context, color),
                    minHeight: 6,
                  ),
                ),
              ],
              if (caption != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                // "Over budget!" said less than it could: this slot now names
                // the amount in every non-normal state, so no state on this
                // card is distinguishable by colour alone.
                Text(
                  caption,
                  style: AppFonts.labelSmall
                      .copyWith(color: status.captionColor(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
