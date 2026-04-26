import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'i_session_service.dart';

class SessionService implements ISessionService {
  SessionService(this._storage);

  static const _kToken = 'badmin_api_token_v1';

  final FlutterSecureStorage _storage;
  String? _cached;

  @override
  String? get token => _cached;

  Future<void> load() async {
    try {
      _cached = await _storage.read(key: _kToken);
    } catch (e) {
      debugPrint('SessionService.load error: $e');
      _cached = null;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    _cached = token;
    try {
      await _storage.write(key: _kToken, value: token);
    } catch (e) {
      debugPrint('SessionService.saveToken error: $e');
    }
  }

  @override
  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _kToken);
    } catch (e) {
      debugPrint('SessionService.clear error: $e');
    }
  }
}

