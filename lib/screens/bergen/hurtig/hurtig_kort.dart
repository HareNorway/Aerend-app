import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/bergen_perf.dart';
import 'hurtig_bits.dart';
import 'hurtig_brain.dart';
import 'hurtig_copy.dart';
import 'hurtig_data.dart';
import 'hurtig_glass.dart';

// ── Hurtigbestilling · the module cards and the draft (new Bergen L4264–4535)
// New Bergen turned every card from white to dark glass and gave each its
// own layout: the favourite as a hero, store logos everywhere, the last order
// as a glass receipt with «TIDLIGERE» tiles, and «Slik kjenner Ægil deg» as
// a set of tiles. The cards span the chat's full width (`margin-left:-41px`).

const String _kOmIgjen = 'M20 11a8 8 0 1 0-2.3 5.7 M20 4v7h-7';
const String _kStjerne = 'M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.4 6.8 19.1l1-5.8L3.5 9.2l5.9-.9z';

/// «Hurtig · oftest bestilt» (L4264): «Din favoritt» as a hero card, the
/// rest as ranked rows with logos, and the habit of the day.
class HbOftestKort extends StatelessWidget {
  const HbOftestKort({super.key, required this.rader, required this.under, required this.vane, required this.onVelg, required this.onVane});

  final List<HbOftestVis> rader;
  final String under;
  final HbVaneVis? vane;
  final ValueChanged<int> onVelg;
  final VoidCallback onVane;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HbSeksjon(HurtigCopy.oftestBestilt, under: under),
      if (rader.isNotEmpty) ...[const SizedBox(height: 10), _topp(rader.first)],
      for (var i = 1; i < rader.length; i++) ...[const SizedBox(height: 10), HbFlisInn(delayMs: 180 + (i - 1) * 70, child: _rad(rader[i]))],
      if (vane != null) ...[const SizedBox(height: 10), _vane(vane!)],
    ],
  );

  Widget _leggKnapp(HbOftestVis r, {required bool bred}) {
    final Widget knapp = r.lagt
        ? VcKnapp(
            key: ValueKey('lagt-${r.id}'),
            ms: 350,
            child: CssBox(
              width: bred ? null : 40,
              height: 40,
              radius: BorderRadius.circular(13),
              bg: const [CssSolid(Color.fromRGBO(92, 224, 184, .16))],
              border: Border.all(color: const Color.fromRGBO(127, 240, 203, .5)),
              padding: bred ? const EdgeInsets.symmetric(horizontal: 17) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HbIkon(HbIkoner.hake, size: bred ? 13 : 15, stroke: kHbMintLys, width: 3.2),
                  if (bred) ...[
                    const SizedBox(width: 6),
                    Text(
                      HurtigCopy.lagtTilKnapp,
                      style: hbI(13.5, weight: FontWeight.w800, color: kHbMintLys),
                    ),
                  ],
                ],
              ),
            ),
          )
        : CssBox(
            key: ValueKey('legg-${r.id}'),
            width: bred ? null : 40,
            height: 40,
            radius: BorderRadius.circular(13),
            bg: kHbOransjeBg,
            shadows: hbOransjeSkygge(),
            padding: bred ? const EdgeInsets.symmetric(horizontal: 16) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HbIkon(HbIkoner.pluss, size: bred ? 13 : 15, stroke: Colors.white, width: 3),
                if (bred) ...[
                  const SizedBox(width: 6),
                  Text(
                    HurtigCopy.leggTilKnapp,
                    style: hbI(13.5, weight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ],
            ),
          );
    return Semantics(
      button: true,
      label: r.lagt ? HurtigCopy.fjernFraUtkastet : HurtigCopy.leggIUtkastet,
      child: HbPress(dy: 2, onTap: () => onVelg(r.id), child: knapp),
    );
  }

  Widget _topp(HbOftestVis r) => HbGlass(
    clip: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HbTint(
          farge: r.b.bg,
          height: 62,
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 10,
                child: HbBandChip(
                  bg: const [
                    CssLinear(180, [Color.fromRGBO(255, 224, 138, .3), Color.fromRGBO(242, 193, 78, .2)]),
                  ],
                  kant: const Color.fromRGBO(242, 193, 78, .55),
                  child: Row(
                    children: [
                      const HbIkon(_kStjerne, size: 11, fill: Color(0xFFF2C14E)),
                      const SizedBox(width: 4),
                      Text(
                        HurtigCopy.dinFavorittChip,
                        style: hbI(11, weight: FontWeight.w800, color: const Color(0xFFFFE2A0)),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: HbBandChip(
                  child: Row(
                    children: [
                      const HbIkon(_kOmIgjen, size: 11, stroke: kHbMintLys, width: 2.6),
                      const SizedBox(width: 4),
                      Text(
                        r.ganger,
                        style: hbI(11, weight: FontWeight.w800, color: Colors.white, tabular: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Overlapp(
                opp: 25,
                child: HbLogo(b: r.b, size: 50, radius: 16, ikon: 24, kant: 3, skygge: const [CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 10, 16, .9))]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 7),
                  Text(
                    r.navn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: hbJ(17, em: -.02, height: 1.2, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.butikk,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: hbI(12, color: const Color.fromRGBO(255, 255, 255, .66)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.pris, style: hbJ(19, em: -.02, color: Colors.white, tabular: true)),
                      ),
                      const SizedBox(width: 10),
                      _leggKnapp(r, bred: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rad(HbOftestVis r) => HbGlass(
    radius: 18,
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              HbLogo(b: r.b, size: 46, radius: 15, ikon: 22, skygge: const [CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18)), CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 10, 16, .9))]),
              Positioned(
                right: -5,
                bottom: -5,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF173E48),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22), width: 1.5),
                  ),
                  child: Text(
                    '${r.nr}',
                    style: hbI(10, weight: FontWeight.w800, color: Colors.white, tabular: true),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.navn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: hbI(14, weight: FontWeight.w800, em: -.01, color: Colors.white),
              ),
              const SizedBox(height: 1),
              Text(
                r.butikk,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: hbI(11.5, color: const Color.fromRGBO(255, 255, 255, .66)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    r.pris,
                    style: hbI(12.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .4)),
                  ),
                  const SizedBox(width: 6),
                  const HbIkon(_kOmIgjen, size: 10, stroke: kHbMintPale, width: 2.6),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      r.ganger,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: hbI(11, weight: FontWeight.w700, color: kHbMintPale, tabular: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _leggKnapp(r, bred: false),
      ],
    ),
  );

  Widget _vane(HbVaneVis v) => HbPress(
    scale: .99,
    ms: 140,
    onTap: onVane,
    child: HbGlass(
      radius: 20,
      padding: const EdgeInsets.all(12),
      kant: const Color.fromRGBO(255, 180, 142, .3),
      bg: const [
        CssRadial([Color.fromRGBO(255, 148, 102, .24), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: 1.3, cx: 1, cy: 0),
        ...kHbGlassBg,
      ],
      child: Row(
        children: [
          CssBox(
            width: 46,
            radius: BorderRadius.circular(12),
            clip: true,
            bg: const [CssSolid(Color.fromRGBO(10, 26, 34, .4))],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
            padding: const EdgeInsets.all(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFE95C2C)]),
                  ),
                  child: Text(
                    v.dag,
                    style: hbI(8.5, weight: FontWeight.w800, em: .12, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 6),
                  child: Text(
                    v.kl,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: hbJ(11.5, color: Colors.white, tabular: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.tittel,
                  style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbFersken),
                ),
                const SizedBox(height: 3),
                LfPretty(v.varer, style: hbJ(13, color: Colors.white, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CssBox(
            height: 44,
            radius: BorderRadius.circular(13),
            bg: kHbOransjeBg,
            shadows: hbOransjeSkygge(),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  HurtigCopy.settOpp,
                  style: hbI(12.5, weight: FontWeight.w800, color: Colors.white),
                ),
                Opacity(
                  opacity: .9,
                  child: Text(
                    v.sum,
                    style: hbI(10.5, weight: FontWeight.w700, color: Colors.white, tabular: true),
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

/// `margin-top:-N` on a tile that rides over the header band: it takes
/// [opp] px of the body and pokes the rest up over the band.
class _Overlapp extends StatelessWidget {
  const _Overlapp({required this.opp, required this.child});
  final double opp;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: opp,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -opp,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ],
    ),
  );
}

/// One «oftest» row as the card shows it.
class HbOftestVis {
  const HbOftestVis({required this.id, required this.nr, required this.navn, required this.butikk, required this.b, required this.ganger, required this.pris, required this.lagt});

  final int id;
  final int nr;
  final String navn;
  final String butikk;
  final HbButikk b;
  final String ganger;
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

/// «Hurtig · bestilt forrige gang» (L4307): the last order as a glass card
/// (logo, code · date, sum, «Levert», the lines, «Bestill det samme igjen»),
/// then the orders before it as «TIDLIGERE» tiles in a row.
class HbForrigeKort extends StatelessWidget {
  const HbForrigeKort({super.key, required this.fo, required this.tidligere, required this.onIgjen});

  final HbOrdreVis fo;
  final List<HbOrdreVis> tidligere;
  final ValueChanged<HbOrdreVis> onIgjen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HbSeksjon(HurtigCopy.bestiltForrigeGang, under: fo.dato),
      const SizedBox(height: 10),
      HbGlass(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HbLogo(b: fo.b, size: 48, radius: 15, ikon: 23, skygge: const [CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18)), CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 10, 16, .9))]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fo.butikk,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: hbI(15, weight: FontWeight.w800, em: -.01, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              fo.kode,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: hbI(12, color: const Color.fromRGBO(255, 255, 255, .66), tabular: true),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .45)),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              fo.dato,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: hbI(12, color: const Color.fromRGBO(255, 255, 255, .66)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fo.sum, style: hbJ(17, em: -.02, color: Colors.white, tabular: true)),
                    const SizedBox(height: 4),
                    CssBox(
                      height: 24,
                      radius: BorderRadius.circular(999),
                      bg: const [CssSolid(Color.fromRGBO(92, 224, 184, .14))],
                      border: Border.all(color: const Color.fromRGBO(92, 224, 184, .35)),
                      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: kHbMint),
                            child: const HbIkon(HbIkoner.hake, size: 10, stroke: Color(0xFF0F3A40), width: 3.2),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            HurtigCopy.levertChip,
                            style: hbI(11, weight: FontWeight.w800, color: kHbMintLys),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .1))),
              ),
              child: Column(
                children: [
                  for (final x in fo.linjer)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          CssBox(
                            height: 24,
                            radius: BorderRadius.circular(8),
                            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
                            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 14),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  x.ant,
                                  style: hbI(11, weight: FontWeight.w800, color: kHbMintPale, tabular: true),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              x.navn,
                              style: hbI(13, weight: FontWeight.w700, height: 1.3, color: const Color(0xFFDCE9EC), tabular: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            x.pris,
                            style: hbI(13, weight: FontWeight.w800, color: Colors.white, tabular: true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HbPress(
              dy: 2,
              onTap: () => onIgjen(fo),
              child: CssBox(
                height: 48,
                radius: BorderRadius.circular(15),
                bg: kHbOransjeBg,
                shadows: hbOransjeSkygge(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HbIkon(_kOmIgjen, size: 16, stroke: Colors.white, width: 2.6),
                    const SizedBox(width: 8),
                    Text(HurtigCopy.bestillDetSammeIgjen, style: hbJ(14.5, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (tidligere.isNotEmpty) ...[
        const SizedBox(height: 10),
        HbSeksjon(HurtigCopy.tidligere),
        const SizedBox(height: 10),
        // `margin:0 -16px; padding:0 16px 6px; overflow-x:auto`: the tiles
        // start at the column's edge and scroll past it, unclipped.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tidligere.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                HbFlisInn(delayMs: 150 + i * 80, child: _tidligere(tidligere[i])),
              ],
            ],
          ),
        ),
      ],
    ],
  );

  Widget _tidligere(HbOrdreVis t) => SizedBox(
    width: 168,
    child: HbGlass(
      radius: 20,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HbTint(
            farge: t.b.bg,
            height: 54,
            child: Stack(
              children: [
                Positioned(
                  right: 8,
                  top: 8,
                  child: HbBandChip(
                    h: 22,
                    pad: 8,
                    child: Text(
                      t.dato,
                      style: hbI(10.5, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Overlapp(
                  opp: 20,
                  child: HbLogo(b: t.b, size: 40, radius: 13, ikon: 19, kant: 3, skygge: const [CssShadow(0, 8, 14, -8, Color.fromRGBO(0, 10, 16, .9))]),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      t.butikk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: hbI(14, weight: FontWeight.w800, em: -.01, color: Colors.white),
                    ),
                    const SizedBox(height: 1),
                    SizedBox(
                      height: 31,
                      child: Text(
                        t.varer,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: hbI(11.5, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .7)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      button: true,
                      label: HurtigCopy.bestillIgjen,
                      child: HbPress(
                        dy: 2,
                        onTap: () => onIgjen(t),
                        child: CssBox(
                          height: 38,
                          radius: BorderRadius.circular(12),
                          bg: kHbOransjeBg,
                          shadows: hbOransjeSkygge(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HbIkon(_kOmIgjen, size: 13, stroke: Colors.white, width: 2.6),
                              const SizedBox(width: 6),
                              Text(
                                t.sum,
                                style: hbI(13, weight: FontWeight.w800, color: Colors.white, tabular: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// An order as the «forrige» card shows it.
class HbOrdreVis {
  const HbOrdreVis({required this.ordre, required this.butikk, required this.b, required this.sum, required this.dato, required this.varer, this.kode = '', this.linjer = const []});

  final HbOrdre ordre;
  final String butikk;
  final HbButikk b;
  final String sum;
  final String dato;
  final String varer;
  final String kode;
  final List<HbLinjeVis> linjer;
}

class HbLinjeVis {
  const HbLinjeVis(this.ant, this.navn, this.pris);
  final String ant;
  final String navn;
  final String pris;
}

/// «Hurtig · dine preferanser» (L4339): «Slik kjenner Ægil deg» with the
/// taste tiles and «Endre» (→ Min Bio), the favourite stores, the household
/// and allergy tiles, the dinner days, and «Ægil foreslår i kveld».
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
    required this.middagDager,
    required this.idag,
    required this.kl,
    required this.forslag,
    required this.onMinne,
  });

  final String under;
  final List<String> liker;
  final List<HbButikk> butikker;
  final int hus;
  final VoidCallback onHusMinus;
  final VoidCallback onHusPluss;
  final bool unngaaSkalldyr;
  final VoidCallback onSkalldyr;

  /// Dinner days, lower case, and today (`hbDag()`).
  final List<String> middagDager;
  final String idag;
  final String kl;

  /// «Ægil foreslår i kveld» (null: nothing to suggest yet).
  final HbPrefForslagVis? forslag;
  final VoidCallback onMinne;

  static const String _ikButikk = 'M4 9l1.5-5h13L20 9 M4 9h16v11H4z M9 20v-6h6v6';
  static const String _ikHus = 'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z M2.5 20a6.5 6.5 0 0 1 13 0 M16 4.5a3.5 3.5 0 0 1 0 6.5 M18 14.5a6 6 0 0 1 3.5 5.5';
  static const String _ikSkjold = 'M12 3l8 3v6c0 4.5-3.4 8-8 9-4.6-1-8-4.5-8-9V6z';
  static const String _ikKlokke = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z M12 7v5l3 2';
  static const String _ikKort = 'M3 6h18v13H3z M3 10.5h18';
  static const String _ikSkaal = 'M3 13h18a9 9 0 0 1-18 0z M12 4v3';
  static const String _ikBlyant = 'M4 20h4L19 9l-4-4L4 16z M14 6l4 4';
  static const String _ikPerson = 'M10 1.8a4.2 4.2 0 1 0 0 8.4a4.2 4.2 0 1 0 0-8.4M2 22.5c0-4.9 3.6-8.5 8-8.5s8 3.6 8 8.5z';

  /// `grid-template-columns: repeat(auto-fill, minmax(86px, 1fr)); gap: 8px`.
  static Widget _rutenett(double w, List<Widget> barn, {double min = 86, double gap = 8}) {
    final n = ((w + gap) / (min + gap)).floor().clamp(1, 99);
    final bw = (w - gap * (n - 1)) / n;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final b in barn) SizedBox(width: bw, child: b)],
    );
  }

  Widget _hode(String ik, String tittel, {bool fersken = false, Widget? hoyre}) => Row(
    children: [
      HbHodeIkon(ik, fersken: fersken),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          tittel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: hbI(12.5, weight: FontWeight.w800, color: Colors.white),
        ),
      ),
      if (hoyre != null) ...[const SizedBox(width: 8), hoyre],
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HbSeksjon(HurtigCopy.dinePreferanser, under: under),
      const SizedBox(height: 10),
      HbFlisInn(delayMs: 100, child: _kjenner()),
      if (butikker.isNotEmpty) ...[const SizedBox(height: 10), HbFlisInn(delayMs: 200, child: _butikker())],
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: HbFlisInn(delayMs: 280, child: _husstand())),
            const SizedBox(width: 10),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('sk-$unngaaSkalldyr'),
                child: HbFlisInn(delayMs: unngaaSkalldyr ? 340 : 100, child: _allergi()),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      HbFlisInn(delayMs: 400, child: _rytme()),
      if (forslag != null) ...[const SizedBox(height: 10), _Forslag(f: forslag!)],
    ],
  );

  Widget _kjenner() => HbGlass(
    radius: 24,
    clip: true,
    bg: const [
      CssRadial([Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .6], rx: .8, ry: .9, cx: 0, cy: 0),
      ...kHbGlassBg,
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(left: -3, top: -3, right: -3, bottom: -3, child: ClipOval(child: HbSkannRing())),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: kHbKant),
                        padding: const EdgeInsets.all(2),
                        child: const HbAegilFjes(size: 48, topp: -.06),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: 1,
                      child: HbPusteDot(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kHbMint,
                            border: Border.all(color: kHbKant, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(HurtigCopy.slikKjenner, style: hbJ(16, em: -.02, height: 1.2, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(under, style: hbI(12, color: const Color.fromRGBO(255, 255, 255, .66))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HbPress(
                key: const Key('hb-pref-endre'),
                scale: .95,
                onTap: onMinne,
                child: CssBox(
                  height: 32,
                  radius: BorderRadius.circular(999),
                  bg: const [CssSolid(Color.fromRGBO(92, 224, 184, .14))],
                  border: Border.all(color: const Color.fromRGBO(127, 240, 203, .4)),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HbIkon(_ikBlyant, size: 12, stroke: kHbMintPale, width: 2.6),
                      const SizedBox(width: 5),
                      Text(
                        HurtigCopy.endre,
                        style: hbI(12, weight: FontWeight.w800, color: kHbMintPale),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (liker.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HurtigCopy.duLikerKicker,
                  style: hbI(10.5, weight: FontWeight.w800, em: .12, color: const Color.fromRGBO(255, 255, 255, .55)),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, box) => _rutenett(box.maxWidth, [for (var i = 0; i < liker.length; i++) HbFlisInn(delayMs: 180 + i * 70, child: _smak(liker[i], i))]),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _smak(String t, int i) => HbTenn(
    delayMs: 1200 + i * 900,
    builder: (lys) => CssBox(
      radius: BorderRadius.circular(16),
      bg: const [
        CssLinear(180, [Color.fromRGBO(92, 224, 184, .14), Color.fromRGBO(92, 224, 184, .04)]),
      ],
      border: Border.all(color: Color.lerp(const Color.fromRGBO(127, 240, 203, .3), const Color.fromRGBO(127, 240, 203, .9), lys)!),
      shadows: lys > 0 ? [CssShadow(0, 0, 14, 1, Color.fromRGBO(92, 224, 184, .5 * lys))] : const [],
      padding: const EdgeInsets.fromLTRB(7, 13, 7, 11),
      child: Column(
        children: [
          CssBox(
            width: 40,
            height: 40,
            radius: BorderRadius.circular(20),
            bg: const [
              CssLinear(160, [Color(0xFF8CF0D2), Color(0xFF3CC79F)]),
            ],
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .55)), CssShadow(0, 6, 12, -6, Color.fromRGBO(60, 199, 159, .8))],
            child: Center(child: HbIkon(hbSmakIkon(t), size: 20, stroke: const Color(0xFF0F3A40), width: 2.2)),
          ),
          const SizedBox(height: 7),
          Text(
            t,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: hbI(12.5, weight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _butikker() => HbGlass(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hode(
          _ikButikk,
          HurtigCopy.favorittbutikker,
          hoyre: Text(
            HurtigCopy.lagret(butikker.length),
            style: hbI(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55)),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) => _rutenett(box.maxWidth, [
            for (var i = 0; i < butikker.length; i++)
              HbFlisInn(
                delayMs: 260 + i * 70,
                child: Column(
                  children: [
                    HbLogo(
                      b: butikker[i],
                      size: 52,
                      radius: 17,
                      ikon: 24,
                      skygge: const [CssShadow(0, 0, 0, 2, Color.fromRGBO(127, 240, 203, .28)), CssShadow(0, 10, 16, -8, Color.fromRGBO(0, 10, 16, .9))],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      butikker[i].navn,
                      textAlign: TextAlign.center,
                      style: hbI(12, weight: FontWeight.w800, height: 1.25, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ]),
        ),
      ],
    ),
  );

  Widget _husstand() => HbGlass(
    padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hode(_ikHus, HurtigCopy.husstand),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$hus', style: hbJ(30, em: -.03, height: 1, color: Colors.white, tabular: true)),
            const SizedBox(width: 5),
            Text(
              HurtigCopy.personOrd(hus),
              style: hbI(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 8; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              i < hus ? HbPop(key: ValueKey('p$i-on'), delayMs: 350 + i * 50, child: const _Figur(on: true)) : const _Figur(on: false),
            ],
          ],
        ),
        const SizedBox(height: 10),
        const Spacer(),
        Row(
          children: [
            Expanded(child: _steg(HbIkoner.minus, HurtigCopy.faerre, onHusMinus)),
            const SizedBox(width: 6),
            Expanded(child: _steg(HbIkoner.pluss, HurtigCopy.flere, onHusPluss)),
          ],
        ),
      ],
    ),
  );

  Widget _steg(String ik, String navn, VoidCallback onTap) => Semantics(
    button: true,
    label: navn,
    child: HbPress(
      scale: .9,
      onTap: onTap,
      child: CssBox(
        height: 34,
        radius: BorderRadius.circular(11),
        bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
        child: Center(child: HbIkon(ik, size: 13, stroke: kHbMintPale, width: 3)),
      ),
    ),
  );

  Widget _allergi() {
    final u = unngaaSkalldyr;
    return HbPress(
      scale: .98,
      ms: 140,
      onTap: onSkalldyr,
      child: HbGlass(
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
        clip: true,
        kant: u ? const Color.fromRGBO(255, 180, 142, .32) : const Color.fromRGBO(255, 255, 255, .16),
        bg: u
            ? const [
                CssRadial([Color.fromRGBO(255, 148, 102, .26), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .65], rx: 1, ry: .8, cx: 1, cy: 0),
                ...kHbGlassBg,
              ]
            : kHbGlassBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hode(_ikSkjold, HurtigCopy.allergier, fersken: u),
            const SizedBox(height: 11),
            Text(
              u ? HurtigCopy.unngaarKicker : HurtigCopy.tillattKicker,
              style: hbI(10.5, weight: FontWeight.w800, em: .12, color: u ? kHbFersken : kHbMintLys),
            ),
            const SizedBox(height: 2),
            Text(HurtigCopy.skalldyr, style: hbJ(19, em: -.02, color: Colors.white)),
            const SizedBox(height: 2),
            Text(u ? HurtigCopy.holdesUnna : HurtigCopy.kanKomme, style: hbI(11, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .66))),
            const SizedBox(height: 10),
            const Spacer(),
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      HurtigCopy.trykkForAaEndre,
                      style: hbI(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CssBox(
                    width: 42,
                    height: 24,
                    radius: BorderRadius.circular(999),
                    bg: u
                        ? const [
                            CssLinear(180, [Color(0xFFF9A273), Color(0xFFE95C2C)]),
                          ]
                        : const [CssSolid(Color.fromRGBO(255, 255, 255, .16))],
                    shadows: u ? const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4))] : const [CssShadow.inset(0, 1, 2, 0, Color.fromRGBO(0, 0, 0, .25))],
                    child: Align(
                      alignment: u ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .25), offset: Offset(0, 2), blurRadius: 4 / 2 / .57735)],
                        ),
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

  Widget _rytme() => HbGlass(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hode(
          _ikKlokke,
          HurtigCopy.middagsrytme,
          hoyre: CssBox(
            height: 24,
            radius: BorderRadius.circular(999),
            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              widthFactor: 1,
              child: Text(
                HurtigCopy.rundtKl(kl),
                style: hbI(11.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[if (i > 0) const SizedBox(width: 5), Expanded(child: _dag(i))],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .08))),
          ),
          child: Row(
            children: [
              const HbHodeIkon(_ikKort),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HurtigCopy.betaling,
                      style: hbI(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .55)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      HurtigCopy.vippsPaaDora,
                      style: hbI(13, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kHbMint),
                child: const HbIkon(HbIkoner.hake, size: 11, stroke: Color(0xFF0F3A40), width: 3.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dag(int i) {
    final navn = HurtigCopy.dagerNo[i];
    final on = middagDager.contains(navn);
    final iDag = idag == navn;
    final k = HurtigCopy.dagKort(i);
    final Widget flis = on
        ? HbPop(
            key: ValueKey('d$i-on'),
            delayMs: 450 + i * 50,
            ms: 450,
            child: CssBox(
              height: 46,
              radius: BorderRadius.circular(13),
              bg: kHbOransjeBg,
              shadows: hbOransjeSkygge(dyp: 10, blur: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    k,
                    style: hbI(11.5, weight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const HbIkon(_ikSkaal, size: 12, stroke: Colors.white, width: 2.4),
                ],
              ),
            ),
          )
        : CssBox(
            key: ValueKey('d$i-av'),
            height: 46,
            radius: BorderRadius.circular(13),
            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .05))],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .1)),
            child: Center(
              child: Text(
                k,
                style: hbI(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .5)),
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        flis,
        const SizedBox(height: 5),
        SizedBox(
          height: 6,
          child: iDag
              ? OverflowBox(
                  maxHeight: 20,
                  child: Text(
                    HurtigCopy.iDagKicker,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: hbI(9, weight: FontWeight.w800, em: .06, color: kHbMintLys),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _Figur extends StatelessWidget {
  const _Figur({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 13,
    height: 15,
    child: FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 24 * 20 / 24,
        height: 24,
        child: HbIkon(HbPrefKort._ikPerson, size: 24, fill: on ? kHbMintLys : const Color.fromRGBO(255, 255, 255, .16)),
      ),
    ),
  );
}

/// What «Ægil foreslår i kveld» shows.
class HbPrefForslagVis {
  const HbPrefForslagVis({required this.linje, required this.butikk, required this.grunner, required this.sum, required this.retter, required this.wok, required this.onTap, this.bilde});

  final String linje;
  final String butikk;
  final List<String> grunner;
  final String sum;
  final int retter;

  /// `/wok|thai/` picks the warm tint and the bowl.
  final bool wok;

  /// The main dish's photo, when the menu has one.
  final String? bilde;
  final VoidCallback onTap;
}

/// «ÆGIL FORESLÅR I KVELD» (L4401): a picture band (the dish, else the
/// design's tint with its icon), Ægil, the store, the dish line, the reasons
/// and «Sett opp · sum».
class _Forslag extends StatelessWidget {
  const _Forslag({required this.f});
  final HbPrefForslagVis f;

  static const String _ikWok = 'M4 11h16a8 8 0 0 1-16 0z M9 7l6-4 M12 7l6-3';
  static const String _ikFisk = 'M3 12c3-4 8-5 12-3l4-3v12l-4-3c-4 2-9 1-12-3z M15.5 11v.01';

  Widget _chip(BuildContext context, Widget child, Color kant) {
    final Widget c = CssBox(
      height: 26,
      radius: BorderRadius.circular(999),
      bg: const [CssSolid(Color.fromRGBO(10, 26, 34, .55))],
      border: Border.all(color: kant),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
    );
    if (!BergenPerf.blurOn(context, secondary: true)) return c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = f.bilde;
    return HbGlass(
      clip: true,
      kant: const Color.fromRGBO(255, 180, 142, .3),
      bg: const [
        CssRadial([Color.fromRGBO(255, 148, 102, .22), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: 1.2, cx: 1, cy: 0),
        ...kHbGlassBg,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 156,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(.4, -.4),
                      radius: .8,
                      colors: f.wok ? const [Color(0xFFE0A050), Color(0xFF8A5A1E)] : const [Color(0xFF6FA3B2), Color(0xFF2A6272)],
                      stops: const [0, .7],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromRGBO(255, 255, 255, .16),
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .28)),
                      ),
                      child: HbIkon(f.wok ? _ikWok : _ikFisk, size: 40, stroke: Colors.white, width: 1.8),
                    ),
                  ),
                ),
                if (url != null && url.isNotEmpty)
                  // `bpKB 16s ease-in-out infinite alternate` (rests in lite / still).
                  LfLoop(
                    builder: (context, t, child) {
                      final ping = (t / 16000) % 2;
                      final p = cssEaseInOut.transform(ping <= 1 ? ping : 2 - ping);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scaleByDouble(1.04 + .13 * p, 1.04 + .13 * p, 1, 1)
                          ..translateByDouble(-.025 * 360 * p, -.02 * 156 * p, 0, 1),
                        child: child,
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: url,
                      memCacheWidth: BergenPerf.decodeWidth,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromRGBO(10, 26, 34, .38), Color.fromRGBO(10, 26, 34, 0), Color.fromRGBO(10, 26, 34, 0), Color.fromRGBO(23, 62, 72, .85)],
                        stops: [0, .34, .58, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _chip(
                    context,
                    Row(
                      children: [
                        const HbIkon(HbIkoner.lyn, size: 11, fill: kHbFersken),
                        const SizedBox(width: 5),
                        Text(
                          HurtigCopy.foreslaarIKveld,
                          style: hbI(10.5, weight: FontWeight.w800, em: .1, color: kHbFersken),
                        ),
                      ],
                    ),
                    const Color.fromRGBO(255, 180, 142, .4),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _chip(
                    context,
                    Text(
                      HurtigCopy.retter(f.retter),
                      style: hbI(11.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
                    ),
                    const Color.fromRGBO(255, 255, 255, .22),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Overlapp(
                  opp: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kHbKant,
                          boxShadow: [
                            BoxShadow(color: Color.fromRGBO(127, 240, 203, .6), spreadRadius: 2),
                            BoxShadow(color: Color.fromRGBO(0, 10, 16, .8), offset: Offset(0, 8), blurRadius: 12 / 2 / .57735, spreadRadius: -6),
                          ],
                        ),
                        child: const HbAegilFjes(size: 42),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            f.butikk,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: hbI(11.5, color: const Color.fromRGBO(255, 255, 255, .66)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    LfPretty(f.linje, style: hbJ(15.5, em: -.01, height: 1.3, color: Colors.white)),
                    if (f.grunner.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final g in f.grunner)
                            CssBox(
                              height: 24,
                              radius: BorderRadius.circular(999),
                              bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
                              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kHbMint),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    g,
                                    style: hbI(11, weight: FontWeight.w700, color: const Color(0xFFDCE9EC)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    HbPress(
                      dy: 2,
                      onTap: f.onTap,
                      child: CssBox(
                        height: 46,
                        radius: BorderRadius.circular(14),
                        bg: kHbOransjeBg,
                        shadows: hbOransjeSkygge(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const HbIkon(HbIkoner.lyn, size: 13, fill: Colors.white),
                            const SizedBox(width: 7),
                            Text(HurtigCopy.settOppSum(f.sum), style: hbJ(14, color: Colors.white, tabular: true)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Hurtig · bestilt» (L4435): the confirmation inside the chat, in glass
/// with a mint border.
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
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(22),
    bg: const [
      CssLinear(180, [Color.fromRGBO(255, 255, 255, .09), Color.fromRGBO(255, 255, 255, .04)]),
    ],
    border: Border.all(color: const Color.fromRGBO(127, 240, 203, .4)),
    shadows: const [CssShadow(0, 18, 30, -20, Color.fromRGBO(0, 10, 16, .9))],
    padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kHbMint,
                boxShadow: [
                  BoxShadow(color: Color(0xFF23946F), offset: Offset(0, 3)),
                  BoxShadow(color: Color.fromRGBO(20, 110, 80, .7), offset: Offset(0, 10), blurRadius: 16 / 2 / .57735, spreadRadius: -8),
                ],
              ),
              child: const HbIkon(HbIkoner.hake, size: 19, stroke: Color(0xFF0F3A40), width: 3.2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HurtigCopy.bestiltKode(kode),
                    style: hbI(10, weight: FontWeight.w800, em: .1, color: kHbMintLys),
                  ),
                  const SizedBox(height: 1),
                  Text(butikk, style: hbJ(15.5, em: -.01, color: Colors.white)),
                  Text(klar, style: hbI(11.5, color: const Color.fromRGBO(255, 255, 255, .6))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LfPretty(linje, style: hbI(12, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .7))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .08))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(92, 224, 184, .14)),
                child: Text(
                  kr,
                  style: hbI(10.5, weight: FontWeight.w800, color: kHbMintLys),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(HurtigCopy.vipps, style: hbI(11, color: const Color.fromRGBO(255, 255, 255, .6))),
                  const SizedBox(width: 6),
                  Text(sum, style: hbJ(16, color: Colors.white, tabular: true)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HbPress(
          scale: .98,
          onTap: onFolg,
          child: CssBox(
            height: 44,
            radius: BorderRadius.circular(14),
            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .08))],
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  HurtigCopy.folgBestillingen,
                  style: hbI(13.5, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 7),
                const HbIkon(HbIkoner.videre, size: 13, stroke: kHbMintLys, width: 2.8),
              ],
            ),
          ),
        ),
      ],
    ),
  );
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

  static const Color _svak = Color.fromRGBO(255, 255, 255, .66);
  static const Border _kant = Border.fromBorderSide(BorderSide(color: Color.fromRGBO(255, 255, 255, .08)));

  Widget _rund(Widget icon) => Container(
    width: 28,
    height: 28,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(92, 224, 184, .12)),
    child: Center(child: icon),
  );

  @override
  Widget build(BuildContext context) {
    // The fill grows one second per tick, from 20 % at 5 s to 100 % at 1 s.
    final fyll = teller ? ((6 - tellerSek) / 5).clamp(0.0, 1.0) : 0.0;
    return CssBox(
      radius: BorderRadius.circular(26),
      bg: const [
        CssLinear(180, [Color.fromRGBO(255, 255, 255, .09), Color.fromRGBO(255, 255, 255, .04)]),
      ],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .1)),
      shadows: const [CssShadow(0, 22, 34, -20, Color.fromRGBO(0, 10, 16, .9))],
      padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
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
                          const HbIkon(HbIkoner.lyn, size: 10, fill: Color(0xFFFF9466)),
                          const SizedBox(width: 5),
                          Text(
                            HurtigCopy.aegilsUtkast,
                            style: hbI(10, weight: FontWeight.w800, em: .12, color: kHbFersken),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        butikk,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: hbJ(16, em: -.015, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const HbIkon(HbIkoner.klokke, size: 11, stroke: kHbMintPale, width: 2.6),
                          const SizedBox(width: 5),
                          Text(
                            klar,
                            style: hbI(11, weight: FontWeight.w700, color: _svak, tabular: true),
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
                    style: hbI(10, weight: FontWeight.w800, em: .12, color: _svak),
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
            bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .14))],
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.varer,
                      style: hbI(12, weight: FontWeight.w700, color: _svak),
                    ),
                    Text(
                      varer,
                      style: hbI(12, weight: FontWeight.w700, color: _svak, tabular: true),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.levering,
                      style: hbI(12, weight: FontWeight.w700, color: _svak),
                    ),
                    if (levGratis)
                      CssBox(
                        radius: BorderRadius.circular(999),
                        bg: const [CssSolid(Color.fromRGBO(92, 224, 184, .14))],
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                        child: Text(
                          HurtigCopy.gratis,
                          style: hbI(11, weight: FontWeight.w800, color: kHbMintLys),
                        ),
                      )
                    else
                      Text(
                        lev,
                        style: hbI(12, weight: FontWeight.w700, color: _svak, tabular: true),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: const Color.fromRGBO(255, 255, 255, .1)),
                        child: Stack(
                          children: [
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
                                    levGratis ? const CssLinear(180, [Color(0xFF8CF0D2), Color(0xFF2FB893)]) : const CssLinear(90, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
                                  ],
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
                      style: hbI(10.5, weight: FontWeight.w800, color: levGratis ? kHbMintLys : kHbFersken),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color.fromRGBO(255, 255, 255, .08)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      HurtigCopy.totalt,
                      style: hbI(13, weight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(total, style: hbJ(22, em: -.03, color: Colors.white, tabular: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CssBox(
            radius: BorderRadius.circular(14),
            bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .05))],
            border: _kant,
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
            child: Row(
              children: [
                _rund(const HbIkon(HbIkoner.pin, size: 13, fill: kHbMintPale)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HurtigCopy.leveresTil,
                        style: hbI(9.5, weight: FontWeight.w800, color: _svak),
                      ),
                      Text(
                        adresse,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: hbI(12.5, weight: FontWeight.w800, color: Colors.white),
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
                      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .05))],
                      border: Border.all(color: const Color.fromRGBO(127, 240, 203, .3)),
                      padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
                      child: Row(
                        children: [
                          _rund(const HbIkon(HbIkoner.klokke, size: 13, stroke: kHbMintPale, width: 2.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  HurtigCopy.naar,
                                  style: hbI(9.5, weight: FontWeight.w800, color: kHbMintPale),
                                ),
                                Text(
                                  tid,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: hbI(12.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const HbIkon(HbIkoner.tidBytt, size: 12, stroke: kHbMintPale, width: 2.8),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CssBox(
                    radius: BorderRadius.circular(14),
                    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .05))],
                    border: _kant,
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                    child: Row(
                      children: [
                        _rund(const HbIkon(HbIkoner.kort, size: 13, stroke: kHbMintPale, width: 2.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                HurtigCopy.betaling,
                                style: hbI(9.5, weight: FontWeight.w800, color: _svak),
                              ),
                              const SizedBox(height: 2),
                              CssBox(
                                height: 19,
                                radius: BorderRadius.circular(6),
                                bg: const [CssSolid(Color(0xFFFF5B24))],
                                shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .35)), CssShadow(0, 1.5, 0, 0, Color(0xFFC23A0C))],
                                padding: const EdgeInsets.symmetric(horizontal: 7),
                                child: Center(widthFactor: 1, child: Image.asset('assets/images/vipps_logo_hvit.png', height: 10, filterQuality: FilterQuality.medium)),
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
                style: hbI(11.5, weight: FontWeight.w700, color: _svak),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTilKurv,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HbIkon(HbIkoner.kurv, size: 13, stroke: kHbMintPale, width: 2.6),
                  const SizedBox(width: 6),
                  Text(
                    HurtigCopy.leggIKurvenIStedet,
                    style: hbI(12, weight: FontWeight.w800, color: kHbMintPale),
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
    bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .05))],
    border: _kant,
    padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.navn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: hbJ(13.5, em: -.01, height: 1.2, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                HurtigCopy.perStk(l.enhet),
                style: hbI(11, weight: FontWeight.w700, color: _svak, tabular: true),
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
              bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .18))],
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HbPress(
                    dy: 2,
                    onTap: l.onMinus,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .1)),
                      child: const Center(child: HbIkon(HbIkoner.minus, size: 11, stroke: kHbMintPale, width: 3.2)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${l.ant}',
                      textAlign: TextAlign.center,
                      style: hbJ(14, color: Colors.white, tabular: true),
                    ),
                  ),
                  const SizedBox(width: 2),
                  HbPress(
                    dy: 2,
                    onTap: l.onPluss,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .1)),
                      child: const Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: kHbMintPale, width: 3.2)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(l.sum, style: hbJ(13, color: Colors.white, tabular: true)),
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
      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .07))],
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .1)),
      padding: const EdgeInsets.fromLTRB(5, 0, 13, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CssBox(
            width: 26,
            height: 26,
            radius: BorderRadius.circular(13),
            bg: const [
              CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
            ],
            child: const Center(child: HbIkon(HbIkoner.pluss, size: 11, stroke: Colors.white, width: 3.4)),
          ),
          const SizedBox(width: 7),
          Text(
            f.navn,
            style: hbI(11.5, weight: FontWeight.w800, color: Colors.white, tabular: true),
          ),
          const SizedBox(width: 7),
          Text(
            f.pris,
            style: hbI(11, weight: FontWeight.w800, color: kHbMintPale, tabular: true),
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
