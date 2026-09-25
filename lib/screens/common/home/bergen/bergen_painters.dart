import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../splash/splash_sticker_painter.dart';
import 'bergen_kit.dart';

// Painters for the Bergen hero — the Bryggen house row (the design's
// `bryggen` template loop), its reflection, and the water. All draw in the
// design's 390-wide coordinate space and scale to [Size].

/// One house of the eleven, from the design's `bryggen` array.
class _House {
  const _House(this.x, this.w, this.top, this.rot, this.color);

  final double x;
  final double w;
  final double top; // `topp` — the ridge
  final double rot;
  final Color color;

  double get eave => top + 12; // `tak`
  double get half => w / 2;
  double get side => w + 4; // `wS`
  double get sideEave => eave - 2.5; // `takS`
  double get sideTop => top - 2.5; // `toppS`
  double get sideHalf => w / 2 + 4; // `w2S`
  double get p1 => (w * .28).roundToDouble();
  double get p2 => (w * .5).roundToDouble();
  double get p3 => (w * .72).roundToDouble();
  double get v1 => (w * .22).roundToDouble();
  double get v2 => (w * .58).roundToDouble();
  double get r1 => eave + 8;
  double get r2 => eave + 22;
  double get r3 => eave + 36;
}

List<_House> _buildHouses() {
  const colors = [
    0xFFB8452E,
    0xFF8E3B2E,
    0xFFE1642E,
    0xFFC8443A,
    0xFFEFE7D6,
    0xFFF4F1EA,
    0xFFC8443A,
    0xFFD9A254,
    0xFFE1642E,
    0xFFEFE7D6,
    0xFFB8452E,
  ];
  const widths = <double>[34, 30, 36, 32, 30, 34, 28, 32, 36, 30, 34];
  const tops = <double>[14, 20, 10, 17, 22, 12, 24, 16, 11, 20, 15];
  const rots = <double>[0, 0, -1, 0, 0, .8, 0, 0, -.6, 0, 0];
  final out = <_House>[];
  var x = -2.0;
  for (var i = 0; i < colors.length; i++) {
    out.add(_House(x, widths[i], tops[i], rots[i], Color(colors[i])));
    x += widths[i] + 2;
  }
  return out;
}

final List<_House> _kBergenHouses = _buildHouses();

Float64List _bbox(Rect r) {
  final m = Float64List(16);
  m[0] = r.width;
  m[5] = r.height;
  m[10] = 1;
  m[12] = r.left;
  m[13] = r.top;
  m[15] = 1;
  return m;
}

Paint _lin(
  Rect box,
  List<Color> colors,
  List<double> stops, {
  bool vertical = true,
}) => Paint()
  ..shader = ui.Gradient.linear(
    Offset.zero,
    vertical ? const Offset(0, 1) : const Offset(1, 0),
    colors,
    stops,
    TileMode.clamp,
    _bbox(box),
  );

/// The Bryggen row: eleven gabled houses, the quay with bollards and two
/// mooring lights, in a 390×76 box (`stilRom` houses svg).
class BergenHousesPainter extends CustomPainter {
  const BergenHousesPainter({required this.dim});

