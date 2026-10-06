import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_scene_kai.dart';

/// **Sporing · Tilberedes** (L6609): the kitchen, built from the
/// prototype's CSS scene (the WebGL one does not render off-screen): tiled
/// walls in perspective, the plank floor, two hanging lamps with their
/// cones, the shelf with jars, the rack with pans, the order note swaying
/// (`lappSvai`), Ægil the cook behind the stove with the pan on a roaring
/// flame (`flamme`, `gnistFly`, `varmeglod`), the steaming pot (`damp`),
/// his bubble and the «På komfyren» pill. 390 × 460; the kitchen box is
/// left 14 → right 14, top 8 → bottom, radius 28 on top.
class SpSceneKjokken extends StatelessWidget {
  const SpSceneKjokken({super.key, required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) => SpSceneInn(
    child: SizedBox(
      width: 390,
      height: 460,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 8,
            width: 362,
            height: 452,
            child: CssBox(
              radius: const BorderRadius.vertical(top: Radius.circular(28)),
              clip: true,
              bg: const [CssSolid(Color(0xFF2A3236))],
              shadows: [CssShadow(0, 30, 50, -24, rgba(4, 18, 26, .9))],
              child: RepaintBoundary(child: _Kjokken(info: info)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Kjokken extends StatelessWidget {
  const _Kjokken({required this.info});

  final SpSceneInfo info;

  @override
  Widget build(BuildContext context) {
    final min = info.minIgjen;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Walls, tiles, floor.
        const Positioned.fill(child: CustomPaint(painter: _RomPainter())),
        // The warm light from above and the dark foot of the wall.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 290,
          child: IgnorePointer(
            child: CssBox(
              bg: [
                CssLinear(180, [rgba(0, 0, 0, 0), rgba(20, 30, 35, .35)], const [.4, 1]),
                CssRadial([rgba(255, 236, 190, .55), rgba(255, 236, 190, 0)], stops: const [0, .8], rx: .5, ry: .7, cx: .5, cy: 0),
              ],
            ),
          ),
        ),
        // Lamps.
        const _Lampe(x: 96),
        const _Lampe(x: 264),
        // Shelf and jars.
        Positioned(
          left: 14,
          top: 96,
          child: CssBox(
            width: 84,
            height: 8,
            bg: const [
              CssLinear(180, [Color(0xFF8A5B3A), Color(0xFF5E3B22)]),
            ],
            shadows: [CssShadow(0, 4, 6, 0, rgba(0, 0, 0, .35))],
          ),
        ),
        _krukke(20, 70, 16, 26, const [Color(0xFFD94B2B), Color(0xFFA8361C)], glans: true),
        _krukke(42, 76, 14, 20, const [Color(0xFFE8C27A), Color(0xFFB98D4A)]),
        _krukke(62, 66, 16, 30, const [Color(0xFF3B8A5C), Color(0xFF246641)], glans: true),
        _krukke(82, 80, 12, 16, const [Color(0xFFF2C14E), Color(0xFFC99A2C)]),
        // Rack: bar and three hooks.
        Positioned(
          right: 20,
          top: 92,
          child: Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFF5A6268), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Positioned(right: 34, top: 96, child: Container(width: 3, height: 40, color: const Color(0xFF8A9298))),
        Positioned(
          right: 26,
          top: 132,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-.2, -.3), colors: [Color(0xFFD8DEE2), Color(0xFF8A9298)]),
            ),
          ),
        ),
        Positioned(right: 72, top: 96, child: Container(width: 3, height: 36, color: const Color(0xFF8A9298))),
        Positioned(
          right: 66,
          top: 130,
          child: Container(
            width: 16,
            height: 22,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(
                left: BorderSide(color: Color(0xFF8A9298), width: 3),
                right: BorderSide(color: Color(0xFF8A9298), width: 3),
                bottom: BorderSide(color: Color(0xFF8A9298), width: 3),
              ),
            ),
          ),
        ),
        Positioned(right: 110, top: 96, child: Container(width: 3, height: 44, color: const Color(0xFF8A9298))),
        Positioned(
          right: 104,
          top: 138,
          child: Container(
            width: 14,
            height: 18,
            decoration: BoxDecoration(color: const Color(0xFF8A9298), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        // The order note (left 10, top 136, 70 wide), `lappSvai 5.5s`.
        Positioned(
          left: 10,
          top: 136,
          child: LfLoop(
            builder: (context, t, child) {
              final p = (t / 5500) % 1.0;
              final r = kf(p, const [0, .5, 1], const [-4, -2.6, -4], cssEaseInOut);
              return Transform(alignment: const Alignment(46 / 35 - 1, -1), transform: Matrix4.rotationZ(rad(r)), child: child);
            },
            child: Container(
              width: 70,
              padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFDFCF8), Color(0xFFF1EEE6)]),
                boxShadow: [
                  BoxShadow(color: rgba(0, 0, 0, .32), offset: const Offset(0, 6), blurRadius: 10),
                  BoxShadow(color: rgba(0, 0, 0, .25), offset: const Offset(0, 1), blurRadius: 2),
                ],
              ),
              child: DefaultTextStyle(
                style: inter(6.5, weight: FontWeight.w700, height: 1.55, color: kSpInk),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      [if (info.kode.isNotEmpty) info.kode, if (info.klokke.isNotEmpty) SporingCopy.a1_sporing_kl_stempel(info.klokke)].join(' · '),
                      style: inter(7, weight: FontWeight.w800, height: 1.55, color: kSpInk),
                    ),
                    for (final l in info.linjer.take(3)) Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        SporingCopy.a1_sporing_tilberedes_stempel,
                        style: inter(6.5, weight: FontWeight.w800, em: .04, height: 1.55, color: const Color(0xFF2E6B47)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // The pin.
        Positioned(
          left: 56,
          top: 126,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFF9A70), Color(0xFFF26D3D), Color(0xFFB8441A)], stops: [0, .55, 1]),
              boxShadow: [
                const BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 1.5),
                BoxShadow(color: rgba(0, 0, 0, .45), offset: const Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
        // Ægil's shadow and Ægil the cook (left 45, top 113, 210 × 137).
        Positioned(
          left: 40,
          top: 120,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: SizedBox(
              width: 220,
              height: 150,
              child: CssBox(
                radius: BorderRadius.circular(110),
                bg: [
                  CssRadial([rgba(20, 40, 50, .38), rgba(20, 40, 50, 0)], stops: const [0, .7], cx: .5, cy: .6),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 45,
          top: 113,
          width: 210,
          height: 137,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 0, top: 0, child: aegil('front', w: 210, h: 210)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 80,
                  height: 57,
                  child: IgnorePointer(
                    child: CssBox(
                      bg: [
                        CssLinear(180, [rgba(10, 20, 26, 0), rgba(10, 20, 26, .42)]),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 40,
                  width: 210,
                  height: 97,
                  child: _Glod(
                    dur: 700,
                    child: CssBox(
                      bg: [
                        CssRadial([rgba(255, 150, 60, .3), rgba(255, 150, 60, 0)], stops: const [0, .65], cx: .45, cy: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // The counter: back edge in perspective, top, front, oven window.
        const Positioned(left: 36, right: 36, top: 237, height: 13, child: CustomPaint(painter: _BenkKantPainter())),
        Positioned(
          left: 36,
          right: 36,
          top: 274,
          height: 20,
          child: CssBox(
            bg: const [
              CssLinear(180, [Color(0xFFB9C0C6), Color(0xFF8E979E)]),
            ],
            shadows: [CssShadow.inset(0, 2, 0, 0, rgba(255, 255, 255, .7))],
          ),
        ),
        Positioned(
          left: 36,
          right: 36,
          top: 294,
          height: 120,
          child: CssBox(
            bg: const [
              CssLinear(180, [Color(0xFF2C3237), Color(0xFF15191C)], [0, .8]),
            ],
            shadows: [CssShadow.inset(0, 2, 0, 0, rgba(255, 255, 255, .12)), CssShadow(0, 20, 30, -10, rgba(0, 0, 0, .6))],
          ),
        ),
        Positioned(
          left: 52,
          right: 52,
          top: 322,
          height: 60,
          child: CssBox(
            radius: BorderRadius.circular(8),
            bg: const [
              CssLinear(180, [Color(0xFF0E1113), Color(0xFF1A1F23)]),
            ],
            shadows: [CssShadow.inset(0, 0, 0, 1.5, rgba(255, 255, 255, .08))],
          ),
        ),
        for (final x in const [70.0, 112.0, 236.0, 278.0]) _knott(x),
        _led(74, 338),
        _led(242, 338),
        // Burner glows.
        Positioned(left: 100, top: 262, child: _Glod(dur: 1200, child: _glodEllipse(70, 12, const Color(0xF2FF963C), 3))),
        Positioned(left: 238, top: 262, child: _Glod(dur: 1500, delay: 400, child: _glodEllipse(74, 12, const Color(0xF2FF963C), 3))),
        Positioned(left: 80, top: 256, child: _Glod(dur: 600, child: _glodEllipse(92, 8, const Color(0xF278B4FF), 2))),
        // Small blue flames.
        _flamme(96, 240, 12, 20, const [Color(0xFFFFF4B0), Color(0xFFF26D3D)], 300, 0),
        _flamme(118, 236, 14, 26, const [Color(0xFFFFFBE0), Color(0xFFF9A23D)], 260, 100),
        _flamme(140, 240, 12, 20, const [Color(0xFFFFF4B0), Color(0xFFF26D3D)], 320, 50),
        // The pan.
        Positioned(
          left: 66,
          top: 226,
          child: CssBox(
            width: 118,
            height: 26,
            radius: const BorderRadius.vertical(bottom: Radius.elliptical(60, 26)),
            bg: const [
              CssLinear(180, [Color(0xFF2A2F33), Color(0xFF101214)]),
            ],
            shadows: [CssShadow(0, 10, 14, 0, rgba(0, 0, 0, .45))],
          ),
        ),
        Positioned(
          left: 66,
          top: 206,
          child: CssBox(
            width: 118,
            height: 42,
            radius: const BorderRadius.all(Radius.elliptical(59, 21)),
            bg: const [
              CssLinear(180, [Color(0xFF4A5056), Color(0xFF22262A), Color(0xFF111315)], [0, .55, 1]),
            ],
            shadows: [CssShadow.inset(0, 3, 0, 0, rgba(255, 255, 255, .22)), CssShadow.inset(0, -6, 10, 0, rgba(0, 0, 0, .6))],
          ),
        ),
        Positioned(
          left: 76,
          top: 212,
          child: CssBox(
            width: 98,
            height: 30,
            radius: const BorderRadius.all(Radius.elliptical(49, 15)),
            bg: const [
              CssRadial([Color(0xFF3A2A1A), Color(0xFF1A1614)], stops: [0, .7], cx: .5, cy: .6),
            ],
            shadows: [CssShadow.inset(0, 2, 4, 0, rgba(0, 0, 0, .6))],
          ),
        ),
        Positioned(
          left: 78,
          top: 214,
          child: _Glod(
            dur: 500,
            child: SizedBox(
              width: 94,
              height: 26,
              child: CssBox(
                radius: const BorderRadius.all(Radius.elliptical(47, 13)),
                bg: [
                  CssRadial([rgba(255, 170, 60, .85), rgba(255, 120, 40, .35), rgba(255, 120, 40, 0)], stops: const [0, .45, .75], cx: .5, cy: .7),
                ],
              ),
            ),
          ),
        ),
        // The big flames.
        _flamme(86, 174, 22, 48, const [Color(0xFFFFE27A), Color(0xFFF26D3D)], 340, 0),
        _flamme(104, 156, 28, 68, const [Color(0xFFFFF4B0), Color(0xFFF58A3D)], 280, 90),
        _flamme(126, 148, 30, 76, const [Color(0xFFFFFBE0), Color(0xFFF9A23D)], 300, 170),
        _flamme(150, 160, 26, 64, const [Color(0xFFFFF4B0), Color(0xFFF58A3D)], 270, 40),
        _flamme(168, 178, 20, 46, const [Color(0xFFFFE27A), Color(0xFFF26D3D)], 330, 130),
        _flamme(96, 194, 14, 32, const [Color(0xFFFFFFFF), Color(0xFFFFE27A)], 220, 20),
        _flamme(116, 178, 16, 44, const [Color(0xFFFFFFFF), Color(0xFFFFF0A0)], 200, 110),
        _flamme(136, 172, 18, 50, const [Color(0xFFFFFFFF), Color(0xFFFFF0A0)], 240, 70),
        _flamme(158, 186, 14, 38, const [Color(0xFFFFFFFF), Color(0xFFFFE27A)], 210, 140),
        // Sparks.
        _gnist(110, 150, 4, const Color(0xFFFFD27A), -18, -60, 1200, 0),
        _gnist(134, 142, 3, const Color(0xFFFFB26B), 12, -70, 1500, 500),
        _gnist(156, 154, 3, const Color(0xFFFF8A4A), 22, -56, 1100, 900),
        // Heat haze.
        Positioned(left: 84, top: 150, child: _Glod(dur: 700, child: _glodEllipse(110, 80, const Color(0x73FFA03C), 10))),
        // The pan handle.
        Positioned(
          left: 180,
          top: 228,
          child: Transform.rotate(
            angle: rad(-6),
            alignment: Alignment.centerLeft,
            child: CssBox(
              width: 46,
              height: 10,
              radius: const BorderRadius.horizontal(left: Radius.circular(3), right: Radius.circular(6)),
              bg: const [
                CssLinear(180, [Color(0xFF4A4F54), Color(0xFF1E2124)]),
              ],
              shadows: [CssShadow(0, 3, 4, 0, rgba(0, 0, 0, .4))],
            ),
          ),
        ),
        // The pot.
        Positioned(
          left: 236,
          top: 186,
          child: CssBox(
            width: 78,
            height: 76,
            radius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(14)),
            bg: const [
              CssLinear(90, [Color(0xFFB8BFC5), Color(0xFFF0F3F5), Color(0xFFC9D0D5), Color(0xFF8E979E)], [0, .3, .6, 1]),
            ],
            shadows: [CssShadow.inset(0, -12, 16, -8, rgba(0, 0, 0, .35)), CssShadow(0, 10, 14, 0, rgba(0, 0, 0, .4))],
          ),
        ),
        Positioned(
          left: 232,
          top: 178,
          child: CssBox(
            width: 86,
            height: 16,
            radius: const BorderRadius.all(Radius.elliptical(43, 8)),
            bg: const [
              CssLinear(180, [Color(0xFFF4F6F8), Color(0xFFB8BFC5)]),
            ],
            shadows: [CssShadow(0, 2, 3, 0, rgba(0, 0, 0, .35))],
          ),
        ),
        Positioned(
          left: 270,
          top: 170,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E2124)),
          ),
        ),
        Positioned(
          left: 224,
          top: 210,
          child: Container(
            width: 14,
            height: 8,
            decoration: BoxDecoration(color: const Color(0xFF2E3338), borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Positioned(
          left: 312,
          top: 210,
          child: Container(
            width: 14,
            height: 8,
            decoration: BoxDecoration(color: const Color(0xFF2E3338), borderRadius: BorderRadius.circular(4)),
          ),
        ),
        // Steam.
        _damp(248, 150, 34, .9, 7, 3200, 0),
        _damp(270, 156, 28, .85, 7, 3600, 1100),
        _damp(258, 152, 40, .75, 9, 4000, 2200),
        // Ægil's bubble (left 96, top 44, 212 wide), `spOpp .5s .5s`.
        Positioned(
          left: 96,
          top: 44,
          width: 212,
          child: LfRise(
            delay: 500,
            dur: 500,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CssBox(
                  radius: BorderRadius.circular(16),
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                  bg: [
                    CssLinear(160, [rgba(255, 255, 255, .97), rgba(233, 240, 242, .94)]),
                  ],
                  shadows: [CssShadow(0, 10, 22, -8, rgba(3, 16, 24, .55)), const CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF))],
                  child: LfPretty(
                    SporingCopy.a1_sporing_koker,
                    style: inter(12.5, weight: FontWeight.w700, em: -.01, height: 1.35, color: kSpPaperInk),
                  ),
                ),
                Positioned(
                  left: 44,
                  bottom: -7,
                  child: Transform.rotate(
                    angle: rad(45),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [rgba(255, 255, 255, .97), rgba(233, 240, 242, .94)]),
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // «På komfyren · N min igjen» (right 16, top 14).
        Positioned(
          right: 16,
          top: 14,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: rgba(255, 255, 255, .8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: rgba(255, 255, 255, .95)),
              boxShadow: [BoxShadow(color: rgba(15, 31, 43, .5), offset: const Offset(0, 10), blurRadius: 18, spreadRadius: -10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [kSpOrange, kSpOrange, rgba(0, 0, 0, .1), rgba(0, 0, 0, .1)], stops: [0, info.pct, info.pct, 1], transform: const GradientRotation(-1.5708)),
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      SporingCopy.a1_sporing_paa_komfyren,
                      style: inter(12, weight: FontWeight.w800, height: 1.1, color: kSpInk),
                    ),
                    if (min != null)
                      Text(
                        SporingCopy.a1_sporing_min_igjen(min),
                        style: inter(10, weight: FontWeight.w700, height: 1.1, color: const Color(0xFF6E6862)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // The vignette.
        Positioned.fill(
          child: IgnorePointer(
            child: CssBox(
              bg: [
                CssLinear(115, [rgba(255, 255, 255, .16), rgba(255, 255, 255, 0), rgba(0, 0, 0, 0), rgba(0, 0, 0, .22)], const [0, .38, .7, 1]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _krukke(double x, double y, double w, double h, List<Color> farger, {bool glans = false}) => Positioned(
    left: x,
    top: y,
    child: CssBox(width: w, height: h, radius: BorderRadius.circular(3), bg: [CssLinear(90, farger)], shadows: [if (glans) CssShadow.inset(2, 0, 0, 0, rgba(255, 255, 255, .35))]),
  );

  static Widget _knott(double x) => Positioned(
    left: x,
    top: 346,
    child: Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(center: Alignment(-.2, -.3), colors: [Color(0xFFE6EAED), Color(0xFF9AA3AA)]),
        boxShadow: [BoxShadow(color: rgba(0, 0, 0, .6), offset: const Offset(0, 2), blurRadius: 3)],
      ),
    ),
  );

  static Widget _led(double x, double y) => Positioned(
    left: x,
    top: y,
    child: Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: kSpOrange,
        boxShadow: [BoxShadow(color: kSpOrange, blurRadius: 6)],
      ),
    ),
  );

  static Widget _glodEllipse(double w, double h, Color c, double blur) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
    child: SizedBox(
      width: w,
      height: h,
      child: CssBox(
        radius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
        bg: [
          CssRadial([c, c.withValues(alpha: 0)], stops: const [0, .7]),
        ],
      ),
    ),
  );

  /// A teardrop flame flickering (`flamme` alternate).
  static Widget _flamme(double x, double y, double w, double h, List<Color> farger, double dur, double delay) => Positioned(
    left: x,
    top: y,
    child: LfLoop(
      builder: (context, t, child) {
        final p = cssEaseInOut.transform(spAlternate(t, dur, delay));
        final sy = .8 + .35 * p;
        final sx = 1.05 - .15 * p;
        return Opacity(
          opacity: .85 + .15 * p,
          child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(sx, sy, 1), child: child),
        );
      },
      child: SizedBox(
        width: w,
        height: h,
        child: CssBox(
          radius: BorderRadius.vertical(top: Radius.elliptical(w / 2, h * .8), bottom: Radius.elliptical(w / 2, h * .2)),
          bg: [
            CssRadial([farger[0], farger[1], farger[1].withValues(alpha: 0)], stops: const [0, .5, 1], rx: .6, ry: .8, cx: .5, cy: .9),
          ],
        ),
      ),
    ),
  );

  /// `gnistFly` — a spark rising and shrinking.
  static Widget _gnist(double x, double y, double size, Color c, double dx, double dy, double dur, double delay) => Positioned(
    left: x,
    top: y,
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : cssEaseOut.transform((e / dur) % 1.0);
        final o = kf(p, const [0, .15, 1], const [0, 1, 0]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(dx * p, dy * p, 0)..scaleByDouble(1 - p, 1 - p, 1, 1), child: child),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [BoxShadow(color: c.withValues(alpha: .9), blurRadius: 6, spreadRadius: 2)],
        ),
      ),
    ),
  );

  /// `damp` — a puff of steam rising and widening.
  static Widget _damp(double x, double y, double size, double alpha, double blur, double dur, double delay) => Positioned(
    left: x,
    top: y,
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : cssEaseOut.transform((e / dur) % 1.0);
        final o = kf(p, const [0, .28, 1], const [0, .5, 0]);
        final ty = kf(p, const [0, 1], const [8, -30]);
        final sx = kf(p, const [0, 1], const [.7, 1.35]);
        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, ty, 0)..scaleByDouble(sx, 1, 1, 1), child: child),
        );
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(255, 255, 255, alpha)),
        ),
      ),
    ),
  );
}

/// `varmeglod` — opacity .55 ↔ .85.
class _Glod extends StatelessWidget {
  const _Glod({required this.child, required this.dur, this.delay = 0});

  final Widget child;
  final double dur, delay;

  @override
  Widget build(BuildContext context) => LfLoop(
    child: child,
    builder: (context, t, child) {
      final e = t - delay;
      final p = e < 0 ? 0.0 : (e / dur) % 1.0;
      return Opacity(opacity: kf(p, const [0, .5, 1], const [.55, .85, .55], cssEaseInOut), child: child);
    },
  );
}

/// A hanging lamp: the cord, the orange shade, the bulb and its cone.
class _Lampe extends StatelessWidget {
  const _Lampe({required this.x});

  final double x;

  @override
  Widget build(BuildContext context) => Positioned(
    left: x - 96,
    top: -4,
    child: SizedBox(
      width: 230,
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 96, top: 0, child: Container(width: 3, height: 52, color: const Color(0xFF2A2A2A))),
          Positioned(
            left: 78,
            top: 50,
            child: ClipPath(
              clipper: _Trapes(.3, .7),
              child: CssBox(
                width: 40,
                height: 24,
                bg: const [
                  CssLinear(180, [Color(0xFFF26D3D), Color(0xFFC4491A)]),
                ],
              ),
            ),
          ),
          Positioned(
            left: 84,
            top: 72,
            child: Container(
              width: 28,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFFFE7B0),
                boxShadow: [BoxShadow(color: rgba(255, 220, 150, .75), blurRadius: 18, spreadRadius: 8)],
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 76,
            child: IgnorePointer(
              child: ClipPath(
                clipper: _Trapes(.4, .6),
                child: CssBox(
                  width: 136,
                  height: 220,
                  bg: [
                    CssLinear(180, [rgba(255, 225, 150, .32), rgba(255, 225, 150, 0)]),
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

/// `clip-path: polygon(a 0, b 0, 100% 100%, 0 100%)`.
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

/// The counter's back edge (`rotateX(60deg)` on a 26 px slab → 13 px).
class _BenkKantPainter extends CustomPainter {
  const _BenkKantPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final path = Path()
      ..moveTo(6, 0)
      ..lineTo(size.width - 6, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7DCE0), Color(0xFFB7BEC4)]).createShader(r));
    canvas.drawLine(
      const Offset(6, 1),
      Offset(size.width - 6, 1),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The room: the tiled back wall, the two side walls in perspective and the
/// plank floor receding.
class _RomPainter extends CustomPainter {
  const _RomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Back wall (0..290) and tiles.
    final wall = Rect.fromLTWH(0, 0, w, 290);
    canvas.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEAF0EE), Color(0xFFD8E2E0)]).createShader(wall));
    final fuge = Paint()
      ..color = rgba(60, 80, 85, .22)
      ..strokeWidth = 2;
    for (var x = 0.0; x <= w; x += 36) {
      canvas.drawLine(Offset(x + 1, 0), Offset(x + 1, 290), fuge);
    }
    for (var y = 0.0; y <= 290; y += 36) {
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), fuge);
    }
    // Side walls: a 120-wide slab turned 58°, its far edge at x≈64.
    void sidevegg(bool venstre) {
      final p = Path();
      final x0 = venstre ? 0.0 : w;
      final x1 = venstre ? 64.0 : w - 64;
      p
        ..moveTo(x0, -30)
        ..lineTo(x1, 0)
        ..lineTo(x1, 290)
        ..lineTo(x0, 330)
        ..close();
      final r = Rect.fromLTRB(venstre ? 0 : w - 64, 0, venstre ? 64 : w, 290);
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: venstre ? Alignment.centerLeft : Alignment.centerRight,
            end: venstre ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [Color(0xFFB9C7C6), Color(0xFFD3DEDC)],
          ).createShader(r),
      );
      canvas.save();
      canvas.clipPath(p);
      for (var y = -30.0; y <= 330; y += 36) {
        canvas.drawLine(
          Offset(x0, y),
          Offset(x1, y + (venstre ? 1 : 1) * (y > 150 ? 1 : -1) * 0),
          Paint()
            ..color = rgba(60, 80, 85, .18)
            ..strokeWidth = 1.5,
        );
      }
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: venstre ? Alignment.centerRight : Alignment.centerLeft,
            end: venstre ? Alignment.centerLeft : Alignment.centerRight,
            colors: [rgba(0, 0, 0, .35), rgba(0, 0, 0, 0)],
            stops: const [0, .5],
          ).createShader(r),
      );
      canvas.restore();
    }

    sidevegg(true);
    sidevegg(false);
    // Floor (290..bottom): planks receding, the far edge compressed.
    final floor = Rect.fromLTRB(0, 290, w, size.height);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5B3A), Color(0xFF6E4529), Color(0xFF4E3020)],
          stops: [0, .5, 1],
        ).createShader(floor),
    );
    final plank = Paint()
      ..color = rgba(0, 0, 0, .18)
      ..strokeWidth = 2;
    const n = 9;
    for (var i = 0; i <= n; i++) {
      final fx = w / 2 + (i / n - .5) * w * .55;
      final nx = w / 2 + (i / n - .5) * w * 1.9;
      canvas.drawLine(Offset(fx, 290), Offset(nx, size.height), plank);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
