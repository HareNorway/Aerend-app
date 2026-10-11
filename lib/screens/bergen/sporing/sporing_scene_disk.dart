import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_gl.dart';
import 'sporing_scene_kai.dart';

/// **Henting · disken** (L6694, the WebGL branch `sjoGlPaa`): the store's
/// pickup counter — the prototype's own shader (`spHkInit`, ported as
/// `shaders/sp_disk.frag`): the panelled wall, the window over Vågen with the
/// rain and the lights across the water, the pendant lamp, the counter with
/// the store's logo, the paper bag with the logo, the bell, and Ægil behind
/// the counter (his sprite and the logo as textures, lit by the scene). Over
/// it, as in the prototype: the bag's label swaying (`hkLapp`) and Ægil's
/// bubble (`bobleFraAegil`). 390 × 450; the box is left 14 → right 14, top
/// 10, 330 tall, radius 28.
class SpSceneDisk extends StatelessWidget {
  const SpSceneDisk({super.key, required this.info});

  final SpSceneInfo info;

  /// Ægil's sprite as the prototype samples it (160 design px at the canvas's
  /// 300 000-pixel size ≈ 254 px), the small copy its soft reads use (mip
  /// bias 2.5–3 ≈ 36 px), and the store's logo (62 px ≈ 98 px).
  static final List<SpGlTex> _ae = [
    SpGlTex.asset('assets/images/dashboard/popup.png', 254, 254),
    SpGlTex.asset('assets/images/dashboard/popup.png', 36, 36),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = SpPal.of(spVaer());
    return SpSceneInn(
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
                      child: SpGl(
                        key: const Key('sp-disk-gl'),
                        asset: 'shaders/sp_disk.frag',
                        w: 362,
                        h: 330,
                        tex: [..._ae, SpGlTex.net(info.logo, 98)],
                        uniforms: (f, _, _, ok) {
                          f(pal.night);
                          f(pal.rain);
                          f(pal.snow);
                          f(ok(0) ? 1 : 0);
                          f(ok(2) ? 1 : 0);
                          pal.skT.forEach(f);
                          pal.skH.forEach(f);
                        },
                      ),
                    ),
                    // The bag's label (left 256, top 102, 36 wide), `hkLapp 3.4s`.
                    Positioned(left: 256, top: 102, child: IgnorePointer(child: _Lapp(info: info))),
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
}

/// The stapled label on the bag (WebGL branch): the store, the customer, the
/// code and time, a dashed rule, the total and a small KLAR.
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
        CssBox(
          width: 36,
          radius: BorderRadius.circular(2),
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
          bg: const [CssLinear(180, [Color(0xFFFDFBF6), Color(0xFFF0ECE2)])],
          shadows: [CssShadow.inset(0, 1, 0, 0, rgba(255, 255, 255, .8)), CssShadow(0, 6, 9, -4, rgba(30, 14, 2, .65)), CssShadow(0, 1, 2, 0, rgba(30, 14, 2, .35))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.butikk.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: inter(5, weight: FontWeight.w800, em: .04, height: 1.1, color: kSpInk),
              ),
              const SizedBox(height: 3),
              Text(
                '${info.kunde}\n${[if (info.kode.isNotEmpty) info.kode, if (info.klokke.isNotEmpty) info.klokke].join(' · ')}',
                style: inter(4.5, weight: FontWeight.w600, height: 1.45, color: const Color(0xFF57534B)),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 3), child: SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _Strek()))),
              Text(info.total, style: inter(5, weight: FontWeight.w800, height: 1.1, color: kSpInk)),
              const SizedBox(height: 3),
              Transform.rotate(
                angle: rad(-8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 1, 3, 1),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2E8B5E)), borderRadius: BorderRadius.circular(2)),
                  child: Text(SporingCopy.a1_sporing_klar_stempel, style: inter(4.5, weight: FontWeight.w800, em: .08, height: 1.1, color: const Color(0xFF2E8B5E))),
                ),
              ),
            ],
          ),
        ),
        // The staple.
        Positioned(
          left: 13,
          top: -2,
          child: Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F6F8), Color(0xFF8A97A2)]),
              boxShadow: [BoxShadow(color: rgba(0, 0, 0, .35), offset: const Offset(0, 1), blurRadius: 1)],
            ),
          ),
        ),
      ],
    ),
  );
}

/// `repeating-linear-gradient(90deg, rgba(35,32,29,.35) 0 2px, transparent 2px 4px)`.
class _Strek extends CustomPainter {
  const _Strek();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = rgba(35, 32, 29, .35);
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_Strek old) => false;
}
