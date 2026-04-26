import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes/app_routes.dart';
import 'app_role.dart';

/// Persists [AppRole] after successful auth; drives which main shell opens after OTP.
class AppSessionService extends GetxService {
  AppSessionService(this._prefs);

  final SharedPreferences _prefs;

  static const _kRole = 'bhoomise_session_app_role';
  static const _kApiToken = 'bhoomise_session_api_token';

  final Rxn<AppRole> role = Rxn<AppRole>();

  /// Set on login before navigating to OTP; consumed when session is established.
  AppRole? _pendingRole;

  @override
  void onInit() {
    super.onInit();
    final raw = _prefs.getString(_kRole);
    if (raw == AppRole.partner.name) {
      role.value = AppRole.partner;
    } else if (raw == AppRole.customer.name) {
      role.value = AppRole.customer;
    } else if (raw == AppRole.admin.name) {
      role.value = AppRole.admin;
    }
  }

  void setPendingRole(AppRole value) {
    _pendingRole = value;
  }

  /// Returns and clears the role selected on the login screen for the current OTP flow.
  AppRole? consumePendingRole() {
    final p = _pendingRole;
    _pendingRole = null;
    return p;
  }

  Future<void> persistRole(AppRole value) async {
    role.value = value;
    await _prefs.setString(_kRole, value.name);
  }

  void clearRole() {
    _pendingRole = null;
    role.value = null;
    _prefs.remove(_kRole);
  }

  /// Admin app defaults to admin when no role is persisted yet.
  AppRole get resolvedRoleForNavigation => role.value ?? AppRole.admin;

  AppRole get effectiveRole => _pendingRole ?? role.value ?? AppRole.admin;

  String? get apiToken => _prefs.getString(_kApiToken);

  Future<void> persistApiToken(String token) async {
    await _prefs.setString(_kApiToken, token);
  }

  Future<void> clearApiToken() async {
    await _prefs.remove(_kApiToken);
  }

  /// Primary shell route for the persisted or resolved role (post-auth / splash).
  /// Admin app always redirects to admin supply dashboard.
  String get mainShellRouteAfterAuth => AppRoutes.adminSupply;
}
