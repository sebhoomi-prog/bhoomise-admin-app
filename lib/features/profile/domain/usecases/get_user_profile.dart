import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetUserProfile {
  GetUserProfile(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile?> call(String uid) => _repository.getProfile(uid);
}
