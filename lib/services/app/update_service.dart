import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService extends GetxService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<UpdateService> init() async {
    await _initRemoteConfig();
    _checkForUpdates();
    return this;
  }

  Future<void> _initRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1), // Can be adjusted
    ));
    await _remoteConfig.setDefaults(const {
      'min_app_version': '1.0.0',
      'latest_app_version': '1.0.0',
      'is_force_update': false,
      'update_url_android': 'https://play.google.com/store/apps/details?id=com.buddgetbuddy.app',
      'update_url_ios': 'https://apps.apple.com/app/buddgetbuddy/id123456789',
    });
    
    // Fetch and activate
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Failed to fetch remote config: $e");
    }
  }

  void _checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // Use format like "1.0.0" without build numbers for comparison
    final currentVersion = packageInfo.version.split('+').first;

    final minAppVersion = _remoteConfig.getString('min_app_version');
    final latestAppVersion = _remoteConfig.getString('latest_app_version');
    final isForceUpdate = _remoteConfig.getBool('is_force_update');
    
    final isMinVersionSatisfied = _isVersionGreaterOrEqual(currentVersion, minAppVersion);
    final isLatestVersion = _isVersionGreaterOrEqual(currentVersion, latestAppVersion);

    // If minimum version is not satisfied, OR if it's force update and not the latest version, force it.
    if (!isMinVersionSatisfied || (isForceUpdate && !isLatestVersion)) {
      _showUpdateDialog(force: true);
    } else if (!isLatestVersion) {
      _showUpdateDialog(force: false);
    }
  }

  bool _isVersionGreaterOrEqual(String current, String target) {
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> targetParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int t = i < targetParts.length ? targetParts[i] : 0;
      if (c > t) return true;
      if (c < t) return false;
    }
    return true; // They are equal
  }

  void _showUpdateDialog({required bool force}) {
    // Delay to allow the app UI to build first
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.context != null) {
        showDialog(
          context: Get.context!,
          barrierDismissible: !force,
          builder: (context) => PopScope(
            canPop: !force,
            child: AlertDialog(
              title: const Text('Update Available'),
              content: Text(force 
                ? 'A critical update is available. You must update the app to continue using it.'
                : 'A new version of the app is available. Please update for the best experience.'),
              actions: [
                if (!force)
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Later'),
                  ),
                FilledButton(
                  onPressed: () => _launchStore(),
                  child: const Text('Update Now'),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Future<void> _launchStore() async {
    final urlString = Platform.isIOS 
      ? _remoteConfig.getString('update_url_ios')
      : _remoteConfig.getString('update_url_android');
      
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
