import 'dart:convert';

import 'package:flutter/services.dart';

/// UI copy + image URLs from `assets/mock_api/ui/login_screen.json` (Laravel-style envelope).
/// Replace with live `GET /api/ui/login` when backend exists.
class LoginUiConfig {
  const LoginUiConfig({
    required this.heroImageUrl,
    required this.heroImageUrlAlt,
    required this.headlineLine1,
    required this.headlineLine2,
    required this.subheadlineLine1,
    required this.subheadlineLine2,
    required this.roleCustomerLabel,
    required this.roleBusinessLabel,
    required this.defaultDialCode,
    required this.phoneFieldLabel,
    required this.phonePlaceholderUs,
    required this.phonePlaceholderIn,
    required this.primaryCta,
    required this.enterpriseSsoLabel,
    required this.corporateEmailCta,
    required this.footerLead,
    required this.footerBrandWord,
    required this.footerBetween,
    required this.footerPrivacyPhrase,
    required this.footerMid,
    required this.termsLabel,
    required this.privacyUrl,
    required this.termsUrl,
    required this.brandPrimaryHex,
    required this.surfaceHex,
    required this.textSecondaryHex,
    required this.textMutedHex,
    required this.borderHex,
    required this.segmentTrackHex,
    required this.corporateBorderHex,
    required this.ctaGradientStartHex,
    required this.ctaGradientEndHex,
    required this.googleIconUrl,
    required this.appleIconUrl,
    required this.corporateEmailIconUrl,
    required this.ctaTrailingIconUrl,
    required this.showHeroImage,
    required this.showRoleSegment,
    required this.splitPhoneFields,
    required this.headlineColorHex,
    required this.phoneFieldFillHex,
    required this.socialPillFillHex,
    required this.ctaUseSolid,
    /// `shield` | `arrow`
    required this.ctaTrailingStyle,
    required this.socialGoogleLabel,
    required this.socialEmailLabel,
    required this.vendorAdminCta,
    required this.vendorAdminUnderlineSubstring,
    required this.welcomeAlignStart,
    required this.socialLabelHex,
    required this.footerStyle,
    required this.footerSuffix,
  });

  final String heroImageUrl;
  final String heroImageUrlAlt;
  final String headlineLine1;
  final String headlineLine2;
  final String subheadlineLine1;
  final String subheadlineLine2;
  final String roleCustomerLabel;
  final String roleBusinessLabel;
  /// Figma default: `+1`; use `+91` in JSON for India-first builds.
  final String defaultDialCode;
  final String phoneFieldLabel;
  final String phonePlaceholderUs;
  final String phonePlaceholderIn;
  final String primaryCta;
  final String enterpriseSsoLabel;
  final String corporateEmailCta;
  final String footerLead;
  /// Bold green word before the line break (Figma: ends line 1).
  final String footerBrandWord;
  final String footerBetween;
  final String footerPrivacyPhrase;
  final String footerMid;
  final String termsLabel;
  final String privacyUrl;
  final String termsUrl;
  final String brandPrimaryHex;
  final String surfaceHex;
  final String textSecondaryHex;
  final String textMutedHex;
  final String borderHex;
  final String segmentTrackHex;
  final String corporateBorderHex;
  final String ctaGradientStartHex;
  final String ctaGradientEndHex;
  final String googleIconUrl;
  final String appleIconUrl;
  final String corporateEmailIconUrl;
  final String ctaTrailingIconUrl;

  final bool showHeroImage;
  final bool showRoleSegment;
  final bool splitPhoneFields;
  /// Empty = use [brandPrimaryHex] for headline (legacy).
  final String headlineColorHex;
  final String phoneFieldFillHex;
  final String socialPillFillHex;
  final bool ctaUseSolid;
  final String ctaTrailingStyle;
  final String socialGoogleLabel;
  final String socialEmailLabel;
  /// Single line (e.g. `LOGIN AS VENDOR / ADMIN`). Empty = legacy two links.
  final String vendorAdminCta;
  /// If set and contained in [vendorAdminCta], that substring is underlined.
  final String vendorAdminUnderlineSubstring;
  /// Left-align welcome title + subhead (organic login).
  final bool welcomeAlignStart;
  /// GOOGLE/EMAIL label color; empty = [textMutedHex].
  final String socialLabelHex;
  /// `legacy` | `terms_privacy`
  final String footerStyle;
  final String footerSuffix;

