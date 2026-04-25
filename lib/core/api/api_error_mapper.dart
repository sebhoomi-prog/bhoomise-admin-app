import 'package:dio/dio.dart';

import '../network/network_exceptions.dart';
import '../../features/auth/domain/auth_exception.dart';

class ApiErrorMapper {
  ApiErrorMapper._();

  static AuthException toAuthException(Object error) {
    if (error is AuthException) return error;
    if (error is NetworkException) {
      return AuthException(error.message);
    }
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return AuthException(message.toString().trim());
        }
      }
      return AuthException(error.message ?? 'Network request failed.');
    }
    return AuthException(error.toString());
  }
}

