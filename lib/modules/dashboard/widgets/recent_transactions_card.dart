import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction_item.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';

/// The dashboard's proof that a log landed.
///
/// Before this, saving an expense changed nothing visible on the screen the
/// user was returned to: the totals moved, but nothing said "here is the thing
/// you just typed" — which is the pattern that historically invited a second
/// save (F-04).
///
/// Rows are plain [ListTile]s inside ONE card: no nested cards, no
/// [Dismissible] (deleting stays in the full list, behind its confirm dialog),
/// and **no chevron** — the ripple is the affordance, and a chevron per row
/// would steal width from the amount (danish). A tap opens the row for editing,
/// because the row is the transaction.
///
/// This widget owns its [Card], unlike the budgets list next door: `ListTile`
/// brings its own 16dp horizontal padding, so a blanket card padding would
/// indent every row twice.
class RecentTransactionsCard extends StatelessWidget {
  /// Newest first, already scoped to the viewed month and already capped — the
  /// controller decides how many "recent" is.
  final List<TransactionItem> transactions;

  /// The viewed month's categories, for each row's icon and name fallback.
  final List<Category> categories;

  final Currency currency;

  /// Opens the month-scoped list.
  final VoidCallback onSeeAll;

  /// Opens one row for editing (F-07).
  final void Function(TransactionItem) onTapTransaction;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
    required this.onSeeAll,
    required this.onTapTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = context.semanticColors.textMuted;
    final byId = {for (final c in categories) c.id: c};

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.m,
              right: AppSpacing.xs,
              top: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: AppFonts.h6),
                // Stays "See All": this one opens a longer version of the same
                // list, which is the un-disorienting kind of navigation. The
                // budgets card's button names its destination instead (FD-3).
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
              ],
            ),
          ),
          ...transactions.map((t) {
            final cat = byId[t.categoryId];
            return ListTile(
              onTap: () => onTapTransaction(t),
              leading: cat != null
                  ? CategoryIcon(category: cat, size: 32)
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
              // The same fallback the full list uses: a note if there is one,
              // otherwise the category's name.
              title: Text(
                t.note.isNotEmpty ? t.note : (cat?.name ?? 'Unknown'),
                style: AppFonts.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // labelSmall carries no colour of its own since F-11.
              subtitle: Text(
                AppDateUtils.formatDate(t.date),
                style: AppFonts.labelSmall.copyWith(color: mutedColor),
              ),
              trailing: Text(
                CurrencyUtils.formatAmount(t.amountMinor, currency),
                // Never red: every transaction here is an expense, so red
                // would carry no information and would collide with the
                // over-budget signal (UI-29).
                style: AppFonts.labelLarge.copyWith(color: colorScheme.onSurface),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
