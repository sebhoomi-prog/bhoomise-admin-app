import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// JWT / Bearer — pass a token getter from your session layer when wiring [Dio].
class AuthBearerInterceptor extends Interceptor {
  AuthBearerInterceptor(this._token);

  final String? Function() _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = _token();
    if (t != null && t.isNotEmpty) {
      options.headers[AppConstants.headerAuthorization] =
          '${AppConstants.bearerPrefix} $t';
    }
    handler.next(options);
  }
}

class ApiLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint(
      '[API][REQ] ${options.method} ${options.baseUrl}${options.path} '
      'query=${options.queryParameters} body=${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[API][RES] ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.path} data=${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[API][ERR] ${err.response?.statusCode} '
      '${err.requestOptions.method} ${err.requestOptions.path} '
      'message=${err.message} data=${err.response?.data}',
    );
    handler.next(err);
  }
}
