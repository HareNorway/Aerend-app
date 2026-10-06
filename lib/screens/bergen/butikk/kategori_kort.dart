import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_fav_heart.dart';
import '../kit/bergen_motion.dart';
import '../sok/sok_oversikt.dart' show SokIkon;

// ── Kategori cards (L6048–6120, `butikkListe` / `produktListe`) ─────────────
// Cream cards that float in 3D (`bm3Svev`), follow the finger (`bmTiltMove`),
// carry a moving holographic sheen (`bm3Holo`) and a spinning coin
// (`bm3Mynt`). Everything above the card face sits at its own depth
// (`translateZ`), so it shifts against the card as it turns.

/// One store card's content.
class KatButikkVis {
  const KatButikkVis({
    required this.id,
    required this.navn,
    required this.sub,
    required this.nr,
    this.bannerUrl,
    this.logoUrl,
    this.eta,
    this.midt,
    this.midtGratis = false,
    this.live,
    this.poeng,
    this.tag,
  });

  final int id;
  final String navn;
  final String sub;

  /// Place in the list: picks the card's colour and float phase.
  final int nr;
  final String? bannerUrl;
  final String? logoUrl;
  final String? eta;

  /// The bottom row's middle item: the delivery fee where it is known,
  /// otherwise the rating.
  final String? midt;
  final bool midtGratis;
  final int? live;
  final int? poeng;
  final String? tag;
}

/// One product card's content.
class KatProduktVis {
  const KatProduktVis({
    required this.id,
    required this.storeId,
    required this.navn,
    required this.butikk,
    required this.pris,
    required this.nr,
    required this.fargeNr,
    this.bildeUrl,
    this.logoUrl,
    this.eta,
    this.kroner,
    this.tag,
  });

  final int id;
  final int storeId;
  final String navn;
  final String butikk;
  final String pris;
  final int nr;

  /// The store's place in the store list (the card's colour).
  final int fargeNr;
  final String? bildeUrl;
  final String? logoUrl;
  final String? eta;
  final int? kroner;

  /// `Mest kjøpt` / `Ny` / `Tilbud`.
  final String? tag;
}

/// `bmFarge` / `bmDyp`.
const List<Color> kKatFarge = [
  Color(0xFFF26D3D),
  Color(0xFFE2453F),
  Color(0xFFF0A93B),
  Color(0xFFF08A8A),
];
const List<Color> kKatDyp = [
  Color(0xFFB8380F),
  Color(0xFFA3172A),
  Color(0xFFA85A12),
  Color(0xFFB23A55),
];

const Color _kInk = Color(0xFF23201D);
const Color _kGra = Color(0xFF6E675D);
const List<Color> _kKnapp = [
  Color(0xFFF9A273),
  Color(0xFFF26D3D),
  Color(0xFFDD5A25),
];

/// A loop with a phase offset (CSS negative `animation-delay`).
class KatLoop extends StatelessWidget {
  const KatLoop({
    super.key,
    required this.durationMs,
    required this.builder,
    this.phaseMs = 0,
    this.child,
  });

  final double durationMs;
  final double phaseMs;
  final Widget Function(BuildContext context, double p, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => OnbLoopClock(
    child: child,
    builder: (context, t, child) =>
        builder(context, ((t + phaseMs) % durationMs) / durationMs, child),
  );
}

/// CSS `transform` in the card's 3D space: positive z comes toward you.
Matrix4 katPerspektiv(double perspektiv) =>
    Matrix4.identity()..setEntry(3, 2, -1 / perspektiv);

/// `translateZ(z)` inside a card that turns.
Widget katZ(double z, Widget child) =>
    Transform(transform: Matrix4.translationValues(0, 0, z), child: child);

/// The float (`bm3Svev`), the finger tilt (`--rx`/`--ry`, `bmTiltMove` /
/// `bmTiltUt`) and the press (`scale(.975)`), around one card. [builder]
/// gets the light's position (`--mx`/`--my`, 0–1).
class KatSvevKort extends StatefulWidget {
  const KatSvevKort({
    super.key,
    required this.perspektiv,
    required this.svevMs,
    required this.faseMs,
    required this.tiltK,
    required this.trykk,
    required this.onTap,
    required this.builder,
  });

  final double perspektiv;
  final double svevMs;
  final double faseMs;

  /// `data-tilt` — degrees across the card.
  final double tiltK;
  final double trykk;
  final VoidCallback onTap;
  final Widget Function(BuildContext context, Offset lys) builder;

