import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../../common/auth/launch/lf_widgets.dart' show LfPress;
import '../../common/home/bergen/bergen_floats.dart';
import '../kit/sjo_water.dart';
import 'hjem_fiskestang.dart';

// ── Hjem · hero (`data-hero="1"`, kategoriStil "Rom") ───────────────────────
// Prototype L2227–2520. Design px, 390 wide, `top:72px; height:258px`:
//   0–127   Bryggen seen from Nordnes (the prototype's WebGL render, baked
//           per weather into assets/images/bryggen/hjem_<vær>.jpg)
//   127–    Vågen (`Sjø · hero`): the shared water shader + vignette
//   on top  rain on the glass, the Forundringspose raft, Ægil's floats with
//           their price flags, the quay with Ægil fishing, the Fjordfiske
//           pill, the first-visit intro and the Napp card.

/// The four weathers the hero is baked for (`VAER` keys).
enum HjemVaer { regn, sol, solnedgang, natt }

extension HjemVaerLook on HjemVaer {
  String get bryggen => 'assets/images/bryggen/hjem_$name.jpg';

  /// `sjoM()`: sol → Dag; natt / solnedgang → Kveld; regn → the default
  /// `sjoModus` (Kveld).
  SjoPalette get sea => this == HjemVaer.sol ? SjoPalette.dag : SjoPalette.kveld;

  /// `uRegn`: .5 when it rains over a non-rain sea.
  double get regn => this == HjemVaer.regn ? .5 : 0;

  /// `brPal().skB` — the reflection's fog fill.
  Color get fog => switch (this) {
    HjemVaer.regn => const Color(0xFFC9D3D5),
    HjemVaer.sol => const Color(0xFFB8D1E0),
    HjemVaer.solnedgang => const Color(0xFFD9A176),
    HjemVaer.natt => const Color(0xFF1F4460),
  };

  /// `sjoKveld` / `sjoDag` base under the shader.
  Color get seaBase => this == HjemVaer.sol ? const Color(0xFF9FC3CC) : const Color(0xFF3D6B7A);
}

const double kHjemHeroTop = 72;
const double kHjemHeroH = 258;
const double _kWater = 127;

class HjemHero extends StatefulWidget {
  const HjemHero({
    super.key,
    required this.vaer,
    required this.floats,
    required this.onFloatAdd,
    required this.onFloatSink,
    required this.onFloatNever,
    required this.onPose,
    required this.onFjordfiske,
    this.nappAvailable = true,
    this.playIntro = false,
    this.extraHeight = 0,
  });

  final HjemVaer vaer;

  /// Ægil's picks (`dupper`); the first two are shown.
  final List<BergenFloatItem> floats;
  final ValueChanged<BergenFloatItem> onFloatAdd;
  final ValueChanged<BergenFloatItem> onFloatSink;
  final ValueChanged<BergenFloatItem> onFloatNever;
  final VoidCallback onPose;

  /// `sceneFiske` — Ægil on the quay and the pill both open Fjordfiske.
  final VoidCallback onFjordfiske;

  /// `napp` — today's +5 is still on the first float.
  final bool nappAvailable;
  final bool playIntro;

  /// `dY` while the sheet is dragged down.
  final double extraHeight;

  @override
  State<HjemHero> createState() => _HjemHeroState();
}

class _HjemHeroState extends State<HjemHero> {
  final SjoRipples _ripples = SjoRipples();
  final math.Random _rnd = math.Random();
  double _nextFloatRipple = 2;

  String? _valgt;
  DateTime? _valgtAt;
  bool _kort = false;
  Timer? _kortT;
  bool _intro = false;
  Timer? _introT;

  static const List<double> _xs = [195, 284];

  @override
  void initState() {
    super.initState();
    if (widget.playIntro) {
      _intro = true;
      _introT = Timer(const Duration(milliseconds: 4450), () {
        if (mounted) setState(() => _intro = false);
      });
    }
  }

  @override
  void dispose() {
    _kortT?.cancel();
    _introT?.cancel();
    _ripples.dispose();
    super.dispose();
  }

  List<BergenFloatItem> get _vis => widget.floats.take(2).toList();

  Offset _floatPos(int n) {
    final f = _vis[n];
    final erValgt = _valgt == f.id;
    return Offset(erValgt ? (n == 2 ? 268 : 232) : _xs[n], 130);
  }

