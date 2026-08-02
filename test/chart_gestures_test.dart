import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/widgets/category_legend.dart';
import 'package:budget_buddy/data/models/category.dart';
import 'package:budget_buddy/modules/analytics/analytics_controller.dart';
import 'package:budget_buddy/modules/analytics/widgets/category_pie_chart.dart';
import 'package:budget_buddy/modules/analytics/widgets/monthly_bar_chart.dart';
import 'package:budget_buddy/modules/dashboard/widgets/spending_donut_chart.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-10.1 — a drag that starts on a chart scrolls the page.
///
/// The mechanism, verified against fl_chart 0.70.2's own source rather than
/// assumed: `RenderBaseChart.handleEvent` gives the pointer to a
/// PanGestureRecognizer only when a touch callback exists. A recognizer in the
/// arena beats the enclosing scroll view, and the page then does not move.
///
///  * The donuts install no callback today, so they are not claiming anything —
///    but `PieChartData` DEFAULTS to touch enabled, so the guard is an
///    `IgnorePointer` that cannot be undone by adding a callback later.
///    (`PieTouchData(enabled: false)` would be theatre: `PieChart._getData`
///    never reads the flag.)
///  * The bar chart DID install one, because `BarTouchData()` defaults to
///    enabled and `BarChart._getData` then wires its built-in handler. Passing
///    `enabled: false` explicitly is what takes it out of the arena — and costs
///    the tooltip, which is why every rod now carries its value above it.
void main() {
  final pkr = CurrencyUtils.currencies.firstWhere((c) => c.code == 'PKR');

  /// An ancestor that actually blocks pointers. `Scaffold` and friends leave
  /// inert `IgnorePointer(ignoring: false)` widgets all over the tree, so a
  /// bare type match proves nothing.
  Finder blockedBy(Finder finder) => find.ancestor(
        of: finder,
        matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
      );

  Category category(String id, String name) => Category(
        id: id,
        name: name,
        budgetLimitMinor: 500000,
        colorValue: 0xFF2D8B8B,
        iconCodePoint: Icons.restaurant.codePoint,
        month: '2026-08',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

  group('the dashboard donut', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SpendingDonutChart(
              categories: [category('food', 'Food'), category('gym', 'Gym')],
              spentMinorByCategory: const {'food': 120000, 'gym': 45000},
              currency: pkr,
            ),
          ),
        ));

    testWidgets('the chart takes no pointers', (tester) async {
      await pump(tester);
      expect(blockedBy(find.byType(PieChart)), findsOneWidget);
    });

    testWidgets('the legend still can', (tester) async {
      await pump(tester);
      expect(blockedBy(find.byType(CategoryLegend)), findsNothing,
          reason: 'the legend is content, not chrome — one day it may be '
              'tappable');
    });
  });

  group('the analytics donut', () {
    testWidgets('the chart takes no pointers, the legend still can',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CategoryPieChart(
            data: [
              CategorySpend(
                  category: category('food', 'Food'),
                  name: 'Food',
                  spentMinor: 120000),
            ],
            currency: pkr,
          ),
        ),
      ));

      expect(blockedBy(find.byType(PieChart)), findsOneWidget);
      expect(blockedBy(find.byType(CategoryLegend)), findsNothing);
    });
  });

  group('the monthly bar chart', () {
    const months = [
      MonthlyTotal(month: '2026-06', totalMinor: 245000),
      MonthlyTotal(month: '2026-07', totalMinor: 0),
      MonthlyTotal(month: '2026-08', totalMinor: 80000),
    ];

    Future<BarChartData> pumpAndRead(WidgetTester tester,
        {ThemeData? theme}) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const Scaffold(
          body: MonthlyBarChart(data: months, currency: _pkr),
        ),
      ));
      return tester.widget<BarChart>(find.byType(BarChart)).data;
    }

    testWidgets('touch is disabled EXPLICITLY, not left to the default',
        (tester) async {
      final data = await pumpAndRead(tester);
      expect(data.barTouchData.enabled, isFalse,
          reason: 'enabled is what puts a pan recognizer in the arena against '
              'the page scroll');
    });

    testWidgets('every rod carries its own value above it', (tester) async {
      final data = await pumpAndRead(tester);
      expect(data.titlesData.topTitles.sideTitles.showTitles, isTrue);

      // Compact whole units, from the exact minor-unit totals.
      expect(find.text('₨2,450'), findsOneWidget);
      expect(find.text('₨800'), findsOneWidget);
      expect(find.text('₨0'), findsOneWidget,
          reason: 'a month with no spending reads as zero, not as broken '
              '(AC-10.1b)');
    });

    testWidgets('a long amount shrinks rather than clipping', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MonthlyBarChart(
            data: [MonthlyTotal(month: '2026-08', totalMinor: 144000000)],
            currency: _pkr,
          ),
        ),
      ));

      expect(find.text('₨1,440,000'), findsOneWidget);
      expect(
          find.ancestor(
              of: find.text('₨1,440,000'), matching: find.byType(FittedBox)),
          findsOneWidget,
          reason: 'the six-bar width wall stands until MF-1 gives us a k/M '
              'format; until then the label scales down instead of clipping');
    });

    testWidgets('the labels are readable in the dark theme too', (tester) async {
      // labelSmall carries no colour since F-11, so a forgotten copyWith here
      // paints in the engine default.
      await pumpAndRead(tester, theme: AppTheme.dark);
      final label = tester.widget<Text>(find.text('₨2,450'));
      expect(label.style?.color, isNotNull);
      expect(label.style?.color, isNot(Colors.white));
    });
  });
}

const _pkr =
    Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', decimalDigits: 2);
