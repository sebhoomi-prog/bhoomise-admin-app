import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfile?> getProfile(String uid) => _remote.fetchProfile(uid);

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final model = UserProfileModel(
      uid: profile.uid,
      displayName: profile.displayName,
      email: profile.email,
      phoneNumber: profile.phoneNumber,
      profileCompleted: profile.profileCompleted,
    );
    await _remote.writeProfile(model);
  }
}
