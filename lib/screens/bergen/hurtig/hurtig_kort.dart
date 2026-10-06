import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../kit/bergen_css.dart';
import 'hurtig_bits.dart';
import 'hurtig_brain.dart';
import 'hurtig_copy.dart';
import 'hurtig_data.dart';

// ── Hurtigbestilling · the module cards and the draft (prototype L4289–4475) ─

/// «Hurtig · oftest bestilt» (L4289): the four most ordered products with
/// their medals and bars, and the habit of the day with its calendar leaf.
class HbOftestKort extends StatelessWidget {
  const HbOftestKort({super.key, required this.rader, required this.under, required this.vane, required this.onVelg, required this.onVane});

  final List<HbOftestVis> rader;
  final String under;
  final HbVaneVis? vane;
  final ValueChanged<int> onVelg;
  final VoidCallback onVane;

  static const List<(List<Color>, Color, Color)> _med = [
    ([Color(0xFFFFF3C4), Color(0xFFF2C14E), Color(0xFFC98F1E)], Color(0xFF9A6A10), Color(0xFF5A3C10)),
    ([Color(0xFFFFFFFF), Color(0xFFCDD6DA), Color(0xFF8E9BA1)], Color(0xFF6E7B80), Color(0xFF33424A)),
    ([Color(0xFFFFE1C7), Color(0xFFD8915A), Color(0xFFA9612E)], Color(0xFF7E4520), Color(0xFF4A260E)),
  ];

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(24),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE8EFEF)]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 4, 0, 0, Color.fromRGBO(6, 30, 38, .5)), CssShadow(0, 20, 28, -16, Color.fromRGBO(3, 14, 20, .9))],
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HurtigCopy.oftestBestilt,
                  style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbTeal),
                ),
                const SizedBox(height: 2),
                Text(
                  under,
                  style: hbI(11, weight: FontWeight.w700, color: kHbInkFaint),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rader.length; i++) ...[if (i > 0) const SizedBox(height: 6), _rad(rader[i], i)],
          if (vane != null) ...[const SizedBox(height: 10), _vane(vane!)],
        ],
      ),
    );
  }

  Widget _rad(HbOftestVis r, int i) {
    final md = i < _med.length ? _med[i] : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: cssEase,
      padding: const EdgeInsets.fromLTRB(12, 10, 9, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: r.lagt
            ? cssLinear(100, const [Color(0xFFE0F8EF), Color(0xFFFFFFFF)], const [0, .75])
            : i == 0
            ? cssLinear(100, const [Color(0xFFFFF3D2), Color(0xFFFFFFFF)], const [0, .75])
            : cssLinear(100, const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]),
        boxShadow: [
          const BoxShadow(color: Color.fromRGBO(35, 32, 29, .35), offset: Offset(0, 6), blurRadius: 12 / 2 / .57735, spreadRadius: -8),
          if (!r.lagt) const BoxShadow(color: Color.fromRGBO(35, 32, 29, .06), offset: Offset(0, 1)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: r.lagt ? const Color.fromRGBO(60, 199, 159, .55) : Colors.transparent, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HbFlis(ini: r.ini, bg: r.bg, fg: r.fg, size: 42, radius: 13, fontSize: 12.5),
                Positioned(
                  left: -7,
                  top: -7,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: md != null
                          ? RadialGradient(center: const Alignment(-.3, -.4), radius: .7, colors: md.$1, stops: const [0, .55, 1])
                          : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFE6ECEE)]),
                      boxShadow: [
                        const BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 2),
                        BoxShadow(color: md?.$2 ?? const Color(0xFFB9C4C7), offset: const Offset(0, 2.5), spreadRadius: 2),
                        const BoxShadow(color: Color.fromRGBO(3, 16, 24, .28), offset: Offset(0, 6), blurRadius: 8 / 2 / .57735, spreadRadius: 1),
                      ],
                    ),
                    foregroundDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromRGBO(255, 255, 255, .75), Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(0, 0, 0, 0), Color.fromRGBO(0, 0, 0, .12)],
                        stops: [0, .08, .92, 1],
                      ),
                    ),
                    child: Text('${r.nr}', style: hbJ(10, color: md?.$3 ?? const Color(0xFF57534B), tabular: true)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.navn, maxLines: 2, overflow: TextOverflow.ellipsis, style: hbJ(13.5, em: -.01, height: 1.2)),
                const SizedBox(height: 3),
                Text(
                  r.butikk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: hbI(10.5, weight: FontWeight.w700, color: kHbInkFaint),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 70),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color.fromRGBO(35, 32, 29, .08)),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CssBox(radius: BorderRadius.circular(3), clip: true, shadows: const [CssShadow.inset(0, 1, 1, 0, Color.fromRGBO(35, 32, 29, .14))]),
                              ),
                              FractionallySizedBox(
                                widthFactor: r.pst.clamp(0, 1),
                                child: CssBox(
                                  height: 6,
                                  radius: BorderRadius.circular(3),
                                  clip: true,
                                  bg: const [
                                    CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF2FB893)]),
                                  ],
                                  shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .55))],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.ganger,
                      style: hbI(10, weight: FontWeight.w800, color: kHbTeal, tabular: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(r.pris, style: hbJ(13, tabular: true)),
              const SizedBox(height: 6),
              HbPress(
                dy: 3,
                onTap: () => onVelg(r.id),
                child: r.lagt
                    ? VcKnapp(
                        key: ValueKey('lagt-${r.id}'),
                        ms: 350,
                        child: CssBox(
                          width: 40,
                          height: 32,
                          radius: BorderRadius.circular(12),
                          bg: const [
                            CssLinear(180, [Color(0xFFA6F8DD), Color(0xFF5CE0B8), Color(0xFF3CC79F)], [0, .55, 1]),
                          ],
                          shadows: const [
                            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .65)),
                            CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .06)),
                            CssShadow(0, 3, 0, 0, Color(0xFF23946F)),
                            CssShadow(0, 9, 12, -6, Color.fromRGBO(20, 110, 80, .6)),
                          ],
                          child: const Center(child: HbIkon(HbIkoner.hake, size: 14, stroke: Color(0xFF0F3A40), width: 3.4)),
                        ),
                      )
                    : CssBox(
                        key: ValueKey('legg-${r.id}'),
                        width: 40,
                        height: 32,
                        radius: BorderRadius.circular(12),
                        bg: const [
                          CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1]),
                        ],
                        shadows: const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                          CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                          CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                          CssShadow(0, 9, 12, -6, Color.fromRGBO(120, 40, 10, .6)),
                        ],
                        child: const Center(child: HbIkon(HbIkoner.pluss, size: 14, stroke: Colors.white, width: 3.4)),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vane(HbVaneVis v) => HbPress(
    dy: 3,
    onTap: onVane,
    child: CssBox(
      radius: BorderRadius.circular(18),
      clip: true,
      bg: const [
        CssRadial([Color.fromRGBO(255, 148, 102, .3), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: 1.2, cx: 1, cy: 0),
        CssLinear(160, [Color(0xFF2F6C7D), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .58, 1]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .08)),
        CssShadow(0, 4, 0, 0, Color(0xFF0E2E36)),
        CssShadow(0, 14, 20, -12, Color.fromRGBO(4, 18, 26, .85)),
      ],
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          CssBox(
            width: 44,
            radius: BorderRadius.circular(11),
            clip: true,
            bg: const [
              CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE9F0F1)]),
            ],
            shadows: const [CssShadow(0, 3, 0, 0, Color(0xFF92A9B0)), CssShadow(0, 9, 12, -6, Color.fromRGBO(0, 0, 0, .6))],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CssBox(
                  height: 16,
                  width: 44,
                  bg: const [
                    CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
                  ],
                  shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4))],
                  child: Center(
                    child: Text(
                      v.dag,
                      style: hbI(8.5, weight: FontWeight.w800, em: .12, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 6),
                  child: Text(v.kl, style: hbJ(11.5, color: kHbTealDeep, tabular: true)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.tittel,
                  style: hbI(9.5, weight: FontWeight.w800, em: .1, color: kHbMintPale),
                ),
                const SizedBox(height: 2),
                LfPretty(v.varer, style: hbJ(12.5, color: Colors.white, height: 1.3)),
                const SizedBox(height: 2),
                Text(
                  v.sum,
                  style: hbI(11, weight: FontWeight.w800, color: const Color(0xFFFFD2BD), tabular: true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          CssBox(
            height: 34,
            radius: BorderRadius.circular(11),
            bg: const [
              CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE4EDEF)]),
            ],
            shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 3, 0, 0, Color(0xFF8FA6AD)), CssShadow(0, 9, 12, -6, Color.fromRGBO(0, 0, 0, .55))],
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                HurtigCopy.settOpp,
                style: hbI(12, weight: FontWeight.w800, color: kHbTealDeep),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One «oftest» row as the card shows it.
