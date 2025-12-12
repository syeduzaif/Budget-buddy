import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/category.dart';
import '../services/budget_service.dart';
import '../utils/currency_helper.dart';
import 'progress_bar.dart';

/// Card widget to display a category with budget progress
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final budgetService = Get.find<BudgetService>();

    return Obx(() {
      // Access observable variables to trigger updates when they change
      // ignore: unused_local_variable
      final _ = budgetService.categories.length;
      // ignore: unused_local_variable
      final __ = budgetService.transactionUpdateTrigger.value;

      final spent = budgetService.getCategorySpending(category.id);
      final remaining = category.calculateRemaining(spent);
      final percentage = category.budgetLimit > 0
          ? (spent / category.budgetLimit * 100).clamp(0, 100)
          : 0.0;

      // Determine color based on spending percentage
      Color statusColor;
      if (percentage < 75) {
        statusColor = const Color(0xFF66BB6A); // Green
      } else if (percentage < 100) {
        statusColor = const Color(0xFFFFB800); // Orange
      } else {
        statusColor = const Color(0xFFFF6B6B); // Red
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        shadowColor: Color(category.colorValue).withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(category.colorValue).withOpacity(0.08),
                  Color(category.colorValue).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Row(
                  children: [
                    // Color indicator with icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category,
                        color: Color(category.colorValue),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category name and budget
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Budget: ${CurrencyHelper.formatAmount(category.budgetLimit, compact: true)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Remaining amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyHelper.formatAmount(remaining, compact: true),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'left',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                ProgressBar(
                  spent: spent,
                  limit: category.budgetLimit,
                ),
                const SizedBox(height: 8),
                // Spent amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${CurrencyHelper.formatAmount(spent, compact: true)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
