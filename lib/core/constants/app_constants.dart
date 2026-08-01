/// Centralized app constants — single source of truth for version and branding.
class AppConstants {
  AppConstants._();

  static const String appName = 'BuddgetBuddy';
  /// Kept in lockstep with `pubspec.yaml`'s `version:` — this string is what
  /// Settings and the splash screen show, and nothing derives it from the
  /// pubspec at runtime. Reset to 1.0.0 for the first real release (PRD D1):
  /// the inherited 1.1.0+3 counted CI builds of an unreleased app and would
  /// have shipped a "second-version" claim to a first-time user.
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Budgeting, Simply Done';
}
