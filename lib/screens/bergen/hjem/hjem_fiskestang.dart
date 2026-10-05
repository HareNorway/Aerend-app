import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ── Ægil's rod on the quay (`svg[data-aefs]`, prototype `afStart`) ──────────
// A 160×120 box. One 15 s cycle: the bobber floats with nibbles (0–10.9 s),
// fights a tug (10.9–12.5), is reeled in (12.5–13.3), hangs from the tip
// (13.3–14.1) and is cast again (14.1–15). Rings and drops are spawned the
// way the prototype does; splashes ripple the water through [onWater].
// When a float is selected the line runs to it ([hook], box px).

/// Absolute-command SVG path (M L H V C Q Z) — enough for the bobber art.
Path svgPath(String d) {
  final p = Path();
  final tok = RegExp(r'[MLHVCQZmlhvcqz]|-?\d*\.?\d+(?:e-?\d+)?').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  double cx = 0, cy = 0;
  String cmd = 'M';
  double n() => double.parse(tok[i++]);
  while (i < tok.length) {
    if (RegExp(r'[A-Za-z]').hasMatch(tok[i])) cmd = tok[i++];
    switch (cmd) {
      case 'M':
        cx = n();
        cy = n();
        p.moveTo(cx, cy);
        cmd = 'L';
      case 'L':
        cx = n();
        cy = n();
        p.lineTo(cx, cy);
      case 'H':
        cx = n();
        p.lineTo(cx, cy);
      case 'V':
        cy = n();
        p.lineTo(cx, cy);
      case 'C':
        final a = n(), b = n(), c = n(), d2 = n();
        cx = n();
        cy = n();
        p.cubicTo(a, b, c, d2, cx, cy);
      case 'Q':
        final a = n(), b = n();
        cx = n();
        cy = n();
        p.quadraticBezierTo(a, b, cx, cy);
      case 'Z':
      case 'z':
        p.close();
      default:
        i++;
    }
  }
  return p;
}

class HjemFiskestang extends StatefulWidget {
  const HjemFiskestang({super.key, this.hook, this.selectedAt, this.onWater});

  /// Where the line hooks the selected float (box px), or null.
  final Offset? hook;

  /// When the float was selected (for the cast-to-it motion).
  final DateTime? selectedAt;

  /// A splash at (box x, box y) with amplitude — ripple the water there.
  final void Function(double x, double y, double a)? onWater;

  @override
  State<HjemFiskestang> createState() => _HjemFiskestangState();
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

class _HjemFiskestangState extends State<HjemFiskestang> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _repaint = ValueNotifier(0);
  final math.Random _rnd = math.Random();

  static const double wl0 = 71, rx0 = 50, bsx = 100, bsy = 62, len = 46, sk = .66;

  final List<_Ring> _rings = [];
  final List<_Drop> _drops = [];
  double _nibT = 0, _nib = -9, _tug = -9, _tugT = 0, _base = 0, _vT = 0, _ripT = 0;
  int _sist = -1, _splash = -1, _opp = -1;
  bool? _vSist;
  double _t = 0;
  bool _started = false;

