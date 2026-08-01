import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_storage.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'services/app/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive adapters + the settings box must be ready before anything reads them.
  await HiveStorage.init();
  await HiveStorage.openSettings();

  // The app is local-only: there is no sign-in event to wait for, so every
  // dependency is registered unconditionally at process start.
  await AppBindings.register();

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
      // The persisted choice, applied at startup rather than only when the
      // user next opens the theme sheet: SettingsService has already read the
      // settings box by the time this builds (see main() above). Later changes
      // come through Get.changeThemeMode in SettingsService.setThemeMode.
      themeMode: Get.find<SettingsService>().flutterThemeMode,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
