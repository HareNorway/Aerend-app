import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/aegil/aegil_models.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfToast;
import 'aegil_bits.dart';
import 'aegil_launch_copy.dart';

// ── Innstillinger for Ægil (new Bergen L5082–5092, L9954, L20363–20393) ─────
// One list for both places: the Ægil screen's settings view and the dark
// Meg sheet (`aegilInnst`), «Det samme gjelder i Meg».
//
// The design's levels are 0 Av · 1 Bare svar · 2 Varsle og foreslå · 3 Handle
// i kurven · 4 Fast bestilling. The backend has 0 ask-only · 1 suggest in the
// app · 2 + pushes · 3 + basket · 4 weekly order, and a pause. They map
// without new levels: «Av» is the pause (no suggestions, no pushes, no chat
// actions), «Bare svar» is level 0, 2 and 3 are 2 and 3, and «Fast bestilling»
// stays «Kommer snart» (it needs a Vipps agreement the app can't make yet).
// A customer still on level 1 sees that level as its own row.

abstract final class AeInnstCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String get tittel => _t('Innstillinger for Ægil', 'Settings for Ægil');
  static String get linjeAegil =>
      _t('Bestem hvor mye Ægil kan gjøre for deg, og hva han kan bruke. Det samme gjelder i Meg.', 'Decide how much Ægil can do for you, and what he can use. The same applies in Me.');
  static String get linjeMeg => _t('Bestem hvor mye Ægil kan gjøre for deg, og hva han kan bruke.', 'Decide how much Ægil can do for you, and what he can use.');
  static String get s1 => _t('1 · Hvor mye kan Ægil gjøre', '1 · How much Ægil can do');
  static String get s1Under => _t('Ægil gjør aldri mer enn nivået sier, og du får kvittering på alt.', 'Ægil never does more than the level says, and you get a receipt for everything.');
  static String nivaa(int n) => _t('Nivå $n', 'Level $n');
  static List<String> get navn =>
      _en ? const ['Off', 'Answers only', 'Notify and suggest', 'Shop in the basket', 'Standing order'] : const ['Av', 'Bare svar', 'Varsle og foreslå', 'Handle i kurven', 'Fast bestilling'];
  static List<String> get hva => _en
      ? const [
          '',
          'Answers when you ask, but does nothing on his own.',
          'Tells you about offers and suggests. You decide.',
          'Puts items in the basket for you. You pay yourself.',
          'Ægil orders the weekly shop for you.',
        ]
      : const [
          '',
          'Svarer når du spør, men gjør ingenting selv.',
          'Sier fra om tilbud og foreslår. Du bestemmer.',
          'Legger varer i kurven for deg. Du betaler selv.',
          'Ægil bestiller ukeshandelen for deg.',
        ];
  static String get endreMerke => _t('Endre', 'Edit');
  static String get kommerSnart => _t('Kommer snart', 'Coming soon');
  static String get snartToast => _t('Fast bestilling kommer snart · vi sier fra når det er klart', 'Standing orders are coming soon · we will let you know');
  static String nivaaToast(int n, String navn) => _t('Ægil er på nivå $n · $navn', 'Ægil is on level $n · $navn');
  static String lagretToast(int n, String navn) => _t('Lagret · Ægil er på nivå $n · $navn', 'Saved · Ægil is on level $n · $navn');
  static String lagretMeg(int n) => _t('Lagret · Ægil er på nivå $n', 'Saved · Ægil is on level $n');

  static String get s2 => _t('2 · Rammer', '2 · Limits');
  static String get s2Handler => _t('Gjelder når Ægil handler for deg', 'Apply when Ægil shops for you');
  static String get s2Senere => _t('Brukes når du gir Ægil nivå 3', 'Used when you give Ægil level 3');
  static String get grense => _t('Beløpsgrense', 'Spending limit');
  static String get grenseUnder => _t('Per bestilling · Ægil går aldri over', 'Per order · Ægil never goes over');
  static String get grenseLabel => _t('Beløpsgrense i kroner', 'Spending limit in kroner');
  static String grenseToast(int kr, bool klemt) => _t('Beløpsgrense: $kr kr${klemt ? ' (mellom 100 og 5000 kr)' : ''}', 'Spending limit: $kr kr${klemt ? ' (between 100 and 5000 kr)' : ''}');
  static String get billig => _t('Bytt til billigere vare', 'Swap to a cheaper item');
  static String get billigUnder => _t('Ægil foreslår samme vare til lavere pris', 'Ægil suggests the same item at a lower price');
  static String get billigLab => _t('Billigere bytte', 'Cheaper swap');

  static String get s3 => _t('3 · Hva Ægil kan bruke', '3 · What Ægil can use');
  static String get s3Under => _t('Du kan slå av hver del når som helst', 'You can turn off each part at any time');

  static String bryterToast(String lab, bool paa) => _t('$lab: ${paa ? 'på' : 'av'}', '$lab: ${paa ? 'on' : 'off'}');
  static String get hvaVet => _t('Hva Ægil vet', 'What Ægil knows');
  static String get ferdig => _t('Ferdig', 'Done');
  static String get kr => 'kr';
}

