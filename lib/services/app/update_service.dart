import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Remote Config keys
const _kMinVersion = 'min_app_version';
const _kTestVersion = 'test_version';
const _kForceUpdate = 'is_force_update';
const _kUrlAndroid = 'update_url_android';
const _kUrlIos = 'update_url_ios';

class UpdateService extends GetxService {
  final _remoteConfig = FirebaseRemoteConfig.instance;

  Future<UpdateService> init() async {
    await _setupRemoteConfig();
    await _checkForUpdates();
    return this;
  }

  // ─── Remote Config Setup ──────────────────────────────────────────

  Future<void> _setupRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      // Use short interval for testing; set to hours: 1 for production
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    // Default values — update these to match your Firebase console
    await _remoteConfig.setDefaults(const {
      _kMinVersion: '1.0.0',   // Oldest version still allowed to run
      _kTestVersion: '1.1.0',  // Version used for testing the dialog
      _kForceUpdate: false,     // true = user CANNOT dismiss the dialog
      _kUrlAndroid: 'https://play.google.com/store/apps/details?id=com.buddgetbuddy.app',
      _kUrlIos: 'https://apps.apple.com/app/buddgetbuddy/id123456789',
    });

    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('[UpdateService] Remote Config fetched successfully');
    } catch (e) {
      debugPrint('[UpdateService] Failed to fetch Remote Config: $e');
    }
  }

  // ─── Version Check Logic ──────────────────────────────────────────

  Future<void> _checkForUpdates() async {
    final info = await PackageInfo.fromPlatform();
    // Strip build number (e.g. "1.1.0+2" → "1.1.0")
    final currentVersion = info.version.split('+').first.trim();

    final minVersion = _remoteConfig.getString(_kMinVersion).trim();
    final testVersion = _remoteConfig.getString(_kTestVersion).trim();
    final isForce = _remoteConfig.getBool(_kForceUpdate);

    debugPrint('[UpdateService] currentVersion=$currentVersion | minVersion=$minVersion | testVersion=$testVersion | isForce=$isForce');

    // ── Rule 1: current < min_version → always force update ──────────
    if (_isLower(currentVersion, minVersion)) {
      debugPrint('[UpdateService] Below minimum version → FORCE dialog');
      _showDialog(force: true);
      return;
    }

    // ── Rule 2: current != test_version → show dialog based on force flag ──
    if (currentVersion != testVersion) {
      debugPrint('[UpdateService] Version mismatch with test_version → showing dialog (force=$isForce)');
      _showDialog(force: isForce);
    }
  }

  /// Returns true if [a] is strictly lower than [b] using segment comparison.
  /// e.g. "1.0.9" < "1.1.0" → true
  bool _isLower(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final length = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < length; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av < bv) return true;
      if (av > bv) return false;
    }
    return false; // equal
  }

  // ─── Update Dialog ────────────────────────────────────────────────

  void _showDialog({required bool force}) {
    // Small delay so the app's first route is fully rendered
    Future.delayed(const Duration(seconds: 2), () {
      final ctx = Get.context;
      if (ctx == null) return;

      showDialog(
        context: ctx,
        barrierDismissible: !force, // tap-outside only closes if not forced
        builder: (_) => PopScope(
          canPop: !force, // back-button only works if not forced
          child: AlertDialog(
            icon: Icon(
              force ? Icons.warning_amber_rounded : Icons.system_update_alt_rounded,
              color: force ? Colors.orange : Theme.of(ctx).colorScheme.primary,
              size: 36,
            ),
            title: Text(force ? '🚨 Update Required' : '🆕 Update Available'),
            content: Text(
              force
                  ? 'This version is no longer supported.\nPlease update the app to continue.'
                  : 'A new version of Budget Buddy is available.\nUpdate now for the latest features and fixes.',
            ),
            actions: [
              // "Later" button — only shown when update is NOT forced
              if (!force)
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Later'),
                ),
              FilledButton.icon(
                onPressed: _launchStore,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Now'),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Store Launcher ───────────────────────────────────────────────

  Future<void> _launchStore() async {
    final urlStr = Platform.isIOS
        ? _remoteConfig.getString(_kUrlIos)
        : _remoteConfig.getString(_kUrlAndroid);

    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[UpdateService] Could not launch store URL: $url');
    }
  }
}
