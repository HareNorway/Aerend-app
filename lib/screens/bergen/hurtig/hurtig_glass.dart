import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/bergen_perf.dart';
import 'hurtig_bits.dart';
import 'hurtig_data.dart';

// ── Hurtig · the dark glass of new Bergen (L4264–4545) ─────────────────────
// Every Hurtig card turned from white to glass on the teal: a white .14 → .05
// fill, a 1px white .16 border, a light top edge and a deep drop shadow.

const Color kHbMintLys = Color(0xFF7FF0CB);
const Color kHbFersken = Color(0xFFFFB48E);
const Color kHbKant = Color(0xFF1F5463);

const List<CssBg> kHbGlassBg = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, .05)]),
];

/// `inset 0 1px 0 rgba(255,255,255,.14), 0 18px 30px -20px rgba(0,10,16,.9)`.
const List<CssShadow> kHbGlassSkygge = [CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .14)), CssShadow(0, 18, 30, -20, Color.fromRGBO(0, 10, 16, .9))];

/// The orange 3D key of the dark cards: `#F9A273 → #F26D3D 56% → #DD5A25`.
const List<CssBg> kHbOransjeBg = [
  CssLinear(180, [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)], [0, .56, 1]),
];

List<CssShadow> hbOransjeSkygge({double dyp = 12, double blur = 20}) => [
  const CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
  const CssShadow(0, 3, 0, 0, Color.fromRGBO(160, 60, 20, .6)),
  CssShadow(0, dyp, blur, -10, const Color.fromRGBO(242, 109, 61, .8)),
];

/// One glass card. The CSS border sits inside the box, so the padding is
/// the design's plus 1px.
class HbGlass extends StatelessWidget {
  const HbGlass({super.key, required this.child, this.radius = 22, this.padding = EdgeInsets.zero, this.kant = const Color.fromRGBO(255, 255, 255, .16), this.bg = kHbGlassBg, this.clip = false});

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color kant;
  final List<CssBg> bg;
  final bool clip;

  @override
  Widget build(BuildContext context) => CssBox(
    radius: BorderRadius.circular(radius),
    bg: bg,
    border: Border.all(color: kant),
    shadows: kHbGlassSkygge,
    clip: clip,
    padding: padding + const EdgeInsets.all(1),
    child: child,
  );
}

/// The kicker over a dark card: «OFTEST BESTILT ─── 8 bestillinger …».
class HbSeksjon extends StatelessWidget {
  const HbSeksjon(this.tittel, {super.key, this.under = ''});

  final String tittel;
  final String under;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
    child: Row(
      children: [
        Text(
          tittel,
          style: hbI(11, weight: FontWeight.w800, em: .12, color: kHbMintLys),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            constraints: const BoxConstraints(minWidth: 12),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color.fromRGBO(127, 240, 203, .4), Color.fromRGBO(127, 240, 203, 0)])),
          ),
        ),
        if (under.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            under,
            style: hbI(11.5, weight: FontWeight.w700, color: const Color.fromRGBO(255, 255, 255, .7)),
          ),
        ],
      ],
    ),
  );
}

/// `hbLg(navn).katIkon`: the stand-in icon for a store without a logo.
String hbKatIkon(String navn) {
  final n = navn.toLowerCase();
  if (RegExp('kaffe').hasMatch(n)) return 'M5 8h11v6a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5z M16 10h2a2 2 0 0 1 0 4h-2 M8 3v2 M11 3v2';
  if (RegExp('wok|thai').hasMatch(n)) return 'M4 11h16a8 8 0 0 1-16 0z M9 7l6-4 M12 7l6-3';
  if (RegExp('pizza|maria').hasMatch(n)) return 'M12 3 21 20H3z M10 12v.01 M14 15v.01';
  return 'M3 13h18a9 9 0 0 1-18 0z M12 4v3';
}

/// `pr.smak[].ik`: the icon of a taste («Fisk», «Thai», «Pizza» …).
String hbSmakIkon(String t) {
  final s = t.toLowerCase();
  if (RegExp('fisk|sjømat|laks').hasMatch(s)) return 'M3 12c3-4 8-5 12-3l4-3v12l-4-3c-4 2-9 1-12-3z M15.5 11v.01';
  if (RegExp('thai|wok|asia|nudl').hasMatch(s)) return 'M4 11h16a8 8 0 0 1-16 0z M9 7l6-4 M12 7l6-3';
  if (RegExp('pizza|ital').hasMatch(s)) return 'M12 3 21 20H3z M10 12v.01 M14 15v.01';
  if (RegExp('sushi').hasMatch(s)) return 'M4 12a8 4 0 0 0 16 0a8 4 0 0 0-16 0z M4 12v3a8 4 0 0 0 16 0v-3 M10 12h4';
  if (RegExp('burger').hasMatch(s)) return 'M4 11a8 6 0 0 1 16 0z M4 15h16 M5 18h14l-1 2H6z';
  if (RegExp('kaffe').hasMatch(s)) return 'M5 8h11v6a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5z M16 10h2a2 2 0 0 1 0 4h-2 M8 3v2 M11 3v2';
  if (RegExp('bakst|bakeri|brød|bolle').hasMatch(s)) return 'M4 14c0-4 3.6-7 8-7s8 3 8 7v3H4z M8 10l1 4 M12 9v5 M16 10l-1 4';
  if (RegExp('veg|grønt|salat').hasMatch(s)) return 'M5 19c0-8 6-14 15-14 0 9-6 15-14 15z M5 19l7-7';
  return 'M3 13h18a9 9 0 0 1-18 0z M12 4v3';
}

