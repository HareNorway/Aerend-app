import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/bergen_tokens.dart';
import '../../../utils/shared_pref_utill.dart' show resolveSelectedLanguage;
import '../../common/auth/launch/lf_css.dart' show CssBox, CssLinear, CssShadow;
import '../../common/auth/onboarding_kit.dart' show onbBlur;
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_fav_heart.dart';
import '../kit/bergen_motion.dart';
import '../kit/bergen_perf.dart';
import 'kategori_kort.dart';

/// Kategori › Butikker: the store module (Onboarding plan Step 5, §3 #15,
/// prototype `data-screen-label="Butikkmodul"` L6745–6826): the cream card
/// with the header row (logo tile, name, bike · fee · eta · ★, chips, heart,
/// arrow) and the draggable product rail with its own physics (`bmSpor` …
/// `bmHjul` L19802–19900), ending with «Se hele menyen · N retter».

/// One tile of the rail (`BM_VARER` → `flis`).
class KatModulVare {
  const KatModulVare({
    required this.id,
    required this.storeId,
    required this.navn,
    required this.prisTx,
    this.forTx,
    this.bildeUrl,
    this.ikon = 'ico_mat',
    this.tint = const [Color(0xFFF6D9B4), Color(0xFFD2854A)],
  });

  final int id;
  final int storeId;
  final String navn;
  final String prisTx;

  /// The old price, struck through (`harFor`).
  final String? forTx;
  final String? bildeUrl;

  /// The 3D icon when there is no photo (`assets/images/kategori/<ikon>.svg`).
  final String ikon;

  /// The tile's gradient (165deg) behind the icon.
  final List<Color> tint;

  bool get foto => bildeUrl != null && bildeUrl!.isNotEmpty;
}

/// The tile icon for a product name, by the design's `BILDE` keywords, else
/// the category's icon (`IKO`: mat, fisk, mote, interior, gaver by slot).
String katVareIkon(String navn, int slot) {
  final n = navn.toLowerCase();
  bool har(List<String> ord) => ord.any(n.contains);
  if (har(['pizza', 'margherita', 'diavola', 'pepperoni'])) return 'pi_pizza';
  if (har(['wok', 'pad thai', 'nudler', 'nudel', 'vårrull', 'varrull'])) return 'pi_wok';
  if (har(['suppe', 'bolle', 'ramen', 'miso', 'edamame', 'skjell', 'gryte'])) return 'pi_bolle';
  if (har(['brød', 'brod', 'focaccia', 'calzone', 'hvitløk', 'grateng', 'bakst', 'smørbrød'])) return 'pi_ovn';
  if (har(['kylling', 'chicken', 'nugget', 'wings'])) return 'ico_kylling';
  if (har(['pommes', 'frites', 'fries', 'løkring', 'lokring', 'chips'])) return 'ico_frites';
  if (har(['cola', 'brus', 'milkshake', 'shake', 'drikke', 'juice', 'vann', 'kaffe', 'øl', 'fanta', 'sprite'])) return 'ico_brus';
  if (har(['burger', 'cheese', 'whopper'])) return 'ico_burger';
  if (har(['fisk', 'laks', 'reke', 'sushi', 'torsk', 'krabbe', 'hummer', 'sjømat', 'skrei', 'sei ', 'makrell', 'sild'])) return 'ico_fisk';
  if (har(['gave', 'gift'])) return 'ico_gaver';
  if (har(['genser', 'skjorte', 'jeans', 'bukse', 'jakke', 'kjole', 'sko', 'lue', 'skjerf', 'votter', 'sokker', 'kåpe', 'anorakk', 'vest', 't-skjorte'])) return 'ico_mote';
  if (har(['lys', 'pute', 'pledd', 'lampe', 'vase', 'krukke', 'kopp', 'fat', 'glass', 'kurv', 'brett', 'krakk', 'karaffel', 'bestikk'])) return 'ico_interior';
  return const ['ico_mat', 'ico_fisk', 'ico_mote', 'ico_interior', 'ico_gaver'][slot.clamp(0, 4)];
}

/// The tile tint for an icon (the design's per-product gradients), else one
/// of its five generic tints by place.
List<Color> katVareTint(String ikon, int nr) => switch (ikon) {
  'ico_frites' => const [Color(0xFFFCE7B8), Color(0xFFE8A64B)],
  'ico_kylling' => const [Color(0xFFF6DCA8), Color(0xFFC98A3A)],
  'ico_burger' => const [Color(0xFFF6E7C8), Color(0xFFD9A254)],
  'ico_brus' => const [Color(0xFFF28B7E), Color(0xFFB7261E)],
  'pi_pizza' => const [Color(0xFFF2C9A0), Color(0xFFC97A4A)],
  'pi_wok' => const [Color(0xFFF0B8A8), Color(0xFFA8352E)],
  'pi_bolle' => const [Color(0xFFE9D6C4), Color(0xFF9E6E4E)],
  'pi_ovn' => const [Color(0xFFF6EBD6), Color(0xFFC9A46E)],
  'ico_fisk' => const [Color(0xFFF6D6CC), Color(0xFFD4705A)],
  _ => _kTint[nr % _kTint.length],
};

