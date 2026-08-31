import 'package:flutter/material.dart';

/// Lucide-style `box` from `Design/ui_kits/icons.jsx` — isometric package.
class LucideBoxIcon extends StatelessWidget {
  const LucideBoxIcon({
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LucideBoxPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _LucideBoxPainter extends CustomPainter {
  const _LucideBoxPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer package: M21 16V8a2 2 0 0 0-1-1.7l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.7l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z
    final outer = Path()
      ..moveTo(21, 16)
      ..lineTo(21, 8)
      ..cubicTo(21, 7.3, 20.7, 6.6, 20, 6.3)
      ..lineTo(13, 2.3)
      ..cubicTo(12.4, 2, 11.6, 2, 11, 2.3)
      ..lineTo(4, 6.3)
      ..cubicTo(3.3, 6.6, 3, 7.3, 3, 8)
      ..lineTo(3, 16)
      ..cubicTo(3, 16.7, 3.3, 17.4, 4, 17.7)
      ..lineTo(11, 21.7)
      ..cubicTo(11.6, 22, 12.4, 22, 13, 21.7)
      ..lineTo(20, 17.7)
      ..cubicTo(20.7, 17.4, 21, 16.7, 21, 16)
      ..close();
    canvas.drawPath(outer, paint);

    // Top crease: polyline 3.3 7 → 12 12 → 20.7 7
    canvas.drawPath(
      Path()
        ..moveTo(3.3, 7)
        ..lineTo(12, 12)
        ..lineTo(20.7, 7),
      paint,
    );

    // Vertical seam: line 12 22 → 12 12
    canvas.drawLine(const Offset(12, 22), const Offset(12, 12), paint);
  }

  @override
  bool shouldRepaint(covariant _LucideBoxPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
