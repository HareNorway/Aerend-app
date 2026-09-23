import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Painters for the 3D-sticker Æ mark on the splash — a 1:1 port of the
// `<symbol id="merke">` art and the `spGlattUt` sheen overlay in
// `Design/Ærend Kunde Bergen (frittstående).html`. Both draw in the design's
// SVG user space (`viewBox="-30 -14 172 138"`, `rotate(-5 60 53)`).

const Color _navy = Color(0xFF0F1F2B);
const Color _white = Color(0xFFFFFFFF);

Path _letterPath() => Path()
  ..moveTo(14, 90)
  ..lineTo(60, 16)
  ..lineTo(60, 90)
  ..moveTo(34, 58)
  ..lineTo(60, 58)
  ..moveTo(62, 16)
  ..lineTo(104, 16)
  ..moveTo(62, 53)
  ..lineTo(96, 53)
  ..moveTo(62, 90)
  ..lineTo(104, 90);

Path _speedPath() => Path()
  ..moveTo(-14, 60)
  ..lineTo(8, 60)
  ..moveTo(-8, 76)
  ..lineTo(4, 76);

Path _peelPath() => Path()
  ..moveTo(107.6, 78)
  ..quadraticBezierTo(113.5, 84.5, 116, 95)
  ..cubicTo(106.5, 95.5, 98.5, 87.5, 102.4, 79.6)
  ..cubicTo(104, 78.6, 105.8, 78, 107.6, 78)
  ..close();

Path _limPath() => Path()
  ..moveTo(107.6, 78)
  ..quadraticBezierTo(113.5, 84.5, 116, 95)
  ..arcToPoint(
    const Offset(107.6, 78),
    radius: const Radius.circular(12.5),
    clockwise: false,
  )
  ..close();

Paint _stroke(Color color, double width, {double blur = 0}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  return paint;
}

Paint _fill(Color color, {double blur = 0}) {
  final paint = Paint()..color = color;
  if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  return paint;
}

/// SVG `objectBoundingBox` gradient space → local space for [box].
Float64List _bboxMatrix(Rect box) {
  final m = Float64List(16);
  m[0] = box.width;
  m[5] = box.height;
  m[10] = 1;
  m[12] = box.left;
  m[13] = box.top;
  m[15] = 1;
  return m;
}

/// Maps the `-30 -14 172 138` viewBox into [size] (`xMidYMid meet`) and
/// applies the mark's `rotate(-5 60 53)`.
void _enterMarkSpace(Canvas canvas, Size size) {
  final s = math.min(size.width / 172, size.height / 138);
  canvas.translate((size.width - 172 * s) / 2, (size.height - 138 * s) / 2);
  canvas.scale(s);
  canvas.translate(30, 14);
  canvas.translate(60, 53);
  canvas.rotate(-5 * math.pi / 180);
  canvas.translate(-60, -53);
}

/// `mask="url(#b-mask)"` — the white sticker outline as an alpha mask.
void _drawMarkMask(Canvas canvas) {
  canvas.drawPath(_letterPath(), _stroke(_white, 25));
  canvas.drawPath(_speedPath(), _stroke(_white, 16));
}

const Rect _maskRect = Rect.fromLTWH(-30, -20, 180, 150);

/// The full layered sticker (`#merke`).
class SplashStickerPainter extends CustomPainter {
  const SplashStickerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _enterMarkSpace(canvas, size);

    final letter = _letterPath();
    final speed = _speedPath();

    // Soft drop shadow (`opacity=.22`, `#b-soft`).
    canvas.save();
    canvas.translate(1.5, 6);
    canvas.drawPath(letter, _stroke(_navy.withValues(alpha: .22), 17, blur: 3));
    canvas.drawPath(speed, _stroke(_navy.withValues(alpha: .22), 8, blur: 3));
    canvas.restore();

    // Contact edge.
    canvas.save();
    canvas.translate(0, 1.4);
    canvas.drawPath(letter, _stroke(_navy.withValues(alpha: .14), 25.5));
    canvas.drawPath(speed, _stroke(_navy.withValues(alpha: .14), 16.5));
    canvas.restore();

    // Sticker border: white → bevel grey → white.
    canvas.drawPath(letter, _stroke(_white, 25));
    canvas.drawPath(speed, _stroke(_white, 16));
    canvas.drawPath(letter, _stroke(const Color(0xFFDFE5E8), 22.4));
    canvas.drawPath(speed, _stroke(const Color(0xFFDFE5E8), 13.6));
    canvas.drawPath(letter, _stroke(_white, 21));
    canvas.drawPath(speed, _stroke(_white, 12.4));

    // Ink.
    canvas.drawPath(letter, _stroke(const Color(0xFF3A7D8C), 15));
    canvas.drawPath(speed, _stroke(const Color(0xFFF26D3D), 6.5));

    // Ink highlight.
    canvas.save();
    canvas.translate(-1.6, -2.2);
    canvas.drawPath(
      letter,
      _stroke(const Color(0xFF8FC2CF).withValues(alpha: .75), 3),
    );
    canvas.restore();

