import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/auth/launch/lf_css.dart';
import '../../common/auth/launch/lf_motion.dart';
import '../kit/svg_sti.dart';

// ── Ægil · shared pieces (Launch prototype L4500–5120, design px) ───────────

/// The Ægil sprites (`assets/aegil-s/*.png`).
String aePose(String name) => 'assets/images/dashboard/$name.png';

const Color kAeInk = Color(0xFF23201D);
const Color kAeMint = Color(0xFF5CE0B8);
const Color kAeMintLys = Color(0xFF9FF0D4);
const Color kAeSub = Color(0xFFBFD6DD);
const Color kAeTeal = Color(0xFF1E4F5C);

/// The chat glass (`linear-gradient(180deg,rgba(255,255,255,.15),
/// rgba(255,255,255,.06))` + `inset 0 1.5px 0 .3, inset 0 0 0 1px .12,
/// 0 3px 0 rgba(8,28,36,.45), 0 16px 22px -16px rgba(3,14,20,.85)`).
const List<CssBg> kAeGlass = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .15), Color.fromRGBO(255, 255, 255, .06)]),
];
const List<CssShadow> kAeGlassSh = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .3)),
  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .12)),
  CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .45)),
  CssShadow(0, 16, 22, -16, Color.fromRGBO(3, 14, 20, .85)),
];

/// The orange key (`linear-gradient(180deg,#FF9466,#E95C2C)` with the 3 px
/// `#A63A12` base).
const List<CssBg> kAeOransje = [
  CssLinear(180, [Color(0xFFFF9466), Color(0xFFE95C2C)]),
];
const List<CssShadow> kAeOransjeSh = [
  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .45)),
  CssShadow(0, 3, 0, 0, Color(0xFFA63A12)),
  CssShadow(0, 10, 14, -8, Color.fromRGBO(3, 16, 24, .75)),
];

/// The secondary glass key (`rgba(255,255,255,.2) → .08`, `0 3px 0
/// rgba(8,28,36,.7)`).
const List<CssBg> kAeSek = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .2), Color.fromRGBO(255, 255, 255, .08)]),
];
const List<CssShadow> kAeSekSh = [
  CssShadow.inset(0, 1, 0, 0, Color.fromRGBO(255, 255, 255, .32)),
  CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(255, 255, 255, .1)),
  CssShadow(0, 3, 0, 0, Color.fromRGBO(8, 28, 36, .7)),
];

/// The white paper card of the reply states (`#FFFFFF`, `0 2px 3px -1px
/// rgba(120,80,40,.12), 0 16px 30px -20px rgba(30,79,92,.45)`).
const List<CssShadow> kAePapirSh = [
  CssShadow(0, 2, 3, -1, Color.fromRGBO(120, 80, 40, .12)),
  CssShadow(0, 16, 30, -20, Color.fromRGBO(30, 79, 92, .45)),
];

/// The minne/nivå row glass (`linear-gradient(180deg,rgba(255,255,255,.12),
/// rgba(255,255,255,.05))`, 1px `.18` border, `inset 0 1.5px 0 .26`).
const List<CssBg> kAeRadGlass = [
  CssLinear(180, [Color.fromRGBO(255, 255, 255, .12), Color.fromRGBO(255, 255, 255, .05)]),
];
const List<CssShadow> kAeRadGlassSh = [
  CssShadow.inset(0, 1.5, 0, 0, Color.fromRGBO(255, 255, 255, .26)),
  CssShadow(0, 16, 28, -22, Color.fromRGBO(4, 18, 26, .7)),
];

TextStyle aeTab(TextStyle s) => s.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// A 24-unit stroked icon from the prototype's inline SVG `d`.
class AeIkon extends StatelessWidget {
  const AeIkon(this.d, {super.key, required this.size, this.stroke = 2.4, this.color = Colors.white, this.fill});

  final String d;
  final double size;
  final double stroke;
  final Color color;
  final Color? fill;

  static String sirkel(double cx, double cy, double r) => 'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0';

  static final Map<String, Path> _cache = {};

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _AeIkonPainter(_cache.putIfAbsent(d, () => svgSti(d)), size / 24, stroke, color, fill),
  );
}

