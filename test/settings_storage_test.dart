import 'dart:io';

import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// The settings box is untyped and static, which makes it the easiest place
/// in the app to lose money quietly: a write to a box that was never opened
/// used to succeed silently (H3), and a read used to cast whatever it found
/// (H2).
///
/// NOTE: `HiveStorage` holds its box in static state, so the "box not open"
/// group must stay FIRST in this file.
void main() {
  group('before openSettings', () {
    test('writes fail loudly instead of pretending to succeed', () {
      expect(() => HiveStorage.setMonthlyIncomeMinor(12345),
          throwsA(isA<StateError>()));
      expect(() => HiveStorage.setCurrencyCode('PKR'),
          throwsA(isA<StateError>()));
      expect(() => HiveStorage.setOnboardingComplete(true),
          throwsA(isA<StateError>()));
    });

    test('reads fall back to defaults', () {
      expect(HiveStorage.getMonthlyIncomeMinor(), 0);
      expect(HiveStorage.getCurrencyCode(), 'USD');
      expect(HiveStorage.isOnboardingComplete(), isFalse);
    });
  });

  group('with an open box', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_settings');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('income round-trips as minor units', () async {
      await HiveStorage.openSettings();
      await HiveStorage.setMonthlyIncomeMinor(250000);

      expect(HiveStorage.getMonthlyIncomeMinor(), 250000);
    });

    test('a pre-C4 major-unit income is dropped on open, not reinterpreted',
        () async {
      // What a float build left behind: a double under the old key.
      final box = await Hive.openBox(HiveStorage.settingsBoxName);
      await box.put('monthly_income', 2500.0);
      await box.close();

      await HiveStorage.openSettings();

      expect(HiveStorage.getMonthlyIncomeMinor(), 0,
          reason: '2500.0 must not be read as 2500 minor units (=25.00)');
      final reopened = Hive.box(HiveStorage.settingsBoxName);
      expect(reopened.containsKey('monthly_income'), isFalse);
    });

    test('a wrong-typed value reads as the default rather than throwing',
        () async {
      await HiveStorage.openSettings();
      final box = Hive.box(HiveStorage.settingsBoxName);
      await box.put('monthly_income_minor', 'not a number');
      await box.put('currency_code', 42);

      expect(HiveStorage.getMonthlyIncomeMinor(), 0);
      expect(HiveStorage.getCurrencyCode(), 'USD');
    });

    test('clearSettings returns every accessor to its default', () async {
      await HiveStorage.openSettings();
      await HiveStorage.setMonthlyIncomeMinor(9900);
      await HiveStorage.setCurrencyCode('JPY');
      await HiveStorage.setOnboardingComplete(true);

      await HiveStorage.clearSettings();

      expect(HiveStorage.getMonthlyIncomeMinor(), 0);
      expect(HiveStorage.getCurrencyCode(), 'USD');
      expect(HiveStorage.isOnboardingComplete(), isFalse);
    });
  });
}
