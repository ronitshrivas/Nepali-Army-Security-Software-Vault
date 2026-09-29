/// Central configuration. The API base URL can be overridden at build time:
///   flutter run --dart-define=API_BASE_URL=https://your-host
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vault-production-463b.up.railway.app',
  );

  static const appName = 'Secure Officer Vault';
  static const orgName = 'Nepali Army';
}
