import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency_helper.dart';
import '../../services/budget_service.dart';

/// Dialog widget for setting monthly income
class SetIncomeDialog extends StatefulWidget {
  final double initialAmount;

  const SetIncomeDialog({
    super.key,
    required this.initialAmount,
  });

  @override
  State<SetIncomeDialog> createState() => _SetIncomeDialogState();
}

class _SetIncomeDialogState extends State<SetIncomeDialog> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    final amount = Helpers.parseAmount(_amountController.text);
    if (amount > 0) {
      final budgetService = Get.find<BudgetService>();
      budgetService.setIncome(amount);
      Get.back(result: true);
    } else {
      Get.snackbar(
        'Error',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Monthly Income',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter monthly income',
                    prefixText: CurrencyHelper.getCurrencySymbol(),
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (value) => _onSave(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onSave,
                      child: const Text('Set'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

