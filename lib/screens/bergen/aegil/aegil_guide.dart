import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../hjem/hjem_harness.dart';
import 'aegil_bits.dart';
import 'aegil_entry.dart';
import 'aegil_launch_copy.dart';

/// One tip (`gTips(sk).tips[i]`).
class AeGTip {
  const AeGTip(this.tx, {this.pose = 'front', this.handling, this.mal = false});
  final String tx;

  /// `popup` (Ægil from the side, facing the bubble), `voucher` (cheering,
  /// with a hop) or `front`.
  final String pose;

  /// «Spør Ægil» — the orange key that opens Ægil.
  final String? handling;

  /// Ring the guide's target ([AegilGuide.mal]) while this tip shows.
  final bool mal;
}

/// The tips per screen (`gTips`), with the real numbers where the prototype
/// has them: the store's own free-delivery threshold and the basket sum.
List<AeGTip> aegilGuideTips(String skjerm, {double sum = 0, double? gratisOver}) {
  final igjen = gratisOver == null || gratisOver <= 0 ? null : math.max(0, (gratisOver - sum).ceil());
  return switch (skjerm) {
    'utforsk' => [
      AeGTip(AeCopy.gUtforsk1, pose: 'popup', mal: true),
      AeGTip(AeCopy.gUtforsk2),
      AeGTip(AeCopy.gUtforsk3, pose: 'explore', handling: AeCopy.gSpor),
    ],
    'kategori' => [AeGTip(AeCopy.gKategori1, pose: 'popup'), AeGTip(AeCopy.gKategori2)],
    'butikk' => [
      AeGTip(AeCopy.gButikk1, pose: 'popup'),
      if (igjen != null) igjen > 0 ? AeGTip(AeCopy.gButikk2(gratisOver!.round())) : AeGTip(AeCopy.gButikkGratis, pose: 'voucher'),
    ],
    'kurv' => sum <= 0
        ? [AeGTip(AeCopy.gKurvTom, pose: 'explore', handling: AeCopy.gSpor)]
        : [
            if (igjen != null) igjen > 0 ? AeGTip(AeCopy.gKurvIgjen(igjen), pose: 'popup') : AeGTip(AeCopy.gKurvGratis, pose: 'voucher'),
            AeGTip(AeCopy.gKurv2),
          ],
    _ => const [],
  };
}

String aegilGuideTittel(String skjerm) => switch (skjerm) {
  'utforsk' => AeCopy.gUtforsk,
  'kategori' => AeCopy.gKategori,
  'butikk' => AeCopy.gButikk,
  'kurv' => AeCopy.gKurv,
  _ => '',
};

/// The Ægil-guide (`data-guide-lag`, L9495–9522): once per screen and
/// session, 1.5 s after the screen opens, Ægil walks in from the right
/// (`aegGang`), lands, and offers the screen's tips in a white bubble —
/// tap him or «Neste» for the next, ✕ to send him off. He leaves on his own
/// after 13 s, and comes back once with a later tip if the screen is still
/// open 16 s after (`gIdle`). Lay it over the screen with
/// `Positioned.fill`; it is design px inside its own [LfFrame].
class AegilGuide extends StatefulWidget {
  const AegilGuide({super.key, required this.skjerm, required this.tips, this.nav = true, this.mal});

  final String skjerm;
  final List<AeGTip> tips;

  /// The screen shows the bottom nav (Ægil stands lower beside it).
  final bool nav;

  /// What a tip with `mal` rings (`gMalSett`).
  final GlobalKey? mal;

  static final Set<String> _sett = {};
  static final Set<String> _idle = {};

  @visibleForTesting
  static void reset() {
    _sett.clear();
    _idle.clear();
  }

  @override
  State<AegilGuide> createState() => _AegilGuideState();
}

enum _Fase { borte, inn, her, ut }

class _AegilGuideState extends State<AegilGuide> with TickerProviderStateMixin {
  _Fase _fase = _Fase.borte;
  int _i = 0;
  bool _boble = false;
  bool _land = true;
  int _animN = 0;
  Timer? _t1, _t2, _t3, _auto, _idleT;

  /// The walk (`gX`): 170 → 0 in, 0 → 180 out.
  late final AnimationController _gang;
  double _fra = 170, _til = 0;
  Curve _kurve = const Cubic(.3, .15, .3, 1);

