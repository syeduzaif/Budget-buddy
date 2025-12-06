import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/storage/hive_service.dart';
import '../utils/helpers.dart';

class AiAlertService extends GetxService {
  void checkAndTriggerAlerts() {
    final categories = HiveService.getAllCategories();
    final transactions = HiveService.getAllTransactions();
    final currentMonth = HiveService.getCurrentMonth();

    final monthTransactions = transactions.where((t) {
      return Helpers.getMonthKeyFromDate(t.date) == currentMonth;
    }).toList();

    for (var category in categories) {
      if (category.month != currentMonth) continue;

      final spent = category.calculateTotalSpent(monthTransactions);
      final percentage = category.calculatePercentage(spent);

      if (percentage >= 100) {
        _showNotification(
          "Budget Exceeded",
          "You have exceeded your budget for ${category.name}!",
          Colors.red,
        );
      } else if (percentage >= 90) {
        _showNotification(
          "Budget Alert",
          "You have used 90% of your ${category.name} budget.",
          Colors.orange,
        );
      }
    }
  }

  void _showNotification(String title, String message, Color color) {
    // Simple debounce or check to avoid spamming could be added here
    // For now, we rely on this being called sparingly (e.g. on app open or new transaction)
    Get.snackbar(
      title,
      message,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      icon: Icon(Icons.warning_amber_rounded, color: color),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }
}
