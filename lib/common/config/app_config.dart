abstract final class AppConfig {
  /// API base URL for deployed hostinger backend.
  ///
  /// Current backend is mounted at `/api`, while endpoint constants include
  /// `/api/...`, yielding URLs like `https://bhoomise.tech/api/api/stores`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bhoomise.tech/api',
  );

  /// InfinityFree anti-bot: mimic browser headers and attach cookies.
  static const hostingCookie = String.fromEnvironment('HOSTING_COOKIE');
  static const userAgent = String.fromEnvironment('USER_AGENT');
  static const acceptLanguage = String.fromEnvironment('ACCEPT_LANGUAGE');
  static const browserAccept = String.fromEnvironment('BROWSER_ACCEPT');
}

