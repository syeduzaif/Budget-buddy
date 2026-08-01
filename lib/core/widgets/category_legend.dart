import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../../data/models/category.dart';
import '../../utils/currency_utils.dart';
import 'category_icon.dart';

/// One legend row's worth of data.
class CategoryLegendEntry {
  /// Null when the spend belongs to a category that has since been deleted.
  final Category? category;

  /// Spend in minor units — formatted once, at the boundary, by the legend.
  final int spentMinor;

  const CategoryLegendEntry({
    required this.category,
    required this.spentMinor,
  });
}

/// Icon · name · exact amount, one row per category.
///
/// Lifted out of the analytics pie chart so the dashboard donut can show the
/// same legend instead of unreadable in-slice percentages (UI-09) — the two
/// charts now read identically. Shared here rather than copied because it is
/// used by two modules; it takes plain models, so `core` keeps its layering.
class CategoryLegend extends StatelessWidget {
  /// Rows in the order they should be drawn (biggest spend first, by
  /// convention of both callers).
  final List<CategoryLegendEntry> entries;
  final Currency currency;

  const CategoryLegend({
    super.key,
    required this.entries,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // AppFonts.bodySmall and labelMedium both BAKE textSecondary, a
    // light-theme token — 2.21:1 on a dark card, which made the legend the
    // dimmest text on the dashboard (N6).
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: entries.map((e) {
        final cat = e.category;
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
                    style: AppFonts.bodySmall.copyWith(color: onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(CurrencyUtils.formatAmount(e.spentMinor, currency),
                  style: AppFonts.labelMedium.copyWith(color: onSurface)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