const List<List<Color>> _kTint = [
  [Color(0xFFF6D9B4), Color(0xFFD2854A)],
  [Color(0xFFCFE3E8), Color(0xFF6FA3B2)],
  [Color(0xFFF0D2C4), Color(0xFFB9634A)],
  [Color(0xFFE4E8D2), Color(0xFF94A86A)],
  [Color(0xFFE9DCEB), Color(0xFF9B7AA6)],
];

/// A column of the rail: one large tile (206×172) or two small (132×82);
/// the design's alternation, seven columns at most (`bmModul`).
class KatModulKolonne {
  const KatModulKolonne(this.w, this.fliser, {required this.stor});
  final double w;
  final List<KatModulVare> fliser;
  final bool stor;

  static List<KatModulKolonne> lag(List<KatModulVare> v) {
    final kol = <KatModulKolonne>[];
    var j = 0, c = 0;
    while (j < v.length && kol.length < 7) {
      if (c.isEven) {
        kol.add(KatModulKolonne(206, [v[j]], stor: true));
        j += 1;
      } else if (j + 1 < v.length) {
        kol.add(KatModulKolonne(132, [v[j], v[j + 1]], stor: false));
        j += 2;
      } else {
        kol.add(KatModulKolonne(132, [v[j]], stor: true));
        j += 1;
      }
      c++;
    }
    return kol;
  }
}

/// The rail's physics as the design has it (`bmSpor`, `bmNed/Flytt/Opp`,
/// `bmAnimer`), in unscaled px so the tests can read it.
abstract final class BmFysikk {
  /// Snap stops: every column's left edge less the 12 px padding, clamped
  /// to the scroll range, plus the end — unique, ascending (`stopp`).
  static List<double> stopp(List<double> kolVenstre, double maks, {double pad = 12}) {
    final s = <double>{for (final l in kolVenstre) (l - pad).clamp(0, maks).roundToDouble(), maks.roundToDouble()}.toList()..sort();
    return s;
  }

  /// Rubber band past the ends: `pow .82 × .55` (`bmFlytt`).
  static double gummi(double x, double maks) {
    if (x < 0) return -math.pow(-x, .82) * .55;
    if (x > maks) return maks + math.pow(x - maks, .82) * .55;
    return x;
  }

  static double naermest(List<double> stopp, double x) {
    if (stopp.isEmpty) return 0;
    var m = stopp.first;
    for (final s in stopp) {
      if ((s - x).abs() < (m - x).abs()) m = s;
    }
    return m;
  }

  /// Where a release lands: the nearest stop to `x + v·.22`, v clamped ±2600.
  static double maal(List<double> stopp, double maks, double x, double v) {
    final vv = v.clamp(-2600.0, 2600.0);
    return naermest(stopp, (x + vv * .22).clamp(0, maks));
  }

  /// One spring step (ω 9.5, ζ .96), dt capped at 34 ms (`bmAnimer`).
  static (double x, double v) fjaer(double x, double v, double til, double dt) {
    const w = 9.5, z = .96;
    final d = math.min(.034, dt);
    final v2 = v + (w * w * (til - x) - 2 * z * w * v) * d;
    return (x + v2 * d, v2);
  }

  static bool ferdig(double x, double v, double til, double sk) => (til - x).abs() < .2 && v.abs() < 6 && sk.abs() < .04;

  /// The skew after speed, up to 2.6° (`bmSett`).
  static double skjevMaal(double v) => (-v * .0016).clamp(-2.6, 2.6);
}

/// The module.
class KatButikkModul extends StatelessWidget {
  const KatButikkModul({
    super.key,
    required this.b,
    required this.varer,
    required this.antall,
    required this.enhet,
    required this.provd,
    required this.onTap,
    required this.onLegg,
    this.frakt,
    this.fraktGratis = false,
    this.ratingKort,
    this.seHeleMenyen = 'Se hele menyen',
  });

  final KatButikkVis b;
  final List<KatModulVare> varer;

  /// The store's live product count (`antallTx`), null until known.
  final int? antall;

  /// «retter» / «varer».
  final String enhet;

  /// The customer has ordered here (`besokt` → «PRØVD»).
  final bool provd;
  final VoidCallback onTap;

