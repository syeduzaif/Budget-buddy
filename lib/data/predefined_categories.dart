import 'package:flutter/material.dart';

class PredefinedCategory {
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final double defaultBudget;

  const PredefinedCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.defaultBudget,
  });
}

final List<PredefinedCategory> kPredefinedCategories = [
  PredefinedCategory(
    name: 'Food',
    iconCodePoint: Icons.restaurant.codePoint,
    colorValue: 0xFFE74C3C,
    defaultBudget: 500.0,
  ),
  PredefinedCategory(
    name: 'Transport',
    iconCodePoint: Icons.directions_car.codePoint,
    colorValue: 0xFF3498DB,
    defaultBudget: 200.0,
  ),
  PredefinedCategory(
    name: 'Housing',
    iconCodePoint: Icons.home.codePoint,
    colorValue: 0xFF1B4965,
    defaultBudget: 1200.0,
  ),
  PredefinedCategory(
    name: 'Utilities',
    iconCodePoint: Icons.bolt.codePoint,
    colorValue: 0xFFF39C12,
    defaultBudget: 150.0,
  ),
  PredefinedCategory(
    name: 'Entertainment',
    iconCodePoint: Icons.movie.codePoint,
    colorValue: 0xFF9B59B6,
    defaultBudget: 150.0,
  ),
  PredefinedCategory(
    name: 'Shopping',
    iconCodePoint: Icons.shopping_bag.codePoint,
    colorValue: 0xFFE91E63,
    defaultBudget: 300.0,
  ),
  PredefinedCategory(
    name: 'Health',
    iconCodePoint: Icons.local_hospital.codePoint,
    colorValue: 0xFF2ECC71,
    defaultBudget: 100.0,
  ),
  PredefinedCategory(
    name: 'Education',
    iconCodePoint: Icons.school.codePoint,
    colorValue: 0xFFE67E22,
    defaultBudget: 200.0,
  ),
  PredefinedCategory(
    name: 'Savings',
    iconCodePoint: Icons.savings.codePoint,
    colorValue: 0xFF1ABC9C,
    defaultBudget: 400.0,
  ),
];

/// Fallback "Other" category used when no category matches a transaction.
final PredefinedCategory kOtherCategory = PredefinedCategory(
  name: 'Other',
  iconCodePoint: Icons.more_horiz.codePoint,
  colorValue: 0xFF607D8B,
  defaultBudget: 0.0,
);