  /// Weather darkening (CSS `brightness`) as an overlay alpha.
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 76);
    for (final h in _kBergenHouses) {
      canvas.save();
      canvas.translate(h.x, 0);
      canvas.translate(h.half, 76);
      canvas.rotate(h.rot * math.pi / 180);
      canvas.translate(-h.half, -76);
      _house(canvas, h);
      canvas.restore();
    }
    _quay(canvas);
    if (dim > 0) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 390, 62),
        Paint()..color = Colors.black.withValues(alpha: dim),
      );
    }
    canvas.restore();
  }

  void _house(Canvas c, _House h) {
    final front = Path()
      ..moveTo(0, h.eave)
      ..lineTo(h.half, h.top)
      ..lineTo(h.w, h.eave)
      ..lineTo(h.w, 62)
      ..lineTo(0, 62)
      ..close();
    final side = Path()
      ..moveTo(h.w, h.eave)
      ..lineTo(h.side, h.sideEave)
      ..lineTo(h.side, 60)
      ..lineTo(h.w, 62)
      ..close();
    final roofSide = Path()
      ..moveTo(h.half, h.top)
      ..lineTo(h.sideHalf, h.sideTop)
      ..lineTo(h.side, h.sideEave)
      ..lineTo(h.w, h.eave)
      ..close();
    final sideBox = Rect.fromLTRB(h.w, h.sideEave, h.side, 62);
    c.drawPath(side, Paint()..color = h.color);
    c.drawPath(
      side,
      _lin(
        sideBox,
        [
          Colors.black.withValues(alpha: .3),
          Colors.black.withValues(alpha: .62),
        ],
        const [0, 1],
      ),
    );
    c.drawPath(roofSide, Paint()..color = h.color);
    c.drawPath(roofSide, Paint()..color = Colors.black.withValues(alpha: .5));
    c.drawPath(front, Paint()..color = h.color);
    final frontBox = Rect.fromLTRB(0, h.top, h.w, 62);
    // `brg-nabo` — the neighbour's shadow on the left 6px.
    c.drawRect(
      Rect.fromLTRB(0, h.eave, 6, 62),
      _lin(
        Rect.fromLTRB(0, h.eave, 6, 62),
        [
          Colors.black.withValues(alpha: .42),
          Colors.black.withValues(alpha: 0),
        ],
        const [0, 1],
        vertical: false,
      ),
    );
    // `brg-vegg` — horizontal light → dark.
    c.drawPath(
      front,
      _lin(
        frontBox,
        [
          Colors.white.withValues(alpha: .22),
          Colors.white.withValues(alpha: 0),
          Colors.black.withValues(alpha: .3),
        ],
        const [0, .45, 1],
        vertical: false,
      ),
    );
    // `brg-vegg-v` — vertical grime.
    c.drawPath(
      front,
      _lin(
        frontBox,
        [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .08),
          Colors.black.withValues(alpha: .38),
        ],
        const [0, .7, 1],
      ),
    );
    // Planks.
    final plank = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = const Color.fromRGBO(44, 33, 20, .5).withValues(alpha: .25);
    for (final px in [h.p1, h.p2, h.p3]) {
      c.drawLine(Offset(px, h.eave), Offset(px, 62), plank);
    }
    final rows = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5
      ..color = Colors.black.withValues(alpha: .12);
    for (final ry in [h.r1, h.r2, h.r3, 56.0]) {
      c.drawLine(Offset(0, ry), Offset(h.w, ry), rows);
    }
    // Roof: dark edge, gradient edge, soft shadow, highlight.
    final roof = Path()
      ..moveTo(0, h.eave)
      ..lineTo(h.half, h.top)
      ..lineTo(h.w, h.eave);
    final roofStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.save();
    c.translate(0, 3.4);
    c.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    c.restore();
    c.drawPath(roof, roofStroke..color = const Color.fromRGBO(44, 33, 20, .55));
    c.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(1, 0),
          [
            Colors.white.withValues(alpha: .3),
            Colors.white.withValues(alpha: .05),
            Colors.black.withValues(alpha: .35),
          ],
          const [0, .5, 1],
          TileMode.clamp,
          _bbox(Rect.fromLTRB(0, h.top, h.w, h.eave)),
        ),
    );
    c.save();
    c.translate(0, -1.2);
    c.drawLine(
      Offset(0, h.eave),
      Offset(h.half, h.top),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .55),
    );
    c.restore();
    c.drawLine(
      Offset(.6, h.eave),
      const Offset(.6, 62),
      Paint()
        ..strokeWidth = .8
        ..color = Colors.white.withValues(alpha: .35),
    );
    // Windows.
    final glow = Paint()
      ..color = const Color(0xFFFFCE7A).withValues(alpha: .55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    final frame = Paint()
      ..color = const Color(0xFF3A3128).withValues(alpha: .7);
    final shade = Paint()..color = Colors.black.withValues(alpha: .35);
    final glass = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, 1),
        const [Color(0xFFFFF3D0), Color(0xFFFFCE7A), Color(0xFFE9A24A)],
        const [0, .55, 1],
        TileMode.clamp,
        _bbox(const Rect.fromLTWH(0, 0, 4.5, 6)),
      );
    final hi = Paint()..color = Colors.white.withValues(alpha: .55);
    final sill = Paint()..color = Colors.white.withValues(alpha: .6);
    final mullion = Paint()
      ..strokeWidth = .6
      ..color = const Color(0xFF7A5A28).withValues(alpha: .7);
    for (final vx in [h.v1, h.v2]) {
      for (final ry in [h.r1, h.r2]) {
        c.drawRect(Rect.fromLTWH(vx, ry, 4.5, 6), glow);
      }
    }
    for (final vx in [h.v1, h.v2]) {
      for (final ry in [h.r1, h.r2, h.r3]) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(vx, ry, 4.5, 6),
          const Radius.circular(1),
        );
        if (ry != h.r3) {
          c.drawRRect(r.shift(const Offset(-.6, -.6)), frame);
          c.drawRRect(r.shift(const Offset(.5, .6)), shade);
        }
        c.save();
        c.translate(vx, ry);
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 4.5, 6),
            const Radius.circular(1),
          ),
          ry == h.r3
              ? (Paint()
                  ..shader = glass.shader
                  ..color = Colors.white.withValues(alpha: .7))
              : glass,
        );
        c.restore();
        if (ry != h.r3) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(vx + .6, ry + .6, 1.4, 2.2),
              const Radius.circular(.4),
            ),
            hi,
          );
          c.drawRect(Rect.fromLTWH(vx - .5, ry + 6.2, 5.5, .8), sill);
          c.drawLine(Offset(vx + 2.25, ry), Offset(vx + 2.25, ry + 6), mullion);
        }
      }
    }
    // Door + lamp.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(h.p1, 51, 8, 11),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF2C2114).withValues(alpha: .9),
    );
    c.drawLine(
      Offset(h.p1, 51),
      Offset(h.p1 + 8, 51),
      Paint()
        ..strokeWidth = 1.2
        ..color = const Color(0xFF8A6A3A).withValues(alpha: .8),
    );
    c.drawCircle(
      Offset(h.p1, 49),
      3.5,
      Paint()
        ..color = const Color(0xFFFFCE7A).withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    c.drawCircle(
      Offset(h.p1, 49),
      1.3,
      Paint()..color = const Color(0xFFFFE2A8).withValues(alpha: .9),
    );
  }

  void _quay(Canvas c) {
    c.drawRect(
      const Rect.fromLTWH(0, 54, 390, 8),
      _lin(
        const Rect.fromLTWH(0, 54, 390, 8),
        [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .08 * .9),
          Colors.black.withValues(alpha: .38 * .9),
        ],
        const [0, .7, 1],
      ),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 61, 390, 6),
        const Radius.circular(1),
      ),
      _lin(
        const Rect.fromLTWH(0, 61, 390, 6),
        const [Color(0xFF6A5A44), Color(0xFF4A3C2A), Color(0xFF241A10)],
        const [0, .35, 1],
      ),
    );
    c.drawRect(
      const Rect.fromLTWH(0, 61, 390, 1),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );
    final tick = Paint()
      ..strokeWidth = .8
      ..color = const Color(0xFF1A1209).withValues(alpha: .55);
    for (var x = 14.0; x < 390; x += 26) {
      c.drawLine(Offset(x, 61), Offset(x, 67), tick);
    }
    final bollard = Paint()..color = const Color(0xFF3A3128);
    for (final x in <double>[24, 106, 196, 286, 358]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 66, 3.2, 9),
          const Radius.circular(1.6),
        ),
        bollard,
      );
    }
    final dot = Paint()..color = BergenColors.orange.withValues(alpha: .9);
    c.drawCircle(const Offset(66, 70), 1.6, dot);
    c.drawCircle(const Offset(248, 70), 1.6, dot);
  }

  @override
  bool shouldRepaint(BergenHousesPainter old) => old.dim != dim;
}