  /// «+»: a real cart line; true when it landed (the mint check for 1.6 s).
  final Future<bool> Function(KatModulVare v) onLegg;
  final String? frakt;
  final bool fraktGratis;
  final String? ratingKort;
  final String seHeleMenyen;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final farge = kKatFarge[b.nr % 4];
    return KatSvevKort(
      key: ValueKey('kat-bm-${b.id}'),
      perspektiv: 1100,
      svevMs: 10000,
      faseMs: b.nr * 2700,
      tiltK: 9,
      trykk: .985,
      onTap: onTap,
      builder: (context, lys) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -10 * s,
            right: -10 * s,
            top: 40 * s,
            bottom: -34 * s,
            child: katZ(
              -60 * s,
              IgnorePointer(
                child: Opacity(
                  opacity: .45,
                  child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [farge, farge.withValues(alpha: 0)]))),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * s),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBF5), Color(0xFFF7EEE2)]),
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .55), spreadRadius: 1),
                BoxShadow(color: rgba(4, 18, 26, .25), offset: Offset(0, 3 * s)),
                BoxShadow(color: rgba(4, 18, 26, .85), offset: Offset(0, 30 * s), blurRadius: onbBlur(40 * s), spreadRadius: -22 * s),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30 * s),
              child: Stack(
                children: [
                  const Positioned.fill(child: IgnorePointer(child: KatHolo(farger: kKatHoloLys, stopp: kKatHoloLysStopp))),
                  bergenInsetTop(radius: 30 * s, height: 1.5 * s, alpha: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Hode(b: b, provd: provd, frakt: frakt, fraktGratis: fraktGratis, ratingKort: ratingKort),
                        SizedBox(height: 4 * s),
                        _Rail(
                          key: ValueKey('rail-${b.id}-${varer.length}'),
                          butikkId: b.id,
                          nr: b.nr,
                          kolonner: KatModulKolonne.lag(varer),
                          antallTx: antall == null ? '' : '$antall $enhet',
                          seHeleMenyen: seHeleMenyen,
                          onSlutt: onTap,
                          onLegg: onLegg,
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
    );
  }
}

// ── Header row ──────────────────────────────────────────────────────────────

const Color _kInk = Color(0xFF23201D);
const Color _kGra = Color(0xFF6E675D);
const Color _kGronn = Color(0xFF1E8F72);

class _Hode extends StatelessWidget {
  const _Hode({required this.b, required this.provd, required this.frakt, required this.fraktGratis, required this.ratingKort});
  final KatButikkVis b;
  final bool provd;
  final String? frakt;
  final bool fraktGratis;
  final String? ratingKort;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final fraktFarge = fraktGratis ? _kGronn : _kGra;
    final linje = bText(context, 11.5, weight: FontWeight.w700, color: _kGra);
    Widget prikk() => Container(width: 3 * s, height: 3 * s, margin: EdgeInsets.symmetric(horizontal: 5 * s), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB5AC9F)));
    final deler = <Widget>[
      if (frakt != null) Text(frakt!, style: linje.copyWith(fontWeight: FontWeight.w800, color: fraktFarge)),
      if (b.eta != null) Text(b.eta!, style: linje),
      if (ratingKort != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          CustomPaint(size: Size.square(11 * s), painter: const _StjerneMaler()),
          SizedBox(width: 3 * s),
          Text(ratingKort!, style: linje),
        ]),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogoFlis(b: b),
          SizedBox(width: 11 * s),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.navn, maxLines: 1, overflow: TextOverflow.ellipsis, style: bDisplay(context, 17, letterSpacingEm: -.025, height: 1.15, color: _kInk)),
                  SizedBox(height: 3 * s),
                  ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(children: [
                        CustomPaint(size: Size.square(14 * s), painter: _SykkelMaler(fraktFarge, 2 * s)),
                        SizedBox(width: 5 * s),
                        for (var i = 0; i < deler.length; i++) ...[if (i > 0) prikk(), deler[i]],
                      ]),
                    ),
                  ),
                  if (b.tag != null || provd || b.live != null) ...[
                    SizedBox(height: 7 * s),
                    ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(children: [
                          if (b.tag != null) ...[_Brikke(tekst: b.tag!, bg: _kInk, fg: const Color(0xFFF6D27A)), SizedBox(width: 6 * s)],
                          if (provd) ...[_Brikke(tekst: KatModulCopy.provd, bg: rgba(47, 184, 147, .14), fg: _kGronn, hake: true), SizedBox(width: 6 * s)],
                          if (b.live != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const _Puls(),
                              SizedBox(width: 5 * s),
                              Text(KatModulCopy.bestillerNaa(b.live!), style: bText(context, 11, weight: FontWeight.w700, color: _kGra)),
                            ]),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 7 * s),
          if (b.id > 0) BergenFavHeart(storeId: b.id, size: 36 * s, iconSize: 16 * s, burst: true, burstFarge: kKatFarge[b.nr % kKatFarge.length], navn: b.navn),
          SizedBox(width: 7 * s),
          KatRundKnapp(size: 42, ikon: 'M5 12h13M13 6l6 6-6 6', ikonPx: 18, strek: 2.8, onTap: () {}),
        ],
      ),
    );
  }
}

