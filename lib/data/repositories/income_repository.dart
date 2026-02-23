import 'package:get/get.dart';
import '../../services/firebase/firestore_service.dart';
import '../models/income_model.dart';

class IncomeRepository extends GetxService {
  final FirestoreService _fs = Get.find<FirestoreService>();

  Stream<List<IncomeModel>> getIncomes() {
    if (_fs.incomeCollection == null) return Stream.value([]);
    return _fs.incomeCollection!
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => IncomeModel.fromFirestore(doc)).toList());
  }

  Future<void> addIncome(IncomeModel income) async {
    if (_fs.incomeCollection == null) return;
    await _fs.incomeCollection!.doc(income.id).set(income.toFirestore());
  }

  Future<void> deleteIncome(String id) async {
    if (_fs.incomeCollection == null) return;
    await _fs.incomeCollection!.doc(id).delete();
  }
}