  void _velg(BergenFloatItem f) {
    HapticFeedback.selectionClick();
    setState(() {
      _valgt = f.id;
      _valgtAt = DateTime.now();
      _kort = false;
    });
    _kortT?.cancel();
    _kortT = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _kort = true);
    });
  }

  void _lukk() {
    _kortT?.cancel();
    setState(() {
      _valgt = null;
      _kort = false;
    });
  }

  /// `sjoRipple` for the hero: every 1.9–3.7 s a random float rings.
  void _onWaterTick(double t) {
    if (t < _nextFloatRipple || _vis.isEmpty) return;
    _nextFloatRipple = t + 1.9 + _rnd.nextDouble() * 1.8;
    final n = _rnd.nextInt(_vis.length);
    final p = _floatPos(n);
    // flyter centre x, top + 80% of its 58px → water coordinates.
    _ripples.add(p.dx, p.dy - 8 + 58 * .8 - _kWater, .55);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vaer;
    final regn = v == HjemVaer.regn;
    final vis = _vis;
    final valgt = _valgt == null ? null : vis.where((f) => f.id == _valgt).firstOrNull;
    final valgtN = valgt == null ? -1 : vis.indexOf(valgt);
    Offset? hook;
    if (valgtN >= 0) {
      final p = _floatPos(valgtN);
      // krok: flyter left + 84% of 72, top + 50% of 58 → rod box (230,120).
      hook = Offset(p.dx - 36 + 72 * .84 - 230, p.dy - 8 + 29 - 120);
    }
    final rearOp = _intro ? 0.0 : 1.0;

    return SizedBox(
      width: 390,
      height: kHjemHeroH + widget.extraHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Bryggen (0–127).
          Positioned(
            left: 0,
            top: 0,
            width: 390,
            height: _kWater,
            child: Image.asset(v.bryggen, fit: BoxFit.fill, filterQuality: FilterQuality.medium, gaplessPlayback: true),
          ),
          // Sjø · hero (127 → bottom).
          Positioned(
            left: 0,
            right: 0,
            top: _kWater,
            bottom: 0,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: v.seaBase)),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: SjoWater(
                      palette: v.sea,
                      regn: v.regn,
                      reflection: v.bryggen,
                      reflectionHeight: _kWater,
                      fogColor: v.fog,
                      ripples: _ripples,
                      onTick: _onWaterTick,
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: CssBox(
                    bg: [
                      CssRadial(
                        [Color(0x00000000), Color(0x00000000), Color.fromRGBO(3, 14, 20, .3)],
                        stops: [0, .58, 1],
                        rx: 1.1,
                        ry: .9,
                        cx: .5,
                        cy: .3,
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromRGBO(8, 24, 32, .28), Color.fromRGBO(8, 24, 32, 0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (regn) ..._regnPaaGlass(),
          // Ægil's rain hat (`erRegn`).
          if (regn)
            Positioned(
              right: 38,
              top: 170,
              child: AnimatedOpacity(
                opacity: rearOp,
                duration: const Duration(milliseconds: 450),
                child: SvgPicture.string(_kHatt, width: 24, height: 12),
              ),
            ),
          // Quay under Ægil (`aegKaiTop` 196).
          ..._kai(),
          // Ægil's shadow, Ægil (rear) and the rod.
          Positioned(
            right: 22,
            top: 146 + 52,
            width: 58,
            height: 9,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: rearOp,
                duration: const Duration(milliseconds: 450),
                child: const CssBox(
                  bg: [
                    CssRadial([Color.fromRGBO(20, 40, 50, .35), Color.fromRGBO(20, 40, 50, .2), Color.fromRGBO(20, 40, 50, 0)], stops: [0, .55, 1]),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 230,
            top: 120,
            width: 160,
            height: 120,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: rearOp,
                duration: const Duration(milliseconds: 450),
                child: HjemFiskestang(
                  hook: hook,
                  selectedAt: _valgtAt,
                  onWater: (x, y, a) => _ripples.add(x + 230, y + 120 - _kWater, a),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 146,
            width: 58,
            height: 58,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: rearOp,
                duration: const Duration(milliseconds: 450),
                child: Image.asset('assets/images/dashboard/rear.png', filterQuality: FilterQuality.medium),
              ),
            ),
          ),
          // Tap target over Ægil (60×62, margin -6 -2 0 0).
          Positioned(
            right: 24 - 2,
            top: 146 - 6,
            width: 60,
            height: 62,
            child: IgnorePointer(
              ignoring: _intro,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onFjordfiske),
            ),
          ),
          // Fjordfiske-knapp (right 124, top 196-14).
          Positioned(
            right: 124,
            top: 196 - 14,
            width: 180,
            height: 46,
            child: IgnorePointer(
              ignoring: _intro,
              child: AnimatedOpacity(
                opacity: rearOp,
                duration: const Duration(milliseconds: 450),
                child: _FjordfiskeKnapp(onTap: widget.onFjordfiske),
              ),
            ),
          ),
          // Forundringspose · vannet.
          Positioned(left: 12, top: 94, width: 128, height: 122, child: _PoseFlate(onTap: widget.onPose)),
          // Floats (`dupper`).
          for (var n = 0; n < vis.length; n++)
            AnimatedPositioned(
              key: ValueKey('dupp-${vis[n].id}'),
              duration: const Duration(milliseconds: 750),
              curve: const Cubic(.45, .05, .3, 1),
              left: _floatPos(n).dx - 36,
              top: _floatPos(n).dy - 8,
              width: 72,
              height: 58,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: valgt != null && valgt.id != vis[n].id ? .22 : 1,
                child: _Dupp(
                  item: vis[n],
                  n: n,
                  napp: n == 0 && widget.nappAvailable,
                  onTap: () => _velg(vis[n]),
                ),
              ),
            ),
          if (_intro) ..._intro0(),
          // Napp-kort (rises 600 ms after a float is chosen).
          if (valgt != null && _kort) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _lukk,
                child: LfOnce(
                  ms: 300,
                  builder: (context, t, child) => Opacity(opacity: cssEaseOut.transform(kfP(t, 0, 300)), child: child),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.fromRGBO(6, 20, 28, .05), Color.fromRGBO(6, 20, 28, .42)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 46 + widget.extraHeight,
              child: HjemNappKort(
                item: valgt,
                onClose: _lukk,
                onAdd: () {
                  _lukk();
                  widget.onFloatAdd(valgt);
                },
                onIkkeNaa: () {
                  _lukk();
                  widget.onFloatSink(valgt);
                },
                onAldri: () {
                  _lukk();
                  widget.onFloatNever(valgt);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Rain on the glass (`erRegn`, L2244): six beads and the running drop.
  List<Widget> _regnPaaGlass() {
    Widget bead(double l, double t, double w, double h, {bool glow = false, bool warm = false}) => Positioned(
      left: l,
      top: t,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h * (w == 4 && h == 5 ? .5 : .55))),
            gradient: RadialGradient(
              center: const Alignment(-.3, -.4),
              radius: .75,
              colors: [
                Color.fromRGBO(255, 255, 255, w >= 5 ? .9 : .85),
                warm ? const Color.fromRGBO(255, 220, 150, .3) : Color.fromRGBO(255, 255, 255, w >= 5 ? .25 : .2),
                const Color.fromRGBO(255, 255, 255, .05),
              ],
              stops: const [0, .6, 1],
            ),
            boxShadow: glow ? const [BoxShadow(color: Color.fromRGBO(255, 220, 150, .35), blurRadius: 2)] : null,
          ),
        ),
      ),
    );
    return [
      Positioned(
        left: 246,
        top: 36,
        width: 3,
        height: 14,
        child: IgnorePointer(
          child: LfLoop(
            builder: (context, t, child) {
              final p = kfLoop(t, 600, 9000) ?? -1;
              if (p < 0) return const SizedBox.shrink();
              final y = kf(p, const [0, .7, 1], const [0, 150, 240]);
              final sy = kf(p, const [0, .7, 1], const [1, 1.6, 1.2]);
              final o = kf(p, const [0, .08, .7, 1], const [0, .9, .8, 0]);
              return Opacity(
                opacity: o.clamp(0.0, 1.0),
                child: Transform(
                  transform: Matrix4.translationValues(0, y, 0)..scaleByDouble(1, sy, 1, 1),
                  child: child,
                ),
              );
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0xCCFFFFFF)],
                ),
              ),
            ),
          ),
        ),
      ),
      bead(62, 64, 5, 6, glow: true),
      bead(118, 102, 4, 5),
      bead(204, 78, 6, 7, glow: true),
      bead(296, 126, 4, 5),
      bead(342, 60, 5, 6),
      bead(160, 150, 4, 4, warm: true),
    ];
  }

  /// The quay planks, edge, shade and two posts (L2350–2354).
  List<Widget> _kai() => [
    const Positioned(right: 0, top: 196, width: 124, height: 14, child: IgnorePointer(child: _Planker())),
    const Positioned(
      right: 0,
      top: 196 + 14,
      width: 124,
      height: 6,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C1A17), Color.fromRGBO(28, 26, 23, .6)],
            ),
          ),
        ),
      ),
    ),
    const Positioned(
      right: 0,
      top: 196 + 20,
      width: 124,
      height: 10,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromRGBO(8, 24, 32, .45), Color.fromRGBO(8, 24, 32, 0)],
            ),
          ),
        ),
      ),
    ),
    for (final r in const [112.0, 14.0])
      Positioned(
        right: r,
        top: 196 - 6,
        width: 5,
        height: 18,
        child: const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
              gradient: LinearGradient(colors: [Color(0xFF4A3C2A), Color(0xFF2C2114)]),
            ),
          ),
        ),
      ),
  ];

  /// `aegIntro`: Ægil walks in, says it, turns and walks to the quay (4.6s).
  List<Widget> _intro0() {
    const c = Cubic(.3, .9, .4, 1);
    Matrix4 walk(double p, {bool flip = true}) {
      final x = kf(p, const [0, .3, .38, .62, .68, .72, .96, 1], const [150, 24, 0, 0, 0, 6, 112, 112], c);
      final y = kf(p, const [0, .3, .38, .62, .68, .72, .96, 1], const [26, 6, 0, 0, 0, 2, 24, 24], c);
      final s = kf(p, const [0, .3, .38, .62, .68, .72, .96, 1], const [.62, .92, 1, 1, 1, .99, .78, .78], c);
      final ry = flip ? kf(p, const [0, .62, .68, .72, 1], const [0, 0, 90, 180, 180], c) : 0.0;
      return Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(s, s, 1, 1)
        ..rotateY(rad(ry));
    }

    return [
      Positioned(
        left: 195 - 30,
        top: 196,
        width: 60,
        height: 11,
        child: IgnorePointer(
          child: LfOnce(
            ms: 4600,
            builder: (context, t, child) {
              final p = t / 4600;
              final o = kf(p, const [0, .14, 1], const [0, .9, .9], c);
              return Opacity(
                opacity: o,
                child: Transform(alignment: Alignment.center, transform: walk(p, flip: false), child: child),
              );
            },
            child: const CssBox(
              bg: [CssRadial([Color.fromRGBO(20, 40, 50, .4), Color.fromRGBO(20, 40, 50, .2), Color.fromRGBO(20, 40, 50, 0)], stops: [0, .55, 1])],
            ),
          ),
        ),
      ),
      Positioned(
        left: 195 - 38,
        top: 140,
        width: 76,
        height: 76,
        child: IgnorePointer(
          child: LfOnce(
            ms: 4600,
            builder: (context, t, child) {
              final p = t / 4600;
              final o = kf(p, const [0, .14, 1], const [0, 1, 1], c);
              return Opacity(
                opacity: o,
                child: Transform(alignment: Alignment.bottomCenter, transform: walk(p), child: child),
              );
            },
            child: Image.asset('assets/images/dashboard/front.png', filterQuality: FilterQuality.medium),
          ),
        ),
      ),
      Positioned(
        left: 16,
        right: 64,
        top: 74,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topLeft,
            child: LfOnce(
              ms: 4600,
              builder: (context, t, child) {
                final p = t / 4600;
                final s = kf(p, const [0, .16, .2, .58, .66, 1], const [.7, 1.03, 1, 1, .94, .94], cssEaseInOut);
                final y = kf(p, const [0, .16, .2, .58, .66, 1], const [8, 0, 0, 0, 4, 4], cssEaseInOut);
                final o = kf(p, const [0, .16, .58, .66, 1], const [0, 1, 1, 0, 0], cssEaseInOut);
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, y),
                    child: Transform.scale(scale: s, alignment: Alignment.bottomRight, child: child),
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 238),
                child: CssBox(
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(16),
                  ),
                  bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .95))],
                  shadows: const [
                    CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .9)),
                    CssShadow(0, 14, 24, -12, Color.fromRGBO(15, 31, 43, .5)),
                  ],
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  child: Text(
                    HjemHeroCopy.intro,
                    style: inter(11.5, weight: FontWeight.w700, height: 1.4, color: const Color(0xFF23201D)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

abstract final class HjemHeroCopy {
  static const intro = 'Jeg har funnet spesialtilbudene dine her i Vågen. Trykk på dem, så fisker jeg dem opp for deg.';
  static const fjordfiske = 'Fjordfiske';
  static const fjordfiskeSub = 'Kast ut · vinn premier';
  static const poseType = 'FORUNDRINGSPOSE';
  static const posePris = '99 kr';
  static const leggIKurven = 'Legg i kurven';
  static const ikkeNaa = 'Ikke nå';
  static const aldri = 'Aldri dette';
}

const String _kHatt =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 22">'
    '<path d="M2 20 C6 6 38 6 42 20 C34 15 10 15 2 20 Z" fill="#F2C14E"/>'
    '<path d="M12 8 C16 2 28 2 32 8" stroke="#D9A254" stroke-width="2" fill="none"/></svg>';

/// `repeating-linear-gradient(90deg, transparent 0 18px, rgba(0,0,0,.22)
/// 18px 19px)` over `#6A5A44 → #4A3C2A 40% → #2C2114`, radius 7 0 0 3.
class _Planker extends StatelessWidget {
  const _Planker();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PlankerPainter());
}

class _PlankerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndCorners(r, topLeft: const Radius.circular(7), bottomLeft: const Radius.circular(3));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A5A44), Color(0xFF4A3C2A), Color(0xFF2C2114)],
          stops: [0, .4, 1],
        ).createShader(r),
    );
    final g = Paint()..color = const Color.fromRGBO(0, 0, 0, .22);
    for (double x = 18; x < size.width; x += 19) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), g);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), Paint()..color = const Color.fromRGBO(255, 255, 255, .28));
    canvas.restore();
    // 0 6px 10px -6px rgba(8,24,32,.6)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Keyframe helpers shared by the floats ───────────────────────────────────

