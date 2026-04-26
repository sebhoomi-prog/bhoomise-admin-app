class SendOtpRequestModel {
  const SendOtpRequestModel({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({
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

class AuthApiUserModel {
  const AuthApiUserModel({
    required this.id,
    required this.phone,
    this.role,
    this.name,
  });

  final String id;
  final String phone;
  final String? role;
  final String? name;

  factory AuthApiUserModel.fromJson(Map<String, dynamic> json) {
    return AuthApiUserModel(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: json['role']?.toString(),
      name: json['name']?.toString(),
    );
  }
}

class VerifyOtpResponseModel {
  const VerifyOtpResponseModel({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final AuthApiUserModel user;

  factory VerifyOtpResponseModel.fromApi(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Invalid verify-otp response body.');
    }
    final map = Map<String, dynamic>.from(body);
    final dataRaw = map['data'];
    if (dataRaw is! Map) {
      throw const FormatException('Missing verify-otp response data.');
    }
    final data = Map<String, dynamic>.from(dataRaw);
    final accessToken = (data['accessToken'] ?? '').toString().trim();
    final userRaw = data['user'];
    if (accessToken.isEmpty || userRaw is! Map) {
      throw const FormatException('Invalid verify-otp payload.');
    }
    return VerifyOtpResponseModel(
      accessToken: accessToken,
      user: AuthApiUserModel.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }
}

