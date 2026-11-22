import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../game/fjordlopet/haptics/game_haptics.dart';
import '../../../game/fjordlopet/haptics/haptikk_moenster.dart';
import '../kit/ae_primitiver.dart' show aeMyk;
import '../kit/bergen_kit.dart';
import 'lopet_copy.dart';
import 'lopet_data.dart';
import 'lopet_screen.dart' show LopetSjokortMaler, LopetSjokortStor;

/// Design 21 Nov plan Step 7 (design `Fjordløpet · Start`): the quay's pieces and its two sheets.
///
/// - [LopetLosgrad]: the losgrad pill with the anchor, its bar and «13 760 m til Styrmann».
/// - [LopetKaiSjokort]: «SJØKORTET · SEILT 516 M», the week's course left to right up to the best distance (fog after
///   it, «Tåke · seil lenger for å se mer»), the gate chips («✓ Bøye 1 +3» / «Bryggen +12»), «Din beste» and «Ukens
///   beste»; a tap opens the full chart.
/// - [LopetMaalFlis] (NESTE MÅL) and [LopetListeFlis] (UKELISTEN), [LopetBoyer] (the life rings, «3 seilaser igjen»,
///   «+ redningsvest»), [LopetPyntKnapp] (the corner button on the scene).
/// - [LopetPyntArk]: «Pynt på båten», three groups × three tiles, locked «Ta Kassejeger», stars, the chosen one ringed.

const Color _mint = Color(0xFF7FF0CB);
const Color _gull = Color(0xFFF2C14E);
const Color _gullLys = Color(0xFFFFE3A3);

BoxDecoration lopetKort({double r = 22}) => BoxDecoration(
  borderRadius: BorderRadius.circular(r),
  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .08), Color.fromRGBO(255, 255, 255, .04)]),
  border: Border.all(color: const Color.fromRGBO(255, 255, 255, .12)),
);

TextStyle _kicker(Color c) => BergenTokens.text(12, weight: FontWeight.w800, color: c).copyWith(letterSpacing: 1.1);

/// The pill with the anchor and the losgrad, the thin bar and the metres to the next.
class LopetLosgrad extends StatelessWidget {
  const LopetLosgrad({super.key, required this.s});
  final LopetState s;

  @override
  Widget build(BuildContext context) {
    final neste = s.losgradNesteM;
    final fra = neste == null ? 0 : _forrigeTerskel(s);
    final pct = neste == null ? 1.0 : ((s.lifetimeM - fra) / math.max(1, neste - fra)).clamp(0.0, 1.0);
    return SizedBox(
      width: 128,
      child: Column(
        key: const Key('lopet-losgrad'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            height: 30,
            width: 128,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(242, 193, 78, .1), border: Border.all(color: const Color.fromRGBO(242, 193, 78, .55))),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.anchor_rounded, size: 14, color: _gull),
                const SizedBox(width: 6),
                Text(s.losgrad, style: BergenTokens.text(13, weight: FontWeight.w800, color: _gullLys)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .12))),
                FractionallySizedBox(widthFactor: math.max(.03, pct), child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE0A92C), _gullLys])))),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            neste == null ? LopetCopy.gradHoyeste : LopetCopy.gradNeste(math.max(0, neste - s.lifetimeM), s.losgradNeste ?? ''),
            key: const Key('lopet-losgrad-neste'),
            textAlign: TextAlign.right,
            style: BergenTokens.text(11, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7)),
          ),
        ],
      ),
    );
  }

  /// The current losgrad's threshold is not on the state; the bar runs from 0 when it is unknown.
  static int _forrigeTerskel(LopetState s) => 0;
}

class LopetKaiSjokort extends StatelessWidget {
  const LopetKaiSjokort({super.key, required this.s, required this.besteM, this.stoppM});
  final LopetState s;
  final int besteM;

  /// The end card (Design 21 Nov Step 8): where this run stopped — «STOPPET VED 317 M» and the cross on the chart.
  final int? stoppM;

  static const int _visM = 1200;

