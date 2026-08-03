import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/animations/animations.dart';
import '../../../core/utils/budget_status.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';

class CategoryBudgetList extends StatelessWidget {
  final List<Category> categories;

  /// Spend per category id, in minor units.
  final Map<String, int> spentMinorByCategory;
  final Currency currency;

  /// The month being viewed, `"YYYY-MM"` — named in the title when it is not
  /// the current one.
  final String monthKey;

  /// False when the user has browsed back. "This Month's Budgets" rendered
  /// over July's numbers is a false statement about which month is which
  /// (F-10.3).
  final bool isCurrentMonth;

  final VoidCallback? onSeeAll;

  const CategoryBudgetList({
    super.key,
    required this.categories,
    required this.spentMinorByCategory,
    required this.currency,
    required this.monthKey,
    required this.isCurrentMonth,
    this.onSeeAll,
  });

  int _spentOf(Category c) => spentMinorByCategory[c.id] ?? 0;

  /// Most-pressured budget first.
  ///
  /// The preview shows 4 of however many exist, and it used to show whichever
  /// 4 the store happened to emit first — so the one category that was over
  /// budget could sit at position 7, invisible, while the dashboard looked
  /// calm (N10). Sorting by ratio makes the preview mean something: whatever
  /// is worth seeing is what is shown.
  ///
  /// Zero-limit categories sort last regardless. They have no ratio to compare
  /// and no budget to breach, so they fill the preview only when there is
  /// nothing else to put in it.
  ///
  /// The tail of the comparator is not decoration: ratio-then-spend leaves two
  /// unspent zero-limit rows completely tied, and `List.sort` is not stable,
  /// so without a unique final key the preview could reshuffle itself between
  /// rebuilds. Name then id makes the order total.
  int _byPressure(Category a, Category b) {
    final aUnlimited = a.budgetLimitMinor <= 0;
    final bUnlimited = b.budgetLimitMinor <= 0;
    if (aUnlimited != bUnlimited) return aUnlimited ? 1 : -1;

    if (!aUnlimited) {
      final ratioA = _spentOf(a) / a.budgetLimitMinor;
      final ratioB = _spentOf(b) / b.budgetLimitMinor;
      if (ratioA != ratioB) return ratioB.compareTo(ratioA);
    }

    final spentA = _spentOf(a);
    final spentB = _spentOf(b);
    if (spentA != spentB) return spentB.compareTo(spentA);

    final byName = a.name.compareTo(b.name);
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor = context.semanticColors.textMuted;
    // A COPY. `categories` is the controller's RxList, handed in and read
    // inside an Obx — sorting it in place would write to an observable during
    // a rebuild that observes it, which is a rebuild loop. Sorting here also
    // means dashboard_view needs to know nothing about any of this.
    final shown = List.of(categories)..sort(_byPressure);
    final rows = shown.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                isCurrentMonth
                    ? "This Month's Budgets"
                    // No year: the app bar directly above already says
                    // "July 2025". The possessive is English-only, which the
                    // whole app currently is.
                    : "${AppDateUtils.formatMonthName(monthKey)}'s Budgets",
                style: AppFonts.h6,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onSeeAll != null)
              // Not "See All": this button leaves the dashboard for another
              // tab, which is the disorienting kind of navigation, so it names
              // where it goes (FD-3). The Recent list's own "See All" stays.
              TextButton(
                  onPressed: onSeeAll, child: const Text('All Categories')),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            child: Center(
              child: Text('No categories yet.',
                  style: AppFonts.bodySmall.copyWith(color: mutedColor)),
            ),
          )
        else
          ...rows.map((cat) {
            final spent = _spentOf(cat);
            final status = BudgetStatus.of(
                spentMinor: spent, limitMinor: cat.budgetLimitMinor);
            // Whole major units here: four rows share the width of one card,
            // and the exact figure lives on the Categories tab.
            final caption = status.caption(currency, compact: true);
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
                      if (status.showsOverIcon)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xxs),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 14, color: status.amountColor(context)),
                        ),
                      Text(
                        // The No-limit row prints the spend alone: "₨0 / ₨0"
                        // is the same nothing twice, and the second half reads
                        // as a budget of zero rather than no budget (danish,
                        // BUG-001 verification; BUG-120 requires its absence).
                        // The caption below still says "No limit set".
                        status.showsLimit
                            ? '${CurrencyUtils.formatAmountCompact(spent, currency)}'
                                ' / '
                                '${CurrencyUtils.formatAmountCompact(cat.budgetLimitMinor, currency)}'
                            : CurrencyUtils.formatAmountCompact(
                                spent, currency),
                        style: AppFonts.labelSmall.copyWith(
                          // labelSmall carries no colour of its own since F-11,
                          // so every state names one — including the quiet one.
                          color: status.amountColor(context) ?? mutedColor,
                        ),
                      ),
                    ],
                  ),
                  if (status.showsBar) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    AnimatedProgressBar(
                      value: status.barValue,
                      color: status.barColor(context, color),
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ],
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      caption,
                      style: AppFonts.labelSmall
                          .copyWith(color: status.captionColor(context)),
                      // One line at any text scale: the caption is a companion
                      // to the bar, and a wrapped one pushes the next row's
                      // budget off the card (palwasha's 1.3x AC).
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
