import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Launch onboarding · CSS primitives ──────────────────────────────────────
// `Design-New/Ærend Kunde Launch.dc.html` styles everything inline. These
// helpers take the CSS values as written (px in the 390-wide frame) so the
// widgets read like the markup: layered backgrounds, outer and inset
// box-shadows, CSS-exact linear/radial gradient geometry.

/// CSS box-shadow blur length → Flutter Gaussian sigma (CSS σ = blur / 2).
double cssSigma(double blur) => blur <= 0 ? 0 : blur / 2;

/// One CSS `box-shadow` entry.
class CssShadow {
  const CssShadow(
    this.dx,
    this.dy,
    this.blur,
    this.spread,
    this.color, {
    this.inset = false,
  });

  /// `inset dx dy blur spread color`.
  const CssShadow.inset(
    this.dx,
    this.dy,
    this.blur,
    this.spread,
    this.color,
  ) : inset = true;

  final double dx;
  final double dy;
  final double blur;
  final double spread;
  final Color color;
  final bool inset;
}

/// One CSS background layer.
sealed class CssBg {
  const CssBg();
  Shader? shader(Rect r);
  Color? get solid => null;
}

class CssSolid extends CssBg {
  const CssSolid(this.color);
  final Color color;
  @override
  Shader? shader(Rect r) => null;
  @override
  Color get solid => color;
}

/// `linear-gradient(<deg>, …)` with the CSS gradient-line length, so angled
/// gradients in non-square boxes land exactly where the browser puts them.
class CssLinear extends CssBg {
  const CssLinear(this.deg, this.colors, [this.stops]);
  final double deg;
  final List<Color> colors;
  final List<double>? stops;

  @override
  Shader shader(Rect r) {
    final a = deg * math.pi / 180;
    final sx = math.sin(a), sy = -math.cos(a);
    final len = (r.width * sx).abs() + (r.height * sy).abs();
    final c = r.center;
    final half = Offset(sx, sy) * (len / 2);
    return ui.Gradient.linear(c - half, c + half, colors, _stops(colors, stops));
  }
}

/// `radial-gradient(<rx> <ry> at <cx> <cy>, …)`. Radii and centre are
/// fractions of the box unless [px] is set. [closestSide] / [farthestCorner]
/// mirror the CSS keywords.
class CssRadial extends CssBg {
  const CssRadial(
    this.colors, {
    this.stops,
    this.rx = .5,
    this.ry = .5,
    this.cx = .5,
    this.cy = .5,
    this.px = false,
    this.circle = false,
    this.farthestCorner = false,
  });

  /// `radial-gradient(closest-side, …)` centred.
  const CssRadial.closestSide(this.colors, {this.stops})
    : rx = .5,
      ry = .5,
      cx = .5,
      cy = .5,
      px = false,
      circle = false,
      farthestCorner = false;

  final List<Color> colors;
  final List<double>? stops;
  final double rx, ry, cx, cy;
  final bool px;
  final bool circle;
  final bool farthestCorner;

  @override
  Shader shader(Rect r) {
    final center = Offset(r.left + cx * r.width, r.top + cy * r.height);
    double ex, ey;
    if (farthestCorner) {
      final dx = math.max(center.dx - r.left, r.right - center.dx);
      final dy = math.max(center.dy - r.top, r.bottom - center.dy);
      if (circle) {
        ex = ey = math.sqrt(dx * dx + dy * dy);
      } else {
        // CSS ellipse through the farthest corner keeps the side ratio.
        ex = dx * math.sqrt2;
        ey = dy * math.sqrt2;
      }
    } else if (px) {
      ex = rx;
      ey = ry;
    } else {
      ex = rx * r.width;
      ey = circle ? ex : ry * r.height;
    }
    if (ex <= 0 || ey <= 0) {
      return ui.Gradient.linear(r.topLeft, r.bottomRight, [
        colors.last,
        colors.last,
      ]);
    }
    final m = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1, ey / ex, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    return ui.Gradient.radial(
      center,
      ex,
      colors,
      _stops(colors, stops),
      TileMode.clamp,
      m.storage,
    );
  }
}

List<double> _stops(List<Color> c, List<double>? s) =>
    s ?? List.generate(c.length, (i) => c.length == 1 ? 0 : i / (c.length - 1));

/// A CSS box: border-radius, layered backgrounds (first = top, as in CSS),
/// outer + inset box-shadows and an optional border. Paints like the
/// browser: outer shadows, backgrounds (bottom-up), border, inset shadows.
class CssBox extends StatelessWidget {
  const CssBox({
    super.key,
    this.width,
    this.height,
    this.radius = BorderRadius.zero,
    this.bg = const [],
    this.shadows = const [],
    this.border,
    this.padding,
    this.clip = false,
    this.child,
  });

