import 'dart:async';

// `show debugPrint` only: foundation also exports a `Category` annotation,
// which would collide with our model.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';

/// On-device store for the app's financial data.
///
/// Owns the two Hive boxes that replace the former Firestore collections.
/// Repositories are the only callers — controllers and views must go through
/// `data/repositories/*` (view → controller → repository → service).
///
/// Records are keyed by the model's own `id` (a client-minted `Uuid().v4()`),
/// so a `put` of an existing id is an in-place update.
///
/// Invariant worth keeping: a record's key is always its own `id`. The models
/// extend `HiveObject`, and Hive throws if one instance is ever stored under
/// two different keys — so callers must build a fresh model when they change
/// an `id`, never re-key an instance that came out of a box.
class LocalStoreService extends GetxService {
  static const String categoriesBoxName = 'categories';
  static const String transactionsBoxName = 'transactions';

  late final Box<Category> _categories;
  late final Box<TransactionItem> _transactions;

  /// Opens both boxes. Call once at startup, before any repository is used.
  /// Hive adapters must already be registered (see `HiveStorage.init`).
  Future<LocalStoreService> init() async {
    _categories = await Hive.openBox<Category>(categoriesBoxName);
    _transactions = await Hive.openBox<TransactionItem>(transactionsBoxName);
    return this;
  }

  // --- Categories -----------------------------------------------------------

  /// Newest first, matching the ordering the Firestore query used to provide.
  List<Category> readCategories() {
    final list = _categories.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<Category>> watchCategories() =>
      _watch(_categories, readCategories, categoriesBoxName);

  Future<void> putCategory(Category category) =>
      _categories.put(category.id, category);

  Future<void> putCategories(List<Category> categories) =>
      _categories.putAll({for (final c in categories) c.id: c});

  Future<void> deleteCategory(String id) => _categories.delete(id);

  Future<void> clearCategories() => _categories.clear();

  List<Category> readCategoriesForMonth(String month) =>
      readCategories().where((c) => c.month == month).toList();

  // --- Transactions ---------------------------------------------------------

  /// Newest first by transaction date, matching the former Firestore ordering.
  List<TransactionItem> readTransactions() {
    final list = _transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Stream<List<TransactionItem>> watchTransactions() =>
      _watch(_transactions, readTransactions, transactionsBoxName);

  Future<void> putTransaction(TransactionItem transaction) =>
      _transactions.put(transaction.id, transaction);

  Future<void> deleteTransaction(String id) => _transactions.delete(id);

  Future<void> clearTransactions() => _transactions.clear();

  // --- Internals ------------------------------------------------------------

  /// Emits the current contents immediately, then again after every box
  /// mutation.
  ///
  /// Read failures are logged and the last good snapshot is re-emitted instead
  /// of an error: one bad record must never tear down a live screen. This is
  /// the local-store equivalent of the H2 rule that every Firestore listener
  /// carries `onError` — here the stream simply cannot fail, so no consumer is
  /// forced to handle one.
  ///
  /// One stream per call, and cancelling it releases the underlying box
  /// subscription.
  Stream<List<T>> _watch<T>(
    Box<T> box,
    List<T> Function() read,
    String label,
  ) {
    var lastGood = <T>[];

    List<T> safeRead() {
      try {
        lastGood = read();
      } catch (e, s) {
        debugPrint('[LocalStoreService] read failed for "$label": $e\n$s');
      }
      return lastGood;
    }

    late final StreamController<List<T>> controller;
    StreamSubscription<BoxEvent>? subscription;

    controller = StreamController<List<T>>(
      onListen: () {
        // Subscribe before the first read so no mutation can slip through the
        // gap between them.
        subscription = box.watch().listen(
          (_) => controller.add(safeRead()),
          onError: (Object e, StackTrace s) {
            debugPrint('[LocalStoreService] watch failed for "$label": $e\n$s');
          },
        );
        controller.add(safeRead());
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
      },
    );

    return controller.stream;
  }
}
