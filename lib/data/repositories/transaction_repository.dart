import 'package:get/get.dart';
import '../../services/local/local_store_service.dart';
import '../models/transaction_item.dart';

class TransactionRepository extends GetxService {
  final LocalStoreService _store = Get.find<LocalStoreService>();

  /// Live list of every transaction, newest first by transaction date.
  Stream<List<TransactionItem>> getTransactions() => _store.watchTransactions();

  Future<void> addTransaction(TransactionItem transaction) =>
      _store.putTransaction(transaction);

  /// Saves an edited transaction.
  ///
  /// The same box write as [addTransaction] — records are keyed by their own
  /// `id`, so a put IS the atomic upsert — but named for the caller's intent,
  /// so an edit screen never has to read as if it were adding a second record
  /// (F-07). Pass a FRESH instance rather than a mutated one that came out of
  /// a box.
  Future<void> updateTransaction(TransactionItem transaction) =>
      _store.putTransaction(transaction);

  /// One-shot read of every transaction, newest first by date.
  ///
  /// For callers that need the data once rather than a live view — the CSV
  /// export, which must not hold a subscription open to write a file.
  Future<List<TransactionItem>> getAllTransactions() async =>
      _store.readTransactions();

  Future<void> deleteTransaction(String id) => _store.deleteTransaction(id);

  /// Removes every transaction. Used by the "erase all data" flow.
  Future<void> deleteAll() => _store.clearTransactions();
}
