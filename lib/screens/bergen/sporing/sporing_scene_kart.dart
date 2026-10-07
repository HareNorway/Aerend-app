import 'dart:async';
import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/svg_sti.dart';
import 'sporing_bits.dart';
import 'sporing_copy.dart';
import 'sporing_scene_kai.dart';

/// **Sporing · På vei** (L6775): the map card, built from the prototype's
/// SVG scene: the paper grid, parks, Vågen and the pond, roads, buildings
/// with roofs and windows, trees, the store and the house, the route glowing
/// and drawing itself (`rute 14s`), Ægil riding it on the bike (`kjor 14s`,
/// `hopp`) or in the van (`hjul`), the rings at the door (`ringUt`), the
/// place labels, the «Ankommer om» card with the live countdown, cloud
/// shadows drifting over (`skyskygge`) and Ægil's line under the card.
/// 390 × 450; the card is left 14 → right 14, top 10, 420 tall, radius 28.
class SpSceneKart extends StatelessWidget {
  const SpSceneKart({super.key, required this.info, required this.linje, this.regn = false});

  final SpSceneInfo info;
  final String linje;
  final bool regn;

  static final Path rute = svgSti('M300 70 C300 110 280 136 250 150 C215 166 195 186 180 204 C165 230 150 244 118 256 C88 268 74 300 68 340');

