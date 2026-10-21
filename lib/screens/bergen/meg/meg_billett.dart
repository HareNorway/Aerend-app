import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/aegil/aegil_app_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../aegil/aegil_bits.dart';
import '../kit/bergen_perf.dart';
import 'meg_bergen.dart';
import 'package:aerend_customer/utils/route_names.dart';

// ── Gullbilletten (Bergen Step 8, new Bergen L9844–9859, L9963–10017) ──────

abstract final class GbCopy {
  static const String billetteneDine = 'BILLETTENE DINE';
  static const String ingenGrense = 'Ingen grense';
  static String avCap(int n, int cap) => '$n av $cap denne måneden';
  static const String vennerVervet = 'venner vervet';
  static const String vennVervet = 'venn vervet';
  static String hentetInn(int poeng, int per) => '${_nf(poeng)} poeng hentet inn · $per for hver ny';
  static const String nesteVenn = 'Neste venn';
  static String pluss(int n) => '+$n poeng';
  static const String lastetNed = 'Lastet ned';

  // The celebration.
  static const String gullbillett = 'GULLBILLETT';
  static String tilBegge(int n) => '$n poeng til dere begge';
  static const String poeng = 'POENG';
  static const String delt = 'DELT';
  static const String lenken = 'LENKEN ER SENDT';
  static const String duHarDelt = 'Du har delt ';
  static const String gullbilletten = 'gullbilletten';
  static const String din = ' din!';
  static String naarVennen(int n) => 'Når vennen din får første bestilling levert, får dere $n poeng hver.';
  static const String du = 'Du';
  static const String vennen = 'Vennen';
  static const String delMedFlere = 'Del med flere';
  static const String ferdig = 'Ferdig';

  static String _nf(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
}

/// «BILLETTENE DINE» (L9844–9858): the cap chip (D5: «Ingen grense» only when
/// there is no monthly cap, else «N av 5 denne måneden»), the count of
/// friends who qualified and the points they brought in, then a row of
/// tickets: «Neste venn» (shares) and one per friend, newest first —
/// delivered ones in gold with «+200 poeng», the others «Lastet ned».
class GbBillettene extends StatelessWidget {
  const GbBillettene({super.key, required this.referral, required this.onNeste});

  final Referral referral;
  final VoidCallback onNeste;

  @override
  Widget build(BuildContext context) {
    final r = referral;
    final ant = r.qualifiedTotal;
    final venner = r.friends.reversed.toList();
    return LfRise(
      delay: 80,
      dur: 400,
      child: CssBox(
        key: const Key('meg-billett-board'),
        radius: BorderRadius.circular(22),
        clip: true,
        bg: const [
          CssRadial([Color.fromRGBO(242, 193, 78, .22), Color.fromRGBO(242, 193, 78, 0)], rx: .5, ry: .5, cx: .95, cy: -.05),
          CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
        ],
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, .16)),
        shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .22)), CssShadow(0, 12, 20, -14, Color.fromRGBO(0, 10, 16, .85))],
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5CE0B8),
                          boxShadow: [BoxShadow(color: Color(0xFF5CE0B8), blurRadius: 8 / 2 / .57735)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          GbCopy.billetteneDine,
                          style: inter(11, weight: FontWeight.w800, em: .12, color: const Color(0xFF7FF0CB)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color.fromRGBO(242, 193, 78, .14),
                          border: Border.all(color: const Color.fromRGBO(242, 193, 78, .42)),
                        ),
                        child: Text(
                          r.monthlyCap <= 0 ? GbCopy.ingenGrense : GbCopy.avCap(r.qualifiedThisMonth, r.monthlyCap),
                          key: const Key('meg-billett-cap'),
                          style: aeTab(inter(10.5, weight: FontWeight.w800, color: const Color(0xFFF6D27A))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$ant', key: const Key('meg-billett-antall'), style: aeTab(jakarta(44, em: -.04, height: .9))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ant == 1 ? GbCopy.vennVervet : GbCopy.vennerVervet, style: inter(13.5, weight: FontWeight.w800, height: 1.2)),
                              const SizedBox(height: 2),
                              Text(GbCopy.hentetInn(r.pointsEarned, r.pointsForMe), style: aeTab(inter(11, color: const Color.fromRGBO(255, 255, 255, .68)))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // `margin: 0 -14px; padding: 2px 14px 6px; overflow-x: auto`.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(15, 2, 15, 6),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LfRise(
                      delay: 100,
                      dur: 350,
                      child: _Neste(pluss: r.pointsForMe, onTap: onNeste),
                    ),
                    for (var i = 0; i < venner.length; i++) ...[
                      const SizedBox(width: 8),
                      LfRise(
                        delay: 120 + i * 50.0,
                        dur: 350,
                        child: _Venn(v: venner[i], pluss: r.pointsForMe),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // The design's momentum line («Du verver flest på Møhlenpris …»)
            // is left out: there is no such ranking in the points API.
          ],
        ),
      ),
    );
  }
}

