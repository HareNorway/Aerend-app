import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../common/auth/launch/lf_css.dart' show kf, kfLoop;
import '../../common/auth/launch/lf_motion.dart' show LfLoop;
import '../meg/meg_mark.dart';
import '../meg/meg_nivaa_card.dart' show MedalStyle, medalFor;

/// Design 21 Nov plan Step 1 (A6): the one gold coin and the one level medal every screen uses.
///
/// The coin is the design's `phMynt` coin: a 155° gold gradient with a 1 px light edge at the top and a dark one at
/// the bottom, a rim (`0 2.5px 0 #7A4A08` at 44 px) and a drop shadow, an inner disc with a radial gold and inset
/// shadows, a highlight ellipse, two offset dashed rings (light under dark, the engraved look) and the engraved Æ
/// (`#merke-grav`). It flips on its vertical axis (`@keyframes phMynt`: scaleX 1 → .06 → 1 → .06 → 1 between 70 %
/// and 94 % of a 4 s loop) unless [flip] is false. Every length is a share of [size], as the design's sizes are.
class AeMynt extends StatelessWidget {
  const AeMynt({super.key, this.size = 30, this.flip = true, this.periodMs = 4000, this.delayMs = 0, this.glow = false, this.mark = true, this.child});

  final double size;
  final bool flip;
  final double periodMs;
  final double delayMs;

  /// The soft gold halo (`0 0 18px rgba(242,193,78,.45)`) the onboarding and Premiehylla coins carry.
  final bool glow;

  /// The engraved Æ in the middle (off for a plain disc, e.g. a flying coin at 16 px).
  final bool mark;

  /// Something else in the middle instead of the Æ.
  final Widget? child;

  static const Color ink = Color(0xFF74500F);

  /// Paints the coin's disc (no Æ) [size] wide with its top-left at the origin: a pool of flying coins on one painter
  /// (Design 21 Nov Step 6, «Poeng kreditert»).
  static void male(Canvas c, double size) => _MyntMaler(size: size, glow: false).paint(c, Size.square(size));

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MyntMaler(size: size, glow: glow),
        child: Center(child: child ?? (mark ? MegMark(color: ink, size: size * .545, grav: true) : null)),
      ),
    );
    if (!flip) return body;
    return LfLoop(
      child: body,
      builder: (context, t, child) {
        final p = (kfLoop(t, delayMs, periodMs) ?? 0);
        final sx = kf(p, const [0, .7, .76, .82, .88, .94, 1], const [1, 1, .06, 1, .06, 1, 1], Curves.easeInOut);
        return Transform(alignment: Alignment.center, transform: Matrix4.diagonal3Values(sx, 1, 1), child: child);
      },
    );
  }
}

/// The level medal (Bronse · Sølv · Gull · Platina) as the design draws it since 21 Nov: the metal (from
/// [medalFor]), a ring in the metal's own colour, a rim (`0 2.5px 0 1.5px rgba(58,40,12,.6)` at 42 px) and a drop
/// shadow, a 155° light-to-shade overlay, an inner disc with inset shadows, the highlight ellipse, two offset dashed
/// rings and the engraved Æ in the metal's ink. [ring] is the ring's width (0 for none). Static; the callers add the
/// glow pulse, spin or sheen they already have.
class AeMedalje extends StatelessWidget {
  const AeMedalje({super.key, required this.name, this.size = 42, this.ring, this.mark = true, this.child, this.ringColor});

  final String name;
  final double size;
  final double? ring;
  final bool mark;
  final Widget? child;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final m = medalFor(name);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedaljeMaler(size: size, m: m, ring: ring ?? size * .036, ringColor: ringColor),
        child: Center(child: child ?? (mark ? MegMark(color: m.ink, size: size * .55, grav: true) : null)),
      ),
    );
  }
}

// ── painting ────────────────────────────────────────────────────────────────

void _innerShadow(Canvas c, Rect disc, double dx, double dy, double blur, Color color) {
  // An inset shadow: everything outside the disc, moved by (dx, dy) and blurred, clipped to the disc.
  c.save();
  c.clipPath(Path()..addOval(disc));
  final outer = Path()
    ..addRect(disc.inflate(blur * 3 + dx.abs() + dy.abs()))
    ..addOval(disc.shift(Offset(dx, dy)))
    ..fillType = PathFillType.evenOdd;
  c.drawPath(outer, Paint()..color = color..maskFilter = blur > 0 ? ui.MaskFilter.blur(ui.BlurStyle.normal, blur / 2) : null);
  c.restore();
}

void _dropShadow(Canvas c, Rect disc, double dx, double dy, double blur, double spread, Color color) {
  c.drawOval(disc.shift(Offset(dx, dy)).inflate(spread), Paint()..color = color..maskFilter = blur > 0 ? ui.MaskFilter.blur(ui.BlurStyle.normal, blur / 2) : null);
}

void _highlight(Canvas c, Rect r) {
  // left 20 %, right 36 %, top 13 %, height 24 %: white .75 → 0 downwards.
  final h = Rect.fromLTRB(r.left + r.width * .2, r.top + r.height * .13, r.right - r.width * .36, r.top + r.height * .37);
  c.drawOval(h, Paint()..shader = ui.Gradient.linear(h.topCenter, h.bottomCenter, [const Color(0xBFFFFFFF), const Color(0x00FFFFFF)]));
}

