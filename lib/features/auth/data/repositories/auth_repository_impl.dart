import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AuthUser?> watchAuthState() => _remote.watchAuthState();

  @override
  bool get awaitingPhoneSmsCodeEntry => _remote.awaitingPhoneSmsCodeEntry;

  @override
  Future<void> sendPhoneVerificationCode(String phoneE164) =>
      _remote.requestPhoneVerification(phoneE164);

  @override
  Future<void> verifySmsCode(String smsCode) => _remote.verifySmsCode(smsCode);

  @override
  void abandonPhoneVerification() => _remote.abandonPhoneVerification();

  @override
  Future<void> signOut() => _remote.signOut();
}
