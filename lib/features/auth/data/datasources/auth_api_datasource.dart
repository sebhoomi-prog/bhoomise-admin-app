import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_error_mapper.dart';
import '../../../../core/session/app_session_service.dart';
import '../../domain/auth_exception.dart';
import '../models/auth_api_models.dart';
import '../models/auth_user_model.dart';
import 'auth_remote_datasource.dart';

class AuthApiDataSource implements AuthRemoteDataSource {
  AuthApiDataSource(
    this._apiClient,
    this._session,
    this._prefs,
  ) {
    _controller = StreamController<AuthUserModel?>.broadcast();
    // Emit initial auth state immediately so all listeners receive it.
    _lastEmittedUser = _restoreUserFromPrefs();
    Future.microtask(() => _controller.add(_lastEmittedUser));
  }

  final ApiClient _apiClient;
  final AppSessionService _session;
  final SharedPreferences _prefs;
  late final StreamController<AuthUserModel?> _controller;
  AuthUserModel? _lastEmittedUser;

  static const _kPendingPhone = 'bhoomise_pending_phone';
  static const _kUserId = 'bhoomise_auth_user_id';
  static const _kUserPhone = 'bhoomise_auth_user_phone';
  static const _kDebugOtp = 'bhoomise_debug_last_otp';

  @override
  Stream<AuthUserModel?> watchAuthState() {
    // Emit cached value immediately, then stream updates.
    return Stream.value(_lastEmittedUser).asyncExpand(
      (initial) async* {
        yield initial;
        yield* _controller.stream;
      },
    );
  }

  @override
  bool get awaitingPhoneSmsCodeEntry =>
      (_prefs.getString(_kPendingPhone) ?? '').isNotEmpty;

  @override
  Future<void> requestPhoneVerification(String phoneE164) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendOtp,
        data: SendOtpRequestModel(phone: phoneE164).toJson(),
      );
      await _prefs.setString(_kPendingPhone, phoneE164);

      // Dev-only helper: backend may return `{data: {debugOtp: 123456}}` for emulators.
      final body = response.data;
      if (body is Map) {
        final data = body['data'];
        if (data is Map) {
          final debugOtp = data['debugOtp'];
          if (debugOtp != null) {
            await _prefs.setString(_kDebugOtp, debugOtp.toString());
          }
        }
      }
    } on Object catch (e) {
      throw ApiErrorMapper.toAuthException(e);
    }
  }

  @override
  Future<void> verifySmsCode(String smsCode) async {
    final phone = _prefs.getString(_kPendingPhone);
    if (phone == null || phone.isEmpty) {
      throw AuthException('Verification session expired. Request a new code.');
    }

    const role = 'admin';
    late final dynamic response;
    try {
      response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: VerifyOtpRequestModel(
          phone: phone,
          otp: smsCode.trim(),
          role: role,
        ).toJson(),
      );
    } on Object catch (e) {
      throw ApiErrorMapper.toAuthException(e);
    }

    final payload = VerifyOtpResponseModel.fromApi(response.data);
    final token = payload.accessToken;
    final uid = payload.user.id;
    final phoneNumber =
        payload.user.phone.isNotEmpty ? payload.user.phone : phone;

    await _session.persistApiToken(token);
    await _prefs.setString(_kUserId, uid);
    await _prefs.setString(_kUserPhone, phoneNumber);
    await _prefs.remove(_kPendingPhone);
    await _prefs.remove(_kDebugOtp);

    _lastEmittedUser = AuthUserModel(uid: uid, phoneNumber: phoneNumber);
    _controller.add(_lastEmittedUser);
  }

  @override
  void abandonPhoneVerification() {
    _prefs.remove(_kPendingPhone);
    _prefs.remove(_kDebugOtp);
  }

  @override
  Future<void> signOut() async {
    await _session.clearApiToken();
    await _prefs.remove(_kPendingPhone);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kUserPhone);
    await _prefs.remove(_kDebugOtp);
    _lastEmittedUser = null;
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
}