  // Frame values for the painter.
  double _a = 40, _bend = 0, _bx = rx0, _wl = wl0, _boff = 0, _tilt = 0, _ax = 0, _ay = 0, _sag = .3, _iv = 1;
  bool _hidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      _frame(3.0);
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  static double _cl(double x) => x.clamp(0.0, 1.0);
  static double _seg(double x, double a, double b) => _cl((x - a) / (b - a));
  static double _lerp(double a, double b, double k) => a + (b - a) * k;
  static double _oc(double x) => 1 - math.pow(1 - x, 3).toDouble();
  static double _io(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  static double _fj(double x) => x < 0 ? 0 : math.exp(-4.2 * x) * math.cos(13 * x);

  double _wlAt(double x, double t) => wl0 + math.sin(t * 2.1 + x * .05) * .8 + math.sin(t * 3.4 + x * .09) * .4;

  void _ring(double x, double s, [Color c = const Color.fromRGBO(230, 248, 252, .9)]) => _rings.add(_Ring(x, s, _t, c));

  void _sprut(double x, double y, int n, double k) {
    for (var i = 0; i < n; i++) {
      _drops.add(_Drop(x, y, (_rnd.nextDouble() - .5) * 40 * k, -(26 + _rnd.nextDouble() * 44) * k, _t, .6 + _rnd.nextDouble() * .7));
    }
  }

  void _vann(double a) => widget.onWater?.call(_bx, _wl, a);

  ({double x, double y, double cx, double cy}) _tipAt(double aa, double bb) {
    final r = aa * math.pi / 180, dx = -math.cos(r), dy = -math.sin(r), nx = -math.sin(r), ny = math.cos(r);
    return (
      x: bsx + dx * len + nx * bb * .9,
      y: bsy + dy * len + ny * bb * .9,
      cx: bsx + dx * len * .55 + nx * bb * .35,
      cy: bsy + dy * len * .55 + ny * bb * .35,
    );
  }

  void _tick(Duration e) {
    _frame(e.inMicroseconds / 1e6);
    _repaint.value = _t;
  }

  void _frame(double now) {
    final t = now;
    _t = t;
    if (!_started) {
      _started = true;
      _base = t - 3;
    }
    final valgt = widget.hook != null;
    if (valgt != (_vSist ?? false)) {
      if ((_vSist ?? false) && !valgt) _base = t - 14.1;
      _vSist = valgt;
      _vT = t;
    }
    final c = ((t - _base) % 15 + 15) % 15;
    final syk = ((t - _base) / 15).floor();
    double a = 40 + math.sin(t * 1.1) * 1.2, bend = 0, bx = rx0, by = _wlAt(rx0, t), off = 0;
    double tilt = math.sin(t * 1.9) * 5, sag = .3 + math.sin(t * .9) * .04;
    if (_sist != syk) {
      _sist = syk;
      _splash = -1;
      _opp = -1;
      _nibT = t + 1;
    }
    if (c < 10.9) {
      off = 8 * _fj(c) + math.sin(t * 2.6) * .6;
      tilt += 12 * _fj(c);
      if (c > .02 && _splash < 0 && syk > 0) {
        _splash = 1;
        _ring(rx0, 1.1);
        _ring(rx0, .7);
        _sprut(rx0, _wlAt(rx0, t) - 2, 6, 1);
        _vann(.6);
      }
      if (t > _nibT && c > 1.2) {
        _nibT = t + 1.3 + _rnd.nextDouble() * 1.8;
        _nib = t;
        _ring(rx0, .4);
      }
      final nb = t - _nib;
      if (nb < .26) off += 3 * math.sin(nb / .26 * math.pi);
    } else if (c < 12.5) {
      if (t > _tugT) {
        _tugT = t + .3 + _rnd.nextDouble() * .34;
        _tug = t;
        _ring(bx, .6, const Color.fromRGBO(255, 148, 102, .95));
        _vann(.35);
        if (_rnd.nextDouble() < .5) _sprut(rx0, _wlAt(rx0, t) - 1, 2, .5);
      }
      final tg = t - _tug, p = tg < .2 ? math.sin(tg / .2 * math.pi) : 0.0;
      bx = rx0 + math.sin(t * 2.7) * 3 - p * 2;
      by = _wlAt(bx, t);
      off = 6 + math.sin(t * 17) * 1.6 + p * 6;
      tilt = 10 + math.sin(t * 13) * 14 + p * 8;
      a = 26 - p * 5 + math.sin(t * 9) * 1.2;
      bend = 7 + p * 5;
      sag = .015;
    } else if (c < 13.3) {
      final k = _io(_seg(c, 12.5, 13.3)), tp = _tipAt(40, 0), hx = tp.x + 1, hy = tp.y + 26;
      bx = _lerp(rx0, hx, k);
      by = _lerp(_wlAt(rx0, t) + 6, hy, k * k) - math.sin(k * math.pi) * 14;
      a = 40 + math.sin(k * math.pi) * 18;
      bend = 5 * (1 - k);
      sag = .02;
      tilt = -26 * math.sin(k * math.pi);
      if (_opp < 0 && c > 12.58) {
        _opp = 1;
        _sprut(rx0, _wlAt(rx0, t) - 3, 8, 1);
        _ring(rx0, .9);
        _vann(.5);
      }
    } else if (c < 14.1) {
      final tp = _tipAt(a, 0);
      bx = tp.x + math.sin(t * 1.6) * 2;
      by = tp.y + 26;
      sag = 0;
      tilt = math.sin(t * 1.6 + .8) * 7;
    } else {
      final e = c - 14.1, tp0 = _tipAt(40, 0);
      if (e < .3) {
        a = _lerp(40, 66, _io(_seg(e, 0, .3)));
      } else if (e < .48) {
        final k = _oc(_seg(e, .3, .48));
        a = _lerp(66, 20, k);
        bend = -7 * math.sin(k * math.pi);
      } else {
        a = 30 - 10 * _fj(e - .48);
      }
      if (e < .34) {
        final tp = _tipAt(a, 0);
        bx = tp.x;
        by = tp.y + 26;
        sag = 0;
        tilt = -18 * _seg(e, 0, .3);
      } else {
        final k = _seg(e, .34, .9);
        bx = _lerp(tp0.x - 4, rx0, _oc(k));
        by = _lerp(tp0.y + 10, _wlAt(rx0, t), k) - math.sin(k * math.pi) * 46;
        sag = .03 + .12 * k;
        tilt = _lerp(-46, 0, k);
      }
    }
    final krok = widget.hook;
    if (valgt) {
      final e = t - _vT;
      if (e < .22) {
        a = _lerp(40, 64, _io(_seg(e, 0, .22)));
      } else if (e < .36) {
        a = _lerp(64, 30, _oc(_seg(e, .22, .36)));
      } else {
        a = 32 + math.sin(t * 7) * 1.1 - 4 * _fj(e - .36);
      }
      bend = e < .36
          ? (e > .22 ? -6 * math.sin(_seg(e, .22, .36) * math.pi) : 0)
          : (e < 1.15 ? 9 + math.sin(t * 10) * 1.6 : 4 + math.sin(t * 2) * .8);
      if (krok != null && e > .36 && e < 1.15 && t > _ripT) {
        _ripT = t + .2;
        widget.onWater?.call(krok.dx, krok.dy, .32);
      }
    }
    final wl = _wlAt(bx, t), boff = (by - wl) / sk + off, tr = tilt * math.pi / 180;
    final tp = _tipAt(a, bend);
    var ax = bx + math.sin(tr) * 23 * sk, ay = wl + (boff - 3 - math.cos(tr) * 20) * sk;
    if (krok != null) {
      final e = t - _vT, k = _oc(_seg(e, .1, .38));
      ax = _lerp(tp.x, krok.dx, k);
      ay = _lerp(tp.y, krok.dy, k) - math.sin(k * math.pi) * 16;
      sag = e < .38 ? .08 : .02;
    }
    _rings.removeWhere((r) => (t - r.f) / (1.2 * r.s) >= 1);
    _drops.removeWhere((d) {
      final g = t - d.f, x = d.x + d.vx * g, y = d.y + d.vy * g + 140 * g * g;
      if (g > .1 && y > _wlAt(x, t)) {
        _ring(x, .18);
        return true;
      }
      return false;
    });
    _a = a;
    _bend = bend;
    _bx = bx;
    _wl = wl;
    _boff = boff;
    _tilt = tilt;
    _ax = ax;
    _ay = ay;
    _sag = sag;
    _iv = _cl(1 - _boff.abs() / 14);
    _hidden = krok != null;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(160, 120),
        painter: _StangPainter(this, _repaint),
      ),
    );
  }
}

