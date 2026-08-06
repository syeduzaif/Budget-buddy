import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The colours that have ONE meaning and TWO values.
///
/// `AppColors` is a flat list of paint. This is the small set where naming the
/// paint directly is a bug: "muted text" is #7A705F on a cream card and
/// #A19889 on a dark one, and a widget that renders in both themes cannot
/// hardcode either. Widgets ask for the meaning —
/// `context.semanticColors.textMuted` — and get the value that reads on the
/// surface they are painting on.
///
/// ⚠️ [textMuted] and [warning] resolve the **theme's** brightness, not the
/// local surface's. The app bar and the bottom nav are dark surfaces in BOTH
/// themes, so these two must never be used there — that is exactly the
/// inversion [onAppBarDisabled] exists to fix.
///
/// Registered on both themes in `AppTheme`; read through the [BuildContext]
/// extension below, which falls back on brightness rather than `!`-asserting,
/// so a theme built without the extension (a bare `MaterialApp` in a test, a
/// future third theme) degrades to the right colour instead of crashing.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.textMuted,
    required this.warning,
    required this.onAppBarDisabled,
  });

  /// Third-rank text: captions, subtitles, empty-state body lines, disabled
  /// glyphs on ordinary surfaces.
  final Color textMuted;

  /// The budget warning state (75%–100% of a limit) — F-09's ladder.
  ///
  /// Deliberately NOT `AppColors.warning` (#D4A04A, harvest gold): that token
  /// measures 2.32:1 on the light card and cannot carry text. These two do —
  /// `accentDark` 5.10:1 on light card, `accentLight` 6.40:1 on dark.
  final Color warning;

  /// Foreground for a DISABLED control on the app bar.
  ///
  /// Brightness-independent on purpose: both themes' app bars are dark
  /// surfaces, and M3's disabled default (`onSurface` @38%) resolves to the
  /// light scheme's #2C2518 — the exact background of the light theme's bar,
  /// i.e. invisible at 1:1 (F-10.2). `AppBarTheme` has no disabled slot, so
  /// this is passed at the widget.
  final Color onAppBarDisabled;

  static final AppSemanticColors light = AppSemanticColors(
    textMuted: AppColors.textMuted,
    warning: AppColors.accentDark,
    onAppBarDisabled: AppColors.textWhite.withValues(alpha: 0.38),
  );

  static final AppSemanticColors dark = AppSemanticColors(
    textMuted: AppColors.textMutedDark,
    warning: AppColors.accentLight,
    onAppBarDisabled: AppColors.textWhite.withValues(alpha: 0.38),
  );

  @override
  AppSemanticColors copyWith({
    Color? textMuted,
    Color? warning,
    Color? onAppBarDisabled,
  }) {
    return AppSemanticColors(
      textMuted: textMuted ?? this.textMuted,
      warning: warning ?? this.warning,
      onAppBarDisabled: onAppBarDisabled ?? this.onAppBarDisabled,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onAppBarDisabled:
          Color.lerp(onAppBarDisabled, other.onAppBarDisabled, t)!,
    );
  }
}

/// `context.semanticColors.textMuted` — the only supported way to reach these
/// three from a widget.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
  }
}
