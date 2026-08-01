import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

@HiveType(typeId: 1)
class TransactionItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryId;

  @HiveField(2)
  late double amount;

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
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
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
        amount: json['amount'],
        note: json['note'],
        date: DateTime.parse(json['date']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.parse(json['createdAt']), // Fallback
        synced: json['synced'] ?? false,
      );
}
