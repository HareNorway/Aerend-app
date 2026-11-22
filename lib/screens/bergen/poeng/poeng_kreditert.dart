import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../data/points/points_models.dart';
import '../../../ui/kit/ae_haptic.dart';
import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_motion.dart' show LfLoop;
import '../../common/home/bergen/bergen_kit.dart';
import '../../common/home/bergen/bergen_nav.dart' show BergenBottomNav;
import '../kasse/kasse_copy.dart' show KasseCopy;
import '../kit/ae_mynt.dart';
import '../kit/ae_primitiver.dart' show AeKnappPille, aeMyk;
import '../kit/bergen_videre.dart';
import '../lopet/lopet_copy.dart';
import '../meg/a3_services.dart';

/// Design 21 Nov plan Step 6 (A5, D4, D5): «Poeng kreditert» — the Fjordløpet points flying onto the balance when
/// the order is delivered.
///
/// The design's `kr*` timeline on one [AnimationController] (milliseconds since open, `t`): the dimmed backdrop, the
/// slowly turning gold rays, the glow, «FJORDLØPET · ÆRENDET ER LEVERT» with «Godt seilt!», the 128 px coin flipping
/// in (920 ms, rotateY 540° → 24° → −6° → 0) with its ring bursting, «+0» counting up row by row (1 000 + 440·i ms),
/// the rows with a pulse and six sparks each, the balance card sliding up (1 180 ms), then 8–18 coins (two per point)
/// shooting out of the big coin in bézier arcs to the card's coin, 52 ms apart, 820 ms each; every landing counts the
/// balance up one share, bumps the small coin, flashes the number, nudges the card and vibrates every third. At the
/// end: confetti, the level bar grows, its tip sparkles, Ægil hops in, «Fortsett» and «Se poengene dine». The coins,
/// sparks and confetti are one fixed pool on one [CustomPainter] (no widget per coin).
///
/// A tap anywhere skips to the end; reduced motion opens at the end. «Fortsett» fades the layer (260 ms) and bumps
/// the Meg tab's coin; «Se poengene dine» goes to Meg with the points card open. The rows are what the server
/// credited (`game.rows`, D5); the balance and the level are `points/me` after the grant — without it the card is
/// left out rather than computed.
class PoengKreditert extends StatefulWidget {
  const PoengKreditert({super.key, required this.data, this.onLukk});

  final KrData data;
  final VoidCallback? onLukk;

  /// Once per order, from the delivered Sporing (D4): the order's credited Fjordløpet rows and points > 0, never
  /// shown before for this order. Returns whether it opened.
  static Future<bool> kanskje(BuildContext context, int orderId, Map? game) async {
    final rader = KrData.raderFra(game);
    if (rader.isEmpty || prefGetBool(prefNokkel(orderId))) return false;
    // The grant happens at delivered on the server; a snapshot that says it is not credited yet waits.
    if (game != null && game.containsKey('credited_at') && game['credited_at'] == null) return false;
    await prefSetBool(prefNokkel(orderId), true);
    PointsBalance? b;
    try {
      b = await A3Services.points().balance().timeout(const Duration(seconds: 4));
    } catch (_) {}
    if (!context.mounted) return false;
    await vis(context, KrData.fra(rader, b));
    return true;
  }

  static String prefNokkel(int orderId) => 'lop_kreditert_$orderId';

  static Future<void> vis(BuildContext context, KrData data) => Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      settings: const RouteSettings(name: '/bergen/poeng-kreditert'),
      pageBuilder: (_, a, b) => PoengKreditert(data: data),
    ),
  );

  /// Debug harness (`kreditert: boye1 | boye2 | bryggen`): the design's `lopKreditering` «Spill av» cases, with the
  /// real balance when `points/me` answers.
  static Future<void> demo(BuildContext context, String v) async {
    if (!kDebugMode) return;
    final porter = LopetCopy.porter;
    final rader = switch (v) {
      'boye1' => [KrRad(tittel: KrCopy.nadd(porter[0]), under: KrCopy.besteSeilas(236), poeng: 3)],
      'bryggen' => [KrRad(tittel: KrCopy.nadd(porter[2]), under: KrCopy.besteSeilas(1046), poeng: 12), KrRad(tittel: KrCopy.nyRekord, under: KrCopy.nyRekordUnder, poeng: 3, rekord: true)],
      _ => [KrRad(tittel: KrCopy.nadd(porter[1]), under: KrCopy.besteSeilas(540), poeng: 6), KrRad(tittel: KrCopy.nyRekord, under: KrCopy.nyRekordUnder, poeng: 3, rekord: true)],
    };
    PointsBalance? b;
    try {
      b = await A3Services.points().balance().timeout(const Duration(seconds: 4));
    } catch (_) {}
    if (!context.mounted) return;
    await vis(context, KrData.fra(rader, b));
  }

  @override
  State<PoengKreditert> createState() => _PoengKreditertState();
}

// ── data ────────────────────────────────────────────────────────────────────

class KrRad {
  const KrRad({required this.tittel, required this.under, required this.poeng, this.rekord = false});
  final String tittel;
  final String under;
  final int poeng;
  final bool rekord;
}

class KrData {
  const KrData({required this.rader, this.til, this.oppTil, this.tiers = const [], this.nivaaNavn, this.nesteNavn, this.tilNeste, this.pct});

