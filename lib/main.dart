import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'services/app/update_service.dart';

import 'core/constants/app_constants.dart';
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

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized (e.g. hot restart) — safe to ignore
  }
  
  // Crashlytics setup
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseAnalytics.instance; // Initialize Firebase Analytics

  await dotenv.load(fileName: '.env');
  await HiveStorage.init();

  // Auth-independent startup services only
  Get.putAsync(() => UpdateService().init(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  Get.put(FirestoreService(), permanent: true);
  Get.put(FirebaseAuthService(), permanent: true);
  Get.put(GoogleAuthService(), permanent: true);
  Get.put(SessionService(), permanent: true);

  runApp(const BuddgetBuddyApp());
}

class BuddgetBuddyApp extends StatelessWidget {
  const BuddgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
