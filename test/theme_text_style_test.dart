import 'package:budget_buddy/core/theme/app_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// UI-01 regression guard — a bug CLASS, not one bug.
///
/// `AppFonts` getters that carry no colour are safe inline (a `Text` style
/// MERGES with the ambient `DefaultTextStyle`) and unsafe as component theme
/// styles (those REPLACE it, so a null colour paints in the engine default —
/// white). In the light theme that made Settings row titles, every dialog
/// title and every dialog body invisible on cream, including the
/// "Erase all data?" warning copy.
///
/// The assertion is on the style a `Text` actually resolves to, not on the
/// theme object, so it fails the same way the app did.
void main() {
  /// The style the widget under [finder] really paints with: the ambient
  /// `DefaultTextStyle` (which is where a component theme installs itself)
  /// merged with anything the `Text` set inline.
  TextStyle resolvedStyle(WidgetTester tester, Finder finder) {
    final text = tester.widget<Text>(finder);
    final ambient = DefaultTextStyle.of(tester.element(finder)).style;
    return ambient.merge(text.style);
  }

  testWidgets('light theme gives ListTile and dialog text a visible colour',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const ListTile(title: Text('Monthly Income')),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Erase all data?'),
                    content: Text('It cannot be undone.'),
                  ),
                ),
                child: const Text('open'),
              ),
            ],
          ),
        ),
      ),
    ));

    final listTileTitle = resolvedStyle(tester, find.text('Monthly Income'));
    expect(listTileTitle.color, AppColors.textPrimary,
        reason: 'a null colour here renders white on cream — UI-01');
    expect(listTileTitle.color, isNot(Colors.white));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(resolvedStyle(tester, find.text('Erase all data?')).color,
        AppColors.textPrimary,
        reason: 'dialog titles run through dialogTheme.titleTextStyle');
    expect(resolvedStyle(tester, find.text('It cannot be undone.')).color,
        AppColors.textSecondary,
        reason: 'dialog bodies run through dialogTheme.contentTextStyle — '
            'this is the destructive-confirmation warning copy');
  });
}
