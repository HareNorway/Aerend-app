import 'dart:async';
import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/svg_sti.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_gl.dart';
import 'sporing_scene_kai.dart';

/// **Sporing · På vei** (L6775, the WebGL branch `sjoGlPaa`): the 2.5D night
/// map of the centre — the prototype's own shader (`spKartInit`, ported as
/// `shaders/sp_kart.frag`): houses with lit windows and shadows, trees,
/// Vågen with boats and wakes, the pond and its fountain, cars with lights,
/// street lamps, people with umbrellas, rain, cloud shadows, and the route
/// glowing on the ground ahead of Ægil (`uProg`, the `kjor` clock). Over it,
/// as in the prototype: the rings at the door (`ringUt`), the store's logo
/// (`bob2`) and label, the place labels, the scale, the «Ankommer om» card,
/// Ægil on the bike (`kjor 14s`, anchored 50 % 88 %, `hopp`) or in the van
/// (anchored 50 % 92 %), and the card's inner rim. Ægil's line sits under
/// the card. 390 × 450; the card is left 14 → right 14, top 10, 420 tall.
class SpSceneKart extends StatelessWidget {
  const SpSceneKart({super.key, required this.info, required this.linje});

  final SpSceneInfo info;
  final String linje;

  static final Path rute = svgSti('M300 70 C300 110 280 136 250 150 C215 166 195 186 180 204 C165 230 150 244 118 256 C88 268 74 300 68 340');

