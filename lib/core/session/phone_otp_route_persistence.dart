import 'package:shared_preferences/shared_preferences.dart';

/// Persists “user is mid phone OTP” across process death / activity recreate after
/// Android reCAPTCHA (Custom Tabs). Splash reads this and opens [AppRoutes.otp] instead of guest home.
class PhoneOtpRoutePersistence {
  PhoneOtpRoutePersistence._();

  static const _kPending = 'bhoomise_phone_otp_pending_v1';
  static const _kPhone = 'bhoomise_phone_otp_e164';
  static const _kIntent = 'bhoomise_phone_otp_intent';
  static const _kRole = 'bhoomise_phone_otp_role';

  static Future<void> markPending(
    SharedPreferences prefs, {
    required String phoneE164,
    required String intent,
    required String role,
  }) async {
    await prefs.setBool(_kPending, true);
    await prefs.setString(_kPhone, phoneE164);
    await prefs.setString(_kIntent, intent);
    await prefs.setString(_kRole, role);
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_kPending);
    await prefs.remove(_kPhone);
    await prefs.remove(_kIntent);
    await prefs.remove(_kRole);
  }

  static bool shouldResumeOtp(SharedPreferences prefs) {
    return prefs.getBool(_kPending) == true &&
        (prefs.getString(_kPhone)?.isNotEmpty ?? false);
  }

  static Map<String, dynamic> routeArguments(SharedPreferences prefs) {
    return <String, dynamic>{
      'phoneE164': prefs.getString(_kPhone)!,
      'intent': prefs.getString(_kIntent) ?? 'login',
      'role': prefs.getString(_kRole) ?? 'customer',
    };
  }
}
