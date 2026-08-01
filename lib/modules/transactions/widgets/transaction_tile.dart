import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/transaction_item.dart';
import '../../../utils/currency_utils.dart';
import '../../../utils/date_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final String categoryName;
  final int categoryColor;
  final Currency currency;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.categoryColor,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(categoryColor).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: Color(categoryColor), shape: BoxShape.circle),
              ),
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
            style: AppFonts.h6.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