  final List<KrRad> rader;

  /// The spendable balance after the grant (`points.available`), null when `points/me` did not answer.
  final int? til;

  /// The level's points after the grant (`earned_12m`) and the ladder.
  final int? oppTil;
  final List<TierStep> tiers;

  /// Without a ladder: the level and the next as `points/me` says them.
  final String? nivaaNavn;
  final String? nesteNavn;
  final int? tilNeste;
  final double? pct;

  int get pg => rader.fold(0, (a, r) => a + r.poeng);
  int? get fra => til == null ? null : til! - pg;
  int? get oppFra => oppTil == null ? null : oppTil! - pg;

  /// The credited rows from the tracking snapshot's `game` (`rows`: `{reason, gate, points}`); an older server
  /// without rows gives one row from the gate and the total.
  static List<KrRad> raderFra(Map? game) {
    if (game == null) return const [];
    final porter = LopetCopy.porter;
    final bestM = (game['best_m'] as num?)?.toInt() ?? 0;
    String port(Object? g) {
      final i = (g as num?)?.toInt();
      return i != null && i >= 0 && i < porter.length ? porter[i] : '';
    }

    final rows = game['rows'];
    final out = <KrRad>[];
    if (rows is List) {
      for (final r in rows.whereType<Map>()) {
        final p = (r['points'] as num?)?.toInt() ?? 0;
        if (p <= 0) continue;
        if (r['reason'] == 'personal_best') {
          out.add(KrRad(tittel: KrCopy.nyRekord, under: KrCopy.nyRekordUnder, poeng: p, rekord: true));
        } else {
          final n = port(r['gate']);
          out.add(KrRad(tittel: n.isEmpty ? KrCopy.seilas : KrCopy.nadd(n), under: KrCopy.besteSeilas(bestM), poeng: p));
        }
      }
      return out;
    }
    final p = (game['points'] as num?)?.toInt() ?? 0;
    if (p > 0) {
      final n = port(game['gate']);
      out.add(KrRad(tittel: n.isEmpty ? KrCopy.seilas : KrCopy.nadd(n), under: KrCopy.besteSeilas(bestM), poeng: p));
    }
    return out;
  }

  factory KrData.fra(List<KrRad> rader, PointsBalance? b) => KrData(
    rader: rader,
    til: b?.available,
    oppTil: b?.earned12m,
    tiers: [...?b?.tiers]..sort((a, c) => a.threshold.compareTo(c.threshold)),
    nivaaNavn: b?.tierName,
    nesteNavn: b?.nextTierName,
    tilNeste: b?.pointsToNextTier,
    pct: b?.tierProgress,
  );

  int _niv(int opp) {
    var i = 0;
    for (var k = 0; k < tiers.length; k++) {
      if (opp >= tiers[k].threshold) i = k;
    }
    return i;
  }

  bool get harStige => tiers.length >= 2 && oppTil != null;
  int get i0 => harStige ? _niv(oppFra!) : 0;
  int get i1 => harStige ? _niv(oppTil!) : 0;
  String get navn => harStige ? tiers[i1].name : (nivaaNavn ?? '');
  bool get nyttNivaa => harStige && i1 > i0;
  TierStep? get neste => harStige && i1 + 1 < tiers.length ? tiers[i1 + 1] : null;

  double pctAv(int opp) {
    if (!harStige) return pct ?? 1;
    final i = i1, n = neste;
    if (n == null) return 1;
    return ((opp - tiers[i].threshold) / (n.threshold - tiers[i].threshold)).clamp(0.0, 1.0);
  }

  String nivTilTx(int opp) {
    if (harStige) {
      final n = neste;
      return n == null ? KrCopy.hoyeste : KrCopy.poengTil(KasseCopy.tall(n.threshold - opp), n.name);
    }
    return nesteNavn == null || tilNeste == null ? KrCopy.hoyeste : KrCopy.poengTil(KasseCopy.tall(tilNeste!), nesteNavn!);
  }
}

/// The overlay's texts (ARB `lop_kr_*`).
abstract final class KrCopy {
  static String get kicker => languages.lop_kr_kicker;
  static String get tittel => languages.lop_kr_tittel;
  static String get under => languages.lop_kr_under;
  static String get enhet => languages.lop_kr_enhet;
  static String nadd(String port) => languages.lop_kr_nadd(port);
  static String besteSeilas(int m) => languages.lop_kr_beste(KasseCopy.tall(m));
  static String get seilas => languages.lop_kr_seilas;
  static String get nyRekord => languages.lop_kr_rekord;
  static String get nyRekordUnder => languages.lop_kr_rekord_under;
  static String get saldo => languages.lop_kr_saldo;
  static String nyttNivaa(String n) => languages.lop_kr_nytt_nivaa(n);
  static String poengTil(String n, String niv) => languages.lop_kr_poeng_til(n, niv);
  static String get hoyeste => languages.lop_kr_hoyeste;
  static String get fortsett => languages.lop_kr_fortsett;
  static String get sePoengene => languages.lop_kr_se_poengene;
}

// ── the timeline ────────────────────────────────────────────────────────────

