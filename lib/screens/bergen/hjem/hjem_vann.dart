import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ── The sheet as water (prototype `vannKant` / `vannBunn` / `vannBobler`) ──
// Scrolled, the sheet's top becomes a moving water surface: two wave rows
// (120 and 190 px) drift opposite ways over a foam line, and the content
// sinks under it. The content itself ends in a waterline down towards the
// quay. Scrolling releases a few air bubbles that rise towards the surface.
// Everything is in design px × [s].

const double _t1 = 120, _t2 = 190;

/// One row of `bue` waves ("M0 12 C 22 4, 38 4, 60 12 S 98 20, 120 12"), the
/// 190 px row ("M0 14 C 40 7, 60 7, 95 14 S 150 21, 190 14"), or their
/// upside-down "opp" twins for the bottom.
void _rad(Path p, double tile, double x0, double y0, double w, double s, {required bool opp, bool lukk = true}) {
  // Control points per tile, in tile units (22 tall).
  final List<List<double>> c = tile == _t1
      ? (opp
            ? const [
                [0, 10],
                [22, 18, 38, 18, 60, 10],
                [82, 2, 98, 2, 120, 10],
              ]
            : const [
                [0, 12],
                [22, 4, 38, 4, 60, 12],
                [82, 20, 98, 20, 120, 12],
              ])
      : (opp
            ? const [
                [0, 8],
                [40, 15, 60, 15, 95, 8],
                [130, 1, 150, 1, 190, 8],
              ]
            : const [
                [0, 14],
                [40, 7, 60, 7, 95, 14],
                [130, 21, 150, 21, 190, 14],
              ]);
  var start = x0 % tile;
  if (start > 0) start -= tile;
  final first = Offset((start + c[0][0]) * s, (y0 + c[0][1]) * s);
  p.moveTo(first.dx, first.dy);
  for (var x = start; x < w / s; x += tile) {
    for (final k in c.skip(1)) {
      p.cubicTo((x + k[0]) * s, (y0 + k[1]) * s, (x + k[2]) * s, (y0 + k[3]) * s, (x + k[4]) * s, (y0 + k[5]) * s);
    }
  }
  if (!lukk) return;
  final end = (start + ((w / s - start) / tile).ceil() * tile) * s;
  // Close below the curve (top waves) or above it (bottom waves).
  final yEdge = (opp ? y0 : y0 + 22) * s;
  p.lineTo(end, yEdge);
  p.lineTo(first.dx, yEdge);
  p.close();
}

class HjemVann extends StatefulWidget {
  const HjemVann({
    super.key,
    required this.controller,
    required this.s,
    required this.child,
    this.bunnLuft = 0,
    this.bobler = true,
    this.bunn = true,
    this.flate,
  });

  final ScrollController controller;
  final double s;
  final Widget child;

  /// Air bubbles while scrolling (`vannBobler`).
  final bool bobler;

  /// The waterline at the content's end (`vannBunn`).
  final bool bunn;

  /// Where the surface sits for a scroll offset (design px): its depth `y`
  /// from the top and the foam's opacity `a`; null while there is none.
  /// Default: Hjem's sheet (`f = min(40, scroll·.4)`, `y = f + 4`, from
  /// `f ≥ 1`, foam `min(1, f/14)`). The product sheet's `pVann` uses
  /// `f = min(1, scroll/40)`, `y = 6 + 10f`, from 2 px, foam `f`.
  final ({double y, double a})? Function(double scroll)? flate;

  /// Empty water after the waterline at the content's end (design px) —
  /// what lets Under kaien show through below it.
  final double bunnLuft;

  @override
  State<HjemVann> createState() => _HjemVannState();
}

class _Boble {
  _Boble(this.x, this.y0, this.size, this.reise, this.w, this.dur, this.t0);
  final double x, y0, size, reise, w, dur, t0;
}

