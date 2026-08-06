import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/modules/onboarding/onboarding_controller.dart';
import 'package:budget_buddy/routes/app_pages.dart';
import 'package:budget_buddy/routes/app_routes.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// D-009 — the picker opens on PKR, and the user can see that it does.
///
/// Two halves, and the second is the one that makes the first mean anything.
/// PKR is entry 13 of 23 in a 2-across grid — row 7, ~490dp down a viewport
/// around 500dp tall — so flipping the default alone would change a value the
/// user never sees, and a first-run user who sees nothing highlighted taps the
/// top-left cell, which is USD: exactly the outcome D-009 exists to prevent.
///
/// The refused fix is recorded here too: `CurrencyUtils.currencies` was NOT
/// reordered. That list carries the ISO-4217 `decimalDigits` for every code, so
/// letting a picker's layout reorder it couples money formatting to a cosmetic
/// preference. The picker scrolls instead.
void main() {
  late Directory tempDir;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    Get.testMode = true;
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_currency');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(SettingsService());
  });

  tearDown(() async {
    Get.reset();
    Get.testMode = false;
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('the default and the fallback are different settings', () {
    test('AC-D009-1: a fresh onboarding controller starts on PKR', () {
      expect(OnboardingController().selectedCurrency.value.code, 'PKR');
    });

    test('an unknown or absent stored code still resolves to USD', () {
      // The half D-009 deliberately did not touch. `hive_storage.dart:92` and
      // `CurrencyUtils.resolve` answer "how do I interpret a value I cannot
      // read", which is a data rule; the onboarding default answers "which
      // market is this build for". Moving the market choice must not move the
      // data rule — a currency read back wrong is a currency whose
      // `decimalDigits` are wrong, i.e. a money bug.
      expect(CurrencyUtils.resolve('XYZ').code, 'USD');
      expect(CurrencyUtils.resolve(null).code, 'USD');
      expect(HiveStorage.getCurrencyCode(), 'USD',
          reason: 'the settings box has never been written in this test');
    });

    test('PKR has exactly one record, and it is the one in the list', () {
      final fromList =
          CurrencyUtils.currencies.where((c) => c.code == 'PKR').toList();
      expect(fromList, hasLength(1));
      expect(identical(fromList.single, CurrencyUtils.pkr), isTrue,
          reason: 'declared once and referenced, so the picker default and the '
              'ISO-4217 decimalDigits entry can never disagree');
      expect(CurrencyUtils.pkr.decimalDigits, 2);
    });

    test('the list order is untouched — USD first, PKR thirteenth', () {
      // Pinned because reordering was the tempting fix and is the forbidden
      // one: this list IS the decimalDigits table.
      expect(CurrencyUtils.currencies.first.code, 'USD');
      expect(CurrencyUtils.currencies.indexWhere((c) => c.code == 'PKR'), 12);
      expect(CurrencyUtils.currencies, hasLength(23));
    });
  });

  group('AC-D009-2: the preselected tile is on screen without scrolling', () {
    Future<void> pumpCurrencyPage(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GetMaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        getPages: [
          AppPages.pages.firstWhere((p) => p.name == AppRoutes.onboarding),
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Center(child: Text('HOME'))),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    }

    /// The grid's own viewport, which is what "unscrolled" is measured
    /// against — not the window, which includes the header and the Next button.
    Rect gridViewport(WidgetTester tester) =>
        tester.getRect(find.byType(GridView));

    for (final device in [
      // A short phone is the case that matters: on a tall one the offset is 0
      // and this test proves the grid was left alone.
      ('small', const Size(360, 640)),
      ('tall', const Size(430, 932)),
    ]) {
      testWidgets('${device.$1} screen', (tester) async {
        await pumpCurrencyPage(tester, device.$2);

        final pkrTile = find.ancestor(
          of: find.text('PKR'),
          matching: find.byType(InkWell),
        );
        expect(pkrTile, findsOneWidget,
            reason: 'a lazy grid does not build a tile that is nowhere near '
                'the viewport, so merely FINDING it is already part of the '
                'assertion');

        final tile = tester.getRect(pkrTile);
        final viewport = gridViewport(tester);
        expect(tile.top, greaterThanOrEqualTo(viewport.top - 0.5),
            reason: 'PKR is not clipped off the top of the grid');
        expect(tile.bottom, lessThanOrEqualTo(viewport.bottom + 0.5),
            reason: 'PKR is not below the fold — a default nobody can see is '
                'not a default');

        // And it is visibly THE selection, not just present: the selected tile
        // is the only one painted on primaryDark.
        final decoration = tester
            .widget<Container>(find.descendant(
                of: pkrTile, matching: find.byType(Container)))
            .decoration as BoxDecoration;
        expect(decoration.color, isNot(Colors.transparent));
      });
    }

    testWidgets('the top of the list is still reachable', (tester) async {
      // The cost of scrolling to the selection is that the grid no longer
      // starts at row 1. It must still be an ordinary scrollable — USD is not
      // lost, just above.
      await pumpCurrencyPage(tester, const Size(360, 640));

      await tester.drag(find.byType(GridView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('tapping another currency does not yank the grid',
        (tester) async {
      // The offset is applied once, at attach. Re-creating the controller on
      // every selection change would scroll the list under the user's finger
      // the moment they picked something.
      await pumpCurrencyPage(tester, const Size(360, 640));
      final before = tester.getRect(find.ancestor(
        of: find.text('PKR'),
        matching: find.byType(InkWell),
      ));

      await tester.tap(find.text('AED'));
      await tester.pumpAndSettle();

      final after = tester.getRect(find.ancestor(
        of: find.text('PKR'),
        matching: find.byType(InkWell),
      ));
      expect(after, before);
      expect(Get.find<OnboardingController>().selectedCurrency.value.code,
          'AED');
    });
  });
}
