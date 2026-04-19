import 'package:flutter/material.dart';

import '../../../../../core/theme/figma_typography.dart';
import '../../../../../core/util/unsplash_raster_url.dart';

/// Primary pill CTA — gradient (`9:675`) or solid brand (`9:673`), optional arrow / shield / image.
class FigmaLoginPrimaryCta extends StatelessWidget {
  const FigmaLoginPrimaryCta({
    super.key,
    required this.gradientStart,
    required this.gradientEnd,
    required this.label,
    required this.trailingIconUrl,
    required this.onPressed,
    required this.loading,
    this.useSolid = false,
    this.trailingStyle = FigmaLoginCtaTrailing.shield,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final String label;
  final String trailingIconUrl;
  final VoidCallback? onPressed;
  final bool loading;
  final bool useSolid;
  final FigmaLoginCtaTrailing trailingStyle;

  @override
  Widget build(BuildContext context) {
    final fill = useSolid ? gradientStart : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: fill,
            gradient: useSolid
                ? null
                : LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: (useSolid ? gradientStart : gradientEnd)
                    .withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    style: FigmaTypography.cta(Colors.white),
                  ),
                  const SizedBox(width: 10),
                  _Trailing(
                    url: trailingIconUrl,
                    style: trailingStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum FigmaLoginCtaTrailing {
  shield,
  arrow,
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.url, required this.style});

  final String url;
  final FigmaLoginCtaTrailing style;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return Image.network(
        unsplashAsJpeg(url),
        height: 17,
        errorBuilder: (_, __, ___) => _fallback(style),
      );
    }
    return _fallback(style);
  }

  Widget _fallback(FigmaLoginCtaTrailing style) {
    switch (style) {
      case FigmaLoginCtaTrailing.arrow:
        return const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 22,
        );
      case FigmaLoginCtaTrailing.shield:
        return const Icon(
          Icons.verified_user_rounded,
          color: Colors.white,
          size: 20,
        );
    }
  }
}
