import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_scene_kai.dart';

/// **Henting · disken** (L6694): the store's counter, built from the
/// prototype's CSS scene: the warm brick wall under the sign, two lamps with
/// their cones and dust, Ægil behind the counter (`aegStaa`), the red
/// counter with the logo, the paper bag dropping in (`hkPoseInn`) and
/// breathing (`posePust`) with its label swaying (`hkLapp`) and steam
/// (`royk`), the bell ringing (`hkKlokke`, `hkRing`, «ding!») and the KLAR
/// stamp. The whole room drifts (`hkKamera 14s`). 390 × 450; the box is
/// left 14 → right 14, top 10, 330 tall, radius 28.
class SpSceneDisk extends StatelessWidget {
  const SpSceneDisk({super.key, required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) => SpSceneInn(
    child: SizedBox(
      width: 390,
      height: 450,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            top: 10,
            width: 362,
            height: 330,
            child: CssBox(
              radius: BorderRadius.circular(28),
              clip: true,
              bg: const [CssSolid(Color(0xFF1A2E34))],
              shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .3)), CssShadow(0, 0, 0, 1, rgba(255, 255, 255, .1)), CssShadow(0, 26, 44, -22, rgba(3, 14, 20, .8))],
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: LfLoop(
                      builder: (context, t, child) {
                        final p = (t / 14000) % 1.0;
                        final k = kf(p, const [0, .5, 1], const [1, 1.025, 1], cssEaseInOut);
                        final y = kf(p, const [0, .5, 1], const [0, -2, 0], cssEaseInOut);
                        return Transform(alignment: const Alignment(0, .4), transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(k, k, 1, 1), child: child);
                      },
                      child: RepaintBoundary(child: _Rom(info: info)),
                    ),
                  ),
                  // KLAR (right 14, top 56), `stempel .7s .5s`.
                  Positioned(
                    right: 14,
                    top: 56,
                    child: SpStempel(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: rgba(250, 246, 238, .9),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFF3F8F5F), width: 2.5),
                        ),
                        child: Text(SporingCopy.a1_sporing_klar_stempel, style: jakarta(13, em: .06, color: const Color(0xFF3F8F5F))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ægil's bubble (left 12, top 14), `bobleFraAegil .55s 1s`.
          Positioned(
            left: 12,
            top: 14,
            child: SpBobleFraAegil(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 124),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: rgba(255, 255, 255, .94),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(color: rgba(160, 130, 90, .5), offset: const Offset(0, 2)),
                    BoxShadow(color: rgba(40, 20, 4, .7), offset: const Offset(0, 12), blurRadius: 22, spreadRadius: -12),
                  ],
                ),
                child: Text(
                  SporingCopy.a1_sporing_i_disken_si(info.kunde),
                  style: inter(11.5, weight: FontWeight.w700, height: 1.35, color: kSpInk),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Rom extends StatelessWidget {
  const _Rom({required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      // The wall (216 tall): the warm gradient, the bricks, the vignette.
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 216,
        child: CssBox(
          bg: [
            const CssLinear(180, [Color(0xFFE9DCC6), Color(0xFFDCCBAE), Color(0xFFC9B48F)], [0, .6, 1]),
            CssRadial([rgba(255, 196, 120, .28), rgba(255, 196, 120, 0)], stops: const [0, .7], rx: .7, ry: .6, cx: .5, cy: .3),
          ],
        ),
      ),
      const Positioned(left: 0, right: 0, top: 0, height: 216, child: CustomPaint(painter: _MurPainter())),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 216,
        child: IgnorePointer(
          child: CssBox(
            bg: [
              CssRadial([rgba(0, 0, 0, 0), rgba(40, 24, 8, .45)], stops: const [.4, 1], rx: 1.2, ry: .9, cx: .5, cy: 0),
            ],
          ),
        ),
      ),
      // The red band.
      Positioned(
        left: 0,
        right: 0,
        top: 150,
        height: 66,
        child: Opacity(
          opacity: .92,
          child: CssBox(
            bg: const [
              CssLinear(180, [Color(0xFFB8321A), Color(0xFF8E2410)]),
            ],
            shadows: [CssShadow.inset(0, 2, 0, 0, rgba(255, 180, 150, .35))],
          ),
        ),
      ),
      const Positioned(left: 0, right: 0, top: 150, height: 66, child: CustomPaint(painter: _StriperPainter(22, 2, Color(0x24000000)))),
      // The sign's glow and the sign.
      Positioned(
        left: 181 - 75,
        top: 14,
        child: LfLoop(
          builder: (context, t, child) {
            final p = (t / 3600) % 1.0;
            final o = kf(p, const [0, .5, 1], const [.75, 1, .75], cssEaseInOut);
            final k = kf(p, const [0, .5, 1], const [1, 1.06, 1], cssEaseInOut);
            return Opacity(
              opacity: o,
              child: Transform.scale(scale: k, child: child),
            );
          },
          child: SizedBox(
            width: 150,
            height: 150,
            child: CssBox(
              radius: BorderRadius.circular(75),
              bg: [
                CssRadial.closestSide([rgba(255, 170, 90, .55), rgba(255, 140, 60, 0)], stops: const [0, .7]),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 181 - 44,
        top: 22,
        child: CssBox(
          width: 88,
          height: 88,
          radius: BorderRadius.circular(44),
          clip: true,
          bg: const [
            CssLinear(160, [Color(0xFFFFFFFF), Color(0xFFE9E2D6)]),
          ],
          shadows: [
            const CssShadow.inset(0, 2, 0, 0, Color(0xFFFFFFFF)),
            CssShadow.inset(0, -4, 6, 0, rgba(80, 50, 20, .25)),
            const CssShadow(0, 0, 0, 4, Color(0xFF2A2420)),
            CssShadow(0, 0, 0, 5, rgba(255, 214, 150, .6)),
            CssShadow(0, 14, 22, -10, rgba(40, 20, 4, .8)),
            CssShadow(0, 0, 30, 6, rgba(255, 170, 90, .45)),
          ],
          child: Stack(
            children: [
              Center(
                child: SpLogo(size: 78, url: info.logo, name: info.butikk, bg: Colors.transparent),
              ),
              const SpSveip(dur: 6000, delay: 1400, alpha: .55, deg: 100),
            ],
          ),
        ),
      ),
      // Lamps.
      const _Lampe(x: 40, delay: 0),
      const _Lampe(x: 274, delay: 1300),
      // Dust motes.
      for (final (x, y, d) in const [(58.0, 70.0, 0.0), (76.0, 120.0, 1400.0), (64.0, 160.0, 2600.0), (286.0, 80.0, 700.0), (300.0, 130.0, 2000.0), (278.0, 170.0, 3100.0)])
        Positioned(
          left: x,
          top: y,
          child: LfLoop(
            builder: (context, t, child) {
              final e = t - d;
              final p = e < 0 ? 0.0 : cssEaseInOut.transform((e / 5500) % 1.0);
              final o = kf(p, const [0, .2, .8, 1], const [0, 1, 1, 0]);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(10 * p, -28 * p), child: child),
              );
            },
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rgba(255, 236, 196, .9),
                boxShadow: [BoxShadow(color: rgba(255, 214, 140, .9), blurRadius: 4)],
              ),
            ),
          ),
        ),
      // Ægil (left 22, top 92, 124 wide), `aegStaa 3.2s`.
      Positioned(
        left: 22,
        top: 92,
        child: LfLoop(
          builder: (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3200), child: child),
          child: aegil('popup', w: 124, h: 124),
        ),
      ),
      // The counter top (perspective slab), the steel edge, the front.
      const Positioned(left: -10, right: -10, top: 204, height: 40, child: CustomPaint(painter: _BenkTopPainter())),
      Positioned(
        left: 0,
        right: 0,
        top: 222,
        height: 3,
        child: CssBox(
          bg: const [
            CssLinear(90, [Color(0xFF9AA7B0), Color(0xFFF2F6F8), Color(0xFFBFC9CF), Color(0xFFF2F6F8), Color(0xFF8A97A2)], [0, .3, .6, .8, 1]),
          ],
          shadows: [CssShadow(0, 2, 3, 0, rgba(0, 0, 0, .5))],
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 225,
        bottom: 0,
        child: CssBox(
          bg: const [
            CssLinear(180, [Color(0xFFD6411B), Color(0xFFB7341A), Color(0xFF8E2410)], [0, .4, 1]),
          ],
          shadows: [CssShadow.inset(0, 10, 14, -8, rgba(0, 0, 0, .5))],
        ),
      ),
      const Positioned(left: 0, right: 0, top: 225, bottom: 0, child: CustomPaint(painter: _PanelPainter())),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 14,
        child: CssBox(
          bg: const [
            CssLinear(180, [Color(0xFF5A6670), Color(0xFF2A3238)]),
          ],
          shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .4))],
        ),
      ),
      // The logo on the front (58).
      Positioned(
        left: 181 - 29,
        top: 240,
        child: CssBox(
          width: 58,
          height: 58,
          radius: BorderRadius.circular(29),
          bg: const [
            CssLinear(160, [Color(0xFFFFFFFF), Color(0xFFE2DACB)]),
          ],
          shadows: [
            const CssShadow.inset(0, 2, 0, 0, Color(0xFFFFFFFF)),
            CssShadow.inset(0, -3, 5, 0, rgba(80, 50, 20, .3)),
            const CssShadow(0, 0, 0, 3, Color(0xFFF2C14E)),
            CssShadow(0, 0, 0, 4, rgba(90, 40, 4, .5)),
            CssShadow(0, 10, 14, -6, rgba(40, 10, 2, .8)),
          ],
          child: Center(
            child: SpLogo(size: 50, url: info.logo, name: info.butikk, bg: Colors.transparent),
          ),
        ),
      ),
      // The bag (left 206, top 104, 92 × 118).
      Positioned(left: 206, top: 104, child: _Pose(info: info)),
      // The bell (left 312, top 196) and «ding!».
      const Positioned(left: 312, top: 196, child: _Klokke()),
      Positioned(
        left: 300,
        top: 168,
        child: LfLoop(
          builder: (context, t, child) {
            final p = cssEaseOut.transform((t / 3200) % 1.0);
            const st = [0.0, .02, .06, .24, 1.0];
            final o = kf(p, st, const [0, 0, 1, 0, 0]);
            final x = kf(p, st, const [0, 0, 0, 4, 4]);
            final y = kf(p, st, const [6, 6, 0, -10, -10]);
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(x, y), child: child),
            );
          },
          child: Text('ding!', style: jakarta(10, color: const Color(0xFFFFE7A8))),
        ),
      ),
    ],
  );
}