  @override
  Widget build(BuildContext context) => SpSceneInn(
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
              bg: const [CssSolid(Color(0xFFEEEAE2))],
              shadows: [CssShadow.inset(0, 2, 0, 0, rgba(255, 255, 255, .9)), CssShadow(0, 26, 44, -22, rgba(15, 31, 43, .5))],
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The map itself and the route drawing.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: LfLoop(
                        builder: (context, t, _) => CustomPaint(
                          painter: _KartPainter(info: info, p: (t / 14000) % 1.0),
                        ),
                      ),
                    ),
                  ),
                  // Labels.
                  Positioned(
                    left: 236,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(3, 2, 7, 2),
                      decoration: BoxDecoration(color: rgba(35, 32, 29, .78), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpLogo(size: 12, url: info.logo, name: info.butikk),
                          const SizedBox(width: 5),
                          Text(
                            info.butikk,
                            style: inter(9, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _etikett(206, 170, 'Fisketorget'),
                  _etikett(120, 176, 'Torgallmenningen'),
                  _etikett(150, 286, 'Lille Lungegårdsvann'),
                  Positioned(
                    left: 86,
                    top: 346,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
                      decoration: BoxDecoration(color: kSpTeal, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${info.gate} · ${SporingCopy.a1_sporing_hjem_etikett}',
                        style: inter(9, weight: FontWeight.w800, color: const Color(0xFFF5F3EF)),
                      ),
                    ),
                  ),
                  // «Ankommer om» (left 238, top 290, 110 wide).
                  Positioned(
                    left: 238,
                    top: 290,
                    child: SpBobleInn(delay: 300, child: _Ankommer(info: info)),
                  ),
                  // The courier on the route.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LfLoop(
                        builder: (context, t, _) => _Bud(info: info, p: (t / 14000) % 1.0, t: t),
                      ),
                    ),
                  ),
                  if (regn) ...[_regn(.14, .1, 1600, 100), _regn(.44, .3, 1400, 600), _regn(.78, .2, 1700, 1000)],
                  // Cloud shadows and the glass overlay.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            _sky(-.3, -.1, .7, .6, .16, 28, 26000, 0),
                            _sky(-.3, .45, .55, .5, .13, 26, 34000, 8000),
                            Positioned.fill(
                              child: CssBox(
                                bg: [
                                  CssLinear(160, [rgba(255, 255, 255, .35), rgba(255, 255, 255, 0), rgba(0, 0, 0, 0), rgba(15, 31, 43, .22)], const [0, .36, .7, 1]),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              child: CssBox(radius: BorderRadius.circular(28), shadows: [CssShadow.inset(0, 0, 40, 0, rgba(15, 31, 43, .28))]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  static Widget _etikett(double x, double y, String tekst) => Positioned(
    left: x,
    top: y,
    child: Container(
      padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
      decoration: BoxDecoration(color: rgba(255, 255, 255, .85), borderRadius: BorderRadius.circular(8)),
      child: Text(
        tekst,
        style: inter(9, weight: FontWeight.w800, color: kSpInk),
      ),
    ),
  );

  static Widget _regn(double x, double y, double dur, double delay) => Positioned(
    left: 362 * x,
    top: 420 * y,
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : (e / dur) % 1.0;
        final o = kf(p, const [0, .12, .9, 1], const [0, .7, .6, 0]);
        return Opacity(
          opacity: o,
          child: Transform.translate(offset: Offset(0, -30 + 180 * p), child: child),
        );
      },
      child: Container(width: 1, height: 12, color: rgba(30, 79, 92, .35)),
    ),
  );

  static Widget _sky(double x, double y, double w, double h, double a, double blur, double dur, double delay) => Positioned(
    left: 362 * x,
    top: 420 * y,
    child: LfLoop(
      builder: (context, t, child) {
        final e = t - delay;
        final p = e < 0 ? 0.0 : (e / dur) % 1.0;
        return FractionalTranslation(translation: Offset(-.4 + 1.6 * p, 0), child: child);
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
        child: Container(
          width: 362 * w,
          height: 420 * h,
          decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(15, 31, 43, a)),
        ),
      ),
    ),
  );
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
        CssLinear(180, [rgba(10, 32, 42, .88), rgba(6, 22, 30, .94)]),
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

/// Ægil along the route: the bike (76, anchored 50 % 76 %, `hopp .55s`) or
/// the van (86 × 56, wheels turning, Ægil in the window).
class _Bud extends StatelessWidget {
  const _Bud({required this.info, required this.p, required this.t});

  final SpSceneInfo info;
  final double p, t;

  static final PathMetric _m = SpSceneKart.rute.computeMetrics().first;

  @override
  Widget build(BuildContext context) {
    final pos = _m.getTangentForOffset(_m.length * p)?.position ?? const Offset(300, 70);
    if (info.sykkel) {
      final h = kf((t / 550) % 1.0, const [0, .5, 1], const [0, -6, 0], cssEaseInOut);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: pos.dx - 38,
            top: pos.dy - 58,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 14,
                    bottom: 2,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                      child: Container(
                        width: 48,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(15, 31, 43, .28)),
                      ),
                    ),
                  ),
                  Positioned(left: 0, top: h, child: aegil('bike', w: 76, h: 76)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final hjul = -(t / 500 % 1.0) * 6.2832;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: pos.dx - 43,
          top: pos.dy - 44,
          child: SizedBox(
            width: 86,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  bottom: 0,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: rgba(15, 31, 43, .3)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _BilPainter(hjul: hjul)),
                ),
                Positioned(
                  left: 32,
                  top: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 24,
                      height: 16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [Positioned(left: -8, top: -2, child: aegil('popup', w: 40, h: 40))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The prototype's little van (86 × 56).
class _BilPainter extends CustomPainter {
  const _BilPainter({required this.hjul});

  final double hjul;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(svgSti('M6 40 C4 30 10 26 18 24 L28 12 C30 9 34 8 38 8 H62 C68 8 72 12 74 18 L80 26 C84 28 84 36 82 40 Z'), Paint()..color = kSpTeal);
    canvas.drawPath(svgSti('M28 24 L34 13 H60 L66 24 Z'), Paint()..color = const Color(0xD99FB6C2));
    canvas.drawLine(
      const Offset(48, 13),
      const Offset(48, 24),
      Paint()
        ..color = kSpTeal
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      svgSti('M8 34 C10 28 16 26 22 26 H80'),
      Paint()
        ..color = rgba(255, 255, 255, .35)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 30, 6, 5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFFFD98A));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(78, 30, 5, 5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFE85D4A));
    for (final cx in const [22.0, 66.0]) {
      canvas.save();
      canvas.translate(cx, 42);
      canvas.rotate(hjul);
      canvas.drawCircle(Offset.zero, 9, Paint()..color = kSpInk);
      canvas.drawCircle(Offset.zero, 4.5, Paint()..color = const Color(0xFFB9C4CC));
      canvas.drawPath(
        svgSti('M0 -8 V8 M-8 0 H8'),
        Paint()
          ..color = kSpInk
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 26, 18, 7), const Radius.circular(2)), Paint()..color = const Color(0xFFF5F3EF));
    canvas.drawLine(
      const Offset(39, 30),
      const Offset(51, 30),
      Paint()
        ..color = kSpTeal
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BilPainter old) => old.hjul != hjul;
}

/// The map (362 × 420), from the prototype's SVG.
class _KartPainter extends CustomPainter {
  const _KartPainter({required this.info, required this.p});

  final SpSceneInfo info;
  final double p;

