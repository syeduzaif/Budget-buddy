import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/utils/budget_status.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/modules/categories/widgets/category_card.dart';
import 'package:budget_buddy/modules/dashboard/widgets/category_budget_list.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-09 — the budget warning ladder, on both surfaces and in both themes.
///
/// The only budget signal this app had arrived after the overspend. These
/// tests pin the four rungs that replaced it (normal, warning, over, no
/// limit), the captions that make each one readable without colour, and the
/// preview sort that stops a warning from hiding at position 7.
///
/// Both widgets are plain StatelessWidgets over plain data — no Hive, no GetX,
/// no controller — so every state is a pump away.
void main() {
  final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');

  Category category({
    required String id,
    required String name,
    required int limitMinor,
  }) =>
      Category(
        id: id,
        name: name,
        budgetLimitMinor: limitMinor,
        colorValue: 0xFF6B7F4E,
        month: '2026-08',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  Future<void> pumpPreview(
    WidgetTester tester, {
    required List<Category> categories,
    required Map<String, int> spent,
    ThemeData? theme,
    String monthKey = '2026-08',
    bool isCurrentMonth = true,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: theme ?? AppTheme.light,
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: CategoryBudgetList(
            categories: categories,
            spentMinorByCategory: spent,
            currency: pkr,
            monthKey: monthKey,
            isCurrentMonth: isCurrentMonth,
          ),
        ),
      ));

  Future<void> pumpCard(
    WidgetTester tester, {
    required Category cat,
    required int spentMinor,
    ThemeData? theme,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: theme ?? AppTheme.light,
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: CategoryCard(
            category: cat,
            spentMinor: spentMinor,
            currency: pkr,
            onTap: () {},
            onEdit: () {},
          ),
        ),
      ));

  Color colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  // --- The rungs, decided once -------------------------------------------

  group('BudgetStatus', () {
    test('the four states and their boundaries', () {
      // PKR: 100 minor units to the rupee. Limit ₨1,000.
      expect(BudgetStatus.of(spentMinor: 74999, limitMinor: 100000).state,
          BudgetState.normal);
      expect(BudgetStatus.of(spentMinor: 75000, limitMinor: 100000).state,
          BudgetState.warning,
          reason: 'exactly 75% is already the warning rung');
      expect(BudgetStatus.of(spentMinor: 100000, limitMinor: 100000).state,
          BudgetState.warning,
          reason: 'exactly at the limit is not yet over');
      expect(BudgetStatus.of(spentMinor: 100001, limitMinor: 100000).state,
          BudgetState.over);
      expect(BudgetStatus.of(spentMinor: 0, limitMinor: 0).state,
          BudgetState.noLimit);
      expect(BudgetStatus.of(spentMinor: 50000, limitMinor: 0).state,
          BudgetState.noLimit,
          reason: 'spending against no budget is still "no limit set", '
              'never "over"');
    });

    test('captions say the amount, in both formatters', () {
      final warning = BudgetStatus.of(spentMinor: 84400, limitMinor: 90000);
      expect(warning.caption(pkr, compact: false), '₨56.00 left');
      expect(warning.caption(pkr, compact: true), '₨56 left');

      final atLimit = BudgetStatus.of(spentMinor: 90000, limitMinor: 90000);
      expect(atLimit.caption(pkr, compact: true), '₨0 left');

      final over = BudgetStatus.of(spentMinor: 250000, limitMinor: 100000);
      expect(over.caption(pkr, compact: true), 'Over by ₨1,500');
      expect(over.caption(pkr, compact: false), 'Over by ₨1,500.00');
      // D4: the number is the alarming part.
      expect(over.caption(pkr, compact: true), isNot(contains('!')));

      expect(BudgetStatus.of(spentMinor: 1, limitMinor: 0).caption(pkr,
          compact: true),
          'No limit set');
      expect(
          BudgetStatus.of(spentMinor: 1, limitMinor: 100000)
              .caption(pkr, compact: true),
          isNull,
          reason: 'a normal row gains no caption and therefore no height');
    });

    test('the bar is dropped only when there is no limit', () {
      expect(BudgetStatus.of(spentMinor: 0, limitMinor: 0).showsBar, isFalse,
          reason: 'a full-width empty rail reads as a full bar');
      expect(BudgetStatus.of(spentMinor: 0, limitMinor: 1).showsBar, isTrue);
      // An overspend fills the bar once rather than overflowing it.
      expect(BudgetStatus.of(spentMinor: 300, limitMinor: 100).barValue, 1.0);
    });

    test('and so is the limit figure — there is none to print', () {
      expect(BudgetStatus.of(spentMinor: 5000, limitMinor: 0).showsLimit,
          isFalse,
          reason: '"of ₨0" reads as a budget of zero, not as no budget');
      expect(BudgetStatus.of(spentMinor: 0, limitMinor: 1).showsLimit, isTrue);
      expect(BudgetStatus.of(spentMinor: 300, limitMinor: 100).showsLimit,
          isTrue,
          reason: 'an overspend needs the limit it broke');
    });
  });

  // --- Dashboard preview rows --------------------------------------------

  group('dashboard preview', () {
    testWidgets('normal: no caption, no triangle, category-coloured bar',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpPreview(
          tester, categories: [food], spent: {'a': 10000});

      expect(find.textContaining('left'), findsNothing);
      expect(find.textContaining('Over by'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(colorOf(tester, '₨100 / ₨1,000'),
          AppSemanticColors.light.textMuted);
    });

    testWidgets('warning: caption with the exact remainder, warning colour',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpPreview(tester, categories: [food], spent: {'a': 80000});

      expect(find.text('₨200 left'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing,
          reason: 'the triangle belongs to the over state only');
      expect(colorOf(tester, '₨200 left'), AppSemanticColors.light.warning);
      expect(colorOf(tester, '₨800 / ₨1,000'), AppSemanticColors.light.warning);
    });

    testWidgets('over: triangle, error colour, "Over by" caption',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpPreview(tester, categories: [food], spent: {'a': 250000});

      expect(find.text('Over by ₨1,500'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(colorOf(tester, 'Over by ₨1,500'),
          AppTheme.light.colorScheme.error);
    });

    testWidgets('no limit: no bar, no "/ ₨0", muted "No limit set"',
        (tester) async {
      final bucket =
          category(id: 'a', name: 'Uncategorised', limitMinor: 0);
      await pumpPreview(tester, categories: [bucket], spent: {'a': 5000});

      expect(find.text('No limit set'), findsOneWidget);
      expect(colorOf(tester, 'No limit set'),
          AppSemanticColors.light.textMuted);
      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'zero of zero must not render as a full rail');
      // The spend still shows; the comparison it had nothing to compare against
      // does not (BUG-120's frozen expectation).
      expect(find.text('₨50'), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('a limited row still prints the pair', (tester) async {
      // The other half of the assertion above: the fragment goes at limit 0
      // and ONLY at limit 0.
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpPreview(tester, categories: [food], spent: {'a': 10000});

      expect(find.text('₨100 / ₨1,000'), findsOneWidget);
    });

    testWidgets('dark theme resolves the same states to readable colours',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpPreview(tester,
          categories: [food], spent: {'a': 80000}, theme: AppTheme.dark);
      expect(colorOf(tester, '₨200 left'), AppSemanticColors.dark.warning);

      await pumpPreview(tester,
          categories: [food], spent: {'a': 250000}, theme: AppTheme.dark);
      expect(colorOf(tester, 'Over by ₨1,500'),
          AppTheme.dark.colorScheme.error);

      final bucket = category(id: 'b', name: 'Uncategorised', limitMinor: 0);
      await pumpPreview(tester,
          categories: [bucket], spent: {'b': 1}, theme: AppTheme.dark);
      expect(
          colorOf(tester, 'No limit set'), AppSemanticColors.dark.textMuted);
    });
  });

  // --- Preview sort (N10) -------------------------------------------------

  group('preview sort', () {
    testWidgets('shows the four most-pressured budgets, worst first',
        (tester) async {
      final cats = [
        category(id: '1', name: 'Calm', limitMinor: 100000), // 10%
        category(id: '2', name: 'Over', limitMinor: 100000), // 200%
        category(id: '3', name: 'Quiet', limitMinor: 100000), // 20%
        category(id: '4', name: 'Warning', limitMinor: 100000), // 80%
        category(id: '5', name: 'Half', limitMinor: 100000), // 50%
        category(id: '6', name: 'Unlimited', limitMinor: 0),
      ];
      await pumpPreview(tester, categories: cats, spent: {
        '1': 10000,
        '2': 200000,
        '3': 20000,
        '4': 80000,
        '5': 50000,
        '6': 999999,
      });

      // Four of six, and the over-budget one is on the dashboard rather than
      // seventh in an arbitrary order (N10).
      expect(find.text('Over'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Half'), findsOneWidget);
      expect(find.text('Quiet'), findsOneWidget);
      expect(find.text('Calm'), findsNothing);
      expect(find.text('Unlimited'), findsNothing,
          reason: 'a category with no budget cannot outrank one with a '
              'breached budget, however much was spent against it');

      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((s) => s != null)
          .cast<String>()
          .toList();
      expect(order.indexOf('Over'), lessThan(order.indexOf('Warning')));
      expect(order.indexOf('Warning'), lessThan(order.indexOf('Half')));
      expect(order.indexOf('Half'), lessThan(order.indexOf('Quiet')));
    });

    testWidgets('zero-limit rows fill the preview only when nothing else can',
        (tester) async {
      final cats = [
        category(id: '1', name: 'Bills', limitMinor: 100000),
        category(id: '2', name: 'Uncategorised', limitMinor: 0),
      ];
      await pumpPreview(tester,
          categories: cats, spent: {'1': 50000, '2': 700});

      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Uncategorised'), findsOneWidget);
      expect(find.text('No limit set'), findsOneWidget);
    });

    testWidgets('completely tied rows still have one stable order',
        (tester) async {
      // Two unspent zero-limit rows tie on ratio AND on spend. Without the
      // name/id tail the preview could reshuffle between rebuilds, because
      // List.sort is not stable.
      final cats = [
        category(id: 'zzz', name: 'Beta', limitMinor: 0),
        category(id: 'aaa', name: 'Alpha', limitMinor: 0),
      ];
      await pumpPreview(tester, categories: cats, spent: const {});

      var order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(order.indexOf('Alpha'), lessThan(order.indexOf('Beta')));

      // The same input in the other order lands the same way round.
      await pumpPreview(tester,
          categories: cats.reversed.toList(), spent: const {});
      order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(order.indexOf('Alpha'), lessThan(order.indexOf('Beta')));
    });

    testWidgets('the list handed in is never reordered in place',
        (tester) async {
      // It is the controller's RxList, read inside an Obx: mutating it during
      // a rebuild that observes it is a rebuild loop.
      final cats = [
        category(id: '1', name: 'Calm', limitMinor: 100000),
        category(id: '2', name: 'Over', limitMinor: 100000),
      ];
      await pumpPreview(tester,
          categories: cats, spent: {'1': 1000, '2': 500000});

      expect(cats.map((c) => c.name), ['Calm', 'Over']);
    });
  });

  // --- Category cards -----------------------------------------------------

  group('category card', () {
    testWidgets('normal: the amount keeps the surface default', (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpCard(tester, cat: food, spentMinor: 10000);

      expect(find.textContaining('left'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(tester.widget<Text>(find.text('₨100.00')).style!.color, isNull);
    });

    testWidgets('warning: exact remainder, no triangle', (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpCard(tester, cat: food, spentMinor: 84400);

      expect(find.text('₨156.00 left'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(colorOf(tester, '₨844.00'), AppSemanticColors.light.warning);
      expect(colorOf(tester, '₨156.00 left'), AppSemanticColors.light.warning);
    });

    testWidgets('over: the shipped "Over budget!" becomes an amount',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);
      await pumpCard(tester, cat: food, spentMinor: 250000);

      expect(find.text('Over budget!'), findsNothing);
      expect(find.text('Over by ₨1,500.00'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(colorOf(tester, '₨2,500.00'), AppTheme.light.colorScheme.error);
    });

    testWidgets('no limit: no bar, no "of ₨0.00", muted caption',
        (tester) async {
      final bucket = category(id: 'a', name: 'Uncategorised', limitMinor: 0);
      await pumpCard(tester, cat: bucket, spentMinor: 5000);

      expect(find.text('No limit set'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
          colorOf(tester, 'No limit set'), AppSemanticColors.light.textMuted);
      // "₨50.00 … of ₨0.00 / No limit set" said the same nothing twice, and the
      // middle figure read as a budget of zero (danish; BUG-120 requires its
      // absence). The spend itself stays.
      expect(find.text('₨50.00'), findsOneWidget);
      expect(find.textContaining('of ₨'), findsNothing);
    });

    testWidgets('every other state keeps the "of ₨X" it is measured against',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);

      await pumpCard(tester, cat: food, spentMinor: 10000); // normal
      expect(find.text('of ₨1,000.00'), findsOneWidget);

      await pumpCard(tester, cat: food, spentMinor: 84400); // warning
      expect(find.text('of ₨1,000.00'), findsOneWidget);

      await pumpCard(tester, cat: food, spentMinor: 250000); // over
      expect(find.text('of ₨1,000.00'), findsOneWidget);
    });

    testWidgets('dark theme: the same four states, resolved for dark',
        (tester) async {
      final food = category(id: 'a', name: 'Food', limitMinor: 100000);

      await pumpCard(tester,
          cat: food, spentMinor: 84400, theme: AppTheme.dark);
      expect(colorOf(tester, '₨844.00'), AppSemanticColors.dark.warning);

      await pumpCard(tester,
          cat: food, spentMinor: 250000, theme: AppTheme.dark);
      expect(colorOf(tester, '₨2,500.00'), AppTheme.dark.colorScheme.error);
    });

    testWidgets('captions never wrap, even at 1.3x text scale',
        (tester) async {
      // palwasha's AC: one line, ellipsized. A wrapped caption pushes the next
      // card's contents around and turns a warning into a layout bug.
      final food = category(
          id: 'a', name: 'Groceries and household', limitMinor: 100000);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: Scaffold(
              body: SizedBox(
                width: 360,
                child: CategoryCard(
                  category: food,
                  spentMinor: 250000,
                  currency: pkr,
                  onTap: () {},
                  onEdit: () {},
                ),
              ),
            ),
          ),
        ),
      ));

      final caption = tester.widget<Text>(find.text('Over by ₨1,500.00'));
      expect(caption.maxLines, 1);
      expect(caption.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}
