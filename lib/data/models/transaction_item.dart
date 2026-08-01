import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

@HiveType(typeId: 1)
class TransactionItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryId;

  /// Amount in integer MINOR UNITS of the user's currency (cents for USD,
  /// whole yen for JPY). Never a `double`, never a major-unit number — see
  /// `utils/currency_utils.dart`.
  ///
  /// Field index 2 is unchanged from the pre-C4 `double amount`: the boxes
  /// have never existed on a real device, so this is a redefinition of an
  /// unused slot rather than a migration (`LocalStoreService` resets a box
  /// that still holds the old shape).
  @HiveField(2)
  late int amountMinor;

  @HiveField(3)
  late String note;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  /// Dormant cloud-sync hook. Nothing reads or writes it while the app is
  /// local-only; kept so re-introducing sync stays an additive change and the
  /// on-disk Hive layout does not have to shift.
  @HiveField(7)
  late bool synced;

  TransactionItem({
    required this.id,
    required this.categoryId,
    required this.amountMinor,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  /// The key is `amountMinor`, not `amount`: anything reading an exported file
  /// must be told the unit, or it will guess wrong.
  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amountMinor': amountMinor,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'synced': synced,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        categoryId: json['categoryId'],
        amountMinor: _minorUnits(json['amountMinor'], 'amountMinor'),
        note: json['note'],
        date: DateTime.parse(json['date']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.parse(json['createdAt']), // Fallback
        synced: json['synced'] ?? false,
      );
}

/// Guarded read of a money field (H2: no bare casts on untyped input).
///
/// Throws rather than defaulting: a JSON amount we cannot read is missing
/// money, and silently importing it as 0 would be worse than refusing.
int _minorUnits(Object? value, String field) {
  if (value is int) return value;
  throw FormatException(
      '$field must be an integer of minor units, got ${value.runtimeType}');
}