  @override
  Widget build(BuildContext context) {
    final ms = s.milestones;
    final pts = [s.rewards['buoy1'], s.rewards['buoy2'], s.rewards['quay']].map((v) => (v as num?)?.toInt() ?? 0).toList();
    return GestureDetector(
      key: stoppM == null ? const Key('lopet-sjokort') : const Key('lopet-slutt-sjokort'),
      behavior: HitTestBehavior.opaque,
      onTap: () => LopetSjokortStor.vis(context, s, besteM),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: lopetKort(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.explore_outlined, size: 16, color: Color.fromRGBO(255, 255, 255, .7)),
              const SizedBox(width: 8),
              Expanded(child: Text(LopetCopy.sjokort.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _kicker(const Color.fromRGBO(255, 255, 255, .78)))),
              const SizedBox(width: 8),
              Flexible(child: Text(stoppM != null ? LopetCopy.stoppet(stoppM!) : besteM > 0 ? LopetCopy.seilt(besteM) : LopetCopy.altTake, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: _kicker(const Color.fromRGBO(255, 255, 255, .78)))),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_full_rounded, size: 15, color: _mint),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth;
                double x(int m) => (m / _visM).clamp(0.0, 1.0) * w;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E5A55), Color(0xFF1F4A4E)])),
                          // A quarter turn clockwise: the chart's start (its bottom) on the left, the fog to the right, as the design.
                          child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: LopetSjokortMaler(s: s, besteM: besteM, visM: _visM, merker: [if (stoppM != null) stoppM!]))),
                        ),
                      ),
                    ),
                    if (besteM < _visM)
                      Positioned(
                        left: x(besteM) + 8,
                        right: 6,
                        top: 18,
                        bottom: 0,
                        child: Center(child: Text(LopetCopy.take, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: BergenTokens.text(11, weight: FontWeight.w700, color: const Color(0xFF2A4C55)))),
                      ),
                    for (var k = 0; k < ms.length && k < 3; k++)
                      if (ms[k] <= _visM)
                        Positioned(
                          left: (x(ms[k]) - 34).clamp(0.0, w - 72),
                          top: 0,
                          child: _PortChip(navn: LopetCopy.porter[k], poeng: pts[k], naadd: besteM >= ms[k]),
                        ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [
              _Prikk(farge: _mint),
              const SizedBox(width: 6),
              Text(LopetCopy.dinBeste, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .78))),
              const SizedBox(width: 6),
              Text(besteM > 0 ? '${LopetCopy.tallTekst(besteM)} m' : '—', key: const Key('lopet-din-beste'), style: BergenTokens.display(16, weight: FontWeight.w800, color: _mint)),
              const SizedBox(width: 24),
              _Prikk(farge: _gull),
              const SizedBox(width: 6),
              Text(LopetCopy.ukensBeste, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .78))),
              const SizedBox(width: 6),
              Text(s.weekBestM == null ? '—' : '${LopetCopy.tallTekst(s.weekBestM!)} m', key: const Key('lopet-ukens-beste'), style: BergenTokens.display(16, weight: FontWeight.w800, color: _gull)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  const _PortChip({required this.navn, required this.poeng, required this.naadd});
  final String navn;
  final int poeng;
  final bool naadd;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: naadd ? const Color.fromRGBO(127, 240, 203, .9) : const Color.fromRGBO(10, 30, 36, .85),
      border: Border.all(color: naadd ? _mint : _gull),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (naadd) ...[const Icon(Icons.check_rounded, size: 12, color: Color(0xFF0F3540)), const SizedBox(width: 3)],
      Text('$navn +$poeng', style: BergenTokens.text(10.5, weight: FontWeight.w800, color: naadd ? const Color(0xFF0F3540) : _gullLys)),
    ]),
  );
}

class _Prikk extends StatelessWidget {
  const _Prikk({required this.farge});
  final Color farge;
  @override
  Widget build(BuildContext context) => Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: farge, boxShadow: [BoxShadow(color: farge.withValues(alpha: .5), blurRadius: 6)]));
}

