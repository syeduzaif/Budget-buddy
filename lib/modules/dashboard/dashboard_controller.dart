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

  /// True when the dashboard is showing the month the user is actually living
  /// in, as opposed to one they browsed back to.
  ///
  /// Three separate pieces of copy hang off this answer — whether the forward
  /// chevron is inert, whether the budgets card says "This Month's" or names
  /// the month, and whether the second summary card claims money is
  /// "Remaining" (a promise about the future) or merely "Unspent" (a fact
  /// about a month that already ended). Asked once so they cannot disagree.
  bool get isViewingCurrentMonth =>
      settings.currentMonth.value == AppDateUtils.getCurrentMonthKey();

  /// True when the month on screen is not the current one AND holds no
  /// transactions at all.
  ///
  /// Its one consumer is the summary block: on such a month "Monthly Income
  /// ₨45,000 · Spent ₨0 · Unspent ₨45,000" applies TODAY's income figure to a
  /// period the app knows nothing about, and volunteers a money claim about it
  /// ("in July you earned ₨45,000 and spent none of it") — reachable by every
  /// new user on day one (BUG-102). "Holds no records" rather than "predates
  /// first use" on purpose: browsing back WRITES categories into a month via
  /// `ensureMonth`, so the app cannot durably tell when it was installed, and
  /// the record-count predicate also covers "installed in June, logged nothing
  /// in June", which produces the identical bad screen.
  ///
  /// Count-based, never sum-based: a month whose rows happen to total zero is
  /// not an empty month. (A ₨0 transaction cannot be saved today — the amount
  /// validator refuses it — but the predicate does not lean on that.)
  ///
  /// Deliberately beside [isViewingCurrentMonth]: the "Unspent" relabel and this
  /// suppression must never disagree about which month is which.
  bool get viewedMonthHasNoRecords =>
      !isViewingCurrentMonth && !transactions.any(_isCurrentMonth);

  /// How many rows the dashboard's Recent card shows. Five: enough to prove
  /// the last few logs landed, few enough to stay above the fold.
  static const int recentLimit = 5;

  /// The newest few transactions of the VIEWED month, for the Recent card.
  ///
  /// Month-scoped like every other number on this screen — an all-time list
  /// under a month-scoped Spent figure is the mismatch F-04 exists to close, so
  /// a back-dated row appears on its own month's dashboard and nowhere else.
  /// `watchTransactions` already sorts newest first, so this only takes.
  List<TransactionItem> get recentTransactions =>
      transactions.where(_isCurrentMonth).take(recentLimit).toList();

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
