import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'bergen_lagring.dart';
import 'bergen_perf.dart';

// ── Vannoverganger (Bergen 29 Oct, `Vannoverganger.dc.html`, L20229–20510) ──
// Three transitions, one per navigation type, all under 600 ms:
//   Bølge   — a sheet (`arkOpp`) rises behind a wave edge that calms and lies
//             flat; bubbles follow the edge. Also the tab switch, full screen.
//   Menisk  — forward/back between screens: the leading edge curves like the
//             water line in a glass and straightens when the screen lands; the
//             screen underneath slides back 26 % and darkens.
//   Dykk    — the tab switch alternative: the new tab breaks the surface with
//             a little lag in the middle, the old one sinks back.
// The design's tweaks (section Overganger) are [BergenOverganger]; the
// defaults are the design's. Everything honours reduced motion (`ovRolig`).

enum ArkOvergang { bolge, glid }

enum SkjermOvergang { menisk, draape, av }

enum FaneOvergang { bolge, dykk, trapp, av }

abstract final class BergenOverganger {
  static ArkOvergang ark = ArkOvergang.bolge;
  static SkjermOvergang skjerm = SkjermOvergang.menisk;
  static FaneOvergang fane = FaneOvergang.bolge;
}

/// `ovE()`: the five easings.
abstract final class OvE {
  static const Cubic ios = Cubic(.32, .72, 0, 1);
  static const Cubic bolge = Cubic(.25, 1, .5, 1);
  static const Cubic synk = Cubic(.4, 0, 1, 1);
  static const Cubic spr = Cubic(.3, 1.12, .5, 1);
  static const Cubic ut = Cubic(.22, 1, .36, 1);

  static double e(Cubic c, double p) => c.transform(p.clamp(0.0, 1.0));
}

double ovClamp(double v) => v.clamp(0.0, 1.0);

/// `ovBolgeWave(W, amp, ph)`: the wave along the top edge, in px below `amp`.
double Function(double) ovBolgeWave(double w, double amp, double ph) =>
    (x) => amp + amp * (.72 * math.sin(2 * math.pi * x / w * .85 + ph) + .28 * math.sin(2 * math.pi * x / w * 1.9 - ph * 1.5 + 1.2));

/// `ovKant(W, R, f)`: the top edge with rounded corners of radius [r] under
/// the curve [f] — the clip outline and the drawn line.
List<Offset> ovKant(double w, double r, double Function(double) f) {
  const c = [0.0, .02, .06, .12, .2, .3, .42, .56, .72, .86, 1.0];
  final xs = <double>[for (final t in c) t * r, for (var i = 1; i < 16; i++) r + (w - 2 * r) * i / 16, for (final t in c.reversed) w - t * r];
  return [
    for (final x in xs)
      () {
        final d = x < r ? r - x : (x > w - r ? x - (w - r) : 0.0);
        final cy = d > 0 ? r - math.sqrt(math.max(0, r * r - d * d)) : 0.0;
        return Offset(x, math.max(f(x), cy));
      }(),
  ];
}

/// `ovPoly(K, W, bunn)`: the clip polygon under the edge [k].
Path ovPoly(List<Offset> k, double w, double bunn) {
  final p = Path()..moveTo(k.first.dx, k.first.dy);
  for (final q in k.skip(1)) {
    p.lineTo(q.dx, q.dy);
  }
  return p
    ..lineTo(w, bunn)
    ..lineTo(0, bunn)
    ..close();
}

/// `ovBobler`: a bubble — 1.2px white rim, a highlight at 32 % / 30 %, a
/// mint tint.
void ovTegnBoble(Canvas canvas, Offset c, double s, double opacity) {
  if (opacity <= 0) return;
  final r = s / 2;
  canvas.drawCircle(c, r, Paint()..color = const Color(0xFF5CE0B8).withValues(alpha: .12 * opacity));
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.36, -.4),
        radius: .34,
        colors: [Colors.white.withValues(alpha: .95 * opacity), Colors.white.withValues(alpha: .95 * opacity), Colors.white.withValues(alpha: 0)],
        stops: const [0, .53, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  canvas.drawCircle(
    c,
    r - .6,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .65 * opacity),
  );
}

class OvBoble {
  const OvBoble(this.c, this.size, this.opacity);
  final Offset c;
  final double size, opacity;
}

