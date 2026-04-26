import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthSendOtpRequested extends AuthEvent {
  const AuthSendOtpRequested(this.phoneE164);

  final String phoneE164;

  @override
  List<Object?> get props => [phoneE164];
}

final class AuthVerifyOtpRequested extends AuthEvent {
  const AuthVerifyOtpRequested({
    required this.phoneE164,
    required this.otp,
  });

  final String phoneE164;
  final String otp;

  @override
  List<Object?> get props => [phoneE164, otp];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