/// The design's times (ms) for a given row count and points.
class _Tid {
  _Tid(this.nR, int pg, {required this.medKort})
    : nc = medKort ? math.max(8, math.min(18, pg * 2)) : 0 {
    tFly = tR(nR) + 240;
    tEnd = medKort ? tFly + (nc - 1) * st + fl + 30 : tR(nR) + 300;
    total = tEnd + 1500;
  }

  final int nR;
  final bool medKort;
  final int nc;
  static const st = 52, fl = 820;
  late final int tFly, tEnd, total;
  int tR(int i) => 1000 + i * 440;
  int lander(int k) => tFly + k * st + fl;
}

double _seg(double t, num start, num dur, [Curve c = Curves.linear]) => c.transform(((t - start) / dur).clamp(0.0, 1.0));

/// Piecewise linear over keyframe [offsets] → [values] at progress [p].
double _kf(double p, List<double> offsets, List<double> values) {
  if (p <= offsets.first) return values.first;
  for (var i = 1; i < offsets.length; i++) {
    if (p <= offsets[i]) {
      final u = (p - offsets[i - 1]) / (offsets[i] - offsets[i - 1]);
      return values[i - 1] + (values[i] - values[i - 1]) * u;
    }
  }
  return values.last;
}

/// `puls`: scale 1 → [s] (35 %) → 1 over [dur] from [start].
double _puls(double t, num start, num dur, double s) {
  if (t < start || t > start + dur) return 1;
  final u = const Cubic(.3, 1.4, .5, 1).transform(((t - start) / dur).clamp(0.0, 1.0));
  return _kf(u, const [0, .35, 1], [1, s, 1]);
}

