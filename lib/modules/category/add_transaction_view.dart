import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/transaction_item.dart';
import '../../services/budget_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency_helper.dart';

/// View to add a new transaction
class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _categoryId;

  // To verify if we allow changing category or it's fixed
  bool _isCategoryFixed = false;

  @override
  void initState() {
    super.initState();
    // Get category ID from arguments
    _categoryId = Get.arguments as String?;
    if (_categoryId != null) {
      _isCategoryFixed = true;
    }
    _dateController.text = Helpers.formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = Helpers.formatDate(_selectedDate);
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_categoryId == null) {
        Get.snackbar(
          'Error',
          'Please select a category',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final amount = Helpers.parseAmount(_amountController.text);

      final transaction = TransactionItem(
        id: const Uuid().v4(),
        categoryId: _categoryId!,
        amount: amount,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final budgetService = Get.find<BudgetService>();
      await budgetService.addTransaction(transaction);
      // Streams will update the UI, no manual refresh needed

      Get.back();
      Get.snackbar(
        'Success',
        'Transaction added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green, // Use standard colors or theme colors
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetService = Get.find<BudgetService>();

    return Scaffold(
      backgroundColor:
          theme.colorScheme.primary, // Colored background for header
      appBar: AppBar(
        title: const Text('Add Transaction',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. Hero Amount Input Section
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'How much?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicWidth(
                    child: TextFormField(
                      controller: _amountController,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixText: '${CurrencyHelper.getCurrencySymbol()} ',
                        prefixStyle: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return ''; // Suppress inline error for visual cleanliness, validate on save
                        if (!Helpers.isValidAmount(value)) return '';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Details Sheet Section
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Category Selection (if not fixed)
                      if (!_isCategoryFixed) ...[
                        DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: budgetService.categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(Icons.circle,
                                      color: Color(category.colorValue),
                                      size: 12),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _categoryId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Note field
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'What is this for?',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 1,
                        maxLength: AppConstants.maxTransactionNoteLength,
                      ),
                      const SizedBox(height: 20),

                      // Date field
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Save Transaction',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
