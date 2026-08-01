import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/utils/app_icons.dart';
import 'transaction_item.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  /// Budget ceiling in integer MINOR UNITS of the user's currency (cents for
  /// USD, whole yen for JPY) — see `utils/currency_utils.dart`.
  ///
  /// Field index 2 is unchanged from the pre-C4 `double budgetLimit`: the
  /// boxes have never existed on a real device, so this redefines an unused
  /// slot rather than migrating one (`LocalStoreService` resets a box that
  /// still holds the old shape).
  @HiveField(2)
  late int budgetLimitMinor;

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
    required this.budgetLimitMinor,
    required this.colorValue,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
    this.iconCodePoint,
  });

  IconData get icon => AppIcons.fromCodePoint(iconCodePoint);

  /// Total spent against this category, in minor units. Typed input, integer
  /// arithmetic — no `dynamic`, no float accumulator.
  int calculateTotalSpentMinor(Iterable<TransactionItem> allTransactions) =>
      allTransactions
          .where((t) => t.categoryId == id)
          .fold(0, (total, t) => total + t.amountMinor);

  int calculateRemainingMinor(int spentMinor) => budgetLimitMinor - spentMinor;

  /// Percentage of the budget used. A ratio, not money: `int / int` is a
  /// `double` in Dart, so this needs no conversion.
  double calculatePercentage(int spentMinor) {
    if (budgetLimitMinor == 0) return 0;
    return (spentMinor / budgetLimitMinor) * 100;
  }

  /// The key is `budgetLimitMinor`, not `budgetLimit`: anything reading an
  /// exported file must be told the unit, or it will guess wrong.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budgetLimitMinor': budgetLimitMinor,
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
        budgetLimitMinor:
            _minorUnits(json['budgetLimitMinor'], 'budgetLimitMinor'),
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

/// Guarded read of a money field (H2: no bare casts on untyped input).
///
/// Throws rather than defaulting: a JSON budget we cannot read is missing
/// money, and silently importing it as 0 would be worse than refusing.
int _minorUnits(Object? value, String field) {
  if (value is int) return value;
  throw FormatException(
      '$field must be an integer of minor units, got ${value.runtimeType}');
}
