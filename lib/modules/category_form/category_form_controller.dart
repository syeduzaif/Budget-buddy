import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/predefined_categories.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';
import 'package:uuid/uuid.dart';

class CategoryFormController extends GetxController {
  final CategoryRepository categoryRepo;
  final SettingsService settings;

  CategoryFormController({required this.categoryRepo, required this.settings});

  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  final selectedColor = const Color(0xFF2D8B8B).obs;
  final selectedIconCodePoint = Rxn<int>();
  final isLoading = false.obs;
  final selectedPresetIndex = Rxn<int>();

  Category? editingCategory;

  static const List<Color> palette = [
    Color(0xFF2D8B8B),
    Color(0xFF1B4965),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFF1ABC9C),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF795548),
  ];

  static const List<IconData> iconPalette = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.home,
    Icons.bolt,
    Icons.movie,
    Icons.shopping_bag,
    Icons.local_hospital,
    Icons.school,
    Icons.savings,
    Icons.flight,
    Icons.pets,
    Icons.checkroom,
    Icons.phone_android,
    Icons.fitness_center,
    Icons.coffee,
    Icons.child_care,
    Icons.card_giftcard,
    Icons.build,
    Icons.wifi,
    Icons.more_horiz,
  ];

  bool get isEditing => editingCategory != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Category) {
      editingCategory = arg;
      nameController.text = arg.name;
      // Minor units are never shown raw: back to major-unit text for editing.
      budgetController.text = CurrencyUtils.formatForInput(
          arg.budgetLimitMinor, settings.currency);
      selectedColor.value = Color(arg.colorValue);
      selectedIconCodePoint.value = arg.iconCodePoint;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    budgetController.dispose();
    super.onClose();
  }

  void selectColor(Color color) => selectedColor.value = color;
  void selectIcon(int? codePoint) => selectedIconCodePoint.value = codePoint;

  /// Toggle a predefined category preset: tap to fill, tap again to clear.
  void selectPreset(int index) {
    if (selectedPresetIndex.value == index) {
      // Deselect — clear all fields
      selectedPresetIndex.value = null;
      nameController.clear();
      budgetController.clear();
      selectedColor.value = const Color(0xFF2D8B8B);
      selectedIconCodePoint.value = null;
    } else {
      // Select — auto-fill from preset
      final preset = kPredefinedCategories[index];
      selectedPresetIndex.value = index;
      nameController.text = preset.name;
      // Presets are already whole major units — the field takes major units.
      budgetController.text = preset.defaultBudgetMajor.toString();
      selectedColor.value = Color(preset.colorValue);
      selectedIconCodePoint.value = preset.iconCodePoint;
    }
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    // Text → minor units directly (C4): no double.parse, no multiply by 100.
    final budgetMinor = CurrencyUtils.tryParseToMinor(
        budgetController.text, settings.currency);
    if (name.isEmpty || budgetMinor == null || budgetMinor <= 0) return;

    isLoading.value = true;
    try {
      if (isEditing) {
        final updated = Category(
          id: editingCategory!.id,
          name: name,
          budgetLimitMinor: budgetMinor,
          colorValue: selectedColor.value.toARGB32(),
          iconCodePoint: selectedIconCodePoint.value,
          month: editingCategory!.month,
          createdAt: editingCategory!.createdAt,
          updatedAt: DateTime.now(),
        );
        await categoryRepo.updateCategory(updated);
      } else {
        final category = Category(
          id: const Uuid().v4(),
          name: name,
          budgetLimitMinor: budgetMinor,
          colorValue: selectedColor.value.toARGB32(),
          iconCodePoint: selectedIconCodePoint.value,
          month: settings.effectiveMonth,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await categoryRepo.addCategory(category);
      }
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, so a failure is never reported as a success (H3).
      debugPrint('[CategoryFormController] save failed: $e\n$stack');
      Get.snackbar(
        'Could not save category',
        'Nothing was saved. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      isLoading.value = false;
    }
    // Only leave the form once the write is known to have landed.
    Get.back();
  }

  Future<void> delete() async {
    if (!isEditing) return;
    isLoading.value = true;
    try {
      await categoryRepo.deleteCategory(editingCategory!.id);
    } catch (e, stack) {
      // Owner-approved mobile convention (2026-07-28): user-visible
      // failures surface via Get.snackbar. Hive throws on a failed
      // write, so a failure is never reported as a success (H3).
      debugPrint('[CategoryFormController] delete failed: $e\n$stack');
      Get.snackbar(
        'Could not delete category',
        'The category is still there. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      isLoading.value = false;
    }
    Get.back();
  }
}
