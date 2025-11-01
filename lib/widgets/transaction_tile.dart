import 'package:flutter/material.dart';
import '../data/models/transaction_item.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/currency_helper.dart';

/// Tile widget to display a transaction
class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: Center(
                  child: Text(
                    Helpers.formatDateShort(transaction.date),
                    style: AppConstants.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note.isNotEmpty
                          ? transaction.note
                          : 'No note',
                      style: AppConstants.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      Helpers.formatDate(transaction.date),
                      style: AppConstants.bodySmall,
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                CurrencyHelper.formatAmount(transaction.amount, compact: true),
                style: AppConstants.headingSmall.copyWith(
                  color: AppConstants.errorColor,
                ),
              ),
              // Delete button
              if (onDelete != null) ...[
                const SizedBox(width: AppConstants.paddingS),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppConstants.errorColor),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

