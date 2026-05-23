import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_category_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency_helper.dart';

/// View to add a new category
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Category'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g., Food, Travel, Party',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category name';
                  }
                  if (value.length > AppConstants.maxCategoryNameLength) {
                    return 'Category name too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Budget limit field
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget Limit *',
                  hintText: 'Enter budget amount',
                  prefixText: CurrencyHelper.getCurrencySymbol(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: AppConstants.paddingL),

              // Color picker
              const Text(
                'Select Color',
                style: AppConstants.headingSmall,
              ),
              const SizedBox(height: AppConstants.paddingM),
              Obx(() => Wrap(
                    spacing: AppConstants.paddingM,
                    runSpacing: AppConstants.paddingM,
                    children: List.generate(
                      AppConstants.categoryColors.length,
                      (index) => GestureDetector(
                        onTap: () => controller.selectColor(index),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppConstants.categoryColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.selectedColorIndex.value == index
                                  ? AppConstants.textPrimary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: controller.selectedColorIndex.value == index
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: AppConstants.paddingXL),

              // Save button
              ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                ),
                child: const Text('Create Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