class _AeIkonPainter extends CustomPainter {
  _AeIkonPainter(this.path, this.k, this.stroke, this.color, this.fill);

  final Path path;
  final double k;
  final double stroke;
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(k);
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    if (stroke > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_AeIkonPainter old) => old.path != path || old.color != color || old.stroke != stroke || old.fill != fill;
}

/// The prototype's category art (`<use href="#ico-fisk">` in a `0 0 60 54`
/// viewBox). The app's `assets/svgs/dashboard/ico_*.svg` carry the same
/// group with a cropped viewBox; it is swapped back so the art sits where
/// the prototype puts it.
class AeIco extends StatelessWidget {
  const AeIco(this.name, {super.key, required this.w, required this.h, this.viewBox = '0 0 60 54'});

  final String name;
  final double w;
  final double h;
  final String viewBox;

  static final Map<String, Future<String>> _src = {};

  @override
  Widget build(BuildContext context) {
    final key = '$name|$viewBox';
    final f = _src.putIfAbsent(
      key,
      () => rootBundle
          .loadString('assets/svgs/dashboard/$name.svg')
          .then((s) => s.replaceFirst(RegExp(r'viewBox="[^"]*"'), 'viewBox="$viewBox"')),
    );
    return SizedBox(
      width: w,
      height: h,
      child: FutureBuilder<String>(
        future: f,
        builder: (context, snap) => snap.hasData ? SvgPicture.string(snap.data!, width: w, height: h) : const SizedBox.shrink(),
      ),
    );
  }
}

/// The gevir (`#gevir`, viewBox 0 0 40 24) in [color].
class AeGevir extends StatelessWidget {
  const AeGevir({super.key, required this.color, this.w = 18, this.h = 11});

  final Color color;
  final double w;
  final double h;

  static final Path _p = svgSti('M14 22 L9 12 L4 4 M9 12 L14 5 M26 22 L31 12 L36 4 M31 12 L26 5 M14 22 L20 19 L26 22');

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(w, h), painter: _GevirPainter(color));
}

class _GevirPainter extends CustomPainter {
  _GevirPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 40 24 → meet (uniform, centred).
    final k = math.min(size.width / 40, size.height / 24);
    canvas.translate((size.width - 40 * k) / 2, (size.height - 24 * k) / 2);
    canvas.scale(k);
    canvas.drawPath(
      AeGevir._p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_GevirPainter old) => old.color != color;
}

/// Eases [builder]'s value to [v] over [ms] whenever [v] changes (a CSS
/// `transition` on one property).
class AeTw extends StatelessWidget {
  const AeTw({super.key, required this.v, required this.ms, this.curve = cssEase, required this.builder});

  final double v;
  final int ms;
  final Curve curve;
  final Widget Function(double v) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: v),
    duration: Duration(milliseconds: ms),
    curve: curve,
    builder: (context, t, _) => builder(t),
  );
}

// ── One-shot entrances (fill-mode both) ─────────────────────────────────────

/// The prototype's entrance keyframes, each `0% → 100%` on mount.
enum AeInn {
  /// `stigOpp` — translateY(26px) → 0, opacity 0 → 1.
  stigOpp,

  /// `vcKort` — translate(0,14px) scale(.96) → none.
  vcKort,

  /// `vcKnapp` — translate(0,8px) scale(.85) → none.
  vcKnapp,

  /// `vcBoble` — translate(-6px,10px) scale(.9) → none (origin 0 100%).
  vcBoble,

  /// `vcMeg` — translate(10px,12px) scale(.88) → none (origin 100% 100%).
  vcMeg,

  /// `ordInn` / `vcOrd` — translateY(5px) → 0.
  ord,

  /// `chipInn` — translateY(10px) scale(.92) → -2px 1.02 (70%) → none.
  chip,

  /// `bobleFraAegil` — translateX(-14px) scale(.7) → 2px 1.03 → none.
  bobleFraAegil,

  /// `klask` — rotate(-5deg) scale(1.15) → (-7deg .98) → (-5deg 1).
  klask,

  /// `arkOpp` — translateY(26px) opacity .6 → none.
  arkOpp,

  /// `skjermInn` — translate(0,14px) scale(.978), opacity at 55%.
  skjermInn,
}