/// The 54 px logo tile: the store's logo, else its initials on a gradient (`lMono`).
class _LogoFlis extends StatelessWidget {
  const _LogoFlis({required this.b});
  final KatButikkVis b;

  static const List<List<Color>> _mono = [
    [Color(0xFFF2884E), Color(0xFFC2410C)],
    [Color(0xFF3F8798), Color(0xFF1E4F5C)],
    [Color(0xFFE2453F), Color(0xFFA3172A)],
    [Color(0xFFF0A93B), Color(0xFFA85A12)],
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final url = b.logoUrl;
    final mono = b.navn.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 54 * s,
      height: 54 * s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * s),
        boxShadow: [
          BoxShadow(color: rgba(35, 32, 29, .06), spreadRadius: 1),
          BoxShadow(color: rgba(90, 74, 48, .16), offset: Offset(0, 3 * s)),
          BoxShadow(color: rgba(4, 18, 26, .45), offset: Offset(0, 12 * s), blurRadius: onbBlur(16 * s), spreadRadius: -8 * s),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14 * s),
        child: url != null && url.isNotEmpty
            ? SizedBox(width: 44 * s, height: 44 * s, child: _foto(url, BoxFit.contain))
            : Container(
                width: 44 * s,
                height: 44 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14 * s),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _mono[b.nr % 4]),
                ),
                child: Text(mono.length > 2 ? mono.substring(0, 2) : mono, style: bDisplay(context, 16, letterSpacingEm: -.02, color: Colors.white)),
              ),
      ),
    );
  }
}

class _Brikke extends StatelessWidget {
  const _Brikke({required this.tekst, required this.bg, required this.fg, this.hake = false});
  final String tekst;
  final Color bg, fg;
  final bool hake;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      height: 24 * s,
      padding: EdgeInsets.fromLTRB(hake ? 7 * s : 9 * s, 0, 9 * s, 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (hake) ...[CustomPaint(size: Size.square(10 * s), painter: _HakeMaler(fg, 3.6 * s / 2.4)), SizedBox(width: 4 * s)],
        Text(tekst, style: bText(context, 9.5, weight: FontWeight.w800, letterSpacingEm: .07, color: fg)),
      ]),
    );
  }
}

/// The 6 px pulse dot (`bmPuls 1.8s`).
class _Puls extends StatelessWidget {
  const _Puls();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return SizedBox(
      width: 6 * s,
      height: 6 * s,
      child: BergenLoop(
        durationMs: 1800,
        builder: (context, p, _) {
          final q = p ?? 0;
          final ring = q < .7 ? q / .7 : 1.0;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE95C2C),
              boxShadow: [BoxShadow(color: const Color(0xFFE95C2C).withValues(alpha: .55 * (1 - ring)), spreadRadius: 7 * s * ring)],
            ),
          );
        },
      ),
    );
  }
}

// ── The rail ────────────────────────────────────────────────────────────────

