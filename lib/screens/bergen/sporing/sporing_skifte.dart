import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/auth/launch/launch_onboarding.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';

/// **Sporing · stadieskifte** (L6446): the teal iris opening from the
/// centre (`skifteIris 2.1s`), the slow rays, the glow and two rings, six
/// sparks, the 3D Æ mark landing (`skifteLogoInn`) and swinging
/// (`skifteLogoSving`) with a glint, «STEG n AV 4», the stage name, four
/// segments (the current one filling) and Ægil's line. Plays once for 2.1 s
/// and fades out by itself. 390 × 844.
class SpSkifte extends StatelessWidget {
  const SpSkifte({super.key, required this.steg, required this.navn, required this.linje});

  /// 0–3.
  final int steg;
  final String navn;
  final String linje;

  static const double dur = 2100;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LfOnce(
      ms: dur,
      builder: (context, t, child) {
        final p = const Cubic(.6, .05, .3, 1).transform(kfP(t, 0, dur));
        final r = kf(p, const [0, .22, 1], const [0, 760, 760]);
        final o = kf(p, const [0, .8, 1], const [1, 1, 0]);
        final u = cssEaseIn.transform(kfP(t, 0, dur));
        final uy = kf(u, const [0, .8, 1], const [0, 0, -22]);
        final uk = kf(u, const [0, .8, 1], const [1, 1, .96]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: ClipPath(
            clipper: _Iris(r),
            child: CssBox(
              bg: const [
                CssRadial([Color(0xFF1F5864), Color(0xFF133844), Color(0xFF0A1E28)], stops: [0, .52, 1], rx: .9, ry: .6, cx: .5, cy: .36),
              ],
              child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, uy, 0)..scaleByDouble(uk, uk, 1, 1), child: child),
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rays (520 circle at 195,300).
          Positioned(left: 195 - 260, top: 300 - 260, child: const _Straaler()),
          // Glow (360).
          Positioned(
            left: 195 - 180,
            top: 300 - 180,
            child: LfOnce(
              ms: 1000,
              builder: (context, t, child) {
                final p = cssEaseOut.transform(kfP(t, 300, 700));
                return Opacity(
                  opacity: p,
                  child: Transform.scale(scale: .6 + .4 * p, child: child),
                );
              },
              child: SizedBox(
                width: 360,
                height: 360,
                child: CssBox(
                  radius: BorderRadius.circular(180),
                  bg: [
                    CssRadial.closestSide([rgba(92, 224, 184, .38), rgba(92, 224, 184, .12), rgba(92, 224, 184, 0)], stops: const [0, .45, 1]),
                  ],
                ),
              ),
            ),
          ),
          // Two rings (200).
          Positioned(left: 95, top: 200, child: _Ring(delay: 560, dur: 900, color: rgba(255, 255, 255, .75), width: 2)),
          Positioned(left: 95, top: 200, child: _Ring(delay: 680, dur: 1000, color: rgba(92, 224, 184, .7), width: 1.5)),
          // Sparks.
          const _Gnist(size: 7, color: Color(0xFFFFFFFF), dx: -90, dy: -64, delay: 580),
          const _Gnist(size: 6, color: Color(0xFFF26D3D), dx: 96, dy: -52, delay: 600),
          const _Gnist(size: 5, color: Color(0xFF5CE0B8), dx: -78, dy: 74, delay: 620),
          const _Gnist(size: 6, color: Color(0xFFF2C14E), dx: 92, dy: 68, delay: 640),
          const _Gnist(size: 5, color: Color(0xFFFFFFFF), dx: 6, dy: -112, delay: 580),
          const _Gnist(size: 5, color: Color(0xFF5CE0B8), dx: -8, dy: 108, delay: 610),
          // The shadow under the mark (top 370, 150 × 22).
          Positioned(
            left: 195 - 75,
            top: 370,
            child: LfOnce(
              ms: 970,
              builder: (context, t, child) {
                final p = cssEaseOut.transform(kfP(t, 120, 850));
                final sx = kf(p, const [0, .5, 1], const [1, .82, 1]);
                final o = kf(p, const [0, .5, 1], const [.6, .4, .6]);
                return Opacity(
                  opacity: o,
                  child: Transform.scale(scaleX: sx, child: child),
                );
              },
              child: SizedBox(
                width: 150,
                height: 22,
                child: CssBox(
                  radius: BorderRadius.circular(75),
                  bg: [
                    CssRadial.closestSide([rgba(2, 10, 16, .75), rgba(2, 10, 16, 0)]),
                  ],
                ),
              ),
            ),
          ),
          // The 3D mark (140 × 112 at top 244).
          Positioned(left: 195 - 70, top: 244, child: const _Logo3d()),
          // Texts (top 390).
          Positioned(
            left: 0,
            right: 0,
            top: 390,
            child: Column(
              children: [
                LfRise(
                  delay: 550,
                  dur: 400,
                  child: Text(
                    SporingCopy.a1_sporing_steg_av(steg + 1, 4).toUpperCase(),
                    style: inter(10, weight: FontWeight.w800, em: .16, color: kSpMintLight),
                  ),
                ),
                const SizedBox(height: 8),
                LfRise(
                  delay: 620,
                  dur: 500,
                  curve: cssOppStor,
                  child: Text(navn, style: jakarta(38, em: -.035, height: 1, shadows: spTekstSkygge())),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var k = 0; k < 4; k++) ...[if (k > 0) const SizedBox(width: 6), _Segment(fylt: k < steg, naa: k == steg)],
                  ],
                ),
                const SizedBox(height: 16),
                LfRise(
                  delay: 920,
                  dur: 400,
                  child: SizedBox(
                    width: 260,
                    child: LfPretty(
                      linje,
                      align: TextAlign.center,
                      style: inter(12.5, weight: FontWeight.w700, height: 1.4, color: kSpSub),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Iris extends CustomClipper<Path> {
  const _Iris(this.r);

  final double r;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: Offset(size.width / 2, 300), radius: r));

  @override
  bool shouldReclip(covariant _Iris old) => old.r != r;
}

/// `skifteStraaler 2.1s linear` — a repeating conic of 7° rays in 22°,
/// faded out from 18 % of the radius.
class _Straaler extends StatelessWidget {
  const _Straaler();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 2100,
    builder: (context, t, _) {
      final p = kfP(t, 0, 2100);
      final o = kf(p, const [0, .28, 1], const [0, 1, .7]);
      final r = kf(p, const [0, .28, 1], const [0, 18, 54]);
      final k = kf(p, const [0, .28, 1], const [.5, 1, 1.06]);
      return Opacity(
        opacity: o,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationZ(rad(r))..scaleByDouble(k, k, 1, 1),
          child: const CustomPaint(size: Size(520, 520), painter: _StraalePainter()),
        ),
      );
    },
  );
}

class _StraalePainter extends CustomPainter {
  const _StraalePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.saveLayer(Offset.zero & size, Paint());
    final p = Paint()..color = rgba(127, 240, 203, .13);
    for (var a = 0.0; a < 360; a += 22) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..arcTo(Rect.fromCircle(center: c, radius: r), rad(a - 90), rad(7), false)
          ..close(),
        p,
      );
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = RadialGradient(colors: const [Colors.black, Colors.black, Colors.transparent], stops: const [0, .18, 1]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// `spRing` — scale .35→1.7, opacity 0→.8→0.
class _Ring extends StatelessWidget {
  const _Ring({required this.delay, required this.dur, required this.color, required this.width});

  final double delay, dur, width;
  final Color color;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: delay + dur,
    builder: (context, t, child) {
      final p = cssEaseOut.transform(kfP(t, delay, dur));
      final k = kf(p, const [0, 1], const [.35, 1.7]);
      final o = kf(p, const [0, .12, 1], const [0, .8, 0]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(scale: k, child: child),
      );
    },
    child: Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    ),
  );
}

/// `skifteGnist .85s` — a spark flying out from the centre.
class _Gnist extends StatelessWidget {
  const _Gnist({required this.size, required this.color, required this.dx, required this.dy, required this.delay});

  final double size, dx, dy, delay;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 195 - size / 2,
    top: 300 - size / 2,
    child: LfOnce(
      ms: delay + 850,
      builder: (context, t, child) {
        final p = cssEaseOut.transform(kfP(t, delay, 850));
        final o = kf(p, const [0, .1, 1], const [0, 1, 0]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(dx * p, dy * p, 0)..scaleByDouble(1 - p, 1 - p, 1, 1), child: child),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}

/// The Æ mark landing in 3D (`skifteLogoInn .85s .12s`) then swinging
/// (`skifteLogoSving 2.8s .97s`): eleven darkened slices stacked behind the
/// face give it depth, and a glint sweeps across at .74 s.
class _Logo3d extends StatelessWidget {
  const _Logo3d();

  static const double _w = 140, _h = 112;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, _) {
      final i = const Cubic(.22, .9, .3, 1).transform(kfP(t, 120, 850));
      const st = [0.0, .3, .62, .82, 1.0];
      final ty = kf(i, st, const [46, 46 * .55, -8, 2, 0]);
      final tz = kf(i, st, const [-280, -280 * .55, 24, 0, 0]);
      final ry = kf(i, st, const [-140, -140 * .55, 14, -5, 0]);
      final rx = kf(i, st, const [34, 34 * .55, -8, 3, 0]);
      final k = kf(i, st, const [.45, .45 + .63 * .55, 1.08, .98, 1]);
      final o = kf(i, const [0, .3, 1], const [0, 1, 1]);
      // skifteLogoSving from .97 s.
      final e = t - 970;
      final sp = e < 0 ? 0.0 : (e / 2800) % 1.0;
      final sy = e < 0 ? 0.0 : kf(sp, const [0, .25, .75, 1], const [0, -15, 15, 0], cssEaseInOut);
      final sx = e < 0 ? 7.0 : kf(sp, const [0, .25, .75, 1], const [7, 9, 5, 7], cssEaseInOut);
      final sty = e < 0 ? 0.0 : kf(sp, const [0, .25, .75, 1], const [0, -4, -4, 0], cssEaseInOut);
      final glans = cssEaseInOut.transform(kfP(t, 740, 900));
      final m = Matrix4.identity()
        ..setEntry(3, 2, -1 / 620)
        ..translateByDouble(0, ty + sty, tz, 1)
        ..rotateY(rad(ry + sy))
        ..rotateX(rad(rx + (i >= 1 ? sx : 0)))
        ..scaleByDouble(k, k, 1, 1);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: SizedBox(
          width: _w,
          height: _h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Five of the prototype's eleven slices: enough depth, and the
              // raster thread keeps up on the simulator.
              for (var n = 10; n >= 2; n -= 2)
                Transform(
                  alignment: Alignment.center,
                  transform: m.clone()..translateByDouble(0, 0, -1.3 * n, 1),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(rgba(0, 0, 0, (1 - (.34 + .032 * (10 - n))).clamp(0, 1)), BlendMode.srcATop),
                    child: const LfMerke(w: _w, h: _h),
                  ),
                ),
              Transform(
                alignment: Alignment.center,
                transform: m,
                child: Stack(
                  children: [
                    const LfMerke(w: _w, h: _h),
                    if (glans > 0 && glans < 1)
                      ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (r) => LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          transform: const GradientRotation(math.pi / 9),
                          colors: [rgba(255, 255, 255, 0), rgba(255, 255, 255, .75), rgba(255, 255, 255, 0)],
                          stops: [(1.5 - 2 * glans) - .1, 1.5 - 2 * glans, (1.5 - 2 * glans) + .1].map((v) => v.clamp(0.0, 1.0)).toList(),
                        ).createShader(r),
                        child: const LfMerke(w: _w, h: _h),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fylt, required this.naa});

  final bool fylt, naa;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 30,
    height: 5,
    radius: BorderRadius.circular(3),
    clip: true,
    bg: [CssSolid(rgba(255, 255, 255, .16))],
    shadows: [CssShadow.inset(0, 1, 1, 0, rgba(2, 10, 16, .4))],
    child: fylt || naa
        ? LfOnce(
            ms: 1400,
            builder: (context, t, child) {
              final p = naa ? const Cubic(.3, .9, .3, 1).transform(kfP(t, 800, 600)) : 1.0;
              return Transform(alignment: Alignment.centerLeft, transform: Matrix4.diagonal3Values(p, 1, 1), child: child);
            },
            child: const CssBox(
              radius: BorderRadius.all(Radius.circular(3)),
              bg: [
                CssLinear(90, [Color(0xFF7FF0CB), Color(0xFF3CC79F)]),
              ],
            ),
          )
        : null,
  );
}