  static const LoginUiConfig fallback = LoginUiConfig(
    heroImageUrl:
        'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?fm=jpg&fit=crop&w=1200&q=80',
    heroImageUrlAlt:
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?fm=jpg&fit=crop&w=1200&q=80',
    headlineLine1: 'Welcome Back',
    headlineLine2: '',
    subheadlineLine1: 'Access your curated mycelium market.',
    subheadlineLine2: '',
    roleCustomerLabel: 'Customer Login',
    roleBusinessLabel: 'Business / Admin',
    defaultDialCode: '+91',
    phoneFieldLabel: 'REGISTERED PHONE NUMBER',
    phonePlaceholderUs: '000 000 0000',
    phonePlaceholderIn: '00000 00000',
    primaryCta: 'Send OTP',
    enterpriseSsoLabel: 'OR LOG IN WITH',
    corporateEmailCta: 'Login with Corporate Email',
    footerLead: 'By continuing, you acknowledge the ',
    footerBrandWord: 'Bhoomise',
    footerBetween: '',
    footerPrivacyPhrase: 'Privacy Policy',
    footerMid: ' and our standard ',
    termsLabel: 'Terms of Service',
    privacyUrl: 'https://bhoomise.app/privacy',
    termsUrl: 'https://bhoomise.app/terms',
    brandPrimaryHex: '#166534',
    surfaceHex: '#F8F9FF',
    textSecondaryHex: '#4D635C',
    textMutedHex: '#707975',
    borderHex: '#BFC9C4',
    segmentTrackHex: '#EFF4FF',
    corporateBorderHex: '#707975',
    ctaGradientStartHex: '#166534',
    ctaGradientEndHex: '#006B2C',
    googleIconUrl: '',
    appleIconUrl: '',
    corporateEmailIconUrl: '',
    ctaTrailingIconUrl: '',
    showHeroImage: true,
    showRoleSegment: true,
    splitPhoneFields: false,
    headlineColorHex: '',
    phoneFieldFillHex: '#FFFFFF',
    socialPillFillHex: '#FFFFFF',
    ctaUseSolid: false,
    ctaTrailingStyle: 'shield',
    socialGoogleLabel: '',
    socialEmailLabel: '',
    vendorAdminCta: '',
    vendorAdminUnderlineSubstring: '',
    welcomeAlignStart: false,
    socialLabelHex: '',
    footerStyle: 'legacy',
    footerSuffix: '.',
  );

