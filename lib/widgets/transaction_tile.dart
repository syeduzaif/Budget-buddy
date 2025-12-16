import 'package:flutter/material.dart';
import '../data/models/transaction_item.dart';
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: const Color(0xFF00897B).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF00897B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note.isNotEmpty
                          ? transaction.note
                          : 'No note',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatDate(transaction.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Amount and delete button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatAmount(transaction.amount,
                        compact: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFFF6B6B),
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
