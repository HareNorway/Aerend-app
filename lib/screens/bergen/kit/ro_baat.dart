import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart';
import 'bergen_css.dart';
import 'bergen_motion.dart';
import 'svg_sti.dart';

/// Ægil rowing (Seilas L3850 / kassen L6149 / Sporing): the 64×44 boat
/// rocking (`roVugg 4.4s`), surging on each stroke (`roSurge 2.2s`), Ægil
/// leaning into it (`roKropp`), both oars sweeping (`roAare`) with rings
/// (`roRingK`) and spray (`roSprut`) where they bite, two wake arcs
/// (`roKjol2`), the hull mirrored in the water and the water line rolling
/// past (`roBolge`); under it the light on the water (`sjoSkygge`).
/// 64 × 50 design px.
class RoBaat extends StatelessWidget {
  const RoBaat({super.key});

  /// One stroke: `cubic-bezier(.45,.05,.4,1)` per keyframe.
  static const _slag = Cubic(.45, .05, .4, 1);

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      width: 64 * s,
      height: 50 * s,
      child: Column(
        children: [
          // `roVugg 4.4s ease-in-out`.
          BergenLoop(
            durationMs: 4400,
            builder: (context, p, child) {
              final q = p ?? 0;
              const st = [0.0, .25, .5, .75, 1.0];
              final y = kf(q, st, const [0, -1.2, -1.8, -.6, 0], Curves.easeInOut);
              final r = kf(q, st, const [-1.2, .4, 1.4, .2, -1.2], Curves.easeInOut);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, y * s, 0)..rotateZ(r * math.pi / 180),
                child: child,
              );
            },
            child: SizedBox(
              width: 64 * s,
              height: 44 * s,
              child: BergenLoop(
                durationMs: 2200,
                builder: (context, p, _) => _Takt(p: p ?? 0, s: s),
              ),
            ),
          ),
          // `sjoSkygge 2.2s ease-in-out`.
          BergenLoop(
            durationMs: 2200,
            builder: (context, p, _) {
              final q = p ?? 0;
              return Opacity(
                opacity: kf(q, const [0, .5, 1], const [.55, .4, .55], Curves.easeInOut),
                child: Transform.scale(
                  scaleX: kf(q, const [0, .5, 1], const [1, .92, 1], Curves.easeInOut),
                  child: SizedBox(
                    width: 44 * s,
                    height: 6 * s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [rgba(255, 255, 255, .45), rgba(255, 255, 255, 0)],
                          stops: const [0, .72],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One frame of the 2.2 s stroke.
class _Takt extends StatelessWidget {
  const _Takt({required this.p, required this.s});

  final double p;
  final double s;

  @override
  Widget build(BuildContext context) {
    // `roSurge`: 0, 14 % → 0; 58 % → 1.6px.
    final surge = kf(p, const [0, .14, .58, 1], const [0, 0, 1.6, 0], Curves.easeInOut);
    // `roKropp`.
    const kst = [0.0, .14, .58, .70, 1.0];
    final kr = kf(p, kst, const [3, 4, -5, -4, 3], RoBaat._slag);
    final kx = kf(p, kst, const [.5, 1, -1, -1, .5], RoBaat._slag);
    return Transform.translate(
      offset: Offset(surge * s, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `roKjol2`: two wake arcs behind the stern, 1.1 s apart.
          for (final (d, a) in [(0.0, .7), (.5, .6)])
            Positioned(
              left: -18 * s,
              top: 33 * s,
              width: 26 * s,
              height: 7 * s,
              child: _Kjol(t: (p + d) % 1, a: a, s: s),
            ),
          // The boat's inside (`ro-inn`), its rim and the thwart.
          Positioned(
            left: -4 * s,
            top: 0,
            width: 72 * s,
            height: 45 * s,
            child: CustomPaint(painter: _InnPainter()),
          ),
          // Ægil (`roKropp`, origin 50 % 85 %).
          Positioned(
            left: 14 * s,
            top: 1 * s,
            width: 36 * s,
            height: 36 * s,
            child: Transform(
              alignment: const Alignment(0, .7),
              transform: Matrix4.translationValues(kx * s, 0, 0)..rotateZ(kr * math.pi / 180),
              child: Image.asset(BergenAssets.aegilFront, fit: BoxFit.contain),
            ),
          ),
          // The hull, the stripe, the gunwale, the oars, the mirror and the
          // water line.
          Positioned(
            left: -4 * s,
            top: 0,
            width: 72 * s,
            height: 45 * s,
            child: CustomPaint(painter: _SkrogPainter(p)),
          ),
          // `roRingK` where the blades bite.
          for (final l in [-8.0, 56.0])
            Positioned(
              left: l * s,
              top: (l < 0 ? 37 : 35) * s,
              width: 18 * s,
              height: 6 * s,
              child: _Ring(t: p),
            ),
          // `roSprut`: three drops off each blade.
          for (final (l, t, dx, dy, d) in const [
            (0.0, 37.0, -4.0, -7.0, 0.0),
            (2.0, 37.0, 2.0, -9.0, .03),
            (-2.0, 38.0, -7.0, -4.0, .05),
            (64.0, 35.0, 4.0, -8.0, 0.0),
            (66.0, 35.0, 7.0, -5.0, .03),
            (62.0, 36.0, -2.0, -9.0, .05),
          ])
            Positioned(
              left: l * s,
              top: t * s,
              width: 2.2 * s,
              height: 2.2 * s,
              child: _Sprut(t: (p - d / 2.2) % 1, dx: dx, dy: dy, s: s),
            ),
        ],
      ),
    );
  }
}

class _Kjol extends StatelessWidget {
  const _Kjol({required this.t, required this.a, required this.s});

  final double t;
  final double a;
  final double s;

  @override
  Widget build(BuildContext context) {
    final e = Curves.easeOut.transform(t);
    return Opacity(
      opacity: (.7 * (1 - e)).clamp(0.0, 1.0),
      child: Transform(
        transform: Matrix4.translationValues(-24 * e * s, 1 * e * s, 0)..scaleByDouble(.5 + e, .6 + .6 * e, 1, 1),
        alignment: Alignment.center,
        child: CustomPaint(painter: _BuePainter(rgba(226, 248, 252, a), 1.2 * s)),
      ),
    );
  }
}

/// `border-top` of an ellipse: the upper arc only.
class _BuePainter extends CustomPainter {
  const _BuePainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Offset.zero & size,
      math.pi * 1.08,
      math.pi * .84,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_BuePainter old) => old.color != color || old.width != width;
}

class _Ring extends StatelessWidget {
  const _Ring({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    // 0–12 %: hidden at .25; 16 %: .85; 64 %: 1.6, gone.
    final e = Curves.easeOut.transform(t);
    final sc = kf(e, const [0, .12, .64, 1], const [.25, .25, 1.6, 1.6]);
    final op = kf(e, const [0, .12, .16, .64, 1], const [0, 0, .85, 0, 0]);
    return Opacity(
      opacity: op.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: sc,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rgba(226, 248, 252, .85)),
          ),
        ),
      ),
    );
  }
}

class _Sprut extends StatelessWidget {
  const _Sprut({required this.t, required this.dx, required this.dy, required this.s});

