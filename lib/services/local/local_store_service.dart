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
    _categories = await _openOrReset<Category>(categoriesBoxName);
    _transactions = await _openOrReset<TransactionItem>(transactionsBoxName);
    return this;
  }

  /// Opens a box; if it cannot be read, deletes it from disk and opens a fresh
  /// one rather than crashing at startup.
  ///
  /// The case this exists for: the C4 money migration redefined field 2 of
  /// both models from `double` to `int` minor units, so a box written by a
  /// pre-C4 build fails its adapter's type check the moment it is opened. That
  /// can only happen on a developer's device — these boxes have never shipped
  /// (the app was still on Firestore) — so wiping is the honest, simple
  /// answer.
  ///
  /// PRE-RELEASE ONLY. The first real install ends this: from then on a
  /// schema change needs a versioned migration, because this method would
  /// silently delete someone's records. Revisit before shipping to Play.
  ///
  /// Expect a second, redundant stack trace in the log when this fires: Hive
  /// also completes an internal completer with the same error and nothing
  /// listens to it (`hive_impl.dart:116`), so it surfaces as an unhandled
  /// async error. Startup still succeeds — see
  /// `test/local_store_migration_test.dart`.
  Future<Box<T>> _openOrReset<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e, s) {
      debugPrint('[LocalStoreService] could not open "$name" ($e)\n$s');
      debugPrint('[LocalStoreService] resetting "$name" — pre-release only');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (deleteError) {
        // Hive's own cleanup after a failed open is not awaited, so it races
        // this delete and can report the lock file already gone
        // (PathNotFoundException) even though the data file was removed.
        // Reopening is the honest verdict — if the box is really still
        // unreadable, the retry below throws and startup fails loudly.
        debugPrint('[LocalStoreService] delete of "$name" reported: '
            '$deleteError (continuing)');
      }
      return Hive.openBox<T>(name);
    }
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