class _PoengKreditertState extends State<PoengKreditert> with TickerProviderStateMixin {
  late final KrData d = widget.data;
  late final _Tid tid = _Tid(d.rader.length, d.pg, medKort: d.til != null);
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: tid.total));
  late final AnimationController _ut = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  final GlobalKey _lag = GlobalKey(), _stor = GlobalKey(), _liten = GlobalKey(), _total = GlobalKey(), _saldo = GlobalKey();
  late final _Fx _fx = _Fx(seed: d.pg * 7919 + d.rader.length, tid: tid);
  int _landet = 0;

  bool get _ferdig => _c.value >= 1;
  double get _t => _c.value * tid.total;

  @override
  void initState() {
    super.initState();
    _c.addListener(_tikk);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  /// Haptics on the landings (every third), and once at the end.
  void _tikk() {
    if (!tid.medKort) return;
    var n = 0;
    for (var k = 0; k < tid.nc; k++) {
      if (_t >= tid.lander(k)) n++;
    }
    if (n != _landet && !_ferdig) {
      if (n % 3 == 1) AeHaptikk.tikk();
      if (n == tid.nc) AeHaptikk.tung();
    }
    _landet = n;
  }

  @override
  void dispose() {
    _c.dispose();
    _ut.dispose();
    super.dispose();
  }

  void _hopp() {
    if (!_ferdig) _c.value = 1;
  }

  Future<void> _lukk({bool tilMeg = false}) async {
    if (!_ferdig) return _hopp();
    if (_ut.isAnimating) return;
    final nav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (!MediaQuery.disableAnimationsOf(context)) await _ut.forward();
    if (!mounted) return;
    rootNav.pop();
    widget.onLukk?.call();
    if (tilMeg) {
      BergenVidere.tilMeg(nav, poeng: true);
    } else {
      // The design's `poengKlask`: the Meg tab's coin answers.
      BergenBottomNav.megBump.value++;
    }
  }

  /// A widget's centre in the layer's coordinates.
  Offset? _midt(GlobalKey k) {
    final lag = _lag.currentContext?.findRenderObject() as RenderBox?;
    final b = k.currentContext?.findRenderObject() as RenderBox?;
    if (lag == null || b == null || !b.attached || !lag.attached) return null;
    return b.localToGlobal(b.size.center(Offset.zero), ancestor: lag);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final rolig = MediaQuery.disableAnimationsOf(context);
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _ut,
        builder: (context, child) => Opacity(
          opacity: 1 - _ut.value,
          child: Transform.scale(scale: 1 + .03 * _ut.value, child: child),
        ),
        child: GestureDetector(
          key: const Key('poeng_kreditert'),
          behavior: HitTestBehavior.opaque,
          onTap: _hopp,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(
              key: _lag,
              clipBehavior: Clip.hardEdge,
              children: _lag1(context, s, rolig),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _lag1(BuildContext context, double s, bool rolig) {
    final t = _ferdig ? tid.total.toDouble() : _t;
    final K = tid;
    final mq = MediaQuery.of(context);
    const myk = aeMyk;
    // The big coin's intro (`mynt`) and its pulses.
    final pm = _seg(t, 180, 920, const Cubic(.3, .7, .35, 1));
    final myntOp = _kf(pm, const [0, .58, 1], [0, 1, 1]);
    final myntTy = _kf(pm, const [0, .58, .8, 1], [60, -10, 3, 0]);
    final myntS = _kf(pm, const [0, .58, .8, 1], [.2, 1.14, .96, 1]);
    final myntRy = _kf(pm, const [0, .58, .8, 1], [540, 24, -6, 0]);
    var miS = 1.0;
    for (var i = 0; i < K.nR; i++) {
      miS *= _puls(t, K.tR(i) + 170, 360, 1.1);
    }
    if (K.medKort) miS *= _puls(t, K.tFly - 40, 380, .86);
    final pr = _seg(t, 700, 780, const Cubic(.1, .7, .3, 1));
    final ringOp = _kf(pr, const [0, .08, 1], [0, .95, 0]);
    final ringS = _kf(pr, const [0, .08, 1], [.7, .86, 2.2]);
    // «+N»: counts row by row.
    var total = 0.0, cum = 0;
    var totS = 1.0;
    for (var i = 0; i < K.nR; i++) {
      final a = cum, b = cum += d.rader[i].poeng;
      final u = _seg(t, K.tR(i) + 170, 440, Curves.easeOutCubic);
      if (t >= K.tR(i) + 170) total = a + (b - a) * u;
      totS *= _puls(t, K.tR(i) + 170, 380, 1.16);
    }
    if (_ferdig) total = d.pg.toDouble();
    // The balance: one share per landed coin.
    var landet = 0;
    double sisteLanding = -1e9;
    for (var k = 0; k < K.nc; k++) {
      if (t >= K.lander(k)) {
        landet++;
        sisteLanding = K.lander(k).toDouble();
      }
    }
    final fra = d.fra ?? 0, til = d.til ?? 0;
    final saldo = _ferdig || K.nc == 0 ? til : fra + (d.pg * landet / K.nc).round();
    final blink = (1 - ((t - sisteLanding) / 320).clamp(0.0, 1.0));
    final dytt = 2.5 * (1 - ((t - sisteLanding) / 170).clamp(0.0, 1.0));
    final kmS = _puls(t, sisteLanding, 260, 1.3);
    final saldoS = _puls(t, K.tEnd, 420, 1.1);
    final oppFra = d.oppFra ?? 0, oppTil = d.oppTil ?? 0;
    final pb = _seg(t, K.tEnd + 300, 900, const Cubic(.3, .8, .3, 1));
    final pctFra = d.nyttNivaa ? 0.0 : d.pctAv(oppFra), pctTil = d.pctAv(oppTil);
    final pct = pctFra + (pctTil - pctFra) * pb;
    final nivU = _seg(t, K.tEnd, 900, Curves.easeOutCubic);
    final nivOpp = d.nyttNivaa ? oppTil : (oppFra + (oppTil - oppFra) * nivU).round();

    final coinY = 230 * s;
    final w = mq.size.width;

    Widget opp(double op, double ty, Widget child, {double sc = 1}) => Opacity(
      opacity: op.clamp(0.0, 1.0),
      child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, ty, 0)..scaleByDouble(sc, sc, 1, 1), child: child),
    );

    return [
      // The backdrop.
      Positioned.fill(
        child: Opacity(
          opacity: _seg(t, 0, 340, Curves.easeOut),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.44),
                radius: 1.2,
                colors: [Color.fromRGBO(36, 96, 110, .96), Color.fromRGBO(14, 44, 53, .97), Color.fromRGBO(7, 22, 28, .98)],
                stops: [0, .52, 1],
              ),
            ),
          ),
        ),
      ),
      // The rays (32 s a turn) and the glow.
      Positioned(
        left: w / 2 - 300 * s,
        top: coinY - 300 * s,
        width: 600 * s,
        height: 600 * s,
        child: IgnorePointer(
          child: Opacity(
            opacity: _seg(t, 260, 900, Curves.easeOut),
            child: rolig
                ? CustomPaint(painter: _Straaler())
                : LfLoop(
                    builder: (context, ms, child) => Transform.rotate(angle: ms / 32000 * 2 * math.pi, child: child),
                    child: CustomPaint(painter: _Straaler()),
                  ),
          ),
        ),
      ),
      Positioned(
        left: w / 2 - 150 * s,
        top: coinY - 150 * s,
        width: 300 * s,
        height: 300 * s,
        child: IgnorePointer(
          child: opp(
            _seg(t, 160, 820, myk),
            0,
            sc: .4 + .6 * _seg(t, 160, 820, myk),
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color.fromRGBO(255, 214, 120, .42), Color.fromRGBO(242, 193, 78, .16), Color.fromRGBO(242, 193, 78, 0)], stops: [0, .38, .68]),
              ),
            ),
          ),
        ),
      ),
      // The top: the chip, «Godt seilt!», the line.
      Positioned(
        left: 24 * s,
        right: 24 * s,
        top: 58 * s,
        child: opp(
          _seg(t, 90, 520, myk),
          -14 * (1 - _seg(t, 90, 520, myk)),
          Column(
            children: [
              Container(
                height: 26 * s,
                padding: EdgeInsets.symmetric(horizontal: 11 * s),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(10, 33, 40, .6), border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.flag_outlined, size: 12 * s, color: const Color(0xFF7FF0CB)),
                  SizedBox(width: 6 * s),
                  Text(KrCopy.kicker, style: bText(context, 11, weight: FontWeight.w800, letterSpacingEm: .08, color: const Color(0xFFD4FBEB))),
                ]),
              ),
              SizedBox(height: 8 * s),
              Text(KrCopy.tittel, textAlign: TextAlign.center, style: bDisplay(context, 27, letterSpacingEm: -.025, color: Colors.white).copyWith(height: 1.1)),
              SizedBox(height: 8 * s),
              Text(KrCopy.under, textAlign: TextAlign.center, style: bText(context, 13.5, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .78))),
            ],
          ),
        ),
      ),
      // The big coin.
      Positioned(
        left: w / 2 - 64 * s,
        top: coinY - 64 * s,
        width: 128 * s,
        height: 128 * s,
        child: Opacity(
          opacity: myntOp.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..translateByDouble(0, myntTy * s, 0, 1)
              ..scaleByDouble(myntS * miS, myntS * miS, 1, 1)
              ..rotateY(myntRy * math.pi / 180),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AeMynt(key: _stor, size: 128 * s, flip: false, glow: true),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: ringOp.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: ringS,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFE3A3), width: 3 * s),
                            boxShadow: [BoxShadow(color: const Color.fromRGBO(242, 193, 78, .7), blurRadius: 18 * s)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // «+N ÆREND-POENG».
      Positioned(
        left: 0,
        right: 0,
        top: 310 * s,
        child: opp(
          _seg(t, 760, 460, myk),
          14 * s * (1 - _seg(t, 760, 460, myk)),
          sc: .9 + .1 * _seg(t, 760, 460, myk),
          Column(
            children: [
              Transform.scale(
                scale: totS,
                child: Text(
                  '+${total.round()}',
                  key: _total,
                  style: bDisplay(context, 62, letterSpacingEm: -.045, color: const Color(0xFFFFE3A3)).copyWith(
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: const Color.fromRGBO(242, 193, 78, .55), blurRadius: 26 * s), Shadow(color: const Color.fromRGBO(120, 80, 10, .35), offset: Offset(0, 3 * s))],
                  ),
                ),
              ),
              SizedBox(height: 4 * s),
              Text(KrCopy.enhet, style: bText(context, 12, weight: FontWeight.w800, letterSpacingEm: .1, color: const Color(0xFFE9D7A8))),
            ],
          ),
        ),
      ),
      // The rows.
      Positioned(
        left: 22 * s,
        right: 22 * s,
        top: 416 * s,
        child: Column(
          children: [
            for (var i = 0; i < K.nR; i++) ...[
              if (i > 0) SizedBox(height: 8 * s),
              Builder(builder: (context) {
                final u = _seg(t, K.tR(i), 540, myk);
                return opp(
                  _kf(u, const [0, .7, 1], [0, 1, 1]),
                  _kf(u, const [0, .7, 1], [22, -3, 0]) * s,
                  sc: _kf(u, const [0, .7, 1], [.94, 1.015, 1]),
                  _Rad(rad: d.rader[i], key: Key('kr_rad_$i')),
                );
              }),
            ],
          ],
        ),
      ),
      // The balance card.
      if (K.medKort)
        Positioned(
          left: 16 * s,
          right: 16 * s,
          bottom: 118 * s + mq.padding.bottom * .5,
          child: opp(
            _seg(t, 1180, 580, myk),
            48 * s * (1 - _seg(t, 1180, 580, myk)) + dytt * s,
            _Kort(
              s: s,
              myntKey: _liten,
              saldoKey: _saldo,
              saldo: KasseCopy.tall(saldo),
              saldoFarge: Color.lerp(Colors.white, const Color(0xFFFFE3A3), blink.clamp(0.0, 1.0) * (_ferdig ? 0 : 1))!,
              saldoS: saldoS,
              myntS: kmS,
              pluss: '+${d.pg}',
              plussU: _seg(t, K.tEnd, 520),
              glod: _kf(_seg(t, K.tEnd, 1400, Curves.easeOut), const [0, .25, 1], [0, 1, 0]),
              glans: _seg(t, K.tEnd + 60, 950, const Cubic(.4, 0, .2, 1)),
              nivU: _seg(t, K.tEnd + 140, 420),
              nivNavn: d.nyttNivaa ? KrCopy.nyttNivaa(d.navn) : d.navn,
              nivTil: d.nivTilTx(nivOpp),
              pct: pct,
              tupp: _seg(t, K.tEnd + 900, 700),
              ferdig: _ferdig,
            ),
          ),
        ),
      // Ægil hops in.
      if (K.medKort)
        Positioned(
          left: 26 * s,
          bottom: 212 * s + mq.padding.bottom * .5,
          width: 92 * s,
          height: 92 * s,
          child: IgnorePointer(
            child: Builder(builder: (context) {
              final u = _seg(t, K.tEnd + 120, 640);
              final h = _seg(t, K.tEnd + 900, 520, const Cubic(.3, 1.4, .5, 1));
              final ty = _kf(u, const [0, .62, 1], [74, -9, 0]) + _kf(h, const [0, .4, 1], [0, -14, 0]);
              final rot = _kf(u, const [0, .62, 1], [0, -3, 0]) + _kf(h, const [0, .4, 1], [0, 4, 0]);
              return Opacity(
                opacity: _kf(u, const [0, .62, 1], [0, 1, 1]),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.translationValues(0, ty * s, 0)..rotateZ(rot * math.pi / 180),
                  child: Image.asset('assets/images/dashboard/popup.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              );
            }),
          ),
        ),
      // «Fortsett» and «Se poengene dine».
      Positioned(
        left: 16 * s,
        right: 16 * s,
        bottom: 50 * s + mq.padding.bottom * .5,
        child: opp(
          _seg(t, K.tEnd + 420, 440, myk),
          16 * s * (1 - _seg(t, K.tEnd + 420, 440, myk)),
          AeKnappPille(key: const Key('kr_fortsett'), label: KrCopy.fortsett, onPressed: _ferdig ? () => _lukk() : _hopp),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 6 * s + mq.padding.bottom * .5,
        child: Opacity(
          opacity: _seg(t, K.tEnd + 560, 400),
          child: Center(
            child: Semantics(
              button: true,
              label: KrCopy.sePoengene,
              child: GestureDetector(
                key: const Key('kr_se_poengene'),
                behavior: HitTestBehavior.opaque,
                onTap: _ferdig ? () => _lukk(tilMeg: true) : _hopp,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(KrCopy.sePoengene, style: bDisplay(context, 13.5, letterSpacingEm: -.01, color: const Color.fromRGBO(255, 255, 255, .86))),
                    SizedBox(width: 6 * s),
                    Icon(Icons.chevron_right_rounded, size: 16 * s, color: const Color.fromRGBO(255, 255, 255, .86)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      // The coins, the sparks and the confetti: one pool, one painter.
      if (!_ferdig && !rolig)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FxMaler(
                fx: _fx,
                t: t,
                s: s,
                fra: _midt(_stor),
                til: _midt(_liten),
                total: _midt(_total),
                saldo: _midt(_saldo),
              ),
            ),
          ),
        ),
    ];
  }
}

// ── pieces ──────────────────────────────────────────────────────────────────

class _Rad extends StatelessWidget {
  const _Rad({super.key, required this.rad});
  final KrRad rad;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final c = rad.rekord ? const Color(0xFFF2C14E) : const Color(0xFF7FF0CB);
    return Container(
      constraints: BoxConstraints(minHeight: 48 * s),
      padding: EdgeInsets.fromLTRB(8 * s, 7 * s, 14 * s, 7 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * s),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .11), Color.fromRGBO(255, 255, 255, .05)]),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34 * s,
            height: 34 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11 * s),
              color: c.withValues(alpha: .16),
              border: Border.all(color: c.withValues(alpha: .4)),
            ),
            child: Icon(rad.rekord ? Icons.star_rounded : Icons.flag_outlined, size: 17 * s, color: c),
          ),
          SizedBox(width: 11 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rad.tittel, style: bText(context, 14, weight: FontWeight.w800, color: Colors.white)),
                Text(rad.under, style: bText(context, 12, weight: FontWeight.w600, color: const Color.fromRGBO(255, 255, 255, .7))),
              ],
            ),
          ),
          Text('+${rad.poeng}', style: bDisplay(context, 17, letterSpacingEm: -.01, color: const Color(0xFFFFE3A3))),
        ],
      ),
    );
  }
}

