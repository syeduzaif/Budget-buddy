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
    try {
      await categoryRepo.deleteCategory(category.id);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, unlike the Firestore calls this code was written
      // against, which failed silently (H3).
      debugPrint('[CategoriesController] delete failed: $e\n$stack');
      // The row has already been swiped away; say plainly that the data has
      // not, rather than letting the gesture imply a delete that failed.
      Get.snackbar(
        'Could not delete "${category.name}"',
        'It is still saved — reopen this screen to see it.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
    try {
      await categoryRepo.addCategory(category);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, unlike the Firestore calls this code was written
      // against, which failed silently (H3).
      debugPrint('[CategoriesController] add failed: $e\n$stack');
      Get.snackbar(
        'Could not save category',
        'Nothing was saved. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateCategory(Category updated) async {
    try {
      await categoryRepo.updateCategory(updated);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, unlike the Firestore calls this code was written
      // against, which failed silently (H3).
      debugPrint('[CategoriesController] update failed: $e\n$stack');
      Get.snackbar(
        'Could not save changes',
        'The category is unchanged. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
