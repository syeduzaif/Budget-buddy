import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction_item.dart';
import '../../../utils/currency_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;

  /// The transaction's category, or null when it has since been deleted.
  /// Passed in whole so the row can draw the real [CategoryIcon] instead of
  /// rebuilding its own dot (UI-03b).
  final Category? category;
  final Currency currency;

  /// False on the per-category screen, where the screen title already names
  /// the category (UI-04).
  final bool showCategory;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    required this.onDelete,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cat = category;
    final categoryName = cat?.name ?? 'Unknown';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // The device is the only copy of this record, so a swipe asks first —
      // the same pattern category delete already uses (UI-28). The dialog
      // names the amount, because that is what identifies the row.
      confirmDismiss: (_) async {
        // Popped with the dialog's own context rather than the repo's usual
        // `Get.back(result:)` so this leaf widget needs no GetX import;
        // same result.
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: Text(
                'Delete ${CurrencyUtils.formatAmount(transaction.amountMinor, currency)}'
                '${transaction.note.isNotEmpty ? ' — "${transaction.note}"' : ''}?'
                ' This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              // Destroying is not the affirmative action: a green FilledButton
              // means "safe/go" everywhere else in this app. Error-coloured
              // text, matching the erase-all dialog (N9).
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error),
                  child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: AppSpacing.elevationS,
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        child: ListTile(
          leading: cat != null
              ? CategoryIcon(category: cat, size: 40)
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
          title: Text(
            transaction.note.isNotEmpty ? transaction.note : categoryName,
            style: AppFonts.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          // No date: the group header above the row owns it. No category on
          // the filtered screen, where the app bar already says it (UI-04).
          // And nothing at all when the title has already fallen back to the
          // category name — a note-less transaction was showing "Shopping"
          // over "Shopping" (N4).
          subtitle: showCategory && transaction.note.isNotEmpty
              ? Text(
                  categoryName,
                  style: AppFonts.labelSmall,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Text(
            CurrencyUtils.formatAmount(transaction.amountMinor, currency),
            // Neutral: every transaction is an expense, so red carried no
            // information here and collided with the over-budget signal
            // (UI-29).
            style: AppFonts.h6.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
