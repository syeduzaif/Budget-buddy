import 'package:get/get.dart';
import '../../services/firebase/firestore_service.dart';
import '../models/transaction_item.dart';

class TransactionRepository extends GetxService {
  final FirestoreService _fs = Get.find<FirestoreService>();

  Stream<List<TransactionItem>> getTransactions() {
    if (_fs.expensesCollection == null) return Stream.value([]);
    return _fs.expensesCollection!
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionItem.fromFirestore(doc))
            .toList());
  }

  Future<void> addTransaction(TransactionItem transaction) async {
    if (_fs.expensesCollection == null) return;
    await _fs.expensesCollection!.doc(transaction.id).set(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    if (_fs.expensesCollection == null) return;
    await _fs.expensesCollection!.doc(id).delete();
  }
}
