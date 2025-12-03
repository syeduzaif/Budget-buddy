import 'package:get/get.dart';
import '../data/storage/hive_service.dart';
import '../utils/helpers.dart';

class AiInsightsService extends GetxService {
  /// Analyze monthly spending and return a list of insights
  List<String> analyzeMonthlySpending() {
    final insights = <String>[];
    final categories = HiveService.getAllCategories();
    final transactions = HiveService.getAllTransactions();
    final currentMonth = HiveService.getCurrentMonth();
    final income = HiveService.getMonthlyIncome();

    // Filter transactions for current month
    final monthTransactions = transactions.where((t) {
      return Helpers.getMonthKeyFromDate(t.date) == currentMonth;
    }).toList();

    final totalSpent = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // 1. Overall Budget Analysis
    if (income > 0) {
      final percentage = (totalSpent / income) * 100;
      if (percentage > 90) {
        insights.add(
            "⚠️ Critical: You have spent ${percentage.toStringAsFixed(1)}% of your monthly income.");
      } else if (percentage > 75) {
        insights.add(
            "⚠️ Warning: You have used ${percentage.toStringAsFixed(1)}% of your income.");
      } else if (percentage < 50 && DateTime.now().day > 20) {
        insights.add("✅ Great job! You are well under budget for this month.");
      }
    }

    // 2. Category Analysis
    for (var category in categories) {
      if (category.month != currentMonth) continue;

      final spent = category.calculateTotalSpent(monthTransactions);
      final percentage = category.calculatePercentage(spent);

      if (percentage >= 100) {
        insights.add(
            "❌ Overspent in ${category.name}: ${percentage.toStringAsFixed(1)}% of budget used.");
      } else if (percentage > 80) {
        insights.add(
            "⚠️ High spending in ${category.name}: ${percentage.toStringAsFixed(1)}% used.");
      }
    }

    // 3. Spending Trends (Simple comparison)
    // This would require historical data which we might not have fully indexed yet,
    // but we can check high frequency small expenses.
    int smallExpensesCount =
        monthTransactions.where((t) => t.amount < 50).length;
    if (smallExpensesCount > 10) {
      insights.add(
          "💡 You have many small transactions ($smallExpensesCount). Small purchases add up!");
    }

    return insights;
  }

  /// Get specific advice based on user query
  String getAdviceForQuery(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains("save") || lowerQuery.contains("saving")) {
      return "To save more, try the 50/30/20 rule: 50% needs, 30% wants, 20% savings. Also, review your subscriptions.";
    }

    if (lowerQuery.contains("spent") || lowerQuery.contains("spend")) {
      final total = _getCurrentMonthTotal();
      return "You have spent ${HiveService.getCurrencySymbol()}${total.toStringAsFixed(2)} this month.";
    }

    if (lowerQuery.contains("budget")) {
      return "Check your category budgets. Stick to the limits to avoid overspending.";
    }

    return "I can help you analyze your spending. Ask me about your budget, savings, or specific categories.";
  }

  double _getCurrentMonthTotal() {
    final transactions = HiveService.getAllTransactions();
    final currentMonth = HiveService.getCurrentMonth();
    return transactions
        .where((t) => Helpers.getMonthKeyFromDate(t.date) == currentMonth)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
