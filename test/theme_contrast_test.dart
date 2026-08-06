import 'dart:io';
import 'dart:math' as math;

import 'package:budget_buddy/core/constants/app_constants.dart';
import 'package:budget_buddy/core/theme/app_colors.dart';
import 'package:budget_buddy/core/theme/app_semantic_colors.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-11 — the muted-text split, measured rather than eyeballed.
/// D-018 / D-019 — the dark half of it, closed.
///
/// Muted text had ONE token (#9A9182) and TWO surfaces to live on. It measured
/// 3.06:1 on the light card — the last light-theme AA failure in the register —
/// and a naive retune to the readable #7A705F would have dropped the DARK card
/// from 4.38:1 to 2.80:1. Hence two tokens plus an extension that resolves the
/// theme's brightness.
///
/// F-11 closed the light half and pinned the dark one at 4.38:1 — 0.12 short of
/// AA — so the deferred decision would have to be taken consciously rather than
/// drifted past. D-018 takes it: the dark token moves to #A19889 (4.78:1 on the
/// card), and `darkScheme.onSurfaceVariant` moves with it, because that is the
/// token colouring the "of ₨45,000" limit caption and it had zero assertions
/// anywhere in the suite. D-019 removes the 60% alpha the splash's version
/// label wore on its dark branch alone.
///
/// TWO of the four `#9A9182` literals in `lib/` moved. The other two are pinned
/// against exactly that, below: `kUncategorisedColorValue` is persisted user
/// data, and `lightScheme.outline` is a light token that lightening would make
/// worse.
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

    test('dark: the retuned token clears AA — this is what D-018 bought', () {
      // The F-11 AC-4 conflict this line used to encode is resolved, not
      // deleted: that ticket asked for >= 4.5:1 in BOTH themes while its own
      // spec froze the dark token at #9A9182, and the two halves could not
      // both hold. Rather than assert 4.3 and bury it, F-11 pinned the exact
      // 4.38 so the deferred decision had to be taken deliberately. This is
      // that decision, taken.
      final ratio = contrast(AppColors.textMutedDark, AppColors.cardDark);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'F-11 AC-4 now holds in both themes');
      expect(ratio, closeTo(4.78, 0.01));
      // The value it replaced, kept on the record so "it was already fine"
      // can never be argued from memory.
      expect(contrast(const Color(0xFF9A9182), AppColors.cardDark),
          closeTo(4.38, 0.01));
    });

    test('dark: the retune moved the token, and it is still readable on the '
        'page background', () {
      expect(AppColors.textMutedDark, const Color(0xFFA19889));
      expect(contrast(AppColors.textMutedDark, AppColors.backgroundDark),
          greaterThanOrEqualTo(4.5));
    });

    test('muted clears AA on BOTH ends of the splash gradient (D-019)', () {
      // The splash paints its own backgroundDark -> surfaceDark gradient and
      // the version label sits at the bottom of it, so the darker end is not
      // the worst case. Before D-019 that label wore `alpha: 0.6` on the dark
      // branch only — the light branch never had one, so the value was copied
      // across without a contrast check — and composited to 2.84:1.
      expect(contrast(AppColors.textMutedDark, AppColors.backgroundDark),
          greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textMutedDark, AppColors.surfaceDark),
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

  group('the scheme token nothing was asserting', () {
    test('dark onSurfaceVariant clears AA on the card it captions money on',
        () {
      // JF-1, and the reason D-018 is three lines rather than one.
      // `darkScheme.onSurfaceVariant` carries the "of ₨45,000" limit caption
      // (`category_card.dart:122`) and had ZERO hits across all 30 test files.
      // Retune `textMutedDark` alone and the suite goes green with a MONEY
      // figure still rendering at 4.38:1 — a clean suite measures what was
      // asserted, and nothing was asserting this.
      final ratio =
          contrast(AppColors.darkScheme.onSurfaceVariant, AppColors.cardDark);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, closeTo(4.78, 0.01));
    });

    test('the two dark muted tokens hold the same value', () {
      // One meaning, two definition sites, kept in step by hand. Asserted so a
      // future retune of one alone fails here rather than on a user's screen.
      expect(AppColors.darkScheme.onSurfaceVariant, AppColors.textMutedDark);
    });

    test('the LIGHT scheme was not dragged along', () {
      // `lightScheme.outline` is the third `#9A9182` literal and it must not
      // move: it is a LIGHT token, where lightening reduces contrast. M3 also
      // reads `outline` implicitly, so "nothing uses it" is not provable by
      // grep and is not an argument for touching it.
      expect(AppColors.lightScheme.outline, const Color(0xFF9A9182));
      expect(AppColors.lightScheme.onSurfaceVariant, AppColors.textSecondary,
          reason: 'the light half of this pair is textSecondary, not muted');
    });
  });

  group('source guard — the persisted colour is not a theme token', () {
    test('kUncategorisedColorValue keeps its own literal', () {
      // JF-2 — the highest-consequence mis-implementation available in this
      // change, and the only one that would pass every other gate we have.
      //
      // This int is written into `Category.colorValue`
      // (`category_repository.dart:260`), a persisted `@HiveField`
      // (`category.dart:27`). Find-and-replace the hex and only the buckets
      // minted AFTER the change get the new colour: a permanently mixed store,
      // one reserved bucket per month, forever, with no migration. No other
      // test would fail, and the Hive schema discipline would not catch it
      // either — that governs field indices and typeIds, not values.
      //
      // Pinned by LITERAL on purpose. Expressing it as "equals
      // AppColors.textMutedDark" would say the same thing and would be
      // satisfied by the very edit this exists to stop.
      expect(kUncategorisedColorValue, 0xFF9A9182);
    });

    test('the stored colour has deliberately diverged from the text token', () {
      // It was seeded from `textMutedDark`'s old value and still looks like a
      // copy of it. After D-018 it is not one, and that divergence is the
      // feature — not an inconsistency for a later tidy-up to close.
      expect(const Color(kUncategorisedColorValue),
          isNot(AppColors.textMutedDark));
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
      expect(colors.textMuted, const Color(0xFFA19889));
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

    test('the splash version label carries no alpha (D-019)', () {
      // A contrast assertion cannot see this: the composite only exists in the
      // widget's `copyWith`. The token itself measures fine, which is exactly
      // how a 2.84:1 label survived a suite that asserts the token.
      final splash =
          File('lib/modules/splash/splash_view.dart').readAsStringSync();
      expect(splash.contains('textMutedDark.withValues(alpha:'), isFalse,
          reason: 'the light branch has no alpha; the dark branch must not '
              'either');
    });
  });
}