/// NESTE MÅL: the next gate (its points), else the week's best («1. plass»), else «Du leder uken» («Hold plassen»).
class LopetMaalFlis extends StatelessWidget {
  const LopetMaalFlis({super.key, required this.s, required this.besteM});
  final LopetState s;
  final int besteM;

  @override
  Widget build(BuildContext context) {
    final ms = s.milestones;
    final pts = [s.rewards['buoy1'], s.rewards['buoy2'], s.rewards['quay']].map((v) => (v as num?)?.toInt() ?? 0).toList();
    final mi = ms.indexWhere((m) => besteM < m);
    String navn, under, hoyre;
    double pct;
    if (mi >= 0) {
      final fra = mi == 0 ? 0 : ms[mi - 1];
      navn = LopetCopy.porter[mi.clamp(0, 2)];
      under = LopetCopy.igjen(ms[mi] - besteM);
      pct = (besteM - fra) / math.max(1, ms[mi] - fra);
      hoyre = LopetCopy.poeng(mi < pts.length ? pts[mi] : 0);
    } else if (s.weekBestM != null && besteM < s.weekBestM!) {
      navn = LopetCopy.ukensBeste;
      under = LopetCopy.igjen(s.weekBestM! - besteM);
      pct = besteM / math.max(1, s.weekBestM!);
      hoyre = LopetCopy.forstePlass;
    } else {
      navn = LopetCopy.leder;
      under = LopetCopy.ingenForan;
      pct = 1;
      hoyre = LopetCopy.hold;
    }
    return Container(
      key: const Key('lopet-neste-maal'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: lopetKort(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.flag_outlined, size: 14, color: _mint), const SizedBox(width: 6), Flexible(child: Text(LopetCopy.nesteMaal, maxLines: 1, overflow: TextOverflow.ellipsis, style: _kicker(_mint)))]),
          const SizedBox(height: 8),
          Text(navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.display(18, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .1))),
                FractionallySizedBox(widthFactor: math.max(.04, pct.clamp(0.0, 1.0)), child: const ColoredBox(color: _mint)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(under, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .8)))),
            Flexible(child: Text(hoyre, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(12.5, weight: FontWeight.w800, color: _gullLys))),
          ]),
        ],
      ),
    );
  }
}

/// UKELISTEN: the place, the rival line («Seiler 30 · 12 m foran deg»), and what the top places win.
class LopetListeFlis extends StatelessWidget {
  const LopetListeFlis({super.key, required this.s, required this.besteM, required this.onTap, this.toppVinner});
  final LopetState s;
  final int besteM;
  final VoidCallback onTap;

  /// From the ladder's prizes: how many places win from Premiehylla (null until the ladder answered or none).
  final int? toppVinner;

  int? get _plass {
    final meg = s.ladderTop.where((r) => r.me).firstOrNull;
    if (meg != null) return meg.place;
    if (besteM <= 0) return null;
    final r = s.rival;
    if (r == null) return 1;
    return r.distanceM < besteM ? 1 : r.place + 1;
  }

