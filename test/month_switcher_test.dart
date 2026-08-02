import 'package:budget_buddy/core/theme/app_colors.dart';
import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/modules/dashboard/widgets/month_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-10.2 — the forward chevron that vanished.
///
/// At the current month the chevron is disabled, and M3 paints a disabled
/// IconButton in `colorScheme.onSurface` at 38%. In the light theme that is
/// #2C2518 — the deepNavy app bar's own background. The control was not dim,
/// it was invisible, on the one surface in the app whose brightness is
/// inverted relative to its theme.
///
/// Pumped inside a real `AppBar` so the test fails the way the app did: via
/// the theme, not via a colour constant compared to itself.
void main() {
  Future<void> pumpSwitcher(
    WidgetTester tester, {
    required ThemeData theme,
    required bool nextEnabled,
  }) {
    return tester.pumpWidget(MaterialApp(
      theme: theme,
      themeAnimationDuration: Duration.zero,
      home: Scaffold(
        appBar: AppBar(
          title: MonthSwitcher(
            monthKey: '2026-08',
            onPrevious: () {},
            onNext: nextEnabled ? () {} : null,
          ),
        ),
      ),
    ));
  }

  IconButton forwardChevron(WidgetTester tester) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );

  testWidgets('the month reads as a human month, not a key', (tester) async {
    await pumpSwitcher(tester, theme: AppTheme.light, nextEnabled: false);
    expect(find.text('August 2026'), findsOneWidget);
  });

  testWidgets('disabled forward chevron stays on the header', (tester) async {
    // Present-but-inert, not removed: the header must not jump width when the
    // user walks back into the current month.
    await pumpSwitcher(tester, theme: AppTheme.light, nextEnabled: false);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(forwardChevron(tester).onPressed, isNull);
  });

  testWidgets('light theme: disabled colour comes from the dark-surface set',
      (tester) async {
    await pumpSwitcher(tester, theme: AppTheme.light, nextEnabled: false);
    final button = forwardChevron(tester);

    expect(button.disabledColor, AppSemanticColors.light.onAppBarDisabled);
    // The bug, stated as the thing that must not come back: the M3 default
    // resolves to the app bar's own background colour.
    expect(button.disabledColor!.r, isNot(closeTo(AppColors.deepNavy.r, 0.01)));
    expect(button.disabledColor, isNot(AppColors.lightScheme.onSurface));
  });

  testWidgets('dark theme gets the identical treatment', (tester) async {
    // Both app bars are dark surfaces, so this token does not resolve
    // brightness — the two themes must agree here.
    await pumpSwitcher(tester, theme: AppTheme.dark, nextEnabled: false);
    expect(forwardChevron(tester).disabledColor,
        AppSemanticColors.light.onAppBarDisabled);
  });

  testWidgets('an enabled chevron is untouched by the disabled treatment',
      (tester) async {
    await pumpSwitcher(tester, theme: AppTheme.light, nextEnabled: true);
    final button = forwardChevron(tester);
    expect(button.onPressed, isNotNull);
    // `color` is left null on purpose so the AppBarTheme's iconTheme still
    // supplies the enabled foreground.
    expect(button.color, isNull);
  });
}