/// «Neste venn»: the dashed gold ticket with the pulsing + (`pulsDot 2.4s`).
class _Neste extends StatelessWidget {
  const _Neste({required this.pluss, required this.onTap});
  final int pluss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AePress(
    key: const Key('meg-billett-neste'),
    onTap: onTap,
    dy: 2,
    child: CustomPaint(
      foregroundPainter: const _Stiplet(Color.fromRGBO(242, 193, 78, .55)),
      child: Container(
        width: 96,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color.fromRGBO(242, 109, 61, .08)),
        child: Column(
          children: [
            LfLoop(
              builder: (context, t, child) {
                final p = kfLoop(t, 0, 2400) ?? 0;
                final s = kf(p, const [0, .5, 1], const [1, 1.35, 1], cssEaseInOut);
                return Transform.scale(
                  scale: s,
                  child: Opacity(opacity: kf(p, const [0, .5, 1], const [1, .7, 1], cssEaseInOut), child: child),
                );
              },
              child: CssBox(
                width: 28,
                height: 28,
                radius: BorderRadius.circular(14),
                bg: const [
                  CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFE2531F)], [0, .56, 1]),
                ],
                shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 2, 0, 0, Color(0xFFA63A12)), CssShadow(0, 6, 12, -4, Color.fromRGBO(233, 92, 44, .7))],
                child: const Center(child: AeIkon('M12 5v14M5 12h14', size: 13, stroke: 3)),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              GbCopy.nesteVenn,
              textAlign: TextAlign.center,
              style: inter(12.5, weight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.fromLTRB(7, 2.5, 7, 2.5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color.fromRGBO(242, 193, 78, .16)),
              child: Text(
                GbCopy.pluss(pluss),
                style: aeTab(inter(9.5, weight: FontWeight.w800, color: const Color(0xFFF6D27A))),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `border: 1.5px dashed` on a 14 px rounded box.
class _Stiplet extends CustomPainter {
  const _Stiplet(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius((Offset.zero & size).deflate(.75), const Radius.circular(14));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Stiplet o) => o.color != color;
}

/// A friend's ticket: 96 wide, notches at 47 px on both sides, a dashed tear
/// line, the coin with ✓ (delivered, gold) or ↓ (downloaded), the name and
/// the status chip; delivered ones catch a sweep.
class _Venn extends StatelessWidget {
  const _Venn({required this.v, required this.pluss});
  final VervFriend v;
  final int pluss;

  @override
  Widget build(BuildContext context) {
    final lev = v.delivered;
    return ClipPath(
      clipper: const _VennKant(),
      child: CssBox(
        width: 96,
        bg: [
          if (lev)
            const CssLinear(160, [Color(0xFFFFF0C2), Color(0xFFF2CD6B), Color(0xFFD9A33A)], [0, .5, 1])
          else
            const CssLinear(180, [Color.fromRGBO(242, 193, 78, .22), Color.fromRGBO(242, 193, 78, .08)]),
        ],
        shadows: lev
            ? const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .75)), CssShadow.inset(0, -2, 4, 0, Color.fromRGBO(120, 70, 0, .25))]
            : const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(242, 193, 78, .45))],
        radius: BorderRadius.circular(14),
        child: Stack(
          children: [
            if (lev) const Positioned.fill(child: MegSveip3(ms: 5000, delay: 1400, frac: .6, alpha: .6, deg: 100, skew: false)),
            Positioned(
              left: 9,
              right: 9,
              top: 47,
              child: CustomPaint(size: const Size(double.infinity, 1.5), painter: _Linje(lev ? const Color.fromRGBO(90, 60, 10, .32) : const Color.fromRGBO(255, 255, 255, .2))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 11, 8, 10),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lev ? null : const Color.fromRGBO(242, 193, 78, .22),
                      gradient: lev ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A3410), Color(0xFF2E1F06)]) : null,
                    ),
                    child: AeIkon(lev ? 'M4.5 12.5l5 5 10-11' : 'M12 4v10M8 10.5l4 4 4-4M5 19h14', size: 13, stroke: lev ? 3.2 : 2.6, color: const Color(0xFFF6D27A)),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: inter(12.5, weight: FontWeight.w800, color: lev ? const Color(0xFF3A2708) : Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.fromLTRB(7, 2.5, 7, 2.5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: lev ? const Color.fromRGBO(90, 60, 10, .18) : const Color.fromRGBO(242, 193, 78, .18)),
                    child: Text(
                      lev ? GbCopy.pluss(pluss) : GbCopy.lastetNed,
                      maxLines: 1,
                      style: aeTab(inter(9.5, weight: FontWeight.w800, color: lev ? const Color(0xFF4A3208) : const Color(0xFFF6D27A))),
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
}

class _VennKant extends CustomClipper<Path> {
  const _VennKant();

  @override
  Path getClip(Size s) {
    final kropp = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(14)));
    final hull = Path()
      ..addOval(Rect.fromCircle(center: const Offset(0, 47), radius: 5))
      ..addOval(Rect.fromCircle(center: Offset(s.width, 47), radius: 5));
    return Path.combine(PathOperation.difference, kropp, hull);
  }

  @override
  bool shouldReclip(_VennKant o) => false;
}

class _Linje extends CustomPainter {
  const _Linje(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_Linje o) => o.color != color;
}

// ── «Gullbillett delt» ─────────────────────────────────────────────────────

/// Shows the celebration over everything (after a share went out).
Future<void> visGullbillettDelt(BuildContext context, {required String kode, required String initial, required int poeng, required VoidCallback onIgjen}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      settings: const RouteSettings(name: '${appRoutePrefix}gb-delt'),
      pageBuilder: (ctx, a, _) => FadeTransition(
        opacity: ReverseAnimation(ReverseAnimation(a)),
        child: GbDelt(
          kode: kode,
          initial: initial,
          poeng: poeng,
          onFerdig: () => Navigator.of(ctx).pop(),
          onIgjen: () {
            Navigator.of(ctx).pop();
            onIgjen();
          },
        ),
      ),
    ),
  );
}

