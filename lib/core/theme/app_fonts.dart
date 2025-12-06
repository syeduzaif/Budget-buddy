import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography system - Consistent text styles
class AppFonts {
  AppFonts._();

  // Font family
  static const String fontFamily = 'Inter';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Font sizes
  static const double sizeXs = 12.0;
  static const double sizeS = 14.0;
  static const double sizeM = 16.0;
  static const double sizeL = 18.0;
  static const double sizeXl = 20.0;
  static const double sizeXxl = 24.0;
  static const double sizeXxxl = 32.0;
  static const double sizeHuge = 40.0;

  // Heading styles
  static const TextStyle h1 = TextStyle(
    fontSize: sizeHuge,
    fontWeight: bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: sizeXxxl,
    fontWeight: bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: sizeXxl,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: sizeXl,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: sizeL,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: sizeM,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: sizeL,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: sizeM,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: sizeS,
    fontWeight: regular,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: sizeM,
    fontWeight: medium,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: sizeS,
    fontWeight: medium,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: sizeXs,
    fontWeight: medium,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Button text styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: sizeM,
    fontWeight: semiBold,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: sizeS,
    fontWeight: semiBold,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: sizeXs,
    fontWeight: semiBold,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // Caption & overline
  static const TextStyle caption = TextStyle(
    fontSize: sizeXs,
    fontWeight: regular,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const TextStyle overline = TextStyle(
    fontSize: sizeXs,
    fontWeight: medium,
    color: AppColors.textMuted,
    height: 1.3,
    letterSpacing: 1.0,
  );
}
