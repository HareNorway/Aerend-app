import 'package:flutter/material.dart';

import '../theme/design_scale.dart';

/// Which edge a faked CSS `inset` shadow is anchored to.
///
/// A CSS inset with a **negative** y-offset is pushed *up* from the bottom
/// edge. It is not a second top highlight, and painting it from the top puts
/// the glow on the wrong side of the surface.
enum AeInsetEdge { top, bottom }

/// One faked CSS `inset` box-shadow.
///
/// Flutter's [BoxShadow] has no inset mode. Dropping these layers is what
/// flattens a ported surface, and `AeSurface.shiny` did exactly that — its own
/// docstring conceded "Flutter cannot do inset box-shadow", then shipped the
/// outer drop alone.
@immutable
class AeSurfaceInset {
  const AeSurfaceInset.top(this.color, {this.extentPx = 1})
      : edge = AeInsetEdge.top;

  const AeSurfaceInset.bottom(this.color, {required this.extentPx})
      : edge = AeInsetEdge.bottom;

  final Color color;

  /// How far the highlight reaches from its edge, in **design px**.
  final double extentPx;

  final AeInsetEdge edge;
}

/// Paints a surface with faked `inset` layers inside its own clip.
///
/// The stop for each inset comes from the **laid-out** height, never a
/// measured constant: a CSS `0 2px 2px inset` is 2px whatever the box turns
/// out to be. Freezing a height here is the mistake that put `designHeight`
/// 40pt out on the transfer banner.
class AeInsetSurface extends StatelessWidget {
  const AeInsetSurface({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.insets = const [],
    this.shadows = const [],
    this.borderRadius,
    this.isCircle = false,
    this.border,
  });

  /// `--ae-shiny-shadow`: a white top highlight, a purple bottom lift, and a
  /// deep brand-tinted drop.
  factory AeInsetSurface.shiny({
    Key? key,
    required Widget child,
    BorderRadius? borderRadius,
    bool isCircle = false,
    Gradient? gradient,
  }) =>
      AeInsetSurface(
        key: key,
        gradient: gradient ?? kAeShinyGradient,
        borderRadius: borderRadius,
        isCircle: isCircle,
        insets: [
          // 0 2px 2px rgba(255,255,255,.9) inset
          AeSurfaceInset.top(Colors.white.withValues(alpha: 0.9), extentPx: 2),
          // 0 -3px 8px rgba(127,95,196,.14) inset
          AeSurfaceInset.bottom(
            const Color(0xFF7F5FC4).withValues(alpha: 0.14),
            extentPx: 8,
          ),
        ],
        shadows: const [
          // 0 10px 20px -6px rgba(45,27,91,.42)
          BoxShadow(
            color: Color(0x6B2D1B5B),
            offset: Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -6,
          ),
        ],
        child: child,
      );

  /// `--ae-shiny-shadow-sm` — the same three layers, all scaled down. Not a
  /// multiple of the large one: the alphas move too (.9/.14/.42 -> .9/.12/.34).
  factory AeInsetSurface.shinySm({
    Key? key,
    required Widget child,
    BorderRadius? borderRadius,
    bool isCircle = false,
    Gradient? gradient,
  }) =>
      AeInsetSurface(
        key: key,
        gradient: gradient ?? kAeShinyGradient,
        borderRadius: borderRadius,
        isCircle: isCircle,
        insets: [
          AeSurfaceInset.top(Colors.white.withValues(alpha: 0.9)),
          AeSurfaceInset.bottom(
            const Color(0xFF7F5FC4).withValues(alpha: 0.12),
            extentPx: 6,
          ),
        ],
        shadows: const [
          BoxShadow(
            color: Color(0x572D1B5B), // rgba(45,27,91,.34)
            offset: Offset(0, 6),
            blurRadius: 14,
            spreadRadius: -5,
          ),
        ],
        child: child,
      );

