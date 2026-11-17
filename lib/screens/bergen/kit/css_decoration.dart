import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A [BoxDecoration] whose shadows behave like CSS `box-shadow`: painted around the box, never under it.
///
/// Flutter paints a [BoxShadow] under the whole box. On an opaque box that is invisible, but on a translucent one
/// (glass, a tinted card, a selected chip with a `0 0 0 3px` ring) the shadow shows through the fill and the box
/// glows — the design (HTML/CSS) never does that, because CSS clips every outer shadow to outside the element's
/// border box. 2026-11-16 (manager: «the weird green glow on some buttons»): use this in place of [BoxDecoration]
/// wherever a box with shadows may have a translucent fill.
///
/// It draws exactly like [BoxDecoration] unless it has shadows **and** a fill (colour or gradient) that is not fully
/// opaque; only then are the shadows clipped to outside the box's shape. A box with no fill at all is left as Flutter
/// draws it (its shadow may be a deliberate glow behind a child).
class CssDecoration extends BoxDecoration {
  const CssDecoration({
    super.color,
    super.image,
    super.border,
    super.borderRadius,
    super.boxShadow,
    super.gradient,
    super.backgroundBlendMode,
    super.shape,
  });

  /// The same decoration, painted the CSS way.
  CssDecoration.of(BoxDecoration d)
      : super(
          color: d.color,
          image: d.image,
          border: d.border,
          borderRadius: d.borderRadius,
          boxShadow: d.boxShadow,
          gradient: d.gradient,
          backgroundBlendMode: d.backgroundBlendMode,
          shape: d.shape,
        );

  /// The shadows would show through the fill.
  bool get _leaks {
    final List<BoxShadow>? s = boxShadow;
    if (s == null || s.isEmpty || image != null || (color == null && gradient == null)) {
      return false;
    }
    if (color != null && color!.a >= .999) {
      return false;
    }
    final Gradient? g = gradient;
    if (g != null && g.colors.isNotEmpty && g.colors.every((Color c) => c.a >= .999)) {
      return false;
    }
    return true;
  }

  @override
  CssDecoration copyWith({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape? shape,
  }) =>
      CssDecoration.of(super.copyWith(
        color: color,
        image: image,
        border: border,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient: gradient,
        backgroundBlendMode: backgroundBlendMode,
        shape: shape,
      ));

  @override
  CssDecoration scale(double factor) => CssDecoration.of(super.scale(factor));

  // Animated (AnimatedContainer, DecorationTween): stay CSS all the way. Flutter asks the *end* decoration first,
  // so an animation that ends on a plain BoxDecoration is plain; keep both ends CssDecoration.
  @override
  BoxDecoration? lerpFrom(Decoration? a, double t) {
    final BoxDecoration? d = super.lerpFrom(a, t);
    return d == null ? null : CssDecoration.of(d);
  }

  @override
  BoxDecoration? lerpTo(Decoration? b, double t) {
    final BoxDecoration? d = super.lerpTo(b, t);
    return d == null ? null : CssDecoration.of(d);
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _leaks ? _CssDecorationPainter(this, onChanged) : super.createBoxPainter(onChanged);
}

/// The shadows with the box's own shape cut out, then the box without shadows on top.
class _CssDecorationPainter extends BoxPainter {
  _CssDecorationPainter(this._d, VoidCallback? onChanged)
      : _rest = BoxDecoration(
          color: _d.color,
          image: _d.image,
          border: _d.border,
          borderRadius: _d.borderRadius,
          gradient: _d.gradient,
          backgroundBlendMode: _d.backgroundBlendMode,
          shape: _d.shape,
        ).createBoxPainter(onChanged),
        super(onChanged);

  final CssDecoration _d;
  final BoxPainter _rest;

  void _box(Canvas canvas, Rect r, Paint p, TextDirection? dir) {
    if (_d.shape == BoxShape.circle) {
      canvas.drawCircle(r.center, r.shortestSide / 2, p);
    } else if (_d.borderRadius == null || _d.borderRadius == BorderRadius.zero) {
      canvas.drawRect(r, p);
    } else {
      canvas.drawRRect(_d.borderRadius!.resolve(dir).toRRect(r), p);
    }
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size != null && !size.isEmpty) {
      final Rect rect = offset & size;
      final TextDirection? dir = configuration.textDirection;
      double reach = 0;
      for (final BoxShadow s in _d.boxShadow!) {
        reach = math.max(reach, s.offset.distance + s.spreadRadius.abs() + s.blurRadius * 2);
      }
      canvas.save();
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(reach + 1))
        ..addPath(_d.getClipPath(rect, dir ?? TextDirection.ltr), Offset.zero));
      for (final BoxShadow s in _d.boxShadow!) {
        _box(canvas, rect.shift(s.offset).inflate(s.spreadRadius), s.toPaint(), dir);
      }
      canvas.restore();
    }
    _rest.paint(canvas, offset, configuration);
  }

  @override
  void dispose() {
    _rest.dispose();
    super.dispose();
  }
}
