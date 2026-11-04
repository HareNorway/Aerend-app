import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bergen/kit/bergen_perf.dart';

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

  // Perf plan: value equality, so a CssBox rebuilt with an equal (but new)
  // shadow list does not repaint (and its raster stays valid).
  @override
  bool operator ==(Object other) =>
      other is CssShadow && other.dx == dx && other.dy == dy && other.blur == blur && other.spread == spread && other.color == color && other.inset == inset;

  @override
  int get hashCode => Object.hash(dx, dy, blur, spread, color, inset);
}

/// CSS box-shadow interpolation between two lists at [t]: pairs them by
/// index and pads the shorter with transparent zero shadows of the other's
/// kind (inset or outer), as browsers do for `transition: box-shadow`.
List<CssShadow> cssLerpShadows(List<CssShadow> a, List<CssShadow> b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  CssShadow tom(CssShadow s) => CssShadow(0, 0, 0, 0, s.color.withValues(alpha: 0), inset: s.inset);
  double l(double p, double q) => p + (q - p) * t;
  final n = a.length > b.length ? a.length : b.length;
  return [
    for (var i = 0; i < n; i++)
      () {
        final x = i < a.length ? a[i] : tom(b[i]), y = i < b.length ? b[i] : tom(a[i]);
        return CssShadow(l(x.dx, y.dx), l(x.dy, y.dy), l(x.blur, y.blur), l(x.spread, y.spread), Color.lerp(x.color, y.color, t)!, inset: y.inset);
      }(),
  ];
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
  bool operator ==(Object other) => other is CssSolid && other.color == color;

  @override
  int get hashCode => color.hashCode;
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
  bool operator ==(Object other) => other is CssLinear && other.deg == deg && listEquals(other.colors, colors) && listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(deg, Object.hashAll(colors), stops == null ? null : Object.hashAll(stops!));

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
  bool operator ==(Object other) =>
      other is CssRadial &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops) &&
      other.rx == rx && other.ry == ry && other.cx == cx && other.cy == cy &&
      other.px == px && other.circle == circle && other.farthestCorner == farthestCorner;

  @override
  int get hashCode => Object.hash(Object.hashAll(colors), stops == null ? null : Object.hashAll(stops!), rx, ry, cx, cy, px, circle, farthestCorner);

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
    return _CssPaint(
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

  /// Debug (harness `skyggeAv`): skip every blurred shadow, to measure what
  /// the blurs cost on the raster thread.
  static bool debugUtenBlur = false;

  @override
  void paint(Canvas canvas, Size size) {
    // Perf plan: inside a CssBox, a box with blurred or stencil-clipped
    // shadows is drawn from CssBake's raster (painted once by [_tegn] at the
    // box's on-screen resolution), not re-blurred every frame.
    final r = CssBake._skala;
    final ro = CssBake._aktiv;
    if (r == null || ro == null || !CssBake.paa || debugUtenBlur || !_dyr) {
      _tegn(canvas, size);
      return;
    }
    if (ro._pause > 0) {
      ro._pause--;
      _tegn(canvas, size);
      return;
    }
    final b = _grenser(size);
    final key = _nokkel(size, r);
    var img = CssBake._hent(key);
    if (img == null) {
      if (++ro._bom > 3) {
        // Its look changes every frame (an animated colour or size): live.
        ro._bom = 0;
        ro._pause = 90;
        CssBake._levende++;
        _tegn(canvas, size);
        return;
      }
      img = CssBake._lag(key, b, r, (c) => _tegn(c, size));
      if (img == null) {
        _tegn(canvas, size);
        return;
      }
    } else {
      ro._bom = 0;
    }
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(b.left, b.top, img.width / r, img.height / r),
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  /// Worth a raster: a blurred shadow (a Gaussian pass, an offscreen layer
  /// for an inset one) or a translucent box's outer shadow (a stencil clip).
  bool get _dyr {
    for (final s in shadows) {
      if (insetOnTop && !s.inset) continue;
      if (skipInset && s.inset) continue;
      if (s.blur > 0) return true;
      if (!s.inset && !_opaque) return true;
    }
    return false;
  }

  /// What the paint covers: the box and its outer shadows' blur (3σ + 1).
  Rect _grenser(Size size) {
    final rect = Offset.zero & size;
    var b = rect;
    if (!insetOnTop) {
      final rr = radius.toRRect(rect);
      for (final s in shadows) {
        if (s.inset) continue;
        b = b.expandToInclude(rr.inflate(s.spread).shift(Offset(s.dx, s.dy)).outerRect.inflate(cssSigma(s.blur) * 3 + 1));
      }
    }
    return b;
  }

  _CssNokkel _nokkel(Size size, double r) {
    final v = <Object>[
      (size.width * 1000).round(), (size.height * 1000).round(), r, insetOnTop, skipInset,
      radius.topLeft.x, radius.topLeft.y, radius.topRight.x, radius.topRight.y,
      radius.bottomLeft.x, radius.bottomLeft.y, radius.bottomRight.x, radius.bottomRight.y,
    ];
    for (final s in shadows) {
      v..add(s.dx)..add(s.dy)..add(s.blur)..add(s.spread)..add(s.color.toARGB32())..add(s.inset);
    }
    v.add('|');
    for (final g in bg) {
      switch (g) {
        case CssSolid(:final color):
          v..add('s')..add(color.toARGB32());
        case CssLinear(:final deg, :final colors, :final stops):
          v..add('l')..add(deg)..add(colors.length);
          for (final c in colors) {
            v.add(c.toARGB32());
          }
          v.add(stops?.length ?? -1);
          if (stops != null) v.addAll(stops);
        case CssRadial r0:
          v..add('r')..add(r0.rx)..add(r0.ry)..add(r0.cx)..add(r0.cy)..add(r0.px)..add(r0.circle)..add(r0.farthestCorner)..add(r0.colors.length);
          for (final c in r0.colors) {
            v.add(c.toARGB32());
          }
          v.add(r0.stops?.length ?? -1);
          if (r0.stops != null) v.addAll(r0.stops!);
      }
    }
    final side = border?.top;
    if (side != null) v..add('b')..add(side.width)..add(side.color.toARGB32())..add(side.style.index);
    return _CssNokkel(v);
  }

  /// The box as the CSS draws it (live, or into CssBake's raster).
  void _tegn(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect);
    if (!insetOnTop) {
      // Outer shadows, last listed first (CSS paints the first on top).
      // Under an opaque background the box covers its own shadow, so the
      // even-odd clip (a stencil pass per shadow on Impeller) is skipped.
      final tett = _opaque;
      for (final s in shadows.reversed) {
        if (s.inset || (debugUtenBlur && s.blur > 0)) continue;
        final p = Paint()..color = s.color;
        if (s.blur > 0) {
          p.maskFilter = MaskFilter.blur(BlurStyle.normal, cssSigma(s.blur));
        }
        final shadowRR = rr.inflate(s.spread).shift(Offset(s.dx, s.dy));
        if (tett) {
          canvas.drawRRect(shadowRR, p);
          continue;
        }
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
    final insets = shadows.where((s) => s.inset && !(debugUtenBlur && s.blur > 0)).toList();
    if (insets.isEmpty) return;
    canvas.save();
    canvas.clipRRect(rr, doAntiAlias: true);
    for (final s in insets.reversed) {
      final hole = rr.deflate(s.spread).shift(Offset(s.dx, s.dy));
      if (s.blur <= 0) {
        final path = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(s.spread.abs() + 40))
          ..addRRect(hole);
        canvas.drawPath(path, Paint()..color = s.color);
        continue;
      }
      // A blurred inset = the colour over the box, minus the blurred hole.
      // Drawn as a fill and a `dstOut` rounded rect with a mask blur, which
      // Impeller renders analytically — not as a Gaussian pass over a path
      // (the costliest draw on Hjem's raster thread while the sheet scrolls).
      canvas.saveLayer(rect, Paint());
      canvas.drawRect(rect, Paint()..color = s.color);
      canvas.drawRRect(
        hole,
        Paint()
          ..color = const Color(0xFF000000)
          ..blendMode = BlendMode.dstOut
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cssSigma(s.blur)),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  /// True when the backgrounds cover the box fully (any opaque colour or
  /// gradient stop list without transparency).
  bool get _opaque {
    for (final b in bg) {
      final colors = switch (b) {
        CssSolid(:final color) => [color],
        CssLinear(:final colors) => colors,
        CssRadial(:final colors) => colors,
      };
      if (colors.isNotEmpty && colors.every((c) => c.a >= .999)) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(CssBoxPainter old) =>
      old.radius != radius ||
      !listEquals(old.bg, bg) ||
      !listEquals(old.shadows, shadows) ||
      old.border != border ||
      old.insetOnTop != insetOnTop ||
      old.skipInset != skipInset;
}

// ── CssBake: the CssBox raster cache (perf plan) ───────────────────────────

/// Impeller draws every frame from scratch: a CssBox with a blurred shadow
/// costs a Gaussian pass (and an offscreen layer for an inset one) on every
/// frame anything on the screen moves — on Hjem dozens of them. CssBake
/// paints such a box once, at its on-screen pixel scale, into an image and
/// draws that image afterwards: the same paint commands, so the same
/// pixels, for one texture draw a frame. Identical boxes share one image.
/// A box whose look changes every frame is drawn live (see `_bom`).
abstract final class CssBake {
  /// Off: every CssBox paints live, as before (harness `cssCache: false`).
  static bool paa = true;

  static double? _skala;
  static _RenderCssPaint? _aktiv;

  static final LinkedHashMap<_CssNokkel, ui.Image> _lager = LinkedHashMap<_CssNokkel, ui.Image>();
  static int _bytes = 0;

  /// At most this much texture memory (oldest images go first).
  static const int maksBytes = 40 << 20;

  /// Bigger boxes paint live (a full-screen raster is not worth its memory).
  static const int maksPiksler = 1600000;

  static int treff = 0, bom = 0, _levende = 0;
  static bool _lytter = false;

  /// For the perf heartbeat: hits, misses, live fallbacks, images, MB.
  static String get status => 'css=${treff}h/${bom}m/${_levende}l/${_lager.length}i/${(_bytes / (1 << 20)).toStringAsFixed(1)}MB';

  static ui.Image? _hent(_CssNokkel k) {
    final img = _lager.remove(k);
    if (img == null) return null;
    _lager[k] = img;
    treff++;
    return img;
  }

  static ui.Image? _lag(_CssNokkel k, Rect b, double r, void Function(Canvas) tegn) {
    final w = (b.width * r).ceil(), h = (b.height * r).ceil();
    if (w <= 0 || h <= 0 || w * h > maksPiksler) return null;
    if (!_lytter) {
      _lytter = true;
      WidgetsBinding.instance.addObserver(_CssMinne());
      BergenPerf.pulsTillegg.add(() => status);
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(r);
    c.translate(-b.left, -b.top);
    tegn(c);
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    bom++;
    _lager[k] = img;
    _bytes += w * h * 4;
    while (_bytes > maksBytes && _lager.length > 1) {
      final eldst = _lager.keys.first;
      final ut = _lager.remove(eldst)!;
      _bytes -= ut.width * ut.height * 4;
      ut.dispose();
    }
    return img;
  }

  /// Drops every raster (memory pressure, tests).
  static void tom() {
    for (final img in _lager.values) {
      img.dispose();
    }
    _lager.clear();
    _bytes = 0;
  }

  /// The box's device-pixel scale (all ancestor transforms × the view's
  /// pixel ratio), rounded to 1/16 (≤ 1.6 % off: no visible resampling, and a
  /// small animated scale keeps one image); under a perspective, the largest
  /// scale over the projected box + 10 %.
  static double? _skalaFor(RenderObject ro) {
    final Matrix4 m;
    try {
      m = ro.getTransformTo(null);
    } catch (_) {
      return null;
    }
    final s = m.storage;
    final dpr = ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2;
    double r;
    if (s[3].abs() > 1e-6 || s[7].abs() > 1e-6 || (s[15] - 1).abs() > 1e-6) {
      // Under a perspective (a card tilted in 3D): the largest on-screen
      // scale over the box, from its projected corners (+10 % headroom so
      // the near edge is never upsampled).
      final box = (ro is RenderBox && ro.hasSize) ? Offset.zero & ro.size : Rect.zero;
      if (box.isEmpty) return null;
      final Rect p;
      try {
        p = MatrixUtils.transformRect(m, box);
      } catch (_) {
        return null;
      }
      if (!p.isFinite) return null;
      r = math.max(p.width / box.width, p.height / box.height) * 1.1 * dpr;
    } else {
      final sx = math.sqrt(s[0] * s[0] + s[1] * s[1]), sy = math.sqrt(s[4] * s[4] + s[5] * s[5]);
      r = math.max(sx, sy) * dpr;
    }
    if (!r.isFinite || r <= 0 || r > 8) return null;
    return (r * 16).round() / 16;
  }
}

class _CssMinne with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() => CssBake.tom();
}

class _CssNokkel {
  _CssNokkel(this.v) : _hash = Object.hashAll(v);
  final List<Object> v;
  final int _hash;

  @override
  int get hashCode => _hash;

  @override
  bool operator ==(Object other) {
    if (other is! _CssNokkel || other._hash != _hash || other.v.length != v.length) return false;
    for (var i = 0; i < v.length; i++) {
      if (other.v[i] != v[i]) return false;
    }
    return true;
  }
}

/// CustomPaint for CssBox: the same render object (layout, hit testing and
/// semantics unchanged), which hands its painters the device-pixel scale.
class _CssPaint extends CustomPaint {
  const _CssPaint({super.painter, super.foregroundPainter, super.child});

  @override
  RenderCustomPaint createRenderObject(BuildContext context) => _RenderCssPaint(
    painter: painter,
    foregroundPainter: foregroundPainter,
    preferredSize: size,
    isComplex: isComplex,
    willChange: willChange,
  );
}

class _RenderCssPaint extends RenderCustomPaint {
  _RenderCssPaint({super.painter, super.foregroundPainter, super.preferredSize, super.isComplex, super.willChange});

  /// Misses in a row, and paints left to draw live after too many.
  int _bom = 0, _pause = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final forrigeSkala = CssBake._skala;
    final forrigeAktiv = CssBake._aktiv;
    CssBake._skala = CssBake.paa ? CssBake._skalaFor(this) : null;
    CssBake._aktiv = this;
    try {
      super.paint(context, offset);
    } finally {
      CssBake._skala = forrigeSkala;
      CssBake._aktiv = forrigeAktiv;
    }
  }
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

/// Lays [child] out [designWidth] px wide (any height) and scales it to the
/// width it is given, for design-px sections inside a flowing list.
Widget lfFlow(double designWidth, Widget child) => FittedBox(
  fit: BoxFit.fitWidth,
  alignment: Alignment.topLeft,
  child: SizedBox(width: designWidth, child: child),
);

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
