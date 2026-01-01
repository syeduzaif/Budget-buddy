import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_category_controller.dart';
import '../../utils/currency_helper.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AddCategoryView extends StatefulWidget {
  const AddCategoryView({super.key});

  @override
  State<AddCategoryView> createState() => _AddCategoryViewState();
}

class _AddCategoryViewState extends State<AddCategoryView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late AddCategoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCategoryController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final budgetLimit = Helpers.parseAmount(_budgetController.text);
      await controller.createCategory(
        name: _nameController.text,
        budgetLimit: budgetLimit,
      );
    }
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Obx(() => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(
                      AppConstants.categoryColors.length,
                      (index) => GestureDetector(
                        onTap: () {
                          controller.selectColor(index);
                          Get.back();
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppConstants.categoryColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  controller.selectedColorIndex.value == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.categoryColors[index]
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: controller.selectedColorIndex.value == index
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Category'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Name
              TextFormField(
                controller: _nameController,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Food, Travel',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Budget Limit
              TextFormField(
                controller: _budgetController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Monthly Budget',
                  hintText: '0.00',
                  prefixText: CurrencyHelper.getCurrencySymbol(),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter budget limit';
                  }
                  if (!Helpers.isValidAmount(value)) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Color Picker
              InkWell(
                onTap: () => _showColorPicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(16),
                    color: theme.inputDecorationTheme.fillColor,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.color_lens_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Category Color',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Obx(() => Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppConstants.categoryColors[
                                  controller.selectedColorIndex.value],
                              shape: BoxShape.circle,
                            ),
                          )),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                ),
                child: Text(
                  'Create Category',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
