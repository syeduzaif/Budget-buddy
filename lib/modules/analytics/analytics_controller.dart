import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
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

  /// The period each range covers, spelled out for the stat cards. Two ranges
  /// can otherwise show the same number with nothing to tell them apart
  /// (UI-10) — which is how the F4 savings-rate defect hides.
  static const rangePeriodLabels = [
    'This month',
    'Last 3 months',
    'Last 6 months',
  ];

  /// The selected range's period label.
  String get rangePeriodLabel => rangePeriodLabels[selectedRange.value];

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

  /// Spend per category NAME, biggest first.
  ///
  /// By name, not by `categoryId`: every month holds its own clones of the
  /// user's categories with fresh ids, so grouping a multi-month range by id
  /// drew the same category as up to N slices — same name, same colour,
  /// partial amounts each, and a legend repeating itself. Invisible while an
  /// install is one month old; guaranteed the moment a rollover happens
  /// (F-02). Name is this app's operative category identity, matched the way
  /// the attribution resolver matches it: trimmed and case-insensitive.
  ///
  /// Spend whose category is gone entirely joins the reserved bucket's row —
  /// the same answer attribution gives it.
  List<CategorySpend> get categoryTotals {
    final activeMonths = _activeMonths().toSet();
    final byId = {for (final c in categories) c.id: c};

    final totalByKey = <String, int>{};
    final fallbackName = <String, String>{};
    for (final t in transactions) {
      if (!activeMonths.contains(AppDateUtils.getMonthKeyFromDate(t.date))) {
        continue;
      }
      final name = byId[t.categoryId]?.name ?? kUncategorisedCategoryName;
      final key = _matchKey(name);
      totalByKey[key] = (totalByKey[key] ?? 0) + t.amountMinor;
      fallbackName.putIfAbsent(key, () => name.trim());
    }

    return totalByKey.entries.map((e) {
      final clone = _newestNamed(e.key);
      return CategorySpend(
        category: clone,
        name: clone?.name ?? fallbackName[e.key]!,
        spentMinor: e.value,
      );
    }).toList()
      // Name breaks ties: two groups can hold identical amounts, and
      // `List.sort` is not stable, so without it the legend and the slices
      // could reorder themselves between rebuilds.
      ..sort((a, b) {
        final bySpend = b.spentMinor.compareTo(a.spentMinor);
        return bySpend != 0 ? bySpend : a.name.compareTo(b.name);
      });
  }

  /// The clone that supplies a group's colour and icon: the most recently
  /// created one, so a recolour shows up in the range chart immediately.
  ///
  /// Deliberately the opposite end from the resolver's oldest-wins rule —
  /// that one settles identity, which must not move; this one settles
  /// appearance, which should follow the user's latest choice.
  Category? _newestNamed(String matchKey) {
    Category? best;
    for (final c in categories) {
      if (_matchKey(c.name) != matchKey) continue;
      if (best == null ||
          c.createdAt.isAfter(best.createdAt) ||
          (c.createdAt == best.createdAt && c.id.compareTo(best.id) < 0)) {
        best = c;
      }
    }
    return best;
  }

  static String _matchKey(String name) => name.trim().toLowerCase();

  int get totalSpentMinor =>
      filteredTransactions.fold(0, (sum, t) => sum + t.amountMinor);

  /// Savings rate over the SELECTED RANGE, in percent.
  ///
  /// The defect this closes: range-scoped spend was divided by ONE month's
  /// income, so "Last 3 months" and "This month" reported the same rate on
  /// different periods — ₨12,650 spent against ₨150,000 income read 91.6% for
  /// both, where three months of that income makes it 97.2%.
  double get savingsRate => savingsRatePercent(
        incomeMinorPerMonth: settings.monthlyIncomeMinor.value,
        months: _activeMonths().length,
        spentMinor: totalSpentMinor,
      );

  /// `(income × months − spent) / (income × months)`, as a percentage clamped
  /// to [0, 100].
  ///
  /// Pure and static — no clock, no store, no Rx — so the arithmetic can be
  /// tested as arithmetic. [months] is how many month partitions the range
  /// covers (1, 3, 6), NOT how many of them contain transactions: an install
  /// younger than the range therefore reads high, because the empty months
  /// still count their income. That is accepted and documented (F-03 §4), not
  /// a rounding artefact.
  ///
  /// Unknown or zero income yields 0% rather than a division by zero: a rate
  /// against an income nobody entered would be an invented number.
  static double savingsRatePercent({
    required int incomeMinorPerMonth,
    required int months,
    required int spentMinor,
  }) {
    // Minor units, so exact: no float income ever enters the division.
    final incomeForRange = incomeMinorPerMonth * months;
    if (incomeForRange <= 0) return 0;
    return ((incomeForRange - spentMinor) / incomeForRange * 100)
        .clamp(0, 100)
        .toDouble();
  }

  @override
  void onInit() {
    super.onInit();
    transactionRepo.getTransactions().listen(
      (list) => transactions.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[AnalyticsController] transaction stream failed: $e\n$s');
      },
    );
    categoryRepo.getCategories().listen(
      (list) => categories.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[AnalyticsController] category stream failed: $e\n$s');
      },
    );
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

/// One slice/row of the category breakdown — a NAME's total across the range,
/// not one category record's.
class CategorySpend {
  /// The clone supplying colour and icon: one of possibly several month-clones
  /// sharing [name]. Null only when nothing by that name exists any more.
  ///
  /// Never an identity — read [name] for that. Carrying a single `categoryId`
  /// here would be a lie the moment a range spans two months.
  final Category? category;

  /// The group's display name.
  final String name;

  final int spentMinor;

  const CategorySpend({
    required this.category,
    required this.name,
    required this.spentMinor,
  });
}
