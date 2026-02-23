import 'package:get/get.dart';
import '../../data/local/hive_storage.dart';

/// Manages Hive user session lifecycle.
/// Call initUserSession after login, closeUserSession on logout.
class SessionService extends GetxService {
  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  Future<void> initUserSession(String userId) async {
    _currentUserId = userId;
    await HiveStorage.openUserSession(userId);
  }

  Future<void> closeUserSession() async {
    await HiveStorage.closeUserSession();
    _currentUserId = null;
  }
}
