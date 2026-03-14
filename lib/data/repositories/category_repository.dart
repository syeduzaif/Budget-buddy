import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/firebase/firestore_service.dart';
import '../models/category.dart';

class CategoryRepository extends GetxService {
  final FirestoreService _fs = Get.find<FirestoreService>();

  Stream<List<Category>> getCategories() {
    if (_fs.categoriesCollection == null) return Stream.value([]);
    return _fs.categoriesCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Category.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> addCategory(Category category) async {
    if (_fs.categoriesCollection == null) return;
    await _fs.categoriesCollection!
        .doc(category.id)
        .set(category.toFirestore());
  }

  Future<void> addCategories(List<Category> categories) async {
    if (_fs.categoriesCollection == null) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final cat in categories) {
      batch.set(_fs.categoriesCollection!.doc(cat.id), cat.toFirestore());
    }
    await batch.commit();
  }

  Future<void> updateCategory(Category category) async {
    if (_fs.categoriesCollection == null) return;
    await _fs.categoriesCollection!
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    if (_fs.categoriesCollection == null) return;
    await _fs.categoriesCollection!.doc(id).delete();
  }

  /// One-shot fetch of categories for a specific month key (e.g. "2026-03").
  Future<List<Category>> getCategoriesForMonth(String month) async {
    if (_fs.categoriesCollection == null) return [];
    final snap =
        await _fs.categoriesCollection!.where('month', isEqualTo: month).get();
    return snap.docs
        .map((doc) => Category.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }
}
