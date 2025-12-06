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

  TransactionItem({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        categoryId: json['categoryId'],
        amount: json['amount'],
        note: json['note'],
        date: DateTime.parse(json['date']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
