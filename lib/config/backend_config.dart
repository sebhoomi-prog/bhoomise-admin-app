import '../core/constants/app_constants.dart';

/// Backend selection for **data sources** registered in GetX bindings.
///
/// **Production target:** Firebase — Authentication (phone / OTP), Cloud Firestore,
/// Firebase Storage. Domain and presentation stay free of Firebase imports; only
/// `features/*/data/` and `modules/*/data/` (e.g. `*_firebase_datasource.dart`) call the SDKs.
///
/// **Development / staged rollout:**
/// - Default (no `API_BASE_URL`): bundled JSON under `assets/mock_api/` via
///   [MockAssetClient], plus SharedPreferences (session) and **Hive** ([LocalStorage])
///   for structured offline data (cart) and sync flags.
/// - `flutter run --dart-define=API_BASE_URL=https://api.example.com/api`:
///   REST via [ApiClient] / Dio in `*_remote_datasource.dart` only.
enum BackendType {
  /// SharedPreferences-backed auth, profile, addresses; optional mock fixtures.
  local,

  /// REST API when a base URL is configured (`BackendConfig.hasRestApi`).
  api,
}

class BackendConfig {
  BackendConfig._();

  /// When non-empty, [ApiClient] is registered and REST data sources may be used.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AppConstants.defaultApiBaseUrl,
  );

  /// True when a live API base URL is configured (`dart-define=API_BASE_URL=...`).
  static bool get hasRestApi => apiBaseUrl.trim().isNotEmpty;

  /// Bundled `assets/mock_api/*.json` fixtures (no HTTP) when [hasRestApi] is false.
  static bool get useMockApiAssets => !hasRestApi;

  /// Product catalog from Firestore (`products` collection) instead of asset JSON.
  ///
  /// After Firebase + seed, use `true` (default) so the app shows seeded / live data.
  /// Offline UI dev with assets only: `--dart-define=USE_FIRESTORE=false`
  static bool get useFirestoreCatalog =>
      const bool.fromEnvironment('USE_FIRESTORE', defaultValue: true);

  static BackendType current = BackendType.local;
}