class _StangPainter extends CustomPainter {
  _StangPainter(this.s, Listenable repaint) : super(repaint: repaint);

  final _HjemFiskestangState s;

  static final Path _cap = svgPath('M0 -15 C7.5 -15 9.6 -7 9.6 -3.4 L-9.6 -3.4 C-9.6 -7 -7.5 -15 0 -15 Z');
  static final Path _bottom = svgPath('M-9.6 -3.4 L9.6 -3.4 C9.6 2.6 5.4 6.4 0 6.4 C-5.4 6.4 -9.6 2.6 -9.6 -3.4 Z');
  static final Path _shade = svgPath('M3 -13.6 C7.5 -12 9.6 -7 9.6 -3.4 C9.6 2.6 6.6 5.6 3.4 6.2 C6 3 6.6 -6 3 -13.6 Z');
  static final Path _whole = svgPath(
    'M0 -15 C7.5 -15 9.6 -7 9.6 -3.4 C9.6 2.6 5.4 6.4 0 6.4 C-5.4 6.4 -9.6 2.6 -9.6 -3.4 C-9.6 -7 -7.5 -15 0 -15 Z',
  );
  static final Path _waterline = svgPath('M-10.5 0 Q0 2.6 10.5 0');

  static final Shader _orange = ui.Gradient.radial(
    // objectBoundingBox of the cap (19.2 × 11.6).
    const Offset(-9.6 + .35 * 19.2, -15 + .25 * 11.6),
    .85 * 19.2,
    const [Color(0xFFFFC2A6), Color(0xFFF26D3D), Color(0xFFB23E14)],
    const [0, .5, 1],
  );
  static final Shader _white = ui.Gradient.linear(
    const Offset(-9.6, -3.4),
    const Offset(9.6, 6.4),
    const [Color(0xFFFFFFFF), Color(0xFFC9D6DB)],
  );

