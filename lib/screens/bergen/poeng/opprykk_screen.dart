import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/points/points_app_repo.dart';
import '../../../data/points/points_models.dart';
import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_icons.dart' show LfSvg, lfMerkeInk;
import '../../common/auth/launch/lf_motion.dart';
import '../../common/home/bergen/bergen_kit.dart' show bergenSvg;
import '../aegil/aegil_bits.dart';
import '../kit/svg_sti.dart';
import '../meg/a3_services.dart';
import '../meg/meg_nivaa_card.dart' show medalFor;
import 'poeng_copy.dart';
import 'prize_art.dart';

/// Nivåopprykk (`erOpprykk`, L7502–7554 in `Ærend Kunde Launch.dc.html`,
/// design px): the aurora over Bryggen at night, then — on the prototype's
/// clock (`startOpprykk`: .5 / 1.5 / 2.6 s) — the new medal slapping in
/// (`klask`), «NIVÅOPPRYKK · Du er på {nivå}.», the gift Ægil chose (when the
/// promotion carries one), and «Hylla di har fått N nye premier». Entered from
/// a `TierPromoted` push or a `points/me` tier delta.
class OpprykkScreen extends StatefulWidget {
  const OpprykkScreen({super.key, this.tierName, this.giftName, this.api});

  final String? tierName;
  final String? giftName;
  final PointsAppApi? api;

  @override
  State<OpprykkScreen> createState() => _OpprykkScreenState();
}

