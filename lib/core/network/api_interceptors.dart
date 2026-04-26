import 'dart:convert';

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
    debugPrint('\n${'=' * 80}');
    debugPrint('[API][REQ] ${options.method} ${options.baseUrl}${options.path}');
    debugPrint('Query: ${options.queryParameters}');
    debugPrint('Body: ${options.data}');
    _printCurl(options);
    debugPrint('=' * 80);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('\n${'=' * 80}');
    debugPrint('[API][RES] ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}');
    debugPrint('Response Headers: ${response.headers.map}');
    debugPrint('Response Data:');
    _prettyPrintJson(response.data);
    debugPrint('=' * 80);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('\n${'!' * 80}');
    debugPrint('[API][ERR] ${err.response?.statusCode} '
        '${err.requestOptions.method} ${err.requestOptions.uri}');
    debugPrint('Error Message: ${err.message}');
    debugPrint('Error Type: ${err.type}');
    if (err.response?.data != null) {
      debugPrint('Error Response:');
      _prettyPrintJson(err.response?.data);
    }
    debugPrint('!' * 80);
    handler.next(err);
  }

  void _prettyPrintJson(dynamic data) {
    if (!kDebugMode) return;
    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        final prettyJson = encoder.convert(data);
        for (final line in prettyJson.split('\n')) {
          debugPrint(line);
        }
      } else {
        debugPrint('$data');
      }
    } catch (_) {
      debugPrint('$data');
    }
  }

  void _printCurl(RequestOptions options) {
    if (!kDebugMode) return;

    final components = <String>['curl -X ${options.method}'];

    options.headers.forEach((key, value) {
      if (value != null) {
        final escaped = value.toString().replaceAll("'", "\\'");
        components.add("-H '$key: $escaped'");
      }
    });

    if (options.data != null) {
      String body;
      if (options.data is Map || options.data is List) {
        try {
          body = const JsonEncoder().convert(options.data);
        } catch (_) {
          body = options.data.toString();
        }
      } else {
        body = options.data.toString();
      }
      final escaped = body.replaceAll("'", "\\'");
      components.add("-d '$escaped'");
    }

    var url = '${options.baseUrl}${options.path}';
    if (options.queryParameters.isNotEmpty) {
      final queryString = options.queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url = '$url?$queryString';
    }
    components.add("'$url'");

    final curl = components.join(' \\\n  ');
    debugPrint('\n[CURL COMMAND]\n$curl\n');
  }
}
