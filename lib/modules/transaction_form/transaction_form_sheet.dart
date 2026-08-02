import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import 'transaction_form_controller.dart';
import 'transaction_form_view.dart';

/// Opens the transaction form. The ONE way, from anywhere.
///
/// The form is a modal bottom sheet, not a route — `AppRoutes.transactionForm`
/// is a constant that was never registered in `AppPages`, so there is nothing
/// to `Get.toNamed`. Until now the only way to show it was a private method on
/// `HomeView`, which is why the Add tab was the only door in the building
/// (F-07). Every entry point now calls this: the Add tab, a Recent row, a row
/// in any transactions list.
///
/// [editing] switches the sheet into edit mode — same record, prefilled, saved
/// back over itself. [preselectedCategoryId] is for category-scoped entry
/// points; it is ignored in edit mode, where the transaction's own category is
/// the only sensible starting point.
///
/// Returns when the sheet closes, so a caller that wants to do something
/// afterwards can await it. Nothing is returned through it: the store is the
/// channel, and every list on screen is already watching it.
Future<void> openTransactionSheet(
  BuildContext context, {
  TransactionItem? editing,
  String? preselectedCategoryId,
}) {
  // Delete-then-put, never a bare put over an existing registration: the
  // controller owns two TextEditingControllers and a form's worth of state, so
  // a reused instance would open "Add Transaction" still holding the last
  // edit's amount — and the old instance's `onClose` would never run to
  // dispose those controllers.
  if (Get.isRegistered<TransactionFormController>()) {
    Get.delete<TransactionFormController>();
  }
  Get.put(TransactionFormController(
    categoryRepo: Get.find<CategoryRepository>(),
    transactionRepo: Get.find<TransactionRepository>(),
    settings: Get.find<SettingsService>(),
    editing: editing,
    preselectedCategoryId: preselectedCategoryId,
  ));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const TransactionFormView(),
  );
}
