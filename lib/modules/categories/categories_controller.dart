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

  /// True when the list on screen is a search result, empty or not.
  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  /// Title for the NO-RESULTS state, naming what was searched for.
  ///
  /// A search that matches nothing used to render the FIRST-RUN empty state —
  /// "No categories yet / Tap + to create your first budget category" plus an
  /// Add Category button — with eleven categories on file. Every word of that
  /// was false, and the button pushed the user toward creating a duplicate of
  /// the category the search had merely failed to match: a typo'd "Fod" invited
  /// a second Food (BUG-002).
  ///
  /// Pure and static like `TransactionsController.emptyCopyFor`, for the same
  /// reason: the copy is the fix, so it is readable and testable without a
  /// widget. The fallback wording covers a query that is only whitespace —
  /// there is nothing to quote, but the state is still a search.
  static String searchEmptyTitleFor(String query) {
    final trimmed = query.trim();
    return trimmed.isEmpty
        ? 'No categories match your search'
        : 'No categories match "$trimmed"';
  }

  /// The one muted line beneath [searchEmptyTitleFor].
  ///
  /// Describes the way out that the screen actually has — the search field's own
  /// clear button, one row up — and offers no creation affordance, which is the
  /// half of BUG-002 that could cost the user data quality.
  static const String searchEmptyLine = 'Try a different search.';

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
      // write, so a failure is never reported as a success (H3).
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
      // write, so a failure is never reported as a success (H3).
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
      // write, so a failure is never reported as a success (H3).
      debugPrint('[CategoriesController] update failed: $e\n$stack');
      Get.snackbar(
        'Could not save changes',
        'The category is unchanged. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