/// Brick joints: rows every 15 px, columns every 30 px, 55 %.
class _MurPainter extends CustomPainter {
  const _MurPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = Paint()
      ..color = rgba(120, 90, 50, .28 * .55)
      ..strokeWidth = 1;
    final v = Paint()
      ..color = rgba(120, 90, 50, .22 * .55)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y + .5), Offset(size.width, y + .5), h);
    }
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x + .5, 0), Offset(x + .5, size.height), v);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// `repeating-linear-gradient(90deg, transparent 0 a, c a a+b)`.
class _StriperPainter extends CustomPainter {
  const _StriperPainter(this.a, this.b, this.c);

  final double a, b;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = c;
    for (var x = a; x < size.width; x += a + b) {
      canvas.drawRect(Rect.fromLTWH(x, 0, b, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The counter front's panels: 2 px light, 14 px plain, 2 px dark.
class _PanelPainter extends CustomPainter {
  const _PanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), Paint()..color = rgba(255, 255, 255, .07));
      canvas.drawRect(Rect.fromLTWH(x + 16, 0, 2, size.height), Paint()..color = rgba(0, 0, 0, .16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The counter top: a 60 px slab turned 58° from its top edge, with the
/// two lamp pools.
class _BenkTopPainter extends CustomPainter {
  const _BenkTopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final p = Path()
      ..moveTo(w * .08, 0)
      ..lineTo(w * .92, 0)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    final r = Offset.zero & size;
    canvas.drawPath(p, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4440), Color(0xFF2C2724)]).createShader(r));
    canvas.save();
    canvas.clipPath(p);
    for (final cx in [.22, .82]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * cx, size.height * .3), width: w * .3, height: size.height * 1.6),
        Paint()
          ..shader = RadialGradient(
            colors: [rgba(255, 214, 150, .4), rgba(255, 214, 150, 0)],
            stops: const [0, .7],
          ).createShader(Rect.fromCenter(center: Offset(w * cx, size.height * .3), width: w * .3, height: size.height * 1.6)),
      );
    }
    canvas.drawLine(
      Offset(w * .08, 1),
      Offset(w * .92, 1),
      Paint()
        ..color = rgba(255, 255, 255, .35)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A ceiling lamp: the cord, the dark shade, the bulb (`hkLampe`), the
/// swaying cone (`hkKjegle`) and its pool on the counter.
class _Lampe extends StatelessWidget {
  const _Lampe({required this.x, required this.delay});

  final double x, delay;

  @override
  Widget build(BuildContext context) => Positioned(
    left: x - 46,
    top: -10,
    child: SizedBox(
      width: 140,
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 69, top: 0, child: Container(width: 2, height: 26, color: const Color(0xFF2A2420))),
          Positioned(
            left: 46,
            top: 24,
            child: CssBox(
              width: 48,
              height: 20,
              radius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(4)),
              bg: const [
                CssLinear(180, [Color(0xFF3B3530), Color(0xFF1E1A17)]),
              ],
              shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .18)), CssShadow(0, 6, 10, -4, rgba(0, 0, 0, .6))],
            ),
          ),
          Positioned(
            left: 52,
            top: 41,
            child: LfLoop(
              builder: (context, t, child) {
                final e = t - delay;
                final p = e < 0 ? 0.0 : (e / 4000) % 1.0;
                return Opacity(opacity: kf(p, const [0, .5, 1], const [.9, 1, .9], cssEaseInOut), child: child);
              },
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFFFE6B0),
                  boxShadow: [BoxShadow(color: rgba(255, 206, 130, .75), blurRadius: 14, spreadRadius: 6)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 43,
            child: IgnorePointer(
              child: LfLoop(
                builder: (context, t, child) {
                  final e = t - delay;
                  final p = e < 0 ? 0.0 : (e / 7000) % 1.0;
                  final r = kf(p, const [0, .5, 1], const [-1.2, 1.2, -1.2], cssEaseInOut);
                  return Transform.rotate(angle: rad(r), alignment: Alignment.topCenter, child: child);
                },
                child: ClipPath(
                  clipper: const _Trapes(.38, .62),
                  child: CssBox(
                    width: 140,
                    height: 186,
                    bg: [
                      CssLinear(180, [rgba(255, 214, 150, .34), rgba(255, 214, 150, 0)], const [0, .92]),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 208,
            child: IgnorePointer(
              child: SizedBox(
                width: 120,
                height: 26,
                child: CssBox(
                  radius: BorderRadius.circular(60),
                  bg: [
                    CssRadial.closestSide([rgba(255, 214, 150, .5), rgba(255, 214, 150, 0)]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Trapes extends CustomClipper<Path> {
  const _Trapes(this.a, this.b);

  final double a, b;

  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * a, 0)
    ..lineTo(s.width * b, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant _Trapes old) => old.a != a || old.b != b;
}

/// The paper bag dropping onto the counter and breathing, with its label and
/// a little steam.
class _Pose extends StatelessWidget {
  const _Pose({required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 1200,
    builder: (context, t, child) {
      final p = cssStempel.transform(kfP(t, 400, 800));
      const st = [0.0, .55, .75, 1.0];
      final y = kf(p, st, const [-60, 4, -3, 0]);
      final sx = kf(p, st, const [.85, 1.06, .98, 1]);
      final sy = kf(p, st, const [.85, .92, 1.03, 1]);
      final o = kf(p, const [0, .55, 1], const [0, 1, 1]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(sx, sy, 1, 1), child: child),
      );
    },
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - 1200;
        final p = e < 0 ? 0.0 : (e / 3600) % 1.0;
        final y = kf(p, const [0, .5, 1], const [0, -4, 0], cssEaseInOut);
        final r = kf(p, const [0, .5, 1], const [-1, 1, -1], cssEaseInOut);
        return Transform(alignment: Alignment.bottomCenter, transform: Matrix4.translationValues(0, y, 0)..rotateZ(rad(r)), child: child);
      },
      child: SizedBox(
        width: 92,
        height: 118,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              bottom: -5,
              child: SizedBox(
                width: 80,
                height: 10,
                child: CssBox(
                  radius: BorderRadius.circular(40),
                  bg: [
                    CssRadial.closestSide([rgba(10, 4, 0, .6), rgba(10, 4, 0, 0)]),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: CssBox(
                width: 92,
                height: 98,
                radius: const BorderRadius.vertical(top: Radius.circular(3), bottom: Radius.circular(6)),
                clip: true,
                bg: const [
                  CssLinear(100, [Color(0xFFB98A55), Color(0xFFD9AE76), Color(0xFFC7965A), Color(0xFFA57440)], [0, .3, .7, 1]),
                ],
                shadows: [CssShadow.inset(0, 2, 0, 0, rgba(255, 236, 200, .5)), CssShadow.inset(-8, 0, 12, -8, rgba(60, 30, 6, .55)), CssShadow(0, 12, 18, -10, rgba(20, 8, 0, .7))],
                child: Stack(
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: _StriperPainter(11, 1, Color(0x1AFFFFFF)))),
                    Positioned.fill(
                      child: CssBox(
                        bg: [
                          CssLinear(180, [rgba(0, 0, 0, 0), rgba(60, 30, 6, .25)], const [.6, 1]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: ClipPath(
                clipper: const _Sikksakk(),
                child: CssBox(
                  width: 92,
                  height: 24,
                  bg: const [
                    CssLinear(180, [Color(0xFFC7965A), Color(0xFFA87842)]),
                  ],
                  shadows: [CssShadow.inset(0, -2, 0, 0, rgba(60, 30, 6, .3))],
                ),
              ),
            ),
            Positioned(
              left: 21,
              top: 44,
              child: Transform.rotate(
                angle: rad(-6),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 2),
                      BoxShadow(color: rgba(40, 20, 4, .6), offset: const Offset(0, 4), blurRadius: 6, spreadRadius: -3),
                    ],
                  ),
                  child: Center(
                    child: SpLogo(size: 44, url: info.logo, name: info.butikk, bg: Colors.transparent),
                  ),
                ),
              ),
            ),
            Positioned(left: 52, top: 8, child: _Lapp(info: info)),
            const Positioned(left: 16, top: -40, child: _Royk()),
          ],
        ),
      ),
    ),
  );
}

/// The bag's zigzag top edge.
class _Sikksakk extends CustomClipper<Path> {
  const _Sikksakk();

  @override
  Path getClip(Size s) {
    final p = Path()..moveTo(0, s.height * .3);
    for (var i = 0; i < 12; i++) {
      p.lineTo(s.width * (.08 + i * .08), 0);
      p.lineTo(s.width * (.16 + i * .08), s.height * .3);
    }
    p
      ..lineTo(s.width, s.height * .1)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

/// The stapled label on the bag (`hkLapp 3.4s`).
class _Lapp extends StatelessWidget {
  const _Lapp({required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, child) {
      final p = (t / 3400) % 1.0;
      final r = kf(p, const [0, .5, 1], const [7, 3, 7], cssEaseInOut);
      return Transform.rotate(angle: rad(r), alignment: Alignment.topCenter, child: child);
    },
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 50,
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F1),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: rgba(40, 20, 4, .6), offset: const Offset(0, 5), blurRadius: 8, spreadRadius: -4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.butikk.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: inter(5, weight: FontWeight.w800, em: .04, height: 1.1, color: kSpInk),
              ),
              const SizedBox(height: 3),
              Text(
                '${info.kunde}\n${SporingCopy.a1_sporing_henting_ord[0].toUpperCase()}${SporingCopy.a1_sporing_henting_ord.substring(1)} ${info.klokke}',
                style: inter(4.5, weight: FontWeight.w600, height: 1.45, color: const Color(0xFF57534B)),
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 3), color: rgba(35, 32, 29, .2)),
              Text(
                info.total,
                style: inter(5, weight: FontWeight.w800, height: 1.1, color: kSpInk),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: -3,
          child: Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8EEF1), Color(0xFF8A97A2)]),
            ),
          ),
        ),
      ],
    ),
  );
}

/// `royk 3s` — three puffs rising from the bag.
class _Royk extends StatelessWidget {
  const _Royk();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 44,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (cx, cy, r, a, d) in const [(18.0, 30.0, 7.0, .55, 0.0), (34.0, 32.0, 6.0, .45, 1000.0), (26.0, 34.0, 5.0, .4, 2000.0)])
          Positioned(
            left: cx - r,
            top: cy - r,
            child: LfLoop(
              builder: (context, t, child) {
                final e = t - d;
                final p = e < 0 ? 0.0 : cssEaseOut.transform((e / 3000) % 1.0);
                final o = kf(p, const [0, .2, 1], [0, a, 0]);
                final k = .6 + 1.0 * p;
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(10 * p, -46 * p, 0)..scaleByDouble(k, k, 1, 1), child: child),
                );
              },
              child: Container(
                width: r * 2,
                height: r * 2,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The counter bell: two rings (`hkRing`), the base, the dome tapping
/// (`hkKlokke 3.2s`).
class _Klokke extends StatelessWidget {
  const _Klokke();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 26,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _ring(-14, -12, 62, 30, 1.5, .8, 100),
        _ring(-20, -16, 74, 36, 1, .55, 250),
        Positioned(
          left: 2,
          bottom: 0,
          child: CssBox(
            width: 30,
            height: 6,
            radius: BorderRadius.circular(3),
            bg: const [
              CssLinear(180, [Color(0xFF3A3A40), Color(0xFF1A1A1E)]),
            ],
            shadows: [CssShadow(0, 3, 4, 0, rgba(0, 0, 0, .6))],
          ),
        ),
        Positioned(
          left: 4,
          bottom: 5,
          child: LfLoop(
            builder: (context, t, child) {
              final p = cssEaseInOut.transform((t / 3200) % 1.0);
              const st = [0.0, .03, .06, .08, .1, 1.0];
              final y = kf(p, st, const [0, 2, -1, 0, 0, 0]);
              final sx = kf(p, st, const [1, 1.08, 1, 1, 1, 1]);
              final sy = kf(p, st, const [1, .88, 1, 1, 1, 1]);
              final r = kf(p, st, const [0, 0, -6, 4, 0, 0]);
              return Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.translationValues(0, y, 0)
                  ..rotateZ(rad(r))
                  ..scaleByDouble(sx, sy, 1, 1),
                child: child,
              );
            },
            child: SizedBox(
              width: 26,
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 11,
                    top: -4,
                    child: Container(
                      width: 4,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(colors: [Color(0xFF8A97A2), Color(0xFFF2F6F8), Color(0xFF6E7B85)]),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CssBox(
                      radius: const BorderRadius.vertical(top: Radius.circular(13), bottom: Radius.circular(2)),
                      bg: const [
                        CssRadial([Color(0xFFFFFFFF), Color(0xFFD7DEE2), Color(0xFF8E9AA3), Color(0xFF5E6A72)], stops: [0, .4, .8, 1], rx: .6, ry: .7, cx: .35, cy: .25),
                      ],
                      shadows: [CssShadow.inset(0, -2, 2, 0, rgba(0, 0, 0, .25))],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static Widget _ring(double x, double y, double w, double h, double bw, double a, double delay) => Positioned(
    left: x,
    top: y,
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : cssEaseOut.transform((e / 3200) % 1.0);
        const st = [0.0, .02, .04, .3, 1.0];
        final k = kf(p, st, const [.4, .4, .6, 1.4, 1.4]);
        final o = kf(p, st, const [0, 0, .9, 0, 0]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.scale(scale: k, child: child),
        );
      },
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
          border: Border.all(color: rgba(255, 236, 190, a), width: bw),
        ),
      ),
    ),
  );
}