/// The store's logo tile (`l_torgboden … l_x`): the real logo, or the
/// design's own stand-in (the store colour with a category icon).
class HbLogo extends StatelessWidget {
  const HbLogo({super.key, required this.b, required this.size, required this.radius, this.ikon, this.kant = 0, this.skygge = const []});

  final HbButikk b;
  final double size;
  final double radius;

  /// The stand-in icon's size (the design's 24/22/23/19 px per tile size).
  final double? ikon;

  /// `border: 3px solid #1F5463` (the tiles that overlap a header).
  final double kant;
  final List<CssShadow> skygge;

  @override
  Widget build(BuildContext context) {
    final url = b.logo;
    final indre = size - 2 * kant;
    final Widget stand = ColoredBox(
      color: b.bg,
      child: Center(
        child: HbIkon(hbKatIkon(b.navn), size: ikon ?? indre * .48, stroke: Colors.white, width: 2),
      ),
    );
    return CssBox(
      width: size,
      height: size,
      radius: BorderRadius.circular(radius),
      bg: kant > 0 ? const [CssSolid(kHbKant)] : const [],
      shadows: skygge,
      child: Padding(
        padding: EdgeInsets.all(kant),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(math.max(0, radius - kant)),
          child: SizedBox.square(
            dimension: indre,
            child: url == null || url.isEmpty
                ? stand
                : ColoredBox(
                    color: Colors.white,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      memCacheWidth: BergenPerf.decodeWidth,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      errorWidget: (_, _, _) => stand,
                      placeholder: (_, _) => stand,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The header band of a store card (`m.topp.tint`): the store colour into
/// deep teal at 135°, 9px stripes, a light from the top right and a scrim.
class HbTint extends StatelessWidget {
  const HbTint({super.key, required this.farge, required this.height, this.child});

  final Color farge;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(
      painter: _TintPainter(farge),
      child: child == null ? null : SizedBox.expand(child: child),
    ),
  );
}

class _TintPainter extends CustomPainter {
  const _TintPainter(this.farge);
  final Color farge;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    // linear-gradient(135deg, tile, #173E48 95%)
    canvas.drawRect(r, Paint()..shader = CssLinear(135, [farge, const Color(0xFF173E48)], const [0, .95]).shader(r));
    // repeating-linear-gradient(135deg, white .06 0 9px, transparent 9px 18px)
    const k = 18 / math.sqrt2;
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(k, k),
          const [Color.fromRGBO(255, 255, 255, .06), Color.fromRGBO(255, 255, 255, .06), Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(255, 255, 255, 0)],
          const [0, .5, .5, 1],
          TileMode.repeated,
        ),
    );
    // radial-gradient(70% 120% at 85% 0%, white .22, transparent 60%)
    canvas.drawRect(r, Paint()..shader = const CssRadial([Color.fromRGBO(255, 255, 255, .22), Color.fromRGBO(255, 255, 255, 0)], stops: [0, .6], rx: .7, ry: 1.2, cx: .85, cy: 0).shader(r));
    // linear-gradient(180deg, rgba(10,26,34,0), rgba(10,26,34,.45))
    canvas.drawRect(r, Paint()..shader = const CssLinear(180, [Color.fromRGBO(10, 26, 34, 0), Color.fromRGBO(10, 26, 34, .45)]).shader(r));
  }

  @override
  bool shouldRepaint(_TintPainter o) => o.farge != farge;
}

/// A small chip on a header band (`height:24px; border-radius:999px`).
class HbBandChip extends StatelessWidget {
  const HbBandChip({super.key, required this.child, this.bg = const [CssSolid(Color.fromRGBO(10, 26, 34, .5))], this.kant = const Color.fromRGBO(255, 255, 255, .2), this.h = 24, this.pad = 9});

  final Widget child;
  final List<CssBg> bg;
  final Color kant;
  final double h;
  final double pad;

  @override
  Widget build(BuildContext context) => CssBox(
    height: h,
    radius: BorderRadius.circular(999),
    bg: bg,
    border: Border.all(color: kant),
    padding: EdgeInsets.symmetric(horizontal: pad + 1),
    child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
  );
}

/// `bpFlisInn .5s <delay> cubic-bezier(.2,.9,.3,1) both`: up 16px from .92.
class HbFlisInn extends StatelessWidget {
  const HbFlisInn({super.key, required this.child, this.delayMs = 0, this.ms = 500});

  final Widget child;
  final double delayMs;
  final double ms;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms + delayMs,
    child: child,
    builder: (context, t, child) {
      final e = const Cubic(.2, .9, .3, 1).transform(kfP(t, delayMs, ms));
      return Opacity(
        opacity: e.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(0, 16 * (1 - e), 0)..scaleByDouble(.92 + .08 * e, .92 + .08 * e, 1, 1), child: child),
      );
    },
  );
}