/// `duppSkvulp`: scale .55 → 1.6, opacity 0 → .5 (18%) → 0, ease-out.
Widget _skvulp({required double durMs, double delayMs = 0, required Widget child}) => LfLoop(
  builder: (context, t, c) {
    final p = kfLoop(t, delayMs, durMs);
    if (p == null) return const SizedBox.shrink();
    final s = .55 + (1.6 - .55) * cssEaseOut.transform(p);
    final o = p < .18 ? kf(p, const [0, .18], const [0, .5], cssEaseOut) : kf(p, const [.18, 1], const [.5, 0], cssEaseOut);
    return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform.scale(scale: s, child: c));
  },
  child: child,
);

/// `duppRing`: scale .4 → 1.8, opacity .8 → 0, ease-out.
Widget _ringUt({required double durMs, double delayMs = 0, required Widget child}) => LfLoop(
  builder: (context, t, c) {
    final p = kfLoop(t, delayMs, durMs);
    if (p == null) return const SizedBox.shrink();
    final e = cssEaseOut.transform(p);
    return Opacity(opacity: (.8 * (1 - e)).clamp(0.0, 1.0), child: Transform.scale(scale: .4 + 1.4 * e, child: c));
  },
  child: child,
);

/// `duppDrift`: bob, tilt and squash.
Matrix4 _drift(double t, double durMs, double delayMs) {
  final p = ((t - delayMs) / durMs) % 1.0;
  final y = kf(p, const [0, .25, .5, .75, 1], const [0, -2, -3.4, -1, 0], cssEaseInOut);
  final r = kf(p, const [0, .25, .5, .75, 1], const [-2.6, 0, 2.6, 0, -2.6], cssEaseInOut);
  final sy = kf(p, const [0, .25, .5, .75, 1], const [1, .982, 1, 1.016, 1], cssEaseInOut);
  return Matrix4.translationValues(0, y, 0)
    ..rotateZ(rad(r))
    ..scaleByDouble(1, sy, 1, 1);
}