/// The level the design shows (0–4) for the backend's settings.
int aeVisNivaa(AegilSettings s) {
  if (s.paused) return 0;
  return switch (s.level) {
    <= 1 => 1,
    2 => 2,
    3 => 3,
    _ => 4,
  };
}

/// The name the design gives that level («Varsle og foreslå» …). A customer
/// on the backend's level 1 keeps its own name.
String aeNivaaNavn(AegilSettings s, List<AegilLevel> levels) {
  if (!s.paused && s.level == 1) {
    return levels.where((l) => l.level == 1).firstOrNull?.name ?? 'Foreslå';
  }
  return AeInnstCopy.navn[aeVisNivaa(s)];
}

/// What a change to the settings needs from the caller: save [endring]
/// (`me/settings`) and show [toast] when it went through.
typedef AeInnstEndre = Future<void> Function(Map<String, dynamic> endring, {String? toast});

/// The rows of «Innstillinger for Ægil»: «1 · Hvor mye kan Ægil gjøre» with
/// the levels, «2 · Rammer» and «3 · Hva Ægil kan bruke».
class AegilInnstListe extends StatefulWidget {
  const AegilInnstListe({super.key, required this.settings, required this.levels, required this.onEndre, required this.onButikker});

  final AegilSettings settings;
  final List<AegilLevel> levels;
  final AeInnstEndre onEndre;

  /// «Butikker Ægil kan bruke» (needs the favourites).
  final VoidCallback onButikker;

  @override
  State<AegilInnstListe> createState() => _AegilInnstListeState();
}

class _AegilInnstListeState extends State<AegilInnstListe> {
  final TextEditingController _grense = TextEditingController();
  final FocusNode _grenseFokus = FocusNode();
  bool _skriver = false;

  AegilSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _grenseFokus.addListener(() {
      if (_grenseFokus.hasFocus) {
        setState(() => _skriver = true);
      } else {
        _lagreGrense();
      }
    });
  }

  @override
  void dispose() {
    _grense.dispose();
    _grenseFokus.dispose();
    super.dispose();
  }

  String get _grenseTx => s.capPerOrderOre == null ? '' : '${s.capPerOrderOre! ~/ 100}';

  void _lagreGrense() {
    if (!_skriver) return;
    final n = int.tryParse(_grense.text);
    setState(() => _skriver = false);
    if (n == null || n == 0) {
      _grense.text = _grenseTx;
      return;
    }
    final v = n.clamp(100, 5000);
    if (v * 100 == s.capPerOrderOre) return;
    widget.onEndre({'cap_per_order': v * 100}, toast: AeInnstCopy.grenseToast(v, v != n));
  }

  void _velg(int vis) {
    HapticFeedback.selectionClick();
    final navn = AeInnstCopy.navn[vis];
    if (vis == 0) {
      if (s.paused) return;
      widget.onEndre({'paused_until': DateTime.now().add(const Duration(days: 365)).toIso8601String()}, toast: AeInnstCopy.nivaaToast(0, navn));
      return;
    }
    final level = switch (vis) {
      1 => 0,
      2 => 2,
      _ => 3,
    };
    if (!s.paused && s.level == level) return;
    widget.onEndre({'level': level, if (s.paused) 'paused_until': null}, toast: AeInnstCopy.nivaaToast(vis, navn));
  }

  void _bryter(String felt, bool naa, String lab) {
    HapticFeedback.selectionClick();
    widget.onEndre({felt: !naa}, toast: AeInnstCopy.bryterToast(lab, !naa));
  }

  @override
  Widget build(BuildContext context) {
    if (!_skriver && _grense.text != _grenseTx) _grense.text = _grenseTx;
    final vis = aeVisNivaa(s);
    final legacy = !s.paused && s.level == 1;
    final level1 = widget.levels.where((l) => l.level == 1).firstOrNull;
    final kat = s.allowedCategories.isEmpty ? AeCopy.rmKatAlle : (s.allowedCategories.contains('restaurant') ? AeCopy.rmKatMatRest : AeCopy.rmKatMat);
    final ro = s.hasQuietHours ? '${s.quietHoursFrom}–${s.quietHoursTo}' : AeCopy.rmRoIngen;
    var k = 0;
    Widget kort(Widget Function(double delayMs) b) => b(k++ * 40.0);
    final rader = <Widget>[
      _Seksjon(AeInnstCopy.s1, AeInnstCopy.s1Under, verdi: AeInnstCopy.nivaa(vis)),
      for (var i = 0; i < 5; i++) ...[
        if (i == 4)
          kort(
            (d) => _Kort(
              key: const Key('ae-innst-nivaa-4'),
              delayMs: d,
              tileTx: '4',
              navn: AeInnstCopy.navn[4],
              under: AeInnstCopy.hva[4],
              snart: s.level < 4,
              valgt: s.level >= 4 && !s.paused,
              verdi: s.level < 4 ? AeInnstCopy.kommerSnart : null,
              onTap: () => LfToast.show(context, AeInnstCopy.snartToast),
            ),
          )
        else
          kort(
            (d) => _Kort(
              key: Key('ae-innst-nivaa-$i'),
              delayMs: d,
              tileTx: '$i',
              navn: AeInnstCopy.navn[i],
              // «Av»'s line («Ingen forslag og ingen chat») promises more
              // than the pause does (the chat still answers): hidden.
              under: i == 0 ? null : AeInnstCopy.hva[i],
              valgt: i == vis && !(i == 1 && legacy),
              pil: i != vis || (i == 1 && legacy),
              onTap: () => _velg(i),
            ),
          ),
        if (i == 1 && legacy) kort((d) => _Kort(key: const Key('ae-innst-nivaa-legacy'), delayMs: d, tileTx: '1', navn: level1?.name ?? 'Foreslå', under: level1?.body, valgt: true, onTap: () {})),
      ],
      _Seksjon(AeInnstCopy.s2, vis >= 3 ? AeInnstCopy.s2Handler : AeInnstCopy.s2Senere),
      kort(
        (d) =>
            _Kort(key: const Key('ae-innst-grense'), delayMs: d, ikon: _Ik.lommebok, navn: AeInnstCopy.grense, under: AeInnstCopy.grenseUnder, felt: _felt(), onTap: () => _grenseFokus.requestFocus()),
      ),
      kort(
        (d) => _Kort(
          key: const Key('ae-innst-billig'),
          delayMs: d,
          ikon: _Ik.ned,
          navn: AeInnstCopy.billig,
          under: AeInnstCopy.billigUnder,
          bryter: s.againstInterestEnabled,
          onTap: () => _bryter('against_interest_enabled', s.againstInterestEnabled, AeInnstCopy.billigLab),
        ),
      ),
      // Not in the design (kept, needs sign-off): the limits the app already had.
      kort(
        (d) => _Kort(
          key: const Key('ae-innst-butikker'),
          delayMs: d,
          ikon: _Ik.butikk,
          navn: AeCopy.rmBut,
          verdi: s.allowedStoreMode == 'allowlist' ? AeCopy.rmButFav : AeCopy.rmButAlle,
          onTap: widget.onButikker,
        ),
      ),
      kort(
        (d) => _Kort(
          key: const Key('ae-innst-kategorier'),
          delayMs: d,
          ikon: _Ik.hylle,
          navn: AeCopy.rmKat,
          verdi: kat,
          onTap: () {
            const matFisk = ['fisk', 'gront', 'bakeri', 'mat'];
            final neste = s.allowedCategories.isEmpty ? matFisk : (s.allowedCategories.contains('restaurant') ? <String>[] : [...matFisk, 'restaurant']);
            widget.onEndre({'allowed_categories': neste});
          },
        ),
      ),
      kort(
        (d) => _Kort(
          key: const Key('ae-innst-ro'),
          delayMs: d,
          ikon: _Ik.klokke,
          navn: AeCopy.rmRo,
          verdi: ro,
          onTap: () {
            const valg = [('21:00', '08:00'), ('22:00', '09:00'), null];
            final i = valg.indexWhere((v) => v?.$1 == s.quietHoursFrom);
            final n = valg[(i + 1) % valg.length];
            widget.onEndre({
              'quiet_hours': n == null ? null : {'from': n.$1, 'to': n.$2},
            });
          },
        ),
      ),
      _Seksjon(AeInnstCopy.s3, AeInnstCopy.s3Under),
      kort(
        (d) => _Kort(
          key: const Key('ae-innst-laer'),
          delayMs: d,
          ikon: _Ik.hist,
          navn: AeCopy.rmLaer,
          bryter: s.learningEnabled,
          onTap: () => _bryter('learning_enabled', s.learningEnabled, AeCopy.rmLaer),
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rader.length; i++) ...[if (i > 0) const SizedBox(height: 8), rader[i]],
      ],
    );
  }

  Widget _felt() => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(255, 255, 255, .08)]),
      border: Border.all(color: _skriver ? const Color.fromRGBO(127, 240, 203, .85) : const Color.fromRGBO(255, 255, 255, .22), width: 1.5),
      boxShadow: [BoxShadow(color: _skriver ? const Color.fromRGBO(92, 224, 184, .6) : Colors.transparent, blurRadius: 18 / 2 / .57735, spreadRadius: -6)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 52,
          child: TextField(
            key: const Key('ae-innst-grense-felt'),
            controller: _grense,
            focusNode: _grenseFokus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            textAlign: TextAlign.right,
            cursorColor: const Color(0xFF5CE0B8),
            style: jakarta(15, color: Colors.white),
            decoration: InputDecoration.collapsed(
              hintText: '–',
              hintStyle: jakarta(15, color: const Color.fromRGBO(255, 255, 255, .5)),
            ).copyWith(semanticCounterText: AeInnstCopy.grenseLabel),
            onSubmitted: (_) => _grenseFokus.unfocus(),
            onTapOutside: (_) => _grenseFokus.unfocus(),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          AeInnstCopy.kr,
          style: inter(12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7)),
        ),
      ],
    ),
  );
}