  final double t;
  final double dx;
  final double dy;
  final double s;

  @override
  Widget build(BuildContext context) {
    final e = Curves.easeOut.transform(t);
    const st = [0.0, .12, .16, .36, 1.0];
    final op = kf(e, st, const [0, 0, 1, 0, 0]);
    final sc = kf(e, st, const [.4, .4, 1, .6, .6]);
    final x = kf(e, st, [0, 0, 0, dx, dx]);
    final y = kf(e, st, [0, 0, -1, dy, dy]);
    return Opacity(
      opacity: op.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(x * s, y * s),
        child: Transform.scale(
          scale: sc,
          child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F8FB))),
        ),
      ),
    );
  }
}

/// The 80×50 viewBox, drawn into the 72×45 box.
abstract final class _Ro {
  static final skrog = svgSti('M6 23 Q40 27 76 17 C72 30 60 38.5 44 38.5 C26 38.5 12 34 6 23 Z');
  static final innside = svgSti('M7 22.4 Q40 21 75 16.2 Q42 27 7 22.4 Z');
  static final kant = svgSti('M7 22.4 Q40 21 75 16.2');
  static final bord = [
    (svgSti('M8 27 Q40 31 74.5 20.6'), const Color.fromRGBO(40, 20, 6, .5), .8),
    (svgSti('M8.4 27.6 Q40 31.6 74.2 21.2'), const Color.fromRGBO(255, 220, 170, .16), .5),
    (svgSti('M10.5 31.4 Q40 35.2 71.5 25.4'), const Color.fromRGBO(40, 20, 6, .5), .8),
    (svgSti('M10.9 32 Q40 35.8 71.2 26'), const Color.fromRGBO(255, 220, 170, .14), .5),
    (svgSti('M16 35 Q40 38.2 66 30'), const Color.fromRGBO(40, 20, 6, .45), .7),
  ];
  static final baugLys = svgSti('M70 20 C72.5 19 74.5 18 76 17 C74 24 71 29 67 32');
  static final akterSkygge = svgSti('M6 23 C9 29 13 33 20 35.6');
  static final stripe = svgSti('M8.5 28.6 Q40 32.6 73.4 22.4');
  static final stripeLys = svgSti('M8.5 27.8 Q40 31.8 73.6 21.6');
  static final ripe = svgSti('M6 23 Q40 27 76 17');
  static final ripeLys = svgSti('M6.4 22.3 Q40 26.3 75.6 16.3');
  static final bolge = svgSti(
    'M-14 36.4 Q-9 35 -4 36.4 T6 36.4 T16 36.4 T26 36.4 T36 36.4 T46 36.4 T56 36.4 T66 36.4 T76 36.4 T86 36.4 T96 36.4',
  );
  static final bolgeFyll = svgSti(
    'M-14 36.4 Q-9 35 -4 36.4 T6 36.4 T16 36.4 T26 36.4 T36 36.4 T46 36.4 T56 36.4 T66 36.4 T76 36.4 T86 36.4 T96 36.4 V54 H-14 Z',
  );