/// `prisFlagg`: rotateY(-18deg) rotateZ(-2.5deg) ↔ rotateY(16deg) rotateZ(2deg).
Matrix4 _flagg(double t, double durMs, double delayMs) {
  final p = (((t - delayMs) / durMs) % 1.0 + 1) % 1.0;
  final ry = kf(p, const [0, .5, 1], const [-18, 16, -18], cssEaseInOut);
  final rz = kf(p, const [0, .5, 1], const [-2.5, 2, -2.5], cssEaseInOut);
  return Matrix4.identity()
    ..setEntry(3, 2, -1 / 220)
    ..rotateY(rad(ry))
    ..rotateZ(rad(rz));
}

/// `duppGlans`: the water line glinting.
Widget _glans() => LfLoop(
  builder: (context, t, c) {
    final p = (t / 3800) % 1.0;
    final o = kf(p, const [0, .5, 1], const [.5, .85, .5], cssEaseInOut);
    final x = kf(p, const [0, .5, 1], const [0, 1.5, 0], cssEaseInOut);
    return Opacity(opacity: o, child: Transform.translate(offset: Offset(x, 0), child: c));
  },
  child: const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
        stops: [0, .3, .7, 1],
      ),
    ),
  ),
);

// ── A float (`dupper`, L2390) ───────────────────────────────────────────────

class _Dupp extends StatelessWidget {
  const _Dupp({required this.item, required this.n, required this.napp, required this.onTap});

  final BergenFloatItem item;
  final int n;
  final bool napp;
  final VoidCallback onTap;

  /// `ET[type]`: label, background, price colour, sub colour, rim.
  (String, List<Color>, Color, Color, Color) get _et => switch (item.kind) {
    BergenFloatKind.offer => ('TILBUD', const [Color(0xFFFF9466), Color(0xFFE95C2C)], Colors.white, const Color.fromRGBO(255, 255, 255, .88), const Color(0xFFA63A12)),
    BergenFloatKind.fresh => ('NYHET', const [Color(0xFF8CF0D2), Color(0xFF3CC79F)], const Color(0xFF0F2A30), const Color.fromRGBO(15, 42, 48, .72), const Color(0xFF1F8A6B)),
    BergenFloatKind.rhythm => ('SOM SIST', const [Color(0xFFFFFDF8), Color(0xFFEAE2D2)], const Color(0xFF1E4F5C), const Color.fromRGBO(30, 79, 92, .7), const Color(0xFFB8AC96)),
  };

  String get _vare => item.hasPhoto
      ? 'vare_mat'
      : switch (item.icon) {
          BergenFloatIcon.shrimp => 'vare_reker',
          BergenFloatIcon.fish => 'vare_sei',
          BergenFloatIcon.crate => 'vare_mat',
        };

