import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart' show LearnedPatternItem;
import '../../../data/aegil/aegil_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../meg/min_bio.dart';
import '../meg/min_bio_bits.dart';
import '../meg/min_bio_kort.dart' show bioNivC;
import 'aegil_bits.dart';
import 'aegil_launch_copy.dart';
import 'cus_level3.dart';

// ── Det Ægil vet om deg · Min Bio (`agMinne`, new Bergen L4821–4905) ─────────

/// What Ægil remembers beyond the bio: favourite stores, the household, the
/// dinner rhythm, and the rest he has noticed.
class AeMinneData {
  AeMinneData(List<MemoryEntry> alle) {
    for (final m in alle) {
      if (bioEier(m)) continue;
      switch (m.kind) {
        case 'store' || 'stores':
          butikker.add(m);
        case 'household':
          husstand.add(m);
        case 'dinner' || 'rhythm':
          rytme.add(m);
        default:
          laert.add(m);
      }
    }
    alleLinjer = alle;
  }

  late final List<MemoryEntry> alleLinjer;
  final List<MemoryEntry> butikker = [], husstand = [], rytme = [], laert = [];

  bool get tom => alleLinjer.isEmpty;

  static String tekst(MemoryEntry m) => (m.label ?? m.value).trim();

  /// `mnTopp`: the first two likes joined, the first store, the household.
  List<String> get topp {
    final liker = alleLinjer.where((m) => m.kind == 'like').toList();
    return [
      if (liker.isNotEmpty) liker.length == 1 ? tekst(liker[0]) : AeCopy.og(tekst(liker[0]), tekst(liker[1])),
      if (butikker.isNotEmpty) tekst(butikker[0]),
      if (husstand.isNotEmpty) tekst(husstand[0]),
    ];
  }
}

abstract final class _Tx {
  static const fraBestillinger = 'Fra bestillingene dine';
  static const fraBestillingerSub = 'Ægil har lært dette. Trykk × for å fjerne.';
  static const favorittbutikker = 'FAVORITTBUTIKKER';
  static const husstand = 'HUSSTAND';
  static const middagsrytme = 'MIDDAGSRYTME';
  static const lagtMerke = 'Ægil har lagt merke til';
  static const lagtMerkeSub = 'Bare forslag til du sier «Stemmer»';
  static const varsler = 'Varsler';
  static const glemAlt = 'Glem alt';
  static const glemAltSub = 'Min Bio og alt Ægil har lært slettes. Bestillingshistorikken blir.';
  static const sikker = 'Er du sikker?';
  static const sikkerSub = 'Ægil starter på nytt og må bli kjent med deg igjen.';
  static const avbryt = 'Avbryt';
  static const jaGlem = 'Ja, glem alt';
}

const _glass = [CssLinear(180, [Color.fromRGBO(255, 255, 255, .13), Color.fromRGBO(255, 255, 255, .05)])];
const _glassSh = [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .18)), CssShadow(0, 18, 28, -22, Color.fromRGBO(4, 18, 26, .85))];
const _hvit60 = Color.fromRGBO(255, 255, 255, .6);
const _mintLys = Color(0xFF9FF0D4);

class AeMinneView extends StatefulWidget {
  const AeMinneView({
    super.key,
    required this.data,
    required this.bio,
    required this.varsler,
    required this.nivaaNavn,
    required this.onFjern,
    required this.onStemmer,
    required this.onLeggTil,
    required this.onNivaa,
    required this.onGlem,
    required this.onBio,
    this.monstre = const [],
    this.onMonster,
  });

  final AeMinneData data;
  final MinBio bio;
  final String varsler;
  final String nivaaNavn;
  final ValueChanged<MemoryEntry> onFjern;
  final ValueChanged<MemoryEntry> onStemmer;
  final VoidCallback onLeggTil;
  final VoidCallback onNivaa;
  final VoidCallback onGlem;
  final VoidCallback onBio;

  /// Customer Step 7: what Ægil noticed in the orders (`agent/me/patterns`), «Stemmer» / ✕.
  final List<LearnedPatternItem> monstre;
  final void Function(LearnedPatternItem p, bool stemmer)? onMonster;

