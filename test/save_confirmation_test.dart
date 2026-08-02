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

  /// A navigator with something on it, so `Get.back()` and `Get.snackbar` have
  /// the stack and the overlay they need.
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(body: Center(child: Text('home'))),
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

    expect(find.text('₨2,450 added to Food'), findsOneWidget,
        reason: 'compact amount, exact category (danish A3)');
    expect(find.text('Undo'), findsOneWidget);

    // AC-1's second half: it goes away on its own.
    await drainSnackbar(tester);
    expect(find.text('₨2,450 added to Food'), findsNothing);
    expect(find.text('Undo'), findsNothing,
        reason: 'AC-4: no ghost affordance once the window has closed');
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
    expect(find.text('₨2,450 added to Food'), findsOneWidget);

    // Well inside the first confirmation's window. Snackbars queue, so without
    // closeCurrentSnackbar this one would appear ~4 s from now still naming
    // ₨2,450 — with an Undo pointing at the first row.
    await logExpense(tester, '800', expectedRows: 2);

    expect(find.text('₨800 added to Food'), findsOneWidget);
    expect(find.text('₨2,450 added to Food'), findsNothing,
        reason: 'the stale confirmation is closed, not queued behind');
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
