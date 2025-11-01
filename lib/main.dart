import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/storage/hive_service.dart';
import 'services/budget_service.dart';
import 'services/income_service.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'utils/constants.dart';
import 'utils/currency_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.init();

  // Initialize GetX services
  Get.put(BudgetService(), permanent: true);
  Get.put(IncomeService(), permanent: true);

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: hasSelectedCurrency ? AppRoutes.dashboard : AppRoutes.currencySelection,
      getPages: AppPages.pages,
    );
  }
}
