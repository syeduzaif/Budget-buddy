import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/routes/app_pages.dart';
import 'package:budget_buddy/routes/app_routes.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// How long the fake wipe pretends to take, so `Get.offAllNamed` can be made to
/// fire before, during or after the dialog's exit transition.
Duration wipeDuration = Duration.zero;

class _NoWipeCategoryRepository extends CategoryRepository {
  @override
  Future<void> deleteAll() => Future<void>.delayed(wipeDuration);
}

class _NoWipeTransactionRepository extends TransactionRepository {
  @override
  Future<void> deleteAll() => Future<void>.delayed(wipeDuration);
}

class _NoWipeSettingsService extends SettingsService {
  /// The only thing skipped. `resetToDefaults` still runs as shipped, so the
  /// reload it does reads the (uncleared) box back — which for the value under
  /// test, `themeMode`, is exactly the reset's answer: the box holds 'system'
  /// and the live value was moved off it.
  @override
  Future<void> clearStoredSettings() async {}
}

/// BUG-100 — "Erase All Data" landed on a broken onboarding: a red
/// GlobalKey/ink-renderer panel where the "Get Started" button belongs, a
/// "BOTTOM OVERFLOWED BY 99,597 PIXELS" stripe under it, and no way out but
/// force-killing the app. The very first screen after the one dialog a user has
/// to trust.
///
/// This file is what found the cause, so it keeps the probe matrix that did it.
/// Erasing republishes the theme (`themeMode` → 'system', N3) and then resets the
/// route stack, so buttons were being built while MaterialApp's theme animation
/// ran — and light's and dark's button text styles disagreed about `inherit`
/// (`AppFonts` styles are `inherit: true`; the `textTheme` a brightness without a
/// button theme falls back to is `inherit: false`). `TextStyle.lerp` asserts on
/// that pair. It threw inside the button's own `Material`, so the framework
/// substituted a 100,000 px `ErrorWidget` — which is where BOTH reported symptoms
/// come from. Fixed in `AppTheme._buttonTextStyle`.
///
/// What the matrix measured: `flip` — whether the reset actually CHANGES the
/// mode — decided it every time; wipe duration and platform never did. Deferring
/// the republish by a frame was tried and rejected: it moved the crash from the
/// onboarding button to the dialog's.
///
/// Real disk I/O is faked out and nothing else is: a Hive write completes only
/// under `tester.runAsync`, and `runAsync` also lets `AppFonts`' google_fonts
/// downloads reach the 400 the test binding answers with — an unhandled async
/// error with nothing to do with this flow. So the two box wipes are no-ops and
/// the settings wipe overrides `clearStoredSettings` alone; the dialog, the
/// controller, `resetToDefaults` itself, the routing and both real screens are
/// the shipping code.

void main() {
  late Directory tempDir;
  late SettingsService settings;

  final thisMonth = AppDateUtils.getCurrentMonthKey();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_erase');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put<CategoryRepository>(_NoWipeCategoryRepository());
    Get.put<TransactionRepository>(_NoWipeTransactionRepository());
    settings = Get.put<SettingsService>(_NoWipeSettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setMonthlyIncomeMinor(15000000);
    await settings.setCurrentMonth(thisMonth);
    await settings.completeOnboarding();
    await Get.find<CategoryRepository>().addCategory(Category(
      id: 'food',
      name: 'Food',
      budgetLimitMinor: 500000,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: Icons.restaurant.codePoint,
      month: thisMonth,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await Get.find<TransactionRepository>().addTransaction(TransactionItem(
      id: 'txn-1',
      categoryId: 'food',
      amountMinor: 12345,
      note: 'Lunch',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Every combination that mattered while this was diagnosed.
  ///
  /// `flip` is the ingredient that decides it: with the theme mode UNCHANGED by
  /// the reset the flow was always clean, and with it changed the first screen
  /// after an erase was a red panel — at every wipe duration and on both
  /// platforms. Wipe duration and platform are kept anyway, cheaply, because
  /// they are what the diagnosis ruled out.
  for (final probe in [
    (ms: 0, ios: false, flip: false),
    (ms: 60, ios: true, flip: false),
    (ms: 0, ios: false, flip: true),
    (ms: 0, ios: true, flip: true),
    (ms: 60, ios: false, flip: true),
    (ms: 140, ios: true, flip: true),
  ]) {
    final label = 'wipe ${probe.ms}ms · ios=${probe.ios} · flip=${probe.flip}';
    testWidgets('erase lands on a usable onboarding [$label]', (tester) async {
      wipeDuration = Duration(milliseconds: probe.ms);
      if (probe.ios) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      // Published, not persisted: a HiveStorage write is real I/O and would
      // deadlock against the fake clock. What matters is only that the reset
      // changes the live value, exactly as it does on a device whose stored
      // choice is anything but 'system'.
      if (probe.flip) settings.themeMode.value = 'dark';

      await tester.pumpWidget(GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.flutterThemeMode,
        initialRoute: AppRoutes.home,
        getPages: AppPages.pages,
      ));
      await tester.pumpAndSettle();

      Get.toNamed(AppRoutes.settings);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erase All Data'));
      await tester.pumpAndSettle();
      expect(find.text('Erase all data?'), findsOneWidget);

      await tester.tap(find.text('Erase Everything'));
      // Frame by frame rather than one pumpAndSettle, over a window that
      // comfortably outlasts MaterialApp's 200 ms theme animation: the failure
      // this pins arrived a frame or two INTO that animation, and pumpAndSettle
      // would report only the last of the cascade.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        final err = tester.takeException();
        expect(err, isNull,
            reason: 'frame $i of the erase→onboarding transition threw: $err');
      }

      // Symptom 1: no developer error panel. In a release build this subtree
      // renders blank instead of red, so absence — not colour — is the check.
      expect(find.byType(ErrorWidget), findsNothing);
      // Symptom 2: nothing overflows. A RenderFlex overflow is a FlutterError,
      // so the per-frame check above already catches it; this states the
      // promise in its own right — the screen fits.
      expect(tester.takeException(), isNull);

      // And the screen is the one the user was promised: a first-run onboarding
      // with a way forward, not just a headline.
      expect(find.text('Welcome to BuddgetBuddy'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget,
          reason: 'the control below the tagline is what the crash replaced');
      // The theme reset still happened — deferring it by a frame must not drop
      // it (N3).
      expect(settings.themeMode.value, 'system');
      expect(Get.currentRoute, AppRoutes.onboarding);

      debugDefaultTargetPlatformOverride = null;
    });
  }
}