  @override
  State<KatSvevKort> createState() => _KatSvevKortState();
}

class _KatSvevKortState extends State<KatSvevKort>
    with SingleTickerProviderStateMixin {
  // `transition: transform .7s cubic-bezier(.3,1.4,.5,1)` back to rest.
  late final AnimationController _tilbake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Offset _tilt = Offset.zero;
  Offset _tiltFra = Offset.zero;
  Offset _lys = const Offset(.3, .2);
  Offset _lysFra = const Offset(.3, .2);
  bool _ned = false;

  static const Curve _tilbakeKurve = Cubic(.3, 1.4, .5, 1);

  @override
  void initState() {
    super.initState();
    _tilbake.addListener(() {
      final e = _tilbakeKurve.transform(_tilbake.value);
      setState(() {
        _tilt = Offset.lerp(_tiltFra, Offset.zero, e)!;
        _lys = Offset.lerp(_lysFra, const Offset(.3, .2), e)!;
      });
    });
  }

  @override
  void dispose() {
    _tilbake.dispose();
    super.dispose();
  }

  void _flytt(PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final l = box.globalToLocal(e.position);
    final x = (l.dx / box.size.width).clamp(0.0, 1.0);
    final y = (l.dy / box.size.height).clamp(0.0, 1.0);
    _tilbake.stop();
    setState(() {
      _tilt = Offset((.5 - y) * widget.tiltK, (x - .5) * widget.tiltK * 1.3);
      _lys = Offset(x, y);
    });
  }

  void _slipp() {
    _tiltFra = _tilt;
    _lysFra = _lys;
    _tilbake.forward(from: 0);
    if (_ned) setState(() => _ned = false);
  }

  @override
  Widget build(BuildContext context) {
    final innhold = RepaintBoundary(child: widget.builder(context, _lys));
    return Listener(
      onPointerDown: (e) {
        setState(() => _ned = true);
        _flytt(e);
      },
      onPointerMove: _flytt,
      onPointerUp: (_) => _slipp(),
      onPointerCancel: (_) => _slipp(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _ned ? widget.trykk : 1,
          duration: const Duration(milliseconds: 200),
          curve: const Cubic(.3, 1.3, .5, 1),
          child: KatLoop(
            durationMs: widget.svevMs,
            phaseMs: widget.faseMs,
            child: innhold,
            builder: (context, p, child) {
              // bm3Svev: rotateX(5°) rotateY(-7°) ↔ rotateX(-3°) rotateY(7°).
              final rx = kf(p, const [0, .5, 1], const [5, -3, 5], Curves.easeInOut);
              final ry = kf(p, const [0, .5, 1], const [-7, 7, -7], Curves.easeInOut);
              const d = math.pi / 180;
              return Transform(
                alignment: Alignment.center,
                transform: katPerspektiv(widget.perspektiv)
                  ..rotateX(_tilt.dx * d)
                  ..rotateY(_tilt.dy * d)
                  ..rotateX(rx * d)
                  ..rotateY(ry * d),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// `bm3Holo 5s ease-in-out infinite alternate` — a 115° gradient on a 260%
/// box whose position runs 0% → 100% and back.
class KatHolo extends StatelessWidget {
  const KatHolo({
    super.key,
    required this.farger,
    required this.stopp,
    this.dodge = 0,
    this.halvMs = 5000,
  });

  final List<Color> farger;
  final List<double> stopp;

  /// One way of the `alternate` loop (`bm3Holo 5s` → 5000).
  final double halvMs;

  /// `mix-blend-mode: color-dodge` at this opacity (0: normal blending).
  final double dodge;

  @override
  Widget build(BuildContext context) => KatLoop(
    durationMs: halvMs * 2,
    builder: (context, p, _) {
      final raw = p * 2;
      final e = Curves.easeInOut.transform(raw <= 1 ? raw : 2 - raw);
      return CustomPaint(painter: _HoloMaler(farger, stopp, e, dodge));
    },
  );
}

class _HoloMaler extends CustomPainter {
  _HoloMaler(this.farger, this.stopp, this.p, this.dodge);

  final List<Color> farger;
  final List<double> stopp;
  final double p;
  final double dodge;

  @override
  void paint(Canvas canvas, Size size) {
    final bw = size.width * 2.6, bh = size.height * 2.6;
    final box = Rect.fromLTWH(
      -(bw - size.width) * p,
      -(bh - size.height) * p,
      bw,
      bh,
    );
    const a = 115 * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final len = (bw * dir.dx).abs() + (bh * dir.dy).abs();
    final c = box.center;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        c - dir * (len / 2),
        c + dir * (len / 2),
        farger,
        stopp,
      );
    if (dodge > 0) {
      paint
        ..blendMode = BlendMode.colorDodge
        ..color = Color.fromRGBO(0, 0, 0, dodge);
    }
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_HoloMaler old) => old.p != p;
}

const List<Color> kKatHoloLys = [
  Color.fromRGBO(255, 255, 255, 0),
  Color.fromRGBO(255, 190, 160, .34),
  Color.fromRGBO(255, 228, 150, .34),
  Color.fromRGBO(245, 185, 225, .3),
  Color.fromRGBO(255, 255, 255, 0),
];
const List<double> kKatHoloLysStopp = [.28, .40, .48, .56, .68];

const List<Color> kKatHoloSterk = [
  Color.fromRGBO(255, 255, 255, 0),
  Color.fromRGBO(255, 120, 80, .6),
  Color.fromRGBO(255, 214, 120, .6),
  Color.fromRGBO(255, 150, 190, .55),
  Color.fromRGBO(210, 150, 255, .45),
  Color.fromRGBO(255, 255, 255, 0),
];
const List<double> kKatHoloSterkStopp = [.22, .36, .45, .54, .63, .76];

/// `radial-gradient(circle at var(--mx) var(--my), rgba(255,255,255,a),
/// transparent r)` with a blend mode.
class _Lys extends StatelessWidget {
  const _Lys({
    required this.lys,
    required this.alfa,
    required this.radius,
    required this.blend,
  });

  final Offset lys;
  final double alfa;
  final double radius;
  final BlendMode blend;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _LysMaler(lys, alfa, radius, blend));
}

class _LysMaler extends CustomPainter {
  _LysMaler(this.lys, this.alfa, this.radius, this.blend);

  final Offset lys;
  final double alfa;
  final double radius;
  final BlendMode blend;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(lys.dx * size.width, lys.dy * size.height);
    // CSS `circle` farthest-corner: the radius reaches the far corner.
    final r = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((k) => (k - c).distance).reduce(math.max);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = blend
        ..shader = ui.Gradient.radial(c, r, [
          Color.fromRGBO(255, 255, 255, alfa),
          const Color.fromRGBO(255, 255, 255, 0),
        ], [0, radius]),
    );
  }

  @override
  bool shouldRepaint(_LysMaler old) => old.lys != lys;
}

/// `border-top: 1px dashed rgba(60,40,20,.16)`.
class _Stiplet extends StatelessWidget {
  const _Stiplet();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _StipletMaler()));
}

class _StipletMaler extends CustomPainter {
  const _StipletMaler();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color.fromRGBO(60, 40, 20, .16)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset(math.min(x + 3, size.width), .5), p);
    }
  }

  @override
  bool shouldRepaint(_StipletMaler old) => false;
}

