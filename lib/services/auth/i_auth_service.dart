abstract interface class IAuthService {
  Future<void> sendOtp(String phoneE164);
  Future<void> verifyOtp({
    required String phoneE164,
    required String otp,
  });
}