void _dashedRings(Canvas c, Rect r, double inset, double width, Color light, Color dark) {
  final ring = r.deflate(inset);
  void dashed(Rect rr, Color col, double dy) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = col;
    final n = math.max(18, (rr.width * math.pi / (width * 3.2)).round());
    final step = math.pi * 2 / n;
    for (var i = 0; i < n; i++) {
      c.drawArc(rr.shift(Offset(0, dy)), i * step, step * .5, false, p);
    }
  }
  dashed(ring, light, width * .66);
  dashed(ring, dark, 0);
}

Shader _linear155(Rect r, List<Color> colors, List<double> stops) {
  // CSS `linear-gradient(155deg, …)`: the line through the centre at 155° (0° = up, clockwise).
  const a = 155 * math.pi / 180;
  final sx = math.sin(a), sy = -math.cos(a);
  final len = (r.width * sx).abs() + (r.height * sy).abs();
  final half = Offset(sx, sy) * (len / 2);
  return ui.Gradient.linear(r.center - half, r.center + half, colors, stops);
}

class _MyntMaler extends CustomPainter {
  const _MyntMaler({required this.size, required this.glow});

  final double size;
  final bool glow;

  @override
  void paint(Canvas c, Size s) {
    final k = size / 44; // the design's reference coin
    final r = Offset.zero & s;
    if (glow) _dropShadow(c, r, 0, 0, 18 * k, 0, const Color(0x73F2C14E));
    _dropShadow(c, r, 0, 7.8 * k, 11.4 * k, -4.4 * k, const Color(0x9904141A));
    _dropShadow(c, r, 0, 2.5 * k, 0, 0, const Color(0xFF7A4A08));
    c.drawOval(r, Paint()..shader = _linear155(r, const [Color(0xFFFFF4C6), Color(0xFFF6C94E), Color(0xFFD79A22), Color(0xFF8F5B0C)], const [0, .28, .6, 1]));
    _innerShadow(c, r, 0, 1 * k, 0, const Color(0xF2FFFAE1));
    _innerShadow(c, r, 0, -1 * k, 0, const Color(0x805A3706));
    final disc = r.deflate(3.7 * k);
    c.drawOval(disc, Paint()..shader = ui.Gradient.radial(Offset(disc.left + disc.width * .38, disc.top + disc.height * .3), disc.width * .72,
        const [Color(0xFFFFF9E2), Color(0xFFFCE395), Color(0xFFF1C04A), Color(0xFFD99D28), Color(0xFFC68A1B)], const [0, .24, .55, .84, 1]));
    _innerShadow(c, disc, 0, 1.8 * k, 2.6 * k, const Color(0x8C6E4406));
    _innerShadow(c, disc, 0, -1.3 * k, 1.5 * k, const Color(0xBFFFF6D6));
    _highlight(c, r);
    _dashedRings(c, r, 7 * k, math.max(1, 1.2 * k), const Color(0xBFFFF6D6), const Color(0x807A500C));
  }

  @override
  bool shouldRepaint(_MyntMaler old) => old.size != size || old.glow != glow;
}

class _MedaljeMaler extends CustomPainter {
  const _MedaljeMaler({required this.size, required this.m, required this.ring, this.ringColor});

  final double size;
  final MedalStyle m;
  final double ring;
  final Color? ringColor;

  @override
  void paint(Canvas c, Size s) {
    final k = size / 42; // the design's reference medal
    final r = Offset.zero & s;
    _dropShadow(c, r, 0, 7.5 * k, 10.9 * k, -4.2 * k, const Color(0x8C04141A));
    _dropShadow(c, r, 0, 2.5 * k, 0, ring, const Color(0x993A280C));
    if (ring > 0) c.drawOval(r.inflate(ring), Paint()..color = ringColor ?? m.ring);
    c.drawOval(r, Paint()..shader = ui.Gradient.radial(Offset(r.left + r.width * .34, r.top + r.height * .26), r.width * .9, m.gradient, m.stops));
    c.drawOval(r, Paint()..shader = _linear155(r, const [Color(0x99FFFFFF), Color(0x00FFFFFF), Color(0x00000000), Color(0x7A301C04)], const [0, .3, .52, 1]));
    final disc = r.deflate(3.6 * k);
    c.drawOval(disc, Paint()..shader = ui.Gradient.radial(Offset(disc.left + disc.width * .34, disc.top + disc.height * .26), disc.width * .9, m.gradient, m.stops));
    _innerShadow(c, disc, 0, 1.7 * k, 2.5 * k, const Color(0x803C2606));
    _innerShadow(c, disc, 0, -1.3 * k, 1.5 * k, const Color(0xB3FFFFFF));
    _highlight(c, r);
    _dashedRings(c, r, 7 * k, math.max(1, 1.2 * k), const Color(0xA6FFFFFF), const Color(0x733C280A));
  }

  @override
  bool shouldRepaint(_MedaljeMaler old) => old.size != size || old.m != m || old.ring != ring || old.ringColor != ringColor;
}
