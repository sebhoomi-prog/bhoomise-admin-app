import 'package:dio/dio.dart';

/// Single place that constructs [Dio] for [ApiClient]. Add [AuthBearerInterceptor] via
/// [extraInterceptors] when JWT session exists.
class DioFactory {
  DioFactory._();

  static Dio create({
    required String baseUrl,
    List<Interceptor> extraInterceptors = const [],
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
    );
    dio.interceptors.addAll(extraInterceptors);
    return dio;
  }
}
