import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart';
import '../kit/svg_sti.dart';

part 'adr_tegning.g.dart';

// ── The address scene's drawings ────────────────────────────────────────────
// The prototype draws the street (neighbours, the house, the office, the
// cabin, the dashed "ledig tomt" ghosts, the pin and the small tiles) as
// inline SVG with CSS animations on single windows and lines. The draw lists
// in `adr_tegning.g.dart` are generated from that SVG; [AdrTegning] paints
// one with the animations at time `t` (ms since the scene appeared).

/// A fill or stroke: a colour, a named variable, or one of the scene's
/// gradients.
class AdrFarge {
  const AdrFarge.c(this.argb) : navn = null, grad = null;
  const AdrFarge.v(String this.navn) : argb = 0, grad = null;
  const AdrFarge.g(String this.grad) : argb = 0, navn = null;

  final int argb;
  final String? navn, grad;
}

/// `animation: <navn> <dur>s <delay>s`.
class AdrAnim {
  const AdrAnim(this.navn, this.dur, this.delay);
  final String navn;
  final int dur, delay;
}

enum AdrForm { rect, circle, ellipse, path }

class AdrEl {
  const AdrEl.rect(List<double> this.geo, {this.fill, this.fillOp, this.fillOpVar, this.stroke, this.sw = 1, this.roundJoin = false, this.roundCap = false, this.dash, this.dx = 0, this.dy = 0, this.anim, this.ox = 0, this.oy = 0, this.glid = false})
    : form = AdrForm.rect,
      d = null;
  const AdrEl.circle(List<double> this.geo, {this.fill, this.fillOp, this.fillOpVar, this.stroke, this.sw = 1, this.roundJoin = false, this.roundCap = false, this.dash, this.dx = 0, this.dy = 0, this.anim, this.ox = 0, this.oy = 0, this.glid = false})
    : form = AdrForm.circle,
      d = null;
  const AdrEl.ellipse(List<double> this.geo, {this.fill, this.fillOp, this.fillOpVar, this.stroke, this.sw = 1, this.roundJoin = false, this.roundCap = false, this.dash, this.dx = 0, this.dy = 0, this.anim, this.ox = 0, this.oy = 0, this.glid = false})
    : form = AdrForm.ellipse,
      d = null;
  const AdrEl.path(String this.d, {this.fill, this.fillOp, this.fillOpVar, this.stroke, this.sw = 1, this.roundJoin = false, this.roundCap = false, this.dash, this.dx = 0, this.dy = 0, this.anim, this.ox = 0, this.oy = 0, this.glid = false})
    : form = AdrForm.path,
      geo = null;

  final AdrForm form;
  final List<double>? geo;
  final String? d;
  final AdrFarge? fill, stroke;
  final double? fillOp;
  final String? fillOpVar;
  final double sw, dx, dy, ox, oy;
  final bool roundJoin, roundCap, glid;
  final List<double>? dash;
  final AdrAnim? anim;

  Path get sti {
    final g = geo;
    switch (form) {
      case AdrForm.rect:
        final r = Rect.fromLTWH(g![0], g[1], g[2], g[3]);
        return Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(g[4])));
      case AdrForm.circle:
        return Path()..addOval(Rect.fromCircle(center: Offset(g![0], g[1]), radius: g[2]));
      case AdrForm.ellipse:
        return Path()..addOval(Rect.fromCenter(center: Offset(g![0], g[1]), width: g[2] * 2, height: g[3] * 2));
      case AdrForm.path:
        return _cache[d!] ??= svgSti(d!);
    }
  }

  static final Map<String, Path> _cache = {};
}

/// One drawing and its viewBox.
class AdrBilde {
  const AdrBilde(this.w, this.h, this.els);
  final double w, h;
  final List<AdrEl> els;
}

/// The gradients the scene's SVG defines (objectBoundingBox).
Gradient? _gradient(String id) => switch (id) {
  'adrHusSk' || 'naHusSk' => const LinearGradient(
    colors: [Color.fromRGBO(255, 255, 255, .14), Color.fromRGBO(255, 255, 255, 0), Color.fromRGBO(4, 20, 28, .3)],
    stops: [0, .5, 1],
  ),
  'adrJobbSk' || 'naJobbSk' => const LinearGradient(colors: [Color.fromRGBO(255, 255, 255, .18), Color.fromRGBO(4, 20, 28, .28)]),
  'adrPinG' || 'naPinG2' => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFA77C), Color(0xFFF26D3D), Color(0xFFC9501F)],
    stops: [0, .6, 1],
  ),
  _ => null,
};

