import 'dart:async';
import 'dart:io';

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/modules/dashboard/widgets/category_budget_list.dart';
import 'package:budget_buddy/modules/dashboard/widgets/recent_transactions_card.dart';
import 'package:budget_buddy/modules/dashboard/widgets/summary_card.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// [LocalStoreService] with the disk taken out, and the reason it has to exist.
///
/// The rest of this file drives real Hive, which means every write must run
/// inside `tester.runAsync` — and `runAsync` is exactly what lets `AppFonts`'
/// google_fonts requests reach the test binding's canned 400 and fail the test
/// (the trap the header describes). The GAP-014 (ii) test has to render the
/// real dashboard, so it cannot avoid `AppFonts`; it therefore avoids
/// `runAsync` instead, and the only way to do that is to take the real I/O out.
/// Measured before choosing this: with real Hive the test failed on font
/// exceptions at every timing tried, including zero-length waits and a bounded
/// poll — the two constraints are structurally incompatible, not a matter of
/// tuning.
///
/// Both REPOSITORIES stay real, which is where the behaviour under test lives
/// (`resolveForMonth`, `ensureUncategorised`, month scoping, sorting). Only the
/// thirteen box calls are re-pointed at two maps, with the same ordering
/// contracts the shipped service documents: categories newest-first by
/// `createdAt`, transactions newest-first by `date`, and every watcher gets the
/// current contents immediately and again after each mutation.
class _InMemoryStore extends LocalStoreService {
  final Map<String, Category> _cats = {};
  final Map<String, TransactionItem> _txns = {};
  final _catStreams = <StreamController<List<Category>>>[];
  final _txnStreams = <StreamController<List<TransactionItem>>>[];

  @override
  Future<LocalStoreService> init() async => this;

  void _publish() {
    for (final c in _catStreams) {
      if (!c.isClosed) c.add(readCategories());
    }
    for (final t in _txnStreams) {
      if (!t.isClosed) t.add(readTransactions());
    }
  }