/// The celebration (L9963–10017, `gb*` keyframes): the ticket falls in (3D),
/// the stub tears off and flies away leaving sparks, «DELT» is stamped, two
/// rings, confetti, Ægil with the invitation pops up, then «LENKEN ER SENDT ·
/// Du har delt gullbilletten din!», the line, «Du +200 · Vennen +200» and
/// «Del med flere» / «Ferdig». In `still` it shows the end frame.
class GbDelt extends StatefulWidget {
  const GbDelt({super.key, required this.kode, required this.initial, required this.poeng, required this.onFerdig, required this.onIgjen});

  final String kode;
  final String initial;
  final int poeng;
  final VoidCallback onFerdig;
  final VoidCallback onIgjen;

  @override
  State<GbDelt> createState() => _GbDeltState();
}

class _GbDeltState extends State<GbDelt> with SingleTickerProviderStateMixin {
  static const double _total = 4400;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context) || BergenPerf.of(context) == BergenTier.still;
    if (still) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _p(double t, double delay, double dur) => ((t - delay) / dur).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final konf = BergenPerf.count(context, 34);
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * _total;
          return Opacity(
            opacity: cssEaseOut.transform(_p(t, 0, 350)),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(22, 62, 74, .97), Color.fromRGBO(10, 30, 38, .99)]),
              ),
              child: CustomPaint(
                painter: const _Bakgrunn(),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 250, width: double.infinity, child: _scene(t, w - 40, konf)),
                        const SizedBox(height: 10),
                        _opp(t, 2450, 500, _tekst()),
                        const SizedBox(height: 8),
                        _opp(
                          t,
                          2600,
                          500,
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              GbCopy.naarVennen(widget.poeng),
                              textAlign: TextAlign.center,
                              style: inter(13.5, height: 1.45, color: const Color.fromRGBO(255, 255, 255, .78)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(mainAxisSize: MainAxisSize.min, children: [_popp(t, 2800, _chip(_initial(), GbCopy.du)), const SizedBox(width: 8), _popp(t, 2920, _chip(_venn(), GbCopy.vennen))]),
                        const SizedBox(height: 26),
                        _opp(t, 3050, 500, _knapper()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _opp(double t, double delay, double dur, Widget child) {
    final p = const Cubic(.2, .8, .3, 1).transform(_p(t, delay, dur));
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, 16 * (1 - p)), child: child),
    );
  }

  Widget _popp(double t, double delay, Widget child, {double dur = 500}) {
    final p = _p(t, delay, dur);
    const c = Cubic(.3, 1.4, .5, 1);
    final s = kf(p, const [0, .65, 1], const [.4, 1.1, 1], c);
    final o = kf(p, const [0, .65, 1], const [0, 1, 1], c);
    return Opacity(
      opacity: o.clamp(0.0, 1.0),
      child: Transform.scale(scale: s, child: child),
    );
  }

  Widget _scene(double t, double bredde, int konf) {
    // gbFall 1s .15s: from above, tilted back, into place with a bounce.
    final f = _p(t, 150, 1000);
    const fc = Cubic(.2, .8, .25, 1);
    final fy = kf(f, const [0, .55, .76, 1], const [-300, 16, -7, 0], fc);
    final rx = kf(f, const [0, .55, .76, 1], const [75, -10, 5, 0], fc);
    final rz = kf(f, const [0, .55, .76, 1], const [-16, 3, -1.5, 0], fc);
    final sk = kf(f, const [0, .55, .76, 1], const [.55, 1.05, .985, 1], fc);
    final fo = kf(f, const [0, .55, 1], const [0, 1, 1], fc);
    // gbDunk .45s 2.3s
    final d = _p(t, 2300, 450);
    final dy = d == 0 || d == 1 ? 0.0 : kf(d, const [0, .3, .65, 1], const [0, 5, -2, 0], cssEaseOut);
    final ds = d == 0 || d == 1 ? 1.0 : kf(d, const [0, .3, .65, 1], const [1, .97, 1.01, 1], cssEaseOut);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // The rays (`gbStraaler 26s` + `gbInn 1.2s .4s`), the glow (`gbPuls 2.4s .9s`).
        Opacity(
          opacity: cssEaseOut.transform(_p(t, 400, 1200)),
          child: OverflowBox(
            maxWidth: 640,
            maxHeight: 640,
            child: LfLoop(
              builder: (context, lt, _) => Transform.rotate(
                angle: (lt / 26000) * 2 * math.pi,
                child: const CustomPaint(size: Size(640, 640), painter: _Straaler()),
              ),
            ),
          ),
        ),
        OverflowBox(
          maxWidth: 300,
          maxHeight: 300,
          child: Opacity(
            opacity: _p(t, 900, 1),
            child: LfLoop(
              builder: (context, lt, child) {
                final p = kfLoop(lt, 900, 2400) ?? 0;
                return Transform.scale(
                  scale: kf(p, const [0, .5, 1], const [.9, 1.1, .9], cssEaseInOut),
                  child: Opacity(opacity: kf(p, const [0, .5, 1], const [.6, 1, .6], cssEaseInOut), child: child),
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color.fromRGBO(246, 210, 122, .5), Color.fromRGBO(246, 210, 122, 0)]),
                ),
                child: SizedBox(width: 300, height: 300),
              ),
            ),
          ),
        ),
        _ring(t, 850, 900, const Color.fromRGBO(246, 210, 122, .85)),
        _ring(t, 2300, 1000, const Color.fromRGBO(92, 224, 184, .9)),
        for (final g in _gnister)
          Positioned(
            left: bredde * g.$1 / 100,
            top: 250 * g.$2 / 100,
            child: LfLoop(
              builder: (context, lt, child) {
                final p = kfLoop(lt, g.$4 * 1000, 1800);
                if (p == null) return const SizedBox.shrink();
                final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
                return Opacity(
                  opacity: k,
                  child: Transform.rotate(
                    angle: k * math.pi / 4,
                    child: Transform.scale(scale: .3 + .7 * k, child: child),
                  ),
                );
              },
              child: AeIkon('M12 0c.8 6.4 4.8 10.6 12 12-7.2 1.4-11.2 5.6-12 12-.8-6.4-4.8-10.6-12-12 7.2-1.4 11.2-5.6 12-12z', size: g.$3, stroke: 0, fill: const Color(0xFFFBE3A0)),
            ),
          ),
        // The ticket.
        Opacity(
          opacity: fo.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 1 / 900)
              ..translateByDouble(0, fy, 0, 1)
              ..rotateX(rx * math.pi / 180)
              ..rotateZ(rz * math.pi / 180)
              ..scaleByDouble(sk, sk, 1, 1),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: ds,
                child: SizedBox(width: 272, height: 122, child: _billett(t)),
              ),
            ),
          ),
        ),
        // Confetti from the centre.
        for (var i = 0; i < konf; i++) _konfetti(t, i),
        // Ægil with the invitation (`gbPopp .55s 2.6s`, then `aegHopp 1.8s 3.3s`).
        Positioned(
          left: 0,
          bottom: -8,
          width: 88,
          child: _popp(
            t,
            2600,
            dur: 550,
            LfLoop(
              builder: (context, lt, child) {
                final p = kfLoop(lt, 3300, 1800) ?? 0;
                final y = kf(p, const [0, .3, .55, .7, 1], const [0, -10, 0, -4, 0], cssEaseInOut);
                final r = kf(p, const [0, .3, .55, 1], const [0, -3, 0, 0], cssEaseInOut);
                return Transform.translate(
                  offset: Offset(0, y),
                  child: Transform.rotate(angle: r * math.pi / 180, child: child),
                );
              },
              child: Image.asset(aePose('invitation'), width: 88, fit: BoxFit.fitWidth),
            ),
          ),
        ),
      ],
    );
  }

  static const List<(double, double, double, double)> _gnister = [
    (12, 18, 16, .9),
    (86, 14, 12, 1.1),
    (6, 66, 10, 1.3),
    (92, 60, 15, 1),
    (30, 4, 9, 1.5),
    (70, 88, 11, 1.2),
    (52, 0, 13, 1.7),
    (24, 90, 12, 1.4),
    (97, 36, 9, 1.6),
  ];

  Widget _ring(double t, double delay, double dur, Color c) {
    final p = const Cubic(.2, .7, .3, 1).transform(_p(t, delay, dur));
    if (t < delay) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: (.95 * (1 - p)).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .35 + 2.35 * p,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c, width: 3),
            ),
          ),
        ),
      ),
    );
  }

  /// `gbKonf`: 34 pieces (dots, strips, slivers) in six colours, each on a
  /// turned and scaled arm, flying 190 px out and spinning 520°.
  Widget _konfetti(double t, int i) {
    double r(int n) {
      final x = math.sin(i * 12.9898 + n * 78.233) * 43758.5453;
      return x - x.floorToDouble();
    }

    const farger = [Color(0xFFF6D27A), Color(0xFF5CE0B8), Color(0xFFF26D3D), Color(0xFFFFFFFF), Color(0xFFE3AE3C), Color(0xFF9FF0D4)];
    final f = i % 3;
    final rot = (i * (360 / 34) + r(1) * 9).roundToDouble();
    final skala = .55 + r(2) * .8;
    final dur = (1.2 + r(3) * .7) * 1000;
    final delay = (2.26 + r(4) * .12) * 1000;
    final p = const Cubic(.12, .75, .3, 1).transform(_p(t, delay, dur));
    if (t < delay || p >= 1) return const SizedBox.shrink();
    final rp = _p(t, delay, dur);
    final o = kf(rp, const [0, .06, .7, 1], const [0, 1, 1, 0]);
    return IgnorePointer(
      child: Transform.rotate(
        angle: rot * math.pi / 180,
        child: Transform.scale(
          scale: skala,
          child: Transform.translate(
            offset: Offset(0, -190 * p),
            child: Transform.rotate(
              angle: 520 * p * math.pi / 180,
              child: Transform.scale(
                scale: .5 + .5 * p,
                child: Opacity(
                  opacity: o,
                  child: Container(
                    width: f == 2 ? 4 : 7,
                    height: f == 0 ? 7 : 12,
                    decoration: BoxDecoration(color: farger[i % farger.length], borderRadius: BorderRadius.circular(f == 0 ? 4 : 2)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _billett(double t) {
    // gbRiv 1.05s 1.45s: the stub tips, then flies up and away.
    final rv = _p(t, 1450, 1050);
    const rc = Cubic(.55, 0, .75, .35);
    final rx = kf(rv, const [0, .14, .26, 1], const [0, 5, 3, 190], rc);
    final ry = kf(rv, const [0, .14, .26, 1], const [0, 4, 2, -360], rc);
    final rr = kf(rv, const [0, .14, .26, 1], const [0, 7, 4, 40], rc);
    final rs = kf(rv, const [0, .26, 1], const [1, 1, .3], rc);
    final ro = kf(rv, const [0, .26, 1], const [1, 1, 0], rc);
    // gbStempel .45s 2.22s
    final st = _p(t, 2220, 450);
    const sc = Cubic(.3, 1.4, .5, 1);
    final ss = kf(st, const [0, .6, 1], const [2.8, .9, 1], sc);
    final sr = kf(st, const [0, .6, 1], const [-2, -15, -12], sc);
    final so = kf(st, const [0, .6, 1], const [0, 1, 1], sc);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 272 * .08,
          right: 272 * .08,
          bottom: -20,
          height: 40,
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(colors: [Color.fromRGBO(0, 8, 12, .55), Color.fromRGBO(0, 8, 12, 0)])),
          ),
        ),
        // The main part (196 px, notched on its right edge).
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 196,
          child: ClipPath(
            clipper: const _Hakk(hoyre: true),
            child: CssBox(
              bg: const [
                CssLinear(140, [Color(0xFFFFF4CF), Color(0xFFF6D27A), Color(0xFFE6B347), Color(0xFFC98E22)], [0, .38, .7, 1]),
              ],
              shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .85)), CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(120, 70, 0, .25))],
              child: Stack(
                children: [
                  Positioned(
                    left: 7,
                    top: 7,
                    right: 0,
                    bottom: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                        border: const Border(
                          left: BorderSide(color: Color.fromRGBO(120, 80, 10, .28)),
                          top: BorderSide(color: Color.fromRGBO(120, 80, 10, .28)),
                          bottom: BorderSide(color: Color.fromRGBO(120, 80, 10, .28)),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: MegSveip3(ms: 5000, delay: 1100, frac: .45, alpha: .75, deg: 100, skew: false)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AeIkon('M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4l-5.9 3.1 1.2-6.5L2.5 9.4l6.6-.9z', size: 11, stroke: 0, fill: Color(0xFF7A5414)),
                            const SizedBox(width: 6),
                            Text(
                              GbCopy.gullbillett,
                              style: inter(10, weight: FontWeight.w800, em: .18, color: const Color(0xFF7A5414)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.kode,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: jakarta(23, em: -.01, color: const Color(0xFF3A2708)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          GbCopy.tilBegge(widget.poeng),
                          style: inter(10.5, weight: FontWeight.w700, color: const Color(0xFF6B4A12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The stub (+200 POENG) that tears off.
        Positioned(
          left: 196,
          top: 0,
          bottom: 0,
          width: 76,
          child: Opacity(
            opacity: ro.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.bottomLeft,
              transform: Matrix4.translationValues(rx, ry, 0)
                ..rotateZ(rr * math.pi / 180)
                ..scaleByDouble(rs, rs, 1, 1),
              child: ClipPath(
                clipper: const _Hakk(hoyre: false),
                child: CssBox(
                  bg: const [
                    CssLinear(150, [Color(0xFFF8DC8E), Color(0xFFE6B347), Color(0xFFC98E22)], [0, .55, 1]),
                  ],
                  shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .8)), CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(120, 70, 0, .25))],
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 0,
                        top: 14,
                        bottom: 14,
                        child: CustomPaint(size: Size(2, 94), painter: _Loddrett(Color.fromRGBO(90, 60, 10, .4))),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+${widget.poeng}', style: jakarta(20, em: -.02, color: const Color(0xFF3A2708))),
                            const SizedBox(height: 2),
                            Text(
                              GbCopy.poeng,
                              style: inter(9, weight: FontWeight.w800, em: .16, color: const Color(0xFF6B4A12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sparks left by the stub (`gbSpor`).
        for (final s in const [(228.0, 56.0, 8.0, 1550.0, Color(0xFFFBE3A0)), (232.0, 62.0, 6.0, 1640.0, Color(0xFFFBE3A0)), (224.0, 66.0, 5.0, 1720.0, Color(0xFFFFFFFF))])
          () {
            final p = _p(t, s.$4, 1000);
            if (p == 0 || p == 1) return const SizedBox.shrink();
            final e = rc.transform(p);
            return Positioned(
              left: s.$1 + 170 * e,
              top: s.$2 - 330 * e,
              child: Opacity(
                opacity: kf(p, const [0, .2, 1], const [0, 1, 0]),
                child: Transform.scale(
                  scale: 1 - .8 * e,
                  child: Container(
                    width: s.$3,
                    height: s.$3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.$5,
                      boxShadow: const [BoxShadow(color: Color(0xFFF2C14E), blurRadius: 5)],
                    ),
                  ),
                ),
              ),
            );
          }(),
        // «DELT» stamp.
        Positioned(
          left: 146,
          top: -26,
          child: Opacity(
            opacity: so.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: sr * math.pi / 180,
              child: Transform.scale(
                scale: ss,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(center: Alignment(-.32, -.44), colors: [Color(0xFFB8FBE4), Color(0xFF5CE0B8), Color(0xFF2FB58C)], stops: [0, .55, 1]),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 20, 16, .7), offset: Offset(0, 10), blurRadius: 18 / 2 / .57735, spreadRadius: -8)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AeIkon('M4.5 12.5l5 5 10-11', size: 20, stroke: 3.2, color: Color(0xFF0E4A3A)),
                      const SizedBox(height: 1),
                      Text(
                        GbCopy.delt,
                        style: inter(10, weight: FontWeight.w800, em: .14, color: const Color(0xFF0E4A3A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tekst() => Column(
    children: [
      Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color.fromRGBO(92, 224, 184, .16),
          border: Border.all(color: const Color.fromRGBO(92, 224, 184, .45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AeIkon('M4.5 12.5l5 5 10-11', size: 12, stroke: 3, color: Color(0xFF7FF0CB)),
            const SizedBox(width: 6),
            Text(
              GbCopy.lenken,
              style: inter(11, weight: FontWeight.w800, em: .08, color: const Color(0xFF7FF0CB)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: GbCopy.duHarDelt),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) =>
                    const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF0C2), Color(0xFFF2C14E), Color(0xFFD69A23)], stops: [0, .6, 1]).createShader(r),
                child: Text(GbCopy.gullbilletten, style: jakarta(27, em: -.03, height: 1.12)),
              ),
            ),
            const TextSpan(text: GbCopy.din),
          ],
        ),
        textAlign: TextAlign.center,
        style: jakarta(27, em: -.03, height: 1.12),
      ),
    ],
  );

  Widget _chip(Widget ikon, String navn) => Container(
    height: 38,
    padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .06)]),
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, .2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ikon,
        const SizedBox(width: 8),
        Text(navn, style: inter(12.5, weight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text(
          '+${widget.poeng}',
          style: aeTab(inter(12.5, weight: FontWeight.w800, color: const Color(0xFFF6D27A))),
        ),
      ],
    ),
  );

  Widget _initial() => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9A273), Color(0xFFE2531F)]),
    ),
    child: Text(widget.initial, style: inter(12, weight: FontWeight.w800)),
  );

  Widget _venn() => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color.fromRGBO(92, 224, 184, .2),
      border: Border.all(color: const Color.fromRGBO(92, 224, 184, .5)),
    ),
    child: const AeIkon('M12 5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z M5 20a7 7 0 0 1 14 0', size: 13, stroke: 2.4, color: Color(0xFF7FF0CB)),
  );

  Widget _knapper() => Row(
    children: [
      Expanded(
        flex: 10,
        child: AePress(
          key: const Key('gb-del-igjen'),
          onTap: widget.onIgjen,
          dy: 2,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.fromRGBO(255, 255, 255, .16), Color.fromRGBO(255, 255, 255, .07)]),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, .24)),
            ),
            child: Text(GbCopy.delMedFlere, style: inter(14, weight: FontWeight.w800)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 14,
        child: AePress(
          key: const Key('gb-ferdig'),
          onTap: widget.onFerdig,
          dy: 3,
          child: CssBox(
            height: 52,
            radius: BorderRadius.circular(999),
            bg: const [
              CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFE2531F)], [0, .56, 1]),
            ],
            shadows: const [CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)), CssShadow(0, 4, 0, 0, Color(0xFFA63A12)), CssShadow(0, 14, 22, -10, Color.fromRGBO(233, 92, 44, .7))],
            child: Center(
              child: Text(GbCopy.ferdig, style: inter(14.5, weight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The two radial glows of the backdrop (gold up top, mint at the foot).
class _Bakgrunn extends CustomPainter {
  const _Bakgrunn();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..shader = const CssRadial([Color.fromRGBO(242, 193, 78, .3), Color.fromRGBO(242, 193, 78, 0)], stops: [0, .7], rx: .8, ry: .42, cx: .5, cy: .34).shader(r));
    canvas.drawRect(r, Paint()..shader = const CssRadial([Color.fromRGBO(92, 224, 184, .16), Color.fromRGBO(92, 224, 184, 0)], stops: [0, .7], rx: .6, ry: .3, cx: .5, cy: 1).shader(r));
  }

  @override
  bool shouldRepaint(_Bakgrunn o) => false;
}

/// `repeating-conic-gradient(gold .17 0 7°, transparent 7° 22°)`, faded out
/// from 16 % of the radius.
class _Straaler extends CustomPainter {
  const _Straaler();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final layer = Offset.zero & size;
    canvas.saveLayer(layer, Paint());
    final p = Paint()..color = const Color.fromRGBO(246, 210, 122, .17);
    for (var a = 0.0; a < 360; a += 22) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), (a - 90) * math.pi / 180, 7 * math.pi / 180, false)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.drawRect(
      layer,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const RadialGradient(colors: [Colors.black, Colors.black, Color(0x00000000)], stops: [0, .16, 1]).createShader(layer),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Straaler o) => false;
}

/// A ticket half with notches on one side (`mask: radial-gradient(circle
/// 10px at 100% 0 …)`).
class _Hakk extends CustomClipper<Path> {
  const _Hakk({required this.hoyre});
  final bool hoyre;

  @override
  Path getClip(Size s) {
    final kropp = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & s,
          topLeft: hoyre ? const Radius.circular(20) : Radius.zero,
          bottomLeft: hoyre ? const Radius.circular(20) : Radius.zero,
          topRight: hoyre ? Radius.zero : const Radius.circular(20),
          bottomRight: hoyre ? Radius.zero : const Radius.circular(20),
        ),
      );
    final x = hoyre ? s.width : 0.0;
    final hull = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: 10))
      ..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: 10));
    return Path.combine(PathOperation.difference, kropp, hull);
  }

  @override
  bool shouldReclip(_Hakk o) => o.hoyre != hoyre;
}

class _Loddrett extends CustomPainter {
  const _Loddrett(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var y = 0.0; y < size.height; y += 12) {
      canvas.drawLine(Offset(1, y), Offset(1, math.min(y + 6, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_Loddrett o) => o.color != color;
}
