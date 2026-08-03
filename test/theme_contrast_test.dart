import 'dart:io';
import 'dart:math' as math;

import 'package:budget_buddy/core/theme/app_colors.dart';
import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-11 — the muted-text split, measured rather than eyeballed.
///
/// Muted text had ONE token (#9A9182) and TWO surfaces to live on. It measured
/// 3.06:1 on the light card — the last light-theme AA failure in the register —
/// and a naive retune to the readable #7A705F would have dropped the DARK card
/// from 4.38:1 to 2.80:1. Hence two tokens plus an extension that resolves the
/// theme's brightness.
///
/// The contrast maths below is the WCAG 2.x definition transcribed directly
/// (sRGB → linear → relative luminance → ratio), so this file can be read
/// against the spec rather than trusted. It reproduces danish's numbers.
void main() {
  // --- WCAG 2.x relative luminance and contrast --------------------------

  double linearise(int eightBit) {
    final c = eightBit / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  /// Relative luminance of an OPAQUE colour. Every colour asserted here is
  /// opaque; a translucent one would have to be composited first.
  double luminance(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return 0.2126 * linearise(r) + 0.7152 * linearise(g) + 0.0722 * linearise(b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('WCAG maths', () {
    test('reproduces the two anchors it is calibrated against', () {
      // Black on white is 21:1 by definition; a mid grey on white is the
      // textbook 4.54:1 example. If these drift, nothing below means anything.
      expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21.0, 0.01));
      expect(contrast(const Color(0xFF767676), const Color(0xFFFFFFFF)),
          closeTo(4.54, 0.01));
    });
  });

  group('muted text on its own theme card', () {
    test('light: the retuned token clears AA — this is what F-11 bought', () {
      final ratio = contrast(AppColors.textMuted, AppColors.card);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: '#7A705F on #FFFDF8 — the old #9A9182 was 3.06:1 here, '
              'which is the failure the split closes');
      expect(ratio, closeTo(4.79, 0.01));
      // The value it replaced, kept on the record so "it was already fine"
      // can never be argued from memory.
      expect(contrast(const Color(0xFF9A9182), AppColors.card),
          closeTo(3.06, 0.01));
    });

    test('dark: unchanged at 4.38:1 — the documented F-11 AC-4 conflict', () {
      // ⚠️ SPEC CONFLICT, deliberately encoded rather than hidden.
      // F-11 AC-4 asks this test to assert >= 4.5:1 in BOTH themes. F-11 spec
      // 1a freezes the dark token at #9A9182 ("byte-identical rendering") and
      // its Out-of-scope section explicitly excludes a dark-theme retune. On
      // #332D23 that token measures 4.38:1, so the two halves of the frozen
      // doc cannot both hold. Asserting 4.5 here would fail the build; quietly
      // asserting 4.3 would bury it. So the exact number is PINNED: any change
      // to either token or to the dark card trips this test and forces the
      // decision the doc deferred (retune textMutedDark, or accept 4.38:1 as
      // shipped).
      final ratio = contrast(AppColors.textMutedDark, AppColors.cardDark);
      expect(ratio, closeTo(4.38, 0.01),
          reason: 'dark muted-on-card is a known 0.12 short of AA; the freeze '
              'chose no-change over a mid-cycle retune');
    });

    test('dark: the split changed nothing about how dark renders', () {
      expect(AppColors.textMutedDark, const Color(0xFF9A9182));
      expect(contrast(AppColors.textMutedDark, AppColors.backgroundDark),
          greaterThanOrEqualTo(4.5));
    });

    test('muted clears AA on the PAGE background too, in both themes', () {
      // BUG-102's two-line empty state sits on the scaffold, not on a card, and
      // its AC asks for AA on both. The light background is a shade darker than
      // the card (#FAF7F2 vs #FFFDF8), so the margin is thinner there — pinned
      // rather than assumed.
      expect(contrast(AppColors.textMuted, AppColors.background),
          greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textMutedDark, AppColors.backgroundDark),
          greaterThanOrEqualTo(4.5));
    });

    test('the light token would have wrecked the dark card', () {
      // The single-token retune everyone reaches for first.
      expect(contrast(AppColors.textMuted, AppColors.cardDark),
          lessThan(3.0));
    });
  });

  group('the two riders that came with the split', () {
    test('light input label/hint clear AA on the field fill', () {
      // F-11 1f: #7A705F is only 4.30:1 on cardElevated, so the label a user
      // reads while typing moved to textSecondary.
      expect(contrast(AppColors.textMuted, AppColors.cardElevated),
          lessThan(4.5));
      expect(contrast(AppColors.textSecondary, AppColors.cardElevated),
          greaterThanOrEqualTo(4.5));
    });

    test('light filled buttons clear AA on their new background', () {
      // F-11 2: undefined, M3 fills them with colorScheme.primary under white.
      expect(contrast(const Color(0xFFFFFFFF), AppColors.lightScheme.primary),
          lessThan(4.5));
      expect(contrast(AppColors.textWhite, AppColors.primaryDark),
          greaterThanOrEqualTo(4.5));
    });

    test('the warning colour carries text on both cards, unlike AppColors.warning', () {
      // F-09 consumes these through the extension; measured here because F-09
      // states them as fact.
      expect(contrast(AppColors.warning, AppColors.card), lessThan(3.0));
      expect(contrast(AppColors.accentDark, AppColors.card),
          greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.accentLight, AppColors.cardDark),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('AppSemanticColors resolution', () {
    /// The extension as a widget actually sees it, from inside a pumped tree —
    /// not read off the ThemeData object, because the registration is the part
    /// that breaks.
    Future<AppSemanticColors> resolve(
        WidgetTester tester, ThemeData theme) async {
      late AppSemanticColors resolved;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        // MaterialApp wraps its child in an AnimatedTheme, so a second
        // pumpWidget in the same test reads the PREVIOUS theme mid-lerp — the
        // dark case silently resolved light before this was zeroed out.
        themeAnimationDuration: Duration.zero,
        home: Builder(builder: (context) {
          resolved = context.semanticColors;
          return const SizedBox.shrink();
        }),
      ));
      return resolved;
    }

    testWidgets('light theme resolves the light half', (tester) async {
      final colors = await resolve(tester, AppTheme.light);
      expect(colors.textMuted, const Color(0xFF7A705F));
      expect(colors.warning, AppColors.accentDark);
    });

    testWidgets('dark theme resolves the dark half', (tester) async {
      final colors = await resolve(tester, AppTheme.dark);
      expect(colors.textMuted, const Color(0xFF9A9182));
      expect(colors.warning, AppColors.accentLight);
    });

    testWidgets('an unregistered theme falls back on brightness, not a crash',
        (tester) async {
      // A bare ThemeData carries no extension. `Theme.of(context)
      // .extension<T>()!` would throw here; every widget in the app reads
      // through this accessor, so the fallback is what stops a forgotten
      // registration from being a white screen.
      final light = await resolve(tester, ThemeData(brightness: Brightness.light));
      expect(light.textMuted, AppColors.textMuted);

      final dark = await resolve(tester, ThemeData(brightness: Brightness.dark));
      expect(dark.textMuted, AppColors.textMutedDark);
    });

    testWidgets('the app-bar disabled colour is the same in both themes',
        (tester) async {
      // Both app bars are dark surfaces; a brightness-resolved value here
      // would reintroduce the invisible chevron (F-10.2).
      final light = await resolve(tester, AppTheme.light);
      final dark = await resolve(tester, AppTheme.dark);
      expect(light.onAppBarDisabled, dark.onAppBarDisabled);
      expect(light.onAppBarDisabled.a, closeTo(0.38, 0.01));
    });
  });

  group('grep guard — one definition site per semantic colour', () {
    // F-11 AC-4 as an executable check rather than a review habit: the sweep is
    // only worth anything if the next widget cannot quietly name a raw token.
    final allowed = <String>{
      'lib/core/theme/app_colors.dart', // the definition
      'lib/core/theme/app_semantic_colors.dart', // the resolver
      'lib/core/theme/app_theme.dart', // light component blocks
      'lib/modules/splash/splash_view.dart', // hand-branched on brightness
    };

    List<File> dartSources() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('lib/ exists relative to the test run', () {
      expect(dartSources(), isNotEmpty,
          reason: 'run with `flutter test` from Budget-buddy/');
    });

    test('no widget names AppColors.textMuted or textMutedDark', () {
      final offenders = <String>[];
      for (final file in dartSources()) {
        final path = file.path;
        if (allowed.contains(path)) continue;
        final source = file.readAsStringSync();
        if (source.contains('AppColors.textMuted')) offenders.add(path);
      }
      expect(offenders, isEmpty,
          reason: 'muted text is brightness-dependent — use '
              'context.semanticColors.textMuted');
    });

    test('AppFonts carries no baked muted colour', () {
      final fonts =
          File('lib/core/theme/app_fonts.dart').readAsStringSync();
      expect(fonts.contains('color: AppColors.textMuted'), isFalse,
          reason: 'labelSmall/caption/overline are colourless by design; a '
              'baked colour is wrong in whichever theme it was not '
              'written for');
    });

    test('the splash hold is a named constant, not an inline duration', () {
      final splash =
          File('lib/modules/splash/splash_view.dart').readAsStringSync();
      expect(splash, contains('_holdBeforeRoute'));
      expect(splash, contains('Duration(milliseconds: 800)'));
      expect(splash.contains('milliseconds: 1800'), isFalse);
    });
  });
}
