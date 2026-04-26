import '../../core/network/network_exceptions.dart';
import '../../models/api/auth_models.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../session/i_session_service.dart';
import 'i_auth_service.dart';

class AuthService implements IAuthService {
  AuthService(this._api, this._session);

  final ApiClient _api;
  final ISessionService _session;

  @override
  Future<void> sendOtp(String phoneE164) async {
    try {
      await _api.post(
        ApiEndpoints.sendOtp,
        body: SendOtpRequest(phone: phoneE164).toJson(),
      );
    } on NetworkException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> verifyOtp({
    required String phoneE164,
    required String otp,
  }) async {
    late final dynamic response;
    try {
      response = await _api.post(
        ApiEndpoints.verifyOtp,
        body: VerifyOtpRequest(
          phone: phoneE164,
          otp: otp,
          role: 'admin',
        ).toJson(),
      );
    } on NetworkException catch (e) {
      throw Exception(e.message);
    }
    final parsed = VerifyOtpResponse.fromApi(response.data);
    await _session.saveToken(parsed.accessToken);
  }
}

