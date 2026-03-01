import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/validators.dart';
import 'category_form_controller.dart';

class CategoryFormView extends StatelessWidget {
  const CategoryFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CategoryFormController(
      categoryRepo: Get.find<CategoryRepository>(),
      settings: Get.find<SettingsService>(),
    ));
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(ctrl.isEditing ? 'Edit Category' : 'New Category',
            style: AppFonts.h6),
        actions: [
          if (ctrl.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Category'),
                    content: const Text(
                        'Delete this category? Transactions will not be deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) ctrl.delete();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: ctrl.nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: Validators.categoryName,
              ),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: ctrl.budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Budget Limit',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Pick an Icon', style: AppFonts.labelLarge),
              const SizedBox(height: AppSpacing.s),
              Obx(() => Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children:
                        CategoryFormController.iconPalette.map((iconData) {
                      final isSelected = ctrl.selectedIconCodePoint.value ==
                          iconData.codePoint;
                      return GestureDetector(
                        onTap: () => ctrl.selectIcon(iconData.codePoint),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ctrl.selectedColor.value
                                    .withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: ctrl.selectedColor.value, width: 2)
                                : Border.all(
                                    color: AppColors.border, width: 1),
                          ),
                          child: Icon(
                            iconData,
                            size: AppSpacing.iconM,
                            color: isSelected
                                ? ctrl.selectedColor.value
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: AppSpacing.l),
              Text('Pick a Color', style: AppFonts.labelLarge),
              const SizedBox(height: AppSpacing.s),
              Obx(() => Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: CategoryFormController.palette.map((color) {
                      final selected = ctrl.selectedColor.value.toARGB32() ==
                          color.toARGB32();
                      return GestureDetector(
                        onTap: () => ctrl.selectColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: AppColors.textPrimary, width: 3)
                                : null,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2)
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: AppSpacing.xxl),
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
                        : Text(ctrl.isEditing
                            ? 'Save Changes'
                            : 'Create Category'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