  final double? width;
  final double? height;
  final BorderRadius radius;
  final List<CssBg> bg;
  final List<CssShadow> shadows;
  final Border? border;
  final EdgeInsets? padding;
  final bool clip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget? inner = child;
    if (padding != null) inner = Padding(padding: padding!, child: inner);
    if (clip && inner != null) {
      inner = ClipRRect(borderRadius: radius, child: inner);
    }
    final hasInset = shadows.any((s) => s.inset);
    return CustomPaint(
      painter: CssBoxPainter(
        radius: radius,
        bg: bg,
        shadows: shadows,
        border: border,
        skipInset: hasInset && clip,
      ),
      foregroundPainter: hasInset && clip
          ? CssBoxPainter(
              radius: radius,
              bg: const [],
              shadows: shadows.where((s) => s.inset).toList(),
              insetOnTop: true,
            )
          : null,
      child: SizedBox(width: width, height: height, child: inner),
    );
  }
}

class CssBoxPainter extends CustomPainter {
  const CssBoxPainter({
    required this.radius,
    required this.bg,
    required this.shadows,
    this.border,
    this.insetOnTop = false,
    this.skipInset = false,
  });

  /// The inset shadows are painted by a foreground pass instead.
  final bool skipInset;

  final BorderRadius radius;
  final List<CssBg> bg;
  final List<CssShadow> shadows;
  final Border? border;

  /// Foreground pass: only the inset shadows (used when content must sit
  /// under them, e.g. inputs inside a sunken well).
  final bool insetOnTop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect);
    if (!insetOnTop) {
      // Outer shadows, last listed first (CSS paints the first on top).
      for (final s in shadows.reversed) {
        if (s.inset) continue;
        final p = Paint()..color = s.color;
        if (s.blur > 0) {
          p.maskFilter = MaskFilter.blur(BlurStyle.normal, cssSigma(s.blur));
        }
        final shadowRR = rr.inflate(s.spread).shift(Offset(s.dx, s.dy));
        // A box-shadow never shows through its own box.
        canvas.save();
        final outside = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(400))
          ..addRRect(rr);
        canvas.clipPath(outside);
        canvas.drawRRect(shadowRR, p);
        canvas.restore();
      }
      for (final b in bg.reversed) {
        final p = Paint();
        final solid = b.solid;
        if (solid != null) {
          p.color = solid;
        } else {
          p.shader = b.shader(rect);
        }
        canvas.drawRRect(rr, p);
      }
      if (border != null) {
        final side = border!.top;
        if (side.width > 0 && side.style != BorderStyle.none) {
          final p = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = side.width
            ..color = side.color;
          canvas.drawRRect(rr.deflate(side.width / 2), p);
        }
      }
    }
    if (skipInset) return;
    final insets = shadows.where((s) => s.inset).toList();
    if (insets.isEmpty) return;
    canvas.save();
    canvas.clipRRect(rr, doAntiAlias: true);
    for (final s in insets.reversed) {
      final p = Paint()..color = s.color;
      if (s.blur > 0) {
        p.maskFilter = MaskFilter.blur(BlurStyle.normal, cssSigma(s.blur));
      }
      final hole = rr.deflate(s.spread).shift(Offset(s.dx, s.dy));
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(s.blur * 2 + s.spread.abs() + 40))
        ..addRRect(hole);
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CssBoxPainter old) =>
      old.radius != radius ||
      old.bg != bg ||
      old.shadows != shadows ||
      old.border != border;
}

// ── Type ────────────────────────────────────────────────────────────────────

