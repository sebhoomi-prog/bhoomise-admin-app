class SendOtpRequest {
  const SendOtpRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.phone,
    required this.otp,
    required this.role,
  });

  final String phone;
  final String otp;
  final String role;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        'role': role,
      };
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.role,
  });

  final String id;
  final String phone;
  final String? name;
  final String? role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      name: json['name']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final AuthUser user;

  factory VerifyOtpResponse.fromApi(dynamic body) {
    if (body is! Map) throw const FormatException('Invalid verify-otp response.');
    final data = body['data'];
    if (data is! Map) throw const FormatException('Missing verify-otp data.');
    final token = (data['accessToken'] ?? '').toString().trim();
    final userRaw = data['user'];
    if (token.isEmpty || userRaw is! Map) {
      throw const FormatException('Invalid verify-otp payload.');
    }
    return VerifyOtpResponse(
      accessToken: token,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }
}

