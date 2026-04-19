import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/session/app_role.dart';
import '../../../../core/session/app_session_service.dart';
import '../../../../core/session/phone_otp_route_persistence.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/figma_typography.dart';
import '../../data/login_ui_config.dart';
import '../controllers/auth_controller.dart';
import '../widgets/figma/play_integrity_login_notice.dart';
import '../widgets/figma/figma_login_hero_block.dart';
import '../widgets/figma/figma_login_legal_footer.dart';
import '../widgets/figma/figma_login_phone_field.dart';
import '../widgets/figma/figma_login_phone_split_field.dart';
import '../widgets/figma/figma_login_primary_cta.dart';
import '../widgets/figma/figma_login_role_segment.dart';
import '../widgets/figma/figma_login_social_row.dart';
import '../widgets/figma/figma_login_welcome_illustration.dart';

/// Phone login — Figma **Bhoomise** frames `9:675` (photo hero) · `9:673` (organic waves).
/// ([Dev Mode](https://www.figma.com/design/kWtQ8RReUVoZ7BoABTOe3q/Bhoomise?node-id=9-673&m=dev)); copy from `login_screen.json`.
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
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
  AppRole _loginRole = AppRole.customer;

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
    final auth = Get.find<AuthController>();
    Get.find<AppSessionService>().setPendingRole(_loginRole);
    final prefs = Get.find<SharedPreferences>();
    try {
      // Persist before reCAPTCHA WebView / activity recreate so Splash can open OTP
      // if the engine restarts before [Get.offNamed](otp) runs.
      await PhoneOtpRoutePersistence.markPending(
        prefs,
        phoneE164: e164,
        intent: 'login',
        role: _loginRole.name,
      );
      await auth.sendOtp(e164);
      final repo = Get.find<AuthRepository>();
      // Instant verification signs in without SMS UI — [AuthController] navigates away.
      if (!repo.awaitingPhoneSmsCodeEntry) {
        await PhoneOtpRoutePersistence.clear(prefs);
        return;
      }
      // Do not gate on `mounted`: after reCAPTCHA / app switch the login widget may be
      // disposed while verification still completes; GetX navigation is still valid.
      // Replace login with OTP so the stack is shell → OTP (back returns to guest home).
      await Get.offNamed(
        AppRoutes.otp,
        arguments: <String, dynamic>{
          'phoneE164': e164,
          'intent': 'login',
          'role': _loginRole.name,
        },
      );
    } on Object catch (_) {
      await PhoneOtpRoutePersistence.clear(prefs);
      if (!mounted) return;
      final msg = auth.errorMessage.value;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _soon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  void _selectVendorOrAdmin() {
    setState(() => _loginRole = AppRole.partner);
    Get.find<AppSessionService>().setPendingRole(AppRole.partner);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor selected — enter your work number.'),
      ),
    );
  }

  /// Optional underline on a substring of [LoginUiConfig.vendorAdminCta] (e.g. `VENDOR`).
  Widget _vendorAdminLine(Color textMuted) {
    final base = FigmaTypography.labelCaps(textMuted, letterSpacing: 0.8)
        .copyWith(fontSize: 11);
    final em = cfg.vendorAdminUnderlineSubstring.trim();
    final line = cfg.vendorAdminCta;
    if (em.isEmpty) {
      return Text(line, style: base, textAlign: TextAlign.center);
    }
    final idx = line.indexOf(em);
    if (idx < 0) {
      return Text(line, style: base, textAlign: TextAlign.center);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: line.substring(0, idx)),
          TextSpan(
            text: em,
            style: base.copyWith(decoration: TextDecoration.underline),
          ),
          TextSpan(text: line.substring(idx + em.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final brand = _hex(cfg.brandPrimaryHex);
    final surface = _hex(cfg.surfaceHex);
    final textSecondary = _hex(cfg.textSecondaryHex);
    final textMuted = _hex(cfg.textMutedHex);
    final border = _hex(cfg.borderHex);
    final segmentTrack = _hex(cfg.segmentTrackHex);
    final gradientStart = _hex(cfg.ctaGradientStartHex);
    final gradientEnd = _hex(cfg.ctaGradientEndHex);
    final headlineColor =
        cfg.headlineColorHex.isNotEmpty ? _hex(cfg.headlineColorHex) : brand;
    final phoneFill = _hex(cfg.phoneFieldFillHex);
    final socialFill = _hex(cfg.socialPillFillHex);
    final pillLabelColor = cfg.socialLabelHex.isNotEmpty
        ? _hex(cfg.socialLabelHex)
        : _hex(cfg.textMutedHex);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
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
                if (cfg.showHeroImage) ...[
                  FigmaLoginHeroBlock(cfg: cfg, brand: brand),
                  const SizedBox(height: DesignTokens.spaceLg),
                ] else if (cfg.welcomeAlignStart) ...[
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
                                cfg.headlineLine1,
                                textAlign: TextAlign.left,
                                style:
                                    FigmaTypography.loginHeadline(headlineColor),
                              ),
                              if (cfg.headlineLine2.trim().isNotEmpty) ...[
                                Text(
                                  cfg.headlineLine2,
                                  textAlign: TextAlign.left,
                                  style: FigmaTypography.loginHeadline(
                                    headlineColor,
                                  ),
                                ),
                              ],
                              const SizedBox(height: DesignTokens.spaceMd),
                              Text(
                                cfg.subheadlineLine1,
                                textAlign: TextAlign.left,
                                style: FigmaTypography.loginSubheadline(
                                  textSecondary,
                                ),
                              ),
                              if (cfg.subheadlineLine2.trim().isNotEmpty)
                                Text(
                                  cfg.subheadlineLine2,
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
                ] else ...[
                  SizedBox(
                    height: 168,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          right: -28,
                          top: -12,
                          child: FigmaLoginOrganicWaves(
                            width: MediaQuery.sizeOf(context).width * 0.55,
                            height: 150,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              cfg.headlineLine1,
                              textAlign: TextAlign.center,
                              style: FigmaTypography.loginHeadline(headlineColor),
                            ),
                            if (cfg.headlineLine2.trim().isNotEmpty) ...[
                              Text(
                                cfg.headlineLine2,
                                textAlign: TextAlign.center,
                                style: FigmaTypography.loginHeadline(headlineColor),
                              ),
                            ],
                            const SizedBox(height: DesignTokens.spaceMd),
                            Text(
                              cfg.subheadlineLine1,
                              textAlign: TextAlign.center,
                              style: FigmaTypography.loginSubheadline(textSecondary),
                            ),
                            if (cfg.subheadlineLine2.trim().isNotEmpty)
                              Text(
                                cfg.subheadlineLine2,
                                textAlign: TextAlign.center,
                                style: FigmaTypography.loginSubheadline(textSecondary),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                ],
                if (cfg.showHeroImage) ...[
                  Text(
                    cfg.headlineLine1,
                    textAlign: TextAlign.center,
                    style: FigmaTypography.loginHeadline(headlineColor),
                  ),
                  if (cfg.headlineLine2.trim().isNotEmpty) ...[
                    Text(
                      cfg.headlineLine2,
                      textAlign: TextAlign.center,
                      style: FigmaTypography.loginHeadline(headlineColor),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spaceMd),
                  Text(
                    cfg.subheadlineLine1,
                    textAlign: TextAlign.center,
                    style: FigmaTypography.loginSubheadline(textSecondary),
                  ),
                  if (cfg.subheadlineLine2.trim().isNotEmpty)
                    Text(
                      cfg.subheadlineLine2,
                      textAlign: TextAlign.center,
                      style: FigmaTypography.loginSubheadline(textSecondary),
                    ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],
                if (cfg.showRoleSegment) ...[
                  FigmaLoginRoleSegmentThree(
                    track: segmentTrack,
                    brand: brand,
                    textMuted: textMuted,
                    customerLabel: 'Customer',
                    vendorLabel: 'Vendor',
                    adminLabel: 'Admin',
                    role: _loginRole,
                    onChanged: (r) => setState(() => _loginRole = r),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                ],
                if (cfg.welcomeAlignStart && !cfg.showHeroImage)
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
                        if (cfg.splitPhoneFields)
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
                          )
                        else
                          FigmaLoginPhoneField(
                            dialCode: _dialCode,
                            onDialChanged: (v) =>
                                setState(() => _dialCode = v),
                            controller: _phone,
                            placeholder: _dialCode == '+1'
                                ? cfg.phonePlaceholderUs
                                : cfg.phonePlaceholderIn,
                            borderColor: border,
                            brand: brand,
                          ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    cfg.phoneFieldLabel,
                    style: FigmaTypography.labelCaps(textSecondary),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  if (cfg.splitPhoneFields)
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
                    )
                  else
                    FigmaLoginPhoneField(
                      dialCode: _dialCode,
                      onDialChanged: (v) => setState(() => _dialCode = v),
                      controller: _phone,
                      placeholder: _dialCode == '+1'
                          ? cfg.phonePlaceholderUs
                          : cfg.phonePlaceholderIn,
                      borderColor: border,
                      brand: brand,
                    ),
                ],
                const SizedBox(height: DesignTokens.spaceMd),
                const SizedBox(height: DesignTokens.spaceLg),
                Obx(
                  () => FigmaLoginPrimaryCta(
                    gradientStart: gradientStart,
                    gradientEnd: gradientEnd,
                    label: cfg.primaryCta,
                    trailingIconUrl: cfg.ctaTrailingIconUrl,
                    onPressed: auth.loading.value ? null : _submit,
                    loading: auth.loading.value,
                    useSolid: cfg.ctaUseSolid,
                    trailingStyle: _ctaTrailing(),
                  ),
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
                if (cfg.vendorAdminCta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
                    child: Center(
                      child: TextButton(
                        onPressed: _selectVendorOrAdmin,
                        child: _vendorAdminLine(textMuted),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _selectVendorOrAdmin,
                          child: Text(
                            'REGISTER AS VENDOR',
                            style: FigmaTypography.vendorAdminLink(brand),
                          ),
                        ),
                        Text('|', style: TextStyle(color: textMuted, fontSize: 12)),
                        TextButton(
                          onPressed: _selectVendorOrAdmin,
                          child: Text(
                            'ADMIN',
                            style: FigmaTypography.vendorAdminLink(brand),
                          ),
                        ),
                      ],
                    ),
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
  }
}