class _Rail extends StatefulWidget {
  const _Rail({super.key, required this.butikkId, required this.nr, required this.kolonner, required this.antallTx, required this.seHeleMenyen, required this.onSlutt, required this.onLegg});
  final int butikkId;
  final int nr;
  final List<KatModulKolonne> kolonner;
  final String antallTx;
  final String seHeleMenyen;
  final VoidCallback onSlutt;
  final Future<bool> Function(KatModulVare v) onLegg;

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> with SingleTickerProviderStateMixin {
  Ticker? _tick;
  double _x = 0, _v = 0, _sk = 0, _til = 0;
  Duration? _sist;

  // Drag (`bmNed/Flytt/Opp`): the start offset and the velocity samples.
  double _mx = 0, _raa = 0;
  final List<(int, double)> _pkt = [];
  bool _drar = false;

  // Layout, in logical px (set in build).
  double _W = 0, _maks = 0, _innhold = 0;
  List<double> _stopp = const [0];
  List<double> _kolVenstre = const [];

  final Set<int> _lagt = {};

  @override
  void dispose() {
    _tick?.dispose();
    super.dispose();
  }

  bool get _rolig => BergenPerf.of(context) == BergenTier.still || MediaQuery.disableAnimationsOf(context);

  void _maal(double W, double s) {
    final gap = 8 * s, pad = 12 * s;
    final v = <double>[];
    var x = pad;
    for (final k in widget.kolonner) {
      v.add(x);
      x += k.w * s + gap;
    }
    v.add(x); // the end tile
    _innhold = x + 104 * s + pad;
    _W = W;
    _maks = math.max(0, _innhold - W);
    _kolVenstre = v;
    _stopp = BmFysikk.stopp(v.map((e) => e / s).toList(), _maks / s, pad: 12).map((e) => e * s).toList();
  }

  void _sett(double x, double vps) {
    final maal = BmFysikk.skjevMaal(vps / (context.bs));
    _sk += (maal - _sk) * .18;
    setState(() => _x = x);
  }

  // ── Drag ──
  void _ned(DragStartDetails d) {
    _tick?.stop();
    _sist = null;
    _drar = true;
    _mx = _x;
    _raa = _x;
    _pkt
      ..clear()
      ..add((DateTime.now().millisecondsSinceEpoch, d.globalPosition.dx));
  }

  void _flytt(DragUpdateDetails d) {
    if (!_drar) return;
    final nu = DateTime.now().millisecondsSinceEpoch;
    _pkt.add((nu, d.globalPosition.dx));
    while (_pkt.length > 2 && nu - _pkt.first.$1 > 90) {
      _pkt.removeAt(0);
    }
    final s = context.bs;
    // The finger's raw offset, then the rubber band past the ends.
    _raa -= d.delta.dx;
    _mx = BmFysikk.gummi(_raa / s, _maks / s) * s;
    // The row glides after the finger (`cur + (mx − cur) · .55` per frame).
    final cur = _x, ny = cur + (_mx - cur) * .55;
    _sett((_mx - ny).abs() < .1 ? _mx : ny, _fart() * s);
  }

  double _fart() {
    if (_pkt.length < 2) return 0;
    final (t0, x0) = _pkt.first;
    final (t1, x1) = _pkt.last;
    final dt = math.max(16, t1 - t0);
    return -((x1 - x0) / context.bs) / dt * 1000;
  }

  void _opp(DragEndDetails d) {
    if (!_drar) return;
    _drar = false;
    final s = context.bs;
    final nu = DateTime.now().millisecondsSinceEpoch;
    var v = _pkt.isEmpty || nu - _pkt.last.$1 > 80 ? 0.0 : _fart();
    v = v.clamp(-2600.0, 2600.0);
    final til = BmFysikk.maal(_stopp.map((e) => e / s).toList(), _maks / s, _mx / s, v) * s;
    _animer(til, v * s);
  }

  void _animer(double til, double v0) {
    _til = til;
    _v = v0;
    if (_rolig) {
      _sk = 0;
      setState(() => _x = til);
      return;
    }
    _sist = null;
    final t = _tick ??= createTicker(_steg);
    if (!t.isActive) t.start();
  }

  void _steg(Duration t) {
    final dt = _sist == null ? .016 : (t - _sist!).inMicroseconds / 1e6;
    _sist = t;
    final s = context.bs;
    final (x, v) = BmFysikk.fjaer(_x / s, _v / s, _til / s, dt);
    _v = v * s;
    final ferdig = BmFysikk.ferdig(x, v, _til / s, _sk);
    if (ferdig) {
      _tick?.stop();
      _sk = 0;
      setState(() => _x = _til);
    } else {
      _sett(x * s, v * s);
    }
  }

  Future<void> _legg(KatModulVare v) async {
    final ok = await widget.onLegg(v);
    if (!ok || !mounted) return;
    setState(() => _lagt.add(v.id));
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _lagt.remove(v.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return LayoutBuilder(
      builder: (context, c) {
        final W = c.maxWidth;
        if (W != _W) _maal(W, s);
        final rolig = _rolig;
        final skew = rolig || _sk.abs() < .03 ? 0.0 : _sk * math.pi / 180;
        final tw = math.max(10 * s, (48 * s * W / math.max(W, _innhold)).roundToDouble());
        final frem = _maks > 0 ? (_x / _maks).clamp(0.0, 1.0) * (48 * s - tw) : 0.0;
        final kol = <Widget>[];
        for (var q = 0; q < widget.kolonner.length; q++) {
          final k = widget.kolonner[q];
          final senter = _kolVenstre[q] + k.w * s / 2;
          kol.add(Positioned(
            left: _kolVenstre[q],
            top: 0,
            width: k.w * s,
            child: _KolInn(
              delayMs: (0.2 + widget.nr * 0.07 + q * 0.08) * 1000,
              rolig: rolig,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.skewX(skew),
                child: Column(
                  children: [
                    for (var i = 0; i < k.fliser.length; i++) ...[
                      if (i > 0) SizedBox(height: 8 * s),
                      _Flis(
                        key: q == 0 && i == 0 ? Key('kat-modul-flis-${widget.butikkId}') : null,
                        plussKey: q == 0 && i == 0 ? Key('kat-modul-pluss-${widget.butikkId}') : null,
                        v: k.fliser[i],
                        stor: k.stor,
                        w: k.w * s,
                        h: (k.stor ? 172 : 82) * s,
                        // Parallax ±7 % of the tile, from the column's place in the viewport.
                        par: ((senter - _x - W / 2) * .045).clamp(-k.w * s * .07, k.w * s * .07),
                        lagt: _lagt.contains(k.fliser[i].id),
                        onLegg: () => _legg(k.fliser[i]),
                        bobDelayMs: -((i * 1.3 + widget.nr) % 4) * 1000,
                        rolig: rolig,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ));
        }
        final q = widget.kolonner.length;
        kol.add(Positioned(
          left: _kolVenstre.last,
          top: 0,
          width: 104 * s,
          height: 172 * s,
          child: _KolInn(
            delayMs: (0.2 + widget.nr * 0.07 + q * 0.08) * 1000,
            rolig: rolig,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.skewX(skew),
              child: _Slutt(key: Key('kat-modul-slutt-${widget.butikkId}'), tekst: widget.seHeleMenyen, antallTx: widget.antallTx, onTap: widget.onSlutt),
            ),
          ),
        ));
        return Column(
          children: [
            GestureDetector(
              key: Key('kat-modul-rail-${widget.butikkId}'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _ned,
              onHorizontalDragUpdate: _flytt,
              onHorizontalDragEnd: _opp,
              onHorizontalDragCancel: () => _drar = false,
              child: ClipRect(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 18 * s, 0, 4 * s),
                  child: SizedBox(
                    height: 172 * s,
                    width: W,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -_x,
                          top: 0,
                          width: _innhold,
                          height: 172 * s,
                          child: Stack(clipBehavior: Clip.none, children: kol),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 9 * s),
            IgnorePointer(
              child: Container(
                width: 48 * s,
                height: 4 * s,
                decoration: BoxDecoration(color: rgba(35, 32, 29, .1), borderRadius: BorderRadius.circular(2 * s)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(frem, 0),
                    child: Container(
                      width: tw,
                      height: 4 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2 * s),
                        gradient: const LinearGradient(colors: [Color(0xFFF9A273), Color(0xFFF26D3D)]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `bmKolInn .62s <delay> cubic-bezier(.2,.9,.3,1.08)`: from 46 px right, scale .92.
class _KolInn extends StatelessWidget {
  const _KolInn({required this.delayMs, required this.rolig, required this.child});
  final double delayMs;
  final bool rolig;
  final Widget child;
  static const Curve _c = Cubic(.2, .9, .3, 1.08);

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    final s = context.bs;
    return BergenOnce(
      durationMs: 620,
      delayMs: delayMs,
      child: child,
      builder: (context, p, child) {
        final e = _c.transform(p);
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(46 * s * (1 - e), 0, 0, 1)
              ..scaleByDouble(.92 + .08 * e, .92 + .08 * e, 1, 1),
            child: child,
          ),
        );
      },
    );
  }
}

/// One tile: tinted gradient or photo, the floating 3D icon, the name·price
/// pill, the «+» (→ check for 1.6 s).
class _Flis extends StatelessWidget {
  const _Flis({
    super.key,
    this.plussKey,
    required this.v,
    required this.stor,
    required this.w,
    required this.h,
    required this.par,
    required this.lagt,
    required this.onLegg,
    required this.bobDelayMs,
    required this.rolig,
  });
  final Key? plussKey;
  final KatModulVare v;
  final bool stor;
  final double w, h, par;
  final bool lagt;
  final VoidCallback onLegg;
  final double bobDelayMs;
  final bool rolig;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(20 * s);
    final ikS = (stor ? 116 : 60) * s;
    final foto = v.foto;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CssBox(
              radius: r,
              clip: true,
              bg: [
                if (foto) const CssLinear(165, [Color(0xFF2A1208), Color(0xFF2A1208)]) else CssLinear(165, v.tint),
              ],
              shadows: [
                CssShadow.inset(0, 1.5 * s, 0, 0, rgba(255, 255, 255, .5)),
                CssShadow.inset(0, -14 * s, 22 * s, -14 * s, rgba(40, 16, 4, .45)),
                CssShadow(0, 1 * s, 0, 0, rgba(255, 255, 255, .8)),
                CssShadow(0, 12 * s, 18 * s, -12 * s, rgba(40, 20, 8, .6)),
              ],
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (foto)
                    // The photo is 16 % wider than the tile and slides with the rail (`data-bmpar`).
                    Positioned(
                      left: -w * .08 - par,
                      right: -w * .08 + par,
                      top: 0,
                      bottom: 0,
                      child: _foto(v.bildeUrl!, BoxFit.cover),
                    )
                  else
                    Positioned(
                      left: w / 2 - ikS / 2,
                      top: h * .56 - ikS / 2,
                      width: ikS,
                      height: ikS,
                      child: Stack(children: [
                        Positioned(
                          left: ikS * .14,
                          right: ikS * .14,
                          bottom: ikS * .02,
                          height: ikS * .12,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x66281004), Color(0x00281004)])),
                          ),
                        ),
                        Positioned.fill(
                          child: _Flyt(
                            delayMs: bobDelayMs,
                            rolig: rolig,
                            child: SvgPicture.asset('assets/images/kategori/${v.ikon}.svg', fit: BoxFit.contain),
                          ),
                        ),
                      ]),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(decoration: BoxDecoration(borderRadius: r, border: Border.all(color: rgba(0, 0, 0, .07)))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8 * s,
            top: 8 * s,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w - 16 * s),
              child: _Pille(navn: stor ? v.navn : null, prisTx: v.prisTx, forTx: v.forTx),
            ),
          ),
          Positioned(
            right: 7 * s,
            bottom: 7 * s,
            child: _Pluss(key: plussKey, lagt: lagt, onTap: onLegg, navn: v.navn),
          ),
        ],
      ),
    );
  }
}

/// `bmFlyt 4.6s`: up 4 px, ±1.5°.
class _Flyt extends StatelessWidget {
  const _Flyt({required this.delayMs, required this.rolig, required this.child});
  final double delayMs;
  final bool rolig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (rolig) return child;
    final s = context.bs;
    return BergenLoop(
      durationMs: 4600,
      delayMs: delayMs,
      child: child,
      builder: (context, p, child) {
        final q = p ?? 0;
        final e = .5 - .5 * math.cos(q * 2 * math.pi); // 0 → 1 → 0, ease-in-out
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(0, -4 * s * e, 0, 1)
            ..rotateZ((-1.5 + 3 * e) * math.pi / 180),
          child: child,
        );
      },
    );
  }
}

/// The dark name · price pill (`rgba(14,30,36,.8)` + blur 10).
class _Pille extends StatelessWidget {
  const _Pille({required this.navn, required this.prisTx, required this.forTx});
  final String? navn;
  final String prisTx;
  final String? forTx;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final hvit = bText(context, 11.5, weight: FontWeight.w800, letterSpacingEm: -.005, color: Colors.white);
    final inner = Container(
      height: 26 * s,
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: BoxDecoration(
        color: rgba(14, 30, 36, .8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: rgba(0, 0, 0, .6), offset: Offset(0, 6 * s), blurRadius: onbBlur(12 * s), spreadRadius: -6 * s)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (navn != null) Flexible(child: Text('$navn · ', maxLines: 1, overflow: TextOverflow.ellipsis, style: hvit)),
        Text(prisTx, style: hvit.copyWith(color: forTx != null ? const Color(0xFFFFB38A) : Colors.white)),
        if (forTx != null) ...[
          SizedBox(width: 5 * s),
          Text(forTx!, style: hvit.copyWith(fontWeight: FontWeight.w700, color: rgba(255, 255, 255, .55), decoration: TextDecoration.lineThrough, decorationColor: rgba(255, 255, 255, .55))),
        ],
      ]),
    );
    if (!BergenPerf.blurOn(context, secondary: true)) return inner;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(filter: BergenPerf.blur(context, 10), child: inner),
    );
  }
}

/// The white «+» (32 px) → the mint check (`bmHak .4s cubic(.3,1.6,.5,1)`).
class _Pluss extends StatefulWidget {
  const _Pluss({super.key, required this.lagt, required this.onTap, required this.navn});
  final bool lagt;
  final VoidCallback onTap;
  final String navn;

