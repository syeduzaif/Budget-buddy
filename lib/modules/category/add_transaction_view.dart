import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/transaction_item.dart';
import '../../services/budget_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency_helper.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    // Get category ID from arguments
    _categoryId = Get.arguments as String?;
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = Helpers.formatDate(_selectedDate);
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _categoryId != null) {
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
        backgroundColor: AppConstants.successColor,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  hintText: 'Enter amount',
                  prefixText: CurrencyHelper.getCurrencySymbol(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (!Helpers.isValidAmount(value)) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Note field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Enter note (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                maxLength: AppConstants.maxTransactionNoteLength,
              ),
              const SizedBox(height: AppConstants.paddingM),

              // Date field
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: AppConstants.paddingXL),

              // Save button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                ),
                child: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