  @override
  List<Category> readCategories() {
    final list = _cats.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<Category>> watchCategories() {
    late final StreamController<List<Category>> c;
    c = StreamController<List<Category>>(
      onListen: () => c.add(readCategories()),
      onCancel: () => _catStreams.remove(c),
    );
    _catStreams.add(c);
    return c.stream;
  }

  @override
  Future<void> putCategory(Category category) async {
    _cats[category.id] = category;
    _publish();
  }

  @override
  Future<void> putCategories(List<Category> categories) async {
    for (final c in categories) {
      _cats[c.id] = c;
    }
    _publish();
  }

  @override
  Future<void> deleteCategory(String id) async {
    _cats.remove(id);
    _publish();
  }

  @override
  Future<void> clearCategories() async {
    _cats.clear();
    _publish();
  }

  @override
  List<Category> readCategoriesForMonth(String month) =>
      readCategories().where((c) => c.month == month).toList();

  @override
  List<TransactionItem> readTransactions() {
    final list = _txns.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<List<TransactionItem>> watchTransactions() {
    late final StreamController<List<TransactionItem>> c;
    c = StreamController<List<TransactionItem>>(
      onListen: () => c.add(readTransactions()),
      onCancel: () => _txnStreams.remove(c),
    );
    _txnStreams.add(c);
    return c.stream;
  }

  @override
  Future<void> putTransaction(TransactionItem transaction) async {
    _txns[transaction.id] = transaction;
    _publish();
  }

  @override
  Future<void> putTransactions(Iterable<TransactionItem> transactions) async {
    for (final t in transactions) {
      _txns[t.id] = t;
    }
    _publish();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _txns.remove(id);
    _publish();
  }

  @override
  Future<void> clearTransactions() async {
    _txns.clear();
    _publish();
  }
}

/// The one settings write `save()` makes (`rememberLastUsedCategory`, F-06) is
/// real disk I/O on the settings box, and would reintroduce the `runAsync` the
/// store seam exists to remove. Everything else about the service is shipped
/// code — same narrow-seam approach as `erase_flow_test`'s
/// `clearStoredSettings` override.
class _NoDiskSettingsService extends SettingsService {
  @override
  Future<void> rememberLastUsedCategory(String name) async {}
}

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
///
/// ONE exception, added 2026-08-05: the GAP-014 test pumps the real
/// `DashboardView`, because its whole subject is what the user is looking at.
/// "The record is gone from the box" and "the screen stopped showing the money"
/// are different claims, and the second was the one nobody had asserted.
void main() {
  late Directory tempDir;
  late LocalStoreService store;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);
  final lastMonthStart = AppDateUtils.parseMonthKey(lastMonth)!;
  // Mid-month, so no timezone edge can drag the date into a neighbouring key.
  final lastMonthDate =
      DateTime(lastMonthStart.year, lastMonthStart.month, 14);

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
  ///
  /// [date] sets the sheet's date field, i.e. the month attribution follows
  /// (CR-1). [beforeSave] runs in the real zone immediately before the save, for
  /// the one scenario that needs the store mutated while the sheet is open.
  Future<void> logExpense(WidgetTester tester, String amount,
      {required int expectedRows,
      String? categoryId,
      DateTime? date,
      Future<void> Function()? beforeSave}) async {
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
    if (categoryId != null) {
      final picked = ctrl.categories.where((c) => c.id == categoryId);
      expect(picked, isNotEmpty,
          reason: "the picker has loaded the month's categories by now");
      ctrl.selectCategory(picked.first);
    }
    ctrl.amountController.text = amount;
    if (date != null) ctrl.selectDate(date);

    await tester.runAsync(() async {
      if (beforeSave != null) await beforeSave();
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
  ///
  /// A real `tester.tap` on the RENDERED button, not `onPressed!()` — GAP-014
  /// condition (i). Firing the callback proves the callback; it says nothing
  /// about whether the button can be hit where it is actually drawn, which is
  /// the half that changed under it.
  ///
  /// **The diff fact** (GAP-014 condition (iii)), read off `git diff 57cc309..HEAD`
  /// rather than assumed. Since T-12 `57cc309` — the commit that introduced
  /// Undo, and the build maryam's one successful live tap was made against —
  /// the CALLBACK wiring is unchanged: `_undoCreate`'s body, and the
  /// `TextButton(onPressed: () => _undoCreate(undoId), minimumSize (64,48),
  /// Text('Undo'))` it hangs on, are byte-identical. `mainButton: action` moved
  /// verbatim out of `_confirm` and into `_showAboveTabBar` in BUG-080
  /// (`abc3ee0`) and was not otherwise touched.
  ///
  /// What that same commit DID change is the geometry the button is rendered
  /// at: `margin: confirmationMargin` (bottom = `navigationBarHeight + 8`) and
  /// `isDismissible: false`. So the live evidence was gathered at coordinates
  /// that no longer exist, and it is exactly the reachability half that no
  /// callback-level test can carry. Hence the tap.
  /// The tap happens INSIDE `runAsync`, which is the only arrangement that
  /// works and took three attempts to find. `_undoCreate` awaits a Hive
  /// delete, and a Hive write begun on the fake clock never finishes — it
  /// leaves `tearDown`'s `Hive.close()` blocked past a ten-minute timeout,
  /// measured twice here (once waiting only in `runAsync`, once alternating
  /// `pump` and `runAsync` 200 times). [logExpense] hit the same wall from the
  /// other side and solved it the same way: start the write in the real zone.
  /// `tester.tap` dispatches a pointer without pumping, so it is legal there;
  /// `pumpAndSettle` would not be.
  Future<void> pressUndo(WidgetTester tester,
      {required int expectedRows}) async {
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, 'Undo'));
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
  ///
  /// **This must run even when an expectation fails**, which is why the CR-1
  /// tests below wrap their assertions in `try/finally`. GetX's
  /// `_SnackBarQueue` is a STATIC field on `SnackbarController` and strictly
  /// serial: a bar left up blocks every LATER test in the file from ever
  /// showing one, so a single genuinely-red test reports as four (measured
  /// while landing CR-1 — the shipped GAP-014 test went red too, for no reason
  /// of its own). It is a false RED, never a false green, but it buries the
  /// cause.
  ///
  /// `Get.closeAllSnackbars()` in `tearDown` does NOT cure it, measured: it
  /// awaits `close()`, which calls `_controller.reverse()` and waits for the
  /// animation to reach `dismissed` before `_removeOverlay()` completes the
  /// transition future — and by `tearDown` the widget tree is gone, so that
  /// controller's ticker never advances again and the queue stays blocked
  /// forever (get 4.7.3 `snackbar_controller.dart:49-56,302-327,362-366`).
  /// The drain has to happen inside the test body, while the tree is alive.
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

  group('breaking a budget (BUG-101)', () {
    /// waqas' numbers: Cricket, ₨2,000 limit, ₨1,400 already spent.
    Future<void> seedCricket(WidgetTester tester) async {
      final stamp = DateTime(2026, 1, 1, 9);
      await tester.runAsync(() async {
        await Get.find<CategoryRepository>().addCategory(Category(
          id: 'cricket-now',
          name: 'Cricket',
          budgetLimitMinor: 200000,
          colorValue: 0xFF2D8B8B,
          iconCodePoint: Icons.sports_cricket.codePoint,
          month: thisMonth,
          createdAt: stamp,
          updatedAt: stamp,
        ));
        await Get.find<TransactionRepository>().addTransaction(TransactionItem(
          id: 'grip',
          categoryId: 'cricket-now',
          amountMinor: 140000,
          note: 'grip tape',
          date: DateTime.now(),
          createdAt: stamp,
          updatedAt: stamp,
        ));
      });
      await tester.pump();
    }

    testWidgets('the confirmation says so, in F-09\'s words', (tester) async {
      await pumpHost(tester);
      await seedCricket(tester);

      await logExpense(tester, '900',
          expectedRows: 2, categoryId: 'cricket-now');

      // ₨1,400 + ₨900 against a ₨2,000 limit. The wording is BudgetStatus's,
      // i.e. the category card's, so the bar and the card cannot disagree.
      expect(find.text('₨900.00 added to Cricket · Over by ₨300.00'),
          findsOneWidget);
      // Still undoable: the news does not cost the affordance.
      expect(find.text('Undo'), findsOneWidget);

      await drainSnackbar(tester);
    });

    testWidgets('a save that stays inside the budget says nothing',
        (tester) async {
      await pumpHost(tester);
      await seedCricket(tester);

      await logExpense(tester, '400',
          expectedRows: 2, categoryId: 'cricket-now');

      expect(find.text('₨400.00 added to Cricket'), findsOneWidget,
          reason: '₨1,800 of ₨2,000 is the WARNING rung, and that copy belongs '
              "to danish's three-state spec, not to this fix");

      await drainSnackbar(tester);
    });

    testWidgets('an undo of the save that broke it needs no second message',
        (tester) async {
      await pumpHost(tester);
      await seedCricket(tester);
      await logExpense(tester, '900',
          expectedRows: 2, categoryId: 'cricket-now');

      await pressUndo(tester, expectedRows: 1);

      expect(store.readTransactions().single.id, 'grip',
          reason: 'the row that broke the budget is the row that goes');
      expect(find.textContaining('Over by'), findsNothing);
    });
  });
  /// CR-1 — money that lands in a month the user is not looking at says so.
  ///
  /// The picker is filtered to the VIEWED month while the date field accepts
  /// any day back to 2020, and attribution correctly follows the DATE (F-01
  /// rule 2). Nothing here changes that: `resolveForMonth` is untouched, and
  /// the first assertion in each test re-checks that the money still lands on a
  /// category stamped with the transaction's own month.
  ///
  /// What was missing was the disclosure. The confirmation named the category
  /// by string only — "₨2,450.00 added to Food" — while the row actually
  /// charged was a DIFFERENT Food, in a month the user could not see, with its
  /// own limit and its own history. Worse, `_overBudgetNote` is (correctly)
  /// computed against that other month, so the bar could read "Over by ₨300"
  /// about a month the dashboard behind it says nothing about.
  group('money filed in another month (CR-1)', () {
    /// The line the app is obliged to add, built from the same formatter the
    /// app uses, so the two cannot drift.
    final elsewhere = 'Counted in ${AppDateUtils.formatMonthKey(lastMonth)} — '
        'the month it is dated.';

    testWidgets('a back-dated save names the month the money landed in',
        (tester) async {
      await pumpHost(tester);
      await logExpense(tester, '2450',
          expectedRows: 1, categoryId: 'food-now', date: lastMonthDate);

      // try/finally so the bar is drained even when an expectation throws —
      // see [drainSnackbar]. Without it this one red test reports as four.
      try {
        // F-01 still governs attribution, and still gets it right: the row is
        // charged to a category stamped with the DATE's month, not to the
        // viewed month's "Food" that the picker displayed.
        final saved = store.readTransactions().single;
        final charged =
            store.readCategories().firstWhere((c) => c.id == saved.categoryId);
        expect(charged.month, lastMonth);
        expect(charged.name, 'Food');
        expect(charged.id, isNot('food-now'),
            reason: 'a different row of the same name — which is exactly why '
                'naming the category alone was not enough');

        // The disclosure. Without it the user is told the money went to "Food"
        // and left looking at a month whose Spent will not move.
        expect(find.text('₨2,450.00 added to Food'), findsOneWidget);
        expect(find.text(elsewhere), findsOneWidget);
        // Saying more does not cost the affordance F-05 AC-2 depends on.
        expect(find.text('Undo'), findsOneWidget);
      } finally {
        await drainSnackbar(tester);
      }
    });

    testWidgets('a save inside the month on screen stays silent',
        (tester) async {
      await pumpHost(tester);
      await logExpense(tester, '2450', expectedRows: 1, categoryId: 'food-now');

      try {
        expect(find.text('₨2,450.00 added to Food'), findsOneWidget);
        expect(find.textContaining('Counted in'), findsNothing,
            reason: 'nothing moved out of view, so there is nothing to '
                'disclose — a line on every save is noise, and noise is unread');
      } finally {
        await drainSnackbar(tester);
      }
    });

    testWidgets('a deleted category and a back-date are BOTH disclosed',
        (tester) async {
      await pumpHost(tester);
      await logExpense(tester, '2450',
          expectedRows: 1,
          categoryId: 'food-now',
          date: lastMonthDate,
          beforeSave: () =>
              Get.find<CategoryRepository>().deleteCategory('food-now'));

      try {
        // Two surprises, two sentences: the established stale-category message
        // (F-01 rule 5) must not swallow the month, and the month must not
        // swallow it — the deleted branch returns early, so composing them is
        // a deliberate act, not something that falls out.
        expect(
            find.text('Saved to $kUncategorisedCategoryName'), findsOneWidget);
        expect(
            find.text('That category was deleted. $elsewhere'), findsOneWidget);
        expect(
            store.readTransactions().single.categoryId,
            store
                .readCategories()
                .firstWhere((c) =>
                    c.month == lastMonth && isReservedCategoryName(c.name))
                .id,
            reason: "the bucket it landed in is the DATE-month's, not the "
                "viewed month's (F-01 AC-3b)");
      } finally {
        await drainSnackbar(tester);
      }
    });
  });

  // ─── GAP-014 (ii) ─────────────────────────────────────────────────────────
  //
  // The test above proves the record leaves the store. This one covers the
  // failure mode palwasha named the weakest evidence in the feature: the record
  // is deleted and the screen keeps showing the money. Until now that claim
  // lived in a `reason:` string — "the row, the Spent total and the category
  // bar all revert" — and in nothing that could fail.
  group('AC-2 (GAP-014 ii): Undo reverts the SCREEN, not just the box', () {
    late _InMemoryStore memory;

    setUp(() async {
      // `Get.put` does NOT overwrite a type that is already registered — it
      // returns the existing instance, which is why [logExpense] deletes the
      // form controller before putting one. So the outer setUp's real,
      // Hive-backed registrations have to be cleared, not shadowed: without
      // this the whole test runs against real disk, `save()` never completes on
      // the fake clock, and the in-memory store stays empty while the screen
      // shows nothing. Store first — a repository captures
      // `Get.find<LocalStoreService>()` at construction.
      Get.reset();
      memory = _InMemoryStore();
      Get.put<LocalStoreService>(memory);
      Get.put(CategoryRepository());
      Get.put(TransactionRepository());
      final settings = Get.put<SettingsService>(_NoDiskSettingsService());
      // Still on the real settings box, but written here in the real zone —
      // nothing during the test touches it.
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

    testWidgets('the Spent total and the category row both go back',
        (tester) async {
      Get.put(DashboardController(
        categoryRepo: Get.find<CategoryRepository>(),
        transactionRepo: Get.find<TransactionRepository>(),
        settings: Get.find<SettingsService>(),
      ));
      await tester.pumpWidget(GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const DashboardView(),
          // The same bottom chrome as [pumpHost]: `confirmationMargin` is
          // computed from it, and Undo has to be tappable clear of it.
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
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
      await tester.pumpAndSettle();

      // Both figures are read where the user reads them. Scoped, because the
      // Recent row renders the same amount string and would satisfy a loose
      // finder without the dashboard's totals having moved at all.
      Finder spentCard(String amount) => find.descendant(
            of: find.widgetWithText(SummaryCard, 'Spent'),
            matching: find.text(amount),
          );
      // The budgets card prints whole major units (`formatAmountCompact`).
      Finder budgetRow(String spendOverLimit) => find.descendant(
            of: find.byType(CategoryBudgetList),
            matching: find.text(spendOverLimit),
          );

      expect(spentCard('₨0.00'), findsOneWidget);
      expect(budgetRow('₨0 / ₨50,000'), findsOneWidget);

      // The shipped save path, on the fake clock throughout.
      Get.to(() => const Scaffold(body: Center(child: Text('sheet'))));
      await tester.pumpAndSettle();
      final form = Get.put(TransactionFormController(
        categoryRepo: Get.find<CategoryRepository>(),
        transactionRepo: Get.find<TransactionRepository>(),
        settings: Get.find<SettingsService>(),
      ));
      await tester.pump();
      form.amountController.text = '2450';
      form.save();
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(memory.readTransactions(), hasLength(1));
      expect(find.text('₨2,450.00 added to Food'), findsOneWidget);
      expect(spentCard('₨2,450.00'), findsOneWidget,
          reason: 'the money is on the screen BEFORE Undo — without this the '
              'assertions after it would pass on a dashboard that never moved');
      expect(budgetRow('₨2,450 / ₨50,000'), findsOneWidget);

      // GAP-014 (i) again, and here it is the whole point: the rendered
      // button, hit at the shipped margin, over a real dashboard.
      await tester.tap(find.widgetWithText(TextButton, 'Undo'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(memory.readTransactions(), isEmpty);
      expect(spentCard('₨0.00'), findsOneWidget,
          reason: 'GAP-014 (ii): the Spent total reverts ON SCREEN. A delete '
              'the dashboard does not notice spends the money twice in the '
              "user's head");
      expect(budgetRow('₨0 / ₨50,000'), findsOneWidget,
          reason: "GAP-014 (ii): and so does the category's row");
      expect(spentCard('₨2,450.00'), findsNothing);
      expect(find.byType(RecentTransactionsCard), findsNothing,
          reason: 'the row it named is gone from Recent too — F-05 rule 2 is '
              'that the disappearance IS the message, so there is no second '
              'snackbar to look for');
    });
  });
}
