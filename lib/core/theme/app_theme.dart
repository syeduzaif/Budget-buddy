import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// 🌊 Ocean Depths — Full Material 3 ThemeData
/// Professional & calming maritime theme for Budget Buddy
class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: AppColors.lightScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppFonts.textTheme,

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepNavy,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: AppFonts.h5.copyWith(
            color: AppColors.textWhite,
          ),
          iconTheme: const IconThemeData(
            color: AppColors.textWhite,
            size: 22,
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shadowColor: AppColors.shadow,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryLight.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
        ),

        // ── Elevated Buttons ──────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.40),
            disabledForegroundColor:
                AppColors.textWhite.withValues(alpha: 0.60),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: AppFonts.buttonLarge,
          ),
        ),

        // ── Outlined Buttons ──────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: AppFonts.buttonLarge.copyWith(color: AppColors.primary),
          ),
        ),

        // ── Text Buttons ──────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppFonts.buttonMedium.copyWith(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ── Floating Action Button ────────────────────────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 4,
          focusElevation: 6,
          hoverElevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ── Input Decoration ──────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textMuted),
          hintStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIconColor: AppColors.textMuted,
          suffixIconColor: AppColors.textMuted,
        ),

        // ── Bottom Navigation ─────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.deepNavy,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedIconTheme: IconThemeData(size: 26),
          unselectedIconTheme: IconThemeData(size: 24),
        ),

        // ── Navigation Bar (M3) ──────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.25),
          elevation: 4,
          shadowColor: AppColors.shadow,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),

        // ── Chips ─────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardElevated,
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.25),
          disabledColor: AppColors.border,
          labelStyle: AppFonts.labelMedium,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: AppFonts.h5,
          contentTextStyle: AppFonts.bodyMedium,
        ),

        // ── Bottom Sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.border,
        ),

        // ── Snackbar ──────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.deepNavy,
          contentTextStyle: AppFonts.bodyMedium.copyWith(
            color: AppColors.textWhite,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
        ),

        // ── TabBar ────────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppFonts.labelLarge,
          unselectedLabelStyle: AppFonts.labelMedium,
        ),

        // ── ListTile ──────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle: AppFonts.bodyLarge,
          subtitleTextStyle: AppFonts.bodySmall,
          iconColor: AppColors.primary,
        ),

        // ── Icon ──────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 24,
        ),

        // ── Progress Indicators ───────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.border,
          circularTrackColor: AppColors.border,
        ),

        // ── Switch ────────────────────────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textMuted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryLight.withValues(alpha: 0.5);
            }
            return AppColors.border;
          }),
        ),

        // ── Tooltip ───────────────────────────────────────────────
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppFonts.caption.copyWith(color: AppColors.textWhite),
        ),
      );

  // ─── Dark Theme ───────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: AppColors.darkScheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppFonts.textTheme,

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppFonts.h5.copyWith(
            color: AppColors.textDark,
          ),
          iconTheme: const IconThemeData(
            color: AppColors.textDark,
            size: 22,
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 2,
          shadowColor: Colors.black26,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryLight.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),

        // ── Elevated Buttons ──────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.deepNavy,
            disabledBackgroundColor:
                AppColors.primaryLight.withValues(alpha: 0.30),
            disabledForegroundColor: AppColors.deepNavy.withValues(alpha: 0.50),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 2,
            shadowColor: AppColors.primaryLight.withValues(alpha: 0.20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: AppFonts.buttonLarge,
          ),
        ),

        // ── Outlined Buttons ──────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: BorderSide(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // ── Text Buttons ──────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ── Floating Action Button ────────────────────────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.deepNavy,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ── Input Decoration ──────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textMuted),
          hintStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIconColor: AppColors.textMuted,
          suffixIconColor: AppColors.textMuted,
        ),

        // ── Bottom Navigation ─────────────────────────────────────
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // ── Chips ─────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.20),
          labelStyle: AppFonts.labelMedium.copyWith(color: AppColors.textDark),
          side: BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 1,
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.cardDark,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: AppFonts.h5.copyWith(color: AppColors.textDark),
          contentTextStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textDark),
        ),

        // ── Bottom Sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.cardDark,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.borderDark,
        ),

        // ── Snackbar ──────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.cardDark,
          contentTextStyle: AppFonts.bodyMedium.copyWith(
            color: AppColors.textDark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // ── TabBar ────────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
        ),

        // ── ListTile ──────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle:
              AppFonts.bodyLarge.copyWith(color: AppColors.textDark),
          subtitleTextStyle:
              AppFonts.bodySmall.copyWith(color: AppColors.textMuted),
          iconColor: AppColors.primaryLight,
        ),

        // ── Icon ──────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: AppColors.textMuted,
          size: 24,
        ),

        // ── Progress Indicators ───────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryLight,
          linearTrackColor: AppColors.borderDark,
          circularTrackColor: AppColors.borderDark,
        ),

        // ── Tooltip ───────────────────────────────────────────────
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppFonts.caption.copyWith(color: AppColors.textDark),
        ),
      );

  // ─── Convenience aliases (backward compat) ────────────────────
  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;
}