abstract final class _Ik {
  static const String lommebok = 'M4 7h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4zM4 7l11-3v3M16 13.5h.01';
  static const String klokke = 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2';
  static const String ned = 'M12 4v14M6 12l6 6 6-6';
  static const String hist = 'M3 12a9 9 0 1 0 3-6.7M3 4v4h4M12 8v4l3 2';
  static const String butikk = 'M4 10l1.6-5h12.8L20 10M4 10h16M5 10v10h14V10M10 20v-5h4v5';
  static const String hylle = 'M4 6h16M4 12h16M4 18h16M7 6v12M17 6v12';
}

/// A section head: the glowing mint dot, the name in capitals, its line and
/// (for the levels) the «Nivå N» chip.
class _Seksjon extends StatelessWidget {
  const _Seksjon(this.navn, this.under, {this.verdi});

  final String navn;
  final String under;
  final String? verdi;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF5CE0B8),
                      boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .8), blurRadius: 8 / 2 / .57735)],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      navn.toUpperCase(),
                      style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF7FF0CB)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(under, style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .62))),
            ],
          ),
        ),
        if (verdi != null) ...[const SizedBox(width: 10), _Verdi(verdi!)],
      ],
    ),
  );
}

class _Verdi extends StatelessWidget {
  const _Verdi(this.t, {this.snart = false});

  final String t;
  final bool snart;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(999),
    bg: [CssSolid(snart ? const Color.fromRGBO(245, 196, 81, .16) : const Color.fromRGBO(255, 255, 255, .12))],
    shadows: [CssShadow.inset(0, 0, 0, 1, snart ? const Color.fromRGBO(245, 196, 81, .55) : const Color.fromRGBO(255, 255, 255, .2))],
    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
    child: Text(
      t,
      maxLines: 1,
      softWrap: false,
      style: inter(11, weight: FontWeight.w800, color: snart ? const Color(0xFFFFE08A) : Colors.white),
    ),
  );
}

/// One card row (`radMork`): the tile (icon or number), the name and line,
/// and on the right a chip, a field, a switch, the mint check or an arrow.
class _Kort extends StatelessWidget {
  const _Kort({
    super.key,
    required this.delayMs,
    required this.navn,
    required this.onTap,
    this.ikon,
    this.tileTx,
    this.under,
    this.verdi,
    this.felt,
    this.bryter,
    this.valgt = false,
    this.pil = false,
    this.snart = false,
  });

