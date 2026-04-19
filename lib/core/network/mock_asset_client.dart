import 'dart:convert';

import 'package:flutter/services.dart';

import 'network_exceptions.dart';

/// Loads JSON fixtures from `assets/mock_api/` using the Laravel-style envelope
/// `{ "success": true, "message": "...", "data": { } }`.
class MockAssetClient {
  MockAssetClient();

  /// Returns the `data` object from a successful response.
  Future<Map<String, dynamic>> getData(String relativePath) async {
    final map = await _loadEnvelope(relativePath);
    if (map['success'] != true) {
      throw NetworkException(
        map['message']?.toString() ?? 'Request failed',
      );
    }
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    throw NetworkException('Expected object in data field');
  }

  /// Use when `data` is a list or you need the raw envelope.
  Future<Map<String, dynamic>> getEnvelope(String relativePath) async {
    return _loadEnvelope(relativePath);
  }

  Future<Map<String, dynamic>> _loadEnvelope(String relativePath) async {
    final path = relativePath.startsWith('assets/')
        ? relativePath
        : 'assets/mock_api/$relativePath';
    late final String raw;
    try {
      raw = await rootBundle.loadString(path);
    } on Object catch (e) {
      throw NetworkException(
        'Could not load mock API asset "$path". '
        'Run flutter clean && flutter pub get, then full restart (not hot reload). '
        'Underlying error: $e',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw NetworkException('Invalid mock JSON in $path');
    }
    return decoded;
  }
}
