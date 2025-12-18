import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  Stream<List<ChatMessageModel>> getMessages() {
    if (_firestoreService.chatCollection == null) return Stream.value([]);
    return _firestoreService.chatCollection!
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addMessage(ChatMessageModel message) async {
    if (_firestoreService.chatCollection == null) return;
    await _firestoreService.chatCollection!
        .doc(message.id)
        .set(message.toFirestore());
  }

  Future<void> deleteMessage(String id) async {
    if (_firestoreService.chatCollection == null) return;
    await _firestoreService.chatCollection!.doc(id).delete();
  }
}