  static final Path _park1 = svgSti('M100 210 C140 192 230 200 262 236 C250 276 198 300 140 286 C104 276 86 236 100 210Z');
  static final Path _vann = svgSti('M226 -10 C236 40 256 70 300 92 C330 106 350 118 362 128 V-10 Z');
  static final Path _bolger = svgSti('M270 20 q6 -3 12 0 q6 3 12 0 M300 50 q6 -3 12 0 q6 3 12 0 M330 94 q6 -3 12 0 q6 3 12 0 M250 8 q6 -3 12 0');
  static final Path _strand = svgSti('M232 -10 C242 38 260 66 302 88 C330 102 348 114 362 124');
  static final Path _veier = svgSti('M0 110 H180 M100 0 V420 M0 210 C60 206 120 200 190 200 M240 100 C250 170 260 250 250 420 M0 300 H150 M300 160 C280 240 270 320 330 420');
  static final Path _dam = svgSti('M150 262 C160 244 180 240 192 240 C210 240 226 248 234 262 C226 276 208 284 192 284 C176 284 158 278 150 262Z');
  static final Path _damLys = svgSti('M158 256 C170 246 200 246 226 258');
  static final Path _takLinjer = svgSti('M23 41 L85 89 M115 31 L163 83 M43 133 L117 185 M259 183 L309 245 M151 315 L233 361 M23 233 L85 281');

