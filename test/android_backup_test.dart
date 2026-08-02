import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F-12 — the phone's backup carries this app's data, and only this app's data.
///
/// These are configuration files, so the test is a guard rather than a
/// behaviour check: nothing in Dart can observe them, and the round-trip
/// (`adb shell bmgr backupnow` → wipe → restore) needs a real Android device,
/// which this pipeline does not have. What CAN be checked here is that the
/// three attributes and the two rule files still exist and still say what they
/// were reasoned into saying — the failure mode being a later manifest edit
/// that drops one silently and is only discovered by a user who lost a phone.
///
/// Read as text on purpose: the point is what ships in the file, not what some
/// parser would tolerate.
void main() {
  File manifestFile() =>
      File('android/app/src/main/AndroidManifest.xml');
  File backupRulesFile() =>
      File('android/app/src/main/res/xml/backup_rules.xml');
  File extractionRulesFile() =>
      File('android/app/src/main/res/xml/data_extraction_rules.xml');

  test('the test runs from the package root, so the paths below mean what they say',
      () {
    expect(manifestFile().existsSync(), isTrue,
        reason: 'run with `flutter test` from Budget-buddy/');
  });

  group('the manifest', () {
    late String manifest;

    setUp(() => manifest = manifestFile().readAsStringSync());

    test('declares backup explicitly instead of inheriting the default', () {
      // Absent meant "true, unscoped" from API 23 on — the app was already
      // being backed up with no rules. Explicit is the whole point.
      expect(manifest, contains('android:allowBackup="true"'));
      expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
      expect(manifest,
          contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    });

    test('asks for no permissions at all', () {
      // The local-only claim, kept honest at the source we control. (The
      // release APK also carries androidx.core's self-declared
      // DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, injected by the library
      // merge — signature-level, granted only to this app's own signature, and
      // nothing to do with this app's manifest.)
      expect(manifest.contains('uses-permission'), isFalse);
    });
  });

  group('backup_rules.xml (API 24-30)', () {
    late String rules;

    setUp(() => rules = backupRulesFile().readAsStringSync());

    test('includes exactly the directory Hive writes to', () {
      // The chain, verified rather than assumed:
      //   Hive.initFlutter() with no sub-directory
      //     -> getApplicationDocumentsDirectory()      (hive_flutter 1.1.0)
      //     -> PathUtils.getDataDirectory(context)     (path_provider_android)
      //     -> context.getDir("flutter", MODE_PRIVATE) (Flutter engine)
      //     -> <app data dir>/app_flutter              (Context.getDir prefixes "app_")
      // settings_local, categories and transactions are files directly inside.
      expect(rules, contains('<full-backup-content>'));
      expect(rules, contains('<include domain="root" path="app_flutter"/>'));
    });

    test('excludes nothing, deliberately', () {
      // Include-mode: naming one directory leaves everything else behind by
      // construction. A per-file include list would quietly orphan the next
      // box someone adds.
      expect(rules.contains('<exclude'), isFalse);
    });
  });

  group('data_extraction_rules.xml (API 31+)', () {
    late String rules;

    setUp(() => rules = extractionRulesFile().readAsStringSync());

    test('covers cloud backup AND device transfer with the same include', () {
      // Omitting device-transfer does not turn it off; it leaves it on the
      // unscoped platform default, which is what this ticket ends.
      expect(rules, contains('<cloud-backup'));
      expect(rules, contains('<device-transfer>'));
      expect(
          '<include domain="root" path="app_flutter"/>'
              .allMatches(rules)
              .length,
          2,
          reason: 'one include under each section');
    });

    test('sets disableIfNoEncryptionCapabilities explicitly to false', () {
      // A conscious tradeoff (FD-8), not a default: true would silently skip
      // backup on devices with no lock screen — a large share of the phones
      // this app is for, and the ones most likely to be lost.
      expect(rules,
          contains('disableIfNoEncryptionCapabilities="false"'));
    });

    test('excludes nothing, deliberately', () {
      expect(rules.contains('<exclude'), isFalse);
    });
  });

  test('the erase dialog no longer claims nothing is backed up', () {
    // A source guard, because the string lives inside a private dialog
    // builder. It was false on both platforms — Android has backed this app up
    // by default since API 23, and the iOS documents directory is in iCloud —
    // and it is the one sentence a user reads before wiping their records.
    final settingsView =
        File('lib/modules/settings/settings_view.dart').readAsStringSync();
    expect(settingsView.contains('Nothing is backed up anywhere'), isFalse);
    expect(settingsView, contains('a copy may still exist there'));
  });
}
