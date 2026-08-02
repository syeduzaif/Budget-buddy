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

  /// The month this screen is scoped to, `"YYYY-MM"`, or null for all time.
  ///
  /// Every dashboard entrance passes one: the number a user taps is
  /// month-scoped, so the list it opens has to be as well, or the two disagree
  /// in front of them (F-04). All-time remains reachable only by a caller that
  /// deliberately asks for it.
  String? filterMonth;

  List<TransactionItem> get filtered {
    var list = transactions.toList();
    if (filterCategoryId != null) {
      list = list.where((t) => t.categoryId == filterCategoryId).toList();
    }
    final month = filterMonth;
    if (month != null) {
      list = list
          .where((t) => AppDateUtils.getMonthKeyFromDate(t.date) == month)
          .toList();
    }
    return list;
  }

  /// What the app bar says.
  String get screenTitle =>
      titleFor(categoryName: filterCategoryName, month: filterMonth);

  /// The title for a given scope — pure, so the four combinations can be read
  /// (and tested) in one place.
  ///
  /// `Health · August 2026` when both narrow the list, either alone when only
  /// one does, and the old all-time wording when neither does (RULING-C).
  static String titleFor({String? categoryName, String? month}) {
    final monthLabel = month == null ? null : AppDateUtils.formatMonthKey(month);
    if (categoryName != null && monthLabel != null) {
      return '$categoryName · $monthLabel';
    }
    return categoryName ?? monthLabel ?? 'All Transactions';
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
    filterMonth = args?['month'];

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
    try {
      await transactionRepo.deleteTransaction(id);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, so a failure is never reported as a success (H3).
      debugPrint('[TransactionsController] delete failed: $e\n$stack');
      // The tile has already been swiped away; say plainly that the data has
      // not, rather than letting the gesture imply a delete that failed.
      Get.snackbar(
        'Could not delete transaction',
        'It is still saved — reopen this screen to see it.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
