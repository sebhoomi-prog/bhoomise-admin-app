import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthUserModel?> watchAuthState();

  /// After [requestPhoneVerification] succeeds: user still needs to type the SMS code.
  bool get awaitingPhoneSmsCodeEntry;

  Future<void> requestPhoneVerification(String phoneE164);

  Future<void> verifySmsCode(String smsCode);

  /// Clears pending SMS session without signing out (user tapped back on OTP).
  void abandonPhoneVerification();

  Future<void> signOut();
}
