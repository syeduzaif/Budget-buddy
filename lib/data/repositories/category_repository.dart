import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../models/category.dart';

class CategoryRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  Stream<List<Category>> getCategories() {
    if (_firestoreService.categoriesCollection == null) return Stream.value([]);
    return _firestoreService.categoriesCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> addCategory(Category category) async {
    if (_firestoreService.categoriesCollection == null) return;
    await _firestoreService.categoriesCollection!
        .doc(category.id)
        .set(category.toFirestore());
  }

  Future<void> updateCategory(Category category) async {
    if (_firestoreService.categoriesCollection == null) return;
    await _firestoreService.categoriesCollection!
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    if (_firestoreService.categoriesCollection == null) return;
    await _firestoreService.categoriesCollection!.doc(id).delete();
  }
}
