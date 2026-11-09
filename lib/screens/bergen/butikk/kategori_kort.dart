import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart';
import '../kit/bergen_css.dart';
import '../kit/bergen_lagring.dart' show BergenLagringLive;
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
    this.besk,
    this.ikon,
  });

  final int id;
  final int storeId;
  final String navn;
  final String butikk;
  final String pris;
  final int nr;

  /// Onboarding Step 6: the description (hero, clamped to 3 lines) and the
  /// 3D icon when there is no photo (`assets/images/kategori/<ikon>.svg`).
  final String? besk;
  final String? ikon;

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
  Widget build(BuildContext context) {
    final loop = KatLoop(
      durationMs: halvMs * 2,
      builder: (context, p, _) {
        final raw = p * 2;
        final e = Curves.easeInOut.transform(raw <= 1 ? raw : 2 - raw);
        return CustomPaint(painter: _HoloMaler(farger, stopp, e, dodge));
      },
    );
    // Heat plan Step 8: the colour dodge blends with the screen beneath it.
    return dodge > 0 ? BergenLagringLive(child: loop) : loop;
  }
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

/// The Ærend-kroner pill with the spinning coin (`bmMynt`).
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

// ── Store card: Onboarding Step 5 moved it to `kategori_modul.dart` (the module). ──

// ── Product card: Onboarding Step 6 moved it to `kategori_produkt.dart` (hero + small cards). ──
