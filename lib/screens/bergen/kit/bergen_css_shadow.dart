import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// CSS `box-shadow` for a translucent box.
///
/// Flutter paints a [BoxShadow] underneath the whole box, so on a frosted
/// glass surface the shadow shows *through* the fill and the glass turns
/// dark. CSS clips every shadow to the outside of the element's own border
/// box, whatever its spread and offset. This widget does the same: the
/// shadows are painted first, with the box's rounded rectangle cut out, and
/// the [child] is painted on top. Use it wherever the design puts a shadow on
/// `rgba(255,255,255,…)` glass; opaque boxes can keep `BoxDecoration.boxShadow`.
///
/// [radius] is the box's corner radius (`999` for a pill or a circle).
class BergenCssShadow extends StatelessWidget {
  const BergenCssShadow({
    super.key,
    required this.radius,
    required this.shadows,
    required this.child,
  });

  final double radius;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CssShadowPainter(radius: radius, shadows: shadows),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CssShadowPainter extends CustomPainter {
  const _CssShadowPainter({required this.radius, required this.shadows});

  final double radius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final r = math.min(radius, size.shortestSide / 2);
    final box = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // Everything except the box itself.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(600))
      ..addRRect(box);

    canvas.save();
    canvas.clipPath(outside);
    for (final s in shadows) {
      final shape = box.shift(s.offset).inflate(s.spreadRadius);
      final paint = Paint()..color = s.color;
      if (s.blurRadius > 0) {
        paint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(s.blurRadius),
        );
      }
      canvas.drawRRect(shape, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CssShadowPainter old) =>
      old.radius != radius || !listEquals(old.shadows, shadows);
}
