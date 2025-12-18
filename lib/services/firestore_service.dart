import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // --- Collection References ---

  DocumentReference? get currentUserDoc {
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference? get incomeCollection =>
      currentUserDoc?.collection('income');
  CollectionReference? get categoriesCollection =>
      currentUserDoc?.collection('categories');
  CollectionReference? get expensesCollection =>
      currentUserDoc?.collection('expenses');
  CollectionReference? get chatCollection =>
      currentUserDoc?.collection('ai_chat');

  // --- Helper Methods ---

  // Check if a document has pending writes (local changes not yet synced)
  bool hasPendingWrites(DocumentSnapshot doc) {
    return doc.metadata.hasPendingWrites;
  }
}
