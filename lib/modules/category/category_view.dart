import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'category_controller.dart';
import '../../widgets/category_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../utils/constants.dart';

/// Categories view showing list of categories
class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
      ),
      body: Obx(() {
        final categories = controller.budgetService.categories;
        final showTransactions = controller.showTransactions.value;
        final selectedCategory = controller.selectedCategory.value;

        // If showing transactions, display transaction list
        if (showTransactions && selectedCategory != null) {
          return _buildTransactionView(controller, selectedCategory);
        }

        // Show categories list
        return RefreshIndicator(
          onRefresh: () async => controller.refreshCategories(),
          child: categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category,
                        size: 64,
                        color: AppConstants.textSecondary,
                      ),
                      SizedBox(height: AppConstants.paddingL),
                      Text(
                        'No Categories Yet',
                        style: AppConstants.headingMedium,
                      ),
                      SizedBox(height: AppConstants.paddingM),
                      Text(
                        'Create your first category to start tracking expenses',
                        style: AppConstants.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      category: category,
                      onTap: () => controller.goToTransactions(category),
                    );
                  },
                ),
        );
      }),
      floatingActionButton: Obx(() {
        // Hide FAB when showing transactions
        if (controller.showTransactions.value) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: controller.goToAddCategory,
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        );
      }),
    );
  }

  Widget _buildTransactionView(CategoryController controller, category) {
    return Column(
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          color: AppConstants.primaryColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Get.back();
                  controller.showTransactions.value = false;
                  controller.selectedCategory.value = null;
                },
              ),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => controller.goToAddTransaction(category),
                tooltip: 'Add Transaction',
              ),
            ],
          ),
        ),
        // Transactions list
        Expanded(
          child: Obx(() {
            final transactions = controller.transactions;

            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    const Text(
                      'No Transactions Yet',
                      style: AppConstants.headingMedium,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    ElevatedButton.icon(
                      onPressed: () => controller.goToAddTransaction(category),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Transaction'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionTile(
                  transaction: transaction,
                  onDelete: () => controller.deleteTransaction(transaction.id),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