/// The houses mirrored into the water just under the quay (`Husenes speiling
/// i vannet`): each house as a colour column, 28% opacity, fading downward.
class BergenHouseReflectionPainter extends CustomPainter {
  const BergenHouseReflectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final h in _kBergenHouses) {
      canvas.drawRect(
        Rect.fromLTWH(h.x * sx, 0, h.w * sx, size.height),
        Paint()..color = h.color.withValues(alpha: .28),
      );
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ]),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BergenHouseReflectionPainter old) => false;
}

/// The water (`Sjø · hero` / `Sjø · kveld`): depth gradient, three drifting
/// ripple layers, a slow glint, vignette and the light haze at the surface.
/// [t] is milliseconds; the design's layers drift on 14–31s cycles.
class BergenSeaPainter extends CustomPainter {
  const BergenSeaPainter({
    required this.t,
    required this.rain,
    this.base = const Color(0xFF3D6B7A),
    this.rippleAlpha = 1,
  });

  final double t;
  final bool rain;
  final Color base;
  final double rippleAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    // `hav-dybde` (#3D6B7A → #2C5563 → #16303A) at 40%, flipped so the deep
    // end sits at the bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h),
          Offset.zero,
          [
            const Color(0xFF16303A).withValues(alpha: .4),
            const Color(0xFF2C5563).withValues(alpha: .4),
            const Color(0xFF3D6B7A).withValues(alpha: .4),
          ],
          const [0, .65, 1],
        ),
    );
    // Ripple bands (the baked `lf/lm/ln` patterns, wobbled and drifting).
    _ripples(
      canvas,
      size,
      period: 22,
      light: .34,
      dark: .18,
      speed: 21000,
      phase: 0,
      amp: 6,
      alpha: .9,
    );
    _ripples(
      canvas,
      size,
      period: 13,
      light: .30,
      dark: .16,
      speed: 15000,
      phase: 2.1,
      amp: 4,
      alpha: .8,
    );
    _ripples(
      canvas,
      size,
      period: 7,
      light: .26,
      dark: .14,
      speed: 11000,
      phase: 4.2,
      amp: 2.5,
      alpha: .7,
    );
    // Glint drifting across.
    final gp = ((t / 33000) % 1.0);
    final gx = w * (.38 + .24 * math.sin(gp * math.pi * 2));
    final gy = h * (.44 + .06 * math.cos(gp * math.pi * 2));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(gx, gy), width: w * .84, height: h * .76),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(gx, gy),
          w * .42,
          [
            Colors.white.withValues(alpha: .18),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .72],
        ),
    );
    // Vignette + top haze + top shade.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * .5, h * .3),
          w * 1.1,
          [Colors.transparent, const Color.fromRGBO(3, 14, 20, .3)],
          const [.58, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 46),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 46), [
          const Color.fromRGBO(190, 214, 222, .22),
          const Color.fromRGBO(190, 214, 222, 0),
        ]),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 28),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 28), [
          const Color.fromRGBO(8, 24, 32, .28),
          const Color.fromRGBO(8, 24, 32, 0),
        ]),
    );
    if (rain) _rainRings(canvas, size);
  }

  void _ripples(
    Canvas canvas,
    Size size, {
    required double period,
    required double light,
    required double dark,
    required double speed,
    required double phase,
    required double amp,
    required double alpha,
  }) {
    final drift = math.sin((t / speed + phase) * math.pi * 2) * 18;
    final lightP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = period > 10 ? 1.4 : .9
      ..color = Colors.white.withValues(alpha: light * alpha * rippleAlpha);
    final darkP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = period > 10 ? 2.2 : 1
      ..color = const Color(
        0xFF081820,
      ).withValues(alpha: dark * alpha * rippleAlpha);
    final w = size.width;
    for (var y = period * .4; y < size.height + period; y += period) {
      final p = Path();
      final pd = Path();
      for (var x = -20.0; x <= w + 20; x += 8) {
        final wob =
            math.sin((x + drift) / (34 + period) + y / 9 + phase) * amp +
            math.sin((x - drift) / 13 + y / 5) * amp * .35;
        final yy = y + wob;
        if (x == -20) {
          p.moveTo(x, yy);
          pd.moveTo(x, yy + 1.4);
        } else {
          p.lineTo(x, yy);
          pd.lineTo(x, yy + 1.4);
        }
      }
      canvas.drawPath(pd, darkP);
      canvas.drawPath(p, lightP);
    }
  }

  void _rainRings(Canvas canvas, Size size) {
    const rings = <List<double>>[
      [60, 30, 20, 8, 2200, 0, .6],
      [230, 60, 18, 7, 2600, 900, .55],
      [330, 20, 16, 6, 2400, 1600, .5],
    ];
    final sx = size.width / 390;
    for (final r in rings) {
      final p = ((t - r[5]) / r[4]) % 1.0;
      if (p < 0) continue;
      final s = .2 + 1.2 * p;
      final o = .75 * (1 - p);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset((r[0] + r[2] / 2) * sx, r[1] + r[3] / 2),
          width: r[2] * s * sx,
          height: r[3] * s,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFD6F2FA).withValues(alpha: r[6] * o),
      );
    }
  }

  @override
  bool shouldRepaint(BergenSeaPainter old) =>
      old.t != t ||
      old.rain != rain ||
      old.base != base ||
      old.rippleAlpha != rippleAlpha;
}

/// The lit windows overlay for the mountain scene (`k-scene2-lys`) is an
/// SVG asset; the mist and vignette over the scene are plain gradients. This
/// painter adds the two faint wave lines the scene draws across the water.
class BergenSceneLinesPainter extends CustomPainter {
  const BergenSceneLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .08);
    for (final y in [158.0, 186, 208]) {
      final path = Path()
        ..moveTo(-10 * sx, y * size.height / 246)
        ..quadraticBezierTo(
          195 * sx,
          (y - 6) * size.height / 246,
          400 * sx,
          y * size.height / 246,
        );
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(BergenSceneLinesPainter old) => false;
}

/// Soft radial blob helper reused across the hero (shadows, glows).
Widget bergenRadial({
  required List<Color> colors,
  required List<double> stops,
  Offset center = const Offset(.5, .5),
  Offset radii = const Offset(.5, .5),
  bool oval = true,
}) => CustomPaint(
  painter: SplashRadialPainter(
    center: center,
    radii: radii,
    colors: colors,
    stops: stops,
    oval: oval,
  ),
);
