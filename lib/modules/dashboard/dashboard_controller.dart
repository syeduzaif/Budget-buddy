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

  double get totalBudget =>
      categories.fold(0.0, (sum, c) => sum + c.budgetLimit);

  double get totalSpent => transactions
      .where((t) => _isCurrentMonth(t))
      .fold(0.0, (sum, t) => sum + t.amount);

  double get remaining => settings.monthlyIncome.value - totalSpent;

  double get savingsRate {
    final income = settings.monthlyIncome.value;
    if (income <= 0) return 0;
    return ((income - totalSpent) / income * 100).clamp(0, 100);
  }

  double spentForCategory(String categoryId) => transactions
      .where((t) => t.categoryId == categoryId && _isCurrentMonth(t))
      .fold(0.0, (sum, t) => sum + t.amount);

  bool _isCurrentMonth(TransactionItem t) =>
      AppDateUtils.getMonthKeyFromDate(t.date) == settings.currentMonth.value;

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

  void goToPreviousMonth() async {
    final prev = AppDateUtils.getPreviousMonthKey(settings.currentMonth.value);
    await settings.setCurrentMonth(prev);
    _refreshCategories();
  }

  void goToNextMonth() async {
    final next = AppDateUtils.getNextMonthKey(settings.currentMonth.value);
    await settings.setCurrentMonth(next);
    _refreshCategories();
  }

  void _refreshCategories() {
    categoryRepo.getCategories().first.then((list) {
      categories.assignAll(
          list.where((c) => c.month == settings.currentMonth.value).toList());
    });
  }
}
