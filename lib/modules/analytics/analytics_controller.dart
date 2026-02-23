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
    final current = settings.currentMonth.value.isNotEmpty
        ? settings.currentMonth.value
        : AppDateUtils.getCurrentMonthKey();
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

  /// Returns list of {month, total} sorted oldest→newest
  List<Map<String, dynamic>> get monthlyTotals {
    final months = _activeMonths().reversed.toList();
    return months.map((month) {
      final total = transactions
          .where((t) => AppDateUtils.getMonthKeyFromDate(t.date) == month)
          .fold(0.0, (sum, t) => sum + t.amount);
      return {'month': month, 'total': total};
    }).toList();
  }

  /// Returns list of {category, spent} sorted by spent desc
  List<Map<String, dynamic>> get categoryTotals {
    final activeMonths = _activeMonths();
    final map = <String, double>{};
    for (final t in transactions) {
      if (activeMonths.contains(AppDateUtils.getMonthKeyFromDate(t.date))) {
        map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
      }
    }
    final result = map.entries.map((e) {
      Category? cat;
      try {
        cat = categories.firstWhere((c) => c.id == e.key);
      } catch (_) {}
      return {'category': cat, 'categoryId': e.key, 'spent': e.value};
    }).toList()
      ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));
    return result;
  }

  double get totalSpent =>
      filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get savingsRate {
    final income = settings.monthlyIncome.value;
    if (income <= 0) return 0;
    return ((income - totalSpent) / income * 100).clamp(0, 100);
  }

  @override
  void onInit() {
    super.onInit();
    transactionRepo.getTransactions().listen((list) => transactions.assignAll(list));
    categoryRepo.getCategories().listen((list) => categories.assignAll(list));
  }

  void setRange(int index) => selectedRange.value = index;
}
