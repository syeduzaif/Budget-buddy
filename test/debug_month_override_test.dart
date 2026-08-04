import 'dart:io';

import 'package:budget_buddy/utils/app_clock.dart';
import 'package:budget_buddy/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// The QA harness behind F-02's AC-1/2/3: a debug-only month override, so the
/// rollover can be exercised in the real app without moving the host clock.
///
/// Two things have to be true for it to be worth anything, and both are pinned
/// here:
///
/// 1. **It cannot exist in a release build.** The gate is `kDebugMode`, which a
///    debug test run cannot switch off for itself — so the whole decision lives
///    in the pure [AppClock.resolveMonthOverride], and the gate-shut case is
///    tested by passing `debugMode: false` explicitly.
/// 2. **It is the only clock.** A source guard asserts that production code
///    reads the current month through [AppClock.nowMonthKey] and nowhere else;
///    an override that half the app obeyed would produce a screen no real user
///    can ever see, which is worse than no harness at all.
void main() {
  group('the gate', () {
    test('an override is ignored when the debug gate is shut', () {
      final warnings = <String>[];

      expect(
          AppClock.resolveMonthOverride(
              debugMode: false,
              rawDefine: '2099-01',
              onReject: warnings.add),
          isNull,
          reason: 'release/profile builds read the real clock, whatever '
              'define they were built with');
      expect(warnings, isEmpty,
          reason: 'nothing to warn about: the value was never considered');
    });

    test('a well-formed override is ignored when there is no define', () {
      expect(
          AppClock.resolveMonthOverride(debugMode: true, rawDefine: ''),
          isNull);
    });

    test('this suite runs with the gate shut, so the shipped default is the '
        'real clock', () {
      // No `--dart-define=BB_NOW_MONTH` is passed by `flutter test`, so the
      // compile-time gate is false and [AppClock.nowMonthKey] must be
      // indistinguishable from the production month key. This is the
      // "falls through by default" assertion.
      expect(AppClock.monthOverrideCompiledIn, isFalse);
      expect(AppClock.nowMonthKey(), AppDateUtils.getCurrentMonthKey());
    });

    test('the define name is the one the runbook documents', () {
      // A rename here silently breaks every tester invocation written down in
      // product/qa/CODE-REVIEW-SIGNOFF.md.
      expect(AppClock.monthOverrideDefine, 'BB_NOW_MONTH');
    });
  });

  group('validation', () {
    test('accepts a canonical YYYY-MM key', () {
      expect(
          AppClock.resolveMonthOverride(
              debugMode: true, rawDefine: '2026-09'),
          '2026-09');
    });

    test('accepts every month of a year, unchanged', () {
      for (var year = 2025; year <= 2027; year++) {
        for (var month = 1; month <= 12; month++) {
          final key = AppDateUtils.monthKey(DateTime(year, month));
          expect(
              AppClock.resolveMonthOverride(
                  debugMode: true, rawDefine: key),
              key,
              reason: key);
        }
      }
    });

    test('rejects anything that is not a canonical key, loudly', () {
      const bad = <String>[
        '2026-9', // not zero-padded
        '26-09', // two-digit year
        '2026-13', // no such month
        '2026-00', // no such month
        '2026', // no month at all
        '2026-09-01', // a date, not a month
        ' 2026-09', // leading space
        '2026-09 ', // trailing space
        '+2026-09', // int.tryParse would take the sign
        '2026-+9', // …and here too
        '2026_09', // wrong separator
        '٢٠٢٦-٠٩', // non-ASCII digits (fa/ar_EG render these)
        'next month',
        'null',
      ];

      for (final value in bad) {
        final warnings = <String>[];
        expect(
            AppClock.resolveMonthOverride(
                debugMode: true, rawDefine: value, onReject: warnings.add),
            isNull,
            reason: 'accepted "$value"');
        expect(warnings, hasLength(1), reason: 'silent about "$value"');
        expect(warnings.single, contains(value));
        expect(warnings.single, contains(AppClock.monthOverrideDefine));
      }
    });

    test('a rejected value falls back to the real clock, not to nothing', () {
      // The fallback is what stops a typo becoming a wrong month: the harness
      // behaves like an ordinary debug build instead of rolling into 0009-99.
      final resolved = AppClock.resolveMonthOverride(
          debugMode: true, rawDefine: '2026-9');
      expect(resolved, isNull);
      expect(resolved ?? AppDateUtils.getCurrentMonthKey(),
          AppDateUtils.getCurrentMonthKey());
    });

    test('every accepted value keeps lexicographic order chronological', () {
      // `CategoryRepository._isBackwardFill` compares month keys with
      // `compareTo`, so a non-canonical value would not merely look odd — it
      // would sort wrongly and hand a past month a budget (BUG-120's defect).
      const accepted = ['2026-08', '2026-09', '2026-10', '2027-01'];
      for (var i = 0; i < accepted.length - 1; i++) {
        final earlier = AppClock.resolveMonthOverride(
            debugMode: true, rawDefine: accepted[i]);
        final later = AppClock.resolveMonthOverride(
            debugMode: true, rawDefine: accepted[i + 1]);
        expect(earlier!.compareTo(later!), lessThan(0),
            reason: '$earlier should sort before $later');
      }

      // Why the strictness is not pedantry: the rejected spelling of September
      // sorts AFTER October.
      expect('2026-9'.compareTo('2026-10'), greaterThan(0));
    });
  });

  group('source guard — one clock, one entry point', () {
    // Same shape as the F-11 grep guard in theme_contrast_test.dart: the
    // invariant is only worth something if the next call site cannot quietly
    // bypass it.
    final allowed = <String>{
      'lib/utils/date_utils.dart', // the definition
      'lib/utils/app_clock.dart', // the sole production caller
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

    test('no production file calls AppDateUtils.getCurrentMonthKey directly',
        () {
      final offenders = <String>[];
      for (final file in dartSources()) {
        if (allowed.contains(file.path)) continue;
        if (file.readAsStringSync().contains('getCurrentMonthKey')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'read the current month through AppClock.nowMonthKey, so the '
              'debug month override reaches every path that asks what month '
              'it is');
    });

    test('every nowMonthKey seam defaults to AppClock.nowMonthKey', () {
      const seams = <String>[
        'lib/data/repositories/category_repository.dart', // ensureMonth + resolveForMonth
        'lib/modules/splash/splash_controller.dart', // launch roll
        'lib/modules/home/home_controller.dart', // resume roll
        'lib/modules/analytics/analytics_controller.dart', // range anchor
      ];
      for (final path in seams) {
        final source = File(path).readAsStringSync();
        expect(source, contains('nowMonthKey = AppClock.nowMonthKey'),
            reason: path);
      }
      // The repository holds two of them — both clone paths, per FD-1.
      final repo =
          File('lib/data/repositories/category_repository.dart')
              .readAsStringSync();
      expect(
          'nowMonthKey = AppClock.nowMonthKey'.allMatches(repo).length, 2);
    });

    test('the override is gated on kDebugMode and read as a const define', () {
      final source = File('lib/utils/app_clock.dart').readAsStringSync();
      expect(source, contains('String.fromEnvironment'),
          reason: 'const-folded; a runtime lookup would ship the branch');
      expect(source,
          contains('static const bool monthOverrideCompiledIn = kDebugMode &&'),
          reason: 'the gate must be a compile-time constant, and kDebugMode '
              'must be the first term so no release build can open it');
    });
  });
}