  /// The map's masks (`spKartInit`'s two 1024² canvases) as the prototype's
  /// canvas reads them at its 300 000-pixel size: the plain reads and the
  /// mip-biased ones (ui-tools/spgl_ref.py --bake).
  static final List<SpGlTex> _tex = [
    for (final n in const ['a', 'b', 'c', 'd']) SpGlTex(AssetImage('assets/images/sporing/kart_$n.png')),
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
              height: 420,
              child: CssBox(
                radius: BorderRadius.circular(28),
                clip: true,
                bg: const [CssSolid(Color(0xFF4A5A5E))],
                shadows: [CssShadow(0, 26, 44, -22, rgba(15, 31, 43, .6))],
                // The route ahead of Ægil and Ægil himself share the `kjor`
                // clock: kept moving in `lite`, resting halfway in `still`.
                child: LfLoop(
                  essential: true,
                  frozenMs: 7000,
                  child: _Over(info: info),
                  builder: (context, t, over) {
                    final p = (t / 14000) % 1.0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: SpGl(
                            key: const Key('sp-kart-gl'),
                            asset: 'shaders/sp_kart.frag',
                            w: 362,
                            h: 420,
                            tex: _tex,
                            uniforms: (f, _, _, _) {
                              f(pal.night * .72);
                              f(pal.rain);
                              f(pal.snow);
                              f(pal.rain > 0 ? 1 : .15);
                              f(p);
                            },
                          ),
                        ),
                        over!,
                        Positioned.fill(child: IgnorePointer(child: _Bud(info: info, p: p, t: t))),
                        // The rim: inset 0 0 0 1px rgba(255,255,255,.28), inset 0 0 34px rgba(10,24,30,.35).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CssBox(
                              radius: BorderRadius.circular(28),
                              shadows: [CssShadow.inset(0, 0, 0, 1, rgba(255, 255, 255, .28)), CssShadow.inset(0, 0, 34, 0, rgba(10, 24, 30, .35))],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Ægil's line (left 24, top 394), `bobleInn .5s .4s`.
            Positioned(
              left: 24,
              top: 394,
              child: SpBobleInn(
                delay: 400,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                  decoration: BoxDecoration(
                    color: rgba(255, 255, 255, .88),
                    border: Border.all(color: rgba(255, 255, 255, .95)),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4)),
                    boxShadow: [BoxShadow(color: rgba(15, 31, 43, .5), offset: const Offset(0, 12), blurRadius: 22, spreadRadius: -12)],
                  ),
                  child: Text(
                    linje,
                    style: inter(11, weight: FontWeight.w700, height: 1.35, color: kSpInk),
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

/// What sits on the map in the prototype's WebGL branch (L6779–6795).
class _Over extends StatelessWidget {
  const _Over({required this.info});

  final SpSceneInfo info;

  static Widget _etikett(double x, double y, String tekst, {Color bg = const Color(0xE0FFFFFF), Color fg = kSpInk, double skygge = .5}) => Positioned(
    left: x,
    top: y,
    child: Container(
      padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: rgba(10, 30, 40, skygge), offset: const Offset(0, 3), blurRadius: 6, spreadRadius: -3)],
      ),
      child: Text(tekst, style: inter(9, weight: FontWeight.w800, color: fg)),
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      // The door: two rings (`ringUt 2.4s`, the second 1.2 s later).
      const Positioned(left: 54, top: 330, child: _Ring(delay: 0)),
      const Positioned(left: 54, top: 330, child: _Ring(delay: 1200)),
      // The store's logo on its pin (`bob2 2.8s`).
      Positioned(
        left: 292,
        top: 22,
        child: LfLoop(
          builder: (context, t, child) => Transform.translate(offset: Offset(0, kf((t / 2800) % 1.0, const [0, .5, 1], const [-3, 3, -3], cssEaseInOut)), child: child),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .9), spreadRadius: 1.5),
                BoxShadow(color: rgba(10, 30, 40, .7), offset: const Offset(0, 7), blurRadius: 10, spreadRadius: -4),
              ],
            ),
            child: SpLogo(size: 18, url: info.logo, name: info.butikk),
          ),
        ),
      ),
      // The store's label (rgba(20,26,28,.78); the prototype's 6 px backdrop
      // blur is left out — one blur layer per screen, and it is near opaque).
      Positioned(
        left: 236,
        top: 6,
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 2, 7, 2),
          decoration: BoxDecoration(color: rgba(20, 26, 28, .78), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: SpLogo(size: 12, url: info.logo, name: info.butikk),
              ),
              const SizedBox(width: 5),
              Text(info.butikk, style: inter(9, weight: FontWeight.w800, color: const Color(0xFFF5F3EF))),
            ],
          ),
        ),
      ),
      _etikett(176, 84, 'Fisketorget'),
      _etikett(112, 150, 'Torgallmenningen'),
      _etikett(116, 288, 'Lille Lungegårdsvann'),
      _etikett(88, 368, '${info.gate} · ${SporingCopy.a1_sporing_hjem_etikett}', bg: kSpTeal, fg: const Color(0xFFF5F3EF), skygge: .6),
      // The scale (left 14, top 400).
      Positioned(
        left: 14,
        top: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '200 m',
              style: jakarta(6.5, weight: FontWeight.w800, color: rgba(255, 255, 255, .85)).copyWith(shadows: [Shadow(color: rgba(0, 0, 0, .5), offset: const Offset(0, 1), blurRadius: 2)]),
            ),
            const SizedBox(height: 2),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(boxShadow: [BoxShadow(color: rgba(0, 0, 0, .4), offset: const Offset(0, 1), blurRadius: 2)]),
              child: const Row(
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFF23201D))),
                  Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      // «Ankommer om» (left 238, top 290, 110 wide).
      Positioned(
        left: 238,
        top: 290,
        child: SpBobleInn(delay: 300, child: _Ankommer(info: info)),
      ),
    ],
  );
}

/// `ringUt 2.4s ease-out infinite`: a 28 px ring, 2 px #F26D3D, scale .7 → 1.5
/// while it fades from .5 (painted, so no layer per frame).
class _Ring extends StatelessWidget {
  const _Ring({required this.delay});