/// `bioPopA <ms> <delay> cubic-bezier(.2,1.3,.3,1) both`: .6 → 1.08 → 1.
class HbPop extends StatelessWidget {
  const HbPop({super.key, required this.child, this.delayMs = 0, this.ms = 400});

  final Widget child;
  final double delayMs;
  final double ms;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms + delayMs,
    child: child,
    builder: (context, t, child) {
      final p = kfP(t, delayMs, ms);
      const c = Cubic(.2, 1.3, .3, 1);
      final s = kf(p, const [0, .6, 1], const [.6, 1.08, 1], c);
      final o = kf(p, const [0, .6, 1], const [0, 1, 1], c);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.scale(scale: s, child: child),
      );
    },
  );
}

/// The 26px icon tile of a dark card's head (mint, or peach for allergies).
class HbHodeIkon extends StatelessWidget {
  const HbHodeIkon(this.d, {super.key, this.fersken = false});

  final String d;
  final bool fersken;

  @override
  Widget build(BuildContext context) => CssBox(
    width: 26,
    height: 26,
    radius: BorderRadius.circular(9),
    bg: [CssSolid(fersken ? const Color.fromRGBO(242, 109, 61, .18) : const Color.fromRGBO(92, 224, 184, .14))],
    border: Border.all(color: fersken ? const Color.fromRGBO(255, 148, 102, .35) : const Color.fromRGBO(127, 240, 203, .25)),
    child: Center(child: HbIkon(d, size: 13, stroke: fersken ? kHbFersken : kHbMintLys, width: 2.3)),
  );
}

/// Ægil's face in a circle (`assets/aegil-s/front.png`, left −30 %, top
/// [topp], 160 %).
class HbAegilFjes extends StatelessWidget {
  const HbAegilFjes({super.key, required this.size, this.topp = -.08});

  final double size;
  final double topp;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment(-.5, -1), end: Alignment(.5, 1), colors: [Color(0xFF4A93A4), Color(0xFF1E4F5C)]),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -size * .3,
              top: size * topp,
              width: size * 1.6,
              height: size * 1.6,
              child: Image.asset('assets/images/dashboard/front.png', fit: BoxFit.cover, alignment: Alignment.topCenter, filterQuality: FilterQuality.medium),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `bioSkannRing 7s linear infinite`: a mint arc (0 → .95 at 22 % → 0 at
/// 45 %) turning around the portrait.
class HbSkannRing extends StatelessWidget {
  const HbSkannRing({super.key, this.ms = 7000});

  final double ms;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(builder: (context, t, _) => CustomPaint(painter: _RingPainter(((t / ms) % 1) * 2 * math.pi))),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.a);
  final double a;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawOval(
      r,
      Paint()
        ..shader = SweepGradient(
          colors: const [Color.fromRGBO(127, 240, 203, 0), Color.fromRGBO(127, 240, 203, .95), Color.fromRGBO(127, 240, 203, 0), Color.fromRGBO(127, 240, 203, 0)],
          stops: const [0, .22, .45, 1],
          transform: GradientRotation(a - math.pi / 2),
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.a != a;
}

/// `bioDot 2.4s`: the breathing online dot.
class HbPusteDot extends StatelessWidget {
  const HbPusteDot({super.key, required this.child, this.ms = 2400});

  final Widget child;
  final double ms;

  @override
  Widget build(BuildContext context) => LfLoop(
    frozenMs: -1,
    child: child,
    builder: (context, t, child) {
      if (t < 0) return child!;
      final p = kfLoop(t, 0, ms) ?? 0;
      final o = kf(p, const [0, .5, 1], const [.5, 1, .5], cssEaseInOut);
      final s = kf(p, const [0, .5, 1], const [.85, 1.15, .85], cssEaseInOut);
      return Opacity(
        opacity: o,
        child: Transform.scale(scale: s, child: child),
      );
    },
  );
}

/// `bioTenn 7s <delay> ease-in-out infinite`: the taste tile's border lights
/// up (.3 → .9 mint) with a 14px glow at 4 %, out again by 9 %.
class HbTenn extends StatelessWidget {
  const HbTenn({super.key, required this.delayMs, required this.builder});

  final double delayMs;
  final Widget Function(double lys) builder;

  @override
  Widget build(BuildContext context) => LfLoop(
    builder: (context, t, _) {
      final p = kfLoop(t, delayMs, 7000) ?? 0;
      return builder(kf(p, const [0, .04, .09, 1], const [0, 1, 0, 0], cssEaseInOut));
    },
  );
}
