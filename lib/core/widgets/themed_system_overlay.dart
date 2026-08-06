import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// RULE S — whatever paints behind the status bar declares the status bar's
/// style (D-017).
///
/// The app bar is a dark surface in **both** themes (`app_theme.dart:54`,
/// `:402`) and always asks for light icons, which is why the six screens that
/// have one are already correct. The two screens with no app bar — the splash
/// and onboarding — paint the scaffold themselves and declared **nothing**, so
/// Flutter applied no annotation and whatever style the last screen set simply
/// persisted. After an "Erase all data" that is the dashboard's `.light`, i.e.
/// light icons on a cream onboarding: an invisible clock, battery and signal on
/// the first screen of a product whose pitch is care with your money. One
/// defect, filed four times (UI-32, N12, FD-15, QA-BUG-004), reachable on every
/// fresh install and after every erase.
///
/// Wrap it in this, and the declaration follows the surface for the life of the
/// screen.
///
/// Three things this widget is deliberately NOT:
///
/// * **It does not read the device brightness.** A user may force Light on a
///   dark phone (`settings_service.dart:116-125`); the scaffold behind the
///   status bar is then cream whatever the OS thinks. So the style is resolved
///   from `Theme.of(context).brightness` and never `MediaQuery.platformBrightness`.
/// * **It does not hand over `SystemUiOverlayStyle.light` / `.dark` wholesale.**
///   Those constants also carry `systemNavigationBar*` values, and this app has
///   never styled the Android system navigation bar. A status-bar fix that
///   quietly starts styling the bottom system bar is a second, unreviewed
///   change (palwasha, non-negotiable). Only the two status-bar fields are
///   declared here; `statusBarColor` stays null too — the app has never painted
///   the status bar's background and this is not the change that starts.
/// * **It is not for screens that have an `AppBar`.** Those already declare
///   through `AppBarTheme`, and two declarations at the top of one screen is
///   precisely the ambiguity this rule exists to remove.
///
/// The constant names invert, and that inversion is how this bug happens:
/// `Brightness.light` on `statusBarIconBrightness` means **light-coloured
/// icons**, i.e. for a dark background. Anything reading "light theme →
/// light" is wrong by construction.
class ThemedSystemOverlay extends StatelessWidget {
  const ThemedSystemOverlay({super.key, required this.child});

  final Widget child;

  /// The style a surface of [brightness] needs behind it.
  ///
  /// Exposed so a test can state the rule without a widget tree, and so the
  /// inversion above is written down exactly once.
  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      // Android.
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      // iOS, which names the same thing after the background instead.
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleFor(Theme.of(context).brightness),
      child: child,
    );
  }
}
