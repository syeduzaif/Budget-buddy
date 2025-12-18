import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 7)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  bool isUser;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  DateTime? updatedAt;

  @HiveField(5)
  bool synced;

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.updatedAt,
    this.synced = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      message: data['message'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['createdAt'] as Timestamp)
          .toDate(), // Mapping createdAt to timestamp
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      synced: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'isUser': isUser,
      'createdAt':
          Timestamp.fromDate(timestamp), // Mapping timestamp to createdAt
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