class _Kort extends StatelessWidget {
  const _Kort({
    required this.s,
    required this.myntKey,
    required this.saldoKey,
    required this.saldo,
    required this.saldoFarge,
    required this.saldoS,
    required this.myntS,
    required this.pluss,
    required this.plussU,
    required this.glod,
    required this.glans,
    required this.nivU,
    required this.nivNavn,
    required this.nivTil,
    required this.pct,
    required this.tupp,
    required this.ferdig,
  });

  final double s;
  final GlobalKey myntKey, saldoKey;
  final String saldo;
  final Color saldoFarge;
  final double saldoS, myntS;
  final String pluss;
  final double plussU, glod, glans, nivU;
  final String nivNavn, nivTil;
  final double pct, tupp;
  final bool ferdig;

  @override
  Widget build(BuildContext context) {
    final pS = _kf(const Cubic(.3, 1.3, .5, 1).transform(plussU), const [0, .6, 1], [.3, 1.2, 1]);
    final tS = _kf(tupp, const [0, .5, 1], [.3, 1.9, 1]);
    final metall = nivNavn.split('·').last.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * s),
      child: Container(
        key: const Key('kr_saldo_kort'),
        padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 15 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24 * s),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF235C6A), Color(0xFF173F4A)]),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, .18)),
          boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, .75), offset: Offset(0, 22 * s), blurRadius: 44 * s, spreadRadius: -18 * s)],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bergenInsetTop(radius: 24 * s, height: 1.5 * s, alpha: .16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Transform.scale(scale: myntS, child: AeMynt(key: myntKey, size: 46 * s, flip: false, glow: true)),
                    SizedBox(width: 14 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(KrCopy.saldo, style: bText(context, 11, weight: FontWeight.w800, letterSpacingEm: .1, color: const Color.fromRGBO(255, 255, 255, .62))),
                          Row(
                            children: [
                              Transform.scale(
                                scale: saldoS,
                                alignment: const Alignment(-1, .2),
                                child: Text(saldo, key: saldoKey, style: bDisplay(context, 34, letterSpacingEm: -.03, color: saldoFarge).copyWith(height: 1.08, fontFeatures: const [FontFeature.tabularFigures()])),
                              ),
                              SizedBox(width: 10 * s),
                              Opacity(
                                opacity: ferdig ? 1 : _kf(plussU, const [0, .6, 1], [0, 1, 1]),
                                child: Transform.scale(
                                  scale: ferdig ? 1 : pS,
                                  child: Container(
                                    height: 26 * s,
                                    padding: EdgeInsets.symmetric(horizontal: 10 * s),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8FF5D3), Color(0xFF5CE0B8)]),
                                      boxShadow: [BoxShadow(color: const Color.fromRGBO(92, 224, 184, .5), blurRadius: 14 * s)],
                                    ),
                                    child: Text(pluss, style: bText(context, 13.5, weight: FontWeight.w800, color: const Color(0xFF0F3540))),
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
                Opacity(
                  opacity: ferdig ? 1 : nivU,
                  child: Transform.translate(
                    offset: Offset(0, 6 * s * (ferdig ? 0 : 1 - nivU)),
                    child: Padding(
                      padding: EdgeInsets.only(top: 12 * s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              AeMedalje(name: metall, size: 12 * s, mark: false, ring: 0),
                              SizedBox(width: 6 * s),
                              Expanded(child: Text(nivNavn, key: const Key('kr_nivaa'), style: bText(context, 12, weight: FontWeight.w700, color: Colors.white))),
                              Text(nivTil, key: const Key('kr_niv_til'), style: bText(context, 12, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .78)).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                            ],
                          ),
                          SizedBox(height: 10 * s),
                          SizedBox(
                            height: 8 * s,
                            child: LayoutBuilder(builder: (context, box) {
                              final p = pct.clamp(0.0, 1.0);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(4 * s), color: const Color.fromRGBO(255, 255, 255, .12)))),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: box.maxWidth * p,
                                    child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(4 * s), gradient: const LinearGradient(colors: [Color(0xFFE0A92C), Color(0xFFFFE3A3)]))),
                                  ),
                                  Positioned(
                                    left: box.maxWidth * p - 7 * s,
                                    top: 4 * s - 7 * s,
                                    width: 14 * s,
                                    height: 14 * s,
                                    child: Opacity(
                                      opacity: ferdig ? 1 : _kf(tupp, const [0, .5, 1], [0, 1, 1]),
                                      child: Transform.scale(
                                        scale: ferdig ? 1 : tS,
                                        child: const DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFE3A3), Color.fromRGBO(242, 193, 78, 0)], stops: [0, .4, .72]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // The landing glow and the sheen.
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: glod.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24 * s),
                      border: Border.all(color: const Color.fromRGBO(255, 227, 163, .9), width: 1.5 * s),
                      boxShadow: [BoxShadow(color: const Color.fromRGBO(242, 193, 78, .45), blurRadius: 28 * s, blurStyle: BlurStyle.inner)],
                    ),
                  ),
                ),
              ),
            ),
            if (glans > 0 && glans < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(builder: (context, box) {
                    final bw = box.maxWidth * .38;
                    final x = -1.2 * bw + (box.maxWidth + 2.4 * bw) * glans;
                    return Stack(children: [
                      Positioned(
                        left: x,
                        top: -10,
                        bottom: -10,
                        width: bw,
                        child: Transform(
                          transform: Matrix4.skewX(-.28),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, 0)])),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `repeating-conic-gradient(rgba(242,193,78,.16) 0 6deg, transparent 6deg 18deg)` under a radial mask (12 % → 58 %).
class _Straaler extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final r = size.width / 2;
    final ctr = size.center(Offset.zero);
    c.saveLayer(Offset.zero & size, Paint());
    final p = Paint()..color = const Color.fromRGBO(242, 193, 78, .16);
    for (var a = 0.0; a < 360; a += 18) {
      final a0 = (a - 90) * math.pi / 180, a1 = (a + 6 - 90) * math.pi / 180;
      c.drawPath(
        Path()
          ..moveTo(ctr.dx, ctr.dy)
          ..lineTo(ctr.dx + math.cos(a0) * r, ctr.dy + math.sin(a0) * r)
          ..lineTo(ctr.dx + math.cos(a1) * r, ctr.dy + math.sin(a1) * r)
          ..close(),
        p,
      );
    }
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = RadialGradient(colors: const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)], stops: const [0, .12, .58]).createShader(Offset.zero & size),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_Straaler old) => false;
}

