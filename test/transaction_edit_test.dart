import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_controller.dart';
import 'package:budget_buddy/modules/transaction_form/transaction_form_sheet.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-07 — a typo'd amount is corrected, not deleted and retyped.
///
/// Driven through `openTransactionSheet`, the one door every entry point now
/// uses, and asserted against the Hive box wherever the question is "what was
/// written": the whole point of the feature is that the SAME record changes.
///
/// `GetMaterialApp`, not `MaterialApp` — `Get.back()` needs a navigator it owns
/// and `Get.snackbar` inserts into that navigator's overlay, so the confirmation
/// this feature is specced to show cannot be observed without one.
void main() {
  late Directory tempDir;
  late LocalStoreService store;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late SettingsService settings;

  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  int yearOf(String monthKey) => int.parse(monthKey.split('-')[0]);
  int monthOf(String monthKey) => int.parse(monthKey.split('-')[1]);

  Category category({
    required String id,
    required String name,
    required String month,
    int limitMinor = 500000,
  }) {
    final stamp = DateTime(2026, 1, 1, 9);
    return Category(
      id: id,
      name: name,
      budgetLimitMinor: limitMinor,
      colorValue: 0xFF2D8B8B,
      iconCodePoint: Icons.restaurant.codePoint,
      month: month,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  /// Mid-month, so moving the date a month back never lands outside it.
  final lunchDate = DateTime(yearOf(thisMonth), monthOf(thisMonth), 15, 12);
  final lunchCreatedAt = DateTime(2026, 1, 2, 8);

  TransactionItem lunch() => TransactionItem(
        id: 'txn-1',
        categoryId: 'food-now',
        amountMinor: 90000, // ₨900.00
        note: 'Lunch',
        date: lunchDate,
        createdAt: lunchCreatedAt,
        updatedAt: lunchCreatedAt,
      );

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
    // The amount field autofocuses, and a blinking caret schedules a frame
    // every half second forever, so `pumpAndSettle` would never return.
    EditableText.debugDeterministicCursor = true;
  });

  tearDownAll(() => EditableText.debugDeterministicCursor = false);

  // Seeding lives HERE, not in the test bodies: a `testWidgets` body runs on a
  // fake clock, so a real Hive write awaited inside one never completes.
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_edit');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    store = await LocalStoreService().init();
    Get.put<LocalStoreService>(store);
    categories = Get.put(CategoryRepository());
    transactions = Get.put(TransactionRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await categories.addCategories([
      category(id: 'food-now', name: 'Food', month: thisMonth),
      category(id: 'health-now', name: 'Health', month: thisMonth),
    ]);
    await transactions.addTransaction(lunch());
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  TransactionFormController formController() =>
      Get.find<TransactionFormController>();

  /// A host with one button, so the sheet is opened the way the app opens it.
  Future<void> pumpHost(WidgetTester tester, {TransactionItem? editing}) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => openTransactionSheet(context, editing: editing),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Presses the sheet's save button — its real `onPressed`, validator and all
  /// — and waits for the write to land.
  ///
  /// Deliberately NOT `tester.tap`. A widget test body runs on a fake clock, so
  /// a Hive write started there can only advance while frames are being pumped;
  /// leave one unfinished and `tearDown`'s `Hive.close()` waits on a lock that
  /// nothing will ever release (measured: a ten-minute test timeout). Inside
  /// `runAsync` the same callback runs on the real event loop and simply
  /// finishes. [until] is the caller's proof that it did.
  ///
  /// Anything a widget test here does that writes to a box belongs in this
  /// shape.
  Future<void> pressSave(WidgetTester tester, String label,
      {required bool Function() until}) async {
    final button =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));
    expect(button.onPressed, isNotNull, reason: 'the save button must be live');
    await tester.runAsync(() async {
      button.onPressed!();
      for (var attempt = 0; attempt < 400 && !until(); attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      // The write is only the middle of `save()`. Stay in the real zone long
      // enough for the rest of it — the pop, then the confirmation — or the
      // test ends with the sheet's own navigator already torn down.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    // Bounded pumps, not `pumpAndSettle`: the confirmation snackbar keeps
    // scheduling frames for as long as it is on screen, so "settled" is not a
    // state this screen reaches. 2.4 s covers the sheet's pop and the
    // snackbar's entrance.
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Lets a confirmation snackbar live out its display window: it owns a
  /// `Timer`, and a test that ends with one pending fails.
  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.pump(TransactionFormController.confirmationDuration);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  group('opening a row (AC-1)', () {
    testWidgets('the sheet arrives prefilled and named for editing',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Add Transaction'), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Save Transaction'), findsNothing);

      // Major-unit text the field can parse back, not the stored "90000".
      expect(find.widgetWithText(TextFormField, '900'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Lunch'), findsOneWidget);
      // Its own category and its own date, not the month's first and today.
      expect(formController().selectedCategory.value?.id, 'food-now');
      expect(formController().selectedDate.value, lunchDate);
    });

    testWidgets('the prefilled amount arrives selected, so typing replaces it',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      final amount = find.widgetWithText(TextFormField, '900');
      final editable = tester.widget<EditableText>(
          find.descendant(of: amount, matching: find.byType(EditableText)));
      expect(editable.focusNode.hasFocus, isTrue,
          reason: 'the sheet autofocuses the amount, which is what makes the '
              'selection the thing the keyboard types over');
      expect(formController().amountController.selection,
          const TextSelection(baseOffset: 0, extentOffset: 3),
          reason: 'BUG-081: a focused prefill with the caret at the end '
              'APPENDS — 900 then "120" saved ₨900,120, and that append is the '
              "amplifier in BUG-080's corruption chain");
    });

    testWidgets('without a record it is still the Add sheet', (tester) async {
      await pumpHost(tester);

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Save Transaction'), findsOneWidget);
      expect(formController().isEditing, isFalse);
      expect(formController().amountController.text, isEmpty,
          reason: 'nothing leaks from a previous edit');
      expect(formController().amountController.selection.isCollapsed, isTrue,
          reason: 'nothing to select in an empty field: create mode is '
              'untouched by the edit-mode select-all');
    });
  });

  group('saving the edit', () {
    testWidgets('AC-2: the amount changes on the SAME record', (tester) async {
      await pumpHost(tester, editing: lunch());

      await tester.enterText(find.widgetWithText(TextFormField, '900'), '1250');
      await pressSave(tester, 'Save Changes',
          until: () => store.readTransactions().single.amountMinor == 125000);

      final rows = store.readTransactions();
      expect(rows, hasLength(1), reason: 'an edit is not a second record');
      expect(rows.single.id, 'txn-1');
      expect(rows.single.amountMinor, 125000);
      expect(rows.single.note, 'Lunch', reason: 'untouched fields survive');
      expect(rows.single.date, lunchDate);
      expect(rows.single.categoryId, 'food-now');
      expect(rows.single.createdAt, lunchCreatedAt,
          reason: "a correction does not restart the record's history");
      expect(rows.single.updatedAt.isAfter(lunchCreatedAt), isTrue);

      await drainSnackbar(tester);
    });

    testWidgets('AC-5: the confirmation names the new amount, with no Undo',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      await tester.enterText(find.widgetWithText(TextFormField, '900'), '1250');
      await pressSave(tester, 'Save Changes',
          until: () => store.readTransactions().single.amountMinor == 125000);

      expect(find.text('Updated — ₨1,250.00 in Food'), findsOneWidget);
      expect(find.text('Undo'), findsNothing,
          reason: 'the sheet reopens on a tap — one safety mechanism per '
              'action (F-07 rule 3)');
      expect(find.text('Edit Transaction'), findsNothing,
          reason: 'the sheet closed only after the write landed');

      await drainSnackbar(tester);
    });

    testWidgets('an edit that breaks the budget says so (BUG-101)',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      // Food's limit is ₨5,000; the row was ₨900 and is the month's only spend.
      await tester.enterText(find.widgetWithText(TextFormField, '900'), '6000');
      await pressSave(tester, 'Save Changes',
          until: () => store.readTransactions().single.amountMinor == 600000);

      expect(find.text('Updated — ₨6,000.00 in Food · Over by ₨1,000.00'),
          findsOneWidget,
          reason: 'an edit can break a budget as surely as a new expense, and '
              'the words are BudgetStatus\'s — the same ones the card uses');

      await drainSnackbar(tester);
    });

    testWidgets('AC-3: re-pointing to another category moves the whole amount',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      // By its label: every money field on the sheet is an InputDecorator too.
      await tester.tap(find.widgetWithText(InputDecorator, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(SimpleDialog), matching: find.text('Health')));
      await tester.pumpAndSettle();

      await pressSave(tester, 'Save Changes',
          until: () =>
              store.readTransactions().single.categoryId == 'health-now');

      final row = store.readTransactions().single;
      expect(row.categoryId, 'health-now');
      expect(row.amountMinor, 90000,
          reason: 'the month total is unchanged — the money only moved rows');

      await drainSnackbar(tester);
    });

    testWidgets('AC-4: a date moved into last month re-points with it',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      // The state `showDatePicker` would have set. The picker is Flutter's;
      // what F-07 owns is what save() does with the answer.
      formController()
          .selectDate(DateTime(yearOf(lastMonth), monthOf(lastMonth), 10, 12));
      await tester.pumpAndSettle();

      await pressSave(tester, 'Save Changes',
          until: () =>
              AppDateUtils.getMonthKeyFromDate(
                  store.readTransactions().single.date) ==
              lastMonth);

      final row = store.readTransactions().single;
      expect(row.id, 'txn-1');

      final landedOn =
          store.readCategories().firstWhere((c) => c.id == row.categoryId);
      expect(landedOn.month, lastMonth,
          reason: "INV-1: a transaction belongs to a category of its own "
              "date-month, never another month's clone");
      expect(landedOn.name, 'Food');
      expect(landedOn.id, isNot('food-now'));

      await drainSnackbar(tester);
    });

    testWidgets('AC-6: dismissing without saving changes nothing',
        (tester) async {
      await pumpHost(tester, editing: lunch());

      await tester.enterText(find.widgetWithText(TextFormField, '900'), '4242');
      // What tapping the scrim or swiping the sheet down does.
      Get.back();
      await tester.pumpAndSettle();

      final row = store.readTransactions().single;
      expect(row.amountMinor, 90000);
      expect(row.note, 'Lunch');
      expect(find.text('Edit Transaction'), findsNothing);
    });
  });

  group('creating still works through the shared door', () {
    testWidgets('a new record is added, not an existing one overwritten',
        (tester) async {
      await pumpHost(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'), '250');
      await pressSave(tester, 'Save Transaction',
          until: () => store.readTransactions().length == 2);

      final rows = store.readTransactions();
      expect(rows, hasLength(2));
      expect(rows.map((t) => t.amountMinor).toSet(), {90000, 25000});
      // A create gets F-05's confirmation, not this one — and that one carries
      // an Undo, which an edit deliberately does not.
      expect(find.textContaining('Updated —'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      await drainSnackbar(tester);
    });
  });
}
