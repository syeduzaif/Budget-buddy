import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';

class TransactionFormController extends GetxController {
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final SettingsService settings;

  TransactionFormController({
    required this.categoryRepo,
    required this.transactionRepo,
    required this.settings,
  });

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;

  // If opened from a category view, pre-select it
  String? preselectedCategoryId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    preselectedCategoryId = args?['categoryId'];

    categoryRepo.getCategories().listen((list) {
      final filtered = list
          .where((c) => c.month == settings.currentMonth.value)
          .toList();
      categories.assignAll(filtered);
      if (selectedCategory.value == null && filtered.isNotEmpty) {
        if (preselectedCategoryId != null) {
          try {
            selectedCategory.value =
                filtered.firstWhere((c) => c.id == preselectedCategoryId);
          } catch (_) {
            selectedCategory.value = filtered.first;
          }
        } else {
          selectedCategory.value = filtered.first;
        }
      }
    });
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void selectDate(DateTime date) => selectedDate.value = date;
  void selectCategory(Category cat) => selectedCategory.value = cat;

  Future<void> save() async {
    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || selectedCategory.value == null) return;

    isLoading.value = true;
    try {
      final transaction = TransactionItem(
        id: const Uuid().v4(),
        categoryId: selectedCategory.value!.id,
        amount: amount,
        note: noteController.text.trim(),
        date: selectedDate.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await transactionRepo.addTransaction(transaction);
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }
}
