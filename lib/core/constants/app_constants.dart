/// Centralized app constants — single source of truth for version and branding.
class AppConstants {
  AppConstants._();

  static const String appName = 'BuddgetBuddy';
  static const String appVersion = '1.1.0';
  static const String appTagline = 'Smart Budgeting, Simply Done';

  /// Base URL of the BuddgetBuddy web backend that hosts the authenticated AI
  /// proxy (`/api/chat`, `/api/insights`). Supplied at build time:
  ///   `flutter build apk --release --dart-define=API_BASE_URL=https://example.com`
  /// No trailing slash. Empty (the default) means AI features are not
  /// configured in this build: they must fail with a clear message, never crash.
  /// Never put a provider API key here — the proxy holds the only key.
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static bool get isAiConfigured => apiBaseUrl.isNotEmpty;
}
