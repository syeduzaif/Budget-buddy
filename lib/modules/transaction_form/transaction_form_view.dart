import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/category_icon.dart';
import '../../utils/date_utils.dart';
import '../../utils/validators.dart';
import 'transaction_form_controller.dart';

class TransactionFormView extends StatelessWidget {
  const TransactionFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TransactionFormController>();
    final formKey = GlobalKey<FormState>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ctrl.isEditing ? 'Edit Transaction' : 'Add Transaction',
                style: AppFonts.h5),
            const SizedBox(height: AppSpacing.l),

            // Amount
            TextFormField(
              controller: ctrl.amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppFonts.h3,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${ctrl.settings.currency.symbol} ',
                prefixStyle: AppFonts.h4.copyWith(color: AppColors.primary),
                // An always-floating label is what makes `prefixText` paint on
                // an empty field; the UI-17 hint that used to do this job
                // duplicated the symbol once focused ("₨ ₨0.00") — N1.
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              validator: Validators.amount(ctrl.settings.currency),
            ),
            const SizedBox(height: AppSpacing.m),

            // Note
            TextFormField(
              controller: ctrl.noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Category — uses InputDecorator + dialog instead of
            // DropdownButtonFormField to avoid its internal Navigator route
            // conflicting with the bottom sheet during dispose.
            Obx(() {
              final selected = ctrl.selectedCategory.value;
              return GestureDetector(
                onTap: () async {
                  final picked = await showDialog<dynamic>(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: const Text('Select Category'),
                      children: ctrl.categories.isEmpty
                          ? [
                              // Reachable: delete every category in every
                              // month and `ensureMonth` has nothing to clone
                              // from. The dialog was a title over blank space
                              // — a dead end on this app's rank-1 job — while
                              // the save path beneath it already handles the
                              // case correctly and says so. This says the same
                              // thing one step earlier (D-028).
                              //
                              // It names the month the LIST is built from
                              // (`ctrl.categories` is filtered to
                              // `settings.currentMonth`), not the date's — the
                              // sentence is about what is on screen. The
                              // second half stays true either way: with no
                              // pick, the save files into the reserved bucket
                              // of the transaction's own date-month (F-01).
                              //
                              // No "create one" affordance: this dialog cannot
                              // create a category, and copy must not invite an
                              // action the screen cannot honour.
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.xl,
                                    0,
                                    AppSpacing.xl,
                                    AppSpacing.m),
                                child: Text(
                                  'No categories in '
                                  '${AppDateUtils.formatMonthName(ctrl.settings.currentMonth.value)}. '
                                  'Saving will file this under '
                                  '$kUncategorisedCategoryName.',
                                  style: AppFonts.bodyMedium.copyWith(
                                      color: ctx.semanticColors.textMuted),
                                ),
                              ),
                            ]
                          : ctrl.categories
                              .map((cat) => SimpleDialogOption(
                                    onPressed: () => Navigator.pop(ctx, cat),
                                    child: Row(
                                      children: [
                                        CategoryIcon(category: cat, size: 24),
                                        const SizedBox(width: AppSpacing.s),
                                        Expanded(
                                          child: Text(cat.name,
                                              style: AppFonts.bodyMedium,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        // Says which one is already chosen — the
                                        // list gave no marker at all (UI-27).
                                        if (cat.id == selected?.id)
                                          Icon(Icons.check,
                                              size: AppSpacing.iconS,
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .primary),
                                      ],
                                    ),
                                  ))
                              .toList(),
                    ),
                  );
                  if (picked != null) ctrl.selectCategory(picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: selected != null
                      ? Row(
                          children: [
                            CategoryIcon(category: selected, size: 24),
                            const SizedBox(width: AppSpacing.xs),
                            Text(selected.name, style: AppFonts.bodyMedium),
                          ],
                        )
                      : Text('Select a category',
                          style: AppFonts.bodyMedium.copyWith(
                              color: context.semanticColors.textMuted)),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.m),

            // Date
            Obx(() => OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: ctrl.selectedDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) ctrl.selectDate(picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(AppDateUtils.formatDate(ctrl.selectedDate.value)),
                )),
            const SizedBox(height: AppSpacing.l),

            // Save
            Obx(() => FilledButton(
                  onPressed: ctrl.isLoading.value
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) ctrl.save();
                        },
                  child: ctrl.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      // "Save Changes" is the category form's word for the
                      // same act, and it says the record already exists.
                      : Text(
                          ctrl.isEditing ? 'Save Changes' : 'Save Transaction'),
                )),
          ],
        ),
      ),
    );
  }
}
