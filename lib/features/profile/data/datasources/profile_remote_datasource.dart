import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel?> fetchProfile(String uid);

  Future<void> writeProfile(UserProfileModel profile);
}
