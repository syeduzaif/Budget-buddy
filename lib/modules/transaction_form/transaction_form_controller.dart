import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';

class TransactionFormController extends GetxController {
  final CategoryRepository categoryRepo;
  final TransactionRepository transactionRepo;
  final SettingsService settings;

  TransactionFormController({
    required this.categoryRepo,
    required this.transactionRepo,
    required this.settings,
  });

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();
  final selectedDate = DateTime.now().obs;
  final isLoading = false.obs;

  // If opened from a category view, pre-select it
  String? preselectedCategoryId;

  /// The date a newly opened sheet starts on, for a user viewing [viewedMonth].
  ///
  /// Viewing the current month (or, defensively, a future one — the month
  /// chevron itself is unbounded) keeps today. Viewing a PAST month starts on
  /// the 1st of that month: the old unconditional `DateTime.now()` meant
  /// browsing to July and tapping Add silently filed the expense in August,
  /// against August's category clone (F-01 path A′). Month keys are
  /// zero-padded `YYYY-MM`, so comparing them as strings is chronological.
  static DateTime defaultDateForMonth(String viewedMonth, DateTime now) {
    if (viewedMonth.compareTo(AppDateUtils.getMonthKeyFromDate(now)) >= 0) {
      return now;
    }
    return AppDateUtils.parseMonthKey(viewedMonth) ?? now;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    preselectedCategoryId = args?['categoryId'];
    selectedDate.value =
        defaultDateForMonth(settings.effectiveMonth, DateTime.now());

    categoryRepo.getCategories().listen(
      (list) {
        final filtered =
            list.where((c) => c.month == settings.currentMonth.value).toList();
        categories.assignAll(filtered);
        if (selectedCategory.value == null && filtered.isNotEmpty) {
          if (preselectedCategoryId != null) {
            try {
              selectedCategory.value =
                  filtered.firstWhere((c) => c.id == preselectedCategoryId);
            } catch (_) {
              selectedCategory.value = filtered.first;
            }
          } else {
            selectedCategory.value = filtered.first;
          }
        }
      },
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last
        // good snapshot, so this should never fire — but every listener
        // carries onError so a future failing source cannot kill the
        // stream silently (H2).
        debugPrint('[TransactionFormController] category stream failed: $e\n$s');
      },
    );
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void selectDate(DateTime date) => selectedDate.value = date;
  void selectCategory(Category cat) => selectedCategory.value = cat;

  Future<void> save() async {
    // Text → minor units directly. No double.parse, no multiply by 100: the
    // currency's own exponent decides the scale (C4).
    final amountMinor = CurrencyUtils.tryParseToMinor(
        amountController.text, settings.currency);
    if (amountMinor == null || amountMinor <= 0) return;

    isLoading.value = true;
    CategoryResolution resolution;
    try {
      // Attribution follows the transaction's DATE-month, never the month the
      // user happens to be viewing, and the repository is the only place that
      // decides it (F-01). A null pick lands in that month's reserved bucket.
      resolution = await categoryRepo.resolveForMonth(
        selectedCategory.value,
        AppDateUtils.getMonthKeyFromDate(selectedDate.value),
      );

      final transaction = TransactionItem(
        id: const Uuid().v4(),
        categoryId: resolution.category.id,
        amountMinor: amountMinor,
        note: noteController.text.trim(),
        date: selectedDate.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await transactionRepo.addTransaction(transaction);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, so a failure is never reported as a success (H3).
      debugPrint('[TransactionFormController] save failed: $e\n$stack');
      Get.snackbar(
        'Could not save transaction',
        'Nothing was saved. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      isLoading.value = false;
    }
    // The sheet closes only once the write is known to have landed —
    // dismissing it first would report a success that never happened.
    Get.back();

    if (resolution.pickedWasDeleted) {
      // The category was deleted while this sheet was open. The amount is
      // saved and visible, but not where the user aimed it — say so rather
      // than resurrecting a category they deleted.
      Get.snackbar(
        'Saved to $kUncategorisedCategoryName',
        'That category was deleted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