/// Paints [bilde] at [size] with the CSS animations at time [t].
class AdrTegning extends StatelessWidget {
  const AdrTegning({super.key, required this.bilde, required this.t, this.vars = const {}, this.ops = const {}, this.stier = const {}, this.width, this.height});

  final AdrBilde bilde;

  /// ms since the scene appeared (entrance delays count from here).
  final double t;
  final Map<String, Color> vars;
  final Map<String, double> ops;

  /// Paths given as `{{ navn }}` in the drawing (the pin's icon).
  final Map<String, String> stier;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width ?? bilde.w, height ?? bilde.h),
      painter: _Maler(bilde, t, vars, ops, stier),
    );
  }
}

class _Maler extends CustomPainter {
  _Maler(this.b, this.t, this.vars, this.ops, this.stier);
  final AdrBilde b;
  final double t;
  final Map<String, Color> vars;
  final Map<String, double> ops;
  final Map<String, String> stier;

  /// Opacity from the element's animation at [t].
  double _op(AdrAnim? a) {
    if (a == null) return 1;
    switch (a.navn) {
      case 'adrLysPaa':
        // fill both; 0,40% 0 · 55% 1 · 68% .35 · 100% 1 (ease)
        final p = ((t - a.delay) / a.dur).clamp(0.0, 1.0);
        return kf(p, const [0, .4, .55, .68, 1], const [0, 0, 1, .35, 1], cssEase);
      case 'adrLys':
        final p = ((t - a.delay) / a.dur) % 1.0;
        return kf(p, const [0, .5, 1], const [1, .55, 1], cssEaseInOut);
      case 'adrBlink':
        if (t < a.delay) return 1;
        final p = ((t - a.delay) / a.dur) % 1.0;
        return kf(p, const [0, .5, 1], const [.25, 1, .25], cssEaseInOut);
    }
    return 1;
  }

  Color _farge(AdrFarge f) => f.navn != null ? (vars[f.navn] ?? const Color(0xFF24434D)) : Color(f.argb);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / b.w, size.height / b.h);
    for (final e in b.els) {
      final op = _op(e.anim);
      if (op <= 0) continue;
      var sti = e.d != null && e.d!.startsWith('{{') ? svgSti(stier[RegExp(r'\w+').firstMatch(e.d!)!.group(0)] ?? '') : e.sti;
      if (e.dx != 0 || e.dy != 0) sti = sti.shift(Offset(e.dx, e.dy));
      canvas.save();
      if (e.anim?.navn == 'adrVimpel') {
        // skewY(0 → -6deg) scaleX(1 → .9) about the flag's pole
        final p = ((t - e.anim!.delay) / e.anim!.dur) % 1.0;
        final k = kf(p, const [0, .5, 1], const [0, 1, 0], cssEaseInOut);
        canvas.translate(e.ox, e.oy);
        canvas.transform(
          (Matrix4.identity()
                ..setEntry(1, 0, math.tan(rad(-6 * k)))
                ..scaleByDouble(1 - .1 * k, 1, 1, 1))
              .storage,
        );
        canvas.translate(-e.ox, -e.oy);
      }
      final varOp = e.fillOpVar != null ? (ops[e.fillOpVar] ?? 1) : 1.0;
      if (e.fill != null) {
        final f = e.fill!;
        final paint = Paint()..isAntiAlias = true;
        if (f.grad != null) {
          final g = _gradient(f.grad!);
          if (g != null) paint.shader = g.createShader(sti.getBounds());
          paint.color = Color.fromRGBO(0, 0, 0, op);
        } else {
          final c = _farge(f);
          paint.color = c.withValues(alpha: c.a * op * (e.fillOp ?? 1) * varOp);
        }
        canvas.drawPath(sti, paint);
      }
      if (e.stroke != null) {
        final c = _farge(e.stroke!);
        var s = sti;
        if (e.dash != null) {
          // adrTegn: stroke-dashoffset 0 → -22, linear
          final off = e.anim?.navn == 'adrTegn' ? -22 * ((t / e.anim!.dur) % 1.0) : 0.0;
          s = svgStreker(sti, e.dash!, off);
        }
        canvas.drawPath(
          s,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = e.sw
            ..strokeJoin = e.roundJoin ? StrokeJoin.round : StrokeJoin.miter
            ..strokeCap = e.roundCap ? StrokeCap.round : StrokeCap.butt
            ..color = c.withValues(alpha: c.a * op),
        );
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Maler old) => old.t != t || old.b != b || !_likt(old.vars, vars) || !_likt(old.ops, ops) || !_likt(old.stier, stier);

  static bool _likt<T>(Map<String, T> a, Map<String, T> b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