  @override
  Widget build(BuildContext context) {
    final plass = _plass;
    final r = s.rival;
    final String linje;
    if (plass == null) {
      linje = LopetCopy.ikkePaa;
    } else if (r != null) {
      linje = r.distanceM >= besteM ? LopetCopy.foran(r.name, math.max(1, r.distanceM - besteM)) : LopetCopy.bak(r.name, math.max(1, besteM - r.distanceM));
    } else if (plass <= 3) {
      linje = LopetCopy.premieplass;
    } else {
      linje = LopetCopy.toppTi;
    }
    return GestureDetector(
      key: const Key('lopet-ukeliste-knapp'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
        decoration: lopetKort(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events_outlined, size: 14, color: _gull),
              const SizedBox(width: 6),
              Expanded(child: Text(LopetCopy.ukelisten, maxLines: 1, overflow: TextOverflow.ellipsis, style: _kicker(_gull))),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color.fromRGBO(255, 255, 255, .7)),
            ]),
            const SizedBox(height: 6),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(plass == null ? '—' : '$plass.', key: const Key('lopet-plass'), style: BergenTokens.display(24, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 6),
              Text(LopetCopy.plass, style: BergenTokens.text(13, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .8))),
            ])),
            const SizedBox(height: 4),
            Text(linje, key: r != null ? const Key('lopet-rival') : null, maxLines: 2, style: BergenTokens.text(12.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .86))),
            if (toppVinner != null) ...[
              const SizedBox(height: 4),
              Text(LopetCopy.toppVinner(toppVinner!), style: BergenTokens.text(12, weight: FontWeight.w800, color: _gullLys)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The life rings for the order's runs (filled for those left), «3 seilaser igjen», «+ redningsvest».
class LopetBoyer extends StatelessWidget {
  const LopetBoyer({super.key, required this.antall, required this.igjen, required this.vest});
  final int antall;
  final int igjen;
  final bool vest;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var k = 0; k < antall; k++) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: CustomPaint(size: const Size.square(22), painter: _Livboye(paa: k < igjen))),
      const SizedBox(width: 10),
      Text(LopetCopy.seilaserIgjen(igjen), key: const Key('lopet-igjen'), style: BergenTokens.display(15, weight: FontWeight.w800, color: Colors.white)),
      if (vest) ...[
        const SizedBox(width: 10),
        Container(
          key: const Key('lopet-vest'),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(127, 240, 203, .12), border: Border.all(color: const Color.fromRGBO(127, 240, 203, .55))),
          child: Text(LopetCopy.kaiVest, style: BergenTokens.text(12, weight: FontWeight.w800, color: _mint)),
        ),
      ],
    ],
  ));
}

class _Livboye extends CustomPainter {
  _Livboye({required this.paa});
  final bool paa;

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2 - 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .26;
    if (!paa) {
      c.drawCircle(ctr, r - ring.strokeWidth / 2 + 1, ring..color = const Color.fromRGBO(255, 255, 255, .2));
      return;
    }
    for (var i = 0; i < 8; i++) {
      ring.color = i.isEven ? const Color(0xFFE8FFF6) : _mint;
      c.drawArc(Rect.fromCircle(center: ctr, radius: r - ring.strokeWidth / 2 + 1), i * math.pi / 4, math.pi / 4, false, ring);
    }
  }

  @override
  bool shouldRepaint(_Livboye old) => old.paa != paa;
}

/// The «Pynt» corner button over the quay scene.
class LopetPyntKnapp extends StatelessWidget {
  const LopetPyntKnapp({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: LopetCopy.pynt,
    child: GestureDetector(
      key: const Key('lopet-pynt-knapp'),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(10, 33, 40, .82), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .14))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.flag_rounded, size: 17, color: _gullLys),
          const SizedBox(width: 8),
          Text(LopetCopy.pyntKort, style: BergenTokens.text(14, weight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
    ),
  );
}

// ── the sheets ──────────────────────────────────────────────────────────────

/// The sheets' dark frame: the handle, the title 24/800 with its line, the round close key.
class LopetArk extends StatelessWidget {
  const LopetArk({super.key, required this.tittel, required this.linje, required this.children, this.arkKey});
  final String tittel;
  final String linje;
  final List<Widget> children;
  final Key? arkKey;

  static Future<void> vis(BuildContext context, Widget Function(BuildContext) builder) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF235C6A), Color(0xFF173F4A)]),
      border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .14))),
    ),
    child: SafeArea(
      top: false,
      child: ListView(
        key: arkKey,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color.fromRGBO(255, 255, 255, .35)))),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tittel, style: BergenTokens.display(24, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(linje, style: BergenTokens.text(13, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .72))),
              ]),
            ),
            Semantics(
              button: true,
              label: LopetCopy.kartLukk,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .1)), child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
}

/// Pynt på båten: per place, «Ingen» / «Vanlig» and the catalogue's items; locked ones say «Ta {merke}».
class LopetPyntArk extends StatefulWidget {
  const LopetPyntArk({super.key, required this.s, required this.onVelg});
  final LopetState s;
  final Future<void> Function(Map<String, String?> valgt) onVelg;

  @override
  State<LopetPyntArk> createState() => _LopetPyntArkState();
}

