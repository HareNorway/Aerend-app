import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../kit/sjo_water.dart';
import 'fiske_frame.dart';
import 'fiske_game.dart';

/// The rod, the line, the float, the rings and the drops — the prototype's
/// `svg[data-ffs]` (390 × 844, z-index 5) driven by `ffStart()` (L16296),
/// ported frame for frame: the float hangs from the tip and sways while
/// Ægil waits (`klar`), flies out on the cast and settles with a splash and
/// rings (`venter`, nibbling now and then), jerks and tugs on the bite
/// (`napp`), swings back up with the catch (`fangst`) or drifts slack
/// (`mistet`). The rod bends with each move.
///
/// The prototype also drops ripples into the WebGL water at the float
/// (`sjoGlTegn`, `DX 152 / DY 208` in the water's px): [ripples] receives
/// them here.
class FiskeStang extends StatefulWidget {
  const FiskeStang({super.key, required this.phase, this.ripples});

  final FiskePhase phase;
  final SjoRipples? ripples;

  @override
  State<FiskeStang> createState() => _FiskeStangState();
}

class _Ring {
  _Ring(this.x, this.s, this.f, this.color);
  final double x, s, f;
  final Color color;
}

class _Drop {
  _Drop(this.x, this.y, this.vx, this.vy, this.f, this.r);
  final double x, y, vx, vy, f, r;
}

/// One frame of the drawing (design px).
class FiskeStangFrame {
  double bx = 152, wl = 432, boff = 0, tilt = 0, iv = 1;
  double bsx = 298, bsy = 254;
  Offset tip = Offset.zero, ctrl = Offset.zero, dir = Offset.zero;
  Offset a = Offset.zero, c1 = Offset.zero, c2 = Offset.zero;
  List<({double x, double rx, double sw, double op, Color color})> rings = const [];
  List<({Offset p, double r})> drops = const [];
}

class _FiskeStangState extends State<FiskeStang> with SingleTickerProviderStateMixin {
  static const double wl0 = 432, rx0 = 152, bsx = 298, bsy = 254, len = 44;

  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<FiskeStangFrame> _frame = ValueNotifier(FiskeStangFrame());
  final math.Random _rng = math.Random();

  // `S` in the prototype.
  String? _ph;
  double _t0 = 0;
  ({String? ph, double bx, double by, double off})? _fra;
  double _bx = rx0, _by = wl0, _off = 0;
  final List<_Ring> _rings = [];
  final List<_Drop> _drops = [];
  double _nibT = 0, _nib = -9, _tug = -9, _tugT = 0, _ringT = 0;
  bool _plasket = false;

  // The water's ripples (`sjoGlTegn`).
  String? _vFase;
  double _vPlask = 0, _vNeste = 0;

  double _t = 0;
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  String get _f => switch (widget.phase) {
    FiskePhase.klar => 'klar',
    FiskePhase.venter => 'venter',
    FiskePhase.napp => 'napp',
    FiskePhase.fangst => 'fangst',
    FiskePhase.mistet => 'mistet',
  };

