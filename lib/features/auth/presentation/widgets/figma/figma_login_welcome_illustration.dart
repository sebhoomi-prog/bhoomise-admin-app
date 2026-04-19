import 'package:flutter/material.dart';

/// Decorative organic waves — Figma login variant without photo hero (node `9:673` style).
class FigmaLoginOrganicWaves extends StatelessWidget {
  const FigmaLoginOrganicWaves({
    super.key,
    this.width = 200,
    this.height = 140,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _OrganicWavesPainter(),
    );
  }
}

class _OrganicWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c1 = const Color(0xFF9CAF88).withValues(alpha: 0.45);
    final c2 = const Color(0xFFCBD5E0).withValues(alpha: 0.5);
    final c3 = const Color(0xFF718096).withValues(alpha: 0.2);

    void blob(Color c, double ox, double oy, double rw, double rh, double rot) {
      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(rot);
      final paint = Paint()..color = c;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rw, height: rh),
        paint,
      );
      canvas.restore();
    }

    blob(c3, size.width * 0.72, size.height * 0.35, size.width * 0.9, size.height * 0.55, -0.25);
    blob(c2, size.width * 0.55, size.height * 0.5, size.width * 0.7, size.height * 0.45, 0.15);
    blob(c1, size.width * 0.78, size.height * 0.62, size.width * 0.55, size.height * 0.38, 0.4);

    final wave = Path()
      ..moveTo(rect.left, rect.bottom * 0.85)
      ..quadraticBezierTo(
        rect.width * 0.35,
        rect.bottom * 0.55,
        rect.width * 0.65,
        rect.bottom * 0.75,
      )
      ..quadraticBezierTo(
        rect.width * 0.9,
        rect.bottom * 0.95,
        rect.right,
        rect.bottom * 0.65,
      )
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFF9CAF88).withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
