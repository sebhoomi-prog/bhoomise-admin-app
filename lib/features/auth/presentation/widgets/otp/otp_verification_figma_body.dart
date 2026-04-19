import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/design_tokens.dart';

/// Shared OTP UI — Figma organic card, 6 slots, timer, security bar, footer.
class OtpVerificationFigmaBody extends StatelessWidget {
  const OtpVerificationFigmaBody({
    super.key,
    required this.displayPhone,
    required this.controllers,
    required this.focusNodes,
    required this.onDigitChanged,
    required this.timeMmSs,
    required this.canResend,
    required this.onResend,
    required this.onSubmit,
    required this.loading,
    required this.isSignup,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final String displayPhone;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onDigitChanged;
  final String timeMmSs;
  final bool canResend;
  final VoidCallback onResend;
  final VoidCallback onSubmit;
  final bool loading;
  final bool isSignup;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 130,
                  height: 442,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1615672966928-f1cf32c67ef3?fm=jpg&fit=crop&w=400&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: DesignTokens.figmaCategoryCard,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            77 + MediaQuery.paddingOf(context).top,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
              children: [
                _OtpCard(
                  displayPhone: displayPhone,
                  controllers: controllers,
                  focusNodes: focusNodes,
                  onDigitChanged: onDigitChanged,
                  timeMmSs: timeMmSs,
                  canResend: canResend,
                  onResend: onResend,
                  onSubmit: onSubmit,
                  loading: loading,
                  isSignup: isSignup,
                ),
                const SizedBox(height: 32),
                _OtpLegalFooter(
                  onTermsTap: onTermsTap,
                  onPrivacyTap: onPrivacyTap,
                ),
              ],
            ),
        ),
      ],
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({
    required this.displayPhone,
    required this.controllers,
    required this.focusNodes,
    required this.onDigitChanged,
    required this.timeMmSs,
    required this.canResend,
    required this.onResend,
    required this.onSubmit,
    required this.loading,
    required this.isSignup,
  });

  final String displayPhone;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onDigitChanged;
  final String timeMmSs;
  final bool canResend;
  final VoidCallback onResend;
  final VoidCallback onSubmit;
  final bool loading;
  final bool isSignup;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: DesignTokens.figmaCategoryCard,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.figmaHeroCtaGreenAlt.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.cell_tower_rounded,
                      size: 26,
                      color: DesignTokens.figmaHeroCtaGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      AppStrings.verifyPhone,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        height: 36 / 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.75,
                        color: DesignTokens.figmaSectionInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      AppStrings.otpInstructionSixDigit(displayPhone),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 26 / 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3E4A3D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 72,
                child: Row(
                  children: List.generate(controllers.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                        child: _OtpSlot(
                          controller: controllers[i],
                          focusNode: focusNodes[i],
                          onChanged: (v) => onDigitChanged(i, v),
                          textInputAction: i == controllers.length - 1
                              ? TextInputAction.done
                              : TextInputAction.none,
                          onFieldSubmitted: i == controllers.length - 1
                              ? onSubmit
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  Text(
                    AppStrings.timeRemaining,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      height: 15 / 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: DesignTokens.figmaStoreMeta,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeMmSs,
                        style: GoogleFonts.robotoMono(
                          fontSize: 18,
                          height: 28 / 18,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.figmaSectionInk,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Opacity(
                        opacity: canResend ? 1 : 0.45,
                        child: InkWell(
                          onTap: canResend ? onResend : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: DesignTokens.figmaHeroCtaGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.resendCode,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.figmaHeroCtaGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: loading ? null : onSubmit,
                  child: Ink(
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.figmaHeroCtaGreen,
                          DesignTokens.figmaHeroCtaGreenAlt,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.figmaHeroCtaGreen.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isSignup
                                  ? AppStrings.verifyOtpSignup
                                  : AppStrings.verifyAndProceed,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                height: 28 / 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.securityStrength,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          height: 15 / 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: DesignTokens.figmaStoreMeta,
                        ),
                      ),
                      Text(
                        AppStrings.securityHigh,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.figmaHeroCtaGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          Container(
                            color: DesignTokens.figmaSearchBarFill,
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.8,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              color: DesignTokens.figmaHeroCtaGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -48,
          top: -48,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.figmaHeroCtaGreenAlt.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpSlot extends StatelessWidget {
  const _OtpSlot({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.textInputAction = TextInputAction.none,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  /// Last box only: IME "Done" / Enter runs verify (same as primary button).
  final VoidCallback? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final has = value.text.isNotEmpty;
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final fontSize = w < 36 ? 18.0 : (w < 44 ? 22.0 : 26.0);
              const lineHeight = 1.12;
              return Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: textInputAction,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      height: lineHeight,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted:
                        onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      filled: true,
                      fillColor: DesignTokens.figmaSearchBarFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                    ),
                    onChanged: onChanged,
                  ),
                  if (!has)
                    IgnorePointer(
                      child: Text(
                        '·',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          height: lineHeight,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OtpLegalFooter extends StatefulWidget {
  const _OtpLegalFooter({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_OtpLegalFooter> createState() => _OtpLegalFooterState();
}

class _OtpLegalFooterState extends State<_OtpLegalFooter> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacy = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(
      fontSize: 12,
      height: 20 / 12,
      fontWeight: FontWeight.w400,
      color: const Color(0x993E4A3D),
    );
    final link = base.copyWith(
      decoration: TextDecoration.underline,
      color: DesignTokens.figmaCategoryNameGreen,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(
            text: 'By proceeding, you agree to our ',
          ),
          TextSpan(
            text: AppStrings.termsOfService,
            style: link,
            recognizer: _terms,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: AppStrings.privacyPolicy,
            style: link,
            recognizer: _privacy,
          ),
          const TextSpan(
            text: ' regarding your mycological data.',
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Frosted top bar: back only (no storefront title).
class OtpFigmaHeader extends StatelessWidget {
  const OtpFigmaHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.paddingOf(context).top + 8,
            24,
            16,
          ),
          color: DesignTokens.figmaHeaderFrostTint.withValues(alpha: 0.7),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: DesignTokens.figmaDeliverGreen,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