// ── the effects pool ────────────────────────────────────────────────────────

class _Mynt {
  _Mynt(math.Random r, int k, int nc)
    : a = -math.pi / 2 + (k / nc) * math.pi * 2 + (r.nextDouble() - .5) * .5,
      r0 = 52 + r.nextDouble() * 30,
      sideJ = 70 + r.nextDouble() * 50,
      upJ = 30 + r.nextDouble() * 40,
      rot = (r.nextDouble() - .5) * 720;
  final double a, r0, sideJ, upJ, rot;
}

class _Gnist {
  _Gnist(math.Random r, this.start, this.hvor, int i)
    : a = r.nextDouble() * 2 * math.pi,
      d = 22 + r.nextDouble() * 18,
      dur = 380 + r.nextDouble() * 160,
      farge = i.isOdd ? const Color(0xFFFFE3A3) : const Color(0xFFFFFFFF);
  final double start;

  /// 0 = the total, 1 = the card's coin.
  final int hvor;
  final double a, d, dur;
  final Color farge;
}

class _Konfetti {
  _Konfetti(math.Random r, int i)
    : w = 5 + r.nextDouble() * 5,
      hF = .45 + r.nextDouble() * .5,
      farge = const [Color(0xFFF2C14E), Color(0xFFFFE3A3), Color(0xFF5CE0B8), Color(0xFFFFFFFF), Color(0xFFF26D3D)][i % 5],
      a = -math.pi / 2 + (r.nextDouble() - .5) * 2.2,
      v = 260 + r.nextDouble() * 260,
      dur = 1.1 + r.nextDouble() * .5,
      rot = (r.nextDouble() - .5) * 1080;
  final double w, hF, a, v, dur, rot;
  final Color farge;
}

