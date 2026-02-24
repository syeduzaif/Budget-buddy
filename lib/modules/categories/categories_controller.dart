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

  double spentForCategory(String categoryId) => transactions
      .where((t) =>
          t.categoryId == categoryId &&
          AppDateUtils.getMonthKeyFromDate(t.date) ==
              settings.currentMonth.value)
      .fold(0.0, (sum, t) => sum + t.amount);

  @override
  void onInit() {
    super.onInit();
    categoryRepo.getCategories().listen((list) {
      categories.assignAll(
          list.where((c) => c.month == settings.currentMonth.value).toList());
    });
    transactionRepo.getTransactions().listen((list) {
      transactions.assignAll(list);
    });
  }

  Future<void> deleteCategory(Category category) async {
    await categoryRepo.deleteCategory(category.id);
  }

  Future<void> addCategory({
    required String name,
    required double budgetLimit,
    required int colorValue,
  }) async {
    final category = Category(
      id: const Uuid().v4(),
      name: name,
      budgetLimit: budgetLimit,
      colorValue: colorValue,
      month: settings.currentMonth.value.isNotEmpty
          ? settings.currentMonth.value
          : AppDateUtils.getCurrentMonthKey(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.addCategory(category);
  }

  Future<void> updateCategory(Category updated) async {
    await categoryRepo.updateCategory(updated);
  }
}
