import 'package:flutter/material.dart';

/// Premium Minimal — High-end, clean finance palette
/// Best for: Budget apps, productivity tools, premium products
class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // Navy
  static const Color primaryDark = Color(0xFF020617); // Near black navy
  static const Color primaryLight = Color(0xFF1E293B); // Soft navy
  static const Color deepNavy = Color(0xFF020617);

  // Secondary / Accent
  static const Color secondary = Color(0xFF3B82F6); // Premium blue
  static const Color accent = Color(0xFFF59E0B); // Gold accent
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentDark = Color(0xFFD97706);

  // ─── Background & Surface ─────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB); // Off white
  static const Color backgroundDark = Color(0xFF020617); // Dark navy
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A);

  // ─── Card & Container ─────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF111827);
  static const Color cardElevated = Color(0xFFF3F4F6);

  // ─── Semantic Colors ──────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFE5E7EB); // On dark surfaces

  // ─── Border & Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFE5E7EB);

  // ─── Overlay & Shadow ─────────────────────────────────────────
  static const Color overlay = Color(0x80000000);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF020617), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material 3 ColorScheme — Light ───────────────────────────
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F172A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5E7EB),
    onPrimaryContainer: Color(0xFF020617),
    secondary: Color(0xFF3B82F6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDBEAFE),
    onSecondaryContainer: Color(0xFF1E3A8A),
    tertiary: Color(0xFFF59E0B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF78350F),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF111827),
    surfaceContainerHighest: Color(0xFFF3F4F6),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFFE5E7EB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF111827),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFFE5E7EB),
  );

  // ─── Material 3 ColorScheme — Dark ────────────────────────────
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE5E7EB),
    onPrimary: Color(0xFF020617),
    primaryContainer: Color(0xFF1E293B),
    onPrimaryContainer: Color(0xFFE5E7EB),
    secondary: Color(0xFF60A5FA),
    onSecondary: Color(0xFF020617),
    secondaryContainer: Color(0xFF1E3A8A),
    onSecondaryContainer: Color(0xFFDBEAFE),
    tertiary: Color(0xFFFCD34D),
    onTertiary: Color(0xFF020617),
    tertiaryContainer: Color(0xFF78350F),
    onTertiaryContainer: Color(0xFFFEF3C7),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF020617),
    onSurface: Color(0xFFE5E7EB),
    surfaceContainerHighest: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFF374151),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF9FAFB),
    onInverseSurface: Color(0xFF111827),
    inversePrimary: Color(0xFF1E293B),
  );
}
