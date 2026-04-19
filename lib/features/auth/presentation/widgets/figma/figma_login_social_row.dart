import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/util/unsplash_raster_url.dart';

/// "OR LOG IN WITH" rule + outlined icon buttons — Figma login (`9:675`).
class FigmaLoginEnterpriseDivider extends StatelessWidget {
  const FigmaLoginEnterpriseDivider({
    super.key,
    required this.label,
    required this.muted,
  });

  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: DesignTokens.figmaSearchBarFill.withValues(alpha: 0.65),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Icon from Figma export URL with fallback widget.
class FigmaLoginSocialIconButton extends StatelessWidget {
  const FigmaLoginSocialIconButton({
    super.key,
    required this.iconUrl,
    required this.fallback,
    required this.onPressed,
  });

  final String iconUrl;
  final Widget fallback;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: DesignTokens.figmaSearchBarFill.withValues(alpha: 0.85),
        ),
        backgroundColor: Colors.white,
        minimumSize: const Size(0, DesignTokens.buttonMinHeight),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        elevation: 0,
        shadowColor: Colors.black26,
      ),
      onPressed: onPressed,
      child: Opacity(
        opacity: 0.85,
        child: iconUrl.isNotEmpty
            ? Image.network(
                unsplashAsJpeg(iconUrl),
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

/// Fallback Google mark when asset URL fails.
class FigmaGoogleMark extends StatelessWidget {
  const FigmaGoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _FigmaGoogleMarkPainter()),
    );
  }
}

class _FigmaGoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4);
    canvas.drawCircle(center, r, paint);
    paint.color = Colors.white;
    final tp = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Filled pill with icon + uppercase label — organic login (`9:673`).
class FigmaLoginSocialLabeledPill extends StatelessWidget {
  const FigmaLoginSocialLabeledPill({
    super.key,
    required this.label,
    required this.iconUrl,
    required this.fallback,
    required this.fill,
    required this.onPressed,
    required this.labelColor,
  });

  final String label;
  final String iconUrl;
  final Widget fallback;
  final Color fill;
  final VoidCallback onPressed;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.95,
                child: iconUrl.isNotEmpty
                    ? Image.network(
                        unsplashAsJpeg(iconUrl),
                        height: 20,
                        width: 20,
                        errorBuilder: (_, __, ___) => fallback,
                      )
                    : fallback,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