class _HjemVannState extends State<HjemVann> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _t = ValueNotifier(0);
  final List<_Boble> _bobler = [];
  final math.Random _r = math.Random();
  double _sist = 0, _akk = 0;
  bool _rolig = false;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scroll);
  }

  /// The surface for the current scroll offset (see [HjemVann.flate]).
  ({double y, double a})? _overflate() {
    final st0 = _px / widget.s;
    if (widget.flate case final f?) return f(st0);
    final f = math.min(40.0, st0 * .4);
    return f >= 1 ? (y: f + 4, a: math.min(1.0, f / 14)) : null;
  }

  /// Animate only while a surface is on screen.
  void _vurder() {
    final trengs = !_rolig && (_overflate() != null || _slutt() != null || _bobler.isNotEmpty);
    if (trengs && !_ticker.isActive) _ticker.start();
    if (!trengs && _ticker.isActive) _ticker.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rolig = MediaQuery.disableAnimationsOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vurder();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scroll);
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  double _base = 0, _naa = 0;

  void _tick(Duration e) {
    // The clock carries on from where it stopped.
    if (e == Duration.zero) _base = _naa;
    final ms = _base + e.inMicroseconds / 1000;
    _naa = ms;
    _bobler.removeWhere((b) => ms - b.t0 > b.dur + 400);
    _t.value = ms;
    if (_bobler.isEmpty) _vurder();
  }

  double get _px => widget.controller.hasClients ? widget.controller.position.pixels : 0;

  /// `vannBobler`: every ~90 px scrolled, one or two bubbles (at most five).
  void _scroll() {
    _vurder();
    final st0 = _px / widget.s;
    final f = math.min(40.0, st0 * .4);
    final dy = (st0 - _sist).abs();
    _sist = st0;
    if (f < 1 || _rolig || !widget.bobler) return;
    _akk += math.min(dy, 60);
    if (_akk < 90) return;
    _akk = 0;
    if (_bobler.length >= 5) return;
    final w = _size.width / widget.s, h = _size.height / widget.s;
    final flate = f + 4;
    final n = _r.nextDouble() < .35 ? 2 : 1;
    for (var i = 0; i < n; i++) {
      final sz = 3 + _r.nextDouble() * (i > 0 ? 3 : 6);
      final x = 18 + _r.nextDouble() * (w - 36);
      final y0 = flate + 140 + _r.nextDouble() * math.max(60, h - flate - 320);
      final reise = math.min(90 + _r.nextDouble() * 110, y0 - math.max(flate, 0) - 40);
      if (reise < 40) continue;
      final ww = (_r.nextBool() ? -1 : 1) * (4 + _r.nextDouble() * 6);
      _bobler.add(_Boble(x, y0, sz, reise, ww, 2200 + _r.nextDouble() * 1400, _t.value + i * 180));
    }
    _vurder();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: _Klipp(this),
              child: RepaintBoundary(child: widget.child),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(child: CustomPaint(painter: _Skum(this, s))),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Surface depth `f` (design px), wave drift and bob at time [t] (ms).
  ({double f, double x1, double x2, double bob}) _flate(double t) {
    final st0 = _px / widget.s;
    return (f: math.min(40.0, st0 * .4), x1: (t / 38) % 120, x2: -(t / 61) % 190, bob: math.sin(t / 700) * 1.6);
  }

  /// Where the content ends, in design px from the sheet's top (null when
  /// it's well below the screen).
  double? _slutt() {
    if (!widget.bunn) return null;
    final c = widget.controller;
    if (!c.hasClients || !c.position.hasContentDimensions) return null;
    final end = (c.position.maxScrollExtent + c.position.viewportDimension - c.position.pixels) / widget.s - widget.bunnLuft;
    return end < _size.height / widget.s + 30 ? end : null;
  }

  /// The bottom waves' drift (`vannBunn`, 7s loop): row 1 left 840 px,
  /// row 2 right 380 px, lifting 2 / dropping 1 px half-way.
  ({double a, double b, double c, double d}) _bunn(double t) {
    final p = (t / 7000) % 1.0;
    final half = p < .5 ? p * 2 : (p - .5) * 2;
    double lerp(double from, double to) => from + (to - from) * half;
    return p < .5 ? (a: lerp(0, -420), b: lerp(0, 2), c: lerp(0, 190), d: lerp(0, -1)) : (a: lerp(-420, -840), b: lerp(2, 0), c: lerp(190, 380), d: lerp(-1, 0));
  }
}

