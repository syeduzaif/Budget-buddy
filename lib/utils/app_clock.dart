import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;

import 'date_utils.dart';

/// The app's one answer to "which month is it **now**".
///
/// Production behaviour is [AppDateUtils.getCurrentMonthKey] and nothing else.
/// This class exists so that a DEBUG build can be told to pretend it is a
/// different month, via `--dart-define=BB_NOW_MONTH=YYYY-MM`.
///
/// ## Why it exists
///
/// F-02's P0 acceptance criteria (AC-1/2/3 — a new month opens with last
/// month's categories at their limits, the previous month is untouched, a
/// relaunch adds nothing) describe what happens **on the 1st**. There is no
/// simulator clock API, and moving the host machine's clock is an invasive
/// change to the tester's whole computer, so those criteria carried no
/// behavioural evidence at all: only the unit-level seam tests in
/// `test/month_rollover_test.dart`. Substituting the month here drives the
/// REAL rollover path in the REAL app, which is the missing evidence.
///
/// **Honest limit 1:** this substitutes the month; it does not exercise
/// [AppDateUtils.getCurrentMonthKey] reading the system clock. That one line
/// stays covered by `test/month_key_test.dart`. See the F-02 block in
/// `product/qa/CODE-REVIEW-SIGNOFF.md`.
///
/// **Honest limit 2:** it substitutes a month KEY, never a `DateTime`. So a
/// transaction saved while the override is active is dated with the real
/// `DateTime.now()` — `TransactionFormController.defaultDateForMonth` returns
/// today when the viewed month is not in the past, and the date picker's
/// `lastDate` is the real today — and F-01 attributes a transaction by its own
/// date, so the row lands in the REAL month, not the substituted one. Nothing
/// crashes and no data is corrupted; it simply means a rollover pass logs its
/// spend BEFORE turning the override on. F-02's AC-1/2/3 need no write in the
/// new month (they are about categories, limits, and a zero spend), so this
/// costs the evidence nothing. Substituting `DateTime.now()` as well would be a
/// second clock concept and is deliberately not done here.
///
/// ## Why it is safe in release
///
/// [monthOverrideCompiledIn] is a compile-time constant: `kDebugMode` is a
/// `const bool` (false in profile/release) and [_rawOverride] is const-folded
/// from the build's `--dart-define`s. So in any release build the constant is
/// literally `false`, the override branch of [nowMonthKey] is unreachable, and
/// [_resolvedOverride] — with it the validation and the logging — is never
/// initialised. A release build passed `--dart-define=BB_NOW_MONTH=...`
/// ignores it, because `kDebugMode` alone already closes the gate.
///
/// ## The one entry point
///
/// [nowMonthKey] is the default for every `nowMonthKey` seam parameter
/// (`CategoryRepository.ensureMonth` / `resolveForMonth`,
/// `SplashController.prepareForHome`, `HomeController.handleResume`,
/// `AnalyticsController.nowMonthKey`) and the direct answer at the few sites
/// that used to call [AppDateUtils.getCurrentMonthKey] themselves
/// (`DashboardController.isViewingCurrentMonth`, `SettingsService`,
/// `OnboardingController.finish`). One clock concept, not two: a harness where
/// half the app believes a different month than the other half would produce a
/// screen no real user can ever see. `test/debug_month_override_test.dart`
/// keeps that on the record with a source guard.
/// [PROPOSED convention: production code reads the current month ONLY through
/// [AppClock.nowMonthKey]; tests keep passing their own function into the seam.]
class AppClock {
  AppClock._();

  /// The `--dart-define` name. Debug builds only; see the class doc.
  static const String monthOverrideDefine = 'BB_NOW_MONTH';

  /// The raw define value, or `''` when the build did not pass one.
  /// `String.fromEnvironment` is const, so this is folded at compile time.
  static const String _rawOverride = String.fromEnvironment(monthOverrideDefine);

  /// Whether an override could possibly apply in THIS build. Compile-time
  /// `false` in every release build, and in any debug build without the define.
  static const bool monthOverrideCompiledIn = kDebugMode && _rawOverride != '';

  /// The current month key: the real clock, unless a debug build was told
  /// otherwise and the value it was given was well formed.
  ///
  /// Written as a conditional on a compile-time constant so the override cannot
  /// add a runtime branch to a release build.
  static String nowMonthKey() => monthOverrideCompiledIn
      ? (_resolvedOverride ?? AppDateUtils.getCurrentMonthKey())
      : AppDateUtils.getCurrentMonthKey();

  /// The validated override, or null. Static finals are lazy in Dart, so this
  /// resolves once, on first use: the announcement (and any rejection warning)
  /// is printed once rather than on every rebuild — [nowMonthKey] is read from
  /// getters that run inside `Obx`.
  static final String? _resolvedOverride = _resolveAndAnnounce();

  static String? _resolveAndAnnounce() {
    final resolved = resolveMonthOverride(
      debugMode: kDebugMode,
      rawDefine: _rawOverride,
      onReject: (message) => debugPrint(message),
    );
    if (resolved != null) {
      debugPrint('[AppClock] $monthOverrideDefine=$resolved — this DEBUG build '
          'behaves as if the current month were $resolved. Release builds '
          'always read the real clock.');
    }
    return resolved;
  }

  /// The whole decision, as a pure function, so it can be tested with the gate
  /// shut — which is the one thing a debug-mode test run cannot do to itself.
  ///
  /// Returns null for "use the real clock": gate closed, no define, or a value
  /// that is not a canonical month key. A malformed value is REJECTED rather
  /// than parsed leniently: `"2026-9"` is not the same string as `"2026-09"`,
  /// and the app compares month keys lexicographically (see
  /// `CategoryRepository._isBackwardFill`), so a non-canonical key would
  /// silently sort into the wrong place instead of failing loudly.
  @visibleForTesting
  static String? resolveMonthOverride({
    required bool debugMode,
    required String rawDefine,
    void Function(String message)? onReject,
  }) {
    if (!debugMode) return null;
    if (rawDefine.isEmpty) return null;
    if (!_isCanonicalMonthKey(rawDefine)) {
      onReject?.call('[AppClock] IGNORING $monthOverrideDefine="$rawDefine": '
          'not a canonical month key. Expected zero-padded "YYYY-MM" with a '
          'four-digit year and month 01-12, e.g. "2026-09". Falling back to '
          'the real clock.');
      return null;
    }
    return rawDefine;
  }

  /// Canonical means "byte-identical to something [AppDateUtils.monthKey]
  /// produces". Defined by round-trip rather than by a pattern of its own, so
  /// the accepted set cannot drift away from the keys the app actually writes.
  /// [AppDateUtils.parseMonthKey] alone is deliberately lenient (it accepts
  /// `"2026-9"`); the re-render is what makes this strict.
  static bool _isCanonicalMonthKey(String value) {
    final parsed = AppDateUtils.parseMonthKey(value);
    if (parsed == null) return false;
    return AppDateUtils.monthKey(parsed) == value;
  }
}