/// `ovSvg`: the edge line (white .85, 3px) and, when [glod], the mint glow
/// under it (10px), plus the bubbles.
class OvKantPainter extends CustomPainter {
  const OvKantPainter({required this.kant, required this.kantOp, this.glodOp = 0, this.bobler = const []});

  final List<Offset> kant;
  final double kantOp, glodOp;
  final List<OvBoble> bobler;

  @override
  void paint(Canvas canvas, Size size) {
    if (kant.length > 1 && (kantOp > 0 || glodOp > 0)) {
      final p = Path()..moveTo(kant.first.dx, kant.first.dy);
      for (final q in kant.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      if (glodOp > 0) {
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeJoin = StrokeJoin.round
            ..color = const Color.fromRGBO(92, 224, 184, .32).withValues(alpha: .32 * glodOp.clamp(0, 1)),
        );
      }
      if (kantOp > 0) {
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withValues(alpha: .85 * kantOp.clamp(0, 1)),
        );
      }
    }
    for (final b in bobler) {
      ovTegnBoble(canvas, b.c, b.size, b.opacity.clamp(0, 1));
    }
  }

  @override
  bool shouldRepaint(OvKantPainter old) => true;
}

class _PolyClip extends CustomClipper<Path> {
  const _PolyClip(this.path);
  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PolyClip old) => true;
}

// ── Bølge (1b) on a sheet ───────────────────────────────────────────────────

/// Bubble lanes shared by the sheet and the tab Bølge / Dykk (x in the 330
/// frame): six on the edge, five that leave it and rise.
const List<double> kBolgeFx = [38, 88, 146, 198, 250, 296];
const List<double> kBolgeFs = [6, 4, 7, 5, 4, 6];
const List<double> kBolgeKx = [64, 122, 184, 238, 284];
const List<double> kBolgeKs = [6, 4, 7, 5, 4];
const List<double> kBolgeKr = [46, 30, 58, 38, 26];

/// The wave on a sheet (`ovBolgeInn` 520 ms / `ovBolgeUt` 380 ms). Wrap the
/// sheet's panel in it; the route moves the panel ([bolgeArkSlide]), this
/// draws the wave edge the panel rises behind, the bubbles on and above it,
/// and lets the content lag 28px (`barn`; not on dark sheets, `data-arkmork`).
/// [animation] defaults to the enclosing route's.
class BolgeArk extends StatelessWidget {
  const BolgeArk({super.key, required this.child, this.radius = 28, this.mork = false, this.animation});

  final Widget child;
  final double radius;
  final bool mork;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final a = animation ?? ModalRoute.of(context)?.animation;
    if (a == null || BergenOverganger.ark != ArkOvergang.bolge || MediaQuery.disableAnimationsOf(context)) return child;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : MediaQuery.sizeOf(context).width;
        return AnimatedBuilder(
          animation: a,
          child: child,
          builder: (context, child) {
            // The tree keeps one shape from first frame to last (the sheet
            // would otherwise remount and lose its state): landed = no clip,
            // no lag, nothing drawn.
            final st = a.status;
            final ut = st == AnimationStatus.reverse;
            final p = st == AnimationStatus.completed || st == AnimationStatus.dismissed ? 1.0 : (ut ? 1 - a.value : a.value);
            return _BolgeFlate(w: w, p: p, ut: ut, radius: radius, mork: mork, child: child!);
          },
        );
      },
    );
  }
}

class _BolgeFlate extends StatelessWidget {
  const _BolgeFlate({required this.w, required this.p, required this.ut, required this.radius, required this.mork, required this.child});

