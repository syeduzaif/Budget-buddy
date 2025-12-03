import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/storage/hive_service.dart';
import 'services/budget_service.dart';
import 'services/income_service.dart';
import 'services/ai_insights_service.dart';
import 'services/ai_alert_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'utils/currency_helper.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.init();

  // Initialize GetX services
  Get.put(BudgetService(), permanent: true);
  Get.put(IncomeService(), permanent: true);
  Get.put(AiInsightsService(), permanent: true);
  Get.put(AiAlertService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user has selected currency
    final hasSelectedCurrency = CurrencyHelper.hasSelectedCurrency();

    return GetMaterialApp(
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: hasSelectedCurrency
          ? AppRoutes.dashboard
          : AppRoutes.currencySelection,
      getPages: AppPages.pages,
    );
  }
}
