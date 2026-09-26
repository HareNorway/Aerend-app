import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_kit.dart';
import '../kit/bergen_motion.dart';
import 'kasse_copy.dart';

/// `Seilas · kassen` (design L4976–4998): the 104-px header of the Kurv
/// screen — the dashed course, the quay with the store's logo and «Bryggen»,
/// and Ægil rowing in from the left (`roInn 1.3s .1s`), bobbing (`roVugg
/// 2.2s`), oars on `aareA` / `aareB`, the wake (`roKjolvann`), the shadow
/// (`sjoSkygge`) and the two `damp` bubbles over the quay. On pay the boat
/// leaves to the right (`roAvgang .75s cubic-bezier(.4,0,.8,.4)`).
///
/// Left of it the back button (`38 r14` glass) and the title («Kassen» 26px
/// Plus Jakarta 800 −.03em, «Ægil ror til bryggen» with the mint dot).
class KurvSeilas extends StatelessWidget {
  const KurvSeilas({
    super.key,
    required this.safeTop,
    required this.embedded,
    required this.departing,
    this.storeName,
    this.storeLogoUrl,
  });

  final double safeTop;
  final bool embedded;

  /// `kasseAvgang`: the boat rows off (pay started).
  final bool departing;
  final String? storeName;
  final String? storeLogoUrl;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      key: const Key('a1_kasse_seilas'),
      height: safeTop + 104 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: safeTop,
            width: 170 * s,
            height: 104 * s,
            child: IgnorePointer(
              child: _Sea(
                departing: departing,
                storeName: storeName,
                storeLogoUrl: storeLogoUrl,
              ),
            ),
          ),
          Positioned(
            left: 16 * s,
            right: 16 * s,
            top: safeTop + 26 * s,
            child: Row(
              children: [
                if (!embedded) ...[
                  OnbPressable(
                    onTap: () => Navigator.of(context).maybePop(),
                    pressScale: .92,
                    child: BergenCssShadow(
                      radius: 14 * s,
                      shadows: [
                        BoxShadow(
                          color: rgba(4, 18, 26, .8),
                          offset: Offset(0, 10 * s),
                          blurRadius: onbBlur(18 * s),
                          spreadRadius: -10 * s,
                        ),
                      ],
                      child: Container(
                        key: const Key('a1_kasse_tilbake'),
                        width: 38 * s,
                        height: 38 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14 * s),
                          gradient: cssLinear(180, [rgba(255, 255, 255, .16), rgba(255, 255, 255, .07)]),
                          border: Border.all(color: rgba(255, 255, 255, .26)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size.square(15 * s),
                              painter: _StrokePainter(2.4, (c, p) {
                                c.drawPath(
                                  Path()
                                    ..moveTo(15, 6)
                                    ..lineTo(9, 12)
                                    ..lineTo(15, 18),
                                  p,
                                );
                              }),
                            ),
                            bergenInsetTop(radius: 14 * s, height: 1.5 * s, alpha: .32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        KasseCopy.a1_kasse_kassen,
                        style: bDisplay(context, 26, letterSpacingEm: -.03, height: 1),
                      ),
                      SizedBox(height: 6 * s),
                      Row(
                        children: [
                          Container(
                            width: 6 * s,
                            height: 6 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF5CE0B8),
                              boxShadow: [BoxShadow(color: const Color(0xFF5CE0B8), blurRadius: onbBlur(8 * s))],
                            ),
                          ),
                          SizedBox(width: 6 * s),
                          Text(
                            departing ? KasseCopy.a1_kasse_ror_avgang : KasseCopy.a1_kasse_ror,
                            style: bText(context, 10.5, color: rgba(255, 255, 255, .7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sea extends StatelessWidget {
  const _Sea({required this.departing, this.storeName, this.storeLogoUrl});

  final bool departing;
  final String? storeName;
  final String? storeLogoUrl;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // `M-20 70 C40 56 90 82 150 66` dashed 5 7, white .35, 1.4px (in a
        // 190×104 box anchored at the same left).
        Positioned(
          left: 0,
          top: 0,
          width: 190 * s,
          height: 104 * s,
          child: CustomPaint(painter: _CoursePainter(s)),
        ),
        // `onbRing 9s 2s ease-out infinite`: 150×44 at left 50% top 66.
        Positioned(
          left: 85 * s - 75 * s,
          top: 66 * s - 22 * s,
          width: 150 * s,
          height: 44 * s,
          child: BergenLoop(
            durationMs: 9000,
            delayMs: 2000,
            builder: (context, p, _) {
              if (p == null) return const SizedBox();
              final q = Curves.easeOut.transform(p);
              const st = [0.0, .12, .18, .6, 1.0];
              return Opacity(
                opacity: kf(q, st, const [0, 0, .5, .18, 0]),
                child: Transform.scale(
                  scale: kf(q, st, const [.55, .55, .55 + (1.9 - .55) * (.18 - .12) / .88, .55 + (1.9 - .55) * (.6 - .12) / .88, 1.9]),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: rgba(255, 255, 255, .4)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // The quay: `right:14;top:22;54×70`.
        Positioned(
          right: 14 * s,
          top: 22 * s,
          width: 54 * s,
          height: 70 * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final r in [10.0, 40.0])
                Positioned(
                  right: r * s,
                  top: 46 * s,
                  width: 4 * s,
                  height: 12 * s,
                  child: const ColoredBox(color: Color(0xFF4A3018)),
                ),
              Positioned(
                right: 0,
                top: 36 * s,
                width: 54 * s,
                height: 12 * s,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(5 * s)),
                    gradient: cssLinear(180, const [Color(0xFF8A6238), Color(0xFF5E4024)]),
                    boxShadow: [
                      BoxShadow(
                        color: rgba(3, 16, 24, .8),
                        offset: Offset(0, 6 * s),
                        blurRadius: onbBlur(10 * s),
                        spreadRadius: -6 * s,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8 * s,
                top: 0,
                width: 38 * s,
                height: 38 * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38 * s,
                      height: 38 * s,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * s),
                        boxShadow: [
                          BoxShadow(color: rgba(255, 255, 255, .8), spreadRadius: 2 * s),
                          BoxShadow(
                            color: rgba(3, 16, 24, .9),
                            offset: Offset(0, 8 * s),
                            blurRadius: onbBlur(14 * s),
                            spreadRadius: -8 * s,
                          ),
                        ],
                      ),
                      child: storeLogoUrl != null && storeLogoUrl!.isNotEmpty
                          ? Image.network(
                              storeLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _Initial(storeName),
                            )
                          : _Initial(storeName),
                    ),
                    // Two `damp` bubbles (the effective keyframe fades only).
                    for (final (l, t, d, delay) in [(11.0, -7.0, 8.0, 0.0), (20.0, -5.0, 6.0, 900.0)])
                      Positioned(
                        left: l * s,
                        top: t * s,
                        width: d * s,
                        height: d * s,
                        child: BergenLoop(
                          durationMs: 2400,
                          delayMs: delay,
                          builder: (context, p, _) => Opacity(
                            opacity: p == null ? 0 : kf(Curves.easeOut.transform(p), const [0, .2, 1], const [0, .7, 0]),
                            child: DecoratedBox(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, d == 8 ? .7 : .6)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: -4 * s,
                top: 60 * s,
                width: 62 * s,
                child: Text(
                  KasseCopy.a1_kasse_bryggen,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: bText(context, 8, weight: FontWeight.w800, letterSpacingEm: .04, color: rgba(255, 255, 255, .8)),
                ),
              ),
            ],
          ),
        ),
        // The boat: `left:40;top:30`.
        Positioned(
          left: 40 * s,
          top: 30 * s,
          child: BergenOnce(
            key: ValueKey('a1_kasse_baat_${departing ? 'avgang' : 'inn'}'),
            durationMs: departing ? 750 : 1300,
            delayMs: departing ? 0 : 100,
            builder: (context, p, child) {
              double tx, sc, op;
              if (departing) {
                final q = const Cubic(.4, 0, .8, .4).transform(p);
                tx = 130 * q;
                sc = 1 - .14 * q;
                op = 1 - q;
              } else {
                final q = const Cubic(.3, .9, .3, 1).transform(p);
                tx = -120 * (1 - q);
                sc = 1;
                op = kf(q, const [0, .2, 1], const [0, 1, 1]);
              }
              return Opacity(
                opacity: op.clamp(0, 1),
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(tx * s)
                    ..scale(sc),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BergenLoop(
                  durationMs: 2200,
                  builder: (context, p, child) {
                    final q = p ?? 0;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, kf(q, const [0, .5, 1], const [0, -2, 0], Curves.easeInOut) * s)
                        ..rotateZ(kf(q, const [0, .5, 1], const [-1.5, 1.5, -1.5], Curves.easeInOut) * math.pi / 180),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 64 * s,
                    height: 44 * s,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 14 * s,
                          top: 2 * s,
                          width: 36 * s,
                          height: 36 * s,
                          child: Image.asset(BergenAssets.aegilFront, fit: BoxFit.contain),
                        ),
                        Positioned.fill(
                          child: BergenLoop(
                            durationMs: 2200,
                            builder: (context, p, _) => CustomPaint(painter: _BoatPainter(p ?? 0, s)),
                          ),
                        ),
                        Positioned(
                          left: -6 * s,
                          top: 38 * s,
                          width: 22 * s,
                          height: 4 * s,
                          child: BergenLoop(
                            durationMs: 2200,
                            builder: (context, p, _) {
                              final q = Curves.easeOut.transform(p ?? 0);
                              return Opacity(
                                opacity: .5 * (1 - q),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..translate(-22 * q * s)
                                    ..scale(.6 + .8 * q, 1.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, .55)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                              gradient: RadialGradient(colors: [rgba(255, 255, 255, .45), rgba(255, 255, 255, 0)], stops: const [0, .72]),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.name);

  final String? name;

  @override
  Widget build(BuildContext context) {
    final n = (name ?? '').trim();
    return Center(
      child: Text(
        n.isEmpty ? 'Æ' : n.substring(0, 1).toUpperCase(),
        style: bDisplay(context, 16, color: BergenTokens.teal),
      ),
    );
  }
}

typedef _Draw = void Function(Canvas c, Paint p);

class _StrokePainter extends CustomPainter {
  const _StrokePainter(this.width, this.draw);

  final double width;
  final _Draw draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    draw(
      canvas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokePainter old) => old.width != width;
}

/// The dashed course line.
class _CoursePainter extends CustomPainter {
  const _CoursePainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(s);
    final path = Path()
      ..moveTo(-20, 70)
      ..cubicTo(40, 56, 90, 82, 150, 66);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = rgba(255, 255, 255, .35);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(m.length, d + 5)), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_CoursePainter old) => old.s != s;
}

/// The rowing boat (64×44): two oars (`aareA` −28° → 22°, `aareB` 28° →
/// −22°, about (14,27) and (50,27)), the hull in three browns and the gold
/// gunwale line.
class _BoatPainter extends CustomPainter {
  const _BoatPainter(this.p, this.s);

  final double p;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(s);
    final a = kf(p, const [0, .5, 1], const [-28, 22, -28], Curves.easeInOut) * math.pi / 180;
    final b = kf(p, const [0, .5, 1], const [28, -22, 28], Curves.easeInOut) * math.pi / 180;
    final oar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A5A2B);
    final blade = Paint()..color = const Color(0xFFB07A3C);
    void oarAt(double px, double py, double ex, double ey, double angle, double bladeRot) {
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);
      canvas.translate(-px, -py);
      canvas.drawLine(Offset(px, py), Offset(ex, ey), oar);
      canvas.save();
      canvas.translate(ex - .5, ey + .5);
      canvas.rotate(bladeRot);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6, height: 3.2), blade);
      canvas.restore();
      canvas.restore();
    }

    oarAt(14, 27, 3, 40, a, -50 * math.pi / 180);
    oarAt(50, 27, 61, 40, b, 50 * math.pi / 180);
    canvas.drawPath(
      Path()
        ..moveTo(6, 24)
        ..cubicTo(10, 36, 54, 36, 58, 24)
        ..lineTo(62, 22)
        ..cubicTo(60, 30, 52, 40, 32, 40)
        ..cubicTo(12, 40, 4, 30, 2, 22)
        ..close(),
      Paint()..color = const Color(0xFF6B4A2A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 22)
        ..cubicTo(14, 33, 50, 33, 60, 22)
        ..lineTo(62, 22)
        ..cubicTo(56, 34, 46, 38, 32, 38)
        ..cubicTo(18, 38, 8, 34, 2, 22)
        ..close(),
      Paint()..color = const Color(0xFF8C6338),
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 24)
        ..cubicTo(14, 30, 50, 30, 58, 24)
        ..lineTo(61, 22)
        ..cubicTo(54, 30, 10, 30, 3, 22)
        ..close(),
      Paint()..color = const Color(0xFFA5763D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 23)
        ..cubicTo(14, 29, 50, 29, 60, 23),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF2C14E),
    );
  }

  @override
  bool shouldRepaint(_BoatPainter old) => old.p != p || old.s != s;
}
