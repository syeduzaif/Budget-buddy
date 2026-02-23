import 'package:intl/intl.dart';

class AppDateUtils {
  static String getCurrentMonthKey() {
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  static String getMonthKeyFromDate(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return monthKey;
    }
  }

  static String getPreviousMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      final prev = DateTime(date.year, date.month - 1, 1);
      return DateFormat('yyyy-MM').format(prev);
    } catch (_) {
      return monthKey;
    }
  }

  static String getNextMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      final next = DateTime(date.year, date.month + 1, 1);
      return DateFormat('yyyy-MM').format(next);
    } catch (_) {
      return monthKey;
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  static String formatMonthShort(String monthKey) {
    try {
      final parts = monthKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMM yy').format(date);
    } catch (_) {
      return monthKey;
    }
  }

  static List<String> getLastNMonthKeys(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(d);
    });
  }
}
