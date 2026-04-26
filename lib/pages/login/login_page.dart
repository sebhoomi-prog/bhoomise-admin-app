import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/figma_typography.dart';
import '../../features/auth/data/login_ui_config.dart';
import '../../features/auth/presentation/widgets/figma/play_integrity_login_notice.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_legal_footer.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_phone_split_field.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_primary_cta.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_social_row.dart';
import '../../features/auth/presentation/widgets/figma/figma_login_welcome_illustration.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final Future<LoginUiConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = LoginUiConfig.loadFromAssets();
  }

  Color _c(String hex) {
    var v = hex.replaceFirst('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoginUiConfig>(
      future: _configFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          final surface = _c(LoginUiConfig.fallback.surfaceHex);
          return Scaffold(
            backgroundColor: surface,
            body: Center(
              child: CircularProgressIndicator(
                color: _c(LoginUiConfig.fallback.brandPrimaryHex),
              ),
            ),
          );
        }
        return _LoginFormBody(cfg: snap.data!);
      },
    );
  }
}

class _LoginFormBody extends StatefulWidget {
  const _LoginFormBody({required this.cfg});

  final LoginUiConfig cfg;

  @override
  State<_LoginFormBody> createState() => _LoginFormBodyState();
}

class _LoginFormBodyState extends State<_LoginFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  late String _dialCode;

  LoginUiConfig get cfg => widget.cfg;

  Color _hex(String hex) {
    var v = hex.replaceFirst('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _dialCode = cfg.defaultDialCode;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String _toE164(String digitsOnly) {
    if (_dialCode == '+1') return '+1$digitsOnly';
    return '+91$digitsOnly';
  }

  FigmaLoginCtaTrailing _ctaTrailing() {
    return cfg.ctaTrailingStyle.toLowerCase().trim() == 'arrow'
        ? FigmaLoginCtaTrailing.arrow
        : FigmaLoginCtaTrailing.shield;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _phone.text.replaceAll(RegExp(r'\D'), '');
    final e164 = _toE164(raw);
    context.read<AuthBloc>().add(AuthSendOtpRequested(e164));
  }

  void _soon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final brand = _hex(cfg.brandPrimaryHex);
    final surface = _hex(cfg.surfaceHex);
    final textSecondary = _hex(cfg.textSecondaryHex);
    final textMuted = _hex(cfg.textMutedHex);
    final gradientStart = _hex(cfg.ctaGradientStartHex);
    final gradientEnd = _hex(cfg.ctaGradientEndHex);
    final headlineColor =
        cfg.headlineColorHex.isNotEmpty ? _hex(cfg.headlineColorHex) : brand;
    final phoneFill = _hex(cfg.phoneFieldFillHex);
    final socialFill = _hex(cfg.socialPillFillHex);
    final pillLabelColor = cfg.socialLabelHex.isNotEmpty
        ? _hex(cfg.socialLabelHex)
        : _hex(cfg.textMutedHex);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OtpPage(phoneE164: state.phoneE164),
            ),
          );
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop())
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
                          )
                        else
                          const SizedBox(width: 40),
                        const Expanded(child: SizedBox.shrink()),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    // Welcome section with organic waves
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
                                  'Admin Portal',
                                  textAlign: TextAlign.left,
                                  style: FigmaTypography.loginHeadline(
                                      headlineColor),
                                ),
                                const SizedBox(height: DesignTokens.spaceMd),
                                Text(
                                  'Manage products, orders,\nstores and inventory.',
                                  textAlign: TextAlign.left,
                                  style: FigmaTypography.loginSubheadline(
                                    textSecondary,
                                  ),
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
                    // Phone field
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg.phoneFieldLabel,
                            style: FigmaTypography.labelCaps(textSecondary),
                          ),
                          const SizedBox(height: DesignTokens.spaceXs),
                          FigmaLoginPhoneSplitField(
                            dialCode: _dialCode,
                            onDialChanged: (v) {
                              setState(() {
                                _dialCode = v;
                                _phone.clear();
                              });
                            },
                            controller: _phone,
                            placeholder: _dialCode == '+1'
                                ? cfg.phonePlaceholderUs
                                : cfg.phonePlaceholderIn,
                            brand: brand,
                            fieldFill: phoneFill,
                            usStyleDashes: _dialCode == '+1',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    const SizedBox(height: DesignTokens.spaceLg),
                    // Send OTP button
                    FigmaLoginPrimaryCta(
                      gradientStart: gradientStart,
                      gradientEnd: gradientEnd,
                      label: cfg.primaryCta,
                      trailingIconUrl: cfg.ctaTrailingIconUrl,
                      onPressed: loading ? null : _submit,
                      loading: loading,
                      useSolid: cfg.ctaUseSolid,
                      trailingStyle: _ctaTrailing(),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    FigmaLoginEnterpriseDivider(
                      label: cfg.enterpriseSsoLabel,
                      muted: textMuted,
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    if (cfg.socialGoogleLabel.isNotEmpty &&
                        cfg.socialEmailLabel.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: FigmaLoginSocialLabeledPill(
                              label: cfg.socialGoogleLabel,
                              iconUrl: cfg.googleIconUrl,
                              fallback: const FigmaGoogleMark(),
                              fill: socialFill,
                              labelColor: pillLabelColor,
                              onPressed: () => _soon('Google'),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: FigmaLoginSocialLabeledPill(
                              label: cfg.socialEmailLabel,
                              iconUrl: cfg.corporateEmailIconUrl,
                              fallback: Icon(
                                Icons.mail_outline_rounded,
                                size: 22,
                                color: pillLabelColor,
                              ),
                              fill: socialFill,
                              labelColor: pillLabelColor,
                              onPressed: () => _soon('Email'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: FigmaLoginSocialIconButton(
                              iconUrl: cfg.googleIconUrl,
                              fallback: const FigmaGoogleMark(),
                              onPressed: () => _soon('Google'),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: FigmaLoginSocialIconButton(
                              iconUrl: cfg.corporateEmailIconUrl,
                              fallback: Icon(
                                Icons.mail_outline_rounded,
                                size: 22,
                                color: DesignTokens.figmaDeliverGreen,
                              ),
                              onPressed: () => _soon('Email'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    FigmaLoginLegalFooter(
                      cfg: cfg,
                      brand: brand,
                      muted: textMuted,
                      onLink: (url, name) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$name: $url')));
                      },
                    ),
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android)
                      PlayIntegrityLoginNotice(
                        muted: textMuted,
                        linkColor: brand,
                      ),
                    const SizedBox(height: DesignTokens.spaceLg),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
