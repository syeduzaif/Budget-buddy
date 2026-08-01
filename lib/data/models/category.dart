import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/utils/app_icons.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double budgetLimit;

  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late String month; // Format: "YYYY-MM"

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  /// Dormant cloud-sync hook. Nothing reads or writes it while the app is
  /// local-only; kept so re-introducing sync stays an additive change and the
  /// on-disk Hive layout does not have to shift.
  @HiveField(7)
  late bool synced;

  @HiveField(8)
  int? iconCodePoint;

  Category({
    required this.id,
    required this.name,
    required this.budgetLimit,
    required this.colorValue,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
    this.iconCodePoint,
  });

  IconData get icon => AppIcons.fromCodePoint(iconCodePoint);

  // Calculate total spent from transactions
  double calculateTotalSpent(List<dynamic> allTransactions) {
    final categoryTransactions =
        allTransactions.where((t) => t.categoryId == id).toList();

    return categoryTransactions.fold(
      0.0,
      (total, transaction) => total + transaction.amount,
    );
  }

  double calculateRemaining(double spent) {
    return budgetLimit - spent;
  }

  double calculatePercentage(double spent) {
    if (budgetLimit == 0) return 0;
    return (spent / budgetLimit) * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budgetLimit': budgetLimit,
        'colorValue': colorValue,
        'month': month,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'synced': synced,
        'iconCodePoint': iconCodePoint,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        budgetLimit: json['budgetLimit'],
        colorValue: json['colorValue'],
        month: json['month'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.parse(json['createdAt']),
        synced: json['synced'] ?? false,
        iconCodePoint: json['iconCodePoint'] as int?,
      );
}
