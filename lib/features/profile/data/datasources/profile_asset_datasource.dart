import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/mock_asset_client.dart';
import '../models/user_profile_model.dart';
import 'profile_remote_datasource.dart';

/// Reads profile from `user/me.json` (API-shaped); writes still use prefs per uid.
class ProfileAssetDataSource implements ProfileRemoteDataSource {
  ProfileAssetDataSource(this._prefs, this._assets);

  final SharedPreferences _prefs;
  final MockAssetClient _assets;

  String _key(String uid) => 'user_profile_$uid';

  @override
  Future<UserProfileModel?> fetchProfile(String uid) async {
    final local = _prefs.getString(_key(uid));
    if (local != null && local.isNotEmpty) {
      try {
        return UserProfileModel.fromJson(
          jsonDecode(local) as Map<String, dynamic>,
          uid,
        );
      } on Object {
        // fall through to asset
      }
    }

    final data = await _assets.getData('user/me.json');
    final p = data['profile'] as Map<String, dynamic>? ?? {};
    return UserProfileModel(
      uid: uid,
      displayName: p['display_name'] as String? ??
          p['displayName'] as String? ??
          '',
      email: p['email'] as String?,
      phoneNumber: p['phone_number'] as String? ??
          p['phoneNumber'] as String?,
      profileCompleted: p['profile_completed'] as bool? ??
          p['profileCompleted'] as bool? ??
          false,
    );
  }

  @override
  Future<void> writeProfile(UserProfileModel profile) async {
    await _prefs.setString(
      _key(profile.uid),
      jsonEncode(profile.toJson()),
    );
  }
}
