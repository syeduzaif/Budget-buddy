import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../utils/date_utils.dart';

/// The dashboard app bar's `‹ August 2026 ›` title.
///
/// Extracted so the app-bar foreground rule has ONE home:
///
/// > **The app bar is a dark surface in BOTH themes.** Every foreground on it —
/// > enabled, disabled, icon, label, status-bar overlay — is specified from the
/// > dark-surface set and never inherited from the light scheme.
///
/// The forward chevron is why. `AppBarTheme` colours enabled foregrounds via
/// `foregroundColor`/`iconTheme` and has no disabled slot at all, so a disabled
/// `IconButton` fell through to M3's default — `colorScheme.onSurface` at 38%,
/// which in the light theme is #2C2518: the exact background of the bar it was
/// painted on. 1:1. The button was not dim, it was gone, and the header still
/// reserved its width (screenshot 24 / F-10.2).
///
/// Fixed at the widget with [AppSemanticColors.onAppBarDisabled] rather than a
/// global `iconButtonTheme`, which would push white-at-38% onto every
/// IconButton in the app, most of which sit on light surfaces.
class MonthSwitcher extends StatelessWidget {
  /// The viewed month, `"YYYY-MM"`.
  final String monthKey;

  final VoidCallback onPrevious;

  /// `null` disables the forward chevron — the current month is the end of the
  /// line. The button stays present so the header does not jump.
  final VoidCallback? onNext;

  const MonthSwitcher({
    super.key,
    required this.monthKey,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          padding: EdgeInsets.zero,
        ),
        Text(
          AppDateUtils.formatMonthKey(monthKey),
          style: AppFonts.h6,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          // The rule, applied. Dimmed on the bar's own dark surface instead of
          // camouflaged against it.
          disabledColor: context.semanticColors.onAppBarDisabled,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
