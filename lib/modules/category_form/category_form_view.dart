import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/app_icons.dart';
import '../../data/predefined_categories.dart';
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
    // Selection states are hand-built here, but the RESTING states must come
    // from the scheme: the raw light-theme tokens they used computed to 2.79:1
    // on the dark background, so 9 chips and 20 icons read as disabled (UI-03c).
    final colorScheme = Theme.of(context).colorScheme;

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
              // Quick-select chips (only when creating, not editing)
              if (!ctrl.isEditing) ...[
                Text('Quick Select', style: AppFonts.labelLarge),
                const SizedBox(height: AppSpacing.s),
                Obx(() => Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: List.generate(
                        kPredefinedCategories.length,
                        (i) {
                          final preset = kPredefinedCategories[i];
                          final isSelected =
                              ctrl.selectedPresetIndex.value == i;
                          final chipColor = Color(preset.colorValue);
                          return GestureDetector(
                            onTap: () => ctrl.selectPreset(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? chipColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusXl),
                                border: Border.all(
                                  color: isSelected
                                      ? chipColor
                                      : colorScheme.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.fromCodePoint(preset.iconCodePoint),
                                    size: 18,
                                    color: isSelected
                                        ? chipColor
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    preset.name,
                                    style: AppFonts.labelMedium.copyWith(
                                      color: isSelected
                                          ? chipColor
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                const SizedBox(height: AppSpacing.l),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                      child:
                          Text('or customize below', style: AppFonts.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
              ],
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
                decoration: InputDecoration(
                  labelText: 'Budget Limit',
                  // The currency symbol replaces the old hardcoded dollar
                  // icon, which was wrong for 22 of the 23 currencies. Matches
                  // the transaction form's amount field.
                  prefixText: '${ctrl.settings.currency.symbol} ',
                ),
                validator: Validators.amount(ctrl.settings.currency),
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
                        // 48×48: a plain GestureDetector's hit area is exactly
                        // its box, so 44 was 4dp under the minimum target
                        // (UI-30). The glyph stays at 24.
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
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
                                    color: colorScheme.outlineVariant,
                                    width: 1),
                          ),
                          child: Icon(
                            iconData,
                            size: AppSpacing.iconM,
                            color: isSelected
                                ? ctrl.selectedColor.value
                                : colorScheme.onSurfaceVariant,
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
                        // 48×48 hit box around an unchanged 40dp swatch: the
                        // target meets the minimum without the swatch grid
                        // growing (UI-30).
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selected
                                    // Espresso was invisible on the dark
                                    // background; the scheme's onSurface reads
                                    // in both (UI-03c).
                                    ? Border.all(
                                        color: colorScheme.onSurface, width: 3)
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
                          ),
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
