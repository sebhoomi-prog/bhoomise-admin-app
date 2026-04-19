import 'package:dio/dio.dart';

import 'network_exceptions.dart';

/// Thin wrapper over [Dio]. Used only from `*_api_datasource.dart` files.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? '',
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(e.message ?? 'Request failed', code: e.type.name);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(
        _messageFromDio(e),
        code: e.type.name,
      );
    }
  }

  static String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m != null) return m.toString();
    }
    return e.message ?? 'Request failed';
  }
}
