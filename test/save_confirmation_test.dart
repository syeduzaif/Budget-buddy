import 'dart:io';

import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-05 — proof the log landed, and four seconds to take it back.
///
/// Saving used to close the sheet in silence. Combined with the pre-F-04
/// dashboard that left no evidence anywhere that the expense existed, which is
/// the shape that invites a second save; and there was no undo in the app at
/// all, so the only correction was find-and-delete.
///
/// Three of these tests exist for GetX mechanics that were measured rather than
/// assumed at get 4.7.3: snackbars QUEUE (so without `closeCurrentSnackbar` a
/// second save's confirmation arrives ~4 s late still naming the first amount,
/// with an Undo pointing at the wrong row), and Undo has to dismiss an overlay
/// rather than pop a route.
///
/// Deliberately pumped WITHOUT the app's theme or any `AppFonts` style. Those
/// getters call `GoogleFonts.*` on every build, each call starts a font
/// download, and `TestWidgetsFlutterBinding` answers every request with 400 —
/// the failure then surfaces as an unhandled async error in whichever zone is
/// running, which `tester.runAsync` (unavoidable here, see [logExpense]) makes
/// reachable. Nothing in this file is about glyphs; the sheet's own rendering is
/// covered in `transaction_edit_test.dart`.
void main() {
  late Directory tempDir;
  late LocalStoreService store;

  final thisMonth = AppDateUtils.getCurrentMonthKey();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_confirm');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    final settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await Get.find<CategoryRepository>().addCategory(Category(
      id: 'food-now',
      name: 'Food',
      budgetLimitMinor: 5000000,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: Icons.restaurant.codePoint,
      month: thisMonth,
      createdAt: DateTime(2026, 1, 1, 9),
      updatedAt: DateTime(2026, 1, 1, 9),
    ));
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The confirmation bar itself — one place to say which widget renders it.
  final confirmationBar = find.byType(GetSnackBar);

  /// Destinations the host's tab bar received while a test ran.
  final navTaps = <int>[];

  /// Taps that reached the page UNDER a confirmation. Must stay empty: the bar
  /// swallows what lands on it, or a tap meant for the bar edits whatever row
  /// happens to be beneath it (the BUG-080 corruption chain).
  var bodyTaps = 0;

  /// A navigator with something on it, so `Get.back()` and `Get.snackbar` have
  /// the stack and the overlay they need.
  ///
  /// The host carries the app's real bottom chrome — a 4-destination
  /// `NavigationBar`, same as `HomeView` — because BUG-080 was a question about
  /// geometry: a confirmation that lands on top of the tab bar absorbs the taps
  /// meant for it, and nothing about that is visible in a host without one.
  Future<void> pumpHost(WidgetTester tester) async {
    navTaps.clear();
    bodyTaps = 0;
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => bodyTaps++,
          child: const Center(child: Text('home')),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: navTaps.add,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline), label: 'Add'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined), label: 'Analytics'),
          ],
        ),
      ),
    ));
  }

  /// Logs [amount] the way the sheet does: a fresh controller, a route standing
  /// in for the sheet, then `save()`.
  ///
  /// `save()` runs inside `runAsync` because a Hive write started on the test's
  /// fake clock only advances while frames are pumped, and one left unfinished
  /// deadlocks `tearDown`'s `Hive.close()` (measured: a ten-minute timeout).
  Future<void> logExpense(WidgetTester tester, String amount,
      {required int expectedRows}) async {
    // The stand-in for the sheet, so the pop `save()` performs pops something.
    Get.to(() => const Scaffold(body: Center(child: Text('sheet'))));
    await tester.pumpAndSettle();

    if (Get.isRegistered<TransactionFormController>()) {
      Get.delete<TransactionFormController>();
    }
    final ctrl = Get.put(TransactionFormController(
      categoryRepo: Get.find<CategoryRepository>(),
      transactionRepo: Get.find<TransactionRepository>(),
      settings: Get.find<SettingsService>(),
    ));
    await tester.pump();
    ctrl.amountController.text = amount;

    await tester.runAsync(() async {
      ctrl.save();
      for (var attempt = 0;
          attempt < 400 && store.readTransactions().length != expectedRows;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      // The write is the middle of save(); the pop and the confirmation follow.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    // Bounded pumps, not pumpAndSettle: a snackbar on screen keeps scheduling
    // frames, so "settled" is not a state this reaches.
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Presses Undo and waits for the delete.
  Future<void> pressUndo(WidgetTester tester, {required int expectedRows}) async {
    final undo =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Undo'));
    await tester.runAsync(() async {
      undo.onPressed!();
      for (var attempt = 0;
          attempt < 400 && store.readTransactions().length != expectedRows;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Lets the confirmation expire, so no `Timer` outlives the test.
  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.pump(TransactionFormController.confirmationDuration);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('AC-1: the confirmation names the amount and the category',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);

    expect(find.text('₨2,450.00 added to Food'), findsOneWidget,
        reason: 'the exact amount, currency-formatted, and the exact category');
    expect(find.text('Undo'), findsOneWidget);

    // AC-1's second half: it goes away on its own.
    await drainSnackbar(tester);
    expect(find.text('₨2,450.00 added to Food'), findsNothing);
    expect(find.text('Undo'), findsNothing,
        reason: 'AC-4: no ghost affordance once the window has closed');
  });

  testWidgets('AC-1: sub-unit amounts are named, not rounded', (tester) async {
    await pumpHost(tester);
    // Leading dot and all — the app accepts it, so the confirmation has to
    // survive it.
    await logExpense(tester, '.50', expectedRows: 1);

    expect(store.readTransactions().single.amountMinor, 50,
        reason: 'the ledger was always right; the bar was the liar (BUG-082)');
    expect(find.text('₨0.50 added to Food'), findsOneWidget);
    expect(find.text('₨1 added to Food'), findsNothing,
        reason: 'the compact formatter rounds half-up, so it announced an '
            'amount that exists nowhere in the data — and anything under ₨0.50 '
            'would have read "₨0 added to Food"');

    await drainSnackbar(tester);
  });

  testWidgets('AC-2: Undo removes the transaction it named', (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    expect(store.readTransactions(), hasLength(1));

    await pressUndo(tester, expectedRows: 0);

    expect(store.readTransactions(), isEmpty,
        reason: 'the row, the Spent total and the category bar all revert');
    expect(find.text('Undo'), findsNothing);
    expect(find.text('home'), findsOneWidget,
        reason: 'Undo dismisses an overlay; Get.back() would have popped the '
            'screen out from under the user');
  });

  testWidgets('AC-3: letting it expire leaves the transaction saved',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    await drainSnackbar(tester);

    expect(store.readTransactions(), hasLength(1));
    expect(store.readTransactions().single.amountMinor, 245000);
  });

  testWidgets('AC-4: Undo is a real target and stays on one line',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);

    final size = tester.getSize(find.widgetWithText(TextButton, 'Undo'));
    expect(size.height, greaterThanOrEqualTo(48.0),
        reason: 'the only way back from a mistake is not a 40dp target');
    expect(tester.widget<Text>(find.text('Undo')).maxLines, 1);

    await drainSnackbar(tester);
  });

  testWidgets('AC-5: two logs back to back each get their own confirmation',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    expect(find.text('₨2,450.00 added to Food'), findsOneWidget);

    // Well inside the first confirmation's window. Snackbars queue, so without
    // closeCurrentSnackbar this one would appear ~4 s from now still naming
    // ₨2,450 — with an Undo pointing at the first row.
    await logExpense(tester, '800', expectedRows: 2);

    expect(find.text('₨800.00 added to Food'), findsOneWidget);
    expect(find.text('₨2,450.00 added to Food'), findsNothing,
        reason: 'the stale confirmation is closed, not queued behind');
    expect(store.readTransactions(), hasLength(2));

    await drainSnackbar(tester);
  });

  testWidgets('AC-5: the tab bar stays live while a confirmation is up',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    expect(find.text('₨2,450.00 added to Food'), findsOneWidget);

    // The rhythm BUG-080 was measured in: the next tab tap comes while the
    // confirmation is still on screen. The bar used to sit ON the tab bar and
    // absorb every touch across its full width for the whole ~5 s window, so
    // this tap reached nothing and nothing said so.
    await tester.tap(find.text('Analytics'));
    await tester.pump();

    expect(navTaps, [3],
        reason: 'a confirmation must never eat the tab bar underneath it');

    // And the reason it does not: the bar is drawn clear of the tab bar.
    final barRect = tester.getRect(confirmationBar);
    final navRect = tester.getRect(find.byType(NavigationBar));
    expect(barRect.bottom, lessThanOrEqualTo(navRect.top),
        reason: 'the confirmation floats above the bottom nav (FD-14)');
    // The margin is computed from a Material default that has no public
    // constant. If Material moves it, this fails HERE rather than by quietly
    // covering the tab bar again on a device.
    expect(navRect.height, TransactionFormController.navigationBarHeight,
        reason: 'no bottom inset in a test window, so this is the bare '
            'NavigationBar height the margin is built from');

    // The other half of FD-14: what lands ON the bar stops there. A bar that
    // let taps through would hand them to the Recent row underneath, which is
    // the edit sheet BUG-080's corruption arrived through.
    final onTheBar = barRect.centerLeft + const Offset(2, 0);
    await tester.tapAt(onTheBar);
    await tester.pump();
    expect(bodyTaps, 0,
        reason: 'a confirmation absorbs its own bounds, and only those');

    // maryam's A/B, as an assertion: the SAME point once the bar has gone. It
    // reaches the page, which is what makes the line above mean something.
    await drainSnackbar(tester);
    expect(confirmationBar, findsNothing);
    await tester.tapAt(onTheBar);
    await tester.pump();
    expect(bodyTaps, 1);
  });

  testWidgets('AC-5: a save under a live confirmation still closes the sheet',
      (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    // Second save inside the first confirmation's window — now reachable,
    // because the tab bar answers taps again.
    await logExpense(tester, '800', expectedRows: 2);

    expect(find.text('sheet'), findsNothing,
        reason: 'get 4.7.3 turns Get.back() into closeCurrentSnackbar() while a '
            'snackbar is open, which would leave the sheet standing over the '
            'dashboard with the money already written');
    expect(find.text('home'), findsOneWidget);
    expect(store.readTransactions(), hasLength(2));

    await drainSnackbar(tester);
  });

  testWidgets('the second confirmation undoes the SECOND save', (tester) async {
    await pumpHost(tester);
    await logExpense(tester, '2450', expectedRows: 1);
    await logExpense(tester, '800', expectedRows: 2);

    await pressUndo(tester, expectedRows: 1);

    expect(store.readTransactions().single.amountMinor, 245000,
        reason: 'a stale id here is the AC-5 failure wearing a different hat');
  });
}
