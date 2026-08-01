import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

class CategoriesController extends GetxController {
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final SettingsService settings;

  CategoriesController({
    required this.categoryRepo,
    required this.transactionRepo,
    required this.settings,
  });

  final categories = <Category>[].obs;
  final transactions = <TransactionItem>[].obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  List<Category> get filtered => searchQuery.value.isEmpty
      ? categories
      : categories
          .where((c) =>
              c.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();

  /// Spend for one category this month, in minor units (exact integer sum).
  int spentForCategoryMinor(String categoryId) => transactions
      .where((t) =>
          t.categoryId == categoryId &&
          AppDateUtils.getMonthKeyFromDate(t.date) ==
              settings.currentMonth.value)
      .fold(0, (sum, t) => sum + t.amountMinor);

  @override
  void onInit() {
    super.onInit();
    categoryRepo.getCategories().listen(
      (list) {
        categories.assignAll(
            list.where((c) => c.month == settings.currentMonth.value).toList());
      },
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[CategoriesController] category stream failed: $e\n$s');
      },
    );
    transactionRepo.getTransactions().listen(
      (list) => transactions.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[CategoriesController] transaction stream failed: $e\n$s');
      },
    );

    // Re-filter categories when month changes from the dashboard
    ever(settings.currentMonth, (_) {
      categoryRepo.getCategories().first.then(
        (list) {
          categories.assignAll(list
              .where((c) => c.month == settings.currentMonth.value)
              .toList());
        },
        // A `then` without this is an unhandled async error (H2).
        onError: (Object e, StackTrace s) {
          debugPrint('[CategoriesController] month re-filter failed: $e\n$s');
        },
      );
    });
  }

  Future<void> deleteCategory(Category category) async {
    await categoryRepo.deleteCategory(category.id);
  }

  Future<void> addCategory({
    required String name,
    required int budgetLimitMinor,
    required int colorValue,
  }) async {
    final category = Category(
      id: const Uuid().v4(),
      name: name,
      budgetLimitMinor: budgetLimitMinor,
      colorValue: colorValue,
      month: settings.effectiveMonth,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.addCategory(category);
  }

  Future<void> updateCategory(Category updated) async {
    await categoryRepo.updateCategory(updated);
  }
}