  static const _bygg = [
    (18.0, 36.0, 72.0, 58.0, Color(0xFFB9BEB7)),
    (110.0, 26.0, 58.0, 62.0, Color(0xFFC98A6C)),
    (186.0, 112.0, 62.0, 52.0, Color(0xFFB9BEB7)),
    (38.0, 128.0, 84.0, 62.0, Color(0xFFC9B99A)),
    (254.0, 178.0, 60.0, 72.0, Color(0xFFB9BEB7)),
    (292.0, 258.0, 60.0, 60.0, Color(0xFFC98A6C)),
    (146.0, 310.0, 92.0, 56.0, Color(0xFFC9B99A)),
    (18.0, 228.0, 72.0, 58.0, Color(0xFFC98A6C)),
    (18.0, 332.0, 42.0, 50.0, Color(0xFFB9BEB7)),
  ];
  static const _vinduer = [
    (45.0, 61.0),
    (56.0, 61.0),
    (130.0, 53.0),
    (141.0, 53.0),
    (71.0, 155.0),
    (82.0, 155.0),
    (275.0, 210.0),
    (286.0, 210.0),
    (183.0, 334.0),
    (194.0, 334.0),
    (45.0, 253.0),
    (56.0, 253.0),
  ];
  static const _traer = [
    (148.0, 232.0, 6.0),
    (236.0, 286.0, 6.0),
    (160.0, 292.0, 5.0),
    (300.0, 60.0, 7.0),
    (120.0, 120.0, 5.0),
    (214.0, 236.0, 5.0),
    (90.0, 208.0, 4.0),
    (316.0, 380.0, 7.0),
    (342.0, 404.0, 5.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    // Paper grid.
    canvas.drawRect(r, Paint()..color = const Color(0xFFEBE6DC));
    final grid = Paint()
      ..color = rgba(35, 32, 29, .05)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Parks.
    final park = Paint()..color = const Color(0xFFCFDEC4);
    canvas.drawPath(_park1, park);
    canvas.drawOval(Rect.fromCenter(center: const Offset(330, 392), width: 128, height: 84), park);
    // Vågen.
    final vann = Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8FC2D0), Color(0xFF5C97A8)]).createShader(r);
    canvas.drawPath(_vann, vann);
    canvas.drawPath(
      _bolger,
      Paint()
        ..color = rgba(255, 255, 255, .55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _strand,
      Paint()
        ..color = const Color(0xB34F8899)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    // Roads.
    Paint vei(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_veier, vei(const Color(0xFFDAD3C6), 13));
    canvas.drawPath(_veier, vei(const Color(0xFFFBFAF6), 9));
    canvas.drawPath(svgStreker(_veier, const [4, 6], 0), vei(rgba(35, 32, 29, .14), 1));
    // Buildings: shadows, bodies, roofs, ridge lines, windows.
    for (final (x, y, w, h, _) in _bygg) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 3, y + 4, w, h), const Radius.circular(5)), Paint()..color = rgba(35, 32, 29, .16));
    }
    for (final (x, y, w, h, tak) in _bygg) {
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(5));
      canvas.drawRRect(rr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDE7DA), Color(0xFFD5CCBB)]).createShader(rr.outerRect));
      canvas.drawRRect(
        rr,
        Paint()
          ..color = rgba(35, 32, 29, .12)
          ..style = PaintingStyle.stroke,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 5, y + 5, w - 10, h - 10), const Radius.circular(3)), Paint()..color = tak);
    }
    canvas.drawPath(
      _takLinjer,
      Paint()
        ..color = rgba(255, 255, 255, .3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    for (final (x, y) in _vinduer) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 8, 8), const Radius.circular(1.5)), Paint()..color = rgba(35, 32, 29, .14));
    }
    // The pond and its fountain.
    canvas.drawPath(_dam, vann);
    canvas.drawPath(
      _damLys,
      Paint()
        ..color = rgba(255, 255, 255, .5)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      const Offset(192, 262),
      const Offset(192, 248),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(const Offset(192, 247), 2.6, Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: const Offset(192, 264), width: 16, height: 6), Paint()..color = rgba(255, 255, 255, .35));
    // Trees.
    for (final (cx, cy, rad_) in _traer) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 2, cy + 5), width: rad_ * 2, height: rad_ * .9), Paint()..color = rgba(35, 32, 29, .22));
      canvas.drawCircle(Offset(cx, cy), rad_, Paint()..color = const Color(0xFF4E8A5E));
      canvas.drawCircle(Offset(cx - rad_ * .3, cy - rad_ * .3), rad_ * .55, Paint()..color = const Color(0xFF7DB27E));
    }
    // The route: glow, base, dots, the orange line drawing itself.
    final rute = SpSceneKart.rute;
    canvas.drawPath(rute, vei(rgba(242, 109, 61, .28), 14)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(rute, vei(rgba(30, 79, 92, .22), 10));
    canvas.drawPath(svgStreker(rute, const [1, 7], 0), vei(kSpTeal, 4));
    final m = rute.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * p), vei(kSpOrange, 4.5));
    // The store (286,50) and the house (54,330).
    _butikk(canvas);
    _hus(canvas);
    // Scale bar.
    canvas.drawRect(const Rect.fromLTWH(14, 398, 40, 3), Paint()..color = rgba(35, 32, 29, .7));
    canvas.drawRect(const Rect.fromLTWH(34, 398, 20, 3), Paint()..color = rgba(255, 255, 255, .9));
    final tp = TextPainter(
      text: TextSpan(
        text: '200 m',
        style: jakarta(6.5, color: rgba(35, 32, 29, .6)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(14, 388));
    // Vignette.
    canvas.drawRect(r, Paint()..shader = RadialGradient(radius: .72, colors: [rgba(35, 32, 29, 0), rgba(35, 32, 29, .22)], stops: const [.6, 1]).createShader(r));
    // Rings at the door (`ringUt 2.4s`, two, 1.2 s apart).
    for (final d in const [0.0, .5]) {
      final q = cssEaseOut.transform(((p * 14000 / 2400) + d) % 1.0);
      canvas.drawCircle(
        const Offset(68, 344),
        14 * (.7 + .8 * q),
        Paint()
          ..color = kSpOrange.withValues(alpha: .5 * (1 - q))
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _butikk(Canvas canvas) {
    canvas.save();
    canvas.translate(286, 50);
    canvas.drawOval(Rect.fromCenter(center: const Offset(14, 32), width: 36, height: 8), Paint()..color = rgba(35, 32, 29, .25));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, 8, 32, 22), const Radius.circular(3)), Paint()..color = const Color(0xFFB4593E));
    canvas.drawPath(svgSti('M-5 9 L14 -4 L33 9 Z'), Paint()..color = const Color(0xFF7A3A2A));
    for (var x = -2.0; x < 30; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 9, 3, 5), Paint()..color = const Color(0xFFB9441A));
      canvas.drawRect(Rect.fromLTWH(x + 3, 9, 3, 5), Paint()..color = const Color(0xFFF5EBDD));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, 18, 6, 12), const Radius.circular(1)), Paint()..color = const Color(0xFF3A3128));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 16, 6, 6), const Radius.circular(1)), Paint()..color = const Color(0xFFFFD98A));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 16, 6, 6), const Radius.circular(1)), Paint()..color = const Color(0xFFFFD98A));
    canvas.drawCircle(const Offset(14, -8), 8, Paint()..color = Colors.white);
    final tp = TextPainter(
      text: TextSpan(
        text: info.butikk.isEmpty ? 'Æ' : info.butikk.characters.first.toUpperCase(),
        style: jakarta(9, color: const Color(0xFF7A3A22)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(14 - tp.width / 2, -8 - tp.height / 2));
    canvas.restore();
  }

  void _hus(Canvas canvas) {
    canvas.save();
    canvas.translate(54, 330);
    canvas.drawOval(Rect.fromCenter(center: const Offset(14, 34), width: 32, height: 8), Paint()..color = rgba(35, 32, 29, .25));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 10, 28, 24), const Radius.circular(3)), Paint()..color = const Color(0xFFE9E2D2));
    canvas.drawPath(svgSti('M-3 11 L14 -3 L31 11 Z'), Paint()..color = const Color(0xFF3A4548));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, 22, 6, 12), const Radius.circular(1)), Paint()..color = const Color(0xFF3A3128));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 14, 6, 6), const Radius.circular(1)), Paint()..color = const Color(0xFFFFCE7A));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 14, 6, 6), const Radius.circular(1)), Paint()..color = const Color(0xFFFFCE7A));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KartPainter old) => old.p != p || old.info != info;
}
