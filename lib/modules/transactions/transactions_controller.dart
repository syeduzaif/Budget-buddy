import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import '../../data/models/transaction_item.dart';
import '../../data/models/category.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../utils/date_utils.dart';

class TransactionsController extends GetxController {
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;

  TransactionsController({
    required this.transactionRepo,
    required this.categoryRepo,
  });

  final transactions = <TransactionItem>[].obs;
  final categories = <Category>[].obs;
  String? filterCategoryId;
  String? filterCategoryName;

  List<TransactionItem> get filtered {
    var list = transactions.toList();
    if (filterCategoryId != null) {
      list = list.where((t) => t.categoryId == filterCategoryId).toList();
    }
    return list;
  }

  Map<String, List<TransactionItem>> get groupedByDate {
    final map = <String, List<TransactionItem>>{};
    for (final t in filtered) {
      final key = AppDateUtils.formatDate(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  String categoryName(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    filterCategoryId = args?['categoryId'];
    filterCategoryName = args?['categoryName'];

    transactionRepo.getTransactions().listen(
      (list) => transactions.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[TransactionsController] transaction stream failed: $e\n$s');
      },
    );
    categoryRepo.getCategories().listen(
      (list) => categories.assignAll(list),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[TransactionsController] category stream failed: $e\n$s');
      },
    );
  }

  Future<void> deleteTransaction(String id) async {
    await transactionRepo.deleteTransaction(id);
  }
}
