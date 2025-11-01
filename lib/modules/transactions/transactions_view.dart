import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'transactions_controller.dart';
import '../../data/models/transaction_item.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency_helper.dart';

/// View to display all transactions in a list
class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionsController>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('All Transactions'),
        elevation: 0,
      ),
      body: Obx(() {
        final transactions = controller.allTransactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: AppConstants.paddingL),
                Text(
                  'No Transactions Yet',
                  style: AppConstants.headingMedium,
                ),
                const SizedBox(height: AppConstants.paddingM),
                Text(
                  'Start adding transactions to see them here',
                  style: AppConstants.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final categoryName = controller.getCategoryName(transaction.categoryId);
              final categoryColor = controller.getCategoryColor(transaction.categoryId);

              return _buildTransactionTile(
                transaction: transaction,
                categoryName: categoryName,
                categoryColor: categoryColor,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildTransactionTile({
    required TransactionItem transaction,
    required String categoryName,
    required int categoryColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        child: Row(
          children: [
            // Category color indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Color(categoryColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: AppConstants.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyHelper.formatAmount(transaction.amount, compact: true),
                        style: AppConstants.headingSmall.copyWith(
                          color: AppConstants.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.note.isNotEmpty
                              ? transaction.note
                              : 'No description',
                          style: AppConstants.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Helpers.formatDateShort(transaction.date),
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

