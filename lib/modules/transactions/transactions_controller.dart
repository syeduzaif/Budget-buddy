import 'package:flutter/foundation.dart' show debugPrint, immutable;
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

  /// What this screen says when it has nothing to list.
  EmptyListCopy get emptyCopy =>
      emptyCopyFor(categoryName: filterCategoryName, month: filterMonth);

  /// The empty-state words for a given scope — pure, like [titleFor], so all
  /// four combinations can be read (and tested) in one place.
  ///
  /// The copy this replaces was "Add your first transaction using the + button".
  /// There is no + button here: this is a pushed route, so the home tab bar —
  /// whose Add tab is the only door to the form — is off screen, and the list
  /// has no FAB either. An instruction to tap something that does not exist is
  /// worse than no instruction, so the second line describes what will happen
  /// instead of directing a gesture (BUG-021).
  ///
  /// Naming the scope is the other half: on a month-scoped list "No transactions
  /// yet" reads as "this app is empty" when the truth is only that this month is
  /// (F-04 AC-4, the same promise the title makes).
  static EmptyListCopy emptyCopyFor({String? categoryName, String? month}) {
    final monthLabel = month == null ? null : AppDateUtils.formatMonthKey(month);
    if (categoryName != null) {
      return EmptyListCopy(
        monthLabel == null
            ? 'Nothing logged in $categoryName'
            : 'Nothing logged in $categoryName for $monthLabel',
        'Expenses you add to $categoryName will appear here.',
      );
    }
    return EmptyListCopy(
      monthLabel == null
          ? 'Nothing logged yet'
          : 'Nothing logged in $monthLabel',
      'Expenses you add will appear here.',
    );
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

/// The two lines of an empty transactions list: the house empty-state pattern is
/// an icon, a title and one muted line beneath it.
@immutable
class EmptyListCopy {
  /// Names what is empty, and which scope is empty.
  final String title;

  /// What will fill it. Never an instruction to press something — see
  /// [TransactionsController.emptyCopyFor].
  final String line;

  const EmptyListCopy(this.title, this.line);
}