  static Future<LoginUiConfig> loadFromAssets() async {
    try {
      final raw = await rootBundle.loadString('assets/mock_api/ui/login_screen.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['success'] != true) return fallback;
      final d = map['data'] as Map<String, dynamic>? ?? {};
      String s(String key, String def) => d[key] as String? ?? def;

      bool b(String key, bool def) {
        final v = d[key];
        if (v is bool) return v;
        return def;
      }

      return LoginUiConfig(
        heroImageUrl: s('hero_image_url', fallback.heroImageUrl),
        heroImageUrlAlt: s('hero_image_url_alt', fallback.heroImageUrlAlt),
        headlineLine1: s('headline_line1', fallback.headlineLine1),
        headlineLine2: s('headline_line2', fallback.headlineLine2),
        subheadlineLine1: s('subheadline_line1', fallback.subheadlineLine1),
        subheadlineLine2: s('subheadline_line2', fallback.subheadlineLine2),
        roleCustomerLabel: s('role_customer_label', fallback.roleCustomerLabel),
        roleBusinessLabel: s('role_business_label', fallback.roleBusinessLabel),
        defaultDialCode: s('default_dial_code', fallback.defaultDialCode),
        phoneFieldLabel: s('phone_field_label', fallback.phoneFieldLabel),
        phonePlaceholderUs: s('phone_placeholder_us', fallback.phonePlaceholderUs),
        phonePlaceholderIn: s('phone_placeholder_in', fallback.phonePlaceholderIn),
        primaryCta: s('primary_cta', fallback.primaryCta),
        enterpriseSsoLabel: s('enterprise_sso_label', fallback.enterpriseSsoLabel),
        corporateEmailCta: s('corporate_email_cta', fallback.corporateEmailCta),
        footerLead: s('footer_lead', fallback.footerLead),
        footerBrandWord: s('footer_brand_word', fallback.footerBrandWord),
        footerBetween: s('footer_between', fallback.footerBetween),
        footerPrivacyPhrase: s('footer_privacy_phrase', fallback.footerPrivacyPhrase),
        footerMid: s('footer_mid', fallback.footerMid),
        termsLabel: s('terms_label', fallback.termsLabel),
        privacyUrl: s('privacy_url', fallback.privacyUrl),
        termsUrl: s('terms_url', fallback.termsUrl),
        brandPrimaryHex: s('brand_primary_hex', fallback.brandPrimaryHex),
        surfaceHex: s('surface_hex', fallback.surfaceHex),
        textSecondaryHex: s('text_secondary_hex', fallback.textSecondaryHex),
        textMutedHex: s('text_muted_hex', fallback.textMutedHex),
        borderHex: s('border_hex', fallback.borderHex),
        segmentTrackHex: s('segment_track_hex', fallback.segmentTrackHex),
        corporateBorderHex: s('corporate_border_hex', fallback.corporateBorderHex),
        ctaGradientStartHex: s('cta_gradient_start_hex', fallback.ctaGradientStartHex),
        ctaGradientEndHex: s('cta_gradient_end_hex', fallback.ctaGradientEndHex),
        googleIconUrl: s('google_icon_url', fallback.googleIconUrl),
        appleIconUrl: s('apple_icon_url', fallback.appleIconUrl),
        corporateEmailIconUrl: s('corporate_email_icon_url', fallback.corporateEmailIconUrl),
        ctaTrailingIconUrl: s('cta_trailing_icon_url', fallback.ctaTrailingIconUrl),
        showHeroImage: b('show_hero_image', fallback.showHeroImage),
        showRoleSegment: b('show_role_segment', fallback.showRoleSegment),
        splitPhoneFields: b('split_phone_fields', fallback.splitPhoneFields),
        headlineColorHex: s('headline_color_hex', fallback.headlineColorHex),
        phoneFieldFillHex: s('phone_field_fill_hex', fallback.phoneFieldFillHex),
        socialPillFillHex: s('social_pill_fill_hex', fallback.socialPillFillHex),
        ctaUseSolid: b('cta_use_solid', fallback.ctaUseSolid),
        ctaTrailingStyle: s('cta_trailing_style', fallback.ctaTrailingStyle),
        socialGoogleLabel: s('social_google_label', fallback.socialGoogleLabel),
        socialEmailLabel: s('social_email_label', fallback.socialEmailLabel),
        vendorAdminCta: s('vendor_admin_cta', fallback.vendorAdminCta),
        vendorAdminUnderlineSubstring:
            s('vendor_admin_underline_substring', fallback.vendorAdminUnderlineSubstring),
        welcomeAlignStart: b('welcome_align_start', fallback.welcomeAlignStart),
        socialLabelHex: s('social_label_hex', fallback.socialLabelHex),
        footerStyle: s('footer_style', fallback.footerStyle),
        footerSuffix: s('footer_suffix', fallback.footerSuffix),
      );
    } on Object {
      return fallback;
    }
  }
}