  @override
  Widget build(BuildContext context) {
    final et = _et;
    final pris = item.priceText;
    final forPris = item.kind == BergenFloatKind.offer && item.wasPrice != null ? item.wasPrice!.round().toString() : '';
    final vare = SvgPicture.asset('assets/svgs/hjem/$_vare.svg', width: 66, height: 55);
    final driftMs = (5 + n) * 1000.0, driftDelay = n * 700.0;
    final flagMs = (4.4 + n * .8) * 1000, flagDelay = -n * 1300.0;

    return Semantics(
      button: true,
      label: '${item.title} · ${item.reason}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // duppInn .7s .5s: from 120px to the right.
        child: LfOnce(
          ms: 1200,
          builder: (context, t, child) {
            final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 500, 700));
            return Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(120 * (1 - p), 0), child: child));
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 6,
                top: 40,
                width: 62,
                height: 16,
                child: CssBox(bg: [CssRadial([Color.fromRGBO(4, 20, 28, .4), Color.fromRGBO(4, 20, 28, 0)], stops: [0, .72])]),
              ),
              Positioned(
                left: 3,
                top: 41,
                width: 68,
                height: 15,
                child: _skvulp(
                  durMs: 5000,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(214, 242, 250, .5), width: 1.2))),
                  ),
                ),
              ),
              if (item.ring)
                Positioned(
                  left: 0,
                  top: 38,
                  width: 74,
                  height: 20,
                  child: _ringUt(
                    durMs: 4000,
                    delayMs: 1200,
                    child: const DecoratedBox(
                      decoration: ShapeDecoration(shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(255, 255, 255, .85), width: 1.5))),
                    ),
                  ),
                ),
              Positioned.fill(
                child: LfLoop(
                  builder: (context, t, child) => Transform(
                    alignment: const FractionalOffset(.5, .85),
                    transform: _drift(t, driftMs, driftDelay),
                    child: child,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Reflection: scaleY(-.42) from the bottom, opacity .13, faded.
                      Positioned(
                        left: 3,
                        top: -6,
                        width: 66,
                        height: 55,
                        child: Opacity(
                          opacity: .13,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(1, -.42, 1),
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (r) => const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0x00000000), Color(0x00000000), Color(0xFF000000)],
                                stops: [0, .2, .9],
                              ).createShader(r),
                              child: vare,
                            ),
                          ),
                        ),
                      ),
                      Positioned(left: 3, top: 0, width: 66, height: 55, child: vare),
                      if (item.hasPhoto) ...[
                        const Positioned(
                          left: 20,
                          top: 14,
                          width: 34,
                          height: 9,
                          child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(40, 20, 6, .55), Color.fromRGBO(40, 20, 6, 0)])]),
                        ),
                        Positioned(
                          left: 18,
                          top: -6,
                          width: 38,
                          height: 28,
                          child: Transform.rotate(
                            angle: rad(-4),
                            child: item.photoAsset != null
                                ? Image.asset(item.photoAsset!, fit: BoxFit.contain)
                                : Image.network(item.photoUrl!, fit: BoxFit.contain, errorBuilder: (_, e, s) => const SizedBox()),
                          ),
                        ),
                      ],
                      Positioned(left: 6, right: 6, top: 40.5, height: 1.5, child: _glans()),
                      // The pole.
                      const Positioned(
                        left: 35,
                        top: -13,
                        width: 2,
                        height: 27,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(1)),
                            gradient: LinearGradient(colors: [Color(0xFFF2E2C4), Color(0xFFA88456)]),
                            boxShadow: [BoxShadow(color: Color.fromRGBO(40, 20, 6, .25), offset: Offset(1, 0))],
                          ),
                        ),
                      ),
                      // The price flag.
                      Positioned(
                        left: -10,
                        right: -10,
                        top: -42,
                        height: 31,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: LfLoop(
                            builder: (context, t, child) => Transform(
                              alignment: const FractionalOffset(.5, 1.2),
                              transform: _flagg(t, flagMs, flagDelay),
                              child: child,
                            ),
                            child: _Flagg(
                              type: et.$1,
                              bg: et.$2,
                              pris: pris,
                              forPris: forPris,
                              tx: et.$3,
                              sub: et.$4,
                              kant: et.$5,
                              napp: napp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Flagg extends StatelessWidget {
  const _Flagg({
    required this.type,
    required this.bg,
    required this.pris,
    required this.forPris,
    required this.tx,
    required this.sub,
    required this.kant,
    this.napp = false,
    this.big = false,
  });

  final String type;
  final List<Color> bg;
  final String pris;
  final String forPris;
  final Color tx, sub, kant;
  final bool napp;

  /// The Forundringspose flag (padding 4 9 4.5, radius 9, 7.5/15px).
  final bool big;

  @override
  Widget build(BuildContext context) {
    const num = [FontFeature.tabularFigures()];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CssBox(
          radius: BorderRadius.circular(big ? 9 : 7),
          bg: [CssLinear(180, bg)],
          shadows: [
            const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .55)),
            const CssShadow.inset(0, -1.5, 0, 0, Color.fromRGBO(0, 0, 0, .1)),
            CssShadow(0, 2, 0, 0, kant),
            const CssShadow(0, 8, 12, -5, Color.fromRGBO(3, 16, 24, .65)),
          ],
          padding: big ? const EdgeInsets.fromLTRB(9, 4, 9, 4.5) : const EdgeInsets.fromLTRB(7, 3, 7, 3.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type,
                softWrap: false,
                style: inter(big ? 7.5 : 7, weight: FontWeight.w800, em: big ? .08 : .09, height: 1.15, color: sub),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    pris,
                    softWrap: false,
                    style: jakarta(big ? 15 : 12.5, em: -.02, height: 1.05, color: tx).copyWith(fontFeatures: num),
                  ),
                  if (forPris.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      forPris,
                      style: inter(8.5, weight: FontWeight.w700, color: sub).copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: sub,
                        fontFeatures: num,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // The pin under the flag.
        Positioned(
          left: 0,
          right: 0,
          bottom: -3,
          child: Center(
            child: Container(
              width: 6,
              height: 4,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(1)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC9D2D6), Color(0xFF7F8B90)],
                ),
              ),
            ),
          ),
        ),
        if (napp)
          Positioned(
            right: -11,
            top: -9,
            child: LfOnce(
              ms: 500,
              builder: (context, t, child) => Transform.scale(
                scale: kf(t / 500, const [0, .35, .7, 1], const [1, 1.16, .96, 1], const Cubic(.34, 1.56, .64, 1)),
                child: child,
              ),
              child: CssBox(
                radius: BorderRadius.circular(999),
                bg: const [CssLinear(180, [Color(0xFF7EEBC9), Color(0xFF2FB893)])],
                shadows: const [
                  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .6)),
                  CssShadow(0, 1.5, 0, 0, Color(0xFF1E8A6C)),
                  CssShadow(0, 4, 8, -3, Color.fromRGBO(3, 16, 24, .6)),
                ],
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                child: Text('+5', style: inter(9, weight: FontWeight.w800, height: 1.2, color: const Color(0xFF0F1F2B))),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Forundringspose · vannet (L2424) ────────────────────────────────────────

class _PoseFlate extends StatelessWidget {
  const _PoseFlate({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget gnist(double l, double t, double s, Color c, double delay) => Positioned(
      left: l,
      top: t,
      width: s,
      height: s,
      child: LfLoop(
        builder: (context, tt, child) {
          final p = (((tt - delay) / 2400) % 1.0 + 1) % 1.0;
          final sc = kf(p, const [0, .5, 1], const [.2, 1, .2], cssEaseInOut);
          final r = kf(p, const [0, .5, 1], const [0, 45, 0], cssEaseInOut);
          final o = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
          return Opacity(opacity: o, child: Transform.rotate(angle: rad(r), child: Transform.scale(scale: sc, child: child)));
        },
        child: CustomPaint(painter: _StjernePainter(c)),
      ),
    );

    // Everything inside the 56×62 box at (10,24) is scaled 1.5 from 0,0.
    Widget scaled(List<Widget> children) => Positioned(
      left: 10,
      top: 24,
      width: 56,
      height: 62,
      child: Transform.scale(
        scale: 1.5,
        alignment: Alignment.topLeft,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );

    return Semantics(
      button: true,
      label: 'Forundringspose 99 kr · åpne',
      child: LfPress(
        scale: .94,
        ms: 140,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            scaled([
              Positioned(
                left: 4,
                top: 48,
                width: 50,
                height: 14,
                child: LfLoop(
                  builder: (context, t, child) {
                    final p = (t / 3200) % 1.0;
                    return Opacity(opacity: kf(p, const [0, .5, 1], const [.55, 1, .55], cssEaseInOut), child: child);
                  },
                  child: const CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(255, 206, 120, .4), Color.fromRGBO(255, 206, 120, 0)])]),
                ),
              ),
              Positioned(
                left: 2,
                top: 47,
                width: 52,
                height: 14,
                child: _skvulp(
                  durMs: 5000,
                  delayMs: 600,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(214, 242, 250, .5), width: 1))),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 45,
                width: 56,
                height: 17,
                child: _ringUt(
                  durMs: 4000,
                  delayMs: 1200,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(255, 255, 255, .85), width: 1))),
                  ),
                ),
              ),
            ]),
            Positioned.fill(
              child: LfLoop(
                builder: (context, t, child) => Transform(
                  alignment: const FractionalOffset(.4, .85),
                  transform: _drift(t, 6000, 400),
                  child: child,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: 51,
                      top: 30,
                      width: 2,
                      height: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(1)),
                          gradient: LinearGradient(colors: [Color(0xFFF2E2C4), Color(0xFFA88456)]),
                          boxShadow: [BoxShadow(color: Color.fromRGBO(40, 20, 6, .25), offset: Offset(1, 0))],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 104,
                      child: Center(
                        child: LfLoop(
                          builder: (context, t, child) => Transform(
                            alignment: const FractionalOffset(.5, 1.2),
                            transform: _flagg(t, 5200, -600),
                            child: child,
                          ),
                          child: const _Flagg(
                            type: HjemHeroCopy.poseType,
                            bg: [Color(0xFFFFE7A8), Color(0xFFE9AC3C)],
                            pris: HjemHeroCopy.posePris,
                            forPris: '',
                            tx: Color(0xFF5A3C10),
                            sub: Color.fromRGBO(90, 60, 16, .82),
                            kant: Color(0xFFA87418),
                            big: true,
                          ),
                        ),
                      ),
                    ),
                    scaled([
                      Positioned(
                        left: 12,
                        top: -2,
                        width: 32,
                        height: 22,
                        child: LfLoop(
                          builder: (context, t, child) {
                            final p = (t / 2600) % 1.0;
                            return Opacity(opacity: kf(p, const [0, .5, 1], const [.55, 1, .55], cssEaseInOut), child: child);
                          },
                          child: const CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(255, 220, 150, .75), Color.fromRGBO(255, 220, 150, 0)])]),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 56,
                        height: 62,
                        child: SvgPicture.asset('assets/svgs/hjem/hjem_pose.svg', width: 56, height: 62),
                      ),
                      Positioned(
                        left: 41,
                        top: 25,
                        width: 14,
                        height: 14,
                        child: LfLoop(
                          builder: (context, t, child) {
                            final p = (t / 3400) % 1.0;
                            return Transform.rotate(
                              alignment: Alignment.topCenter,
                              angle: rad(kf(p, const [0, .5, 1], const [-10, 12, -10], cssEaseInOut)),
                              child: child,
                            );
                          },
                          child: CssBox(
                            radius: BorderRadius.circular(7),
                            bg: const [CssLinear(180, [Color(0xFFFFE7A8), Color(0xFFE9AC3C)])],
                            shadows: const [
                              CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .7)),
                              CssShadow(0, 1.5, 0, 0, Color(0xFFA87418)),
                              CssShadow(0, 4, 6, -2, Color.fromRGBO(3, 16, 24, .6)),
                            ],
                            child: Center(child: Text('?', style: jakarta(9, height: 1, color: const Color(0xFF5A3C10)))),
                          ),
                        ),
                      ),
                      gnist(14, 4, 5, const Color(0xFFFFF2C8), 0),
                      gnist(34, -1, 6, const Color(0xFFFFFFFF), 1100),
                      gnist(25, -6, 4, const Color(0xFFFFE2A8), 600),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `clip-path: polygon(50% 0,62% 38%,100% 50%,62% 62%,50% 100%,38% 62%,0 50%,38% 38%)`.
