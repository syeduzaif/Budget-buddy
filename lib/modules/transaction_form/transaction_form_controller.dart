import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/predefined_categories.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';

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
      final filtered =
          list.where((c) => c.month == settings.currentMonth.value).toList();
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
    // Text → minor units directly. No double.parse, no multiply by 100: the
    // currency's own exponent decides the scale (C4).
    final amountMinor = CurrencyUtils.tryParseToMinor(
        amountController.text, settings.currency);
    if (amountMinor == null || amountMinor <= 0) return;

    isLoading.value = true;
    try {
      // If no category is selected, auto-create an "Other" category
      Category category;
      if (selectedCategory.value == null) {
        category = await _getOrCreateOtherCategory();
      } else {
        category = selectedCategory.value!;
      }

      final transaction = TransactionItem(
        id: const Uuid().v4(),
        categoryId: category.id,
        amountMinor: amountMinor,
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

  /// Returns an existing "Other" category for the current month, or creates one.
  Future<Category> _getOrCreateOtherCategory() async {
    final month = settings.effectiveMonth;

    // Check if an "Other" category already exists for this month
    final monthCats = await categoryRepo.getCategoriesForMonth(month);
    try {
      return monthCats.firstWhere((c) => c.name.toLowerCase() == 'other');
    } catch (_) {
      // Not found — create one
    }

    final other = Category(
      id: const Uuid().v4(),
      name: kOtherCategory.name,
      budgetLimitMinor: CurrencyUtils.fromMajor(
          kOtherCategory.defaultBudgetMajor, settings.currency),
      colorValue: kOtherCategory.colorValue,
      iconCodePoint: kOtherCategory.iconCodePoint,
      month: month,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.addCategory(other);
    return other;
  }
}
