import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'category_controller.dart';
import '../../widgets/category_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../data/models/category.dart';

/// Categories view showing list of categories
class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
      ),
      body: Obx(() {
        final categories = controller.budgetService.categories;
        final showTransactions = controller.showTransactions.value;
        final selectedCategory = controller.selectedCategory.value;

        // If showing transactions, display transaction list
        if (showTransactions && selectedCategory != null) {
          return _buildTransactionView(controller, selectedCategory, theme);
        }

        // Show categories list
        return RefreshIndicator(
          onRefresh: () async => controller.refreshCategories(),
          child: categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 80,
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Categories Yet',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your first category to start tracking expenses',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Hero(
                      tag: 'category_${category.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CategoryCard(
                          category: category,
                          onTap: () => controller.goToTransactions(category),
                        ),
                      ),
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

  Widget _buildTransactionView(
      CategoryController controller, Category category, ThemeData theme) {
    return Column(
      children: [
        // Category header with gradient
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(category.colorValue),
                Color(category.colorValue).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          // Manually handle back if we want to stay in view, otherwise Get.back() pops the route.
                          // The controller logic uses a bool toggle.
                          if (controller.showTransactions.value) {
                            controller.showTransactions.value = false;
                            controller.selectedCategory.value = null;
                          } else {
                            Get.back();
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          category.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () =>
                            controller.goToAddTransaction(category),
                        tooltip: 'Add Transaction',
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Transactions Yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
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
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionTile(
                    transaction: transaction,
                    onDelete: () =>
                        controller.deleteTransaction(transaction.id),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
