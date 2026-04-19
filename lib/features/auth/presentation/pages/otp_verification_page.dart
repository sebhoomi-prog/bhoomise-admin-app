import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/session/phone_otp_route_persistence.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp/otp_verification_figma_body.dart';

/// OTP verification — shared for all roles (customer / partner / admin flows).
/// Optional Get [arguments]: `phoneE164`, `intent` (`login`|`signup`), `role` (`customer`|`partner`|`admin`).
class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const _otpLen = 6;
  static const _timerSeconds = 120;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  int _secondsLeft = _timerSeconds;
  bool _verifyInFlight = false;

  Map<String, dynamic>? get _args {
    final a = Get.arguments;
    return a is Map<String, dynamic> ? a : null;
  }

  String? get _phoneE164 => _args?['phoneE164'] as String?;

  bool get _isSignup => _args?['intent'] == 'signup';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLen, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLen, (_) => FocusNode());
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _mmSs {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _canResend => _secondsLeft <= 0;

  String _formatDisplayPhone(String? e164) {
    if (e164 == null || e164.isEmpty) return '—';
    final t = e164.trim();
    if (t.startsWith('+1') && t.length >= 12) {
      final d = t.substring(2).replaceAll(RegExp(r'\D'), '');
      if (d.length == 10) {
        return '+1 ${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
      }
    }
    if (t.startsWith('+91') && t.length >= 12) {
      final d = t.substring(3).replaceAll(RegExp(r'\D'), '');
      if (d.length == 10) {
        return '+91 ${d.substring(0, 5)} ${d.substring(5)}';
      }
    }
    return t;
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _controllers[index].clear();
      setState(() {});
      return;
    }
    if (digits.length >= _otpLen) {
      final take = digits.substring(digits.length - _otpLen);
      for (var i = 0; i < _otpLen; i++) {
        _controllers[i].text = take[i];
      }
      setState(() {});
      _scheduleAutoSubmitIfComplete();
      return;
    }
    _controllers[index].text = digits.substring(digits.length - 1);
    if (index < _otpLen - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    _scheduleAutoSubmitIfComplete();
  }

  /// After the 6th digit (or paste), verify like tapping the primary button.
  void _scheduleAutoSubmitIfComplete() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_verifyInFlight) return;
      if (_code().length != _otpLen) return;
      _submit();
    });
  }

  String _code() => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_verifyInFlight) return;
    if (_code().length != _otpLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.enterSixDigit)),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _verifyInFlight = true;
    final auth = Get.find<AuthController>();
    try {
      await auth.verifyOtp(_code());
      if (!mounted) return;
    } on Object catch (e) {
      if (!mounted) return;
      final msg = auth.errorMessage.value;
      final text =
          (msg != null && msg.isNotEmpty) ? msg : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } finally {
      if (mounted) {
        _verifyInFlight = false;
      }
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    final phone = _phoneE164;
    if (phone == null) {
      Get.snackbar(AppStrings.error, AppStrings.missingPhoneSession);
      return;
    }
    final auth = Get.find<AuthController>();
    try {
      await auth.sendOtp(phone);
      if (!mounted) return;
      await PhoneOtpRoutePersistence.markPending(
        Get.find<SharedPreferences>(),
        phoneE164: phone,
        intent: (_args?['intent'] as String?) ?? 'login',
        role: (_args?['role'] as String?) ?? 'customer',
      );
      if (!mounted) return;
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.otpResent)),
      );
    } on Object catch (_) {
      if (!mounted) return;
      final msg = auth.errorMessage.value;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  void _exitOtpFlow() {
    Get.find<AuthController>().cancelPhoneOtpFlow();
    if (Navigator.of(context).canPop()) {
      Get.back<void>();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final display = _formatDisplayPhone(_phoneE164);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitOtpFlow();
      },
      child: Scaffold(
      backgroundColor: DesignTokens.figmaHeaderFrostTint,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Obx(
            () => OtpVerificationFigmaBody(
                displayPhone: display,
                controllers: _controllers,
                focusNodes: _focusNodes,
                onDigitChanged: _onDigitChanged,
                timeMmSs: _mmSs,
                canResend: _canResend,
                onResend: _resend,
                onSubmit: _submit,
                loading: auth.loading.value,
                isSignup: _isSignup,
                onTermsTap: () => _soon(AppStrings.termsOfService),
                onPrivacyTap: () => _soon(AppStrings.privacyPolicy),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OtpFigmaHeader(onBack: _exitOtpFlow),
            ),
          ],
        ),
      ),
    );
  }
}
