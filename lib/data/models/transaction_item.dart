import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory TransactionItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionItem(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      synced: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