class _StjernePainter extends CustomPainter {
  const _StjernePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * .5, 0)
        ..lineTo(w * .62, h * .38)
        ..lineTo(w, h * .5)
        ..lineTo(w * .62, h * .62)
        ..lineTo(w * .5, h)
        ..lineTo(w * .38, h * .62)
        ..lineTo(0, h * .5)
        ..lineTo(w * .38, h * .38)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StjernePainter old) => old.color != color;
}

// ── Fjordfiske-knapp (L2356) ────────────────────────────────────────────────

class _FjordfiskeKnapp extends StatelessWidget {
  const _FjordfiskeKnapp({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Gå til Fjordfiske',
      child: LfPress(
        scale: .95,
        dy: 1,
        ms: 140,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 4,
              right: 4,
              top: 31,
              height: 16,
              child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(4, 20, 28, .55), Color.fromRGBO(4, 20, 28, 0)])]),
            ),
            for (final (d, w, a) in const [(0.0, 1.3, .55), (2000.0, 1.0, .4)])
              Positioned(
                left: 0,
                right: 0,
                top: 30,
                height: 15,
                child: _skvulp(
                  durMs: 4000,
                  delayMs: d,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(shape: OvalBorder(side: BorderSide(color: Color.fromRGBO(214, 242, 250, a), width: w))),
                  ),
                ),
              ),
            Positioned.fill(
              child: LfLoop(
                builder: (context, t, child) => Transform(
                  alignment: const FractionalOffset(.5, .8),
                  transform: _drift(t, 6000, 0),
                  child: child,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      height: 38,
                      child: CssBox(
                        radius: BorderRadius.circular(19),
                        clip: true,
                        bg: const [CssLinear(180, [Color(0xFF438C9D), Color(0xFF2A6474), Color(0xFF1E4F5C)], [0, .46, 1])],
                        shadows: const [
                          CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .38)),
                          CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .18)),
                          CssShadow(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
                          CssShadow(0, 3, 0, 0, Color(0xFF0F2F38)),
                          CssShadow(0, 14, 18, -8, Color.fromRGBO(3, 16, 24, .8)),
                        ],
                        child: Stack(
                          children: [
                            Positioned(
                              left: 12,
                              right: 46,
                              top: 2,
                              height: 13,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, 0)],
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 32,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color.fromRGBO(60, 140, 160, .4), Color.fromRGBO(10, 40, 52, .75)],
                                  ),
                                  border: Border(top: BorderSide(color: Color.fromRGBO(226, 248, 252, .7))),
                                ),
                              ),
                            ),
                            Positioned(left: 8, right: 8, top: 32, height: 1.5, child: _glans()),
                          ],
                        ),
                      ),
                    ),
                    // The bobber (`duppNapp`).
                    Positioned(
                      left: 7,
                      top: 0,
                      width: 28,
                      height: 40,
                      child: LfLoop(
                        builder: (context, t, child) {
                          final p = (t / 5200) % 1.0;
                          const st = <double>[0, .2, .4, .62, .68, .74, .8, .88, 1];
                          final y = kf(p, st, const [0, 1.5, 0, 0, 6, -1, 3, 0, 0], cssEaseInOut);
                          final r = kf(p, st, const [0, -4, 3, 0, -8, 4, -2, 0, 0], cssEaseInOut);
                          return Transform.translate(offset: Offset(0, y), child: Transform.rotate(angle: rad(r), child: child));
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned(
                              left: 13,
                              top: 0,
                              width: 2,
                              height: 11,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(1)),
                                  gradient: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFB9C6CB)]),
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 11.5,
                              top: -2,
                              width: 5,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFFC2A6), Color(0xFFE95C2C)]),
                                  boxShadow: [BoxShadow(color: Color.fromRGBO(255, 140, 90, .85), blurRadius: 5)],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 1,
                              top: 9,
                              width: 26,
                              height: 26,
                              child: CssBox(
                                radius: BorderRadius.circular(13),
                                clip: true,
                                bg: const [
                                  CssLinear(180, [
                                    Color(0xFFFF9466),
                                    Color(0xFFE95C2C),
                                    Color(0xFFC9461C),
                                    Color(0xFFF8F6F1),
                                    Color(0xFFD3DFE3),
                                  ], [0, .47, .5, .52, 1]),
                                ],
                                shadows: const [
                                  CssShadow.inset(-4, -5, 7, 0, Color.fromRGBO(10, 30, 40, .35)),
                                  CssShadow.inset(3, 3, 5, 0, Color.fromRGBO(255, 255, 255, .35)),
                                  CssShadow(0, 0, 0, 1, Color.fromRGBO(120, 40, 10, .25)),
                                  CssShadow(0, 4, 6, -2, Color.fromRGBO(3, 16, 24, .55)),
                                ],
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 4,
                                      top: 3,
                                      width: 10,
                                      height: 6,
                                      child: Transform.rotate(
                                        angle: rad(-25),
                                        child: const CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(255, 255, 255, .95), Color.fromRGBO(255, 255, 255, 0)])]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      top: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            HjemHeroCopy.fjordfiske,
                            softWrap: false,
                            style: jakarta(13, em: -.01, height: 1.05, shadows: const [
                              Shadow(color: Color.fromRGBO(3, 16, 24, .35), offset: Offset(0, 1), blurRadius: 2),
                            ]),
                          ),
                          Text(
                            HjemHeroCopy.fjordfiskeSub,
                            softWrap: false,
                            style: inter(9.5, weight: FontWeight.w700, height: 1.15, color: const Color(0xFF9FF0D4)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 7,
                      top: 11,
                      width: 24,
                      height: 24,
                      child: CssBox(
                        radius: BorderRadius.circular(999),
                        bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                        shadows: const [
                          CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                          CssShadow(0, 2, 0, 0, Color(0xFFA63A12)),
                          CssShadow(0, 5, 8, -3, Color.fromRGBO(3, 16, 24, .6)),
                        ],
                        child: Center(
                          child: SvgPicture.string(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>',
                            width: 10,
                            height: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Napp-kort (L2484) ───────────────────────────────────────────────────────

class HjemNappKort extends StatelessWidget {
  const HjemNappKort({
    super.key,
    required this.item,
    required this.onClose,
    required this.onAdd,
    required this.onIkkeNaa,
    required this.onAldri,
  });

  final BergenFloatItem item;
  final VoidCallback onClose, onAdd, onIkkeNaa, onAldri;

  @override
  Widget build(BuildContext context) {
    final dupp = _Dupp(item: item, n: 0, napp: false, onTap: () {});
    final et = dupp._et;
    final forPris = item.kind == BergenFloatKind.offer && item.wasPrice != null ? item.wasPrice!.round().toString() : '';
    return LfOnce(
      ms: 450,
      builder: (context, t, child) {
        final p = const Cubic(.2, .9, .3, 1).transform(kfP(t, 0, 450));
        return Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 60 * (1 - p)), child: child));
      },
      child: Semantics(
        container: true,
        label: '${item.title}. ${item.reason}',
        child: CssBox(
          radius: BorderRadius.circular(24),
          bg: const [CssLinear(180, [Color.fromRGBO(52, 112, 128, .9), Color.fromRGBO(24, 64, 76, .94)])],
          shadows: const [
            CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
            CssShadow(0, 3, 0, 0, Color.fromRGBO(10, 34, 42, .85)),
            CssShadow(0, 28, 40, -18, Color.fromRGBO(3, 14, 20, .85)),
          ],
          padding: const EdgeInsets.all(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 78,
                          height: 68,
                          child: CssBox(
                            radius: BorderRadius.circular(18),
                            clip: true,
                            bg: const [
                              CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .7], rx: .8, ry: .6, cx: .5, cy: 0),
                              CssLinear(180, [Color(0xFF3E7E8E), Color(0xFF24596A), Color(0xFF173F4C)], [0, .55, 1]),
                            ],
                            shadows: const [
                              CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .35)),
                              CssShadow.inset(0, -3, 6, 0, Color.fromRGBO(3, 16, 24, .35)),
                              CssShadow(0, 8, 12, -6, Color.fromRGBO(3, 16, 24, .7)),
                            ],
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Positioned(
                                  left: 11,
                                  top: 50,
                                  width: 56,
                                  height: 10,
                                  child: CssBox(bg: [CssRadial.closestSide([Color.fromRGBO(4, 20, 28, .5), Color.fromRGBO(4, 20, 28, 0)])]),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 10,
                                  width: 62,
                                  height: 52,
                                  child: LfLoop(
                                    builder: (context, t, child) => Transform(
                                      alignment: const FractionalOffset(.5, .85),
                                      transform: _drift(t, 5000, 0),
                                      child: child,
                                    ),
                                    child: SvgPicture.asset('assets/svgs/hjem/${dupp._vare}.svg', width: 62, height: 52),
                                  ),
                                ),
                                if (item.hasPhoto)
                                  Positioned(
                                    left: 21,
                                    top: 6,
                                    width: 36,
                                    height: 27,
                                    child: Transform.rotate(
                                      angle: rad(-4),
                                      child: item.photoAsset != null
                                          ? Image.asset(item.photoAsset!, fit: BoxFit.contain)
                                          : Image.network(item.photoUrl!, fit: BoxFit.contain, errorBuilder: (_, e, s) => const SizedBox()),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: [
                                  CssBox(
                                    radius: BorderRadius.circular(6),
                                    bg: [CssLinear(180, et.$2)],
                                    shadows: [
                                      const CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .5)),
                                      CssShadow(0, 1.5, 0, 0, et.$5),
                                    ],
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text(et.$1, style: inter(8.5, weight: FontWeight.w800, em: .08, height: 1.2, color: et.$3)),
                                  ),
                                  if (item.bergensk)
                                    CssBox(
                                      radius: BorderRadius.circular(6),
                                      bg: const [CssSolid(Color.fromRGBO(255, 255, 255, .12))],
                                      shadows: const [CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .18))],
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Text('BERGENSK', style: inter(8.5, weight: FontWeight.w800, em: .08, height: 1.2, color: const Color(0xFFDCE9EC))),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              LfPretty(item.title, style: jakarta(15, em: -.02, height: 1.2)),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(item.priceText, style: jakarta(15, em: -.01).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                  if (forPris.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '$forPris kr',
                                        style: inter(11, weight: FontWeight.w700, color: const Color(0xFFBFD6DD)).copyWith(
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: const Color(0xFFBFD6DD),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  SvgPicture.string(
                                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#5CE0B8"><path d="M12 2l2.2 6.8L21 11l-6.8 2.2L12 20l-2.2-6.8L3 11l6.8-2.2z"/></svg>',
                                    width: 11,
                                    height: 11,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      item.reason,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: inter(11, weight: FontWeight.w700, color: const Color(0xFF9FF0D4)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: _KortKnapp(
                          onTap: onAdd,
                          bg: const [CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)])],
                          up: const [
                            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
                            CssShadow.inset(0, -2, 0, 0, Color.fromRGBO(0, 0, 0, .08)),
                            CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
                            CssShadow(0, 12, 16, -8, Color.fromRGBO(3, 16, 24, .75)),
                          ],
                          down: const [
                            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .4)),
                            CssShadow(0, 1, 0, 0, Color(0xFFA63A12)),
                            CssShadow(0, 4, 8, -4, Color.fromRGBO(3, 16, 24, .6)),
                          ],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 7),
                              Text(HjemHeroCopy.leggIKurven, style: jakarta(13.5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        flex: 10,
                        child: _KortKnapp(
                          onTap: onIkkeNaa,
                          bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .08)])],
                          up: const [
                            CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
                            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
                            CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .75)),
                          ],
                          child: Text(HjemHeroCopy.ikkeNaa, style: inter(12.5, weight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        flex: 10,
                        child: _KortKnapp(
                          onTap: onAldri,
                          bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .28))],
                          up: const [
                            CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
                            CssShadow.inset(0, 2, 4, 0, Color.fromRGBO(0, 0, 0, .18)),
                          ],
                          child: Text(HjemHeroCopy.aldri, style: inter(12.5, weight: FontWeight.w700, color: const Color(0xFFBFD6DD))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: -2,
                top: -2,
                child: GestureDetector(
                  onTap: onClose,
                  child: CssBox(
                    width: 28,
                    height: 28,
                    radius: BorderRadius.circular(999),
                    bg: const [CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .07)])],
                    shadows: const [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .3))],
                    child: Center(
                      child: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>',
                        width: 11,
                        height: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KortKnapp extends StatefulWidget {
  const _KortKnapp({required this.onTap, required this.bg, required this.up, this.down, required this.child});

  final VoidCallback onTap;
  final List<CssBg> bg;
  final List<CssShadow> up;
  final List<CssShadow>? down;
  final Widget child;

  @override
  State<_KortKnapp> createState() => _KortKnappState();
}

class _KortKnappState extends State<_KortKnapp> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        child: CssBox(
          height: 44,
          radius: BorderRadius.circular(14),
          bg: widget.bg,
          shadows: _down ? (widget.down ?? widget.up) : widget.up,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
