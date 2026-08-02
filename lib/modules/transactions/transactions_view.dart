import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/app/settings_service.dart';
import '../transaction_form/transaction_form_sheet.dart';
import 'transactions_controller.dart';
import 'widgets/transaction_tile.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TransactionsController(
      transactionRepo: Get.find<TransactionRepository>(),
      categoryRepo: Get.find<CategoryRepository>(),
    ));
    final settings = Get.find<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        // Names both scopes it is under, so the list can never look like it
        // holds more than it does (F-04 AC-4).
        title: Text(ctrl.screenTitle, style: AppFonts.h6),
      ),
      body: Obx(() {
        final grouped = ctrl.groupedByDate;
        final currency = settings.currency;

        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: context.semanticColors.textMuted),
                const SizedBox(height: AppSpacing.m),
                Text('No transactions yet', style: AppFonts.h6),
                const SizedBox(height: AppSpacing.s),
                Text('Add your first transaction using the + button',
                    style: AppFonts.bodySmall
                        .copyWith(color: context.semanticColors.textMuted)),
              ],
            ),
          );
        }

        final dateKeys = grouped.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: dateKeys.length,
          itemBuilder: (_, i) {
            final dateKey = dateKeys[i];
            final items = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(dateKey,
                      style: AppFonts.labelMedium
                          .copyWith(color: context.semanticColors.textMuted)),
                ),
                ...items.map((t) {
                  Category? cat;
                  try {
                    cat = ctrl.categories
                        .firstWhere((c) => c.id == t.categoryId);
                  } catch (_) {}
                  return TransactionTile(
                    transaction: t,
                    category: cat,
                    currency: currency,
                    // Only worth naming when the screen is not already about
                    // one category (UI-04).
                    showCategory: ctrl.filterCategoryName == null,
                    onDelete: () => ctrl.deleteTransaction(t.id),
                    // The row is the transaction: tapping it opens it (F-07).
                    onTap: () => openTransactionSheet(context, editing: t),
                  );
                }),
              ],
            );
          },
        );
      }),
    );
  }
}
