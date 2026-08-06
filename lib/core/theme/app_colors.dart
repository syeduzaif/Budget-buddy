import 'package:flutter/material.dart';

/// Terra Firma — Earthy & natural palette
/// Grounded · Organic · Warm · Trustworthy
/// Inspired by sun-baked clay, forest canopy, and golden harvest
class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF6B7F4E); // Olive green
  static const Color primaryDark = Color(0xFF4E5E38); // Deep forest
  static const Color primaryLight = Color(0xFF9DB87C); // Sage green
  static const Color deepNavy =
      Color(0xFF2C2518); // Rich espresso (kept name for compat)

  // Secondary / Accent
  static const Color secondary = Color(0xFFBF7B4B); // Terracotta
  static const Color accent = Color(0xFFBF7B4B); // Terracotta
  static const Color accentLight = Color(0xFFD9A87C); // Sandy clay
  static const Color accentDark = Color(0xFF9A5F35); // Burnt sienna

  // ─── Background & Surface ─────────────────────────────────────
  static const Color background = Color(0xFFFAF7F2); // Warm linen
  static const Color backgroundDark = Color(0xFF1E1B15); // Dark loam
  static const Color surface = Color(0xFFFFFDF8); // Cream white
  static const Color surfaceDark = Color(0xFF28231B); // Dark walnut

  // ─── Card & Container ─────────────────────────────────────────
  static const Color card = Color(0xFFFFFDF8); // Cream white
  static const Color cardDark = Color(0xFF332D23); // Warm dark bark
  static const Color cardElevated = Color(0xFFF5F0E8); // Parchment

  // ─── Semantic Colors (warm-tinted) ────────────────────────────
  static const Color success = Color(0xFF5A9E6F); // Forest green
  static const Color error = Color(0xFFC25D4E); // Terra red
  static const Color warning = Color(0xFFD4A04A); // Harvest gold
  static const Color info = Color(0xFF6B8DAD); // Dusty sky blue

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C2518); // Espresso
  static const Color textSecondary = Color(0xFF6B604E); // Driftwood

  /// Third-rank text ON LIGHT SURFACES. Retuned from #9A9182, which measured
  /// 3.06:1 on the cream card — the last light-theme AA failure (F-11).
  ///
  /// Muted text has one meaning and two values; this is the light half. Read it
  /// through `context.semanticColors.textMuted` (see `app_semantic_colors.dart`)
  /// rather than naming either token in a widget, or the same widget renders
  /// unreadably in the other theme — which is the defect this pair replaced.
  static const Color textMuted = Color(0xFF7A705F); // Dark driftwood

  /// Third-rank text ON DARK SURFACES. Retuned from #9A9182, which measured
  /// 4.38:1 on the dark card — the AA shortfall F-11 pinned rather than closed,
  /// because closing it was out of that ticket's scope. #A19889 is 4.78:1
  /// there and 6.03:1 on the dark background (D-018).
  ///
  /// Also the value the two light-theme component blocks whose surface is dark
  /// (bottom-nav and tab-bar unselected) must use.
  ///
  /// ⚠️ `kUncategorisedColorValue` (`app_constants.dart:58`) still holds this
  /// token's OLD value, deliberately. It is written into every reserved-bucket
  /// record, so it must not follow a text retune — a stored colour that drifts
  /// with the theme repaints history, per month, forever, with no migration.
  /// Never find-and-replace the two together; `theme_contrast_test.dart` pins
  /// the constant by literal for exactly this reason.
  static const Color textMutedDark =
      Color(0xFFA19889); // Warm stone, lightened
  static const Color textWhite = Color(0xFFF8F4ED); // Warm cream
  static const Color textDark = Color(0xFFEDE8DF); // On dark surfaces

  // ─── Border & Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFE3DDD2); // Sand
  static const Color borderDark = Color(0xFF4A4235); // Dark clay
  static const Color divider = Color(0xFFE3DDD2);

  // ─── Overlay & Shadow ─────────────────────────────────────────
  static const Color overlay = Color(0x801E1B15); // Warm overlay
  static const Color shadow = Color(0x1A2C2518); // Warm shadow
  static const Color shadowDark = Color(0x402C2518);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4E5E38), Color(0xFF6B7F4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFBF7B4B), Color(0xFFD9A87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFDF8), Color(0xFFF5F0E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1E1B15), Color(0xFF28231B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material 3 ColorScheme — Light ───────────────────────────
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6B7F4E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE2EDD3),
    onPrimaryContainer: Color(0xFF2A3520),
    secondary: Color(0xFFBF7B4B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5E1D0),
    onSecondaryContainer: Color(0xFF5A3018),
    tertiary: Color(0xFF5A9E6F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD5EDDC),
    onTertiaryContainer: Color(0xFF1B4D2B),
    error: Color(0xFFC25D4E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE0DC),
    onErrorContainer: Color(0xFF5E1F17),
    surface: Color(0xFFFFFDF8),
    onSurface: Color(0xFF2C2518),
    surfaceContainerHighest: Color(0xFFF5F0E8),
    onSurfaceVariant: Color(0xFF6B604E),
    outline: Color(0xFF9A9182),
    outlineVariant: Color(0xFFE3DDD2),
    shadow: Color(0xFF2C2518),
    scrim: Color(0xFF2C2518),
    inverseSurface: Color(0xFF332D23),
    onInverseSurface: Color(0xFFF8F4ED),
    inversePrimary: Color(0xFF9DB87C),
  );

  // ─── Material 3 ColorScheme — Dark ────────────────────────────
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9DB87C),
    onPrimary: Color(0xFF1E1B15),
    primaryContainer: Color(0xFF2A3520),
    onPrimaryContainer: Color(0xFFE2EDD3),
    secondary: Color(0xFFD9A87C),
    onSecondary: Color(0xFF1E1B15),
    secondaryContainer: Color(0xFF5A3018),
    onSecondaryContainer: Color(0xFFF5E1D0),
    tertiary: Color(0xFF8CC4A0),
    onTertiary: Color(0xFF1E1B15),
    tertiaryContainer: Color(0xFF1B4D2B),
    onTertiaryContainer: Color(0xFFD5EDDC),
    error: Color(0xFFE89088),
    onError: Color(0xFF3D0D08),
    errorContainer: Color(0xFF5E1F17),
    onErrorContainer: Color(0xFFFCE0DC),
    surface: Color(0xFF1E1B15),
    onSurface: Color(0xFFEDE8DF),
    surfaceContainerHighest: Color(0xFF332D23),
    // Kept in step with [textMutedDark] by hand — same meaning, same value,
    // and it carries the "of ₨45,000" limit caption on the dark card
    // (`category_card.dart:122`), which is a money figure (D-018).
    onSurfaceVariant: Color(0xFFA19889),
    outline: Color(0xFF6B604E),
    outlineVariant: Color(0xFF4A4235),
    shadow: Color(0xFF0F0D0A),
    scrim: Color(0xFF0F0D0A),
    inverseSurface: Color(0xFFF8F4ED),
    onInverseSurface: Color(0xFF2C2518),
    inversePrimary: Color(0xFF4E5E38),
  );
}
