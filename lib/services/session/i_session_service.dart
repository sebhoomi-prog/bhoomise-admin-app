abstract interface class ISessionService {
  String? get token;
  Future<void> saveToken(String token);
  Future<void> clear();
}

