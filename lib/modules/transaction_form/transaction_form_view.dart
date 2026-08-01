import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
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
            Text('Add Transaction', style: AppFonts.h5),
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
                prefixText: '${ctrl.settings.currencySymbol.value} ',
                prefixStyle: AppFonts.h4.copyWith(color: AppColors.primary),
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
                      children: ctrl.categories
                          .map((cat) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, cat),
                                child: Row(
                                  children: [
                                    CategoryIcon(category: cat, size: 24),
                                    const SizedBox(width: AppSpacing.s),
                                    Text(cat.name, style: AppFonts.bodyMedium),
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
                          style: AppFonts.bodyMedium
                              .copyWith(color: AppColors.textMuted)),
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
                      : const Text('Save Transaction'),
                )),
          ],
        ),
      ),
    );
  }
}