class _Fx {
  _Fx({required int seed, required this.tid}) {
    final r = math.Random(seed);
    mynter = [for (var k = 0; k < tid.nc; k++) _Mynt(r, k, tid.nc)];
    gnister = [
      for (var i = 0; i < tid.nR; i++)
        for (var j = 0; j < 6; j++) _Gnist(r, tid.tR(i) + 170.0, 0, j),
      for (var k = 0; k < tid.nc; k++)
        for (var j = 0; j < 4; j++) _Gnist(r, tid.lander(k).toDouble(), 1, j),
    ];
    konfetti = tid.medKort ? [for (var i = 0; i < 34; i++) _Konfetti(r, i)] : const [];
  }

  final _Tid tid;
  late final List<_Mynt> mynter;
  late final List<_Gnist> gnister;
  late final List<_Konfetti> konfetti;
}

class _FxMaler extends CustomPainter {
  _FxMaler({required this.fx, required this.t, required this.s, this.fra, this.til, this.total, this.saldo});

  final _Fx fx;
  final double t, s;
  final Offset? fra, til, total, saldo;

  @override
  void paint(Canvas c, Size size) {
    final K = fx.tid;
    // The coins.
    if (fra != null && til != null) {
      final x0 = fra!.dx, y0 = fra!.dy, x1 = til!.dx, y1 = til!.dy;
      const myntD = 30.0;
      for (var k = 0; k < fx.mynter.length; k++) {
        final start = K.tFly + k * _Tid.st;
        if (t < start || t > start + _Tid.fl) continue;
        final m = fx.mynter[k];
        final u = (t - start) / _Tid.fl;
        final bx = x0 + math.cos(m.a) * m.r0 * 1.15 * s, by = y0 + math.sin(m.a) * m.r0 * s;
        final side = math.cos(m.a) >= 0 ? 1 : -1;
        final cx = (bx + x1) / 2 + side * m.sideJ * s, cy = (by + y1) / 2 - m.upJ * s;
        double x, y, sc, rot, op;
        if (u < .24) {
          final e = const Cubic(.15, .85, .35, 1).transform(u / .24);
          x = x0 + (bx - x0) * e;
          y = y0 + (by - y0) * e;
          sc = .3 + .85 * e;
          rot = m.rot * .25 * e;
          op = e;
        } else {
          final sv = (u - .24) / .76;
          final uu = math.pow(sv, 1.55).toDouble(), mm = 1 - uu;
          x = mm * mm * bx + 2 * mm * uu * cx + uu * uu * x1;
          y = mm * mm * by + 2 * mm * uu * cy + uu * uu * y1;
          sc = 1.15 - .6 * sv;
          rot = m.rot * (.25 + .75 * sv);
          op = 1;
        }
        final d = myntD * s * sc;
        c.save();
        c.translate(x, y);
        c.rotate(rot * math.pi / 180);
        c.translate(-d / 2, -d / 2);
        if (op < 1) c.saveLayer(Rect.fromLTWH(-4, -4, d + 8, d + 16), Paint()..color = Color.fromRGBO(0, 0, 0, op));
        AeMynt.male(c, d);
        if (op < 1) c.restore();
        c.restore();
      }
    }
    // The sparks.
    for (final g in fx.gnister) {
      final o = g.hvor == 0 ? total : til;
      if (o == null || t < g.start || t > g.start + g.dur) continue;
      final u = const Cubic(.2, .8, .3, 1).transform((t - g.start) / g.dur);
      final p = o + Offset(math.cos(g.a), math.sin(g.a)) * g.d * s * u;
      final sz = 6 * s * (1 - .8 * u);
      final paint = Paint()..color = g.farge.withValues(alpha: 1 - u);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(math.pi / 4);
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: sz, height: sz), Paint()..color = g.farge.withValues(alpha: (1 - u) * .6)..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s));
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: sz, height: sz), paint);
      c.restore();
    }
    // The confetti.
    if (saldo != null && t >= K.tEnd) {
      for (final k in fx.konfetti) {
        final tt = (t - K.tEnd) / 1000;
        if (tt > k.dur) continue;
        final j = tt / k.dur;
        final x = saldo!.dx + math.cos(k.a) * k.v * tt * .9 * s;
        final y = saldo!.dy + (math.sin(k.a) * k.v * tt + 450 * tt * tt) * s;
        final op = j < 4 / 6 ? 1.0 : 1 - (j - 4 / 6) * 3;
        final w = k.w * s, h = k.w * k.hF * s * math.cos(j * 6 * 160 * math.pi / 180).abs().clamp(.15, 1);
        c.save();
        c.translate(x, y);
        c.rotate(k.rot * j * math.pi / 180);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(1.5 * s)), Paint()..color = k.farge.withValues(alpha: op.clamp(0.0, 1.0)));
        c.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_FxMaler old) => old.t != t || old.fra != fra || old.til != til;
}
