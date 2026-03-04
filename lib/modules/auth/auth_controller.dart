import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../services/firebase/google_auth_service.dart';
import '../../services/app/session_service.dart';
import '../../services/app/settings_service.dart';
import '../../services/app/gemini_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/date_utils.dart';

class AuthController extends GetxController {
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final SessionService _session = Get.find<SessionService>();

  @override
  void onInit() {
    super.onInit();
    _authService.authStateChanges.listen(_handleAuthStateChanged);
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    if (user == null) {
      _cleanupPostLoginServices();
      Get.offAllNamed(AppRoutes.login);
    } else {
      await _initPostLoginServices(user.uid);
      final settings = Get.find<SettingsService>();
      if (!settings.onboardingComplete.value) {
        Get.offAllNamed(AppRoutes.onboarding);
      } else {
        // Always sync to current month on app load/resume
        await settings.setCurrentMonth(AppDateUtils.getCurrentMonthKey());
        Get.offAllNamed(AppRoutes.home);
      }
    }
  }

  Future<void> _initPostLoginServices(String uid) async {
    await _session.initUserSession(uid);

    if (!Get.isRegistered<SettingsService>()) {
      Get.put(SettingsService(), permanent: true);
    }
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.put(CategoryRepository(), permanent: true);
    }
    if (!Get.isRegistered<TransactionRepository>()) {
      Get.put(TransactionRepository(), permanent: true);
    }
    if (!Get.isRegistered<IncomeRepository>()) {
      Get.put(IncomeRepository(), permanent: true);
    }
    if (!Get.isRegistered<ChatRepository>()) {
      Get.put(ChatRepository(), permanent: true);
    }
    if (!Get.isRegistered<GeminiService>()) {
      Get.put(GeminiService(), permanent: true);
    }
  }

  void _cleanupPostLoginServices() {
    _session.closeUserSession();
    // GetX will handle cleanup of permanent services on app exit;
    // on logout we simply delete them so they re-init fresh next login.
    if (Get.isRegistered<SettingsService>())
      Get.delete<SettingsService>(force: true);
    if (Get.isRegistered<CategoryRepository>())
      Get.delete<CategoryRepository>(force: true);
    if (Get.isRegistered<TransactionRepository>())
      Get.delete<TransactionRepository>(force: true);
    if (Get.isRegistered<IncomeRepository>())
      Get.delete<IncomeRepository>(force: true);
    if (Get.isRegistered<ChatRepository>())
      Get.delete<ChatRepository>(force: true);
    if (Get.isRegistered<GeminiService>())
      Get.delete<GeminiService>(force: true);
  }

  Future<void> signOut() async {
    final googleAuth = Get.find<GoogleAuthService>();
    await googleAuth.signOut();
    await _authService.signOut();
    // _handleAuthStateChanged will fire and do the rest
  }
}
