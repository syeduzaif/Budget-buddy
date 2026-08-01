// `show debugPrint` only: foundation also exports a `Category`
// annotation, which would collide with our model.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
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
    await _ensureCategoriesForMonth(prev);
    _refreshCategories();
  }

  void goToNextMonth() async {
    final next = AppDateUtils.getNextMonthKey(settings.currentMonth.value);
    await settings.setCurrentMonth(next);
    await _ensureCategoriesForMonth(next);
    _refreshCategories();
  }

  /// If the target month has no categories, clone them from the most recent
  /// month that does. This gives each month the same category structure;
  /// users can then edit amounts per-month.
  Future<void> _ensureCategoriesForMonth(String targetMonth) async {
    final existing = await categoryRepo.getCategoriesForMonth(targetMonth);
    if (existing.isNotEmpty) return; // already has categories

    // Walk backwards from the month before the target to find a source month.
    const uuid = Uuid();
    final now = DateTime.now();
    String probe = AppDateUtils.getPreviousMonthKey(targetMonth);
    // Also check the month after target (in case user navigated backward first)
    final probeForward = AppDateUtils.getNextMonthKey(targetMonth);

    List<Category> source = await categoryRepo.getCategoriesForMonth(probe);
    if (source.isEmpty) {
      source = await categoryRepo.getCategoriesForMonth(probeForward);
    }
    // Walk up to 12 months back if neither neighbour had categories
    if (source.isEmpty) {
      for (int i = 0; i < 12; i++) {
        probe = AppDateUtils.getPreviousMonthKey(probe);
        source = await categoryRepo.getCategoriesForMonth(probe);
        if (source.isNotEmpty) break;
      }
    }

    if (source.isEmpty) return; // nothing to clone

    final cloned = source
        .map((cat) => Category(
              id: uuid.v4(),
              name: cat.name,
              budgetLimitMinor: cat.budgetLimitMinor,
              colorValue: cat.colorValue,
              iconCodePoint: cat.iconCodePoint,
              month: targetMonth,
              createdAt: now,
              updatedAt: now,
            ))
        .toList();

    await categoryRepo.addCategories(cloned);
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
