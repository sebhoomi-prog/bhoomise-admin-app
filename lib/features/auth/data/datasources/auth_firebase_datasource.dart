import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/auth_exception.dart';
import '../models/auth_user_model.dart';
import 'auth_remote_datasource.dart';

bool get _isiOSDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Maps Firebase / Play Services errors to short, actionable copy for phone auth.
AuthException _mapPhoneAuthFailure(Object error) {
  if (error is AuthException) return error;
  final raw = error.toString();
  if (raw.contains('BILLING_NOT_ENABLED') || raw.contains('17499')) {
    return AuthException(
      'SMS sign-in needs an active Cloud billing account. '
      'Firebase Console → your project → Upgrade (Blaze) → link billing, then retry.',
    );
  }
  if (raw.contains('Recaptcha') && raw.contains('siteKey')) {
    return AuthException(
      'Complete Phone Auth setup: Firebase Console → Authentication → Settings → '
      'App verification / reCAPTCHA for this Android app.',
    );
  }
  final rawLower = raw.toLowerCase();
  if (rawLower.contains('play_integrity') ||
      rawLower.contains('invalid app info') ||
      (rawLower.contains('not authorized') &&
          rawLower.contains('firebase authentication'))) {
    return AuthException(
      'Android: register this app’s SHA-1 and SHA-256 in Firebase (Project settings → '
      'Android app com.bhoomise). Run: cd android && ./gradlew signingReport, add both '
      'fingerprints, re-download google-services.json to android/app/, then rebuild. '
      'For Play Store builds, also add Play app signing certificate SHA from Play Console.',
    );
  }
  if (error is FirebaseAuthException) {
    final code = error.code;
    final combined = '$code ${error.message ?? ''}'.toLowerCase();

    // Real iOS devices (especially release) need APNs + URL scheme; simulator may differ.
    if (_isiOSDevice &&
        (code == 'missing-client-identifier' ||
            code == 'invalid-app-credential' ||
            (code == 'internal-error' && combined.contains('credential')) ||
            combined.contains('apns') ||
            combined.contains('push') ||
            combined.contains('token'))) {
      return AuthException(
        'iOS phone verification failed (often release/device only). '
        'In Firebase Console: add Apple Team ID for this iOS app; '
        'Project settings → Cloud Messaging → upload APNs Authentication Key (.p8); '
        're-download GoogleService-Info.plist and add REVERSED_CLIENT_ID to Xcode URL Types. '
        'Clean rebuild after enabling Push Notifications.',
      );
    }

    // Android: app identity must match Console (Play Integrity) — not the phone model.
    if (!_isiOSDevice &&
        (code == 'invalid-app-credential' || code == 'app-not-authorized')) {
      return AuthException(
        'Firebase could not verify this app build (not your device). Add SHA-1 and SHA-256 '
        'for the keystore you use to com.bhoomise in Firebase Console, re-download '
        'google-services.json, rebuild. If from Play Store, add Play “app signing” SHAs. '
        'Blaze billing must be on for SMS. Wait a few minutes if you just changed Console.',
      );
    }
    if (!_isiOSDevice && code == 'captcha-check-failed') {
      return AuthException(
        'Phone verification check failed (network or Play services). Retry on Wi‑Fi; '
        'confirm Android app + SHA fingerprints in Firebase match this install.',
      );
    }

    if (code == 'too-many-requests') {
      return AuthException(
        'Too many attempts. Wait several minutes, use a test number from Firebase Console '
        '→ Authentication → Phone, or try another device.',
      );
    }

    return AuthException(error.message ?? error.code);
  }
  return AuthException(raw);
}

/// Firebase Phone Auth — SMS OTP from Firebase only; invalid codes do not sign in.
class AuthFirebaseDataSource implements AuthRemoteDataSource {
  AuthFirebaseDataSource() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;

  @override
  bool get awaitingPhoneSmsCodeEntry =>
      _verificationId != null && _auth.currentUser == null;

  AuthUserModel? _mapUser(User? u) {
    if (u == null) return null;
    return AuthUserModel(uid: u.uid, phoneNumber: u.phoneNumber);
  }

  @override
  Stream<AuthUserModel?> watchAuthState() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<void> requestPhoneVerification(String phoneE164) async {
    _verificationId = null;
    final ready = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } on Object catch (e) {
          if (!ready.isCompleted) {
            ready.completeError(_mapPhoneAuthFailure(e));
          }
          return;
        }
        if (!ready.isCompleted) ready.complete();
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!ready.isCompleted) {
          ready.completeError(_mapPhoneAuthFailure(e));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!ready.isCompleted) ready.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId ??= verificationId;
      },
      timeout: const Duration(seconds: 90),
      forceResendingToken: _resendToken,
    );

    try {
      await ready.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw AuthException(
          _isiOSDevice
              ? 'Timed out waiting for SMS. On iOS release builds ensure APNs key is uploaded '
                  'to Firebase, Push Notifications are enabled, and URL schemes include '
                  'REVERSED_CLIENT_ID from GoogleService-Info.plist.'
              : 'Timed out waiting for SMS. Check Phone Auth / SMS / Play Services.',
        ),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AuthFirebaseDataSource: requestPhoneVerification failed: $e');
      }
      throw _mapPhoneAuthFailure(e);
    }
  }

  @override
  Future<void> verifySmsCode(String smsCode) async {
    final trimmed = smsCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      throw AuthException('Enter the 6-digit code.');
    }

    // Instant / auto verification already signed in — no SMS step, nothing to validate here.
    final u = _auth.currentUser;
    if (u != null &&
        u.phoneNumber != null &&
        _verificationId == null) {
      return;
    }

    final vid = _verificationId;
    if (vid == null) {
      throw AuthException('Verification session expired. Request a new code.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: vid,
      smsCode: trimmed,
    );
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapPhoneAuthFailure(e);
    }
  }

  @override
  void abandonPhoneVerification() {
    _verificationId = null;
    _resendToken = null;
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    await _auth.signOut();
  }
}