class HbOftestVis {
  const HbOftestVis({
    required this.id,
    required this.nr,
    required this.navn,
    required this.butikk,
    required this.ini,
    required this.bg,
    this.fg = Colors.white,
    required this.ganger,
    required this.pst,
    required this.pris,
    required this.lagt,
  });

  final int id;
  final int nr;
  final String navn;
  final String butikk;
  final String ini;
  final Color bg;
  final Color fg;
  final String ganger;
  final double pst;
  final String pris;
  final bool lagt;
}

class HbVaneVis {
  const HbVaneVis({required this.dag, required this.kl, required this.tittel, required this.varer, required this.sum});
  final String dag;
  final String kl;
  final String tittel;
  final String varer;
  final String sum;
}

/// «Hurtig · bestilt forrige gang» (L4322): the last order as a receipt with
/// the LEVERT stamp, «Bestill det samme igjen», and the two before it.
class HbForrigeKort extends StatelessWidget {
  const HbForrigeKort({super.key, required this.fo, required this.tidligere, required this.onIgjen});

  final HbOrdreVis fo;
  final List<HbOrdreVis> tidligere;
  final ValueChanged<HbOrdreVis> onIgjen;

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(24),
      bg: const [
        CssLinear(180, [Color(0xFFF3F7F7), Color(0xFFE2EAEB)]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 4, 0, 0, Color.fromRGBO(6, 30, 38, .5)), CssShadow(0, 20, 28, -16, Color.fromRGBO(3, 14, 20, .9))],
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                HbFlis(ini: fo.ini, bg: fo.bg, fg: fo.fg, size: 44, radius: 14, fontSize: 13.5),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HurtigCopy.bestiltForrigeGang,
                        style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbTeal),
                      ),
                      const SizedBox(height: 1),
                      Text(fo.butikk, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: hbJ(15.5, em: -.01)),
                      Text(
                        fo.under,
                        style: hbI(11, weight: FontWeight.w700, color: kHbInkFaint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 11),
                Transform.rotate(
                  angle: rad(-8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2FB893), width: 2),
                      color: const Color.fromRGBO(227, 245, 238, .75),
                      boxShadow: const [BoxShadow(color: Color.fromRGBO(20, 110, 80, .55), offset: Offset(0, 3), blurRadius: 8 / 2 / .57735, spreadRadius: -4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HbIkon(HbIkoner.hake, size: 9, stroke: Color(0xFF1F8A66), width: 3.8),
                        const SizedBox(width: 4),
                        Text(
                          HurtigCopy.levert,
                          style: hbI(9.5, weight: FontWeight.w800, em: .12, color: const Color(0xFF1F8A66)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CssBox(
            radius: const BorderRadius.vertical(top: Radius.circular(14)),
            bg: const [CssSolid(Color(0xFFFFFFFF))],
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF))],
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final x in fo.linjer)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        CssBox(
                          height: 22,
                          radius: BorderRadius.circular(7),
                          bg: const [CssSolid(Color(0xFFEAF1F2))],
                          shadows: const [CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(30, 79, 92, .14))],
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Center(
                              child: Text(
                                x.ant,
                                style: hbI(11, weight: FontWeight.w800, color: kHbTeal, tabular: true),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(x.navn, style: hbI(13, weight: FontWeight.w700, height: 1.25, tabular: true)),
                        ),
                        const SizedBox(width: 9),
                        Text(x.pris, style: hbI(13, weight: FontWeight.w800, tabular: true)),
                      ],
                    ),
                  ),
                const Padding(padding: EdgeInsets.fromLTRB(0, 7, 0, 9), child: HbStiplet()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.betalt,
                      style: hbI(12, weight: FontWeight.w800, color: kHbInkSoft),
                    ),
                    Text(fo.sum, style: hbJ(18, em: -.02, tabular: true)),
                  ],
                ),
              ],
            ),
          ),
          const HbPerforering(),
          const SizedBox(height: 12),
          HbPress(
            dy: 3,
            onTap: () => onIgjen(fo),
            child: HbOransje(
              height: 48,
              radius: 15,
              edge: 4,
              glossInset: 10,
              glossTop: 12,
              glossBottom: 30,
              deep: const CssShadow(0, 12, 16, -8, Color.fromRGBO(120, 40, 10, .6)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HbIkon(HbIkoner.omstart, size: 15, stroke: Colors.white, width: 2.8),
                  const SizedBox(width: 8),
                  Text(
                    HurtigCopy.bestillDetSammeIgjen,
                    style: hbJ(
                      14,
                      color: Colors.white,
                      tabular: true,
                      shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .35), offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (tidligere.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 7),
              child: Text(
                HurtigCopy.tidligere,
                style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbInkFaint),
              ),
            ),
            for (var i = 0; i < tidligere.length; i++) ...[if (i > 0) const SizedBox(height: 6), _tidligere(tidligere[i])],
          ],
        ],
      ),
    );
  }

  Widget _tidligere(HbOrdreVis t) => CssBox(
    radius: BorderRadius.circular(16),
    bg: const [CssSolid(Color(0xFFFFFFFF))],
    shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 1, 0, 0, Color.fromRGBO(35, 32, 29, .06)), CssShadow(0, 6, 12, -8, Color.fromRGBO(35, 32, 29, .35))],
    padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
    child: Row(
      children: [
        HbFlis(ini: t.ini, bg: t.bg, fg: t.fg, size: 36, radius: 11, fontSize: 11),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      t.butikk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: hbI(13, weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(t.sum, style: hbI(12, weight: FontWeight.w800, tabular: true)),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                t.dato,
                style: hbI(10.5, weight: FontWeight.w800, color: kHbTeal),
              ),
              Text(
                t.varer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: hbI(10.5, color: kHbInkFaint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        HbPress(
          dy: 3,
          onTap: () => onIgjen(t),
          child: CssBox(
            height: 32,
            radius: BorderRadius.circular(11),
            bg: const [
              CssLinear(165, [Color(0xFF33788A), Color(0xFF1E4F5C)]),
            ],
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow(0, 3, 0, 0, Color(0xFF0E2E36)), CssShadow(0, 8, 12, -6, Color.fromRGBO(4, 18, 26, .6))],
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HbIkon(HbIkoner.omstart, size: 11, stroke: Color(0xFF7FF0CB), width: 2.8),
                const SizedBox(width: 5),
                Text(
                  HurtigCopy.igjen,
                  style: hbI(11.5, weight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// An order as the «forrige» card shows it.
class HbOrdreVis {
  const HbOrdreVis({
    required this.ordre,
    required this.butikk,
    required this.ini,
    required this.bg,
    this.fg = Colors.white,
    required this.sum,
    required this.dato,
    required this.varer,
    this.under = '',
    this.linjer = const [],
  });

  final HbOrdre ordre;
  final String butikk;
  final String ini;
  final Color bg;
  final Color fg;
  final String sum;
  final String dato;
  final String varer;
  final String under;
  final List<HbLinjeVis> linjer;
}

class HbLinjeVis {
  const HbLinjeVis(this.ant, this.navn, this.pris);
  final String ant;
  final String navn;
  final String pris;
}

/// «Hurtig · dine preferanser» (L4356): what Ægil has learned, the household
/// stepper, the shellfish toggle, and «Ægil foreslår i kveld».
class HbPrefKort extends StatelessWidget {
  const HbPrefKort({
    super.key,
    required this.under,
    required this.liker,
    required this.butikker,
    required this.hus,
    required this.onHusMinus,
    required this.onHusPluss,
    required this.unngaaSkalldyr,
    required this.onSkalldyr,
    required this.rytme,
    required this.forslagLinje,
    required this.forslagButikk,
    required this.grunner,
    required this.forslagSum,
    required this.onForslag,
    required this.onMinne,
  });

  final String under;
  final List<String> liker;
  final List<String> butikker;
  final String hus;
  final VoidCallback onHusMinus;
  final VoidCallback onHusPluss;
  final bool unngaaSkalldyr;
  final VoidCallback onSkalldyr;
  final String rytme;
  final String forslagLinje;
  final String forslagButikk;
  final List<String> grunner;
  final String forslagSum;
  final VoidCallback onForslag;
  final VoidCallback onMinne;

  static const BoxDecoration _linje = BoxDecoration(
    border: Border(top: BorderSide(color: Color.fromRGBO(35, 32, 29, .07))),
  );

  Widget _rad(String label, Widget child, {double pad = 8, CrossAxisAlignment align = CrossAxisAlignment.start, double labelTop = 4}) => Container(
    decoration: _linje,
    padding: EdgeInsets.fromLTRB(2, pad, 2, pad),
    child: Row(
      crossAxisAlignment: align,
      children: [
        SizedBox(
          width: 64,
          child: Padding(
            padding: EdgeInsets.only(top: align == CrossAxisAlignment.start ? labelTop : 0),
            child: Text(
              label,
              style: hbI(10.5, weight: FontWeight.w800, color: kHbInkFaint),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    ),
  );

  Widget _chips(List<String> items, Color bg, Color fg) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final t in items)
        Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: bg),
          child: Text(
            t,
            style: hbI(11, weight: FontWeight.w800, color: fg),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(22),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF2F2)]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 3, 0, 0, Color.fromRGBO(6, 30, 38, .5)), CssShadow(0, 16, 24, -14, Color.fromRGBO(3, 14, 20, .85))],
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  HurtigCopy.dinePreferanser,
                  style: hbI(10, weight: FontWeight.w800, em: .1, color: kHbTeal),
                ),
                Text(
                  under,
                  style: hbI(10.5, weight: FontWeight.w700, color: kHbInkFaint),
                ),
              ],
            ),
          ),
          _rad(HurtigCopy.liker, _chips(liker, const Color(0xFFE3F5EE), kHbTealDeep)),
          _rad(HurtigCopy.butikker, _chips(butikker, const Color.fromRGBO(35, 32, 29, .06), kHbInk)),
          _rad(
            HurtigCopy.husstand,
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(35, 32, 29, .06)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HbPress(
                      scale: .9,
                      onTap: onHusMinus,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Color.fromRGBO(35, 32, 29, .15), offset: Offset(0, 1)),
                            BoxShadow(color: Color.fromRGBO(35, 32, 29, .4), offset: Offset(0, 3), blurRadius: 6 / 2 / .57735, spreadRadius: -3),
                          ],
                        ),
                        child: const Center(child: HbIkon(HbIkoner.minus, size: 11, stroke: kHbInk, width: 3)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 74),
                      child: Text(
                        hus,
                        textAlign: TextAlign.center,
                        style: hbI(12, weight: FontWeight.w800, tabular: true),
                      ),
                    ),
                    const SizedBox(width: 4),
                    HbPress(
                      scale: .9,
                      onTap: onHusPluss,
                      child: CssBox(
                        width: 26,
                        height: 26,
                        radius: BorderRadius.circular(13),
                        bg: const [
                          CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
                        ],
                        shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .26)), CssShadow(0, 2, 0, 0, Color.fromRGBO(11, 38, 45, .9))],
                        child: const Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: Colors.white, width: 3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pad: 7,
            align: CrossAxisAlignment.center,
          ),
          _rad(
            HurtigCopy.allergier,
            Row(
              children: [
                HbPress(
                  scale: .95,
                  onTap: onSkalldyr,
                  child: unngaaSkalldyr
                      ? CssBox(
                          radius: BorderRadius.circular(999),
                          bg: const [CssSolid(Color(0xFFFCE6DC))],
                          shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(176, 71, 44, .25))],
                          padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HbIkon(HbIkoner.kryss, size: 10, stroke: Color(0xFF9A3B22), width: 3.2),
                              const SizedBox(width: 6),
                              Text(
                                HurtigCopy.unngaarSkalldyr,
                                style: hbI(11, weight: FontWeight.w800, color: const Color(0xFF9A3B22)),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFE3F5EE)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HbIkon(HbIkoner.hake, size: 10, stroke: Color(0xFF2E7E4F), width: 3.4),
                              const SizedBox(width: 6),
                              Text(
                                HurtigCopy.skalldyrOk,
                                style: hbI(11, weight: FontWeight.w800, color: const Color(0xFF2E7E4F)),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    HurtigCopy.trykkForAaEndre,
                    style: hbI(10, weight: FontWeight.w700, color: const Color(0xFF8C847C)),
                  ),
                ),
              ],
            ),
            pad: 7,
            align: CrossAxisAlignment.center,
          ),
          _rad(
            HurtigCopy.middag,
            Text(rytme, style: hbI(12, weight: FontWeight.w800)),
            align: CrossAxisAlignment.center,
          ),
          _rad(
            HurtigCopy.betaling,
            Text(HurtigCopy.vippsPaaDora, style: hbI(12, weight: FontWeight.w800)),
            align: CrossAxisAlignment.center,
          ),
          const SizedBox(height: 6),
          CssBox(
            radius: BorderRadius.circular(18),
            clip: true,
            bg: const [
              CssRadial([Color.fromRGBO(255, 148, 102, .26), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: 1.2, cx: 1, cy: 0),
              CssLinear(160, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173E48)], [0, .6, 1]),
            ],
            shadows: const [
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)),
              CssShadow(0, 3, 0, 0, Color.fromRGBO(11, 38, 45, .85)),
              CssShadow(0, 10, 18, -12, Color.fromRGBO(4, 18, 26, .8)),
            ],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  HurtigCopy.foreslaarIKveld,
                  style: hbI(9.5, weight: FontWeight.w800, em: .1, color: kHbMintPale),
                ),
                const SizedBox(height: 4),
                Text(forslagLinje, style: hbJ(14, color: Colors.white, height: 1.3)),
                const SizedBox(height: 2),
                Text(
                  forslagButikk,
                  style: hbI(11, weight: FontWeight.w700, color: const Color(0xFFC4D8DE)),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final g in grunner)
                      CssBox(
                        radius: BorderRadius.circular(999),
                        bg: const [CssSolid(Color.fromRGBO(127, 240, 203, .14))],
                        shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(127, 240, 203, .32))],
                        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                        child: Text(
                          g,
                          style: hbI(10, weight: FontWeight.w800, color: const Color(0xFFC8F7E6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 11),
                HbPress(
                  dy: 2.5,
                  onTap: onForslag,
                  child: CssBox(
                    height: 42,
                    radius: BorderRadius.circular(13),
                    bg: const [
                      CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
                    ],
                    shadows: const [
                      CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                      CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                      CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
                    ],
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HbIkon(HbIkoner.lyn, size: 12, fill: Colors.white),
                          const SizedBox(width: 7),
                          Text(
                            HurtigCopy.settOppSum(forslagSum),
                            style: hbI(13, weight: FontWeight.w800, color: Colors.white, tabular: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMinne,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  HurtigCopy.endreDetAegilVet,
                  style: hbI(11.5, weight: FontWeight.w800, color: kHbTeal),
                ),
                const SizedBox(width: 5),
                const HbIkon(HbIkoner.videre, size: 11, stroke: kHbTeal, width: 2.8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Hurtig · bestilt» (L4385): the confirmation inside the chat.
class HbBestiltKort extends StatelessWidget {
  const HbBestiltKort({super.key, required this.kode, required this.butikk, required this.klar, required this.linje, required this.kr, required this.sum, required this.onFolg});

  final String kode;
  final String butikk;
  final String klar;
  final String linje;
  final String kr;
  final String sum;
  final VoidCallback onFolg;

  @override
  Widget build(BuildContext context) {
    return CssBox(
      radius: BorderRadius.circular(22),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF2F2)]),
      ],
      shadows: const [
        CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
        CssShadow(0, 0, 0, 2, Color.fromRGBO(92, 224, 184, .55)),
        CssShadow(0, 3, 0, 2, Color.fromRGBO(6, 30, 38, .45)),
        CssShadow(0, 18, 26, -14, Color.fromRGBO(3, 14, 20, .85)),
      ],
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CssBox(
                width: 44,
                height: 44,
                radius: BorderRadius.circular(22),
                bg: const [
                  CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF3CC79F)]),
                ],
                shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .6)), CssShadow(0, 3, 0, 0, Color(0xFF23946F)), CssShadow(0, 10, 16, -8, Color.fromRGBO(20, 110, 80, .7))],
                child: const Center(child: HbIkon(HbIkoner.hake, size: 20, stroke: Color(0xFF0F3A40), width: 3.2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HurtigCopy.bestiltKode(kode),
                      style: hbI(10, weight: FontWeight.w800, em: .1, color: const Color(0xFF2E8B5E)),
                    ),
                    const SizedBox(height: 1),
                    Text(butikk, style: hbJ(15.5, em: -.01)),
                    Text(
                      klar,
                      style: hbI(11.5, weight: FontWeight.w700, color: kHbInkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LfPretty(linje, style: hbI(12, color: kHbInkSoft, height: 1.4)),
          const SizedBox(height: 9),
          const HbStiplet(color: Color.fromRGBO(35, 32, 29, .2), dash: 3, gap: 3),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFE3F5EE)),
                child: Text(
                  kr,
                  style: hbI(10.5, weight: FontWeight.w800, color: const Color(0xFF2E7E4F)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    HurtigCopy.vipps,
                    style: hbI(11, weight: FontWeight.w700, color: kHbInkFaint),
                  ),
                  const SizedBox(width: 6),
                  Text(sum, style: hbJ(16, tabular: true)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          HbPress(
            dy: 2.5,
            onTap: onFolg,
            child: CssBox(
              height: 44,
              radius: BorderRadius.circular(14),
              bg: const [
                CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C)]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
                CssShadow(0, 3, 0, 0, Color.fromRGBO(11, 38, 45, .9)),
                CssShadow(0, 10, 14, -8, Color.fromRGBO(15, 45, 55, .8)),
              ],
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      HurtigCopy.folgBestillingen,
                      style: hbI(13.5, weight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(width: 7),
                    const HbIkon(HbIkoner.videre, size: 13, stroke: Color(0xFF7FF0CB), width: 2.8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Hurtig · ordreutkast» (L4417): the draft with its lines and steppers,
/// the «LEGG TIL?» chips, the sums with the free-delivery bar, the three
/// tiles and the order key with its countdown fill.
class HbUtkastKort extends StatelessWidget {
  const HbUtkastKort({
    super.key,
    required this.ini,
    required this.bg,
    this.fg = Colors.white,
    required this.butikk,
    required this.klar,
    required this.linjer,
    required this.forslag,
    required this.varer,
    required this.levGratis,
    required this.lev,
    required this.levPst,
    required this.levTekst,
    required this.total,
    required this.adresse,
    required this.tid,
    required this.teller,
    required this.tellerSek,
    required this.cta,
    required this.onCta,
    required this.onTidBytt,
    required this.onTilKurv,
  });

  final String ini;
  final Color bg;
  final Color fg;
  final String butikk;
  final String klar;
  final List<HbUtkastLinjeVis> linjer;
  final List<HbForslagVis> forslag;
  final String varer;
  final bool levGratis;
  final String lev;
  final double levPst;
  final String levTekst;
  final String total;
  final String adresse;
  final String tid;
  final bool teller;
  final int tellerSek;
  final String cta;
  final VoidCallback onCta;
  final VoidCallback onTidBytt;
  final VoidCallback onTilKurv;

  static const List<CssShadow> _flat = [
    CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)),
    CssShadow(0, 1, 0, 0, Color.fromRGBO(35, 32, 29, .06)),
    CssShadow(0, 6, 12, -8, Color.fromRGBO(35, 32, 29, .35)),
  ];

  Widget _rund(Widget icon) => CssBox(
    width: 28,
    height: 28,
    radius: BorderRadius.circular(14),
    bg: const [
      CssLinear(180, [Color(0xFFEAF4F5), Color(0xFFD2E4E7)]),
    ],
    shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 1.5, 0, 0, Color(0xFFAFC4C9))],
    child: Center(child: icon),
  );

  @override
  Widget build(BuildContext context) {
    // The fill grows one second per tick, from 20 % at 5 s to 100 % at 1 s.
    final fyll = teller ? ((6 - tellerSek) / 5).clamp(0.0, 1.0) : 0.0;
    return CssBox(
      radius: BorderRadius.circular(26),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFE8EFEF)]),
      ],
      shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 5, 0, 0, Color.fromRGBO(6, 30, 38, .55)), CssShadow(0, 26, 36, -16, Color.fromRGBO(3, 14, 20, .9))],
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                HbFlis(ini: ini, bg: bg, fg: fg, size: 46, radius: 15, fontSize: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const HbIkon(HbIkoner.lyn, size: 10, fill: Color(0xFFE95C2C)),
                          const SizedBox(width: 5),
                          Text(
                            HurtigCopy.aegilsUtkast,
                            style: hbI(10, weight: FontWeight.w800, em: .12, color: const Color(0xFFD2501F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(butikk, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, style: hbJ(16, em: -.015)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const HbIkon(HbIkoner.klokke, size: 11, stroke: kHbTeal, width: 2.6),
                          const SizedBox(width: 5),
                          Text(
                            klar,
                            style: hbI(11, weight: FontWeight.w700, color: kHbInkSoft, tabular: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < linjer.length; i++) ...[if (i > 0) const SizedBox(height: 6), _linje(linjer[i])],
          if (forslag.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HurtigCopy.leggTil,
                    style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbInkFaint),
                  ),
                  const SizedBox(height: 7),
                  Wrap(spacing: 7, runSpacing: 7, children: [for (final f in forslag) _forslag(f)]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          CssBox(
            radius: BorderRadius.circular(17),
            bg: const [CssSolid(Color.fromRGBO(30, 79, 92, .06))],
            shadows: const [CssShadow.inset(0, 1.5, 3, 0, Color.fromRGBO(30, 60, 70, .13)), CssShadow(0, 1, 0, 0, Color(0xFFFFFFFF))],
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.varer,
                      style: hbI(12, weight: FontWeight.w700, color: kHbInkSoft),
                    ),
                    Text(
                      varer,
                      style: hbI(12, weight: FontWeight.w700, color: kHbInkSoft, tabular: true),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.levering,
                      style: hbI(12, weight: FontWeight.w700, color: kHbInkSoft),
                    ),
                    if (levGratis)
                      CssBox(
                        radius: BorderRadius.circular(999),
                        bg: const [CssSolid(Color(0xFFD9F4EA))],
                        shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(47, 184, 147, .35))],
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                        child: Text(
                          HurtigCopy.gratis,
                          style: hbI(11, weight: FontWeight.w800, color: const Color(0xFF1F7A55)),
                        ),
                      )
                    else
                      Text(
                        lev,
                        style: hbI(12, weight: FontWeight.w700, color: kHbInkSoft, tabular: true),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: const Color.fromRGBO(35, 32, 29, .1)),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CssBox(radius: BorderRadius.circular(4), clip: true, shadows: const [CssShadow.inset(0, 1, 2, 0, Color.fromRGBO(35, 32, 29, .22))]),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: levPst.clamp(0, 1)),
                              duration: const Duration(milliseconds: 600),
                              curve: const Cubic(.3, 1.2, .4, 1),
                              builder: (context, v, _) => FractionallySizedBox(
                                widthFactor: v.clamp(0.0, 1.0),
                                child: CssBox(
                                  height: 8,
                                  radius: BorderRadius.circular(4),
                                  clip: true,
                                  bg: [
                                    levGratis ? const CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF2FB893)]) : const CssLinear(180, [Color(0xFFFFB089), Color(0xFFF26D3D)]),
                                  ],
                                  shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .55))],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      levTekst,
                      style: hbI(10.5, weight: FontWeight.w800, color: levGratis ? const Color(0xFF1F7A55) : const Color(0xFFC2481C)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color.fromRGBO(35, 32, 29, .1)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(HurtigCopy.totalt, style: hbI(13, weight: FontWeight.w800)),
                    Text(total, style: hbJ(22, em: -.03, tabular: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CssBox(
            radius: BorderRadius.circular(14),
            bg: const [CssSolid(Color(0xFFFFFFFF))],
            shadows: _flat,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                _rund(const HbIkon(HbIkoner.pin, size: 13, fill: kHbTeal)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HurtigCopy.leveresTil,
                        style: hbI(9.5, weight: FontWeight.w800, color: const Color(0xFF8C847C)),
                      ),
                      Text(
                        adresse,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: hbI(12.5, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: HbPress(
                    scale: .97,
                    onTap: onTidBytt,
                    child: CssBox(
                      radius: BorderRadius.circular(14),
                      bg: const [CssSolid(Color(0xFFFFFFFF))],
                      shadows: const [CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(42, 98, 114, .38)), CssShadow(0, 6, 12, -8, Color.fromRGBO(35, 32, 29, .35))],
                      padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
                      child: Row(
                        children: [
                          _rund(const HbIkon(HbIkoner.klokke, size: 13, stroke: kHbTeal, width: 2.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  HurtigCopy.naar,
                                  style: hbI(9.5, weight: FontWeight.w800, color: kHbTeal),
                                ),
                                Text(
                                  tid,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: hbI(12.5, weight: FontWeight.w800, tabular: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const HbIkon(HbIkoner.tidBytt, size: 12, stroke: kHbTeal, width: 2.8),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CssBox(
                    radius: BorderRadius.circular(14),
                    bg: const [CssSolid(Color(0xFFFFFFFF))],
                    shadows: _flat,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        _rund(const HbIkon(HbIkoner.kort, size: 13, stroke: kHbTeal, width: 2.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                HurtigCopy.betaling,
                                style: hbI(9.5, weight: FontWeight.w800, color: const Color(0xFF8C847C)),
                              ),
                              const SizedBox(height: 2),
                              CssBox(
                                height: 19,
                                radius: BorderRadius.circular(6),
                                bg: const [CssSolid(Color(0xFFFF5B24))],
                                shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .35)), CssShadow(0, 1.5, 0, 0, Color(0xFFC23A0C))],
                                padding: const EdgeInsets.symmetric(horizontal: 7),
                                child: Center(child: Image.asset('assets/images/vipps_logo_hvit.png', height: 10, filterQuality: FilterQuality.medium)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          HbPress(
            dy: 3.5,
            onTap: onCta,
            child: CssBox(
              height: 54,
              radius: BorderRadius.circular(17),
              clip: true,
              bg: const [
                CssLinear(180, [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFE95C2C)], [0, .55, 1]),
              ],
              shadows: const [
                CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                CssShadow(0, 4, 0, 0, Color(0xFFA63A12)),
                CssShadow(0, 14, 20, -8, Color.fromRGBO(120, 40, 10, .6)),
              ],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // `width:{{ hbFyllW }}; transition: width 1s linear`.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: teller ? 1000 : 0),
                      curve: Curves.linear,
                      width: 366 * fyll,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC9501F), Color(0xFFA63A12)]),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    right: 10,
                    top: 2,
                    height: 54 * .46,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.elliptical(14, 14),
                            topRight: Radius.elliptical(14, 14),
                            bottomLeft: Radius.elliptical(30, 10),
                            bottomRight: Radius.elliptical(30, 10),
                          ),
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .32), Color.fromRGBO(255, 255, 255, 0)]),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (teller) const HbIkon(HbIkoner.omstart, size: 14, stroke: Colors.white, width: 3) else const HbIkon(HbIkoner.lyn, size: 14, fill: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        cta,
                        style: hbJ(
                          15,
                          color: Colors.white,
                          tabular: true,
                          shadows: const [Shadow(color: Color.fromRGBO(120, 40, 10, .4), offset: Offset(0, 1))],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          if (teller)
            Center(
              child: Text(
                HurtigCopy.betalesMedVipps,
                style: hbI(11.5, weight: FontWeight.w700, color: kHbInkSoft),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTilKurv,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HbIkon(HbIkoner.kurv, size: 13, stroke: kHbTeal, width: 2.6),
                  const SizedBox(width: 6),
                  Text(
                    HurtigCopy.leggIKurvenIStedet,
                    style: hbI(12, weight: FontWeight.w800, color: kHbTeal),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _linje(HbUtkastLinjeVis l) => CssBox(
    radius: BorderRadius.circular(16),
    bg: const [CssSolid(Color(0xFFFFFFFF))],
    shadows: _flat,
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.navn, maxLines: 2, overflow: TextOverflow.ellipsis, style: hbJ(13.5, em: -.01, height: 1.2)),
              const SizedBox(height: 3),
              Text(
                HurtigCopy.perStk(l.enhet),
                style: hbI(11, weight: FontWeight.w700, color: kHbInkFaint, tabular: true),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CssBox(
              height: 36,
              radius: BorderRadius.circular(999),
              bg: const [CssSolid(Color(0xFFE4ECED))],
              shadows: const [CssShadow.inset(0, 1.5, 3, 0, Color.fromRGBO(30, 60, 70, .24)), CssShadow(0, 1, 0, 0, Color(0xFFFFFFFF))],
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HbPress(
                    dy: 2,
                    onTap: l.onMinus,
                    child: CssBox(
                      width: 28,
                      height: 28,
                      radius: BorderRadius.circular(14),
                      bg: const [
                        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFEEF3F4)]),
                      ],
                      shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 2, 0, 0, Color(0xFFB5C4C8)), CssShadow(0, 4, 6, -3, Color.fromRGBO(30, 60, 70, .4))],
                      child: const Center(child: HbIkon(HbIkoner.minus, size: 11, stroke: kHbInk, width: 3.2)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 26,
                    child: Text('${l.ant}', textAlign: TextAlign.center, style: hbJ(14, tabular: true)),
                  ),
                  const SizedBox(width: 2),
                  HbPress(
                    dy: 2,
                    onTap: l.onPluss,
                    child: CssBox(
                      width: 28,
                      height: 28,
                      radius: BorderRadius.circular(14),
                      bg: const [
                        CssLinear(180, [Color(0xFF3A8296), Color(0xFF1E4F5C)]),
                      ],
                      shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)), CssShadow(0, 2, 0, 0, Color(0xFF0E2E36)), CssShadow(0, 4, 6, -3, Color.fromRGBO(4, 18, 26, .6))],
                      child: const Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: Colors.white, width: 3.2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(l.sum, style: hbJ(13, tabular: true)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _forslag(HbForslagVis f) => HbPress(
    dy: 2.5,
    onTap: f.onTap,
    child: CssBox(
      height: 34,
      radius: BorderRadius.circular(999),
      bg: const [
        CssLinear(180, [Color(0xFFFFFFFF), Color(0xFFF3F7F7)]),
      ],
      shadows: const [CssShadow.inset(0, 1, 0, 0, Color(0xFFFFFFFF)), CssShadow(0, 2.5, 0, 0, Color(0xFFC5D2D5)), CssShadow(0, 7, 10, -6, Color.fromRGBO(30, 60, 70, .4))],
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CssBox(
            width: 26,
            height: 26,
            radius: BorderRadius.circular(13),
            bg: const [
              CssLinear(180, [Color(0xFFFFA77C), Color(0xFFE95C2C)]),
            ],
            shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)), CssShadow(0, 1.5, 0, 0, Color(0xFFA63A12))],
            child: const Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: Colors.white, width: 3.4)),
          ),
          const SizedBox(width: 7),
          Text(f.navn, style: hbI(11.5, weight: FontWeight.w800, tabular: true)),
          const SizedBox(width: 7),
          Text(
            f.pris,
            style: hbI(11, weight: FontWeight.w800, color: kHbTeal, tabular: true),
          ),
        ],
      ),
    ),
  );
}

class HbUtkastLinjeVis {
  const HbUtkastLinjeVis({required this.navn, required this.enhet, required this.ant, required this.sum, required this.onMinus, required this.onPluss});
  final String navn;
  final String enhet;
  final int ant;
  final String sum;
  final VoidCallback onMinus;
  final VoidCallback onPluss;
}

class HbForslagVis {
  const HbForslagVis({required this.navn, required this.pris, required this.onTap});
  final String navn;
  final String pris;
  final VoidCallback onTap;
}

/// The habit / suggestion lines as text (shared by the cards).
String hbTekstLinjer(HurtigHjerne h, List<HbLinje> L, [String sep = ' + ']) => h.tekst(L, sep);
