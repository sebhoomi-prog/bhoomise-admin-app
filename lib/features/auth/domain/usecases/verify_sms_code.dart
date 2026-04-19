import '../repositories/auth_repository.dart';

class VerifySmsCode {
  VerifySmsCode(this._repository);

  final AuthRepository _repository;

  Future<void> call(String smsCode) => _repository.verifySmsCode(smsCode);
}