class AeOnce extends StatelessWidget {
  const AeOnce({super.key, required this.kind, required this.ms, this.delay = 0, this.curve = cssEase, this.alignment = Alignment.center, required this.child});

  final AeInn kind;
  final double ms;
  final double delay;
  final Curve curve;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => LfOnce(
    ms: ms + delay,
    child: child,
    builder: (context, t, child) {
      final p = kfP(t, delay, ms);
      return aeInn(kind, p, curve, alignment, child!);
    },
  );
}

/// The frame of [kind] at linear progress [p] (the [curve] applies per
/// keyframe segment, as CSS does).
Widget aeInn(AeInn kind, double p, Curve curve, Alignment a, Widget child) {
  double o = 1, dx = 0, dy = 0, s = 1, r = 0;
  switch (kind) {
    case AeInn.stigOpp:
      final e = curve.transform(p);
      dy = 26 * (1 - e);
      o = e;
    case AeInn.vcKort:
      final e = curve.transform(p);
      dy = 14 * (1 - e);
      s = .96 + .04 * e;
      o = e;
    case AeInn.vcKnapp:
      final e = curve.transform(p);
      dy = 8 * (1 - e);
      s = .85 + .15 * e;
      o = e;
    case AeInn.vcBoble:
      final e = curve.transform(p);
      dx = -6 * (1 - e);
      dy = 10 * (1 - e);
      s = .9 + .1 * e;
      o = e;
    case AeInn.vcMeg:
      final e = curve.transform(p);
      dx = 10 * (1 - e);
      dy = 12 * (1 - e);
      s = .88 + .12 * e;
      o = e;
    case AeInn.ord:
      final e = curve.transform(p);
      dy = 5 * (1 - e);
      o = e;
    case AeInn.chip:
      dy = kf(p, const [0, .7, 1], const [10, -2, 0], curve);
      s = kf(p, const [0, .7, 1], const [.92, 1.02, 1], curve);
      o = kf(p, const [0, .7, 1], const [0, 1, 1], curve);
    case AeInn.bobleFraAegil:
      dx = kf(p, const [0, .6, 1], const [-14, 2, 0], curve);
      s = kf(p, const [0, .6, 1], const [.7, 1.03, 1], curve);
      o = kf(p, const [0, .6, 1], const [0, 1, 1], curve);
    case AeInn.klask:
      r = kf(p, const [0, .6, 1], const [-5, -7, -5], curve);
      s = kf(p, const [0, .6, 1], const [1.15, .98, 1], curve);
      o = kf(p, const [0, .6, 1], const [0, 1, 1], curve);
    case AeInn.arkOpp:
      final e = curve.transform(p);
      dy = 26 * (1 - e);
      o = .6 + .4 * e;
    case AeInn.skjermInn:
      dy = kf(p, const [0, 1], const [14, 0], curve);
      s = kf(p, const [0, 1], const [.978, 1], curve);
      o = kf(p, const [0, .55, 1], const [0, 1, 1], curve);
  }
  if (o >= 1 && dx == 0 && dy == 0 && s == 1 && r == 0) return child;
  return Opacity(
    opacity: o.clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rad(r),
        alignment: a,
        child: Transform.scale(scale: s, alignment: a, child: child),
      ),
    ),
  );
}

// ── Ægil's loops (origin 50% 100%) ──────────────────────────────────────────

/// `aegVink` — rotate 0 → -6 → 6 → 0 (ease-in-out).
Matrix4 aegVink(double t, double durMs) {
  final p = (t / durMs) % 1.0;
  return Matrix4.rotationZ(rad(kf(p, const [0, .25, .75, 1], const [0, -6, 6, 0], cssEaseInOut)));
}

/// `aegHopp` — translateY 0 → -10 (30%) → 0 (55%) → -4 (70%) → 0.
Matrix4 aegHopp(double t, double durMs) {
  final p = (t / durMs) % 1.0;
  final y = kf(p, const [0, .3, .55, .7, 1], const [0, -10, 0, -4, 0], cssEaseInOut);
  final r = kf(p, const [0, .3, .55, 1], const [0, -3, 0, 0], cssEaseInOut);
  return Matrix4.translationValues(0, y, 0)..rotateZ(rad(r));
}