  final double delay;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: 28,
      height: 28,
      child: LfLoop(
        builder: (context, t, _) {
          final e = t - delay;
          final p = e < 0 ? -1.0 : cssEaseOut.transform((e / 2400) % 1.0);
          return CustomPaint(painter: _RingPainter(p));
        },
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    if (p < 0) return;
    final k = .7 + .8 * p;
    canvas.drawCircle(
      size.center(Offset.zero),
      13 * k,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..color = kSpOrange.withValues(alpha: .5 * (1 - p)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.p != p;
}

/// The arrival card: label with its pulse, the countdown (ticking every
/// second to [SpSceneInfo.slutt]), the bar, the km.
class _Ankommer extends StatefulWidget {
  const _Ankommer({required this.info});

  final SpSceneInfo info;

  @override
  State<_Ankommer> createState() => _AnkommerState();
}

class _AnkommerState extends State<_Ankommer> {
  Timer? _tikk;

  @override
  void initState() {
    super.initState();
    _tikk = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.of(context)) setState(() {});
    });
  }

  @override
  void dispose() {
    _tikk?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final slutt = info.slutt;
    final rest = slutt == null ? 0 : slutt.difference(DateTime.now()).inSeconds.clamp(0, 1 << 30);
    final total = (info.totalSek ?? 1).clamp(1, 1 << 30);
    final pst = (1 - rest / total).clamp(0.0, 1.0);
    // Metres to the door from the tracking payload (`distance_metres`, backend
    // plan Step 4): the courier's live position when reported, else the store.
    final meter = info.meterIgjen;
    return CssBox(
      width: 110,
      radius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      bg: [
        CssLinear(180, [rgba(10, 32, 42, .86), rgba(6, 22, 30, .93)]),
      ],
      shadows: [CssShadow.inset(0, 1.5, 0, 0, rgba(255, 255, 255, .22)), CssShadow(0, 14, 22, -12, rgba(4, 20, 28, .9))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SpPuls(size: 5, color: kSpOrange, glow: rgba(242, 109, 61, .9)),
              const SizedBox(width: 5),
              Text(
                SporingCopy.a1_sporing_ankommer.toUpperCase(),
                style: inter(8.5, weight: FontWeight.w800, em: .08, color: kSpLabel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(spMmSs(rest), key: const Key('a1_sporing_nedtelling'), style: jakarta(26, em: -.03, height: 1)),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: rgba(255, 255, 255, .14))),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(seconds: 1),
                    widthFactor: pst,
                    alignment: Alignment.centerLeft,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                        gradient: LinearGradient(colors: [Color(0xFFF26D3D), Color(0xFFFFB27A)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (meter != null) ...[
            const SizedBox(height: 5),
            Text(
              SporingCopy.a1_sporing_km_igjen((meter / 1000).toStringAsFixed(1).replaceAll('.', ',')),
              key: const Key('a1_sporing_km_igjen'),
              style: inter(8.5, weight: FontWeight.w700, color: kSpLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ægil along the route (the WebGL branch): the bike (76², `offset-anchor`
/// 50 % 88 %, `hopp .55s`) or the van (86 × 56 `van.png`, 50 % 92 %), each
/// with its soft shadow.
class _Bud extends StatelessWidget {
  const _Bud({required this.info, required this.p, required this.t});

  final SpSceneInfo info;
  final double p, t;

  static final PathMetric _m = SpSceneKart.rute.computeMetrics().first;

  @override
  Widget build(BuildContext context) {
    final pos = _m.getTangentForOffset(_m.length * p)?.position ?? const Offset(300, 70);
    final sykkel = info.sykkel;
    final w = sykkel ? 76.0 : 86.0, h = sykkel ? 76.0 : 56.0;
    final hopp = sykkel ? kf((t / 550) % 1.0, const [0, .5, 1], const [0, -6, 0], cssEaseInOut) : 0.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: pos.dx - w * .5,
          top: pos.dy - h * (sykkel ? .88 : .92),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: sykkel
                  ? [
                      Positioned(left: 14, bottom: 2, child: _skyggeBox(48, .38)),
                      Positioned(left: 0, top: hopp, child: aegil('bike', w: 76, h: 76)),
                    ]
                  : [
                      Positioned(left: 8, bottom: 0, child: _skyggeBox(70, .4)),
                      Positioned.fill(child: aegil('van', w: 86, h: 56)),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _skyggeBox(double w, double a) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
    child: Container(
      width: w,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(10, 20, 26, a)),
    ),
  );
}