/// The coin pill (`+30`): `bm3Mynt 3.4s cubic-bezier(.5,0,.3,1)` — a full
/// turn in 55% of the cycle, then rest.
class KatMyntPille extends StatelessWidget {
  const KatMyntPille({
    super.key,
    required this.tekst,
    required this.hoyde,
    required this.mynt,
    required this.fontPx,
    required this.faseMs,
    this.skygge = false,
  });

  /// The hero's darker drop (`0 12px 18px -8px rgba(30,10,0,.7)`).
  final bool skygge;

  final String tekst;
  final double hoyde;
  final double mynt;
  final double fontPx;
  final double faseMs;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final stor = hoyde >= 30;
    return Container(
      height: hoyde * s,
      padding: EdgeInsets.fromLTRB((stor ? 8 : 6) * s, 0, (stor ? 11 : 9) * s, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D6), Color(0xFFFFDE90)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9A93A),
            offset: Offset(0, (stor ? 3 : 2) * s),
          ),
          if (skygge)
            BoxShadow(
              color: rgba(30, 10, 0, .7),
              offset: Offset(0, 12 * s),
              blurRadius: onbBlur(18 * s),
              spreadRadius: -8 * s,
            )
          else
            BoxShadow(
              color: rgba(120, 70, 10, .5),
              offset: Offset(0, (stor ? 8 : 6) * s),
              blurRadius: onbBlur((stor ? 12 : 10) * s),
              spreadRadius: -6 * s,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          bergenInsetTop(
            radius: 999,
            height: 1 * s,
            alpha: .85,
            pad: EdgeInsets.fromLTRB((stor ? 8 : 6) * s, 0, (stor ? 11 : 9) * s, 0),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(child: _Mynt(size: mynt * s, faseMs: faseMs)),
              SizedBox(width: (stor ? 6 : 5) * s),
              Text(
                tekst,
                style: bText(
                  context,
                  fontPx,
                  weight: FontWeight.w800,
                  color: const Color(0xFF4A2C05),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mynt extends StatelessWidget {
  const _Mynt({required this.size, required this.faseMs});

  final double size;
  final double faseMs;

  static const Curve _c = Cubic(.5, 0, .3, 1);

  @override
  Widget build(BuildContext context) => KatLoop(
    durationMs: 3400,
    phaseMs: faseMs,
    builder: (context, p, _) {
      final grad = kf(p, const [0, .55, 1], const [0, 360, 360], _c);
      final bak = math.cos(grad * math.pi / 180) < 0;
      return Transform(
        alignment: Alignment.center,
        transform: katPerspektiv(240)..rotateY(grad * math.pi / 180),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: bak ? const Alignment(.2, -.3) : const Alignment(-.3, -.4),
              colors: bak
                  ? const [Color(0xFFFCE7A0), Color(0xFFD9A12C), Color(0xFF9A640C)]
                  : const [Color(0xFFFFF6CF), Color(0xFFF2C14E), Color(0xFFB87A12)],
              stops: bak ? const [0, .55, 1] : const [0, .52, 1],
            ),
            border: bak
                ? null
                : Border.all(color: rgba(150, 95, 20, .55), width: size * .09),
          ),
        ),
      );
    },
  );
}

/// The orange round key (`linear-gradient(180deg,#F9A273,#F26D3D 56%,
/// #DD5A25)`, white hairline, a 3px #C4491A drop).
class KatRundKnapp extends StatelessWidget {
  const KatRundKnapp({
    super.key,
    required this.size,
    required this.ikon,
    required this.ikonPx,
    required this.strek,
    required this.onTap,
  });

  final double size;
  final String ikon;
  final double ikonPx;
  final double strek;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return _Trykk(
      onTap: onTap,
      builder: (ned) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size * s,
        height: size * s,
        transform: Matrix4.translationValues(0, ned ? 3 * s : 0, 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _kKnapp,
            stops: [0, .56, 1],
          ),
          boxShadow: [
            BoxShadow(color: rgba(255, 255, 255, .45), spreadRadius: 1),
            if (!ned) ...[
              BoxShadow(color: const Color(0xFFC4491A), offset: Offset(0, 3 * s)),
              BoxShadow(color: rgba(120, 45, 15, .22), offset: Offset(0, 5 * s)),
              BoxShadow(
                color: rgba(200, 70, 25, .8),
                offset: Offset(0, (size > 45 ? 14 : 12) * s),
                blurRadius: onbBlur((size > 45 ? 18 : 16) * s),
                spreadRadius: (size > 45 ? -10 : -9) * s,
              ),
            ] else
              BoxShadow(
                color: rgba(200, 70, 25, .6),
                offset: Offset(0, 4 * s),
                blurRadius: onbBlur(8 * s),
                spreadRadius: -4 * s,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            bergenInsetTop(radius: 999, height: 1.5 * s, alpha: ned ? .35 : .4),
            SokIkon(ikon, size: ikonPx * s, color: Colors.white, stroke: strek),
          ],
        ),
      ),
    );
  }
}

