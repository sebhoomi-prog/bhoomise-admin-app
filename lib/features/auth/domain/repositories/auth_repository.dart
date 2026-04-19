import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  /// After [sendPhoneVerificationCode] succeeds: whether the SMS code UI should be shown.
  bool get awaitingPhoneSmsCodeEntry;

  Future<void> sendPhoneVerificationCode(String phoneE164);

  Future<void> verifySmsCode(String smsCode);

  void abandonPhoneVerification();

  Future<void> signOut();
}
