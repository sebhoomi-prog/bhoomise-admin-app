/// Domain-level auth failure (mapped from remote/local auth in the data layer).
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
