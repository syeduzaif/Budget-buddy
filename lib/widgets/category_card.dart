import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/category.dart';
import '../services/budget_service.dart';
import '../utils/constants.dart';
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

      return Card(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    // Category name
                    Expanded(
                      child: Text(
                        category.name,
                        style: AppConstants.headingSmall,
                      ),
                    ),
                    // Remaining amount
                    Text(
                      '${CurrencyHelper.formatAmount(remaining, compact: true)} left',
                      style: AppConstants.bodyMedium.copyWith(
                        color: remaining >= 0
                            ? AppConstants.successColor
                            : AppConstants.dangerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingM),
                // Progress bar
                ProgressBar(
                  spent: spent,
                  limit: category.budgetLimit,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

