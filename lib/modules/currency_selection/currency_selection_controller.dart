import 'package:get/get.dart';
import '../../data/storage/hive_service.dart';
import '../../utils/currency_helper.dart';

/// Controller for currency selection
class CurrencySelectionController extends GetxController {
  final Rx<Currency?> selectedCurrency = Rx<Currency?>(null);

  @override
  void onInit() {
    super.onInit();
    // Load current selection if any
    final currentCurrency = CurrencyHelper.getSelectedCurrencyCode();
    final currency = CurrencyHelper.getCurrencyByCode(currentCurrency);
    selectedCurrency.value = currency;
  }

  /// Select a currency
  void selectCurrency(Currency currency) {
    selectedCurrency.value = currency;
  }

  /// Save selected currency
  Future<void> saveCurrency() async {
    if (selectedCurrency.value != null) {
      await HiveService.setSelectedCurrency(selectedCurrency.value!.code);
      // Navigate to dashboard after currency selection
      Get.offAllNamed('/');
    }
  }

  /// Check if currency is selected
  bool isCurrencySelected(Currency currency) {
    return selectedCurrency.value?.code == currency.code;
  }
}

