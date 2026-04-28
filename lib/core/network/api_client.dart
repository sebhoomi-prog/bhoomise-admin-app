import 'package:dio/dio.dart';

import 'network_exceptions.dart';

/// Thin wrapper over [Dio]. Single [ApiClient] for GetX, services, and datasources.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? '',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 45),
              ),
            );

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
  }) async {
    final qp = queryParameters ?? query;
    try {
      return await _dio.get<dynamic>(path, queryParameters: qp);
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(e.message ?? 'Request failed', code: e.type.name);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
  }) async {
    final payload = body ?? data;
    final qp = queryParameters ?? query;
    try {
      return await _dio.post<dynamic>(
        path,
        data: payload,
        queryParameters: qp,
      );
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(
        _messageFromDio(e),
        code: e.type.name,
      );
    }
  }

  /// Multipart upload (e.g. catalog images). [data] is typically [FormData].
  Future<Response<dynamic>> postMultipart(
    String path, {
    required FormData data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
  }) async {
    final qp = queryParameters ?? query;
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: qp,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(
        _messageFromDio(e),
        code: e.type.name,
      );
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? body,
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
  }) async {
    final payload = body ?? data;
    final qp = queryParameters ?? query;
    try {
      return await _dio.put<dynamic>(
        path,
        data: payload,
        queryParameters: qp,
      );
    } on DioException catch (e) {
      if (e.error is NetworkException) rethrow;
      throw NetworkException(
        _messageFromDio(e),
        code: e.type.name,
      );
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
  }) async {
    final qp = queryParameters ?? query;
    try {
      return await _dio.delete<dynamic>(
        path,
        data: body,
        queryParameters: qp,
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
