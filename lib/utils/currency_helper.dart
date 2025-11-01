import '../data/storage/hive_service.dart';
import 'helpers.dart';

/// Helper class for currency operations
class CurrencyHelper {
  /// Common currencies with their names and codes
  static const List<Currency> currencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: '\$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: '\$'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: '\$'),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨'),
    Currency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
    Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: '\$'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: '\$'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿'),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
  ];

  /// Get currency symbol from storage
  static String getCurrencySymbol() {
    return HiveService.getCurrencySymbol();
  }

  /// Get selected currency code
  static String getSelectedCurrencyCode() {
    return HiveService.getSelectedCurrency();
  }

  /// Format amount with currency symbol
  static String formatAmount(double amount, {bool compact = false}) {
    final symbol = getCurrencySymbol();
    if (compact) {
      return '$symbol${Helpers.formatCurrencyCompact(amount)}';
    }
    return '$symbol${Helpers.formatCurrency(amount)}';
  }

  /// Check if user has selected currency
  static bool hasSelectedCurrency() {
    return HiveService.hasSelectedCurrency();
  }

  /// Get currency by code
  static Currency? getCurrencyByCode(String code) {
    try {
      return currencies.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}

/// Currency model
class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