/// A tap target that reports whether it is held (`style-active`).
class _Trykk extends StatefulWidget {
  const _Trykk({required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool ned) builder;

  @override
  State<_Trykk> createState() => _TrykkState();
}

class _TrykkState extends State<_Trykk> {
  bool _ned = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onTapDown: (_) => setState(() => _ned = true),
    onTapUp: (_) => setState(() => _ned = false),
    onTapCancel: () => setState(() => _ned = false),
    child: widget.builder(_ned),
  );
}

/// `bmPuls 1.8s ease-out infinite` — the "1 nå" dot.
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return RepaintBoundary(
      child: KatLoop(
        durationMs: 1800,
        builder: (context, p, _) {
          final e = Curves.easeOut.transform(p);
          final r = kf(e, const [0, .7, 1], const [0, 7, 0], Curves.linear);
          final a = kf(e, const [0, .7, 1], const [.55, 0, 0], Curves.linear);
          return Container(
            width: 6 * s,
            height: 6 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE95C2C),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(233, 92, 44, a),
                  spreadRadius: r * s,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _bilde(String? url, BoxFit fit, {Alignment align = Alignment.center}) {
  if (url == null || url.isEmpty) return const SizedBox.shrink();
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    alignment: align,
    fadeInDuration: const Duration(milliseconds: 200),
    errorWidget: (_, _, _) => const SizedBox.shrink(),
  );
}

/// `kortStag <dur> <delay> cubic-bezier(.2,.9,.3,1) both`.
class KatKortStag extends StatelessWidget {
  const KatKortStag({
    super.key,
    required this.durationMs,
    required this.delayMs,
    required this.child,
  });

  final double durationMs;
  final double delayMs;
  final Widget child;

  static const Curve _c = Cubic(.2, .9, .3, 1);

  @override
  Widget build(BuildContext context) => BergenOnce(
    durationMs: durationMs,
    delayMs: delayMs,
    child: child,
    builder: (context, p, child) {
      final e = _c.transform(p);
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * context.bs * (1 - e)),
          child: Transform.scale(scale: .97 + .03 * e, child: child),
        ),
      );
    },
  );
}

