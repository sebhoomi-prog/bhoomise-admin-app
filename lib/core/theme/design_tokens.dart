import 'package:flutter/material.dart';

import '../design/figma_storefront.dart' show kFigmaBhoomiseFileKey;

/// Bhoomise Agri-Tech UI — customer surfaces from Figma **Customer Home** (file `kWtQ8RReUVoZ7BoABTOe3q`, node `9:3`).
abstract final class DesignTokens {
  /// Figma file key for design reference (not a runtime dependency).
  static const String figmaCustomerHomeFileKey = kFigmaBhoomiseFileKey;

  /// Phone login / multi-role — Dev Mode frame [`9:675`](https://www.figma.com/design/kWtQ8RReUVoZ7BoABTOe3q/Bhoomise?node-id=9-675&m=dev).
  static const String figmaLoginFrameNodeId = '9:675';

  static const String figmaLoginFrameUrl =
      'https://www.figma.com/design/kWtQ8RReUVoZ7BoABTOe3q/Bhoomise?node-id=9-675&m=dev';

  /// Top inset for [Scaffold] body when using [Scaffold.extendBodyBehindAppBar]
  /// with a standard [AppBar] (status bar + toolbar).
  static double underTransparentAppBarTopPadding(BuildContext context) {
    final toolbar =
        Theme.of(context).appBarTheme.toolbarHeight ?? kToolbarHeight;
    return MediaQuery.viewPaddingOf(context).top + toolbar;
  }

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double buttonMinHeight = 52;
  static const double appBarBlurSigma = 12;

  // Figma Customer Home (`9:3`) + CSS export
  static const Color figmaSearchBarFill = Color(0xFFD9E3F6);
  /// Cart quantity stepper background — Figma cart (`#DEE9FC`).
  static const Color figmaCartQtyPill = Color(0xFFDEE9FC);
  static const Color figmaCategoryCard = Color(0xFFEFF4FF);
  static const Color figmaAccentLime = Color(0xFF7FFC97);
  static const Color figmaHeroCtaGreen = Color(0xFF006B2C);
  static const Color figmaHeroCtaGreenAlt = Color(0xFF00873A);
  static const Color figmaLabelMuted = Color(0xFF64748B);
  static const Color figmaDeliverGreen = Color(0xFF166534);
  static const Color figmaPinIconGreen = Color(0xFF15803D);
  static const Color figmaSectionInk = Color(0xFF121C2A);
  static const Color figmaCategoryNameGreen = Color(0xFF14532D);
  static const Color figmaCustomerShellBg = Color(0xFFF8F9FA);
  static const Color figmaHeaderFrostTint = Color(0xFFF8F9FF);
  static const Color figmaNavInactive = Color(0xFF94A3B8);
  static const Color figmaNavActiveMint = Color(0xFFDCFCE7);
  static const Color figmaSearchGlyph = Color(0xFF6E7B6C);
  static const Color figmaStoreMeta = Color(0xFF5D5D4E);
  /// Voucher Apply button — Figma cart.
  static const Color figmaVoucherApplyBg = Color(0xFF767565);
  static const Color figmaVoucherApplyFg = Color(0xFFFFFDD8);
  static const Color figmaProfileRingMuted = Color(0x3300873A);

  static const double customerHomeCategoryRadius = 48;
  static const double customerHomeHeroRadius = 32;
  static const double customerHomeProductCardRadius = 32;
  /// Scroll padding under frosted header (status + toolbar area).
  static double customerHomeHeaderExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 92;
  }

  /// Customer shell body background — matches [ColorScheme.surface] from [AppTheme].
  static Color customerShellBackground(ColorScheme scheme) => scheme.surface;

  static BoxDecoration softCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(radiusLg),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
    );
  }
}
