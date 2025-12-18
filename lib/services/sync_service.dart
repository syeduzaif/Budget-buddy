import 'package:get/get.dart';
import 'connectivity_service.dart';

class SyncService extends GetxService {
  final ConnectivityService connectivityService =
      Get.find<ConnectivityService>();

  bool get isOnline => connectivityService.isOnline.value;

  @override
  void onInit() {
    super.onInit();
    // Monitoring connectivity is handled by ConnectivityService.
    // Firestore SDK handles auto-pushing of pending writes when online.

    // We can listen to connectivity changes to log or trigger specific actions if needed.
    connectivityService.isOnline.listen((online) {
      if (online) {
        print("Device is online. Firestore will auto-sync pending writes.");
      } else {
        print("Device is offline. Writes will be cached locally.");
      }
    });
  }
}