// ── Store card ──────────────────────────────────────────────────────────────

class KatButikkKort extends StatelessWidget {
  const KatButikkKort({super.key, required this.b, required this.onTap});

  final KatButikkVis b;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final farge = kKatFarge[b.nr % 4];
    final dyp = kKatDyp[b.nr % 4];
    return KatSvevKort(
      key: ValueKey('kat-b-${b.id}'),
      perspektiv: 1000,
      svevMs: 10000,
      faseMs: b.nr * 2700,
      tiltK: 14,
      trykk: .975,
      onTap: onTap,
      builder: (context, lys) => Stack(
        clipBehavior: Clip.none,
        children: [
          // The card's coloured glow, far behind it.
          Positioned(
            left: -10 * s,
            right: -10 * s,
            top: 40 * s,
            bottom: -34 * s,
            child: katZ(
              -60 * s,
              IgnorePointer(
                child: Opacity(
                  opacity: .5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [farge, farge.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF5), Color(0xFFF7EEE2)],
              ),
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .55), spreadRadius: 1),
                BoxShadow(color: rgba(4, 18, 26, .25), offset: Offset(0, 3 * s)),
                BoxShadow(
                  color: rgba(4, 18, 26, .85),
                  offset: Offset(0, 30 * s),
                  blurRadius: onbBlur(40 * s),
                  spreadRadius: -22 * s,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30 * s),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 222 * s,
                    bottom: 0,
                    child: const IgnorePointer(
                      child: KatHolo(farger: kKatHoloLys, stopp: kKatHoloLysStopp),
                    ),
                  ),
                  bergenInsetTop(radius: 30 * s, height: 1.5 * s, alpha: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 14 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Foto(url: b.bannerUrl, dyp: dyp, lys: lys),
                        _NavnRad(b: b, onTap: onTap),
                        SizedBox(height: 13 * s),
                        const _Stiplet(),
                        _BunnRad(b: b),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Lys(
                        lys: lys,
                        alfa: .4,
                        radius: .42,
                        blend: BlendMode.softLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The logo stands out of the card (`translateZ(50px)`).
          Positioned(
            left: 18 * s,
            top: 192 * s,
            child: katZ(50 * s, _Logo(url: b.logoUrl)),
          ),
          Positioned(
            left: 18 * s,
            right: 18 * s,
            top: 18 * s,
            child: katZ(
              46 * s,
              Row(
                children: [
                  if (b.tag != null)
                    Transform.rotate(
                      angle: -4 * math.pi / 180,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11 * s,
                          vertical: 6 * s,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2C14E),
                          borderRadius: BorderRadius.circular(8 * s),
                          boxShadow: [
                            BoxShadow(color: Colors.white, spreadRadius: 2 * s),
                            BoxShadow(
                              color: rgba(0, 0, 0, .45),
                              offset: Offset(0, 8 * s),
                              blurRadius: onbBlur(14 * s),
                              spreadRadius: -4 * s,
                            ),
                          ],
                        ),
                        child: Text(
                          b.tag!,
                          style: bText(
                            context,
                            10,
                            weight: FontWeight.w800,
                            letterSpacingEm: .08,
                            color: _kInk,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (b.id > 0)
                    BergenFavHeart(storeId: b.id, size: 40 * s, iconSize: 17 * s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({required this.url, required this.dyp, required this.lys});

  final String? url;
  final Color dyp;
  final Offset lys;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(23 * s);
    return SizedBox(
      height: 214 * s,
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: dyp),
            _bilde(url, BoxFit.cover, align: const Alignment(-.3, -.2)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(20, 10, 4, .3),
                    Color.fromRGBO(20, 10, 4, 0),
                    Color.fromRGBO(20, 10, 4, 0),
                    Color.fromRGBO(20, 10, 4, .22),
                  ],
                  stops: [0, .3, .75, 1],
                ),
              ),
            ),
            const IgnorePointer(
              child: KatHolo(
                farger: kKatHoloSterk,
                stopp: kKatHoloSterkStopp,
                dodge: .34,
              ),
            ),
            IgnorePointer(
              child: _Lys(
                lys: lys,
                alfa: .55,
                radius: .45,
                blend: BlendMode.overlay,
              ),
            ),
            // `inset 0 0 0 1px rgba(0,0,0,.1), inset 0 2px 6px rgba(0,0,0,.22)`.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  border: Border.all(color: rgba(0, 0, 0, .1)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(0, 0, 0, .18), rgba(0, 0, 0, 0)],
                    stops: const [0, 6 / 214],
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

class _Logo extends StatelessWidget {
  const _Logo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      width: 58 * s,
      height: 58 * s,
      padding: EdgeInsets.all(6 * s),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFFBF5), spreadRadius: 4 * s),
          BoxShadow(
            color: rgba(4, 18, 26, .55),
            offset: Offset(0, 16 * s),
            blurRadius: onbBlur(22 * s),
            spreadRadius: -8 * s,
          ),
        ],
      ),
      child: ClipOval(child: _bilde(url, BoxFit.contain)),
    );
  }
}

class _NavnRad extends StatelessWidget {
  const _NavnRad({required this.b, required this.onTap});

  final KatButikkVis b;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 60 * s),
      child: Padding(
        padding: EdgeInsets.fromLTRB(76 * s, 10 * s, 4 * s, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.navn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bDisplay(
                      context,
                      20,
                      letterSpacingEm: -.03,
                      height: 1.1,
                      color: _kInk,
                    ),
                  ),
                  if (b.sub.isNotEmpty) ...[
                    SizedBox(height: 2 * s),
                    Text(
                      b.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bText(
                        context,
                        12.5,
                        weight: FontWeight.w500,
                        color: _kGra,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10 * s),
            KatRundKnapp(
              size: 50,
              ikon: 'M5 12h13M13 6l6 6-6 6',
              ikonPx: 20,
              strek: 2.8,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _BunnRad extends StatelessWidget {
  const _BunnRad({required this.b});

  final KatButikkVis b;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final txt = bText(context, 12, weight: FontWeight.w700, color: const Color(0xFF3F3A33));
    Widget prikk() => Container(
      width: 3 * s,
      height: 3 * s,
      margin: EdgeInsets.symmetric(horizontal: 7 * s),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB5AC9F),
      ),
    );
    final deler = <Widget>[
      if (b.eta != null) Text(b.eta!, style: txt),
      if (b.midt != null)
        Text(
          b.midt!,
          style: txt.copyWith(
            color: b.midtGratis ? const Color(0xFFC2410C) : _kGra,
          ),
        ),
      if (b.live != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LiveDot(),
            SizedBox(width: 5 * s),
            Text(
              '${b.live} nå',
              style: txt.copyWith(fontWeight: FontWeight.w600, color: _kGra),
            ),
          ],
        ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(6 * s, 11 * s, 6 * s, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < deler.length; i++) ...[
                      if (i > 0) prikk(),
                      deler[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (b.poeng != null) ...[
            SizedBox(width: 8 * s),
            KatMyntPille(
              tekst: '+${b.poeng}',
              hoyde: 32,
              mynt: 17,
              fontPx: 12.5,
              faseMs: b.nr * 2700,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Product card ────────────────────────────────────────────────────────────

class KatProduktKort extends StatelessWidget {
  const KatProduktKort({
    super.key,
    required this.p,
    required this.onTap,
    required this.onLeggTil,
  });

  final KatProduktVis p;
  final VoidCallback onTap;
  final VoidCallback onLeggTil;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final farge = kKatFarge[p.fargeNr % 4];
    final dyp = kKatDyp[p.fargeNr % 4];
    final fase = p.nr * 2300.0;
    return KatSvevKort(
      key: ValueKey('kat-p-${p.id}'),
      perspektiv: 800,
      svevMs: 9000,
      faseMs: fase,
      tiltK: 16,
      trykk: .97,
      onTap: onTap,
      builder: (context, lys) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -14 * s,
            right: -14 * s,
            top: 40 * s,
            bottom: -26 * s,
            child: katZ(
              -40 * s,
              IgnorePointer(
                child: Opacity(
                  opacity: .45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [farge, farge.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * s),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFBF5), Color(0xFFF7EEE2)],
              ),
              boxShadow: [
                BoxShadow(color: rgba(255, 255, 255, .55), spreadRadius: 1),
                BoxShadow(color: rgba(4, 18, 26, .25), offset: Offset(0, 3 * s)),
                BoxShadow(
                  color: rgba(4, 18, 26, .85),
                  offset: Offset(0, 26 * s),
                  blurRadius: onbBlur(34 * s),
                  spreadRadius: -20 * s,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26 * s),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: KatHolo(farger: kKatHoloLys, stopp: kKatHoloLysStopp),
                    ),
                  ),
                  bergenInsetTop(radius: 26 * s, height: 1.5 * s, alpha: 1),
                  Positioned(
                    left: 7 * s,
                    right: 7 * s,
                    top: 7 * s,
                    height: 104 * s,
                    child: _Bronn(farge: farge, dyp: dyp, lys: lys, faseMs: fase),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(11 * s, 120 * s, 11 * s, 11 * s),
                    child: _ProduktInfo(p: p, onLeggTil: onLeggTil),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Lys(
                        lys: lys,
                        alfa: .4,
                        radius: .42,
                        blend: BlendMode.softLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The product floats out of the card (`translateZ(60px)`, `bm3Flyt`).
          if ((p.bildeUrl ?? '').isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: -34 * s,
              height: 110 * s,
              child: katZ(
                60 * s,
                Center(
                  child: KatLoop(
                    durationMs: 4000,
                    phaseMs: fase,
                    child: _FlytBilde(url: p.bildeUrl!),
                    builder: (context, t, child) {
                      final y = kf(t, const [0, .5, 1], const [0, -12, 0], Curves.easeInOut);
                      final r = kf(t, const [0, .5, 1], const [-2, 1.5, -2], Curves.easeInOut);
                      return Transform.translate(
                        offset: Offset(0, y * s),
                        child: Transform.rotate(
                          angle: r * math.pi / 180,
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (p.tag != null)
            Positioned(
              left: -6 * s,
              top: -12 * s,
              child: katZ(
                80 * s,
                Transform.rotate(
                  angle: -5 * math.pi / 180,
                  child: _ProduktTag(tag: p.tag!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A real product photo as a rounded print lifting out of the card (the
/// design's cut-out PNGs have no backdrop; shop photos do).
class _FlytBilde extends StatelessWidget {
  const _FlytBilde({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Container(
      width: 136 * s,
      height: 96 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: rgba(30, 8, 0, .45),
            offset: Offset(0, 14 * s),
            blurRadius: onbBlur(18 * s),
            spreadRadius: -8 * s,
          ),
        ],
      ),
      padding: EdgeInsets.all(3 * s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15 * s),
        child: _bilde(url, BoxFit.cover),
      ),
    );
  }
}

class _ProduktTag extends StatelessWidget {
  const _ProduktTag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final tilbud = tag == 'Tilbud', ny = tag == 'Ny';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * s),
        color: tilbud ? null : (ny ? Colors.white : const Color(0xFFF2C14E)),
        gradient: tilbud
            ? cssLinear(160, const [Color(0xFFF2884E), Color(0xFFE0662C)])
            : null,
        boxShadow: [
          BoxShadow(color: Colors.white, spreadRadius: 2 * s),
          BoxShadow(
            color: rgba(0, 0, 0, .5),
            offset: Offset(0, 8 * s),
            blurRadius: onbBlur(14 * s),
            spreadRadius: -4 * s,
          ),
        ],
      ),
      child: Text(
        tag,
        style: bText(
          context,
          10.5,
          weight: FontWeight.w800,
          letterSpacingEm: .02,
          color: tilbud ? Colors.white : (ny ? const Color(0xFFB8380F) : _kInk),
        ),
      ),
    );
  }
}

/// The product's well: `radial-gradient(90% 100% at 50% 100%, farge, dyp
/// 80%)`, the strong holo, the light and the plate shadow (`bm3Skygge`).
class _Bronn extends StatelessWidget {
  const _Bronn({
    required this.farge,
    required this.dyp,
    required this.lys,
    required this.faseMs,
  });

  final Color farge;
  final Color dyp;
  final Offset lys;
  final double faseMs;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    final r = BorderRadius.circular(20 * s);
    return ClipRRect(
      borderRadius: r,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, c) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1,
                  colors: [farge, dyp],
                  stops: const [0, .8],
                  transform: const _Ellipse(.9, 1),
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: KatHolo(farger: kKatHoloSterk, stopp: kKatHoloSterkStopp, dodge: .38),
          ),
          IgnorePointer(
            child: _Lys(lys: lys, alfa: .5, radius: .5, blend: BlendMode.overlay),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 84 * s,
            height: 16 * s,
            child: Center(
              child: KatLoop(
                durationMs: 4000,
                phaseMs: faseMs,
                child: Container(
                  width: 110 * s,
                  height: 16 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(55 * s, 8 * s)),
                    gradient: RadialGradient(
                      colors: [rgba(30, 8, 0, .55), rgba(0, 0, 0, 0)],
                    ),
                  ),
                ),
                builder: (context, t, child) {
                  final sc = kf(t, const [0, .5, 1], const [1, .8, 1], Curves.easeInOut);
                  final o = kf(t, const [0, .5, 1], const [1, .65, 1], Curves.easeInOut);
                  return Opacity(
                    opacity: o,
                    child: Transform.scale(scale: sc, child: child),
                  );
                },
              ),
            ),
          ),
          // `inset 0 0 0 1px rgba(0,0,0,.08), inset 0 -10px 18px -10px
          // rgba(0,0,0,.35)`.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: rgba(0, 0, 0, .08)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [rgba(0, 0, 0, .2), rgba(0, 0, 0, 0)],
                  stops: const [0, .12],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `radial-gradient(<rx>% <ry>% at …)` on a box.
class _Ellipse extends GradientTransform {
  const _Ellipse(this.rx, this.ry);

  final double rx;
  final double ry;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final short = math.min(bounds.width, bounds.height) / 2;
    final c = bounds.bottomCenter;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(rx * bounds.width / short, ry * bounds.height / short, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

class _ProduktInfo extends StatelessWidget {
  const _ProduktInfo({required this.p, required this.onLeggTil});

  final KatProduktVis p;
  final VoidCallback onLeggTil;

  @override
  Widget build(BuildContext context) {
    final s = context.bs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: 37 * s),
          child: Text(
            p.navn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bDisplay(
              context,
              15.5,
              letterSpacingEm: -.02,
              height: 1.2,
              color: _kInk,
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        Row(
          children: [
            Container(
              width: 20 * s,
              height: 20 * s,
              padding: EdgeInsets.all(2.5 * s),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: rgba(60, 40, 20, .12), spreadRadius: 1.5),
                  BoxShadow(
                    color: rgba(0, 0, 0, .45),
                    offset: Offset(0, 3 * s),
                    blurRadius: onbBlur(6 * s),
                    spreadRadius: -2 * s,
                  ),
                ],
              ),
              child: ClipOval(child: _bilde(p.logoUrl, BoxFit.contain)),
            ),
            SizedBox(width: 6 * s),
            Expanded(
              child: Text(
                p.butikk,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bText(
                  context,
                  11.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF57534B),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * s),
        Row(
          children: [
            if (p.eta != null) ...[
              SokIkon(
                '${SokIkon.sirkel(12, 12, 8.5)}M12 7.5V12l3 2',
                size: 12 * s,
                color: _kGra,
                stroke: 2.4,
              ),
              SizedBox(width: 4 * s),
              Flexible(
                child: Text(
                  p.eta!,
                  maxLines: 1,
                  style: bText(context, 11.5, weight: FontWeight.w700, color: _kGra),
                ),
              ),
            ],
            const Spacer(),
            if (p.kroner != null)
              KatMyntPille(
                tekst: '+${p.kroner}',
                hoyde: 24,
                mynt: 14,
                fontPx: 11.5,
                faseMs: p.nr * 2300,
              ),
          ],
        ),
        SizedBox(height: 10 * s),
        const _Stiplet(),
        SizedBox(height: 10 * s),
        Row(
          children: [
            Expanded(
              child: Text(
                p.pris,
                maxLines: 1,
                style: bDisplay(context, 19, letterSpacingEm: -.03, color: _kInk)
                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            KatRundKnapp(
              size: 42,
              ikon: 'M12 5v14M5 12h14',
              ikonPx: 18,
              strek: 3,
              onTap: onLeggTil,
            ),
          ],
        ),
      ],
    );
  }
}
