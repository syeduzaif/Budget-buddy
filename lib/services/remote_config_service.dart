import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Keys used in Firebase Remote Config
const String _kMinVersion = 'min_version';   // e.g. "1.0.0"
const String _kTestVersion = 'test_version'; // e.g. "1.2.0"
const String _kForceUpdate = 'force_update'; // true / false

class RemoteConfigService {
  /// Call this once after Firebase.initializeApp().
  /// It fetches remote config values and shows a dialog when needed.
  static Future<void> checkForUpdate(BuildContext context) async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // ── Default values (safe fallback while config is loading) ──────────────
    await remoteConfig.setDefaults({
      _kMinVersion: '1.0.0',
      _kTestVersion: '1.0.0',
      _kForceUpdate: false,
    });

    // ── Fetch & activate ────────────────────────────────────────────────────
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero, // Always fetch fresh during dev
    ));

    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {
      // If fetch fails, defaults are used — don't crash the app.
    }

    // ── Read remote values ───────────────────────────────────────────────────
    final String minVersion = remoteConfig.getString(_kMinVersion);
    final String testVersion = remoteConfig.getString(_kTestVersion);
    final bool forceUpdate = remoteConfig.getBool(_kForceUpdate);

    // ── Read current app version ─────────────────────────────────────────────
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String currentVersion = info.version; // e.g. "1.0.0"

    debugPrint('[RemoteConfig] current=$currentVersion  '
        'min=$minVersion  test=$testVersion  force=$forceUpdate');

    // ── Compare as plain strings ─────────────────────────────────────────────
    // Show dialog when current version does NOT match min_version
    // OR current version does NOT match test_version.
    final bool versionMismatch =
        (currentVersion != minVersion) || (currentVersion != testVersion);

    if (versionMismatch) {
      _showUpdateDialog(context, forceUpdate: forceUpdate);
    }
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────
  static void _showUpdateDialog(
    BuildContext context, {
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // tap outside only works if NOT forced
      builder: (ctx) => PopScope(
        // Prevent back-button dismiss when forced
        canPop: !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                color: forceUpdate ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Update Available'),
            ],
          ),
          content: Text(
            forceUpdate
                ? 'A required update is available. Please update the app to '
                    'continue using Budget Buddy.'
                : 'A new version of Budget Buddy is available. '
                    'Update now for the best experience.',
          ),
          actions: [
            // "Later" only shown when update is optional
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text('Update Now'),
              onPressed: () {
                // TODO: replace with your Play Store / App Store URL
                // launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.yourapp'));
                if (!forceUpdate) Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
