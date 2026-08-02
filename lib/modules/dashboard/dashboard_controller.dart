// `show debugPrint` only: foundation also exports a `Category`
// annotation, which would collide with our model.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

class DashboardController extends GetxController {
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final SettingsService settings;

  DashboardController({
    required this.categoryRepo,
    required this.transactionRepo,
    required this.settings,
  });

  final categories = <Category>[].obs;
  final transactions = <TransactionItem>[].obs;

  // Every total below is in integer minor units — exact addition, no float
  // accumulator (C4).

  int get totalBudgetMinor =>
      categories.fold(0, (sum, c) => sum + c.budgetLimitMinor);

  int get totalSpentMinor => transactions
      .where((t) => _isCurrentMonth(t))
      .fold(0, (sum, t) => sum + t.amountMinor);

  int get remainingMinor => settings.monthlyIncomeMinor.value - totalSpentMinor;

  /// A ratio, not money: `int / int` is a `double` in Dart.
  double get savingsRate {
    final income = settings.monthlyIncomeMinor.value;
    if (income <= 0) return 0;
    return ((income - totalSpentMinor) / income * 100).clamp(0, 100);
  }

  int spentForCategoryMinor(String categoryId) => transactions
      .where((t) => t.categoryId == categoryId && _isCurrentMonth(t))
      .fold(0, (sum, t) => sum + t.amountMinor);

  bool _isCurrentMonth(TransactionItem t) =>
      AppDateUtils.getMonthKeyFromDate(t.date) == settings.currentMonth.value;

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
        debugPrint('[DashboardController] category stream failed: $e\n$s');
      },
    );
    transactionRepo.getTransactions().listen(
      (list) => transactions.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[DashboardController] transaction stream failed: $e\n$s');
      },
    );
  }

  void goToPreviousMonth() async {
    final prev = AppDateUtils.getPreviousMonthKey(settings.currentMonth.value);
    await settings.setCurrentMonth(prev);
    await categoryRepo.ensureMonth(prev);
    _refreshCategories();
  }

  void goToNextMonth() async {
    final next = AppDateUtils.getNextMonthKey(settings.currentMonth.value);
    await settings.setCurrentMonth(next);
    await categoryRepo.ensureMonth(next);
    _refreshCategories();
  }

  void _refreshCategories() {
    categoryRepo.getCategories().first.then(
      (list) {
        categories.assignAll(
            list.where((c) => c.month == settings.currentMonth.value).toList());
      },
      // A `then` without this is an unhandled async error (H2).
      onError: (Object e, StackTrace s) {
        debugPrint('[DashboardController] category refresh failed: $e\n$s');
      },
    );
  }
}
