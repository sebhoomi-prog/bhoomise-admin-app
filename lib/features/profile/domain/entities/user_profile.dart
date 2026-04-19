class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.phoneNumber,
    required this.profileCompleted,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final bool profileCompleted;

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    bool? profileCompleted,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}
