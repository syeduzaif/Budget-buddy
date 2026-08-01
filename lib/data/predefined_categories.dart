import 'package:flutter/material.dart';
import '../utils/currency_utils.dart';

class PredefinedCategory {
  final String name;
  final int iconCodePoint;
  final int colorValue;

  /// Seed budget in WHOLE MAJOR UNITS of whatever currency the user picked —
  /// 500 means "500 of your currency", exactly as it did before C4.
  ///
  /// Presets are currency-agnostic, so they cannot be stored in minor units:
  /// the conversion happens where the currency is known
  /// (`CurrencyUtils.fromMajor(...)` at seed time and at preset prefill).
  ///
  /// Only a FALLBACK since UI-35: used when income is unknown (skipped or 0),
  /// because these figures are dollar-shaped and ₨200/month for transport made
  /// the first screen look broken to every non-USD user.
  final int defaultBudgetMajor;

  /// Share of monthly income this preset claims, in whole percent. The nine
  /// presets sum to 90, leaving 10% unallocated on purpose.
  final int incomeSharePercent;

  const PredefinedCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.defaultBudgetMajor,
    this.incomeSharePercent = 0,
  });

  /// This preset's seed limit, in MINOR UNITS of [currency], as a share of the
  /// income the user just entered ([incomeMinor], also minor units).
  ///
  /// Integer arithmetic throughout, and the rounding is DOWN to a step that
  /// reads like a budget rather than a calculator result — nearest 100 major
  /// units at 1000+, nearest 10 at 100+, whole units below that. Rounding down
  /// also keeps the nine seeds strictly under the 90% they add up to, so the
  /// seeded budgets can never exceed the stated income.
  ///
  /// Falls back to [defaultBudgetMajor] when there is no income to work from
  /// (or no share, i.e. [kOtherCategory]) — never a zero limit, which the
  /// progress bars and the over-budget flag both read as "no budget".
  ///
  /// Lives here, beside the seed data, rather than in `CurrencyUtils`: it is a
  /// product rule about presets, not a money primitive.
  int seedLimitMinor(int incomeMinor, Currency currency) {
    if (incomeMinor <= 0 || incomeSharePercent <= 0) {
      return CurrencyUtils.fromMajor(defaultBudgetMajor, currency);
    }
    // `parseAmount` caps input at 15 whole digits, so incomeMinor × 25 stays
    // inside a 64-bit int.
    final shareMinor = (incomeMinor * incomeSharePercent) ~/ 100;
    final shareMajor = shareMinor ~/ CurrencyUtils.minorPerMajor(currency);
    final step = shareMajor >= 1000
        ? 100
        : shareMajor >= 100
            ? 10
            : 1;
    final roundedMajor = (shareMajor ~/ step) * step;
    if (roundedMajor > 0) {
      return CurrencyUtils.fromMajor(roundedMajor, currency);
    }
    // An income too small for even one major unit of this share. Stay
    // proportional rather than resurrecting a currency-blind default, and
    // still never zero.
    return shareMinor > 0 ? shareMinor : 1;
  }
}

final List<PredefinedCategory> kPredefinedCategories = [
  PredefinedCategory(
    name: 'Food',
    iconCodePoint: Icons.restaurant.codePoint,
    colorValue: 0xFFE74C3C,
    defaultBudgetMajor: 500,
    incomeSharePercent: 15,
  ),
  PredefinedCategory(
    name: 'Transport',
    iconCodePoint: Icons.directions_car.codePoint,
    colorValue: 0xFF3498DB,
    defaultBudgetMajor: 200,
    incomeSharePercent: 10,
  ),
  PredefinedCategory(
    name: 'Housing',
    iconCodePoint: Icons.home.codePoint,
    colorValue: 0xFF1B4965,
    defaultBudgetMajor: 1200,
    incomeSharePercent: 25,
  ),
  PredefinedCategory(
    name: 'Utilities',
    iconCodePoint: Icons.bolt.codePoint,
    colorValue: 0xFFF39C12,
    defaultBudgetMajor: 150,
    incomeSharePercent: 8,
  ),
  PredefinedCategory(
    name: 'Entertainment',
    iconCodePoint: Icons.movie.codePoint,
    colorValue: 0xFF9B59B6,
    defaultBudgetMajor: 150,
    incomeSharePercent: 5,
  ),
  PredefinedCategory(
    name: 'Shopping',
    iconCodePoint: Icons.shopping_bag.codePoint,
    colorValue: 0xFFE91E63,
    defaultBudgetMajor: 300,
    incomeSharePercent: 7,
  ),
  PredefinedCategory(
    name: 'Health',
    iconCodePoint: Icons.local_hospital.codePoint,
    colorValue: 0xFF2ECC71,
    defaultBudgetMajor: 100,
    incomeSharePercent: 5,
  ),
  PredefinedCategory(
    name: 'Education',
    iconCodePoint: Icons.school.codePoint,
    colorValue: 0xFFE67E22,
    defaultBudgetMajor: 200,
    incomeSharePercent: 5,
  ),
  PredefinedCategory(
    name: 'Savings',
    iconCodePoint: Icons.savings.codePoint,
    colorValue: 0xFF1ABC9C,
    defaultBudgetMajor: 400,
    incomeSharePercent: 10,
  ),
];

/// Fallback "Other" category used when no category matches a transaction.
final PredefinedCategory kOtherCategory = PredefinedCategory(
  name: 'Other',
  iconCodePoint: Icons.more_horiz.codePoint,
  colorValue: 0xFF607D8B,
  defaultBudgetMajor: 0,
);
