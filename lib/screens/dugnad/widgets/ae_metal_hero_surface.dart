import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../metal_hero_tokens.dart';
import '../points_metal_theme.dart';

/// Paints a **Family A** metal surface: `.lb-level.metal-*` on Dine poeng and
/// `DGPointsCard`'s `M_BG`/`M_SHADOW` on home **and** profile.
///
/// Layer order matches the CSS stacking, bottom to top:
///
/// 1. `background: linear-gradient(135deg, …)` — the 3-stop ramp with its 48%
///    midpoint.
/// 2. `.lb-level-bg` — **two stacked radial overlays**.
/// 3. The faked `inset` highlight.
/// 4. The child.
///
/// The outer tone-tinted drop shadow sits on the parent, outside the clip.
///
/// Corners use [Material] + [RoundedRectangleBorder] (not hand-placed tip
/// rects) so left and right anti-alias identically against the feed.
class AeMetalHeroSurface extends StatelessWidget {
  const AeMetalHeroSurface({
    super.key,
    required this.metal,
    required this.child,
    this.scale = AeMetalSurfaceScale.hero,
    this.radius = 20,
  });

  /// `bronse` | `solv` | `gull` | `platina`
  final String metal;
  final Widget child;

  final AeMetalSurfaceScale scale;

  /// `.lb-level { border-radius: 20px }`; home's card uses 16.
  final double radius;

  double get _dropOffsetY => scale == AeMetalSurfaceScale.hero ? 18 : 14;
  double get _dropBlur => scale == AeMetalSurfaceScale.hero ? 36 : 26;
  static const double _dropSpread = -16;

  @override
  Widget build(BuildContext context) {
    final t = PointsMetalTheme.familyATokens(metal);
    final r = BorderRadius.circular(context.dp(radius));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: t.dropTint,
            offset: Offset(0, context.dp(_dropOffsetY)),
            blurRadius: context.dp(_dropBlur),
            spreadRadius: context.dp(_dropSpread),
          ),
        ],
      ),
      child: Material(
        color: t.ramp.first,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: t.background),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.76, -1.5),
                    radius: 1.15,
                    colors: [t.specular, t.specular.withValues(alpha: 0)],
                    stops: const [0.0, 0.70],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.96, 1.6),
                    radius: 1.05,
                    colors: [t.bounce, t.bounce.withValues(alpha: 0)],
                    stops: const [0.0, 0.70],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.maxHeight.isFinite &&
                            constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : 140.0;
                    final stop = (context.dp(1) / h).clamp(0.004, 0.06);
                    final inset = t.insetFor(scale);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [inset, inset.withValues(alpha: 0)],
                          stops: [0.0, stop],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