class _LopetPyntArkState extends State<LopetPyntArk> {
  late final Map<String, String?> _valgt = Map<String, String?>.from(widget.s.equipped);

  void _velg(String kind, String? item) {
    GameHaptics.felles.play(HaptikkId.u10); // haptics plan Step 5
    setState(() => _valgt[kind] = item);
    widget.onVelg(Map<String, String?>.from(_valgt));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final eid = {for (final c in s.cosmetics) c.item: c};
    final katalog = s.katalog.isNotEmpty ? s.katalog : [for (final c in s.cosmetics) LopetPyntVare(item: c.item, kind: c.kind, name: c.name)];
    return LopetArk(
      arkKey: const Key('lopet-pynt'),
      tittel: LopetCopy.pynt,
      linje: LopetCopy.pyntUnder,
      children: [
        for (final kind in const ['pennant', 'wake', 'figurehead']) ...[
          Padding(padding: const EdgeInsets.fromLTRB(4, 6, 0, 8), child: Text(LopetCopy.pyntPlass(kind).toUpperCase(), style: _kicker(const Color.fromRGBO(255, 255, 255, .7)))),
          Row(children: [
            Expanded(child: _PyntFlis(kind: kind, navn: kind == 'wake' ? LopetCopy.pyntVanlig : LopetCopy.pyntIngenValgt, under: LopetCopy.pyntStandard, valgt: _valgt[kind] == null, laast: false, onTap: () => _velg(kind, null))),
            for (final v in katalog.where((v) => v.kind == kind).take(2)) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _PyntFlis(
                  key: Key('lopet-pynt-${v.item}'),
                  kind: kind,
                  navn: v.name,
                  under: eid.containsKey(v.item) ? (v.badgeName ?? '') : LopetCopy.pyntTa(v.badgeName ?? ''),
                  stjerner: (eid[v.item]?.stars ?? 0),
                  valgt: _valgt[kind] == v.item,
                  laast: !eid.containsKey(v.item),
                  onTap: eid.containsKey(v.item) ? () => _velg(kind, v.item) : () => GameHaptics.felles.play(HaptikkId.u09),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PyntFlis extends StatelessWidget {
  const _PyntFlis({super.key, required this.kind, required this.navn, required this.under, required this.valgt, required this.laast, this.onTap, this.stjerner = 0});
  final String kind;
  final String navn;
  final String under;
  final bool valgt;
  final bool laast;
  final int stjerner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ikon = switch (kind) {
      'pennant' => Icons.flag_outlined,
      'wake' => Icons.keyboard_double_arrow_up_rounded,
      _ => Icons.home_outlined,
    };
    return Semantics(
      button: !laast,
      selected: valgt,
      label: navn,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: aeMyk,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: valgt ? const Color.fromRGBO(127, 240, 203, .14) : const Color.fromRGBO(255, 255, 255, .06),
            border: Border.all(color: valgt ? _mint : const Color.fromRGBO(255, 255, 255, .12), width: valgt ? 2 : 1),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: laast ? .5 : 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Icon(ikon, size: 26, color: valgt ? _gullLys : Colors.white)),
                    const SizedBox(height: 6),
                    Text(navn, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: BergenTokens.text(13, weight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(under, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: BergenTokens.text(11.5, weight: FontWeight.w700, color: valgt ? _gullLys : const Color.fromRGBO(255, 255, 255, .62))),
                    if (stjerner > 1) Text('★' * (stjerner - 1), textAlign: TextAlign.center, style: BergenTokens.text(11, weight: FontWeight.w800, color: _gull)),
                  ],
                ),
              ),
              if (valgt) const Positioned(right: -2, top: -4, child: CircleAvatar(radius: 10, backgroundColor: _mint, child: Icon(Icons.check_rounded, size: 13, color: Color(0xFF0F3540)))),
              if (laast) const Positioned(right: 0, top: -2, child: Icon(Icons.lock_outline_rounded, size: 14, color: Color.fromRGBO(255, 255, 255, .55))),
            ],
          ),
        ),
      ),
    );
  }
}
