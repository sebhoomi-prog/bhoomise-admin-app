import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';
import 'profile_remote_datasource.dart';

/// Persists user profile JSON in [SharedPreferences] per uid.
class ProfileLocalDataSource implements ProfileRemoteDataSource {
  ProfileLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  String _key(String uid) => 'user_profile_$uid';

  @override
  Future<UserProfileModel?> fetchProfile(String uid) async {
    final raw = _prefs.getString(_key(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfileModel.fromJson(m, uid);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeProfile(UserProfileModel profile) async {
    await _prefs.setString(_key(profile.uid), jsonEncode(profile.toJson()));
  }
}
