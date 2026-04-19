class AuthUser {
  const AuthUser({
    required this.uid,
    this.phoneNumber,
  });

  final String uid;
  final String? phoneNumber;
}
