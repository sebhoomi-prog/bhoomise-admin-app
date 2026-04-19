import '../repositories/auth_repository.dart';

class SendPhoneVerification {
  SendPhoneVerification(this._repository);

  final AuthRepository _repository;

  Future<void> call(String phoneE164) =>
      _repository.sendPhoneVerificationCode(phoneE164);
}
