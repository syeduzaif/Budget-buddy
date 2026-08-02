import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';
import '../../data/predefined_categories.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/validators.dart';
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

  /// Every category already in [targetMonth]. Live, because it decides both
  /// which Quick Select chips exist and whether a name is taken.
  final monthCategories = <Category>[].obs;

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

  /// The month the saved category lives in: the viewed month for a new one, the
  /// record's own month for an edit — a rename does not move a category, and
  /// each month is its own namespace by construction (F-08 out-of-scope note).
  String get targetMonth => editingCategory?.month ?? settings.effectiveMonth;

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

    categoryRepo.getCategories().listen(
      (list) => monthCategories
          .assignAll(list.where((c) => c.month == targetMonth).toList()),
      onError: (Object e, StackTrace s) {
        // The local store swallows read failures and re-emits the last good
        // snapshot, so this should never fire — but every listener carries
        // onError so a future failing source cannot kill the stream silently
        // (H2).
        debugPrint('[CategoryFormController] category stream failed: $e\n$s');
      },
    );
  }

  // --- Name rules -------------------------------------------------------------
  //
  // Tapping "Food" when a Food already exists used to create a second Food with
  // its own budget, and the month's spend then split across two
  // authoritative-looking rows: one tap to a data-quality defect that nothing in
  // the app could tell you about afterwards (F-08).

  /// The category in [targetMonth] that already answers to [name], if any.
  ///
  /// Trimmed and case-insensitive — "Food " and "food" are the same category to
  /// a person, and the attribution resolver already treats them that way, so a
  /// stricter compare here would let it mint duplicates the resolver then has to
  /// pick between. An edit never collides with ITSELF.
  Category? existingWithName(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final c in monthCategories) {
      if (c.id == editingCategory?.id) continue;
      if (c.name.trim().toLowerCase() == key) return c;
    }
    return null;
  }

  /// The form's name validator: the shared rules, then this month's namespace.
  ///
  /// An inline field error rather than a snackbar — this is a validation, not a
  /// write that failed (F-08 spec 2). The message names the category that is
  /// already there, in ITS spelling, so "food" is answered with the Food the
  /// user actually has.
  String? validateName(String? value) {
    final basic = Validators.categoryName(value);
    if (basic != null) return basic;

    final name = value!.trim();
    if (isReservedCategoryName(name)) {
      // The system bucket. Blocked for creation AND as a rename target —
      // without the second half, renaming any category to "Uncategorised"
      // hijacks the bucket the attribution resolver depends on.
      return '"$kUncategorisedCategoryName" is a reserved name';
    }
    final clash = existingWithName(name);
    if (clash != null) {
      return 'You already have a "${clash.name}" category';
    }
    return null;
  }

  /// The presets worth offering: those whose name is not already taken in
  /// [targetMonth], each paired with its index in [kPredefinedCategories] —
  /// [selectPreset] speaks that index, so filtering must not renumber.
  ///
  /// Empty when all nine exist, and the view then drops the whole section.
  List<MapEntry<int, PredefinedCategory>> get availablePresets => [
        for (var i = 0; i < kPredefinedCategories.length; i++)
          if (existingWithName(kPredefinedCategories[i].name) == null)
            MapEntry(i, kPredefinedCategories[i]),
      ];

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
      // The same share-of-income seed the onboarding flow uses, so a preset
      // picked here prefills the figure the app would have seeded rather than
      // a dollar-shaped constant (UI-35). Rendered as plain major-unit text,
      // which is what the field parses back.
      budgetController.text = CurrencyUtils.formatForInput(
          preset.seedLimitMinor(
              settings.monthlyIncomeMinor.value, settings.currency),
          settings.currency);
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
    // The form's validator is what the user sees; this is the same rule again so
    // the write itself cannot mint a duplicate, exactly as the amount check
    // above guards the money. (The reserved name has a third guard in the
    // repository, which throws.)
    if (validateName(nameController.text) != null) return;

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
