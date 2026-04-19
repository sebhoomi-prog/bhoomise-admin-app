import 'get_user_profile.dart';

/// After phone OTP, route either to profile completion (signup) or home.
enum PostAuthDestination {
  completeProfile,
  home,
}

class ResolvePostAuthDestination {
  ResolvePostAuthDestination(this._getUserProfile);

  final GetUserProfile _getUserProfile;

  Future<PostAuthDestination> call(String uid) async {
    final profile = await _getUserProfile(uid);
    if (profile == null || !profile.profileCompleted) {
      return PostAuthDestination.completeProfile;
    }
    return PostAuthDestination.home;
  }
}
