import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/figma_typography.dart';
import '../../../data/login_ui_config.dart';

/// Privacy / terms rich text — Figma login (`9:675` legacy or `9:673` terms-first).
class FigmaLoginLegalFooter extends StatefulWidget {
  const FigmaLoginLegalFooter({
    super.key,
    required this.cfg,
    required this.brand,
    required this.muted,
    required this.onLink,
  });

  final LoginUiConfig cfg;
  final Color brand;
  final Color muted;
  final void Function(String url, String name) onLink;

  @override
  State<FigmaLoginLegalFooter> createState() => _FigmaLoginLegalFooterState();
}

class _FigmaLoginLegalFooterState extends State<FigmaLoginLegalFooter> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () =>
          widget.onLink(widget.cfg.privacyUrl, widget.cfg.footerPrivacyPhrase);
    _termsTap = TapGestureRecognizer()
      ..onTap = () => widget.onLink(widget.cfg.termsUrl, widget.cfg.termsLabel);
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cfg.footerStyle == 'terms_privacy') {
      return _termsPrivacyLayout();
    }
    return _legacyLayout();
  }

  Widget _termsPrivacyLayout() {
    final base = FigmaTypography.legalBody(widget.muted);
    final link = FigmaTypography.legalLink(widget.brand).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: widget.brand,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: widget.cfg.footerLead),
          TextSpan(
            text: widget.cfg.termsLabel,
            style: link,
            recognizer: _termsTap,
          ),
          TextSpan(text: widget.cfg.footerMid),
          TextSpan(
            text: widget.cfg.footerPrivacyPhrase,
            style: link,
            recognizer: _privacyTap,
          ),
          TextSpan(text: widget.cfg.footerSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _legacyLayout() {
    final base = FigmaTypography.legalBody(widget.muted);
    final link = FigmaTypography.legalLink(widget.brand);
    final brandWord = link.copyWith(fontWeight: FontWeight.w800);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: widget.cfg.footerLead),
          TextSpan(text: widget.cfg.footerBrandWord, style: brandWord),
          if (widget.cfg.footerBetween.isNotEmpty)
            TextSpan(text: widget.cfg.footerBetween),
          const TextSpan(text: ' '),
          TextSpan(
            text: widget.cfg.footerPrivacyPhrase,
            style: link,
            recognizer: _privacyTap,
          ),
          TextSpan(text: widget.cfg.footerMid),
          TextSpan(
            text: '${widget.cfg.termsLabel}.',
            style: link,
            recognizer: _termsTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