/// `aegKikk` — rotate -4 → 4 → -4.
Matrix4 aegKikk(double t, double durMs) {
  final p = (t / durMs) % 1.0;
  return Matrix4.rotationZ(rad(kf(p, const [0, .5, 1], const [-4, 4, -4], cssEaseInOut)));
}

/// `aegPuls` — scale .9 → 1.12 → .9, opacity .5 → .95 → .5.
(double, double) aegPuls(double t, double durMs) {
  final p = (t / durMs) % 1.0;
  return (kf(p, const [0, .5, 1], const [.9, 1.12, .9], cssEaseInOut), kf(p, const [0, .5, 1], const [.5, .95, .5], cssEaseInOut));
}

/// Ægil on a loop: [m] is the transform at time t (ms), around his feet.
class AeLoop extends StatelessWidget {
  const AeLoop({super.key, required this.m, required this.child, this.delay = 0, this.alignment = Alignment.bottomCenter});

  final Matrix4 Function(double t) m;
  final double delay;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      child: child,
      builder: (context, t, child) => Transform(alignment: alignment, transform: m(math.max(0, t - delay)), child: child),
    ),
  );
}

/// `aegStaa` re-exported for the scene.
Matrix4 aeStaa(double t, double durMs) => aegStaa(t, durMs);

/// `pulsDot 1.8s` — the mint dot of the kicker.
class AePulsDot extends StatelessWidget {
  const AePulsDot({super.key, this.size = 6});

  final double size;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LfLoop(
      builder: (context, t, _) {
        final p = (t / 1800) % 1.0;
        final s = kf(p, const [0, .5, 1], const [1, 1.35, 1], cssEaseInOut);
        final o = kf(p, const [0, .5, 1], const [1, .7, 1], cssEaseInOut);
        return Opacity(
          opacity: o,
          child: Transform.scale(
            scale: s,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kAeMint,
                boxShadow: [BoxShadow(color: kAeMint, blurRadius: 4)],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The round Ægil avatar of the chat (`32px`, `linear-gradient(160deg,
/// #4A93A4,#1E4F5C)`, the front sprite at 160 % from 50 % 0 %).
class AeAvatar extends StatelessWidget {
  const AeAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(begin: Alignment(-.34, -.94), end: Alignment(.34, .94), colors: [Color(0xFF4A93A4), kAeTeal]),
      boxShadow: [
        const BoxShadow(color: Color.fromRGBO(255, 255, 255, .85), spreadRadius: 2),
        BoxShadow(color: const Color.fromRGBO(3, 16, 24, .7), offset: const Offset(0, 6), blurRadius: cssSigma(10) * 2, spreadRadius: -4),
      ],
    ),
    child: ClipOval(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: size * 1.6,
        maxHeight: size * 1.6,
        child: Transform.translate(
          offset: Offset(-size * .3, -size * .08),
          child: Image.asset(aePose('front'), width: size * 1.6, height: size * 1.6, fit: BoxFit.cover, alignment: Alignment.topCenter),
        ),
      ),
    ),
  );
}

/// The «Bestill igjen» / chip `style-active` press: translateY(2.5px).
class AePress extends StatelessWidget {
  const AePress({super.key, required this.onTap, required this.child, this.dy = 2.5, this.scale = 1});

  final VoidCallback? onTap;
  final Widget child;
  final double dy;
  final double scale;

  @override
  Widget build(BuildContext context) => _AePress(onTap: onTap, dy: dy, scale: scale, child: child);
}

class _AePress extends StatefulWidget {
  const _AePress({required this.onTap, required this.child, required this.dy, required this.scale});

  final VoidCallback? onTap;
  final Widget child;
  final double dy;
  final double scale;

  @override
  State<_AePress> createState() => _AePressState();
}

class _AePressState extends State<_AePress> {
  bool _ned = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _ned = true),
    onTapCancel: () => setState(() => _ned = false),
    onTapUp: (_) => setState(() => _ned = false),
    onTap: widget.onTap,
    child: AeTw(
      v: _ned ? 1 : 0,
      ms: 120,
      builder: (v) => Transform.translate(
        offset: Offset(0, widget.dy * v),
        child: Transform.scale(scale: 1 + (widget.scale - 1) * v, child: widget.child),
      ),
    ),
  );
}