class _OpprykkScreenState extends State<OpprykkScreen> {
  late final PointsAppApi _api = widget.api ?? A3Services.points();
  PointsBalance? _balance;
  Premiehylla? _shelf;
  List<PrizeClaim> _claims = const [];
  int _steg = 0;
  final List<Timer> _t = [];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _steg = 3);
        return;
      }
      for (final (ms, s) in const [(500, 1), (1500, 2), (2600, 3)]) {
        _t.add(Timer(Duration(milliseconds: ms), () {
          if (mounted) setState(() => _steg = s);
        }));
      }
    });
  }

  @override
  void dispose() {
    for (final t in _t) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final r = await Future.wait<Object?>([a3Try(_api.balance), a3Try(_api.shelf), a3Try(_api.claims)]);
    if (!mounted) return;
    setState(() {
      _balance = r[0] as PointsBalance?;
      _shelf = r[1] as Premiehylla?;
      _claims = (r[2] as List<PrizeClaim>?) ?? const [];
    });
  }

  void _skip() {
    for (final t in _t) {
      t.cancel();
    }
    setState(() => _steg = 3);
  }

  void _tilHylla() => Navigator.of(context).pushReplacementNamed('/bergen/premiehylla');

  @override
  Widget build(BuildContext context) {
    final b = _balance;
    final tier = widget.tierName ?? b?.tierName ?? '';
    final giftClaim = _claims.where((c) => c.isGift).firstOrNull;
    final gift = widget.giftName ?? giftClaim?.prizeName;
    final nye = _shelf?.prizes.where((p) => b != null && p.tierBand == b.tier).length ?? 0;
    final s = _steg;
    return Scaffold(
      backgroundColor: const Color(0xFF0C222C),
      body: LfFrame(
        child: Builder(
          builder: (context) {
            final pb = MediaQuery.paddingOf(context).bottom;
            return AeOnce(
              kind: AeInn.skjermInn,
              ms: 340,
              curve: const Cubic(.2, .9, .3, 1),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned(left: 0, right: 0, bottom: 0, height: 844, child: Image(image: AssetImage('assets/images/meg/opprykk.jpg'), fit: BoxFit.fill)),
                  const Positioned(left: 0, top: 0, width: 390, height: 320, child: _Nordlys()),
                  Positioned(
                    left: 28,
                    right: 28,
                    top: 92,
                    child: s >= 1
                        ? Column(
                            children: [
                              AeOnce(kind: AeInn.klask, ms: 700, curve: const Cubic(.3, 1.3, .5, 1), child: _Medalje(navn: tier)),
                              const SizedBox(height: 16),
                              AeOnce(kind: AeInn.stigOpp, ms: 500, delay: 200, curve: cssEaseOut, child: Text(A3PoengCopy.a3_poeng_opprykk_kicker, style: inter(11, weight: FontWeight.w800, em: .14, color: kAeMint))),
                              const SizedBox(height: 7),
                              AeOnce(
                                kind: AeInn.ord,
                                ms: 900,
                                curve: cssEaseOut,
                                child: Text(
                                  tier.isEmpty ? '' : A3PoengCopy.a3_poeng_opprykk_naa(tier),
                                  key: const Key('opprykk-tittel'),
                                  textAlign: TextAlign.center,
                                  style: jakarta(30, em: -.035, height: 1.1, color: const Color(0xFFF5F3EF)),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (s >= 2 && gift != null) Positioned(left: 22, right: 22, top: 296, child: _Gave(navn: gift, onHent: _tilHylla)),
                  if (s >= 3)
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 104 + pb * .5,
                      child: AeOnce(
                        kind: AeInn.stigOpp,
                        ms: 500,
                        curve: cssEaseOut,
                        child: AePress(
                          key: const Key('opprykk-hylla'),
                          onTap: _tilHylla,
                          child: CssBox(
                            radius: BorderRadius.circular(20),
                            bg: const [CssSolid(Color.fromRGBO(245, 243, 239, .14))],
                            shadows: const [CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(245, 243, 239, .3))],
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            child: Row(
                              children: [
                                Expanded(child: Text(A3PoengCopy.a3_poeng_opprykk_nye(nye), style: inter(12.5, weight: FontWeight.w800, height: 1.35, color: const Color(0xFFF5F3EF)))),
                                const SizedBox(width: 11),
                                Text(A3PoengCopy.a3_poeng_opprykk_se, style: inter(12, weight: FontWeight.w800, color: kAeMint)),
                                const SizedBox(width: 11),
                                const AeIkon('M9 6l6 6-6 6', size: 12, stroke: 2.8, color: kAeMint),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: (s < 3 ? 48 : 52) + pb * .5,
                    child: Center(
                      child: s < 3
                          ? AePress(
                              key: const Key('opprykk-hopp'),
                              onTap: _skip,
                              child: CssBox(
                                height: 38,
                                radius: BorderRadius.circular(999),
                                bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .14))],
                                shadows: const [CssShadow.inset(0, 0, 0, 1.5, Color.fromRGBO(255, 255, 255, .28))],
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Center(widthFactor: 1, child: Text(A3PoengCopy.a3_poeng_opprykk_hopp, style: inter(12, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)))),
                              ),
                            )
                          : GestureDetector(
                              key: const Key('opprykk-ferdig'),
                              onTap: () => Navigator.of(context).maybePop(),
                              child: Text(A3PoengCopy.a3_poeng_opprykk_ferdig, style: inter(12, weight: FontWeight.w800, color: const Color(0xFF9FB6C2))),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The 104 px medal: the metal, the 3 px ring, the dashed inner rim and the
/// embossed Æ, glowing gold.
class _Medalje extends StatelessWidget {
  const _Medalje({required this.navn});
  final String navn;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(navn);
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-.32, -.44), radius: .9, colors: m.gradient, stops: m.stops),
        boxShadow: [
          BoxShadow(color: m.ring, spreadRadius: 3),
          const BoxShadow(color: Color.fromRGBO(8, 24, 32, .9), offset: Offset(0, 18), blurRadius: 15, spreadRadius: -14),
          const BoxShadow(color: Color.fromRGBO(242, 193, 78, .35), blurRadius: 21),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: CssBox(
              radius: BorderRadius.all(Radius.circular(999)),
              shadows: [
                CssShadow.inset(0, 3, 0, 0, Color.fromRGBO(255, 255, 255, .75)),
                CssShadow.inset(0, -8, 16, 0, Color.fromRGBO(35, 32, 29, .28)),
              ],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(painter: _Stiplet(const Color.fromRGBO(90, 60, 10, .35), 2)),
            ),
          ),
          LfSvg(lfMerkeInk(m.ink), w: 66, h: 53),
        ],
      ),
    );
  }
}

class _Stiplet extends CustomPainter {
  _Stiplet(this.c, this.w);
  final Color c;
  final double w;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - w / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    const n = 30;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), i / n * 2 * math.pi, math.pi / n, false, paint);
    }
  }

  @override
  bool shouldRepaint(_Stiplet old) => false;
}

/// «HER ER NOE TIL DEG» — the gift card (`kortInn .55s`), its art bobbing,
/// «Hent» floating (`aeKnSvev 3.4s -2.2s`).
class _Gave extends StatelessWidget {
  const _Gave({required this.navn, required this.onHent});
  final String navn;
  final VoidCallback onHent;

  @override
  Widget build(BuildContext context) {
    final art = PrizeArt.of(name: navn);
    return LfOnce(
      ms: 550,
      builder: (context, t, child) {
        final e = const Cubic(.3, 1.2, .5, 1).transform((t / 550).clamp(0.0, 1.0));
        return Opacity(
          opacity: e.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 140 * (1 - e)), child: Transform.scale(scale: .86 + .14 * e, child: child)),
        );
      },
      child: CssBox(
        key: const Key('opprykk-gave'),
        radius: BorderRadius.circular(24),
        clip: true,
        bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .95))],
        shadows: const [
          CssShadow(0, 0, 0, 1, Colors.white),
          CssShadow(0, 2, 0, 0, Color(0xFFE9E1D0)),
          CssShadow(0, 4, 0, 0, Color.fromRGBO(150, 120, 70, .28)),
          CssShadow(0, 30, 44, -20, Color.fromRGBO(8, 24, 32, .8)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
              child: Text(A3PoengCopy.a3_poeng_opprykk_gave, style: inter(11, weight: FontWeight.w800, em: .1, color: const Color(0xFF8A6A1E))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 9, 15, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: 82,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: art.gradient))),
                          const Positioned.fill(
                            child: CssBox(
                              bg: [
                                CssRadial([Color.fromRGBO(255, 255, 255, .6), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .62], rx: 1.2, ry: .9, cx: .3, cy: .08),
                              ],
                            ),
                          ),
                          RepaintBoundary(
                            child: LfLoop(
                              child: SizedBox(width: 61, height: 57, child: bergenSvg(art.icon, fit: BoxFit.contain)),
                              builder: (context, t, child) => Transform.translate(
                                offset: Offset(0, kf((t / 4200) % 1.0, const [0, .5, 1], const [0, -5, 0], cssEaseInOut)),
                                child: child,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(navn, style: jakarta(16, em: -.025, height: 1.2, color: kAeInk)),
                        const SizedBox(height: 4),
                        Text(A3PoengCopy.a3_poeng_opprykk_valgt, style: inter(11, weight: FontWeight.w700, height: 1.4, color: const Color(0xFF57534B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: AePress(
                key: const Key('opprykk-hent'),
                onTap: onHent,
                dy: 0,
                scale: .98,
                child: const CssBox(
                  height: 48,
                  radius: BorderRadius.all(Radius.circular(999)),
                  bg: [
                    CssLinear(180, [Color(0xFFF68450), Color(0xFFE65A28)]),
                  ],
                  shadows: [
                    CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                    CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(150, 40, 10, .3)),
                  ],
                  child: Center(child: _Hent()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hent extends StatelessWidget {
  const _Hent();

  @override
  Widget build(BuildContext context) => Text(A3PoengCopy.a3_poeng_opprykk_hent, style: inter(14, weight: FontWeight.w800));
}

/// The aurora at full strength (`opacity .85` / `.55`, `sway 7s` / `10s 1.1s`).
class _Nordlys extends StatelessWidget {
  const _Nordlys();

  static final Path _a = svgSti('M-20 170 C70 110 160 148 250 98 C310 64 356 76 410 42');
  static final Path _b = svgSti('M-20 218 C80 164 176 196 258 146 C318 112 370 122 410 94');

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: LfLoop(
        builder: (context, t, _) {
          Widget band(Path p, double w, double op, double period, double delay) {
            final q = ((t - delay) / period) % 1.0;
            final skew = kf(q, const [0, .5, 1], const [-4, 3, -4], cssEaseInOut);
            final x = kf(q, const [0, .5, 1], const [0, 9, 0], cssEaseInOut);
            return Opacity(
              opacity: op,
              child: Transform.translate(
                offset: Offset(x, 0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.skewX(rad(skew)),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: CustomPaint(size: const Size(390, 320), painter: _Strek(p, w)),
                  ),
                ),
              ),
            );
          }

          return Stack(children: [band(_a, 34, .85, 7000, 0), band(_b, 15, .55, 10000, 1100)]);
        },
      ),
    ),
  );
}

class _Strek extends CustomPainter {
  _Strek(this.p, this.w);
  final Path p;
  final double w;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..shader = ui.Gradient.linear(const Offset(-20, 0), const Offset(410, 0), const [kAeMint, Color(0xFF9C7BE8)]),
  );

  @override
  bool shouldRepaint(_Strek old) => false;
}
