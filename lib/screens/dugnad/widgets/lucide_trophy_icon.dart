import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lucide-style `trophy` from `Design/ui_kits/icons.jsx`.
///
/// Stroke-only (no fill) so the gold cup disc shows through — matches
/// `.dgseq-cup .disc` / Figma outline trophy.
class LucideTrophyIcon extends StatelessWidget {
  const LucideTrophyIcon({
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  /// Dark outline used on the T9 gold cup (design / Figma).
  static const Color kOutline = Color(0xFF1A1630);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LucideTrophyPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LucideTrophyPainter extends CustomPainter {
  const _LucideTrophyPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Draw in viewBox 0..24, then scale (Lucide SVG strokeWidth=2).
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Left handle — M6 9 H4.5 a2.5 2.5 0 0 1 0-5 H6
    // Semicircle bulging left (SVG sweep=1 / clockwise).
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(4.5, 9)
        ..arcTo(
          Rect.fromCircle(center: const Offset(4.5, 6.5), radius: 2.5),
          math.pi / 2,
          math.pi,
          false,
        )
        ..lineTo(6, 4),
      paint,
    );

    // Right handle — M18 9 h1.5 a2.5 2.5 0 0 0 0-5 H18
    // Semicircle bulging right (SVG sweep=0 / counter-clockwise).
    canvas.drawPath(
      Path()
        ..moveTo(18, 9)
        ..lineTo(19.5, 9)
        ..arcTo(
          Rect.fromCircle(center: const Offset(19.5, 6.5), radius: 2.5),
          math.pi / 2,
          -math.pi,
          false,
        )
        ..lineTo(18, 4),
      paint,
    );

    // Base — M4 22h16
    canvas.drawLine(const Offset(4, 22), const Offset(20, 22), paint);

    // Left stem — M10 14.7V17c0 .6-.5 1-1 1.2C7.9 18.8 7 20.2 7 22
    canvas.drawPath(
      Path()
        ..moveTo(10, 14.7)
        ..lineTo(10, 17)
        ..cubicTo(10, 17.6, 9.5, 18, 9, 18.2)
        ..cubicTo(7.9, 18.8, 7, 20.2, 7, 22),
      paint,
    );

    // Right stem — M14 14.7V17c0 .6.5 1 1 1.2 1.1.6 2 2 2 3.8
    canvas.drawPath(
      Path()
        ..moveTo(14, 14.7)
        ..lineTo(14, 17)
        ..cubicTo(14, 17.6, 14.5, 18, 15, 18.2)
        ..cubicTo(16.1, 18.8, 17, 20.2, 17, 22),
      paint,
    );

    // Cup body outline only — M18 2H6v7a6 6 0 0 0 12 0V2Z
    canvas.drawPath(
      Path()
        ..moveTo(18, 2)
        ..lineTo(6, 2)
        ..lineTo(6, 9)
        ..cubicTo(6, 12.31, 8.69, 15, 12, 15)
        ..cubicTo(15.31, 15, 18, 12.31, 18, 9)
        ..lineTo(18, 2),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LucideTrophyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
