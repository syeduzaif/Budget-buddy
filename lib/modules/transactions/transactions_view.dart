import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'transactions_controller.dart';
import '../../utils/currency_helper.dart';
import '../../widgets/transaction_tile.dart';
import '../../routes/app_routes.dart';

/// View to display all transactions in a list
class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionsController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Transactions'),
        centerTitle: true,
      ),
      body: Obx(() {
        final transactions = controller.allTransactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Transactions Yet',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start adding transactions to track expenses',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate total spent for displayed transactions (simple summary)
        final totalSpent =
            transactions.fold(0.0, (sum, item) => sum + item.amount);

        return Column(
          children: [
            // Summary Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Spent',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyHelper.formatAmount(totalSpent),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.refreshTransactions(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    // We need category name/color which TransactionTile doesn't natively show yet.
                    // But for now let's use the standard tile.
                    // To show category info, we might need to customize TransactionTile or wrap it.
                    // However, TransactionTile uses TransactionItem which has categoryId but not name.
                    // The standard tile shows 'note' and date.
                    // We'll stick to TransactionTile for consistency.

                    return TransactionTile(
                      transaction: transaction,
                      // No delete on global view usually, or implemented via controller?
                      // Controller doesn't expose delete easily here without category context?
                      // TransactionsController usually has delete logic or one can add it.
                      // Assuming tap to edit/view details if needed.
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addTransaction),
        label: const Text('Add Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
