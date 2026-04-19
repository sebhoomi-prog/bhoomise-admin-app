import 'package:dio/dio.dart';

/// JWT / Bearer — pass a token getter from your session layer when wiring [Dio].
final class AuthBearerInterceptor extends Interceptor {
  AuthBearerInterceptor(this._token);

  final String? Function() _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = _token();
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }
}