  final double w, p, radius;
  final bool ut, mork;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The sheet's own height is what the content gives it: measure it with
    // the clip's size (the polygon's bottom is well under it).
    final List<Offset> kant;
    final double eo, lag;
    final bobler = <OvBoble>[];
    final over = <OvBoble>[];
    bool full;
    if (!ut) {
      final amp = 18 * math.sin(math.pi * p);
      full = p >= 1;
      final f = ovBolgeWave(w, amp, p * math.pi * 1.4);
      kant = ovKant(w, radius, f);
      eo = full ? 0 : math.min(1, amp / 5);
      lag = full || mork ? 0 : 28 * (1 - OvE.e(OvE.ut, p));
      final u = OvE.e(OvE.ut, p);
      for (var j = 0; j < 6; j++) {
        final x = kBolgeFx[j] * w / 330;
        bobler.add(OvBoble(Offset(x, f(x) + 8 + (j % 3) * 7 - 22 * u + kBolgeFs[j] / 2), kBolgeFs[j], .9 * eo * (amp / 18)));
      }
      for (var j = 0; j < 5; j++) {
        final q = ovClamp((p - .26 - j * .045) / .5);
        final x = kBolgeKx[j] * w / 330;
        over.add(OvBoble(Offset(x, f(x) - 4 - kBolgeKr[j] * OvE.e(OvE.ut, q) + kBolgeKs[j] / 2), kBolgeKs[j], q > 0 && q < 1 ? .85 * math.sin(math.pi * q) : 0));
      }
    } else {
      final amp = 14 * math.sin(math.pi * p);
      full = amp < .3;
      final f = ovBolgeWave(w, amp, -p * math.pi * 1.2);
      kant = ovKant(w, radius, f);
      eo = math.min(1, amp / 5);
      lag = 0;
    }
    final clip = full ? null : _PolyClip(ovPoly(kant, w, 100000));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A null clipper clips to the box: nothing is cut once landed.
        ClipPath(
          clipper: clip,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Transform.translate(offset: Offset(0, lag), child: child),
              Positioned(left: 0, right: 0, top: 0, height: 120, child: IgnorePointer(child: CustomPaint(painter: OvKantPainter(kant: full ? const [] : kant, kantOp: .85 * eo, glodOp: eo, bobler: bobler)))),
            ],
          ),
        ),
        // The bubbles that leave the edge and rise over what is behind: their
        // own layer outside the clip (`ut`), 120px up.
        Positioned(
          left: 0,
          right: 0,
          top: -120,
          height: 240,
          child: IgnorePointer(
            child: CustomPaint(painter: OvKantPainter(kant: const [], kantOp: 0, bobler: [for (final b in over) OvBoble(b.c + const Offset(0, 120), b.size, b.opacity)])),
          ),
        ),
      ],
    );
  }
}

/// Bølge timing for a sheet route: in 520 ms with [OvE.bolge], out 380 ms with
/// [OvE.synk].
const Duration kBolgeInn = Duration(milliseconds: 520);
const Duration kBolgeUt = Duration(milliseconds: 380);

/// The panel's travel for a route that moves it itself: the fraction of its
/// own height it sits below its place (`translate3d(0,(h+30)(1−e))`, read as
/// 1.04·h).
double bolgeArkSlide(Animation<double> a) {
  if (a.status == AnimationStatus.reverse) return 1.04 * OvE.e(OvE.synk, 1 - a.value);
  return 1.04 * (1 - OvE.e(OvE.bolge, a.value));
}

/// A sheet panel inside a custom route (the `kArk` sheets with their own
/// `PageRouteBuilder`): the Bølge slide and the wave. Give the route
/// [kBolgeInn] / [kBolgeUt].
Widget bolgeArkRute(Animation<double> anim, Widget panel, {double radius = 28, bool mork = false}) {
  return AnimatedBuilder(
    animation: anim,
    child: BolgeArk(animation: anim, radius: radius, mork: mork, child: panel),
    builder: (context, child) => FractionalTranslation(translation: Offset(0, bolgeArkSlide(anim)), child: child),
  );
}

// ── Menisk (1d): screen forward / back ──────────────────────────────────────

/// A screen route with the Menisk transition: in 440 ms, back 400 ms. The
/// route underneath is shifted by [delegatedTransition] (any route kind) or,
/// under another Menisk route, by its own [buildTransitions].
class MeniskRoute<T> extends PageRoute<T> {
  MeniskRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 440);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 400);

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is MeniskRoute || nextRoute is MaterialRouteTransitionMixin;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _meniskUnder;

  static Widget? _meniskUnder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, bool allowSnapshotting, Widget? child) {
    if (child == null || MediaQuery.disableAnimationsOf(context)) return child;
    return MeniskBunn(secondary: secondaryAnimation, child: child);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final Widget t = MediaQuery.disableAnimationsOf(context) ? child : MeniskBunn(secondary: secondaryAnimation, child: MeniskTopp(animation: animation, child: child));
    // Heat plan Step 8: the cache root goes around the transition layers.
    // Inside them it found, at rest, the box clip of [meniskLag] (a path
    // clip, which it would draw inside again) above it and the dim painted
    // beneath it, and so never made an image (iOS simulator, 2026-11-10).
    // Here the dim and the clip are the bottom of its own run. One tree
    // shape whether animations are off or not.
    return BergenPerf.lagringPaa ? BergenLagring(child: t) : t;
  }
}