  static double _cl(double x) => x.clamp(0.0, 1.0);
  static double _seg(double x, double a, double b) => _cl((x - a) / (b - a));
  static double _lerp(double a, double b, double k) => a + (b - a) * k;
  static double _oc(double x) => 1 - math.pow(1 - x, 3).toDouble();
  static double _io(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;
  static double _fj(double x) => x < 0 ? 0 : math.exp(-4.2 * x) * math.cos(13 * x);

  double _wl(double x, double t) => wl0 + math.sin(t * 2.1 + x * .03) * 1.3 + math.sin(t * 3.4 + x * .07) * .6;

  ({double x, double y, double cx, double cy, double dx, double dy}) _tipAt(double aa, double bb) {
    final r = aa * math.pi / 180, dx = -math.cos(r), dy = -math.sin(r), nx = -math.sin(r), ny = math.cos(r);
    return (
      x: bsx + dx * len + nx * bb * .9,
      y: bsy + dy * len + ny * bb * .9,
      cx: bsx + dx * len * .55 + nx * bb * .35,
      cy: bsy + dy * len * .55 + ny * bb * .35,
      dx: dx,
      dy: dy,
    );
  }

  void _ring(double x, double s, double t, [Color c = const Color.fromRGBO(230, 248, 252, .9)]) => _rings.add(_Ring(x, s, t, c));

  void _sprut(double x, double y, int n, double kraft, double t) {
    for (var i = 0; i < n; i++) {
      _drops.add(_Drop(x, y, (_rng.nextDouble() - .5) * 60 * kraft, -(40 + _rng.nextDouble() * 70) * kraft, t, .8 + _rng.nextDouble() * 1.1));
    }
  }

  void _tick(Duration e) {
    // The reduced-motion frame: the float hanging still from the tip.
    _t = _reduce ? 0 : e.inMicroseconds / 1e6;
    final t = _t, f = _f;
    if (f != _ph) {
      _fra = (ph: _ph, bx: _bx, by: _by, off: _off);
      _ph = f;
      _t0 = t;
      _plasket = false;
    }
    final el = t - _t0;
    double a = 38, bend = 0, bx = rx0, by = _wl(rx0, t), off = 0, tilt = 0, sag = .26;
    ({double x, double y}) heng(double aa) {
      final tp = _tipAt(aa, 0);
      return (x: tp.x + math.sin(t * 1.6) * 2.6, y: tp.y + 34);
    }

    if (f == 'klar' || (f == 'fangst' && el >= .8)) {
      a = 38 + math.sin(t * 1.1) * 1.4;
      final h = heng(a);
      final fr = f == 'klar' && _fra != null && (_fra!.ph == 'venter' || _fra!.ph == 'mistet' || _fra!.ph == 'napp') ? _fra : null;
      if (fr != null && el < .75) {
        final k = _io(_seg(el, 0, .75));
        bx = _lerp(fr.bx, h.x, k);
        by = _lerp(fr.by + fr.off, h.y, k) - math.sin(k * math.pi) * 22;
        a += math.sin(k * math.pi) * 12;
        sag = .04;
        tilt = -24 * math.sin(k * math.pi);
        if (!_plasket && el > .08) {
          _plasket = true;
          _sprut(fr.bx, _wl(fr.bx, t) - 4, 5, .7, t);
          _ring(fr.bx, .8, t);
        }
      } else {
        bx = h.x;
        by = h.y;
        sag = 0;
        tilt = math.sin(t * 1.6 + .8) * 7;
      }
    } else if (f == 'venter') {
      final tp0 = _tipAt(38, 0);
      final h0 = (x: tp0.x, y: tp0.y + 34);
      if (el < .3) {
        a = _lerp(38, 64, _io(_seg(el, 0, .3)));
        bend = 3 * _seg(el, 0, .3);
      } else if (el < .48) {
        final k = _oc(_seg(el, .3, .48));
        a = _lerp(64, 16, k);
        bend = -9 * math.sin(k * math.pi);
      } else {
        a = 26 - 10 * _fj(el - .48);
      }
      if (el < .34) {
        final h = heng(a);
        bx = h.x;
        by = h.y;
        sag = 0;
        tilt = -20 * _seg(el, 0, .3);
      } else if (el < .92) {
        final k = _seg(el, .34, .92), kk = _oc(k);
        bx = _lerp(h0.x - 6, rx0, kk);
        by = _lerp(h0.y - 20, _wl(rx0, t), k) - math.sin(k * math.pi) * 92;
        sag = .03 + .1 * k;
        tilt = _lerp(-50, 0, k);
      } else {
        if (!_plasket) {
          _plasket = true;
          _ring(rx0, 1.25, t);
          _ring(rx0, .8, t);
          _sprut(rx0, _wl(rx0, t) - 3, 8, 1, t);
          _nibT = t + 1.4;
        }
        off = 10 * _fj(el - .92) + math.sin(t * 2.6) * .7;
        tilt = math.sin(t * 1.9) * 5 + 14 * _fj(el - .92);
        if (t > _nibT) {
          _nibT = t + 1.2 + _rng.nextDouble() * 2;
          _nib = t;
          _ring(rx0, .45, t);
        }
        final nb = t - _nib;
        if (nb < .26) off += 3.6 * math.sin(nb / .26 * math.pi);
        sag = .3 + math.sin(t * .9) * .03;
      }
      if (el >= .92) by = _wl(rx0, t);
    } else if (f == 'napp') {
      if (t > _tugT) {
        _tugT = t + .32 + _rng.nextDouble() * .38;
        _tug = t;
        _ring(bx, .7, t, const Color.fromRGBO(255, 148, 102, .95));
        if (_rng.nextDouble() < .5) _sprut(_bx, _wl(_bx, t) - 2, 3, .55, t);
      }
      final tg = t - _tug, puls = tg < .22 ? math.sin(tg / .22 * math.pi) : 0.0;
      bx = rx0 + math.sin(t * 2.7) * 5 + math.sin(t * 7.3) * 1.4 - puls * 3;
      by = _wl(bx, t);
      off = 7 + math.sin(t * 17) * 2.2 + puls * 7;
      tilt = 12 + math.sin(t * 13) * 16 + puls * 10;
      a = 22 - puls * 6 + math.sin(t * 9) * 1.5;
      bend = 9 + puls * 6 + math.sin(t * 11) * 2;
      sag = .015;
      if (t > _ringT) {
        _ringT = t + .26;
        _ring(bx, .5, t);
      }
    } else if (f == 'fangst') {
      final fr = _fra ?? (ph: null, bx: rx0, by: wl0, off: 6.0);
      final k = _io(_seg(el, 0, .8)), h = heng(38);
      bx = _lerp(fr.bx, h.x, k);
      by = _lerp(fr.by + fr.off, h.y, k * k) - math.sin(k * math.pi) * 26;
      a = 38 + math.sin(k * math.pi) * 20;
      bend = 7 * (1 - k);
      sag = .02;
      tilt = -30 * math.sin(k * math.pi);
      if (!_plasket && el > .12) {
        _plasket = true;
        _sprut(fr.bx, _wl(fr.bx, t) - 4, 10, 1.15, t);
        _ring(fr.bx, 1.1, t);
        _ring(fr.bx, .6, t);
      }
    } else if (f == 'mistet') {
      final fr = _fra ?? (ph: null, bx: rx0, by: wl0, off: 0.0);
      bx = fr.bx + math.min(6, el * 3);
      by = _wl(bx, t);
      off = -5 * _fj(el) + math.sin(t * 2.4) * .8;
      tilt = math.sin(t * 1.7) * 9 + 20 * _fj(el);
      a = 32 + 10 * _fj(el);
      sag = .62 - .2 * _cl(el);
      if (!_plasket) {
        _plasket = true;
        _ring(bx, .7, t);
      }
    }
    _bx = bx;
    _by = by;
    _off = off;

    _vann(f, t);

    final wl = _wl(bx, t), boff = by - wl + off, tr = tilt * math.pi / 180;
    final tp = _tipAt(a, bend);
    final ax = bx + math.sin(tr) * 23, ay = wl + boff - 3 - math.cos(tr) * 20;
    final ddx = ax - tp.x, ddy = ay - tp.y, d = math.sqrt(ddx * ddx + ddy * ddy), wind = math.sin(t * 1.3) * 2.4 * _cl(d / 120);

    _rings.removeWhere((r) => (t - r.f) / (1.25 * r.s) >= 1);
    _drops.removeWhere((dr) {
      final g = t - dr.f, x = dr.x + dr.vx * g, y = dr.y + dr.vy * g + 160 * g * g;
      if (g > .12 && y > _wl(x, t)) {
        _ring(x, .22, t);
        return true;
      }
      return false;
    });

    final fr = FiskeStangFrame()
      ..bx = bx
      ..wl = wl
      ..boff = boff
      ..tilt = tilt
      ..iv = _cl(1 - boff.abs() / 14)
      ..tip = Offset(tp.x, tp.y)
      ..ctrl = Offset(tp.cx, tp.cy)
      ..dir = Offset(tp.dx, tp.dy)
      ..a = Offset(ax, ay)
      ..c1 = Offset(tp.x + ddx * .33 + wind * .4, tp.y + ddy * .33 + sag * d * .5)
      ..c2 = Offset(tp.x + ddx * .7 + wind * .7, tp.y + ddy * .7 + sag * d * .42)
      ..rings = [
        for (final r in _rings)
          () {
            final age = (t - r.f) / (1.25 * r.s);
            return (x: r.x, rx: (3 + age * 30) * r.s, sw: 1.3 - age * .7, op: math.pow(1 - age, 1.4) * .85, color: r.color);
          }(),
      ]
      ..drops = [
        for (final dr in _drops)
          (p: Offset(dr.x + dr.vx * (t - dr.f), dr.y + dr.vy * (t - dr.f) + 160 * (t - dr.f) * (t - dr.f)), r: dr.r),
      ];
    _frame.value = fr;
    if (_reduce && _ticker.isActive) _ticker.stop();
  }

  /// `sjoGlTegn`'s fishing ripples in the water (its px: `DX 152`, `DY 208`).
  void _vann(String f, double t) {
    final r = widget.ripples;
    if (r == null) return;
    if (f != _vFase) {
      if (f == 'venter') _vPlask = t + .48;
      if (f == 'fangst') r.add(152, 208, 2);
      _vFase = f;
      _vNeste = t + 1.4;
    }
    if (_vPlask > 0 && t > _vPlask) {
      _vPlask = 0;
      r.add(152, 208, 1.8);
    }
    if ((f == 'venter' || f == 'napp') && t > _vNeste) {
      _vNeste = t + (f == 'napp' ? .42 : 2.4);
      r.add(152, 208, f == 'napp' ? .9 : .4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fr = FiskeFrame.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _StangPainter(_frame, s: fr.s, top: fr.safeTop, hoyre: fr.width - 390 * fr.s),
        ),
      ),
    );
  }
}

