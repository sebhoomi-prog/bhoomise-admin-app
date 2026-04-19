import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes/app_routes.dart';
import 'app_role.dart';

/// Persists [AppRole] after successful auth; drives which main shell opens after OTP.
class AppSessionService extends GetxService {
  AppSessionService(this._prefs);

  final SharedPreferences _prefs;

  static const _kRole = 'bhoomise_session_app_role';

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

  /// When restoring a session with no stored role (legacy), default to customer.
  AppRole get resolvedRoleForNavigation => role.value ?? AppRole.customer;

  /// Primary shell route for the persisted or resolved role (post-auth / splash).
  String get mainShellRouteAfterAuth {
    switch (resolvedRoleForNavigation) {
      case AppRole.admin:
        return AppRoutes.adminSupply;
      case AppRole.partner:
        return AppRoutes.partnerShell;
      case AppRole.customer:
        return AppRoutes.home;
    }
  }
}