  void _bobber(Canvas c, {required bool over}) {
    if (over) {
      c.drawLine(
        const Offset(0, -15),
        const Offset(0, -23),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(const Offset(0, -24), 2, Paint()..color = const Color(0xFFFF9466));
      c.drawCircle(const Offset(0, -24), 4.4, Paint()..color = const Color.fromRGBO(255, 148, 102, .35));
    }
    c.drawPath(_cap, Paint()..shader = _orange);
    c.drawPath(_bottom, Paint()..shader = _white);
    c.drawRect(const Rect.fromLTWH(-9.6, -4.2, 19.2, 1.6), Paint()..color = const Color(0xFFB23E14));
    c.drawPath(_shade, Paint()..color = const Color.fromRGBO(20, 30, 40, .18));
    c.save();
    c.translate(-3.6, -9.6);
    c.rotate(-18 * math.pi / 180);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 4.4, height: 6.8), Paint()..color = const Color.fromRGBO(255, 255, 255, .75));
    c.restore();
    if (!over) c.drawPath(_whole, Paint()..color = const Color.fromRGBO(30, 96, 116, .55));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._t;
    // Rings (`ringer`).
    for (final r in s._rings) {
      final age = (t - r.f) / (1.2 * r.s);
      if (age < 0 || age >= 1) continue;
      final rx = (2 + age * 20) * r.s;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(r.x, _HjemFiskestangState.wl0 + 1), width: rx * 2, height: rx * .6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 - age * .5
          ..color = r.color.withValues(alpha: r.color.a * (math.pow(1 - age, 1.4) * .85)),
      );
    }
    // Line (`snor`).
    final tp = s._tipAt(s._a, s._bend);
    final ddx = s._ax - tp.x, ddy = s._ay - tp.y, d = math.sqrt(ddx * ddx + ddy * ddy);
    final wind = math.sin(t * 1.3) * 1.6 * (d / 60).clamp(0.0, 1.0);
    canvas.drawPath(
      Path()
        ..moveTo(tp.x, tp.y)
        ..cubicTo(
          tp.x + ddx * .33 + wind * .4,
          tp.y + ddy * .33 + s._sag * d * .5,
          tp.x + ddx * .7 + wind * .7,
          tp.y + ddy * .7 + s._sag * d * .42,
          s._ax,
          s._ay,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..strokeCap = StrokeCap.round
        ..color = const Color.fromRGBO(255, 255, 255, .85),
    );
    // Bobber (`dupp`): translate(bx wl) scale(.66).
    if (!s._hidden) {
      canvas.save();
      canvas.translate(s._bx, s._wl);
      canvas.scale(_HjemFiskestangState.sk);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 2.4), width: 22, height: 6),
        Paint()..color = Color.fromRGBO(3, 14, 20, .4 * s._iv),
      );
      void kt() {
        canvas.translate(0, s._boff);
        canvas.translate(0, -3);
        canvas.rotate(s._tilt * math.pi / 180);
        canvas.translate(0, 3);
      }

      // Under water (clip y 0..40, opacity .42).
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(-60, 0, 120, 40));
      canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, .42));
      kt();
      _bobber(canvas, over: false);
      canvas.restore();
      canvas.restore();
      // Over water (clip y < 0).
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(-60, -2000, 120, 2000));
      kt();
      _bobber(canvas, over: true);
      canvas.restore();
      canvas.drawPath(
        _waterline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = Color.fromRGBO(226, 248, 252, .9 * s._iv),
      );
      canvas.restore();
    }
    // Rod (`stang`) with `afStang` (objectBoundingBox 1,1 → 0,0) and tip.
    final rod = Path()
      ..moveTo(_HjemFiskestangState.bsx, _HjemFiskestangState.bsy)
      ..quadraticBezierTo(tp.cx, tp.cy, tp.x, tp.y);
    final b = rod.getBounds();
    canvas.drawPath(
      rod,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          b.bottomRight,
          b.topLeft,
          const [Color(0xFF4A2E14), Color(0xFF8A5A2C), Color(0xFFE9D2A4)],
          const [0, .4, 1],
        ),
    );
    canvas.drawCircle(Offset(tp.x, tp.y), 1.1, Paint()..color = const Color(0xFFFFE2D2));
    // Drops (`draaper`).
    final dp = Paint()..color = const Color(0xFFE2F6FA);
    for (final dr in s._drops) {
      final g = t - dr.f;
      canvas.drawCircle(Offset(dr.x + dr.vx * g, dr.y + dr.vy * g + 140 * g * g), dr.r, dp);
    }
  }

  @override
  bool shouldRepaint(_StangPainter old) => true;
}