    // Gloss (`#b-gloss`, masked by the sticker outline).
    canvas.saveLayer(_maskRect, Paint());
    _drawMarkMask(canvas);
    canvas.saveLayer(_maskRect, Paint()..blendMode = BlendMode.srcIn);
    canvas.drawRect(
      _maskRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(1, 1),
          [
            _white.withValues(alpha: 0),
            _white.withValues(alpha: 0),
            _white.withValues(alpha: .26),
            _white.withValues(alpha: .1),
            _white.withValues(alpha: 0),
            _white.withValues(alpha: 0),
          ],
          const [0, .22, .3, .35, .4, 1],
          TileMode.clamp,
          _bboxMatrix(_maskRect),
        ),
    );
    canvas.restore();
    canvas.restore();

    // Adhesive under the peeled corner (`#b-lim`).
    final lim = _limPath();
    canvas.drawPath(
      lim,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(1, 1),
          [
            const Color(0xFFD5DCE0).withValues(alpha: .82),
            const Color(0xFFE9EEF0).withValues(alpha: .7),
            const Color(0xFFC3CBD0).withValues(alpha: .78),
          ],
          const [0, .55, 1],
          TileMode.clamp,
          _bboxMatrix(lim.getBounds()),
        ),
    );
    final dot = _fill(_white.withValues(alpha: .55));
    canvas.drawCircle(const Offset(113.2, 84.6), 1.1, dot);
    canvas.drawCircle(const Offset(115.4, 89.8), .8, dot);
    canvas.drawCircle(const Offset(111, 80.8), .7, dot);

    // Peel edge crease (unfilled SVG path → default black fill + stroke).
    final edge = Path()
      ..moveTo(107.6, 78)
      ..quadraticBezierTo(113.5, 84.5, 116, 95);
    canvas.saveLayer(null, Paint()..color = _white.withValues(alpha: .18));
    canvas.drawPath(edge, _fill(const Color(0xFF000000), blur: 1.1));
    canvas.drawPath(edge, _stroke(_navy, 1.2, blur: 1.1));
    canvas.restore();

    // Peeled flap: shadow, paper, ambient occlusion.
    final peel = _peelPath();
    final peelBox = peel.getBounds();
    canvas.save();
    canvas.translate(-2.5, 4.5);
    canvas.drawPath(peel, _fill(_navy.withValues(alpha: .3), blur: 3));
    canvas.restore();
    canvas.drawPath(
      peel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(1, 1),
          Offset.zero,
          const [
            Color(0xFFC9D0D4),
            Color(0xFFF7F8F9),
            Color(0xFFFFFFFF),
            Color(0xFFE4E8EA),
            Color(0xFFAEB7BD),
          ],
          const [0, .14, .42, .72, 1],
          TileMode.clamp,
          _bboxMatrix(peelBox),
        ),
    );
    canvas.drawPath(
      peel,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(.9, .9),
          .9,
          [_navy.withValues(alpha: .18), _navy.withValues(alpha: 0)],
          const [0, .45],
          TileMode.clamp,
          _bboxMatrix(peelBox),
        ),
    );

    // Flap highlight (unfilled SVG path → default black fill + stroke).
    final shine = Path()
      ..moveTo(103.6, 81.2)
      ..cubicTo(106.5, 86.5, 110, 90.5, 114.6, 93.2);
    canvas.saveLayer(null, Paint()..color = _white.withValues(alpha: .7));
    canvas.drawPath(shine, _fill(const Color(0xFF000000), blur: 1.1));
    canvas.drawPath(shine, _stroke(_white, 1.6, blur: 1.1));
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashStickerPainter oldDelegate) => false;
}

/// `spGlattUt` — a skewed white band sweeping across the sticker, masked to
/// its outline. [translateX] / [opacity] are the keyframed values.
class SplashSheenPainter extends CustomPainter {
  const SplashSheenPainter({
    required this.translateX,
    required this.opacity,
    this.bandWidth = 44,
  });

  final double translateX;
  final double opacity;

  /// Width of the skewed band (`<rect width>`): 44 on the splash, 50 on the
  /// onboarding landing.
  final double bandWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.save();
    _enterMarkSpace(canvas, size);
    canvas.saveLayer(_maskRect, Paint());
    _drawMarkMask(canvas);
    canvas.saveLayer(
      _maskRect,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..color = _white.withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
    canvas.translate(translateX, 0);
    canvas.skew(math.tan(-18 * math.pi / 180), 0);
    final band = Rect.fromLTWH(-76, -40, bandWidth, 200);
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(1, 0),
          [
            _white.withValues(alpha: 0),
            _white.withValues(alpha: .9),
            _white.withValues(alpha: 0),
          ],
          const [0, .5, 1],
          TileMode.clamp,
          _bboxMatrix(band),
        ),
    );
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashSheenPainter oldDelegate) =>
      oldDelegate.translateX != translateX ||
      oldDelegate.opacity != opacity ||
      oldDelegate.bandWidth != bandWidth;
}

/// CSS `radial-gradient(<rx> <ry> at <cx> <cy>, …)` over the whole box.
/// [center] and [radii] are fractions of the box size; [oval] clips to the
/// box's ellipse (`border-radius: 50%`).
class SplashRadialPainter extends CustomPainter {
  const SplashRadialPainter({
    required this.center,
    required this.radii,
    required this.colors,
    required this.stops,
    this.oval = false,
  });

  final Offset center;
  final Offset radii;
  final List<Color> colors;
  final List<double> stops;
  final bool oval;

  @override
  void paint(Canvas canvas, Size size) {
    final m = Float64List(16);
    m[0] = size.width * radii.dx;
    m[5] = size.height * radii.dy;
    m[10] = 1;
    m[12] = size.width * center.dx;
    m[13] = size.height * center.dy;
    m[15] = 1;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        1,
        colors,
        stops,
        TileMode.clamp,
        m,
      );
    final rect = Offset.zero & size;
    if (oval) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(SplashRadialPainter oldDelegate) => false;
}