  /// `--ae-shiny-shadow-purple` — **one** inset and one drop, not three
  /// layers. Deliberately lighter than the neutral family (rule 18).
  factory AeInsetSurface.shinyPurple({
    Key? key,
    required Widget child,
    BorderRadius? borderRadius,
    bool isCircle = false,
    Gradient? gradient,
  }) =>
      AeInsetSurface(
        key: key,
        gradient: gradient ?? kAeShinyPurpleGradient,
        borderRadius: borderRadius,
        isCircle: isCircle,
        insets: [
          // 0 1px 1px rgba(255,255,255,.45) inset
          AeSurfaceInset.top(Colors.white.withValues(alpha: 0.45)),
        ],
        shadows: const [
          // 0 2px 6px rgba(45,27,91,.4) — a drop, not a second inset.
          BoxShadow(
            color: Color(0x662D1B5B),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
        child: child,
      );

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final List<AeSurfaceInset> insets;
  final List<BoxShadow> shadows;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final radius = isCircle
        ? null
        : (borderRadius ?? BorderRadius.circular(context.dp(999)));
    final shape = isCircle ? BoxShape.circle : BoxShape.rectangle;

    return DecoratedBox(
      // The drop lives outside the clip so it is not painted over.
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
        boxShadow: shadows
            .map((s) => BoxShadow(
                  color: s.color,
                  offset: Offset(context.dp(s.offset.dx), context.dp(s.offset.dy)),
                  blurRadius: context.dp(s.blurRadius),
                  spreadRadius: context.dp(s.spreadRadius),
                ))
            .toList(),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: isCircle
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: radius!),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: shape,
                  borderRadius: radius,
                  gradient: gradient,
                  color: gradient == null ? color : null,
                  border: border,
                ),
              ),
            ),
            for (final inset in insets)
              Positioned.fill(child: _AeInsetLayer(inset: inset)),
            child,
          ],
        ),
      ),
    );
  }
}

/// `--ae-shiny`: linear-gradient(155deg, #fff 0%, #f1ebfb 60%, #e7ddf7 100%)
const Gradient kAeShinyGradient = LinearGradient(
  begin: Alignment(-0.6, -0.8),
  end: Alignment(0.6, 0.8),
  colors: [Color(0xFFFFFFFF), Color(0xFFF1EBFB), Color(0xFFE7DDF7)],
  stops: [0.0, 0.6, 1.0],
);

/// `--ae-shiny-purple`: linear-gradient(150deg, #a98fe0 0%, #7f5fc4 55%,
/// #6b4fa8 100%)
const Gradient kAeShinyPurpleGradient = LinearGradient(
  begin: Alignment(-0.5, -0.85),
  end: Alignment(0.5, 0.85),
  colors: [Color(0xFFA98FE0), Color(0xFF7F5FC4), Color(0xFF6B4FA8)],
  stops: [0.0, 0.55, 1.0],
);

/// Key for the top-edge faked inset, so tests can tell it apart from any
/// sheen or glaze gradient painted on the same surface.
const Key kAeInsetTopKey = ValueKey('ae-surface-inset-top');

/// Key for a bottom-anchored faked inset.
const Key kAeInsetBottomKey = ValueKey('ae-surface-inset-bottom');

class _AeInsetLayer extends StatelessWidget {
  const _AeInsetLayer({required this.inset});

  final AeSurfaceInset inset;

  @override
  Widget build(BuildContext context) {
    final fromBottom = inset.edge == AeInsetEdge.bottom;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : context.dp(48);
          final stop = (context.dp(inset.extentPx) / h).clamp(0.004, 0.6);
          return DecoratedBox(
            key: fromBottom ? kAeInsetBottomKey : kAeInsetTopKey,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:
                    fromBottom ? Alignment.bottomCenter : Alignment.topCenter,
                end: fromBottom ? Alignment.topCenter : Alignment.bottomCenter,
                colors: [inset.color, inset.color.withValues(alpha: 0)],
                stops: [0.0, stop],
              ),
            ),
          );
        },
      ),
    );
  }
}
