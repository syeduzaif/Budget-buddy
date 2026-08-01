import 'package:get/get.dart';
import '../../services/local/local_store_service.dart';
import '../models/category.dart';

class CategoryRepository extends GetxService {
  final LocalStoreService _store = Get.find<LocalStoreService>();

  /// Live list of every category, newest first.
  Stream<List<Category>> getCategories() => _store.watchCategories();

  Future<void> addCategory(Category category) => _store.putCategory(category);

  Future<void> addCategories(List<Category> categories) =>
      _store.putCategories(categories);

  Future<void> updateCategory(Category category) =>
      _store.putCategory(category);

  Future<void> deleteCategory(String id) => _store.deleteCategory(id);

  /// Removes every category. Used by the "erase all data" flow.
  Future<void> deleteAll() => _store.clearCategories();

  /// One-shot fetch of categories for a specific month key (e.g. "2026-03").
  Future<List<Category>> getCategoriesForMonth(String month) async =>
      _store.readCategoriesForMonth(month);
}
