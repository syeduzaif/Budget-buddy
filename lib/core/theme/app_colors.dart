import 'package:flutter/material.dart';

/// App color palette - Modern finance app theme
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5548E8);
  static const Color primaryLight = Color(0xFF8B85FF);

  // Secondary/Accent Colors
  static const Color accent = Color(0xFF00D9A3);
  static const Color accentDark = Color(0xFF00B386);
  static const Color accentLight = Color(0xFF33E3B8);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF252541);

  // Card & Container Colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D44);
  static const Color cardElevated = Color(0xFFFAFAFC);

  // Semantic Colors
  static const Color success = Color(0xFF00D9A3);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB800);
  static const Color info = Color(0xFF4ECDC4);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFE5E7EB);

  // Border & Divider Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFE5E7EB);

  // Overlay & Shadow Colors
  static const Color overlay = Color(0x80000000);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