/// The screen underneath: slides back 26 % while the top one comes in, back
/// to place when it leaves.
class MeniskBunn extends StatelessWidget {
  const MeniskBunn({super.key, required this.secondary, required this.child});

  final Animation<double> secondary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: secondary,
      child: child,
      builder: (context, child) {
        final v = secondary.value;
        final tilbake = secondary.status == AnimationStatus.reverse;
        final e = OvE.e(OvE.ios, tilbake ? 1 - v : v);
        final k = v <= 0 ? 0.0 : (tilbake ? 1 - e : e);
        final w = MediaQuery.sizeOf(context).width;
        // Always the same wrapper (at rest it is the identity), so the
        // screen underneath never remounts.
        return Transform.translate(offset: Offset(-w * .26 * k, 0), child: child);
      },
    );
  }
}

/// The screen coming in (or going back): the meniscus edge, the line on it,
/// the dim under it.
class MeniskTopp extends StatelessWidget {
  const MeniskTopp({super.key, required this.animation, required this.child, this.flat = false});

  final Animation<double> animation;
  final Widget child;

  /// `flat`: transparent layers (the onboarding steps) — no dim, the top
  /// layer fades in / out instead.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final st = animation.status;
        final v = animation.value;
        final tilbake = st == AnimationStatus.reverse || st == AnimationStatus.dismissed;
        // Landed: p = 1 draws the plain screen through the same wrappers.
        final p = st == AnimationStatus.completed || v >= 1 ? 1.0 : (tilbake ? 1 - v : v);
        final size = MediaQuery.sizeOf(context);
        return meniskLag(size: size, p: p, tilbake: tilbake, flat: flat, child: child!);
      },
    );
  }
}

/// One frame of the Menisk top layer at progress [p] (0 → 1 of the move).
Widget meniskLag({required Size size, required double p, required bool tilbake, required Widget child, bool flat = false}) {
  final w = size.width, h = size.height;
  final e = OvE.e(OvE.ios, p), s = math.sin(math.pi * p);
  final b = tilbake ? -28 * s : 34 * s;
  final k = tilbake ? 1 - e : e;
  final tx = tilbake ? w * e : w * (1 - e);
  const n = 24;
  final pts = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final y = i * h / n, sn = math.sin(math.pi * y / h);
    pts.add(Offset(b >= 0 ? b * (1 - sn) : -b * sn, y));
  }
  final clip = Path()..moveTo(w, 0);
  for (final q in pts) {
    clip.lineTo(q.dx, q.dy);
  }
  clip
    ..lineTo(w, h)
    ..close();
  final kantOp = math.min(1, b.abs() / 8) * .7;
  // One tree shape throughout (a null clipper clips to the box): the screen
  // never remounts at the first or the last frame.
  Widget top = ClipPath(
    clipper: b.abs() < .4 ? null : _PolyClip(clip),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(child: CustomPaint(painter: OvKantPainter(kant: pts, kantOp: kantOp))),
      ],
    ),
  );
  if (flat) top = Opacity(opacity: (tilbake ? 1 - .5 * e : .5 + .5 * e).clamp(0, 1), child: top);
  return Stack(
    fit: StackFit.expand,
    children: [
      if (!flat) IgnorePointer(child: ColoredBox(color: const Color(0xFF0B1B20).withValues(alpha: .4 * k))),
      Transform.translate(offset: Offset(tx, 0), child: top),
    ],
  );
}

/// The layer that stays (`bunn`) in a flat Menisk: shifted 26 % and clipped
/// along the same edge, faded to half.
Widget meniskBunnFlat({required Size size, required double p, required bool tilbake, required Widget child}) {
  final w = size.width, h = size.height;
  final e = OvE.e(OvE.ios, p), s = math.sin(math.pi * p);
  final b = tilbake ? -28 * s : 34 * s;
  final k = tilbake ? 1 - e : e;
  final tx = tilbake ? w * e : w * (1 - e);
  final bx = -w * .26 * k;
  const n = 24;
  final clip = Path()..moveTo(0, 0);
  for (var i = 0; i <= n; i++) {
    final y = i * h / n, sn = math.sin(math.pi * y / h);
    final x = b >= 0 ? b * (1 - sn) : -b * sn;
    clip.lineTo(math.max(0, tx + x - bx), y);
  }
  clip
    ..lineTo(0, h)
    ..close();
  return Transform.translate(
    offset: Offset(bx, 0),
    child: Opacity(
      opacity: (1 - .5 * k).clamp(0, 1),
      child: ClipPath(clipper: _PolyClip(clip), child: child),
    ),
  );
}

