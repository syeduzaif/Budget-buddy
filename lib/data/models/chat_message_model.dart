import 'package:hive/hive.dart';

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

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}
