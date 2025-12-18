import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/storage/hive_service.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/user_session_service.dart';
import 'services/user_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'services/sync_service.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/income_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'modules/auth/auth_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive (only registers adapters)
  await HiveService.init();

  // Initialize Core Services
  Get.put(ConnectivityService(), permanent: true);
  Get.put(FirestoreService(), permanent: true);
  Get.put(SyncService(), permanent: true);

  // Repositories
  Get.put(CategoryRepository(), permanent: true);
  Get.put(IncomeRepository(), permanent: true);
  Get.put(ExpenseRepository(), permanent: true);
  Get.put(ChatRepository(), permanent: true);

  Get.put(UserSessionService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(GoogleAuthService(), permanent: true);
  Get.put(UserService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Bind AuthController here to ensure navigation context is ready
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: AppRoutes.login,
      getPages: AppPages.pages,
    );
  }
}
