import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';

class AnalyticsController extends GetxController {
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;
  final SettingsService settings;

  AnalyticsController({
    required this.transactionRepo,
    required this.categoryRepo,
    required this.settings,
  });

  final transactions = <TransactionItem>[].obs;
  final categories = <Category>[].obs;
  final selectedRange = 0.obs; // 0=This Month, 1=3M, 2=6M

  static const ranges = ['This Month', 'Last 3M', 'Last 6M'];

  List<TransactionItem> get filteredTransactions {
    final months = _activeMonths();
    return transactions.where((t) {
      final key = AppDateUtils.getMonthKeyFromDate(t.date);
      return months.contains(key);
    }).toList();
  }

  List<String> _activeMonths() {
    final current = settings.effectiveMonth;
    switch (selectedRange.value) {
      case 1:
        return List.generate(3, (i) {
          var m = current;
          for (var j = 0; j < i; j++) { m = AppDateUtils.getPreviousMonthKey(m); }
          return m;
        });
      case 2:
        return List.generate(6, (i) {
          var m = current;
          for (var j = 0; j < i; j++) { m = AppDateUtils.getPreviousMonthKey(m); }
          return m;
        });
      default:
        return [current];
    }
  }

  /// Spend per month, oldest→newest.
  List<MonthlyTotal> get monthlyTotals {
    final months = _activeMonths().reversed.toList();
    return months.map((month) {
      final total = transactions
          .where((t) => AppDateUtils.getMonthKeyFromDate(t.date) == month)
          .fold(0, (sum, t) => sum + t.amountMinor);
      return MonthlyTotal(month: month, totalMinor: total);
    }).toList();
  }

  /// Spend per category, biggest first.
  List<CategorySpend> get categoryTotals {
    final activeMonths = _activeMonths();
    final spentByCategoryId = <String, int>{};
    for (final t in transactions) {
      if (activeMonths.contains(AppDateUtils.getMonthKeyFromDate(t.date))) {
        spentByCategoryId[t.categoryId] =
            (spentByCategoryId[t.categoryId] ?? 0) + t.amountMinor;
      }
    }
    return spentByCategoryId.entries.map((e) {
      Category? cat;
      try {
        cat = categories.firstWhere((c) => c.id == e.key);
      } catch (_) {}
      return CategorySpend(
          category: cat, categoryId: e.key, spentMinor: e.value);
    }).toList()
      ..sort((a, b) => b.spentMinor.compareTo(a.spentMinor));
  }

  int get totalSpentMinor =>
      filteredTransactions.fold(0, (sum, t) => sum + t.amountMinor);

  /// A ratio, not money: `int / int` is a `double` in Dart.
  double get savingsRate {
    final income = settings.monthlyIncomeMinor.value;
    if (income <= 0) return 0;
    return ((income - totalSpentMinor) / income * 100).clamp(0, 100);
  }

  @override
  void onInit() {
    super.onInit();
    transactionRepo.getTransactions().listen((list) => transactions.assignAll(list));
    categoryRepo.getCategories().listen((list) => categories.assignAll(list));
  }

  void setRange(int index) => selectedRange.value = index;
}

/// One bar of the monthly chart.
///
/// A type, not a `Map<String, dynamic>`: the old shape forced every reader to
/// write `data[i]['total'] as double`, a cast the compiler could not check and
/// which would have kept compiling — and started throwing at runtime — the
/// moment money became an `int` (H2).
class MonthlyTotal {
  /// Canonical `"YYYY-MM"` key.
  final String month;
  final int totalMinor;

  const MonthlyTotal({required this.month, required this.totalMinor});
}

/// One slice/row of the category breakdown.
class CategorySpend {
  /// Null when the transaction's category has since been deleted.
  final Category? category;
  final String categoryId;
  final int spentMinor;

  const CategorySpend({
    required this.category,
    required this.categoryId,
    required this.spentMinor,
  });
}
