import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../services/app/settings_service.dart';
import '../../utils/date_utils.dart';
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

  Category? editingCategory;

  static const List<Color> palette = [
    Color(0xFF2D8B8B), Color(0xFF1B4965), Color(0xFFE74C3C),
    Color(0xFF2ECC71), Color(0xFFF39C12), Color(0xFF3498DB),
    Color(0xFF9B59B6), Color(0xFFE67E22), Color(0xFF1ABC9C),
    Color(0xFFE91E63), Color(0xFF607D8B), Color(0xFF795548),
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
      budgetController.text = arg.budgetLimit.toString();
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

  Future<void> save() async {
    final name = nameController.text.trim();
    final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
    if (name.isEmpty || budget <= 0) return;

    isLoading.value = true;
    try {
      if (isEditing) {
        final updated = Category(
          id: editingCategory!.id,
          name: name,
          budgetLimit: budget,
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
          budgetLimit: budget,
          colorValue: selectedColor.value.toARGB32(),
          iconCodePoint: selectedIconCodePoint.value,
          month: settings.currentMonth.value.isNotEmpty
              ? settings.currentMonth.value
              : AppDateUtils.getCurrentMonthKey(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await categoryRepo.addCategory(category);
      }
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> delete() async {
    if (!isEditing) return;
    isLoading.value = true;
    try {
      await categoryRepo.deleteCategory(editingCategory!.id);
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }
}
