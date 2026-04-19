import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.displayName,
    super.email,
    super.phoneNumber,
    required super.profileCompleted,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfileModel(
      uid: uid,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profileCompleted: json['profileCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileCompleted': profileCompleted,
    };
  }
}
