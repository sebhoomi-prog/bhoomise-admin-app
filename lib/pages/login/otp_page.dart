import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/figma_typography.dart';
import '../../features/auth/data/login_ui_config.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_primary_cta.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_welcome_illustration.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.phoneE164});

  final String phoneE164;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focuses;

  Color _hex(String hex) {
    var v = hex.replaceFirst('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focuses = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int idx, String val) {
    if (val.isNotEmpty && idx < 5) {
      _focuses[idx + 1].requestFocus();
    }
    if (val.isEmpty && idx > 0) {
      _focuses[idx - 1].requestFocus();
    }
    if (_otp.length == 6) {
      _submit();
    }
  }

  void _submit() {
    if (_otp.length != 6) return;
    context.read<AuthBloc>().add(AuthVerifyOtpRequested(
      phoneE164: widget.phoneE164,
      otp: _otp,
    ));
  }

  String _formatPhone(String e164) {
    if (e164.startsWith('+91') && e164.length == 13) {
      final digits = e164.substring(3);
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return e164;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = LoginUiConfig.fallback;
    final brand = _hex(cfg.brandPrimaryHex);
    final surface = _hex(cfg.surfaceHex);
    final textSecondary = _hex(cfg.textSecondaryHex);
    final textMuted = _hex(cfg.textMutedHex);
    final gradientStart = _hex(cfg.ctaGradientStartHex);
    final gradientEnd = _hex(cfg.ctaGradientEndHex);
    final phoneFill = _hex(cfg.phoneFieldFillHex);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Scaffold(
          backgroundColor: surface,
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: brand,
                            size: 18,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  SizedBox(
                    height: 176,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter OTP',
                                textAlign: TextAlign.left,
                                style: FigmaTypography.loginHeadline(brand),
                              ),
                              const SizedBox(height: DesignTokens.spaceMd),
                              Text(
                                'We sent a 6-digit code to',
                                textAlign: TextAlign.left,
                                style: FigmaTypography.loginSubheadline(
                                  textSecondary,
                                ),
                              ),
                              Text(
                                _formatPhone(widget.phoneE164),
                                textAlign: TextAlign.left,
                                style: FigmaTypography.bodyBold(brand),
                              ),
                            ],
                          ),
                        ),
                        FigmaLoginOrganicWaves(
                          width: MediaQuery.sizeOf(context).width * 0.34,
                          height: 140,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Text(
                    'VERIFICATION CODE',
                    style: FigmaTypography.labelCaps(textSecondary),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: Material(
                          color: phoneFill,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusLg,
                          ),
                          child: Center(
                            child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _focuses[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: brand,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => _onDigitChanged(i, v),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code? ',
                        style: FigmaTypography.loginSubheadline(textMuted),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<AuthBloc>().add(
                                AuthSendOtpRequested(widget.phoneE164),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('OTP resent')),
                          );
                        },
                        child: Text(
                          'Resend',
                          style: FigmaTypography.legalLink(brand),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg * 2),
                  FigmaLoginPrimaryCta(
                    gradientStart: gradientStart,
                    gradientEnd: gradientEnd,
                    label: 'Verify OTP',
                    trailingIconUrl: '',
                    onPressed: loading ? null : _submit,
                    loading: loading,
                    useSolid: false,
                    trailingStyle: FigmaLoginCtaTrailing.arrow,
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceMd,
                        vertical: DesignTokens.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: brand,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Access Only',
                            style: FigmaTypography.labelCaps(brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
