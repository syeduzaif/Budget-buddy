import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction_item.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;

  /// The transaction's category, or null when it has since been deleted.
  /// Passed in whole so the row can draw the real [CategoryIcon] instead of
  /// rebuilding its own dot (UI-03b).
  final Category? category;
  final Currency currency;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    required this.onDelete,
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
          subtitle: Text(
            '$categoryName · ${AppDateUtils.formatDate(transaction.date)}',
            style: AppFonts.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
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
