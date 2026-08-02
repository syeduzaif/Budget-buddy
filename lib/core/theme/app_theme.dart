import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_semantic_colors.dart';

/// 🌊 Ocean Depths — Full Material 3 ThemeData
/// Professional & calming maritime theme for Budget Buddy
///
/// Both themes register [AppSemanticColors]; widgets read muted/warning text
/// through `context.semanticColors` rather than naming a raw token, because
/// those two colours have a different right answer per brightness.
class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: AppColors.lightScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppFonts.textTheme,
        extensions: <ThemeExtension<dynamic>>[AppSemanticColors.light],

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

        // ── Filled Buttons ────────────────────────────────────────
        // Save Transaction, Create Category, Add Category — the app's primary
        // actions. Undefined, M3 fills them with `colorScheme.primary` under
        // white: #6B7F4E at 4.40:1, just under AA on the one control a user is
        // meant to aim at. primaryDark under textWhite is 6.42:1 (F-11 2).
        // The dark theme defines none and needs none: its filled buttons take
        // primaryLight under a dark on-colour, which already passes.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.textWhite,
            disabledBackgroundColor:
                AppColors.primaryDark.withValues(alpha: 0.40),
            disabledForegroundColor:
                AppColors.textWhite.withValues(alpha: 0.60),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
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
          // textSecondary, not the muted token: these two sit on `cardElevated`
          // (the field fill), where even the retuned #7A705F is 4.30:1 — short
          // of AA for the label a user reads while typing. #6B604E is 5.43:1
          // there. The two ICON slots below keep muted: a glyph is not text
          // and answers to the 3:1 non-text rule (F-11 1f).
          labelStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          hintStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          prefixIconColor: AppColors.textMuted,
          suffixIconColor: AppColors.textMuted,
        ),

        // ── Bottom Navigation ─────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.deepNavy,
          selectedItemColor: AppColors.primaryLight,
          // A LIGHT-theme block whose surface is dark, so it takes the
          // dark-surface muted value. Dead config today (the app uses
          // NavigationBar), fixed anyway so the trap cannot fire if anyone
          // switches back to BottomNavigationBar.
          unselectedItemColor: AppColors.textMutedDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedIconTheme: IconThemeData(size: 26),
          unselectedIconTheme: IconThemeData(size: 24),
        ),

        // ── Navigation Bar (M3) ──────────────────────────────────
        // M3 selects with secondaryContainer/onSecondaryContainer — terracotta
        // in this palette — so the selected icon and label must be named
        // explicitly or the app ends up with two selection colour families
        // (olive where hand-built, brown wherever M3 decides). Same reason for
        // segmentedButtonTheme below.
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.25),
          elevation: 4,
          shadowColor: AppColors.shadow,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const IconThemeData(color: AppColors.primaryDark, size: 26)
                : const IconThemeData(color: AppColors.textSecondary, size: 24),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppFonts.labelSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: AppFonts.semiBold,
                  )
                : AppFonts.labelSmall
                    .copyWith(color: AppColors.textSecondary),
          ),
        ),

        // ── Segmented Button ─────────────────────────────────────
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.textWhite
                  : AppColors.textSecondary,
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: AppColors.primary.withValues(alpha: 0.50)),
            ),
            textStyle: WidgetStatePropertyAll(AppFonts.labelMedium),
          ),
        ),

        // ── Chips ─────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardElevated,
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.25),
          disabledColor: AppColors.border,
          labelStyle: AppFonts.labelMedium,
          side: const BorderSide(color: AppColors.border),
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
          // A component theme style REPLACES the ambient DefaultTextStyle, so
          // a null colour has nothing to inherit and paints in the engine
          // default (white) — invisible on cream. See the note atop AppFonts.
          titleTextStyle: AppFonts.h5.copyWith(color: AppColors.textPrimary),
          contentTextStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
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
          // The app's only TabBar would sit in the app bar — a dark surface in
          // both themes. Dead config today, pre-fixed for the same reason as
          // the bottom-nav block above.
          unselectedLabelColor: AppColors.textMutedDark,
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
          // Explicit colour for the same reason as dialogTheme above: the
          // subtitle was visible only because AppFonts.bodySmall happens to
          // carry one.
          titleTextStyle:
              AppFonts.bodyLarge.copyWith(color: AppColors.textPrimary),
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
        extensions: <ThemeExtension<dynamic>>[AppSemanticColors.dark],

        // ── AppBar ────────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
          // Both themes' app bars are dark surfaces, so both want light
          // status-bar icons. `.dark` here painted a dark clock on #28231B.
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
              // cardDark on backgroundDark is only 1.26:1, so in dark mode
              // this border is the whole surface hierarchy — 0.10 was not
              // enough to carry it.
              color: AppColors.primaryLight.withValues(alpha: 0.20),
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
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
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
          labelStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textMutedDark),
          hintStyle:
              AppFonts.bodyMedium.copyWith(color: AppColors.textMutedDark),
          prefixIconColor: AppColors.textMutedDark,
          suffixIconColor: AppColors.textMutedDark,
        ),

        // ── Bottom Navigation ─────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMutedDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // ── Navigation Bar (M3) ──────────────────────────────────
        // The dark theme defined none at all, so the indicator pill fell back
        // to raw M3 `secondaryContainer` (terracotta). Named explicitly, same
        // as light.
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.20),
          elevation: 4,
          shadowColor: Colors.black26,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const IconThemeData(color: AppColors.primaryLight, size: 26)
                : const IconThemeData(color: AppColors.textMutedDark, size: 24),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppFonts.labelSmall.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: AppFonts.semiBold,
                  )
                : AppFonts.labelSmall.copyWith(color: AppColors.textMutedDark),
          ),
        ),

        // ── Segmented Button ─────────────────────────────────────
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primaryLight
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.deepNavy
                  : AppColors.textDark,
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.40)),
            ),
            textStyle: WidgetStatePropertyAll(
                AppFonts.labelMedium.copyWith(color: AppColors.textDark)),
          ),
        ),

        // ── Chips ─────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedColor: AppColors.primaryLight.withValues(alpha: 0.20),
          labelStyle: AppFonts.labelMedium.copyWith(color: AppColors.textDark),
          side: const BorderSide(color: AppColors.borderDark),
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
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMutedDark,
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
              AppFonts.bodySmall.copyWith(color: AppColors.textMutedDark),
          iconColor: AppColors.primaryLight,
        ),

        // ── Icon ──────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: AppColors.textMutedDark,
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
