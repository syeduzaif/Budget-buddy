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
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  DocumentReference? get currentUserDoc {
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference? get categoriesCollection => currentUserDoc?.collection('categories');
  CollectionReference? get expensesCollection => currentUserDoc?.collection('expenses');
  CollectionReference? get incomeCollection => currentUserDoc?.collection('income');
  CollectionReference? get chatCollection => currentUserDoc?.collection('ai_chat');
}
