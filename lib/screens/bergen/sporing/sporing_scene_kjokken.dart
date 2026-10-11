import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_gl.dart';
import 'sporing_scene_kai.dart';

/// **Sporing · Tilberedes** (L6609, the WebGL branch `sjoGlPaa`): the
/// kitchen — the prototype's own shader (`spKjInit`, ported as
/// `shaders/sp_kjokken.frag`): tiled walls, the two lamps, the shelf with
/// jars, the rack, the steel worktop and the stove, Ægil the cook (his
/// sprite as a texture, lit by the scene) with the pan on real flames, the
/// steaming pot. Over it, as in the prototype: the order note swaying
/// (`lappSvai`) with its pin, Ægil's bubble (`spOpp`) and the «På komfyren»
/// pill. 390 × 460; the kitchen box is left 14 → right 14, top 8 → bottom,
/// radius 28 on top.
class SpSceneKjokken extends StatelessWidget {
  const SpSceneKjokken({super.key, required this.info});

  final SpSceneInfo info;

  /// Ægil's sprite as the prototype samples it: 210 design px wide at the
  /// canvas's 300 000-pixel size (≈ 284 px), and the small copy its soft
  /// shadow reads (mip bias 2.8 ≈ 40 px).
  static final List<SpGlTex> _tex = [
    SpGlTex.asset('assets/images/dashboard/front.png', 284, 284),
    SpGlTex.asset('assets/images/dashboard/front.png', 40, 40),
  ];

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
              child: _Kjokken(info: info),
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
    final pal = SpPal.of(spVaer());
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: SpGl(
            key: const Key('sp-kjokken-gl'),
            asset: 'shaders/sp_kjokken.frag',
            w: 362,
            h: 452,
            tex: SpSceneKjokken._tex,
            uniforms: (f, _, _, ok) {
              f(pal.night * .8);
              f(ok(0) ? 1 : 0);
            },
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
      ],
    );
  }
}
