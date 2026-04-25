import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/session/app_role.dart';
import '../../../../core/session/app_session_service.dart';
import '../../domain/auth_exception.dart';
import '../models/auth_user_model.dart';
import 'auth_remote_datasource.dart';

class AuthApiDataSource implements AuthRemoteDataSource {
  AuthApiDataSource(
    this._apiClient,
    this._session,
    this._prefs,
  ) {
    _controller = StreamController<AuthUserModel?>.broadcast(
      onListen: () => _controller.add(_restoreUserFromPrefs()),
    );
  }

  final ApiClient _apiClient;
  final AppSessionService _session;
  final SharedPreferences _prefs;
  late final StreamController<AuthUserModel?> _controller;

  static const _kPendingPhone = 'bhoomise_pending_phone';
  static const _kUserId = 'bhoomise_auth_user_id';
  static const _kUserPhone = 'bhoomise_auth_user_phone';

  @override
  Stream<AuthUserModel?> watchAuthState() => _controller.stream;

  @override
  bool get awaitingPhoneSmsCodeEntry =>
      (_prefs.getString(_kPendingPhone) ?? '').isNotEmpty;

  @override
  Future<void> requestPhoneVerification(String phoneE164) async {
    await _apiClient.post(
      ApiEndpoints.sendOtp,
      data: {'phone': phoneE164},
    );
    await _prefs.setString(_kPendingPhone, phoneE164);
  }

  @override
  Future<void> verifySmsCode(String smsCode) async {
    final phone = _prefs.getString(_kPendingPhone);
    if (phone == null || phone.isEmpty) {
      throw AuthException('Verification session expired. Request a new code.');
    }

    final role = _roleToApi(_session.effectiveRole);
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phone': phone,
        'otp': smsCode.trim(),
        'role': role,
      },
    );

    final body = response.data;
    if (body is! Map) {
      throw AuthException('Invalid server response.');
    }
    final data = body['data'];
    if (data is! Map) {
      throw AuthException('Invalid auth payload.');
    }

    final token = (data['accessToken'] ?? '').toString().trim();
    final user = data['user'];
    if (token.isEmpty || user is! Map) {
      throw AuthException('Invalid auth payload.');
    }

    final uid = (user['id'] ?? '').toString();
    final phoneNumber = (user['phone'] ?? phone).toString();

    await _session.persistApiToken(token);
    await _prefs.setString(_kUserId, uid);
    await _prefs.setString(_kUserPhone, phoneNumber);
    await _prefs.remove(_kPendingPhone);

    _controller.add(AuthUserModel(uid: uid, phoneNumber: phoneNumber));
  }

  @override
  void abandonPhoneVerification() {
    _prefs.remove(_kPendingPhone);
  }

  @override
  Future<void> signOut() async {
    await _session.clearApiToken();
    await _prefs.remove(_kPendingPhone);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kUserPhone);
    _controller.add(null);
  }

  AuthUserModel? _restoreUserFromPrefs() {
    final token = _session.apiToken;
    final uid = _prefs.getString(_kUserId);
    if (token == null || token.isEmpty || uid == null || uid.isEmpty) {
      return null;
    }
    final phone = _prefs.getString(_kUserPhone);
    return AuthUserModel(uid: uid, phoneNumber: phone);
  }

  String _roleToApi(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'admin';
      case AppRole.partner:
        return 'partner';
      case AppRole.customer:
        return 'customer';
    }
  }
}