class _Klipp extends CustomClipper<Path> {
  _Klipp(this.v) : super(reclip: Listenable.merge([v._t, v.widget.controller]));

  final _HjemVannState v;

  @override
  Path getClip(Size size) {
    final s = v.widget.s;
    final t = v._rolig ? 0.0 : v._t.value;
    final q = v._flate(t);
    final full = Path()..addRect(Offset.zero & size);
    var p = full;
    final o = v._overflate();
    if (o != null) {
      final y = o.y;
      final w1 = Path(), w2 = Path();
      _rad(w1, _t1, q.x1, y - 22 + q.bob, size.width, s, opp: false);
      _rad(w2, _t2, q.x2, y - 20 - q.bob, size.width, s, opp: false);
      p = Path.combine(PathOperation.union, Path.combine(PathOperation.union, Path()..addRect(Rect.fromLTRB(0, y * s, size.width, size.height)), w1), w2);
    }
    final e = v._slutt();
    if (e != null) {
      final b = v._bunn(t);
      final w1 = Path(), w2 = Path();
      _rad(w1, _t1, b.a, e - 22 - b.b, size.width, s, opp: true);
      _rad(w2, _t2, b.c, e - 22 - b.d, size.width, s, opp: true);
      final bunn = Path.combine(PathOperation.union, Path.combine(PathOperation.union, Path()..addRect(Rect.fromLTRB(0, -size.height, size.width, (e - 20) * s)), w1), w2);
      p = Path.combine(PathOperation.intersect, p, bunn);
    }
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// The foam lines and the tinted band just under each surface, and the
/// bubbles.
class _Skum extends CustomPainter {
  _Skum(this.v, this.s) : super(repaint: Listenable.merge([v._t, v.widget.controller]));

  final _HjemVannState v;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final t = v._rolig ? 0.0 : v._t.value;
    final q = v._flate(t);
    final w = size.width;

    final o = v._overflate();
    if (o != null) {
      final top = (o.y - 22) * s;
      canvas.save();
      canvas.translate(0, top);
      final a = o.a;
      // Tone just under the surface.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 64 * s),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(30, 79, 92, 0),
              const Color.fromRGBO(30, 79, 92, 0),
              Color.fromRGBO(23, 62, 72, .55 * a),
              Color.fromRGBO(30, 79, 92, .22 * a),
              const Color.fromRGBO(30, 79, 92, 0),
            ],
            stops: const [0, 14 / 64, 20 / 64, 38 / 64, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, 64 * s)),
      );
      _skum(canvas, w, q.x1, q.bob, q.x2, 2 - q.bob, a, opp: false);
      canvas.restore();
    }

    final e = v._slutt();
    if (e != null) {
      final b = v._bunn(t);
      canvas.save();
      canvas.translate(0, (e - 64) * s);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 64 * s),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color.fromRGBO(30, 79, 92, 0), Color.fromRGBO(30, 79, 92, 0), Color.fromRGBO(10, 32, 40, .55), Color.fromRGBO(23, 62, 72, .2), Color.fromRGBO(30, 79, 92, 0)],
            stops: [0, 12 / 64, 22 / 64, 44 / 64, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, 64 * s)),
      );
      _skum(canvas, w, b.a, 42 - b.b, b.c, 42 - b.d, 1, opp: true);
      canvas.restore();
    }

    // Bubbles, only below the surface.
    if (v._bobler.isNotEmpty && o != null) {
      final flate = o.y;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, (flate + 24) * s, w, size.height));
      const ease = Cubic(.3, .1, .4, 1);
      for (final bb in v._bobler) {
        final p = ((t - bb.t0) / bb.dur).clamp(0.0, 1.0);
        if (t < bb.t0) continue;
        final e2 = ease.transform(p);
        double k(List<double> vals) {
          const st = [0.0, .2, .6, 1.0];
          var i = 0;
          while (i < 2 && e2 > st[i + 1]) {
            i++;
          }
          final l = (e2 - st[i]) / (st[i + 1] - st[i]);
          return vals[i] + (vals[i + 1] - vals[i]) * l;
        }

        final dx = k([0, bb.w * .6, -bb.w * .4, bb.w]);
        final dy = k([0, -bb.reise * .25, -bb.reise * .6, -bb.reise]);
        final sc = k([.6, 1, 1.05, 1.12]);
        final o = k([0, .85, .7, 0]);
        final r = bb.size / 2 * sc * s;
        final c = Offset((bb.x + bb.size / 2 + dx) * s, (bb.y0 + bb.size / 2 + dy) * s);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.36, -.4),
              colors: [Color.fromRGBO(255, 255, 255, .75 * o), Color.fromRGBO(255, 255, 255, .75 * o), Color.fromRGBO(214, 242, 250, .12 * o), const Color.fromRGBO(214, 242, 250, 0)],
              stops: const [0, .18, .4, .7],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
        canvas.drawCircle(
          c,
          r - .5 * s,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * s
            ..color = Color.fromRGBO(214, 242, 250, .55 * o),
        );
      }
      canvas.restore();
    }
  }

  /// `skum`/`skum2` (top) or `skumOpp`/`skumOpp2` (bottom), tiled.
  void _skum(Canvas canvas, double w, double x1, double y1, double x2, double y2, double a, {required bool opp}) {
    final hoved = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6 * s
      ..color = Color.fromRGBO(214, 242, 250, (opp ? .8 : .85) * a);
    final p1 = Path();
    _rad(p1, _t1, x1, y1, w, s, opp: opp, lukk: false);
    canvas.drawPath(p1, hoved);
    // The small highlight strokes inside each 120 px tile.
    final fin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1 * s;
    var start = x1 % _t1;
    if (start > 0) start -= _t1;
    for (var x = start; x < w / s; x += _t1) {
      final l = Path();
      if (opp) {
        l
          ..moveTo((x + 10) * s, (y1 + 6) * s)
          ..cubicTo((x + 26) * s, (y1 + 10) * s, (x + 36) * s, (y1 + 10) * s, (x + 50) * s, (y1 + 7) * s);
        canvas.drawPath(l, fin..color = Color.fromRGBO(255, 255, 255, .3 * a));
        final l2 = Path()
          ..moveTo((x + 72) * s, (y1 + 4) * s)
          ..cubicTo((x + 86) * s, (y1 + 8) * s, (x + 98) * s, (y1 + 8) * s, (x + 112) * s, (y1 + 5) * s);
        canvas.drawPath(l2, fin..color = Color.fromRGBO(255, 255, 255, .26 * a));
      } else {
        l
          ..moveTo((x + 8) * s, (y1 + 15) * s)
          ..cubicTo((x + 24) * s, (y1 + 10) * s, (x + 34) * s, (y1 + 10) * s, (x + 48) * s, (y1 + 14) * s);
        canvas.drawPath(l, fin..color = Color.fromRGBO(255, 255, 255, .35 * a));
        final l2 = Path()
          ..moveTo((x + 70) * s, (y1 + 17) * s)
          ..cubicTo((x + 84) * s, (y1 + 13) * s, (x + 96) * s, (y1 + 13) * s, (x + 110) * s, (y1 + 16) * s);
        canvas.drawPath(l2, fin..color = Color.fromRGBO(255, 255, 255, .28 * a));
      }
    }
    final p2 = Path();
    _rad(p2, _t2, x2, y2, w, s, opp: opp, lukk: false);
    canvas.drawPath(
      p2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s
        ..color = Color.fromRGBO(92, 224, 184, .35 * a),
    );
  }

  @override
  bool shouldRepaint(covariant _Skum oldDelegate) => true;
}
