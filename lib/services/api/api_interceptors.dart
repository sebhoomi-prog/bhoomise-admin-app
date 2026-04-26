import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../common/config/app_config.dart';
import '../session/i_session_service.dart';

class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._session);

  final ISessionService _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = _session.token;
    if (t != null && t.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $t';
    }
    handler.next(options);
  }
}

/// Logs all API requests and responses for debugging.
class ApiLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 🚀 API REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ${options.method} ${options.baseUrl}${options.path}');
    debugPrint('║ Headers: ${_prettyJson(options.headers)}');
    if (options.data != null) {
      debugPrint('║ Body: ${_prettyJson(options.data)}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('║ Query: ${_prettyJson(options.queryParameters)}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ ✅ API RESPONSE [${response.statusCode}]');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ${response.requestOptions.method} ${response.requestOptions.path}');
    debugPrint('║ Data: ${_prettyJson(response.data)}');
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ API ERROR [${err.response?.statusCode ?? 'N/A'}]');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ${err.requestOptions.method} ${err.requestOptions.path}');
    debugPrint('║ Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('║ Response: ${_prettyJson(err.response?.data)}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');
    handler.next(err);
  }

  String _prettyJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}

/// InfinityFree free-hosting injects an anti-bot layer.
/// The Postman collection sets browser-like headers + Cookie when baseUrl contains `infinityfree`.
class InfinityFreeBypassInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final base = (options.baseUrl).toLowerCase();
    final isInfinityFree = base.contains('infinityfree');
    if (!isInfinityFree) {
      options.headers.remove('Cookie');
      handler.next(options);
      return;
    }
    if (AppConfig.userAgent.trim().isNotEmpty) {
      options.headers['User-Agent'] = AppConfig.userAgent;
    }
    if (AppConfig.acceptLanguage.trim().isNotEmpty) {
      options.headers['Accept-Language'] = AppConfig.acceptLanguage;
    }
    if (AppConfig.browserAccept.trim().isNotEmpty) {
      options.headers['Accept'] = AppConfig.browserAccept;
    }
    if (AppConfig.hostingCookie.trim().isNotEmpty) {
      options.headers['Cookie'] = AppConfig.hostingCookie;
    }
    handler.next(options);
  }
}

