import 'currency_utils.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  /// Validator for a money field, bound to the currency the user is entering.
  ///
  /// Currency-aware on purpose: 3 decimals is valid for a 3-decimal currency
  /// and nonsense for USD, and any decimal at all is nonsense for JPY. Returns
  /// a validator so it can be handed straight to a `TextFormField`:
  /// `validator: Validators.amount(currency)`.
  static String? Function(String?) amount(Currency currency) {
    return (String? value) {
      final parsed = CurrencyUtils.parseAmount(value, currency);
      final problem = _amountProblem(parsed.error, currency);
      if (problem != null) return problem;
      final minorUnits = parsed.minorUnits;
      if (minorUnits == null || minorUnits <= 0) return 'Enter a valid amount';
      return null;
    };
  }

  /// [amount] for an optional field that may legitimately be blank or zero —
  /// monthly income. Only rejects text that cannot be read as money; a blank
  /// field means zero.
  static String? Function(String?) amountOrZero(Currency currency) {
    return (String? value) {
      final parsed = CurrencyUtils.parseAmount(value, currency);
      if (parsed.error == AmountParseError.empty) return null;
      final problem = _amountProblem(parsed.error, currency);
      if (problem != null) return problem;
      final minorUnits = parsed.minorUnits;
      if (minorUnits == null || minorUnits < 0) return 'Enter a valid amount';
      return null;
    };
  }

  static String? _amountProblem(AmountParseError? error, Currency currency) {
    switch (error) {
      case AmountParseError.empty:
        return 'Amount is required';
      case AmountParseError.malformed:
        return 'Enter a valid amount';
      case AmountParseError.tooPrecise:
        return currency.decimalDigits == 0
            ? '${currency.code} amounts have no decimal places'
            : 'Use at most ${currency.decimalDigits} decimal places';
      case AmountParseError.tooLarge:
        return 'Amount is too large';
      case null:
        return null;
    }
  }

  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Category name is required';
    if (value.trim().length > 30) return 'Name must be under 30 characters';
    return null;
  }
}
