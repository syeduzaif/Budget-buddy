import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'data/local/hive_storage.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/app/connectivity_service.dart';
import 'services/app/session_service.dart';
import 'services/firebase/firebase_auth_service.dart';
import 'services/firebase/firestore_service.dart';
import 'services/firebase/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env');
  await HiveStorage.init();

  // Auth-independent startup services only
  Get.put(ConnectivityService(), permanent: true);
  Get.put(FirestoreService(), permanent: true);
  Get.put(FirebaseAuthService(), permanent: true);
  Get.put(GoogleAuthService(), permanent: true);
  Get.put(SessionService(), permanent: true);

  runApp(const BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Budget Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.login,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
    );
  }
}
