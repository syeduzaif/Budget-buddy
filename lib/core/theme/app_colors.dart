import 'package:flutter/material.dart';

/// Ocean Depths — Professional & calming maritime color palette
/// Best for: Finance, corporate dashboards, trust-building interfaces
class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2D8B8B); // Teal accent
  static const Color primaryDark = Color(0xFF1B4965); // Ocean Blue
  static const Color primaryLight = Color(0xFFA8DADC); // Seafoam
  static const Color deepNavy = Color(0xFF1A2332); // Deep Navy

  // Secondary / Accent
  static const Color accent = Color(0xFF2D8B8B); // Teal
  static const Color accentDark = Color(0xFF1B4965); // Ocean Blue
  static const Color accentLight = Color(0xFFA8DADC); // Seafoam

  // ─── Background & Surface ─────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA); // White Smoke
  static const Color backgroundDark = Color(0xFF0D1620); // Deep ocean dark
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A2332); // Deep Navy

  // ─── Card & Container ─────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E2D3D);
  static const Color cardElevated = Color(0xFFF1FAEE); // Cream tint

  // ─── Semantic Colors ──────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A2332); // Deep Navy
  static const Color textSecondary = Color(0xFF5A6F82);
  static const Color textMuted = Color(0xFF8FA3B5);
  static const Color textWhite = Color(0xFFF1FAEE); // Cream
  static const Color textDark = Color(0xFFE8F0F2); // On-dark surfaces

  // ─── Border & Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFD0DDE6);
  static const Color borderDark = Color(0xFF2E4154);
  static const Color divider = Color(0xFFD0DDE6);

  // ─── Overlay & Shadow ─────────────────────────────────────────
  static const Color overlay = Color(0x801A2332);
  static const Color shadow = Color(0x1A1A2332);
  static const Color shadowDark = Color(0x401A2332);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B4965), Color(0xFF2D8B8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2D8B8B), Color(0xFFA8DADC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF1FAEE), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D1620), Color(0xFF1A2332)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material 3 ColorScheme — Light ───────────────────────────
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2D8B8B),
    onPrimary: Color(0xFFF1FAEE),
    primaryContainer: Color(0xFFA8DADC),
    onPrimaryContainer: Color(0xFF1A2332),
    secondary: Color(0xFF1B4965),
    onSecondary: Color(0xFFF1FAEE),
    secondaryContainer: Color(0xFFBFD7EA),
    onSecondaryContainer: Color(0xFF1A2332),
    tertiary: Color(0xFFA8DADC),
    onTertiary: Color(0xFF1A2332),
    tertiaryContainer: Color(0xFFE0F4F4),
    onTertiaryContainer: Color(0xFF1A2332),
    error: Color(0xFFE74C3C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE4E4),
    onErrorContainer: Color(0xFF8B1A1A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A2332),
    surfaceContainerHighest: Color(0xFFE8F0F2),
    onSurfaceVariant: Color(0xFF5A6F82),
    outline: Color(0xFF8FA3B5),
    outlineVariant: Color(0xFFD0DDE6),
    shadow: Color(0xFF1A2332),
    scrim: Color(0xFF1A2332),
    inverseSurface: Color(0xFF1A2332),
    onInverseSurface: Color(0xFFF1FAEE),
    inversePrimary: Color(0xFFA8DADC),
  );

  // ─── Material 3 ColorScheme — Dark ────────────────────────────
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA8DADC),
    onPrimary: Color(0xFF1A2332),
    primaryContainer: Color(0xFF1B4965),
    onPrimaryContainer: Color(0xFFA8DADC),
    secondary: Color(0xFFBFD7EA),
    onSecondary: Color(0xFF1A2332),
    secondaryContainer: Color(0xFF1B4965),
    onSecondaryContainer: Color(0xFFBFD7EA),
    tertiary: Color(0xFF2D8B8B),
    onTertiary: Color(0xFFF1FAEE),
    tertiaryContainer: Color(0xFF1B4965),
    onTertiaryContainer: Color(0xFFA8DADC),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF5C1010),
    errorContainer: Color(0xFF8B1A1A),
    onErrorContainer: Color(0xFFFCE4E4),
    surface: Color(0xFF1A2332),
    onSurface: Color(0xFFE8F0F2),
    surfaceContainerHighest: Color(0xFF2E4154),
    onSurfaceVariant: Color(0xFF8FA3B5),
    outline: Color(0xFF5A6F82),
    outlineVariant: Color(0xFF2E4154),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF1FAEE),
    onInverseSurface: Color(0xFF1A2332),
    inversePrimary: Color(0xFF1B4965),
  );
}
