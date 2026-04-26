import 'package:dio/dio.dart';

import '../../common/config/app_config.dart';
import '../../core/network/api_origin_normalize.dart';

abstract final class DioFactory {
  DioFactory._();

  static Dio create({
    required List<Interceptor> interceptors,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: normalizeApiOriginForDio(AppConfig.apiBaseUrl),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: <String, dynamic>{
          Headers.contentTypeHeader: Headers.jsonContentType,
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.addAll(interceptors);
    return dio;
  }
}

