import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../models/income_model.dart';

class IncomeRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  Stream<List<IncomeModel>> getIncomes() {
    if (_firestoreService.incomeCollection == null) return Stream.value([]);
    return _firestoreService.incomeCollection!
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncomeModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addIncome(IncomeModel income) async {
    if (_firestoreService.incomeCollection == null) return;
    await _firestoreService.incomeCollection!
        .doc(income.id)
        .set(income.toFirestore());
  }

  Future<void> updateIncome(IncomeModel income) async {
    if (_firestoreService.incomeCollection == null) return;
    await _firestoreService.incomeCollection!
        .doc(income.id)
        .update(income.toFirestore());
  }

  Future<void> deleteIncome(String id) async {
    if (_firestoreService.incomeCollection == null) return;
    await _firestoreService.incomeCollection!.doc(id).delete();
  }
}