  final double delayMs;
  final String navn;
  final VoidCallback onTap;
  final String? ikon;
  final String? tileTx;
  final String? under;
  final String? verdi;
  final Widget? felt;
  final bool? bryter;
  final bool valgt;
  final bool pil;
  final bool snart;

  @override
  Widget build(BuildContext context) {
    final v = valgt;
    final tBd = snart ? const Color.fromRGBO(245, 196, 81, .4) : (v ? const Color.fromRGBO(127, 240, 203, .55) : const Color.fromRGBO(255, 255, 255, .2));
    final tC = snart ? const Color(0xFFFFE08A) : (v ? const Color(0xFF7FF0CB) : Colors.white);
    final tile = CssBox(
      width: 40,
      height: 40,
      radius: BorderRadius.circular(13),
      bg: [
        CssLinear(
          160,
          snart
              ? const [Color.fromRGBO(245, 196, 81, .22), Color.fromRGBO(245, 196, 81, .05)]
              : v
              ? const [Color.fromRGBO(127, 240, 203, .4), Color.fromRGBO(92, 224, 184, .14)]
              : const [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .06)],
        ),
      ],
      shadows: [const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .28)), CssShadow.inset(0, 0, 0, 1, tBd), const CssShadow(0, 8, 12, -6, Color.fromRGBO(0, 0, 0, .5))],
      child: Center(
        child: tileTx != null ? Text(tileTx!, style: jakarta(13, color: tC)) : AeIkon(ikon ?? _Ik.hist, size: 18, stroke: 2.1, color: tC),
      ),
    );
    final Widget? hoyre =
        felt ??
        (bryter != null
            ? _Bryter(paa: bryter!)
            : verdi != null
            ? _Verdi(verdi!, snart: snart)
            : v
            ? const _Hake()
            : pil
            ? const _Pil()
            : null);
    final innhold = Row(
      children: [
        tile,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(navn, style: inter(14, weight: FontWeight.w800, em: -.01, height: 1.3)),
              if (under != null && under!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(under!, style: inter(12, height: 1.4, color: const Color.fromRGBO(255, 255, 255, .62))),
              ],
            ],
          ),
        ),
        if (hoyre != null) ...[const SizedBox(width: 12), hoyre],
      ],
    );
    // `transition: box-shadow .25s ease, background .25s ease` between the
    // plain and the chosen look; «Kommer snart» has its own stripes.
    final kort = snart
        ? CustomPaint(
            painter: const _Striper(),
            child: CssBox(
              radius: BorderRadius.circular(20),
              shadows: const [CssShadow(0, 0, 0, 1.5, Color.fromRGBO(245, 196, 81, .32)), CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .18))],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: innhold),
              ),
            ),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween(end: v ? 1 : 0),
            duration: const Duration(milliseconds: 250),
            curve: cssEase,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: innhold),
            ),
            builder: (context, a, child) {
              Color l(Color x, Color y) => Color.lerp(x, y, a)!;
              return CssBox(
                radius: BorderRadius.circular(20),
                bg: [
                  CssLinear(180, [
                    l(const Color.fromRGBO(255, 255, 255, .14), const Color.fromRGBO(92, 224, 184, .24)),
                    l(const Color.fromRGBO(255, 255, 255, .05), const Color.fromRGBO(92, 224, 184, .08)),
                  ]),
                ],
                shadows: [
                  CssShadow(0, 0, 0, 1.5, l(const Color.fromRGBO(255, 255, 255, .16), const Color.fromRGBO(127, 240, 203, .75))),
                  const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .18)),
                  // `0 12px 20px -14px rgba(4,18,26,.8)` ↔ `0 0 22px -6px rgba(92,224,184,.7)`.
                  CssShadow(0, 12 * (1 - a), 20 + 2 * a, -14 + 8 * a, l(const Color.fromRGBO(4, 18, 26, .8), const Color.fromRGBO(92, 224, 184, .7))),
                ],
                child: child,
              );
            },
          );
    return _Stag(
      delayMs: delayMs,
      child: AePress(
        onTap: onTap,
        dy: 0,
        scale: .985,
        child: kort,
      ),
    );
  }
}

/// `repeating-linear-gradient(135deg, white .05 0 8px, white .02 8px 16px)`
/// behind «Kommer snart».
class _Striper extends CustomPainter {
  const _Striper();

