import 'package:get/get.dart';
import '../../services/local/local_store_service.dart';
import '../models/transaction_item.dart';

class TransactionRepository extends GetxService {
  final LocalStoreService _store = Get.find<LocalStoreService>();

  /// Live list of every transaction, newest first by transaction date.
  Stream<List<TransactionItem>> getTransactions() => _store.watchTransactions();

  Future<void> addTransaction(TransactionItem transaction) =>
      _store.putTransaction(transaction);

  Future<void> deleteTransaction(String id) => _store.deleteTransaction(id);

  /// Removes every transaction. Used by the "erase all data" flow.
  Future<void> deleteAll() => _store.clearTransactions();
}
