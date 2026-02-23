import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Ocean Depths Typography System
/// Display/Headlines: Merriweather (serif — authoritative, trustworthy)
/// Body/Labels: Source Sans Pro (clean, highly readable)
class AppFonts {
  AppFonts._();

  // ─── Font Families ────────────────────────────────────────────
  static String get fontFamily => GoogleFonts.sourceSans3().fontFamily!;
  static String get displayFontFamily => GoogleFonts.merriweather().fontFamily!;

  // ─── Font Weights ─────────────────────────────────────────────
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ─── Font Sizes ───────────────────────────────────────────────
  static const double sizeXs = 12.0;
  static const double sizeS = 14.0;
  static const double sizeM = 16.0;
  static const double sizeL = 18.0;
  static const double sizeXl = 20.0;
  static const double sizeXxl = 24.0;
  static const double sizeXxxl = 32.0;
  static const double sizeHuge = 40.0;

  // ─── Heading Styles (Merriweather) ────────────────────────────
  static TextStyle get h1 => GoogleFonts.merriweather(
        fontSize: sizeHuge,
        fontWeight: bold,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.merriweather(
        fontSize: sizeXxxl,
        fontWeight: bold,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get h3 => GoogleFonts.merriweather(
        fontSize: sizeXxl,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get h4 => GoogleFonts.merriweather(
        fontSize: sizeXl,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h5 => GoogleFonts.merriweather(
        fontSize: sizeL,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h6 => GoogleFonts.merriweather(
        fontSize: sizeM,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  // ─── Body Text Styles (Source Sans 3) ─────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.sourceSans3(
        fontSize: sizeL,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.sourceSans3(
        fontSize: sizeM,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.sourceSans3(
        fontSize: sizeS,
        fontWeight: regular,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ─── Label Styles (Source Sans 3) ─────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.sourceSans3(
        fontSize: sizeM,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.sourceSans3(
        fontSize: sizeS,
        fontWeight: medium,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.sourceSans3(
        fontSize: sizeXs,
        fontWeight: medium,
        color: AppColors.textMuted,
        height: 1.4,
      );

  // ─── Button Text Styles ───────────────────────────────────────
  static TextStyle get buttonLarge => GoogleFonts.sourceSans3(
        fontSize: sizeM,
        fontWeight: semiBold,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => GoogleFonts.sourceSans3(
        fontSize: sizeS,
        fontWeight: semiBold,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => GoogleFonts.sourceSans3(
        fontSize: sizeXs,
        fontWeight: semiBold,
        color: AppColors.textWhite,
        height: 1.2,
        letterSpacing: 0.5,
      );

  // ─── Caption & Overline ───────────────────────────────────────
  static TextStyle get caption => GoogleFonts.sourceSans3(
        fontSize: sizeXs,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.3,
      );

  static TextStyle get overline => GoogleFonts.sourceSans3(
        fontSize: sizeXs,
        fontWeight: medium,
        color: AppColors.textMuted,
        height: 1.3,
        letterSpacing: 1.5,
      );

  // ─── Material 3 TextTheme ─────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.merriweather(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displayMedium: GoogleFonts.merriweather(
          fontSize: 45,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.merriweather(
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.merriweather(
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.merriweather(
          fontSize: 28,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: GoogleFonts.merriweather(
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.sourceSans3(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.sourceSans3(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.sourceSans3(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.sourceSans3(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        bodyMedium: GoogleFonts.sourceSans3(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: GoogleFonts.sourceSans3(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: GoogleFonts.sourceSans3(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.sourceSans3(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.sourceSans3(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}
