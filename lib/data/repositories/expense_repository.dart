import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../models/transaction_item.dart';

class ExpenseRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  Stream<List<TransactionItem>> getExpenses() {
    if (_firestoreService.expensesCollection == null) return Stream.value([]);
    return _firestoreService.expensesCollection!
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionItem.fromFirestore(doc))
            .toList());
  }

  Future<void> addExpense(TransactionItem expense) async {
    if (_firestoreService.expensesCollection == null) return;
    await _firestoreService.expensesCollection!
        .doc(expense.id)
        .set(expense.toFirestore());
  }

  Future<void> updateExpense(TransactionItem expense) async {
    if (_firestoreService.expensesCollection == null) return;
    await _firestoreService.expensesCollection!
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    if (_firestoreService.expensesCollection == null) return;
    await _firestoreService.expensesCollection!.doc(id).delete();
  }
}