  static bool bekreftet(MemoryEntry m) => m.source == 'stated' || m.source == 'onboarding' || m.source == 'settings';

  @override
  State<AeMinneView> createState() => _AeMinneViewState();
}

class _AeMinneViewState extends State<AeMinneView> {
  /// «Glem alt» asks first; the question goes away by itself after 8 s.
  bool _sporGlem = false;
  Timer? _glemT;

  @override
  void dispose() {
    _glemT?.cancel();
    super.dispose();
  }

  void _glemStart() {
    setState(() => _sporGlem = true);
    _glemT?.cancel();
    _glemT = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _sporGlem = false);
    });
  }

  Widget _kort({required Widget child, required double delay, EdgeInsets padding = const EdgeInsets.fromLTRB(13, 13, 13, 6)}) => LfRise(
        delay: delay,
        dur: 400,
        child: CssBox(radius: BorderRadius.circular(22), bg: _glass, border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)), shadows: _glassSh, padding: padding, child: child),
      );

  Widget _kortHode(String ik, String tittel, String sub, {Widget? hoyre}) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(92, 224, 184, .14),
              border: Border.all(color: const Color.fromRGBO(127, 240, 203, .36)),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: BioIkon(ik, color: _mintLys, size: 15, width: 2.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tittel, style: jakarta(14, em: -.01)),
                const SizedBox(height: 1),
                Text(sub, style: inter(11, weight: FontWeight.w600, height: 1.35, color: _hvit60)),
              ],
            ),
          ),
          ?hoyre,
        ],
      );

  Widget _kryss(VoidCallback onTap, {double size = 22, double ik = 9, double w = 3.4, double a = .16}) => LfPress(
        onTap: onTap,
        scale: .88,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 148, 102, a)),
          alignment: Alignment.center,
          child: BioIkon(BioIk.kryss, color: const Color(0xFFFFB08A), size: ik, width: w),
        ),
      );

  Widget _pille(MemoryEntry m) => Container(
        key: Key('a1_aegil_minne_${m.id}'),
        height: 30,
        padding: const EdgeInsets.fromLTRB(11, 0, 4, 0),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, .09),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(AeMinneData.tekst(m), maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w800))),
            const SizedBox(width: 6),
            _kryss(() => widget.onFjern(m)),
          ],
        ),
      );

  Widget _gruppe(String tittel, List<MemoryEntry> l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tittel, style: inter(10, weight: FontWeight.w800, em: .1, color: const Color.fromRGBO(255, 255, 255, .55))),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final m in l) _pille(m)]),
        ],
      );

  /// The bio's four groups (`bioGrupper`), two by two.
  Widget _bioGruppe(int i, BioEff E) {
    final b = widget.bio;
    final (ik, stil) = switch (i) {
      0 => (BioIk.blad, BioStil.mint),
      1 => (BioIk.varsel, BioStil.ora),
      2 => (BioIk.hjerte, BioStil.mint),
      _ => (BioIk.nei, BioStil.nei),
    };
    final on = <({String tx, BioStil stil, String? merke, Color? mBg, Color? mC})>[
      if (i == 0)
        for (final k in E.kost) (tx: k, stil: BioStil.mint, merke: null, mBg: null, mC: null),
      if (i == 1) ...[
        for (final e in E.all.entries)
          e.value == BioAll.allergi
              ? (tx: e.key, stil: BioStil.ora, merke: BioCopy.merkeAllergi, mBg: const Color(0xFFF26D3D), mC: Colors.white)
              : (tx: e.key, stil: BioStil.gul, merke: BioCopy.merkeUnngaar, mBg: const Color.fromRGBO(246, 210, 122, .92), mC: const Color(0xFF4A300A)),
        if (b.ingen && E.all.isEmpty) (tx: BioCopy.ingenAllergier, stil: BioStil.mint, merke: null, mBg: null, mC: null),
      ],
      if (i == 2)
        for (final k in E.liker) (tx: k, stil: BioStil.mint, merke: null, mBg: null, mC: null),
      if (i == 3)
        for (final k in E.ikke) (tx: k, stil: BioStil.nei, merke: null, mBg: null, mC: null),
    ];
    return LfRise(
      delay: 60 + i * 60.0,
      dur: 400,
      child: LfPress(
        onTap: widget.onBio,
        scale: .97,
        ms: 140,
        child: CssBox(
          radius: BorderRadius.circular(22),
          bg: _glass,
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
          shadows: _glassSh,
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112 - 23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CssBox(
                      width: 26,
                      height: 26,
                      radius: BorderRadius.circular(9),
                      bg: stil.bg,
                      border: Border.all(color: stil.bd),
                      child: Center(child: BioIkon(ik, color: stil.c, size: 13, width: 2.4)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(BioCopy.grupper[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: FontWeight.w800))),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .1), borderRadius: BorderRadius.circular(999)),
                      child: Text('${on.length}', style: inter(10.5, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .75))),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final c in on.take(5)) BioSmaaChip(tx: c.tx, stil: c.stil, merke: c.merke, merkeBg: c.mBg, merkeC: c.mC, panel: true),
                    if (on.length > 5)
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, .08), borderRadius: BorderRadius.circular(999)),
                        child: Text('+${on.length - 5}', style: inter(11, weight: FontWeight.w800, color: const Color.fromRGBO(255, 255, 255, .7))),
                      ),
                    if (on.isEmpty) Text(BioCopy.grupperTom[i], style: inter(11, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .55))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final b = widget.bio;
    final E = bioEff(b);
    final score = bioScore(b, E);
    // Customer Step 7: a pattern Ægil noticed is something known too.
    final tom = d.tom && b.tekst.trim().isEmpty && !b.ingen && widget.monstre.isEmpty;
    final barn = <Widget>[
      if (tom)
        LfRise(
          dur: 400,
          child: CssBox(
            radius: BorderRadius.circular(22),
            bg: _glass,
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
            shadows: _glassSh,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment(-.26, -1), end: Alignment(.26, 1), colors: [Color(0xFF2F6E80), Color(0xFF173E48)]),
                    boxShadow: [BoxShadow(color: Color.fromRGBO(127, 240, 203, .55), spreadRadius: 2)],
                  ),
                  child: ClipOval(
                    child: Stack(clipBehavior: Clip.none, children: [Positioned(left: 2, bottom: -8, width: 44, child: Image.asset(aePose('front'), width: 44, fit: BoxFit.fitWidth))]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(AeCopy.minneTom, style: inter(12.5, weight: FontWeight.w700, height: 1.4))),
                const SizedBox(width: 12),
                LfPress(
                  key: const Key('a1_aegil_minne_ja'),
                  onTap: widget.onLeggTil,
                  dy: 1.5,
                  child: CssBox(
                    radius: BorderRadius.circular(999),
                    bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
                    shadows: const [CssShadow(0, 1.5, 0, 0, Color(0xFFC4491A))],
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    child: Text(AeCopy.jaLaOss, style: inter(11.5, weight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        )
      else ...[
        // Min Bio.
        LfRise(
          dur: 450,
          child: CssBox(
            key: const Key('a1_aegil_min_bio'),
            radius: BorderRadius.circular(24),
            clip: true,
            bg: const [
              CssRadial([Color.fromRGBO(92, 224, 184, .2), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .6], rx: .9, ry: .8, cx: 1, cy: 0),
              CssLinear(180, [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)]),
            ],
            border: Border.all(color: const Color.fromRGBO(127, 240, 203, .34)),
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow(0, 22, 32, -22, Color.fromRGBO(4, 18, 26, .95))],
            child: Stack(
              children: [
                const Positioned.fill(child: BioSveip()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const BioRingPortrett(size: 64, inset: 3, aegW: 56, aegBunn: -10, merke: 22, merkeIk: 12, merkeR: -2, merkeB: -1),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(BioCopy.minneKicker, style: inter(10, weight: FontWeight.w800, em: .12, color: const Color(0xFF7FF0CB))),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [Text(BioCopy.tittel, style: jakarta(20, em: -.02)), const BioIntelligence()],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 13),
                          Semantics(
                            label: BioCopy.redigerBio,
                            button: true,
                            child: LfPress(key: const Key('a1_aegil_bio_rediger'), onTap: widget.onBio, dy: 2, scale: .94, child: const BioBlyant(size: 38, ik: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(BioCopy.minneLinje, style: inter(11.5, weight: FontWeight.w600, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .7))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: BioSegmenter(score: score, h: 8)),
                          const SizedBox(width: 10),
                          Text(BioCopy.nivaa(score), style: inter(11, weight: FontWeight.w800, color: bioNivC(score)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(bioNeste(b, E), style: inter(11, weight: FontWeight.w600, height: 1.4, color: _hvit60)),
                      const SizedBox(height: 11),
                      CssBox(
                        radius: BorderRadius.circular(14),
                        bg: const [CssSolid(Color.fromRGBO(0, 0, 0, .18))],
                        shadows: const [CssShadow.inset(0, 1, 3, 0, Color.fromRGBO(0, 0, 0, .3))],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: BioCopy.aegil, style: inter(12.5, weight: FontWeight.w700, height: 1.45, color: const Color(0xFF7FF0CB))),
                            TextSpan(text: bioSetning(E)),
                          ]),
                          style: inter(12.5, weight: FontWeight.w700, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // The bio's groups.
        Column(
          children: [
            for (final r in const [0, 2]) ...[
              if (r > 0) const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: _bioGruppe(r, E)), const SizedBox(width: 8), Expanded(child: _bioGruppe(r + 1, E))],
                ),
              ),
            ],
          ],
        ),
        // «Med egne ord».
        if (b.tekst.trim().isNotEmpty)
          LfRise(
            delay: 300,
            dur: 400,
            child: GestureDetector(
              onTap: widget.onBio,
              child: CssBox(
                radius: BorderRadius.circular(22),
                bg: _glass,
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
                shadows: _glassSh,
                padding: const EdgeInsets.fromLTRB(34, 12, 14, 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(left: -22, top: -6, child: Text('«', style: jakarta(34, height: 1, color: const Color.fromRGBO(127, 240, 203, .55)))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(BioCopy.medEgneOrd, style: inter(10, weight: FontWeight.w800, em: .1, color: const Color.fromRGBO(255, 255, 255, .55))),
                        const SizedBox(height: 4),
                        Text(b.tekst.trim(), maxLines: 3, overflow: TextOverflow.ellipsis, style: inter(12.5, weight: FontWeight.w600, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .88))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Fra bestillingene dine.
        _kort(
          delay: 340,
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kortHode(
                'M5 8h14l-1 12H6z M9 8V6a3 3 0 0 1 6 0v2',
                _Tx.fraBestillinger,
                _Tx.fraBestillingerSub,
                hoyre: GestureDetector(onTap: widget.onLeggTil, child: Text(AeCopy.leggTil, style: inter(11.5, weight: FontWeight.w800, color: const Color(0xFF7FF0CB)))),
              ),
              const SizedBox(height: 12),
              _gruppe(_Tx.favorittbutikker, d.butikker),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _gruppe(_Tx.husstand, d.husstand)),
                  const SizedBox(width: 10),
                  Expanded(child: _gruppe(_Tx.middagsrytme, d.rytme)),
                ],
              ),
            ],
          ),
        ),
        // Ægil har lagt merke til.
        _kort(
          delay: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kortHode('M9 18h6 M10 21h4 M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z', _Tx.lagtMerke, _Tx.lagtMerkeSub),
              const SizedBox(height: 6),
              // Customer Step 7: the learned patterns (design `mnLaert`), proposed first.
              for (final p in widget.monstre)
                Container(
                  key: Key('a1_aegil_monster_${p.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .08)))),
                  child: Row(
                    children: [
                      () {
                        final c = p.confirmed ? const Color(0xFF5CE0B8) : const Color(0xFFF6D27A);
                        return Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c, blurRadius: 4)]));
                      }(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.text, style: inter(12.5, weight: FontWeight.w700, height: 1.35)),
                            const SizedBox(height: 2),
                            Text(
                              p.confirmed ? CusLevel3Copy.cus_monster_bekreftet : CusLevel3Copy.cus_monster_forslag(p.support),
                              style: inter(10.5, weight: FontWeight.w700, color: p.confirmed ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .58)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!p.confirmed) ...[
                        LfPress(
                          key: Key('a1_aegil_monster_stemmer_${p.id}'),
                          onTap: () => widget.onMonster?.call(p, true),
                          scale: .94,
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(92, 224, 184, .16),
                              border: Border.all(color: const Color.fromRGBO(127, 240, 203, .55)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(CusLevel3Copy.cus_monster_stemmer, style: inter(11, weight: FontWeight.w800, color: _mintLys)),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      _kryss(() => widget.onMonster?.call(p, false), size: 28, ik: 10, w: 3.2, a: .14),
                    ],
                  ),
                ),
              for (final m in d.laert)
                Container(
                  key: Key('a1_aegil_minne_${m.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .08)))),
                  child: Row(
                    children: [
                      () {
                        final ok = AeMinneView.bekreftet(m);
                        final c = ok ? const Color(0xFF5CE0B8) : const Color(0xFFF6D27A);
                        return Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c, boxShadow: [BoxShadow(color: c, blurRadius: 4)]));
                      }(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AeMinneData.tekst(m), style: inter(12.5, weight: FontWeight.w700, height: 1.35)),
                            const SizedBox(height: 2),
                            Text(
                              AeMinneView.bekreftet(m) ? AeCopy.bekreftet : '${AeCopy.fraChat} · ${AeCopy.kunForslag}',
                              style: inter(10.5, weight: FontWeight.w700, color: AeMinneView.bekreftet(m) ? const Color(0xFF7FF0CB) : const Color.fromRGBO(255, 255, 255, .58)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!AeMinneView.bekreftet(m)) ...[
                        LfPress(
                          onTap: () => widget.onStemmer(m),
                          scale: .94,
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(92, 224, 184, .16),
                              border: Border.all(color: const Color.fromRGBO(127, 240, 203, .55)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(AeCopy.stemmer, style: inter(11, weight: FontWeight.w800, color: _mintLys)),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      _kryss(() => widget.onFjern(m), size: 28, ik: 10, w: 3.2, a: .14),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // «Slik bruker Ærend bioen» is left out: only Ægil's own suggestions
        // read the bio today (needs sign-off).
        // Så mye kan Ægil gjøre · Varsler.
        _kort(
          delay: 520,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            children: [
              _rad(
                key: const Key('a1_aegil_til_nivaa'),
                ik: 'M13 2L4 14h7l-1 8 9-12h-7z',
                ikC: const Color(0xFFFFE7A8),
                ikBg: const Color.fromRGBO(242, 193, 78, .14),
                ikBd: const Color.fromRGBO(246, 210, 122, .45),
                tittel: AeCopy.saaMyeRad,
                verdi: widget.nivaaNavn,
              ),
              _rad(
                topp: true,
                ik: 'M6 16V11a6 6 0 0 1 12 0v5l2 2H4z M10 21h4',
                ikC: _mintLys,
                ikBg: const Color.fromRGBO(92, 224, 184, .12),
                ikBd: const Color.fromRGBO(127, 240, 203, .32),
                tittel: _Tx.varsler,
                verdi: widget.varsler,
              ),
            ],
          ),
        ),
        // Glem alt.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _sporGlem ? _glemSpor() : _glemKnapp(),
        ),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in barn.indexed) ...[if (i > 0) const SizedBox(height: 10), w],
        ],
      ),
    );
  }

  Widget _rad({Key? key, bool topp = false, required String ik, required Color ikC, required Color ikBg, required Color ikBd, required String tittel, required String verdi}) => GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: widget.onNivaa,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: topp ? const Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, .08))) : null),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: ikBg, border: Border.all(color: ikBd), borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: BioIkon(ik, color: ikC, size: 14, width: 2.2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: tittel),
                    TextSpan(text: ' · $verdi', style: inter(12.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .62))),
                  ]),
                  style: inter(12.5, weight: FontWeight.w800),
                ),
              ),
              const BioIkon('M9 6l6 6-6 6', color: Color.fromRGBO(255, 255, 255, .55), size: 14, width: 2.4),
            ],
          ),
        ),
      );

  Widget _glemKnapp() => LfRise(
        delay: 580,
        dur: 400,
        child: LfPress(
          key: const Key('a1_aegil_glem'),
          onTap: _glemStart,
          scale: .985,
          ms: 140,
          child: CssBox(
            radius: BorderRadius.circular(20),
            bg: const [CssLinear(180, [Color.fromRGBO(255, 148, 102, .12), Color.fromRGBO(255, 148, 102, .04)])],
            border: Border.all(color: const Color.fromRGBO(255, 154, 107, .34)),
            shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .08)), CssShadow(0, 16, 24, -20, Color.fromRGBO(4, 18, 26, .9))],
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 148, 102, .16),
                    border: Border.all(color: const Color.fromRGBO(255, 154, 107, .5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const BioIkon('M4 7h16 M9 7V4.5h6V7 M6 7l1 13h10l1-13 M10 11v5.5M14 11v5.5', color: Color(0xFFFFB08A), size: 17, width: 2.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_Tx.glemAlt, style: jakarta(14, em: -.01, color: const Color(0xFFFFC7AE))),
                      const SizedBox(height: 2),
                      Text(_Tx.glemAltSub, style: inter(11, weight: FontWeight.w600, height: 1.35, color: const Color.fromRGBO(255, 255, 255, .62))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const BioIkon('M9 6l6 6-6 6', color: Color.fromRGBO(255, 199, 174, .75), size: 14, width: 2.4),
              ],
            ),
          ),
        ),
      );

  Widget _glemSpor() => LfRise(
        dur: 300,
        child: CssBox(
          key: const Key('a1_aegil_glem_spor'),
          radius: BorderRadius.circular(20),
          bg: const [
            CssRadial([Color.fromRGBO(255, 148, 102, .22), Color.fromRGBO(255, 148, 102, 0)], stops: [0, .6], rx: .9, ry: .9, cx: 0, cy: 0),
            CssLinear(180, [Color.fromRGBO(255, 255, 255, .1), Color.fromRGBO(255, 255, 255, .04)]),
          ],
          border: Border.all(color: const Color.fromRGBO(255, 154, 107, .62)),
          shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .14)), CssShadow(0, 18, 28, -20, Color.fromRGBO(4, 18, 26, .95))],
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CssBox(
                    width: 38,
                    height: 38,
                    radius: BorderRadius.circular(12),
                    bg: const [CssLinear(180, [Color(0xFFFFB08A), Color(0xFFF26D3D)])],
                    shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 8, 14, -8, Color.fromRGBO(200, 70, 25, .9))],
                    child: const Center(child: BioIkon('M12 3l9.5 17h-19z M12 10v4 M12 17v.01', color: Colors.white, size: 18, width: 2.4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_Tx.sikker, style: jakarta(14.5, em: -.01)),
                        const SizedBox(height: 2),
                        Text(_Tx.sikkerSub, style: inter(11.5, weight: FontWeight.w600, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .72))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LfPress(
                      onTap: () {
                        _glemT?.cancel();
                        setState(() => _sporGlem = false);
                      },
                      dy: 2,
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, .1),
                          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(_Tx.avbryt, style: inter(13, weight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LfPress(
                      key: const Key('a1_aegil_glem_ja'),
                      onTap: () {
                        _glemT?.cancel();
                        setState(() => _sporGlem = false);
                        widget.onGlem();
                      },
                      dy: 2,
                      child: CssBox(
                        height: 46,
                        radius: BorderRadius.circular(999),
                        bg: const [CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1])],
                        shadows: const [
                          CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .4)),
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                          CssShadow(0, 2, 0, 0, Color(0xFFC4491A)),
                          CssShadow(0, 12, 16, -10, Color.fromRGBO(200, 70, 25, .85)),
                        ],
                        child: Center(child: Text(_Tx.jaGlem, style: inter(13, weight: FontWeight.w800))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
