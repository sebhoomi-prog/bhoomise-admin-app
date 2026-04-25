import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    this.phoneNumber,
  });

  final String uid;
  final String? phoneNumber;

  @override
  List<Object?> get props => [uid, phoneNumber];
}