  /// `ro-tre`: #A9743E → #8A5A2C 45 % → #4E3016, top to bottom of the hull.
  static Paint tre(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFA9743E), Color(0xFF8A5A2C), Color(0xFF4E3016)],
      stops: [0, .45, 1],
    ).createShader(r);

  static Paint strek(Color c, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..color = c;
}

class _InnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80);
    canvas.drawPath(
      _Ro.innside,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A381A), Color(0xFF2E1A0A)],
        ).createShader(_Ro.innside.getBounds()),
    );
    canvas.drawPath(_Ro.kant, _Ro.strek(const Color(0xFFB88A52), 1.1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36, 20.5, 10, 2.4), const Radius.circular(.8)),
      Paint()..color = const Color(0xFF6E4520),
    );
  }

  @override
  bool shouldRepaint(_InnPainter old) => false;
}

class _SkrogPainter extends CustomPainter {
  const _SkrogPainter(this.p);

  final double p;

  void _skrog(Canvas canvas) {
    canvas.drawPath(_Ro.skrog, _Ro.tre(_Ro.skrog.getBounds()));
    for (final (path, c, w) in _Ro.bord) {
      canvas.drawPath(path, _Ro.strek(c, w));
    }
    canvas.drawPath(_Ro.baugLys, Paint()..color = const Color.fromRGBO(255, 220, 170, .12));
    canvas.drawPath(_Ro.akterSkygge, _Ro.strek(const Color.fromRGBO(20, 10, 2, .35), 1.2)..strokeCap = StrokeCap.butt);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 80);
    // The shadow under the hull.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(41, 41), width: 62, height: 7.2),
      Paint()..color = const Color.fromRGBO(3, 14, 20, .38),
    );
    _skrog(canvas);
    canvas.drawPath(_Ro.stripe, _Ro.strek(const Color(0xFFE95C2C), 1.6));
    canvas.drawPath(_Ro.stripeLys, _Ro.strek(const Color.fromRGBO(255, 190, 150, .45), .5));
    canvas.drawPath(_Ro.ripe, _Ro.strek(const Color(0xFFC99A5E), 2.3));
    canvas.drawPath(_Ro.ripeLys, _Ro.strek(const Color(0xFFF4D7A6), .7));
    final aare = Paint()..color = const Color(0xFF3A2410);
    canvas.drawCircle(const Offset(23, 24.6), 1.3, aare);
    canvas.drawCircle(const Offset(58, 23.2), 1.3, aare);

    // `roAare`: −16° → −18° (14 %) → 16° (58 %) → 18° (70 %) → −16°.
    const st = [0.0, .14, .58, .70, 1.0];
    final rot = kf(p, st, const [-16, -18, 16, 18, -16], RoBaat._slag) * math.pi / 180;
    final ty = kf(p, st, const [-2.5, 0, 0, -3, -2.5], RoBaat._slag);
    void aaren(Offset pivot, Offset fra, Offset til, double bladRot) {
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(rot);
      canvas.translate(-pivot.dx, -pivot.dy + ty);
      canvas.drawLine(
        fra,
        til,
        Paint()
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [Color(0xFFE8C48E), Color(0xFF9A6834)]).createShader(Rect.fromPoints(fra, til)),
      );
      canvas.save();
      canvas.translate(til.dx, til.dy);
      canvas.rotate(bladRot * math.pi / 180);
      final blad = Rect.fromCenter(center: Offset.zero, width: 9.2, height: 3.4);
      canvas.drawOval(blad, Paint()..color = const Color(0xFFC98E4E));
      canvas.drawOval(blad, _Ro.strek(const Color(0xFF7A4E24), .6));
      canvas.restore();
      canvas.restore();
    }

    aaren(const Offset(23, 24.6), const Offset(25, 21.5), const Offset(7, 44), -55);
    aaren(const Offset(58, 23.2), const Offset(56, 20.5), const Offset(75, 42), 55);

    // The hull mirrored in the water (`translate(0 77) scale(1 -1)`, .22).
    canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, .22));
    canvas.translate(0, 77);
    canvas.scale(1, -1);
    _skrog(canvas);
    canvas.restore();

    // `roBolge 2.2s linear`: the water line, masked to fade at both ends.
    final dx = -20 * p;
    const maske = Rect.fromLTWH(-6, 30, 94, 26);
    canvas.saveLayer(const Rect.fromLTWH(-14, 30, 110, 26), Paint());
    canvas.save();
    canvas.translate(dx, 0);
    canvas.drawPath(
      _Ro.bolgeFyll,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(34, 92, 106, .55), Color.fromRGBO(20, 62, 74, .85)],
        ).createShader(const Rect.fromLTWH(-14, 35, 110, 19)),
    );
    canvas.drawPath(_Ro.bolge, _Ro.strek(const Color.fromRGBO(226, 248, 252, .75), .8));
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(-14, 30, 110, 26),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          stops: [0, .18, .82, 1],
        ).createShader(maske),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkrogPainter old) => old.p != p;
}
