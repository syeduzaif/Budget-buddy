import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Inject services if they aren't already (though Main should handle permanent services)
    // Using lazyPut to ensure they are available when AuthController needs them
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<GoogleAuthService>()) {
      Get.put(GoogleAuthService(), permanent: true);
    }
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }

    // Get.lazyPut<AuthController>(() => AuthController());
  }
}
