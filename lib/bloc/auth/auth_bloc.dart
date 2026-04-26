import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth/i_auth_service.dart';
import '../../services/session/i_session_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._auth, this._session) : super(const AuthInitial()) {
    on<AuthSendOtpRequested>(_onSendOtp);
    on<AuthVerifyOtpRequested>(_onVerifyOtp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final IAuthService _auth;
  final ISessionService _session;

  Future<void> _onSendOtp(
    AuthSendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _auth.sendOtp(event.phoneE164);
      emit(AuthOtpSent(event.phoneE164));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _auth.verifyOtp(phoneE164: event.phoneE164, otp: event.otp);
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _session.clear();
    emit(const AuthInitial());
  }
}

