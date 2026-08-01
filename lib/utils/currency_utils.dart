/// Money handling for the whole app.
///
/// **Money is an `int` of MINOR UNITS everywhere** — storage, arithmetic,
/// model fields, controller getters. Decimals exist only at the display
/// boundary ([formatAmount], [formatAmountCompact], [formatForInput]) and at
/// the chart boundary ([toMajor], which fl_chart forces to be a `double`).
///
/// How many minor units make one major unit is a property of the CURRENCY, not
/// a constant: `USD 1.00 = 100` cents, but `JPY 1 = 1` yen and there is no
/// smaller unit. Anything that hardcodes `* 100` is a defect (C4) — always go
/// through [minorPerMajor] / [Currency.decimalDigits].
///
/// User input is parsed from the text string straight into minor units
/// ([parseAmount]); it must never take the `double.parse(text) * 100` route,
/// which reintroduces the float error this module exists to remove.
library;

class CurrencyUtils {
  CurrencyUtils._();

  /// Fallback for an unknown/missing currency code, and the onboarding
  /// default. Also the first entry of [currencies].
  static const Currency usd =
      Currency(code: 'USD', name: 'US Dollar', symbol: '\$', decimalDigits: 2);

  /// The 23 currencies the app offers.
  ///
  /// `decimalDigits` is the ISO 4217 minor-unit exponent for each code —
  /// verified against ISO 4217 on 2026-08-01. JPY, KRW and VND are the only
  /// zero-decimal members of this list. Adding a currency without looking its
  /// exponent up is a money bug: the field is deliberately `required`.
  static const List<Currency> currencies = [
    usd,
    Currency(code: 'EUR', name: 'Euro', symbol: '€', decimalDigits: 2),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', decimalDigits: 2),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', decimalDigits: 2),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalDigits: 0),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', decimalDigits: 2),
    Currency(
        code: 'AUD', name: 'Australian Dollar', symbol: '\$', decimalDigits: 2),
    Currency(
        code: 'CAD', name: 'Canadian Dollar', symbol: '\$', decimalDigits: 2),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', decimalDigits: 2),
    Currency(
        code: 'SGD', name: 'Singapore Dollar', symbol: '\$', decimalDigits: 2),
    Currency(
        code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', decimalDigits: 2),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', decimalDigits: 2),
    Currency(
        code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', decimalDigits: 2),
    Currency(
        code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', decimalDigits: 2),
    Currency(
        code: 'NZD',
        name: 'New Zealand Dollar',
        symbol: '\$',
        decimalDigits: 2),
    Currency(
        code: 'ZAR', name: 'South African Rand', symbol: 'R', decimalDigits: 2),
    Currency(
        code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', decimalDigits: 2),
    Currency(
        code: 'MXN', name: 'Mexican Peso', symbol: '\$', decimalDigits: 2),
    Currency(
        code: 'KRW', name: 'South Korean Won', symbol: '₩', decimalDigits: 0),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', decimalDigits: 2),
    // ISO 4217 gives IDR two decimals (sen), even though Indonesian practice
    // rounds to whole rupiah. Following the standard, not the practice.
    Currency(
        code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', decimalDigits: 2),
    Currency(
        code: 'PHP', name: 'Philippine Peso', symbol: '₱', decimalDigits: 2),
    Currency(
        code: 'VND', name: 'Vietnamese Dong', symbol: '₫', decimalDigits: 0),
  ];

  static Currency? getByCode(String code) {
    for (final c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// [getByCode] with a safe fallback — an unknown code must never crash a
  /// screen or, worse, silently change how much money a number means.
  static Currency resolve(String? code) =>
      code == null ? usd : (getByCode(code) ?? usd);

  /// Minor units in one major unit: 100 for USD, 1 for JPY, 1000 for a
  /// 3-decimal currency. Never hardcode this.
  static int minorPerMajor(Currency currency) {
    var factor = 1;
    for (var i = 0; i < currency.decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  /// Whole major units → minor units (e.g. a preset budget of 500 → 50000 for
  /// USD, 500 for JPY).
  static int fromMajor(int majorUnits, Currency currency) =>
      majorUnits * minorPerMajor(currency);

  /// Minor units → a `double` of major units.
  ///
  /// DISPLAY/GEOMETRY BOUNDARY ONLY — fl_chart takes doubles. Never feed the
  /// result back into storage or arithmetic that is later stored.
  static double toMajor(int minorUnits, Currency currency) =>
      minorUnits / minorPerMajor(currency);

  // --- Display --------------------------------------------------------------

  /// `$1,234.56`, `¥1,234`, `-$12.00`.
  ///
  /// Built with integer arithmetic and a fixed `,` group / `.` decimal, so the
  /// output cannot drift with the ambient locale (a locale flip must never
  /// change what a stored number appears to mean).
  static String formatAmount(int minorUnits, Currency currency) {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    final factor = minorPerMajor(currency);
    final major = _group(abs ~/ factor);
    if (currency.decimalDigits == 0) return '$sign${currency.symbol}$major';
    final fraction =
        (abs % factor).toString().padLeft(currency.decimalDigits, '0');
    return '$sign${currency.symbol}$major.$fraction';
  }

  /// Whole major units, rounded half-up: `$1,235`. For tight rows where the
  /// decimals do not fit.
  static String formatAmountCompact(int minorUnits, Currency currency) {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    final factor = minorPerMajor(currency);
    final rounded = (abs + factor ~/ 2) ~/ factor;
    return '$sign${currency.symbol}${_group(rounded)}';
  }

  /// Plain major-unit text for prefilling an input field: no symbol, no group
  /// separators, trailing `.00` dropped. [parseAmount] of this string returns
  /// the value it was built from.
  static String formatForInput(int minorUnits, Currency currency) {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    final factor = minorPerMajor(currency);
    final major = abs ~/ factor;
    final remainder = abs % factor;
    if (remainder == 0) return '$sign$major';
    final fraction =
        remainder.toString().padLeft(currency.decimalDigits, '0');
    return '$sign$major.$fraction';
  }

  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // --- Input ----------------------------------------------------------------

  /// Reads a user-typed major-unit amount into minor units, by string, with no
  /// floating-point step anywhere.
  ///
  /// Accepted: optional sign, digits, `,` as a group separator in strict runs
  /// of three, at most one `.` as the decimal separator, at most
  /// `currency.decimalDigits` digits after it. Whitespace is ignored.
  ///
  /// Deliberately strict about `,`: `"12,50"` (a comma-decimal locale habit) is
  /// REJECTED rather than read as `1250`. A rejection the user can see and fix
  /// beats a silent 100x error. Comma-decimal locales must type `.` — a
  /// locale-aware parser is a separate piece of work.
  static ParsedAmount parseAmount(String? raw, Currency currency) {
    if (raw == null) return const ParsedAmount._(null, AmountParseError.empty);
    // Dart's `\s` follows ECMAScript: it already covers NBSP and thin
    // spaces, which soft keyboards and pasted values like to smuggle in.
    final stripped = raw.replaceAll(RegExp(r'\s'), '');
    if (stripped.isEmpty) {
      return const ParsedAmount._(null, AmountParseError.empty);
    }

    var body = stripped;
    var negative = false;
    if (body.startsWith('-')) {
      negative = true;
      body = body.substring(1);
    } else if (body.startsWith('+')) {
      body = body.substring(1);
    }

    final parts = body.split('.');
    if (parts.length > 2) {
      return const ParsedAmount._(null, AmountParseError.malformed);
    }
    final fraction = parts.length == 2 ? parts[1] : '';
    var whole = parts[0];
    if (whole.isEmpty && fraction.isEmpty) {
      return const ParsedAmount._(null, AmountParseError.malformed);
    }

    if (whole.contains(',')) {
      if (!RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(whole)) {
        return const ParsedAmount._(null, AmountParseError.malformed);
      }
      whole = whole.replaceAll(',', '');
    }
    if (whole.isEmpty) whole = '0';
    if (!RegExp(r'^\d+$').hasMatch(whole)) {
      return const ParsedAmount._(null, AmountParseError.malformed);
    }
    if (fraction.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fraction)) {
      return const ParsedAmount._(null, AmountParseError.malformed);
    }
    if (fraction.length > currency.decimalDigits) {
      return const ParsedAmount._(null, AmountParseError.tooPrecise);
    }
    // 15 digits keeps the padded result inside a 64-bit int for every
    // supported exponent.
    if (whole.length > 15) {
      return const ParsedAmount._(null, AmountParseError.tooLarge);
    }

    final value =
        int.tryParse(whole + fraction.padRight(currency.decimalDigits, '0'));
    if (value == null) {
      return const ParsedAmount._(null, AmountParseError.tooLarge);
    }
    return ParsedAmount._(negative ? -value : value, null);
  }

  /// [parseAmount] when the caller does not care why it failed.
  static int? tryParseToMinor(String? raw, Currency currency) =>
      parseAmount(raw, currency).minorUnits;
}

class Currency {
  final String code;
  final String name;
  final String symbol;

  /// ISO 4217 minor-unit exponent: 2 for USD/PKR, 0 for JPY/KRW/VND.
  /// Drives every conversion, format and parse for this currency.
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalDigits,
  });
}

/// Why [CurrencyUtils.parseAmount] could not read a string.
enum AmountParseError {
  /// Nothing entered.
  empty,

  /// Not a number in the accepted shape.
  malformed,

  /// More decimal places than the currency has.
  tooPrecise,

  /// Too many digits to hold exactly.
  tooLarge,
}

/// Outcome of [CurrencyUtils.parseAmount]: either [minorUnits] or an [error],
/// never both, never neither.
class ParsedAmount {
  final int? minorUnits;
  final AmountParseError? error;

  const ParsedAmount._(this.minorUnits, this.error);

  bool get isValid => minorUnits != null;
}
