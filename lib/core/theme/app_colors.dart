import 'package:flutter/material.dart';

/// Velvet Glow — Warm plum & amber, dark-first palette
/// Calm intelligence · Trust · Personal guidance · Premium comfort
/// Designed for long dark-mode sessions with financial data
class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF8B6FC0); // Soft plum
  static const Color primaryDark = Color(0xFF6B5299); // Deep plum
  static const Color primaryLight = Color(0xFFB4A0D6); // Lavender mist
  static const Color deepNavy =
      Color(0xFF1C1626); // Deep warm dark (kept name for compat)

  // Secondary / Accent
  static const Color secondary = Color(0xFFD4A05A); // Warm amber-gold
  static const Color accent = Color(0xFFD4A05A); // Warm amber
  static const Color accentLight = Color(0xFFEBC88A); // Pale gold
  static const Color accentDark = Color(0xFFB8873D); // Deep amber

  // ─── Background & Surface ─────────────────────────────────────
  static const Color background =
      Color(0xFFFAF8FC); // Warm off-white (subtle plum tint)
  static const Color backgroundDark = Color(0xFF1A1525); // Warm charcoal plum
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF221D2E); // Warm dark surface

  // ─── Card & Container ─────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2A2438); // Warm plum card
  static const Color cardElevated = Color(0xFFF4F1F8); // Light plum tint

  // ─── Semantic Colors (warm-tinted) ────────────────────────────
  static const Color success = Color(0xFF5CB88A); // Warm sage green
  static const Color error = Color(0xFFD4605A); // Warm coral red
  static const Color warning = Color(0xFFD4A05A); // Amber (matches accent)
  static const Color info = Color(0xFF7B8EC8); // Soft lavender-blue

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E1A28); // Warm near-black
  static const Color textSecondary = Color(0xFF6B6180); // Muted plum-grey
  static const Color textMuted = Color(0xFF9590A3); // Light purple-grey
  static const Color textWhite = Color(0xFFF5F2F8); // Warm white
  static const Color textDark = Color(0xFFEDE9F3); // On dark surfaces

  // ─── Border & Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFE6E1ED); // Warm light border
  static const Color borderDark = Color(0xFF3B3450); // Warm dark border
  static const Color divider = Color(0xFFE6E1ED);

  // ─── Overlay & Shadow ─────────────────────────────────────────
  static const Color overlay = Color(0x801A1525); // Warm overlay
  static const Color shadow = Color(0x1A1A1525); // Warm shadow
  static const Color shadowDark = Color(0x401A1525);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B5299), Color(0xFF8B6FC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD4A05A), Color(0xFFEBC88A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F1F8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1525), Color(0xFF221D2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material 3 ColorScheme — Light ───────────────────────────
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8B6FC0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEDE5F7),
    onPrimaryContainer: Color(0xFF3D2A61),
    secondary: Color(0xFFD4A05A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFAEDD6),
    onSecondaryContainer: Color(0xFF5C3F14),
    tertiary: Color(0xFF5CB88A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD9F2E4),
    onTertiaryContainer: Color(0xFF1B5E3A),
    error: Color(0xFFD4605A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE4E3),
    onErrorContainer: Color(0xFF6B1F1B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1E1A28),
    surfaceContainerHighest: Color(0xFFF4F1F8),
    onSurfaceVariant: Color(0xFF6B6180),
    outline: Color(0xFF9590A3),
    outlineVariant: Color(0xFFE6E1ED),
    shadow: Color(0xFF1A1525),
    scrim: Color(0xFF1A1525),
    inverseSurface: Color(0xFF2A2438),
    onInverseSurface: Color(0xFFF5F2F8),
    inversePrimary: Color(0xFFB4A0D6),
  );

  // ─── Material 3 ColorScheme — Dark ────────────────────────────
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB4A0D6),
    onPrimary: Color(0xFF1E1A28),
    primaryContainer: Color(0xFF3D2A61),
    onPrimaryContainer: Color(0xFFEDE5F7),
    secondary: Color(0xFFEBC88A),
    onSecondary: Color(0xFF1E1A28),
    secondaryContainer: Color(0xFF5C3F14),
    onSecondaryContainer: Color(0xFFFAEDD6),
    tertiary: Color(0xFF8CD4AE),
    onTertiary: Color(0xFF1E1A28),
    tertiaryContainer: Color(0xFF1B5E3A),
    onTertiaryContainer: Color(0xFFD9F2E4),
    error: Color(0xFFE8918B),
    onError: Color(0xFF3D0D0A),
    errorContainer: Color(0xFF6B1F1B),
    onErrorContainer: Color(0xFFFCE4E3),
    surface: Color(0xFF1A1525),
    onSurface: Color(0xFFEDE9F3),
    surfaceContainerHighest: Color(0xFF2A2438),
    onSurfaceVariant: Color(0xFF9590A3),
    outline: Color(0xFF6B6180),
    outlineVariant: Color(0xFF3B3450),
    shadow: Color(0xFF0D0A12),
    scrim: Color(0xFF0D0A12),
    inverseSurface: Color(0xFFF5F2F8),
    onInverseSurface: Color(0xFF1E1A28),
    inversePrimary: Color(0xFF6B5299),
  );
}