/// Whether the design's transitions run here at all (`ovRolig`): not under
/// reduced motion, nor in the `still` tier.
bool ovRolig(BuildContext context) => MediaQuery.disableAnimationsOf(context) || BergenPerf.of(context) == BergenTier.still;

// ── Menisk between steps that are not routes (the onboarding, `ovForLag`
// type 'onb') ───────────────────────────────────────────────────────────────

/// Swaps [child] with the flat Menisk when [steg] changes: the old step is
/// pictured once and slides back 26 % (clipped along the same edge, fading
/// to half) while the new one comes in from the right; back when [steg]
/// decreases. Reduced motion, the `still` tier and a step that only re-keys
/// swap at once.
class MeniskBytte extends StatefulWidget {
  const MeniskBytte({super.key, required this.steg, required this.child});

  final int steg;
  final Widget child;

  @override
  State<MeniskBytte> createState() => _MeniskBytteState();
}

class _MeniskBytteState extends State<MeniskBytte> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final GlobalKey _flate = GlobalKey();
  late Widget _vis = widget.child;
  late int _steg = widget.steg;
  ui.Image? _gml;
  bool _tilbake = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(MeniskBytte old) {
    super.didUpdateWidget(old);
    if (widget.steg == _steg || ovRolig(context) || BergenOverganger.skjerm != SkjermOvergang.menisk) {
      _vis = widget.child;
      _steg = widget.steg;
      return;
    }
    _bytt();
  }

  Future<void> _bytt() async {
    final seq = ++_seq;
    _c.stop();
    // The old step stays one frame while it is pictured; a picture that
    // takes longer than 300ms gives way to a plain swap.
    final done = Completer<ui.Image?>();
    _bilde().then((img) {
      if (done.isCompleted) {
        img?.dispose();
      } else {
        done.complete(img);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!done.isCompleted) done.complete(null);
    });
    final gml = await done.future;
    if (!mounted || seq != _seq) {
      gml?.dispose();
      return;
    }
    _gml?.dispose();
    final tilbake = widget.steg < _steg;
    setState(() {
      _gml = gml;
      _tilbake = tilbake;
      _vis = widget.child;
      _steg = widget.steg;
    });
    if (gml == null) return;
    _c.duration = Duration(milliseconds: tilbake ? 400 : 440);
    await _c.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted || seq != _seq) return;
    setState(() {
      _gml?.dispose();
      _gml = null;
    });
  }

  Future<ui.Image?> _bilde() async {
    if (!mounted) return null;
    final ro = _flate.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary || !ro.hasSize) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    try {
      final gpu = await ro.toImage(pixelRatio: dpr);
      final data = await gpu.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = gpu.width, h = gpu.height;
      gpu.dispose();
      if (data == null) return null;
      final done = Completer<ui.Image>();
      ui.decodeImageFromPixels(data.buffer.asUint8List(), w, h, ui.PixelFormat.rgba8888, done.complete);
      return await done.future;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _gml?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = RepaintBoundary(key: _flate, child: _vis);
    // The live step keeps the wrappers of its own move for as long as it is
    // up (at rest they are the identity), so it never remounts; the picture
    // of the old step is drawn only while the move runs.
    return AnimatedBuilder(
      animation: _c,
      child: live,
      builder: (context, live) {
        final g = _gml;
        final p = g == null ? 1.0 : _c.value;
        final size = MediaQuery.sizeOf(context);
        final bilde = g == null ? null : RawImage(image: g, fit: BoxFit.fill, filterQuality: FilterQuality.low);
        // Forward: the new step on top, the old one underneath. Back: the
        // old one leaves on top, the new one is revealed underneath.
        return Stack(
          fit: StackFit.expand,
          children: _tilbake
              ? [
                  meniskBunnFlat(size: size, p: p, tilbake: true, child: live!),
                  if (bilde != null && p < 1) IgnorePointer(child: meniskLag(size: size, p: p, tilbake: true, flat: true, child: bilde)),
                ]
              : [
                  if (bilde != null && p < 1) IgnorePointer(child: meniskBunnFlat(size: size, p: p, tilbake: false, child: bilde)),
                  meniskLag(size: size, p: p, tilbake: false, flat: true, child: live!),
                ],
        );
      },
    );
  }
}
