import 'package:get/get.dart';
import '../../services/firebase/firestore_service.dart';
import '../models/chat_message_model.dart';

class ChatRepository extends GetxService {
  final FirestoreService _fs = Get.find<FirestoreService>();

  Stream<List<ChatMessageModel>> getMessages() {
    if (_fs.chatCollection == null) return Stream.value([]);
    return _fs.chatCollection!
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList());
  }

  Future<void> addMessage(ChatMessageModel message) async {
    if (_fs.chatCollection == null) return;
    await _fs.chatCollection!.doc(message.id).set(message.toFirestore());
  }

  Future<void> deleteAllMessages() async {
    if (_fs.chatCollection == null) return;
    final snap = await _fs.chatCollection!.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
