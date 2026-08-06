import 'dart:io';

import 'package:budget_buddy/core/theme/app_colors.dart';
import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/data/local/hive_storage.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/data/models/transaction_item.dart';
import 'package:budget_buddy/data/repositories/category_repository.dart';
import 'package:budget_buddy/data/repositories/transaction_repository.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_controller.dart';
import 'package:budget_buddy/modules/dashboard/dashboard_view.dart';
import 'package:budget_buddy/modules/dashboard/widgets/summary_card.dart';
import 'package:budget_buddy/services/app/settings_service.dart';
import 'package:budget_buddy/services/local/local_store_service.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// F-04 AC-D010-1 / AC-D010-2 (D-010) — the summary pair withholds figures it
/// cannot derive, and gives them back the moment it can.
///
/// On the shortest path through onboarding — "Skip for now" at the income step,
/// then one ₨50 expense — the dashboard showed `Monthly Income ₨0.00`, a Spent
/// card correctly staying neutral (D-020), and eight pixels away a `Remaining
/// −₨50.00` in error red. Two cards disagreeing about whether income is known,
/// one of them asserting a deficit computed from a zero the user deliberately
/// skipped.
///
/// AC-D010-2 is the case that matters and is written first in each group's
/// mind: without it, an implementation that hides Remaining PERMANENTLY passes
/// AC-D010-1. Same principle as the `kUncategorisedColorValue` source guard —
/// an AC that only proves the new state is an AC a wrong fix satisfies.
///
/// The card is never suppressed, and one test asserts that outright: palwasha
/// refused suppression explicitly, and the shipped comment barring it was
/// written for this exact case.
void main() {
  final thisMonth = AppDateUtils.getCurrentMonthKey();
  final lastMonth = AppDateUtils.getPreviousMonthKey(thisMonth);

  int yearOf(String m) => int.parse(m.split('-')[0]);
  int monthOf(String m) => int.parse(m.split('-')[1]);
  DateTime midMonth(String m) => DateTime(yearOf(m), monthOf(m), 14, 12);

  Category food(String month) => Category(
        id: 'food-$month',
        name: 'Food',
        budgetLimitMinor: 500000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: month,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

  TransactionItem expense(int amountMinor, {String? month}) {
    final when = midMonth(month ?? thisMonth);
    return TransactionItem(
      id: 'e$amountMinor-${month ?? thisMonth}',
      categoryId: 'food-${month ?? thisMonth}',
      amountMinor: amountMinor,
      note: 'Biryani',
      date: when,
      createdAt: when,
      updatedAt: when,
    );
  }

  late Directory tempDir;
  late SettingsService settings;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('buddgetbuddy_income0');
    Hive.init(tempDir.path);
    await HiveStorage.openSettings();
    Get.put<LocalStoreService>(await LocalStoreService().init());
    Get.put(CategoryRepository());
    Get.put(TransactionRepository());
    settings = Get.put(SettingsService());
    await settings.setCurrency('PKR', '₨');
    await settings.setCurrentMonth(thisMonth);
    await Get.find<CategoryRepository>()
        .addCategories([food(thisMonth), food(lastMonth)]);
    Get.put(DashboardController(
      categoryRepo: Get.find<CategoryRepository>(),
      transactionRepo: Get.find<TransactionRepository>(),
      settings: settings,
    ));
  });

  tearDown(() async {
    Get.reset();
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  DashboardController ctrl() => Get.find<DashboardController>();

  /// Real Hive writes, so every caller wraps this in `tester.runAsync`.
  Future<void> seed({
    required int incomeMinor,
    int spendMinor = 0,
    String? month,
  }) async {
    await settings.setMonthlyIncomeMinor(incomeMinor);
    if (spendMinor > 0) {
      await Get.find<TransactionRepository>()
          .addTransaction(expense(spendMinor, month: month));
    }
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DashboardView()));
    await tester.pumpAndSettle();
  }

  /// The card as it was actually built, never a re-derivation of its rule.
  SummaryCard cardLabelled(WidgetTester tester, String label) => tester
      .widgetList<SummaryCard>(find.byType(SummaryCard))
      .firstWhere((c) => c.label == label);

  /// The muted token as the running theme resolves it — read off the tree
  /// rather than re-typed, so a retune of the token cannot make this file
  /// assert an old hex (the T-3 pin lives in `theme_contrast_test.dart`).
  Color mutedOf(WidgetTester tester) => tester
      .element(find.byType(DashboardView))
      .semanticColors
      .textMuted;

  /// U+2014, written as an escape so the assertion cannot be satisfied by a
  /// hyphen or an en dash that merely looks right in a diff.
  const emDash = '\u2014';

  group('the predicate', () {
    testWidgets('income 0 is unknown; one minor unit is known', (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 45000));
      expect(ctrl().incomeIsKnown, isFalse);

      await tester.runAsync(() => seed(incomeMinor: 1));
      expect(ctrl().incomeIsKnown, isTrue,
          reason: 'the boundary is "did they answer", not "is it enough"');
    });

    testWidgets('the overspend verdict reads the SAME predicate (D-020)',
        (tester) async {
      // Not a duplicate of `spent_card_colour_test.dart`: that file pins the
      // colour, this pins that both rules turn on ONE threshold. Written twice,
      // the two would drift into exactly the disagreement D-010 was filed for.
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 45000));
      expect(ctrl().incomeIsKnown, isFalse);
      expect(ctrl().spendExceedsKnownIncome, isFalse);

      await tester.runAsync(() => seed(incomeMinor: 1));
      expect(ctrl().incomeIsKnown, isTrue);
      expect(ctrl().spendExceedsKnownIncome, isTrue,
          reason: '₨450 spent against a stated income of one paisa IS an '
              'overspend — the verdict was only ever withheld for the '
              'unanswered question');
    });
  });

  group('AC-D010-1 — the fresh-install path', () {
    testWidgets('Income reads "Not set" and Remaining shows an em dash',
        (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 5000));
      await pumpDashboard(tester);

      final income = cardLabelled(tester, 'Monthly Income');
      final spent = cardLabelled(tester, 'Spent');
      final remaining = cardLabelled(tester, 'Remaining');

      expect(income.amount, 'Not set');
      expect(income.color, AppTheme.light.colorScheme.primary,
          reason: 'card colour unchanged — a missing value is not a warning');

      // Spent is COMPLETELY unchanged: exact figure, normal foreground. P2's
      // headline must stay enumerable against the Categories tab (F-01 AC-4).
      expect(spent.amount, '₨50.00');
      expect(spent.color, AppColors.warning);
      expect(spent.amountColor, isNull);

      expect(remaining.amount, emDash);
      expect(remaining.amountColor, mutedOf(tester));
      expect(remaining.color, mutedOf(tester),
          reason: 'muted throughout: tertiary would claim things are fine and '
              'error would claim a deficit, and this card may claim neither');
    });

    testWidgets('the Remaining card is still THERE — suppression was refused',
        (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 5000));
      await pumpDashboard(tester);

      // The two-up Row is fixed: a month that renders one card instead of two
      // reads as data loss (`dashboard_view.dart`, the comment that barred
      // suppression). Three cards, and the label is still on screen.
      expect(find.byType(SummaryCard), findsNWidgets(3));
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text(emDash), findsOneWidget);
    });

    testWidgets('neither card shows a zero figure — they move together',
        (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 5000));
      await pumpDashboard(tester);

      // "Income ₨0.00, Remaining —" would be the incoherent half-fix: ₨0 − ₨50
      // is perfectly computable, so withholding only the second reads as a
      // broken app rather than as a declined question.
      expect(find.text('₨0.00'), findsNothing);
      expect(find.text('-₨50.00'), findsNothing,
          reason: 'the deficit asserted from a skipped zero is the defect');
    });

    testWidgets('the dash is announced as words, not read out as a dash',
        (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 5000));
      await pumpDashboard(tester);

      expect(cardLabelled(tester, 'Remaining').amountSemanticsLabel,
          'Remaining, not available');
    });

    testWidgets('a past month with records says "Unspent, not available"',
        (tester) async {
      // The label changes on a closed month, and the announcement is built from
      // it — two literals would be one rename away from a card that says
      // "Unspent" and announces "Remaining".
      await tester.runAsync(() async {
        await seed(incomeMinor: 0, spendMinor: 5000, month: lastMonth);
        await settings.setCurrentMonth(lastMonth);
      });
      await pumpDashboard(tester);

      final unspent = cardLabelled(tester, 'Unspent');
      expect(unspent.amount, emDash);
      expect(unspent.amountSemanticsLabel, 'Unspent, not available');
    });
  });

  group('AC-D010-2 — the figures come back the moment income is known', () {
    testWidgets('income above spend: a real figure in the positive colour',
        (tester) async {
      await tester.runAsync(() => seed(incomeMinor: 100000, spendMinor: 45000));
      await pumpDashboard(tester);

      final income = cardLabelled(tester, 'Monthly Income');
      final remaining = cardLabelled(tester, 'Remaining');

      expect(income.amount, '₨1,000.00');
      expect(remaining.amount, '₨550.00');
      expect(remaining.color, AppTheme.light.colorScheme.tertiary);
      expect(remaining.amountColor, isNull,
          reason: 'a derived figure takes the default foreground');
      expect(remaining.amountSemanticsLabel, isNull);
      expect(find.text('Not set'), findsNothing);
      expect(find.text(emDash), findsNothing);
    });

    testWidgets('income below spend: the negative figure and its red stay',
        (tester) async {
      // The wrong fix that "solves" D-010 by never showing a deficit again
      // fails here. A deficit against an income the user GAVE is a fact, and
      // this is the claim the colour is for.
      await tester.runAsync(() => seed(incomeMinor: 10000, spendMinor: 45000));
      await pumpDashboard(tester);

      final remaining = cardLabelled(tester, 'Remaining');
      expect(remaining.amount, '-₨350.00');
      expect(remaining.color, AppTheme.light.colorScheme.error);
      expect(cardLabelled(tester, 'Spent').color,
          AppTheme.light.colorScheme.error);
    });

    testWidgets('setting an income mid-session replaces the dash live',
        (tester) async {
      // The reactivity half of AC-D010-2, and the reason the predicate is read
      // inside the Obx body: a user who skips income, logs, then sets it in
      // Settings must not be left looking at a stale dash.
      await tester.runAsync(() => seed(incomeMinor: 0, spendMinor: 45000));
      await pumpDashboard(tester);
      expect(cardLabelled(tester, 'Remaining').amount, emDash);

      await tester.runAsync(() => settings.setMonthlyIncomeMinor(100000));
      await tester.pumpAndSettle();

      final remaining = cardLabelled(tester, 'Remaining');
      expect(remaining.amount, '₨550.00');
      expect(remaining.amountColor, isNull);
      expect(remaining.amountSemanticsLabel, isNull);
      expect(cardLabelled(tester, 'Monthly Income').amount, '₨1,000.00');
    });
  });
}
