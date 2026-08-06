import 'dart:async';
import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/settings/settings_controller.dart';
import 'package:budget_buddy/modules/settings/settings_view.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-10 AC-D026-2 (D-026, second half) — the Settings income sheet's Save is
/// disabled and spinning while its write is in flight.
///
/// The same defect as onboarding's, in the sheet's ONLY control: Save awaited a
/// Hive write and gave no feedback of any kind, so the only thing a user could
/// do with an apparently-dead button was press it again. The consequence is
/// much smaller here — a duplicate write of an identical parsed value, which is
/// idempotent — and it is fixed anyway, because leaving one of two identical
/// defects fixed is how a codebase acquires "why is this one different"
/// archaeology.
///
/// Both mechanisms are asserted separately, so neither can hide the other:
/// the disabled/spinning button (what stops the second tap) and the controller
/// latch (the guarantee, which holds for any future caller).
///
/// The write is the only thing faked. A real Hive `put` cannot complete under
/// the fake clock that `tester.tap` needs, and the point of these tests is the
/// window WHILE it is in flight — so the seam is a settings service whose
/// income write waits on a completer this file controls.
void main() {
  late Directory tempDir;
  late _GatedIncomeSettings settings;

  final thisMonth = AppDateUtils.getCurrentMonthKey();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_income');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    settings = _GatedIncomeSettings();
    Get.put<SettingsService>(settings);
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await settings.setMonthlyIncomeMinor(15000000);
    settings.resetSeam();
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// GetX's snackbar queue is static and strictly serial, so a bar left
  /// standing blocks every later test in this file.
  ///
  /// Drained on the FAKE clock, deliberately, and this is the one thing about
  /// this file's shape worth reading: `tester.runAsync` — how the splash tests
  /// drain — is exactly what lets `AppFonts`' google_fonts requests reach the
  /// binding's canned 400 and fail a test that renders a real screen. These
  /// bars are raised inside the test body rather than inside `runAsync`, so
  /// their dismissal timers are fake-clock timers and `pump` can reach them.
  Future<void> drainSnackbars(WidgetTester tester) async {
    Get.closeAllSnackbars();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> openIncomeSheet(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      home: const SettingsView(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly Income'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget,
        reason: 'the sheet is open and its only control is on screen');
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  group('AC-D026-2 — the button while the write is in flight', () {
    testWidgets('Save is disabled and shows a spinner', (tester) async {
      await openIncomeSheet(tester);
      await tester.enterText(find.byType(TextField), '90000');

      expect(saveButton(tester).onPressed, isNotNull,
          reason: 'live before the tap — otherwise the assertion below proves '
              'nothing');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(saveButton(tester).onPressed, isNull,
          reason: 'AC-D026-2: dead while the write runs');
      expect(
          find.descendant(
              of: find.byType(FilledButton),
              matching: find.byType(CircularProgressIndicator)),
          findsOneWidget,
          reason: 'AC-D026-2: the spinner is in the button itself');
      expect(find.text('Save'), findsNothing,
          reason:
              'the label is replaced by the spinner, not sitting beside it');

      settings.completeWrite();
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing,
          reason: 'the sheet closes on success');
      expect(settings.monthlyIncomeMinor.value, 9000000);
      await drainSnackbars(tester);
    });

    testWidgets('the button comes back live after a FAILED write',
        (tester) async {
      // The release is in a `finally`, so every exit — rejected amount, failed
      // write, success — leaves the control usable. A latch that leaked on the
      // error path would strand the sheet.
      await openIncomeSheet(tester);
      await tester.enterText(find.byType(TextField), '90000');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(saveButton(tester).onPressed, isNull);

      settings.failWrite();
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget,
          reason: 'a failed write must not close the sheet');
      expect(saveButton(tester).onPressed, isNotNull);
      expect(find.text('Save'), findsOneWidget);
      expect(settings.monthlyIncomeMinor.value, 15000000,
          reason: 'unchanged — and the user was told');
      await drainSnackbars(tester);
    });

    testWidgets('a rejected amount releases the button before any frame',
        (tester) async {
      // Validation is synchronous and sits inside the latch. If the release
      // were not in a `finally`, this path would leave Save dead forever with
      // the sheet still open.
      await openIncomeSheet(tester);
      await tester.enterText(find.byType(TextField), 'not a number');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(saveButton(tester).onPressed, isNotNull);
      expect(settings.writeCalls, 0);
      await drainSnackbars(tester);
    });
  });

  group('AC-D026-2 — the latch, with no button state to help it', () {
    testWidgets('a second saveIncome during the first is a no-op',
        (tester) async {
      await openIncomeSheet(tester);
      await tester.enterText(find.byType(TextField), '90000');

      final ctrl = Get.find<SettingsController>();
      final first = ctrl.saveIncome();
      await tester.pump();
      final second = ctrl.saveIncome();
      await tester.pump();

      expect(settings.writeCalls, 1,
          reason: 'the latch, not the button — this call bypassed the UI '
              'entirely, which is how a future third caller would arrive');

      settings.completeWrite();
      await first;
      await second;
      await tester.pumpAndSettle();

      expect(ctrl.isSavingIncome.value, isFalse);
      await drainSnackbars(tester);
    });
  });
}

/// Settings whose income write is held open by this file.
///
/// Everything else is the shipping service — the currency, the month and the
/// initial income in `setUp` are real Hive writes, so the controller reads a
/// real box and formats a real value.
class _GatedIncomeSettings extends SettingsService {
  /// Off while `setUp` seeds through the real service; on for the test body.
  bool gated = false;
  Completer<void>? _gate;
  int writeCalls = 0;

  void resetSeam() {
    gated = true;
    _gate = null;
    writeCalls = 0;
  }

  /// Lets the in-flight write succeed.
  void completeWrite() => _gate?.complete();

  /// Makes the in-flight write throw, as a full disk would.
  void failWrite() => _gate?.completeError(StateError('simulated Hive put'));

  @override
  Future<void> setMonthlyIncomeMinor(int minor) async {
    if (!gated) return super.setMonthlyIncomeMinor(minor);
    writeCalls++;
    final gate = Completer<void>();
    _gate = gate;
    await gate.future;
    // Published, not persisted: a real box write cannot complete under the
    // fake clock, and what these tests measure is the window before this line.
    monthlyIncomeMinor.value = minor;
  }
}