class _StangPainter extends CustomPainter {
  _StangPainter(this.frame, {required this.s, required this.top, required this.hoyre}) : super(repaint: frame);

  final ValueNotifier<FiskeStangFrame> frame;
  final double s, top;

  /// How much wider the screen is than the scaled frame. Ægil and the pier
  /// hold the right edge, the water's middle the left: a point is moved
  /// right by this in proportion to how far it is from the float's spot in
  /// the water (152) towards the rod's foot (298), so the line stays joined.
  final double hoyre;

  Offset _p(double x, double y) => Offset(x * s + hoyre * ((x - 152) / 146).clamp(0.0, 1.0), top + y * s);

  static const _orange = RadialGradient(
    center: Alignment(-.3, -.5),
    radius: .85,
    colors: [Color(0xFFFFC2A6), Color(0xFFF26D3D), Color(0xFFB23E14)],
    stops: [0, .5, 1],
  );
  static const _hvit = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFC9D6DB)]);

  static final Path _topp = Path()
    ..moveTo(0, -15)
    ..cubicTo(7.5, -15, 9.6, -7, 9.6, -3.4)
    ..lineTo(-9.6, -3.4)
    ..cubicTo(-9.6, -7, -7.5, -15, 0, -15)
    ..close();
  static final Path _bunn = Path()
    ..moveTo(-9.6, -3.4)
    ..lineTo(9.6, -3.4)
    ..cubicTo(9.6, 2.6, 5.4, 6.4, 0, 6.4)
    ..cubicTo(-5.4, 6.4, -9.6, 2.6, -9.6, -3.4)
    ..close();
  static final Path _skygge = Path()
    ..moveTo(3, -13.6)
    ..cubicTo(7.5, -12, 9.6, -7, 9.6, -3.4)
    ..cubicTo(9.6, 2.6, 6.6, 5.6, 3.4, 6.2)
    ..cubicTo(6, 3, 6.6, -6, 3, -13.6)
    ..close();
  static final Path _hel = Path()
    ..moveTo(0, -15)
    ..cubicTo(7.5, -15, 9.6, -7, 9.6, -3.4)
    ..cubicTo(9.6, 2.6, 5.4, 6.4, 0, 6.4)
    ..cubicTo(-5.4, 6.4, -9.6, 2.6, -9.6, -3.4)
    ..cubicTo(-9.6, -7, -7.5, -15, 0, -15)
    ..close();

  /// The float's body (`k1` / `k2`).
  void _kropp(Canvas c, {required bool under}) {
    if (!under) {
      c.drawLine(const Offset(0, -15), const Offset(0, -23), Paint()
        ..color = Colors.white
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round);
      c.drawCircle(const Offset(0, -24), 4.2, Paint()..color = const Color.fromRGBO(255, 148, 102, .35));
      c.drawCircle(const Offset(0, -24), 1.9, Paint()..color = const Color(0xFFFF9466));
    }
    c.drawPath(_topp, Paint()..shader = _orange.createShader(_topp.getBounds()));
    c.drawPath(_bunn, Paint()..shader = _hvit.createShader(_bunn.getBounds()));
    c.drawRect(const Rect.fromLTWH(-9.6, -4.2, 19.2, 1.6), Paint()..color = const Color(0xFFB23E14));
    c.drawPath(_skygge, Paint()..color = const Color.fromRGBO(20, 30, 40, .18));
    c.save();
    c.translate(-3.6, -9.6);
    c.rotate(-18 * math.pi / 180);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 4.4, height: 6.8), Paint()..color = const Color.fromRGBO(255, 255, 255, .75));
    c.restore();
    if (under) c.drawPath(_hel, Paint()..color = const Color.fromRGBO(30, 96, 116, .55));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame.value;

    // Rings on the water (their width scales; their centre follows _p).
    for (final r in f.rings) {
      canvas.drawOval(
        Rect.fromCenter(center: _p(r.x, 432 + 1.5), width: r.rx * 2 * s, height: r.rx * .6 * s),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.sw * s
          ..color = r.color.withValues(alpha: r.color.a * r.op),
      );
    }

    // The line.
    final tip = _p(f.tip.dx, f.tip.dy);
    final c1 = _p(f.c1.dx, f.c1.dy), c2 = _p(f.c2.dx, f.c2.dy), an = _p(f.a.dx, f.a.dy);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, an.dx, an.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .95 * s
        ..strokeCap = StrokeCap.round
        ..color = const Color.fromRGBO(255, 255, 255, .88),
    );

    // The float at (bx, wl): shadow, the part under water, the part over it,
    // the waterline.
    canvas.save();
    final o = _p(f.bx, f.wl);
    canvas.translate(o.dx, o.dy);
    canvas.scale(s);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 2.4), width: 22, height: 6), Paint()..color = Color.fromRGBO(3, 14, 20, .4 * f.iv));
    void kt(Canvas c) {
      c.translate(0, f.boff);
      c.translate(0, -3);
      c.rotate(f.tilt * math.pi / 180);
      c.translate(0, 3);
    }

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(-80, 0, 160, 80));
    canvas.saveLayer(const Rect.fromLTWH(-80, -80, 160, 160), Paint()..color = const Color.fromRGBO(0, 0, 0, .42));
    kt(canvas);
    _kropp(canvas, under: true);
    canvas.restore();
    canvas.restore();

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(-80, -3000, 160, 3000));
    kt(canvas);
    _kropp(canvas, under: false);
    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(-10.5, 0)
        ..quadraticBezierTo(0, 2.6, 10.5, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(226, 248, 252, .9 * f.iv),
    );
    canvas.restore();

    // The rod, its handle and tip.
    final bs = _p(298, 254), ctrl = _p(f.ctrl.dx, f.ctrl.dy);
    final rod = Path()
      ..moveTo(bs.dx, bs.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
    canvas.drawPath(
      rod,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF5A3A1C), Color(0xFF8A5A2C), Color(0xFFE9D2A4)],
          stops: [0, .35, 1],
        ).createShader(rod.getBounds().inflate(.01)),
    );
    canvas.drawLine(
      Offset(bs.dx - f.dir.dx * 4 * s, bs.dy - f.dir.dy * 4 * s),
      Offset(bs.dx + f.dir.dx * 11 * s, bs.dy + f.dir.dy * 11 * s),
      Paint()
        ..strokeWidth = 3.6 * s
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A2410),
    );
    canvas.drawCircle(tip, 1.3 * s, Paint()..color = const Color(0xFFFFE2D2));

    final dp = Paint()..color = const Color(0xFFE2F6FA);
    for (final d in f.drops) {
      canvas.drawCircle(_p(d.p.dx, d.p.dy), d.r * s, dp);
    }
  }

  @override
  bool shouldRepaint(_StangPainter old) => old.s != s || old.top != top || old.hoyre != hoyre;
}