  @override
  State<_Pluss> createState() => _PlussState();
}

class _PlussState extends State<_Pluss> {
  bool _ned = false;
  static const Curve _hak = Cubic(.3, 1.6, .5, 1);

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Semantics(
      button: true,
      label: KatModulCopy.leggIKurven(widget.navn),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _ned = true),
        onTapCancel: () => setState(() => _ned = false),
        onTapUp: (_) => setState(() => _ned = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32 * s,
          height: 32 * s,
          transform: Matrix4.identity()
            ..translateByDouble(0, _ned ? 2 * s : 0, 0, 1)
            ..scaleByDouble(_ned ? .9 : 1, _ned ? .9 : 1, 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFF1ECE1)]),
            boxShadow: [
              BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1),
              BoxShadow(color: const Color(0xFFD9D2C4), offset: Offset(0, 2 * s)),
              BoxShadow(color: rgba(90, 74, 48, .3), offset: Offset(0, 3 * s)),
              BoxShadow(color: rgba(35, 32, 29, .6), offset: Offset(0, 8 * s), blurRadius: onbBlur(12 * s), spreadRadius: -6 * s),
            ],
          ),
          child: Center(
            child: widget.lagt
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: BergenTokens.motion(context, const Duration(milliseconds: 400)),
                    curve: _hak,
                    builder: (context, p, child) => Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.scale(scale: .3 + .7 * p, child: child)),
                    child: CustomPaint(size: Size.square(14 * s), painter: _HakeMaler(_kGronn, 3.6 * s * 14 / 24)),
                  )
                : CustomPaint(size: Size.square(14 * s), painter: _PlussMaler(const Color(0xFFF26D3D), 3.4 * s * 14 / 24)),
          ),
        ),
      ),
    );
  }
}