  @override
  void paint(Canvas canvas, Size size) {
    const k = 16 / math.sqrt2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(k, k),
          const [Color.fromRGBO(255, 255, 255, .05), Color.fromRGBO(255, 255, 255, .05), Color.fromRGBO(255, 255, 255, .02), Color.fromRGBO(255, 255, 255, .02)],
          const [0, .5, .5, 1],
          TileMode.repeated,
        ),
    );
  }

  @override
  bool shouldRepaint(_Striper o) => false;
}

/// `kortStag .45s <delay> cubic-bezier(.2,.9,.3,1) both`.
class _Stag extends StatelessWidget {
  const _Stag({required this.delayMs, required this.child});

  final double delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 450 + delayMs,
    child: child,
    builder: (context, t, child) {
      final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, delayMs, 450));
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 18 * (1 - e), 0)..scaleByDouble(.97 + .03 * e, .97 + .03 * e, 1, 1), child: child),
      );
    },
  );
}

/// The switch: 46 × 28, mint when on, the knob springing 18 px
/// (`cubic-bezier(.34,1.56,.64,1)` .3 s).
class _Bryter extends StatelessWidget {
  const _Bryter({required this.paa});
  final bool paa;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: paa,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: paa ? null : const Color.fromRGBO(255, 255, 255, .14),
        gradient: paa ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FF0CB), Color(0xFF3FCB9E)]) : null,
        border: Border.all(color: paa ? const Color.fromRGBO(255, 255, 255, .4) : const Color.fromRGBO(255, 255, 255, .2)),
      ),
      child: Stack(
        children: [
          // `inset 0 2px 4px rgba(0,0,0,.3)`.
          Positioned.fill(
            child: CssBox(radius: BorderRadius.circular(999), clip: true, shadows: const [CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .3))]),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(.34, 1.56, .64, 1),
            left: paa ? 20 : 2,
            top: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE4ECEE)]),
                boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), offset: Offset(0, 2), blurRadius: 5 / 2 / .57735)],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The mint check of the chosen level (`klask .4s`).
class _Hake extends StatelessWidget {
  const _Hake();

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: 400,
    builder: (context, t, child) {
      final p = kfP(t, 0, 400);
      const c = Cubic(.3, 1.4, .5, 1);
      final s = kf(p, const [0, .6, 1], const [1.15, .98, 1], c);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(scale: s, child: child),
      );
    },
    child: Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB4F9E2), Color(0xFF5CE0B8)]),
        boxShadow: [BoxShadow(color: Color.fromRGBO(92, 224, 184, .6), blurRadius: 14 / 2 / .57735)],
      ),
      child: const AeIkon('M5 12.5l4.5 4.5L19 7.5', size: 13, stroke: 3.6, color: Color(0xFF0F2B33)),
    ),
  );
}

class _Pil extends StatelessWidget {
  const _Pil();

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color.fromRGBO(255, 255, 255, .12),
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
    ),
    child: const AeIkon('M9 6l6 6-6 6', size: 11, stroke: 3),
  );
}

/// The two keys under the list: «Hva Ægil vet» (glass) and «Ferdig» (orange).
class AegilInnstKnapper extends StatelessWidget {
  const AegilInnstKnapper({super.key, required this.onHvaVet, required this.onFerdig});

  final VoidCallback onHvaVet;
  final VoidCallback onFerdig;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AePress(
          key: const Key('ae-innst-hva-vet'),
          onTap: onHvaVet,
          dy: 2,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)]),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .22)),
            ),
            child: Text(AeInnstCopy.hvaVet, style: inter(13.5, weight: FontWeight.w800)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AePress(
          key: const Key('ae-innst-ferdig'),
          onTap: onFerdig,
          dy: 2,
          child: CssBox(
            height: 52,
            radius: BorderRadius.circular(999),
            bg: const [
              CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
            ],
            shadows: const [
              CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .45)),
              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
              CssShadow(0, 3, 0, 0, Color(0xFFC4491A)),
              CssShadow(0, 5, 0, 0, Color.fromRGBO(120, 45, 15, .22)),
              CssShadow(0, 14, 18, -10, Color.fromRGBO(200, 70, 25, .8)),
            ],
            child: Center(
              child: Text(AeInnstCopy.ferdig, style: inter(13.5, weight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    ],
  );
}
