import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../services/budget_service.dart';
import '../../utils/constants.dart';
import 'package:uuid/uuid.dart';

/// Controller for Add Category view
class AddCategoryController extends GetxController {
  final BudgetService budgetService = Get.find<BudgetService>();

  // Reactive variables
  final RxInt selectedColorIndex = 0.obs;

  /// Create a new category
  Future<void> createCategory({
    required String name,
    required double budgetLimit,
  }) async {
    if (name.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Category name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    if (budgetLimit <= 0) {
      Get.snackbar(
        'Error',
        'Budget limit must be greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    final category = Category(
      id: const Uuid().v4(),
      name: name.trim(),
      budgetLimit: budgetLimit,
      colorValue: AppConstants.categoryColors[selectedColorIndex.value].toARGB32(),
      month: budgetService.currentMonth.value,
      createdAt: DateTime.now(),
    );

    await budgetService.addCategory(category);

    Get.back();
    Get.snackbar(
      'Success',
      'Category created successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppConstants.successColor,
      colorText: Colors.white,
    );
  }

  /// Select color by index
  void selectColor(int index) {
    selectedColorIndex.value = index;
  }
}