/// `font-family:'Plus Jakarta Sans'`.
TextStyle jakarta(
  double size, {
  FontWeight weight = FontWeight.w800,
  double em = 0,
  double? height,
  Color color = Colors.white,
  List<Shadow>? shadows,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: size * em,
  height: height,
  color: color,
  shadows: shadows,
).copyWith(leadingDistribution: TextLeadingDistribution.even);

/// The page font (`font-family:Inter`).
TextStyle inter(
  double size, {
  FontWeight weight = FontWeight.w600,
  double em = 0,
  double? height,
  Color color = Colors.white,
}) => GoogleFonts.inter(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: size * em,
  height: height,
  color: color,
).copyWith(leadingDistribution: TextLeadingDistribution.even);

// ── Frame ───────────────────────────────────────────────────────────────────

/// Lays [child] out in the prototype's 390-px-wide frame and scales it to
/// the device width, so every child uses the CSS numbers as written.
/// `MediaQuery` inside reports design px (size, padding, insets).
class LfFrame extends StatelessWidget {
  const LfFrame({super.key, required this.child});

  final Widget child;

  static const double width = 390;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final mq = MediaQuery.of(context);
        final w = box.maxWidth.isFinite ? box.maxWidth : mq.size.width;
        final h = box.maxHeight.isFinite ? box.maxHeight : mq.size.height;
        final s = w / width;
        final dh = h / s;
        EdgeInsets d(EdgeInsets e) =>
            EdgeInsets.fromLTRB(e.left / s, e.top / s, e.right / s, e.bottom / s);
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: dh,
            maxHeight: dh,
            child: Transform.scale(
              scale: s,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: mq.copyWith(
                  size: Size(width, dh),
                  padding: d(mq.padding),
                  viewPadding: d(mq.viewPadding),
                  viewInsets: d(mq.viewInsets),
                  devicePixelRatio: mq.devicePixelRatio * s,
                ),
                child: SizedBox(width: width, height: dh, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Keyframes ───────────────────────────────────────────────────────────────

/// Progress of a one-shot animation with fill-mode both.
double kfP(double t, double delayMs, double durMs) =>
    durMs <= 0 ? (t >= delayMs ? 1 : 0) : ((t - delayMs) / durMs).clamp(0.0, 1.0);

/// Progress of an infinite animation (null before the delay — no fill).
double? kfLoop(double t, double delayMs, double durMs) {
  final e = t - delayMs;
  if (e < 0) return null;
  return (e / durMs) % 1.0;
}

/// Keyframed value with the timing function per segment, as CSS applies it.
double kf(double p, List<double> stops, List<double> values, [Curve curve = Curves.linear]) {
  if (p <= stops.first) return values.first;
  for (var i = 1; i < stops.length; i++) {
    if (p <= stops[i]) {
      final a = stops[i - 1], b = stops[i];
      final local = b == a ? 1.0 : (p - a) / (b - a);
      final v = curve.transform(local.clamp(0.0, 1.0));
      return values[i - 1] + (values[i] - values[i - 1]) * v;
    }
  }
  return values.last;
}

/// CSS `ease-in-out`, `ease-out`, `ease-in`, `ease` (Flutter's named curves
/// differ slightly from the CSS keywords).
const Cubic cssEase = Cubic(.25, .1, .25, 1);
const Cubic cssEaseIn = Cubic(.42, 0, 1, 1);
const Cubic cssEaseOut = Cubic(0, 0, .58, 1);
const Cubic cssEaseInOut = Cubic(.42, 0, .58, 1);

double rad(double deg) => deg * math.pi / 180;

/// CSS `text-wrap: balance`: keeps the line count the browser would use at
/// the full width but shrinks the box until the lines are as even as they
/// can be (binary search on the width).
class LfBalanced extends StatelessWidget {
  const LfBalanced(this.text, {super.key, required this.style, this.align = TextAlign.center});

  final String text;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final max = box.maxWidth;
        if (!max.isFinite) return Text(text, style: style, textAlign: align);
        final scaler = MediaQuery.textScalerOf(context);
        int lines(double w) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: w);
          final n = tp.computeLineMetrics().length;
          tp.dispose();
          return n;
        }

        final n = lines(max);
        if (n <= 1) return Text(text, style: style, textAlign: align);
        var lo = max / n, hi = max;
        for (var i = 0; i < 12; i++) {
          final mid = (lo + hi) / 2;
          if (lines(mid) > n) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return Align(
          alignment: align == TextAlign.center ? Alignment.topCenter : Alignment.topLeft,
          child: SizedBox(width: hi + .5, child: Text(text, style: style, textAlign: align)),
        );
      },
    );
  }
}

/// CSS `text-wrap: pretty` (the part that shows): no single word alone on
/// the last line — the box narrows just enough to carry a second word down.
class LfPretty extends StatelessWidget {
  const LfPretty(this.text, {super.key, required this.style, this.align = TextAlign.start});

  final String text;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final max = box.maxWidth;
        if (!max.isFinite || !text.contains(' ')) return Text(text, style: style, textAlign: align);
        final scaler = MediaQuery.textScalerOf(context);
        (int, bool) probe(double w) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: w);
          final lines = tp.computeLineMetrics();
          final n = lines.length;
          var orphan = false;
          if (n > 1) {
            final start = tp.getLineBoundary(TextPosition(offset: text.length - 1)).start;
            orphan = !text.substring(start).trim().contains(' ');
          }
          tp.dispose();
          return (n, orphan);
        }

        final (n, orphan) = probe(max);
        if (!orphan) return Text(text, style: style, textAlign: align);
        var w = max;
        for (var i = 0; i < 40; i++) {
          w -= 4;
          if (w < max * .6) return Text(text, style: style, textAlign: align);
          final (n2, o2) = probe(w);
          if (n2 > n) return Text(text, style: style, textAlign: align);
          if (!o2) break;
        }
        return Align(
          alignment: align == TextAlign.center ? Alignment.topCenter : Alignment.topLeft,
          widthFactor: 1,
          child: SizedBox(width: w, child: Text(text, style: style, textAlign: align)),
        );
      },
    );
  }
}
