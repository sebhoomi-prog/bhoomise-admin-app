import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/firebase/firestore_test_seed.dart';
import '../../../../core/session/app_session_service.dart';
import '../../../../core/session/phone_otp_route_persistence.dart';
import '../../../profile/domain/usecases/resolve_post_auth_destination.dart';
import '../../domain/auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_phone_verification.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_sms_code.dart';
import '../../domain/usecases/watch_auth_state.dart';

class AuthController extends GetxController {
  AuthController(
    this._watchAuthState,
    this._sendPhoneVerification,
    this._verifySmsCode,
    this._signOut,
    this._resolvePostAuth,
  );

  final WatchAuthState _watchAuthState;
  final SendPhoneVerification _sendPhoneVerification;
  final VerifySmsCode _verifySmsCode;
  final SignOut _signOut;
  final ResolvePostAuthDestination _resolvePostAuth;

  final Rxn<AuthUser> currentUser = Rxn<AuthUser>();
  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();

  /// True after SMS/captcha sent and the user still must enter the 6-digit code.
  /// Blocks [Get.currentRoute]==login auto-navigation until OTP is pushed.
  final RxBool smsCodeUiExpected = false.obs;

  StreamSubscription<AuthUser?>? _sub;

  /// True after we have observed a signed-in session (restored or fresh login).
  bool _hadAuthenticatedSession = false;

  /// Avoids duplicate redirects while [signOutUser] is clearing remote/local auth.
  bool _explicitSignOutInFlight = false;

  @override
  void onInit() {
    super.onInit();
    _sub = _watchAuthState().listen(_onAuthUserChanged);
  }

  void _onAuthUserChanged(AuthUser? user) {
    currentUser.value = user;
    final route = Get.currentRoute;
    if (user != null) {
      _hadAuthenticatedSession = true;
      // SMS + captcha flow: avoid jumping to shell while still on phone login before OTP opens.
      if (smsCodeUiExpected.value && route == AppRoutes.login) {
        return;
      }
      // Instant verification: user is signed in on the phone screen (no OTP route).
      // SMS success is handled inside [verifyOtp] to avoid races with [authStateChanges].
      if (route == AppRoutes.login) {
        unawaited(_navigateAfterPhoneSignIn());
      }
      return;
    }

    if (_explicitSignOutInFlight) {
      return;
    }

    // Session ended while user was signed in (sign-out elsewhere, token expiry, etc.).
    if (_hadAuthenticatedSession &&
        route != AppRoutes.login &&
        route != AppRoutes.otp &&
        route != AppRoutes.splash) {
      _hadAuthenticatedSession = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> _navigateAfterPhoneSignIn() async {
    final session = Get.find<AppSessionService>();
    final pending = session.consumePendingRole();
    if (pending != null) {
      await session.persistRole(pending);
    }
    final uid = currentUser.value?.uid;
    if (uid == null) return;
    final shell = session.mainShellRouteAfterAuth;
    try {
      final dest = await _resolvePostAuth(uid);
      if (dest == PostAuthDestination.completeProfile) {
        Get.offAllNamed(AppRoutes.signupProfile);
      } else {
        Get.offAllNamed(shell);
      }
    } on Object catch (_) {
      Get.offAllNamed(shell);
    }
  }

  /// First emission from auth state stream (restored session or signed out).
  Future<void> waitForInitialAuth() async {
    await _watchAuthState().first;
  }

  Future<void> sendOtp(String phoneE164) async {
    loading.value = true;
    errorMessage.value = null;
    smsCodeUiExpected.value = false;
    try {
      await _sendPhoneVerification(phoneE164);
      smsCodeUiExpected.value =
          Get.find<AuthRepository>().awaitingPhoneSmsCodeEntry;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      rethrow;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  /// User left the OTP screen (back) — allow browsing as guest again.
  void cancelPhoneOtpFlow() {
    smsCodeUiExpected.value = false;
    Get.find<AuthRepository>().abandonPhoneVerification();
    final prefs = Get.find<SharedPreferences>();
    unawaited(PhoneOtpRoutePersistence.clear(prefs));
  }

  Future<void> verifyOtp(String code) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      await _verifySmsCode(code);
      smsCodeUiExpected.value = false;
      await PhoneOtpRoutePersistence.clear(Get.find<SharedPreferences>());
      await maybeSeedFirestoreForTesting(Get.find<SharedPreferences>());
      unawaited(_navigateAfterPhoneSignIn());
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      rethrow;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  Future<void> signOutUser() async {
    loading.value = true;
    errorMessage.value = null;
    _explicitSignOutInFlight = true;
    smsCodeUiExpected.value = false;
    try {
      Get.find<AppSessionService>().clearRole();
      await PhoneOtpRoutePersistence.clear(Get.find<SharedPreferences>());
      await _signOut();
      _hadAuthenticatedSession = false;
      Get.offAllNamed(AppRoutes.login);
    } finally {
      _explicitSignOutInFlight = false;
      loading.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