  @override
  void initState() {
    super.initState();
    _gang = AnimationController(vsync: this);
    final sk = widget.skjerm;
    if (kDebugMode && HjemHarness.guide == sk) {
      _t1 = Timer(const Duration(milliseconds: 600), () => _inn(HjemHarness.guideIdx ?? 0));
      return;
    }
    if (AegilGuide._sett.contains(sk) || widget.tips.isEmpty) {
      _planIdle();
      return;
    }
    _t1 = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || widget.tips.isEmpty) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return _planIdle();
      AegilGuide._sett.add(sk);
      _inn(0);
    });
  }

  @override
  void dispose() {
    for (final t in [_t1, _t2, _t3, _auto, _idleT]) {
      t?.cancel();
    }
    _gang.dispose();
    super.dispose();
  }

  void _planIdle() {
    _idleT?.cancel();
    if (AegilGuide._idle.contains(widget.skjerm)) return;
    _idleT = Timer(const Duration(seconds: 16), () {
      if (!mounted || _fase != _Fase.borte || widget.tips.isEmpty) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      AegilGuide._idle.add(widget.skjerm);
      _inn(math.min(1, widget.tips.length - 1));
    });
  }

  void _inn(int i) {
    if (!mounted) return;
    setState(() {
      _fase = _Fase.inn;
      _i = i;
      _boble = false;
      _fra = 170;
      _til = 0;
      _kurve = const Cubic(.3, .15, .3, 1);
    });
    _gang
      ..duration = const Duration(milliseconds: 1200)
      ..forward(from: 0);
    _t2 = Timer(const Duration(milliseconds: 1220), () => _vis(i, true));
  }

  void _vis(int i, bool land) {
    if (!mounted || widget.tips.isEmpty) return;
    final t = widget.tips[i % widget.tips.length];
    setState(() {
      _fase = _Fase.her;
      _i = i;
      _boble = true;
      _land = land && t.pose != 'voucher';
      _animN++;
    });
    _auto?.cancel();
    _auto = Timer(const Duration(seconds: 13), () => _ut());
  }

  void _neste() {
    final i = _i + 1;
    if (i >= widget.tips.length) return _ut();
    setState(() => _boble = false);
    _t3 = Timer(const Duration(milliseconds: 120), () => _vis(i, false));
  }

  void _trykk() {
    if (_fase != _Fase.her) return;
    setState(() => _boble = false);
    _t3 = Timer(const Duration(milliseconds: 120), () => _vis((_i + 1) % widget.tips.length, false));
  }

  void _ut({bool fort = false}) {
    _auto?.cancel();
    if (_fase == _Fase.borte || _fase == _Fase.ut) return;
    setState(() {
      _fase = _Fase.ut;
      _boble = false;
      _fra = 0;
      _til = 180;
      _kurve = fort ? const Cubic(.5, 0, .8, .5) : const Cubic(.45, 0, .7, .55);
    });
    _gang
      ..duration = Duration(milliseconds: fort ? 550 : 1100)
      ..forward(from: 0);
    _t3 = Timer(Duration(milliseconds: fort ? 580 : 1140), () {
      if (!mounted) return;
      setState(() => _fase = _Fase.borte);
      _planIdle();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fase == _Fase.borte || widget.tips.isEmpty) return const SizedBox.shrink();
    final tip = widget.tips[_i % widget.tips.length];
    return Material(
      type: MaterialType.transparency,
      child: _ramme(context, tip),
    );
  }

  Widget _ramme(BuildContext context, AeGTip tip) {
    return LfFrame(
      child: Builder(
        builder: (context) {
          final pb = MediaQuery.paddingOf(context).bottom;
          final loft = math.max(pb, 16.0) - 16;
          final hoyre = widget.nav ? -5.0 : 4.0;
          final bunn = (widget.nav ? 70.0 : 96.0) + loft;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (_boble && tip.mal && widget.mal != null) Positioned.fill(child: IgnorePointer(child: _Mal(mal: widget.mal!))),
              Positioned(
                right: hoyre,
                bottom: bunn,
                width: 104,
                height: 108,
                child: AnimatedBuilder(
                  animation: _gang,
                  builder: (context, child) => Transform.translate(offset: Offset(_fra + (_til - _fra) * _kurve.transform(_gang.value), 0), child: child),
                  child: _Figur(
                    key: ValueKey('$_animN${_fase.name}'),
                    fase: _fase,
                    pose: tip.pose,
                    land: _land,
                    animer: _animN > 0 && _fase == _Fase.her,
                    onTap: _trykk,
                  ),
                ),
              ),
              if (_boble)
                Positioned(
                  right: widget.nav ? 84 : 98,
                  bottom: (widget.nav ? 160.0 : 186.0) + loft,
                  width: 228,
                  child: AeOnce(
                    key: ValueKey('b$_i$_animN'),
                    kind: AeInn.vcBoble,
                    ms: 420,
                    curve: const Cubic(.25, 1.25, .45, 1),
                    alignment: Alignment.bottomRight,
                    child: _Boble(
                      tittel: aegilGuideTittel(widget.skjerm),
                      tip: tip,
                      neste: _i + 1 < widget.tips.length ? AeCopy.gNeste : AeCopy.gSkjonner,
                      teller: widget.tips.length > 1 ? '${_i + 1}/${widget.tips.length}' : '',
                      onNeste: _neste,
                      onLukk: () => _ut(),
                      onHandling: () {
                        _ut(fort: true);
                        Navigator.of(context).pushNamed(kAegilRoute);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Ægil in the guide: walking (`aegGang .44s`), then standing (`aegStaa
/// 3.6s`, or `aegilNikk 2.6s` from the side), landing (`aegLand .42s`) or
/// hopping (`aegHopp .64s`) on each new tip.
class _Figur extends StatelessWidget {
  const _Figur({super.key, required this.fase, required this.pose, required this.land, required this.animer, required this.onTap});

  final _Fase fase;
  final String pose;
  final bool land;
  final bool animer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gaar = fase == _Fase.inn || fase == _Fase.ut;
    final side = gaar || pose == 'popup';
    final flip = fase == _Fase.ut ? -1.0 : 1.0;
    final hopp = animer && !land;
    final bilde = side
        ? Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(flip, 1, 1), child: Image.asset(aePose('side'), width: 104))
        : Image.asset(aePose('front'), width: 104);
    return GestureDetector(
      key: const Key('a1_guide_aegil'),
      onTap: onTap,
      child: RepaintBoundary(
        child: LfLoop(
          frozenMs: 0,
          builder: (context, t, _) {
            // The idle / walk loop.
            Matrix4 idle;
            if (gaar) {
              final p = (t / 440) % 1.0;
              final r = kf(p, const [0, .25, .5, .75, 1], const [-2.5, 0, 2.5, 0, -2.5]);
              final y = kf(p, const [0, .25, .5, .75, 1], const [0, -5, 0, -5, 0]);
              idle = Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
            } else if (side) {
              final p = (t / 2600) % 1.0;
              final y = kf(p, const [0, .5, 1], const [0, -3, 0], cssEaseInOut);
              final r = kf(p, const [0, .5, 1], const [0, -2, 0], cssEaseInOut);
              idle = Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
            } else {
              idle = aegStaa(t, 3600);
            }
            // The landing / hop (once).
            var dy = 0.0, sx = 1.0, sy = 1.0, skS = 1.0, skO = 1.0;
            if (animer) {
              if (hopp) {
                final p = (t / 640).clamp(0.0, 1.0);
                const st = <double>[0, .14, .38, .6, .76, .9, 1.0];
                const c = Cubic(.3, .7, .4, 1);
                dy = kf(p, st, const [0, 0, -30, -10, 0, 0, 0], c);
                sx = kf(p, st, const [1, 1.1, .93, 1, 1.08, .98, 1], c);
                sy = kf(p, st, const [1, .86, 1.09, 1, .9, 1.02, 1], c);
                skS = kf(p, const <double>[0, .38, .6, 1], const <double>[1, .55, .8, 1], c);
                skO = kf(p, const <double>[0, .38, .6, 1], const <double>[1, .4, .7, 1], c);
              } else {
                final p = (t / 420).clamp(0.0, 1.0);
                sx = kf(p, const [0, .35, .7, 1], const [1, 1.07, .98, 1], cssEaseOut);
                sy = kf(p, const [0, .35, .7, 1], const [1, .9, 1.03, 1], cssEaseOut);
              }
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 22,
                  bottom: -4,
                  width: 60,
                  height: 13,
                  child: Opacity(
                    opacity: skO,
                    child: Transform.scale(
                      scale: skS,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(30, 6.5)),
                          gradient: RadialGradient(colors: [Color.fromRGBO(3, 14, 20, .55), Color.fromRGBO(3, 14, 20, 0)], stops: [0, .72]),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.translationValues(0, dy, 0)..scaleByDouble(sx, sy, 1, 1),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: idle,
                      child: Align(alignment: Alignment.bottomLeft, child: bilde),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Boble extends StatelessWidget {
  const _Boble({
    required this.tittel,
    required this.tip,
    required this.neste,
    required this.teller,
    required this.onNeste,
    required this.onLukk,
    required this.onHandling,
  });

  final String tittel;
  final AeGTip tip;
  final String neste;
  final String teller;
  final VoidCallback onNeste;
  final VoidCallback onLukk;
  final VoidCallback onHandling;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CssBox(
        key: const Key('a1_guide_boble'),
        radius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(6)),
        bg: const [
          CssLinear(180, [Colors.white, Color(0xFFF4F1EA)]),
        ],
        shadows: const [
          CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .95)),
          CssShadow(0, 2, 0, 0, Color(0xFFE5DDCD)),
          CssShadow(0, 4, 0, 0, Color(0xFFCFC5B2)),
          CssShadow(0, 5, 0, 0, Color.fromRGBO(50, 38, 20, .35)),
          CssShadow(0, 18, 28, -12, Color.fromRGBO(6, 26, 36, .75)),
        ],
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2FB893),
                    boxShadow: [BoxShadow(color: Color.fromRGBO(47, 184, 147, .18), spreadRadius: 3)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text('ÆGIL · ${tittel.toUpperCase()}', style: inter(9.5, weight: FontWeight.w800, em: .08, color: const Color(0xFF1E8F72)))),
                GestureDetector(
                  key: const Key('a1_guide_lukk'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onLukk,
                  child: Transform.translate(
                    offset: const Offset(6, 0),
                    child: const SizedBox(width: 22, height: 22, child: Center(child: AeIkon('M6 6l12 12M18 6L6 18', size: 9, stroke: 3, color: Color(0xFF8C9A9E)))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(tip.tx, style: jakarta(13, em: -.012, height: 1.36, color: const Color(0xFF12303B))),
            const SizedBox(height: 9),
            Row(
              children: [
                if (tip.handling != null) ...[
                  AePress(
                    key: const Key('a1_guide_handling'),
                    onTap: onHandling,
                    dy: 2,
                    child: CssBox(
                      height: 32,
                      radius: BorderRadius.circular(999),
                      bg: const [
                        CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
                      ],
                      shadows: const [
                        CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                        CssShadow(0, 3, 0, 0, Color(0xFFB9441A)),
                        CssShadow(0, 8, 12, -6, Color.fromRGBO(185, 68, 26, .8)),
                      ],
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: Center(child: Text(tip.handling!, style: inter(12, weight: FontWeight.w800))),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  key: const Key('a1_guide_neste'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onNeste,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(neste, style: inter(12, weight: FontWeight.w800, color: kAeTeal)),
                  ),
                ),
                const Spacer(),
                Text(teller, style: aeTab(inter(10.5, weight: FontWeight.w800, color: const Color(0xFF8C9A9E)))),
              ],
            ),
          ],
        ),
      ),
      // The tail (12 px, rotated 45°, right −5, bottom 10).
      Positioned(
        right: -5,
        bottom: 10,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: const Color(0xFFF5F2EB),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(255, 255, 255, .9), offset: Offset(1.5, -1.5))],
            ),
          ),
        ),
      ),
    ],
  );
}

/// `guideRing 1.8s` around the target: the page dimmed except a rounded
/// hole, a mint ring pulsing 2.5 → 4 px and its glow.
class _Mal extends StatelessWidget {
  const _Mal({required this.mal});

  final GlobalKey mal;

  @override
  Widget build(BuildContext context) {
    final rb = mal.currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (rb == null || !rb.attached) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final self = context.findRenderObject() as RenderBox? ?? me;
        if (self == null || !self.hasSize) return const SizedBox.shrink();
        final tl = self.globalToLocal(rb.localToGlobal(Offset.zero));
        final br = self.globalToLocal(rb.localToGlobal(rb.size.bottomRight(Offset.zero)));
        final h = math.min(br.dy - tl.dy, box.maxHeight - 190 - tl.dy);
        if (tl.dy > box.maxHeight - 220 || br.dy < 60 || h < 40) return const SizedBox.shrink();
        final r = Rect.fromLTWH(tl.dx - 5, tl.dy - 5, br.dx - tl.dx + 10, h + 10);
        return RepaintBoundary(
          child: LfLoop(
            builder: (context, t, _) => CustomPaint(size: Size.infinite, painter: _MalPainter(r, (t / 1800) % 1.0)),
          ),
        );
      },
    );
  }
}

class _MalPainter extends CustomPainter {
  _MalPainter(this.r, this.p);
  final Rect r;
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(28));
    final ring = kf(p, const [0, .5, 1], const [2.5, 4, 2.5], cssEaseInOut);
    final ringA = kf(p, const [0, .5, 1], const [.95, .7, .95], cssEaseInOut);
    final glow = kf(p, const [0, .5, 1], const [22, 30, 22], cssEaseInOut);
    final glowS = kf(p, const [0, .5, 1], const [4, 8, 4], cssEaseInOut);
    final glowA = kf(p, const [0, .5, 1], const [.45, .28, .45], cssEaseInOut);
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rr);
    canvas.drawPath(dim, Paint()..color = const Color.fromRGBO(4, 18, 26, .32));
    canvas.drawRRect(
      rr.inflate(glowS),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowS * 2
        ..color = Color.fromRGBO(92, 224, 184, glowA)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow / 2),
    );
    canvas.drawRRect(
      rr.inflate(ring / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..color = Color.fromRGBO(92, 224, 184, ringA),
    );
  }

  @override
  bool shouldRepaint(_MalPainter old) => old.p != p || old.r != r;
}