/// The teal end tile «Se hele menyen · N retter» (104×172).
class _Slutt extends StatelessWidget {
  const _Slutt({super.key, required this.tekst, required this.antallTx, required this.onTap});
  final String tekst, antallTx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CssBox(
        radius: BorderRadius.circular(20 * s),
        clip: true,
        bg: const [
          CssLinear(165, [Color(0xFF2A6272), Color(0xFF1E4F5C), Color(0xFF173F4A)], [0, .6, 1]),
        ],
        shadows: [
          CssShadow.inset(0, 1.5 * s, 0, 0, rgba(255, 255, 255, .24)),
          CssShadow(0, 12 * s, 18 * s, -12 * s, rgba(4, 18, 26, .7)),
        ],
        padding: EdgeInsets.symmetric(horizontal: 10 * s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IgnorePointer(child: KatRundKnapp(size: 44, ikon: 'M5 12h13M13 6l6 6-6 6', ikonPx: 18, strek: 2.8, onTap: () {})),
            SizedBox(height: 10 * s),
            Text(tekst, textAlign: TextAlign.center, style: bText(context, 12.5, weight: FontWeight.w800, height: 1.2, color: Colors.white)),
            if (antallTx.isNotEmpty) ...[
              SizedBox(height: 10 * s),
              Text(antallTx, textAlign: TextAlign.center, style: bText(context, 10.5, weight: FontWeight.w700, color: rgba(255, 255, 255, .66))),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small painters ──────────────────────────────────────────────────────────

class _SykkelMaler extends CustomPainter {
  const _SykkelMaler(this.color, this.w);
  final Color color;
  final double w;

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 14 / 24 / 2 * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawCircle(Offset(6 * k, 17 * k), 3.2 * k, p);
    c.drawCircle(Offset(18 * k, 17 * k), 3.2 * k, p);
    final path = Path()
      ..moveTo(6 * k, 17 * k)
      ..lineTo(10 * k, 9 * k)
      ..lineTo(15 * k, 9 * k)
      ..lineTo(18 * k, 17 * k)
      ..moveTo(10 * k, 9 * k)
      ..lineTo(15 * k, 9 * k)
      ..lineTo(12 * k, 17 * k)
      ..moveTo(14 * k, 6 * k)
      ..lineTo(17 * k, 6 * k);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SykkelMaler o) => o.color != color || o.w != w;
}

class _StjerneMaler extends CustomPainter {
  const _StjerneMaler();

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    final p = Path()..moveTo(12 * k, 3 * k);
    for (final d in const [[2.7, 5.6], [6.1, .8], [-4.5, 4.2], [1.1, 6], [-5.4, -3], [-5.4, 3], [1.1, -6], [-4.5, -4.2], [6.1, -.8]]) {
      p.relativeLineTo(d[0] * k, d[1] * k);
    }
    p.close();
    c.drawPath(p, Paint()..color = const Color(0xFFE9A23C));
  }

  @override
  bool shouldRepaint(_StjerneMaler o) => false;
}

class _HakeMaler extends CustomPainter {
  const _HakeMaler(this.color, this.w);
  final Color color;
  final double w;

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    c.drawPath(
      Path()
        ..moveTo(5 * k, 12.5 * k)
        ..lineTo(9.5 * k, 17 * k)
        ..lineTo(19 * k, 7.5 * k),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HakeMaler o) => o.color != color || o.w != w;
}

class _PlussMaler extends CustomPainter {
  const _PlussMaler(this.color, this.w);
  final Color color;
  final double w;

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(12 * k, 5 * k), Offset(12 * k, 19 * k), p);
    c.drawLine(Offset(5 * k, 12 * k), Offset(19 * k, 12 * k), p);
  }

  @override
  bool shouldRepaint(_PlussMaler o) => o.color != color || o.w != w;
}

Widget _foto(String url, BoxFit fit) => CachedNetworkImage(
  memCacheWidth: BergenPerf.decodeWidth,
  imageUrl: url,
  fit: fit,
  fadeInDuration: const Duration(milliseconds: 200),
  errorWidget: (_, _, _) => const SizedBox.shrink(),
);

/// The module's strings (NO / EN, the Kategori group's pattern).
abstract final class KatModulCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;
  static String get provd => _t('PRØVD', 'TRIED');
  static String get seHeleMenyen => _t('Se hele menyen', 'See the whole menu');
  static String get seAlleVarer => _t('Se alle varer', 'See all items');
  static String retter(int n) => _t('$n retter', '$n dishes');
  static String varer(int n) => _t('$n varer', '$n items');
  static String get enhetRetter => _t('retter', 'dishes');
  static String get enhetVarer => _t('varer', 'items');
  static String bestillerNaa(int n) => _t('$n bestiller nå', '$n ordering now');
  static String get gratis => _t('Gratis', 'Free');
  static String leggIKurven(String navn) => _t('Legg $navn i kurven', 'Add $navn to the basket');
}
