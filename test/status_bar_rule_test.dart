import 'dart:io';

import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/core/widgets/themed_system_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// AC-S6 [CODE-REVIEW] — RULE S, pinned as a rule (D-017, F-10 §10.4).
///
/// One defect filed four times (UI-32, N12, FD-15, QA-BUG-004) and deferred
/// four times as "Android-only, not closable on a simulator", which was false.
/// It is hit by every launch that reaches onboarding — every fresh install and
/// every erase — and it fails **no** acceptance criterion, because F-10 AC-10.2
/// enumerates *app-bar* foregrounds and these two screens have none. Nothing in
/// the test pack would ever have caught it. Hence a test for the rule itself.
///
/// The *appearance* half needs a human (AC-S2/S3/S4, reporter-verified — never
/// the author). This is the half that must not: the declaration exists, it
/// follows the theme, it inverts correctly, and it does not quietly start
/// styling a system bar the app has never touched.
void main() {
  group('the rule: the style follows the surface', () {
    test('a dark surface asks for LIGHT icons, and vice versa', () {
      // S-c: the constant names invert. `Brightness.light` on
      // `statusBarIconBrightness` means light-COLOURED icons, for a dark
      // background. Any code reading "light theme -> light" is wrong by
      // construction, and this is the assertion that says so out loud.
      final onDark = ThemedSystemOverlay.styleFor(Brightness.dark);
      expect(onDark.statusBarIconBrightness, Brightness.light);
      expect(onDark.statusBarBrightness, Brightness.dark);

      final onLight = ThemedSystemOverlay.styleFor(Brightness.light);
      expect(onLight.statusBarIconBrightness, Brightness.dark);
      expect(onLight.statusBarBrightness, Brightness.light);
    });

    test('nothing else is declared — the non-negotiable', () {
      // palwasha, §5.2: handing over `SystemUiOverlayStyle.light`/`.dark`
      // wholesale would also carry systemNavigationBar values, and this app has
      // never styled the Android system navigation bar. A status-bar fix that
      // quietly begins styling the bottom bar is a second, unreviewed change.
      for (final style in [
        ThemedSystemOverlay.styleFor(Brightness.dark),
        ThemedSystemOverlay.styleFor(Brightness.light),
      ]) {
        expect(style.systemNavigationBarColor, isNull);
        expect(style.systemNavigationBarIconBrightness, isNull);
        expect(style.systemNavigationBarDividerColor, isNull);
        expect(style.systemNavigationBarContrastEnforced, isNull);
        expect(style.statusBarColor, isNull,
            reason: 'the app has never painted the status bar background and '
                'this is not the change that starts');
        expect(style.systemStatusBarContrastEnforced, isNull);
      }
    });

    test('the two brightnesses do not resolve to the same style', () {
      // The failure mode a copy-paste produces: one branch, both themes.
      expect(
          ThemedSystemOverlay.styleFor(Brightness.dark).statusBarIconBrightness,
          isNot(ThemedSystemOverlay.styleFor(Brightness.light)
              .statusBarIconBrightness));
    });
  });

  group('the widget: it follows the THEME, not the device', () {
    /// The style the widget actually publishes into the tree.
    SystemUiOverlayStyle declaredBy(WidgetTester tester) => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(find.descendant(
          of: find.byType(ThemedSystemOverlay),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ))
        .value;

    Future<void> pumpUnder(WidgetTester tester, ThemeData theme) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const ThemedSystemOverlay(
          child: Scaffold(body: Text('any screen with no app bar')),
        ),
      ));
      await tester.pump();
    }

    testWidgets('the light theme gets dark icons', (tester) async {
      await pumpUnder(tester, AppTheme.light);
      expect(declaredBy(tester).statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('the dark theme gets light icons', (tester) async {
      await pumpUnder(tester, AppTheme.dark);
      expect(declaredBy(tester).statusBarIconBrightness, Brightness.light);
    });

    testWidgets('a forced Light theme on a DARK device still gets dark icons',
        (tester) async {
      // S-b, and the reason `MediaQuery.platformBrightness` is banned here: a
      // user can force Light on a dark phone (`settings_service.dart:116-125`).
      // The scaffold behind the status bar is cream regardless of what the
      // device thinks, so the icons must be dark regardless too.
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ThemedSystemOverlay(
            child: Scaffold(body: Text('onboarding, forced light')),
          ),
        ),
      ));
      await tester.pump();

      expect(declaredBy(tester).statusBarIconBrightness, Brightness.dark,
          reason: 'the device is dark and the SURFACE is cream — the surface '
              'wins, or the clock disappears');
    });

    testWidgets('it repaints when the theme changes underneath it',
        (tester) async {
      // AC-S4's mechanism: the user backgrounds the app, flips the system
      // appearance and returns WITHOUT leaving the screen. A declaration made
      // once at startup (the rejected `SystemChrome.setSystemUIOverlayStyle`
      // shape) would not survive this.
      await pumpUnder(tester, AppTheme.light);
      expect(declaredBy(tester).statusBarIconBrightness, Brightness.dark);

      await pumpUnder(tester, AppTheme.dark);
      await tester.pumpAndSettle();
      expect(declaredBy(tester).statusBarIconBrightness, Brightness.light);
    });
  });

  group('AC-S6 source guard — exactly two call sites, and the right two', () {
    final lib = Directory('lib');

    List<File> dartFiles() => lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('lib/ exists relative to the test run', () {
      expect(lib.existsSync(), isTrue);
    });

    test('the wrapper is used on exactly two screens', () {
      final users = <String>[];
      for (final file in dartFiles()) {
        if (file.path.endsWith('themed_system_overlay.dart')) continue;
        if (file.readAsStringSync().contains('ThemedSystemOverlay(')) {
          users.add(file.path.split('/').last);
        }
      }
      expect(users.toSet(), {'splash_view.dart', 'onboarding_view.dart'},
          reason:
              'the two screens with no app bar. A third would mean either a '
              'new app-bar-less screen (fine — add it here deliberately) or a '
              'screen declaring twice, which is the ambiguity RULE S removes');
    });

    test('no screen that has an AppBar wraps itself', () {
      for (final file in dartFiles()) {
        final source = file.readAsStringSync();
        if (!source.contains('ThemedSystemOverlay(')) continue;
        if (file.path.endsWith('themed_system_overlay.dart')) continue;
        expect(source.contains('AppBar('), isFalse,
            reason: '${file.path} has an app bar AND wraps itself — two '
                'declarations at the top of one screen');
      }
    });

    test('the wrapper reads the theme, never the platform brightness', () {
      final source = File('lib/core/widgets/themed_system_overlay.dart')
          .readAsStringSync();
      expect(source.contains('Theme.of(context).brightness'), isTrue);
      // Named in the doc comment as the banned alternative, so the check is on
      // executable lines only.
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('///'))
          .join('\n');
      expect(code.contains('platformBrightness'), isFalse);
      expect(code.contains('SystemUiOverlayStyle.light'), isFalse,
          reason: 'the wholesale constant carries systemNavigationBar values');
      expect(code.contains('SystemUiOverlayStyle.dark'), isFalse);
    });

    test('the app still declares its style in only two ways', () {
      // Before D-017: two declarations, both inside AppBarTheme. After: those
      // two, plus this widget. If a third mechanism appears — a SystemChrome
      // call in main(), an AnnotatedRegion hand-rolled in a screen — the rule
      // has been forked and this fails.
      final offenders = <String>[];
      for (final file in dartFiles()) {
        if (file.path.endsWith('themed_system_overlay.dart')) continue;
        final source = file.readAsStringSync();
        if (source.contains('SystemChrome.setSystemUIOverlayStyle') ||
            source.contains('AnnotatedRegion<SystemUiOverlayStyle>')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'RULE S is one declaration in one place; these files declare '
              'their own');
    });
  });
}
