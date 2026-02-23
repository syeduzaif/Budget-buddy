import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Add Transaction', style: AppFonts.h5),
            const SizedBox(height: AppSpacing.l),

            // Amount
            TextFormField(
              controller: ctrl.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppFonts.h3,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${ctrl.settings.currencySymbol.value} ',
                prefixStyle: AppFonts.h4.copyWith(color: AppColors.primary),
              ),
              validator: Validators.amount,
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

            // Category
            Obx(() => DropdownButtonFormField(
                  value: ctrl.selectedCategory.value,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ctrl.categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(cat.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(cat.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (cat) {
                    if (cat != null) ctrl.selectCategory(cat);
                  },
                )),
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
