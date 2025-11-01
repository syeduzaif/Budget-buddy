import 'package:intl/intl.dart';

/// Helper functions for common operations
class Helpers {
  /// Get current month key in format "YYYY-MM"
  static String getCurrentMonthKey() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM').format(now);
  }

  /// Format date to readable string (e.g., "Dec 15, 2023")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date to short format (e.g., "12/15")
  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  /// Format currency (e.g., "50,000.00")
  static String formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  /// Format currency without decimals (e.g., "50,000")
  static String formatCurrencyCompact(double amount) {
    return NumberFormat('#,##0').format(amount);
  }

  /// Format month key to readable format (e.g., "2023-11" -> "November 2023")
  static String formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return monthKey;
    }
  }

  /// Get month key for a specific date
  static String getMonthKeyFromDate(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// Get color based on spending percentage
  /// Green (<75%), Orange (75-100%), Red (>100%)
  static int getColorForPercentage(double percentage) {
    if (percentage < 75) {
      return 0xFF4CAF50; // Green
    } else if (percentage <= 100) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }

  /// Get previous month key
  static String getPreviousMonthKey(String currentMonthKey) {
    try {
      final parts = currentMonthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month, 1);
      final previousMonth = DateTime(date.year, date.month - 1, 1);
      return DateFormat('yyyy-MM').format(previousMonth);
    } catch (e) {
      return currentMonthKey;
    }
  }

  /// Get next month key
  static String getNextMonthKey(String currentMonthKey) {
    try {
      final parts = currentMonthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month, 1);
      final nextMonth = DateTime(date.year, date.month + 1, 1);
      return DateFormat('yyyy-MM').format(nextMonth);
    } catch (e) {
      return currentMonthKey;
    }
  }

  /// Validate if amount is valid
  static bool isValidAmount(String amount) {
    if (amount.isEmpty) return false;
    final parsedAmount = double.tryParse(amount);
    return parsedAmount != null && parsedAmount > 0;
  }

  /// Parse amount from string
  static double parseAmount(String amount) {
    return double.tryParse(amount) ?? 0.0;
  }
}

