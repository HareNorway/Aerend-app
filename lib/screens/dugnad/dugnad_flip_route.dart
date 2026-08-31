import 'dart:math' as math;

import 'package:flutter/material.dart';

/// `[data-trans="flip"]` — the 3D perspective depth push `Custom Dugnad.html`
/// sets on `.dg-viewport`.
///
/// ```css
/// [data-trans="flip"] .dg-viewport { perspective: 1400px }
/// @keyframes dg-flip-fwd  { from { transform: perspective(1400px)
///     rotateY(14deg)  translateX(10%)  scale(.94); opacity: 0 } to { … } }
/// @keyframes dg-flip-back { from { transform: perspective(1400px)
///     rotateY(-14deg) translateX(-10%) scale(.94); opacity: 0 } to { … } }
/// ```
///
/// A plain slide does not read the same — the depth comes from the perspective
/// divide, so this builds the real `Matrix4` rather than approximating.
class DugnadFlipRoute<T> extends PageRouteBuilder<T> {
  DugnadFlipRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: kDugnadFlipDuration,
          reverseTransitionDuration: kDugnadFlipDuration,
          transitionsBuilder: (context, animation, secondary, child) {
            return DugnadFlipTransition(animation: animation, child: child);
          },
        );
}

/// `.dg-screen--fwd` / `--back` duration.
const Duration kDugnadFlipDuration = Duration(milliseconds: 520);

/// CSS `perspective: 1400px`.
const double kDugnadFlipPerspective = 1400;

/// `cubic-bezier(.2,.7,.2,1)`
const Curve kDugnadFlipCurve = Cubic(0.2, 0.7, 0.2, 1);

class DugnadFlipTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  /// `true` renders `dg-flip-fwd` (+14deg / +10%), `false` the mirrored
  /// `dg-flip-back`.
  final bool forward;

  const DugnadFlipTransition({
    super.key,
    required this.animation,
    required this.child,
    this.forward = true,
  });

  @override
  Widget build(BuildContext context) {
    // `@media (prefers-reduced-motion: reduce) { .dg-screen { animation: none } }`
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final width = MediaQuery.sizeOf(context).width;
    final curved = CurvedAnimation(parent: animation, curve: kDugnadFlipCurve);
    final sign = forward ? 1.0 : -1.0;

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        // t: 0 at the "from" keyframe, 1 at rest.
        final t = curved.value;
        final rest = 1 - t;

        final angle = sign * 14 * math.pi / 180 * rest;
        final dx = sign * width * 0.10 * rest;
        final scale = 0.94 + (1 - 0.94) * t;

        // CSS applies right-to-left, so the matrix is P · rotateY · translate
        // · scale — the same order the cascade multiplies in.
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 1 / kDugnadFlipPerspective)
          ..rotateY(angle)
          ..translateByDouble(dx, 0, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);

        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}
