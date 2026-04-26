import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
          AppConstants.headerAccept: AppConstants.valueApplicationJson,
        },
      ),
    );
    dio.interceptors.addAll(extraInterceptors);
    return dio;
  }
}
