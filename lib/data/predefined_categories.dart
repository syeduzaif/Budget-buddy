import 'package:flutter/material.dart';

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
  final int defaultBudgetMajor;

  const PredefinedCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.defaultBudgetMajor,
  });
}

final List<PredefinedCategory> kPredefinedCategories = [
  PredefinedCategory(
    name: 'Food',
    iconCodePoint: Icons.restaurant.codePoint,
    colorValue: 0xFFE74C3C,
    defaultBudgetMajor: 500,
  ),
  PredefinedCategory(
    name: 'Transport',
    iconCodePoint: Icons.directions_car.codePoint,
    colorValue: 0xFF3498DB,
    defaultBudgetMajor: 200,
  ),
  PredefinedCategory(
    name: 'Housing',
    iconCodePoint: Icons.home.codePoint,
    colorValue: 0xFF1B4965,
    defaultBudgetMajor: 1200,
  ),
  PredefinedCategory(
    name: 'Utilities',
    iconCodePoint: Icons.bolt.codePoint,
    colorValue: 0xFFF39C12,
    defaultBudgetMajor: 150,
  ),
  PredefinedCategory(
    name: 'Entertainment',
    iconCodePoint: Icons.movie.codePoint,
    colorValue: 0xFF9B59B6,
    defaultBudgetMajor: 150,
  ),
  PredefinedCategory(
    name: 'Shopping',
    iconCodePoint: Icons.shopping_bag.codePoint,
    colorValue: 0xFFE91E63,
    defaultBudgetMajor: 300,
  ),
  PredefinedCategory(
    name: 'Health',
    iconCodePoint: Icons.local_hospital.codePoint,
    colorValue: 0xFF2ECC71,
    defaultBudgetMajor: 100,
  ),
  PredefinedCategory(
    name: 'Education',
    iconCodePoint: Icons.school.codePoint,
    colorValue: 0xFFE67E22,
    defaultBudgetMajor: 200,
  ),
  PredefinedCategory(
    name: 'Savings',
    iconCodePoint: Icons.savings.codePoint,
    colorValue: 0xFF1ABC9C,
    defaultBudgetMajor: 400,
  ),
];

/// Fallback "Other" category used when no category matches a transaction.
final PredefinedCategory kOtherCategory = PredefinedCategory(
  name: 'Other',
  iconCodePoint: Icons.more_horiz.codePoint,
  colorValue: 0xFF607D8B,
  defaultBudgetMajor: 0,
);
