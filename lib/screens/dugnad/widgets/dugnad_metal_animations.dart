import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';

import '../../../theme/sc_saas_theme.dart';
import '../dugnad_club_theme.dart';
import '../points_metal_theme.dart';

/// Soft metallic reflection gradient — wide feathered band.
///
/// Peak matches Design `.lb-entry-shine` / `.tb-shine`:
/// `rgba(255,255,255,.6)` on gold, `.22` on the transfer sweep. Feed cards
/// use [overContent] so the band stays a highlight, not a grey veil.
LinearGradient dugnadMetalGlazeGradient({
  Alignment begin = const Alignment(-0.85, -0.3),
  Alignment end = const Alignment(0.85, 0.3),
  bool overContent = false,
}) {
  final peak = overContent ? 0.60 : 0.50;
  const mid = 0.32;
  final edge = overContent ? 0.12 : 0.11;
  return LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Colors.white.withValues(alpha: 0),
      Colors.white.withValues(alpha: edge),
      Colors.white.withValues(alpha: mid),
      Colors.white.withValues(alpha: peak),
      Colors.white.withValues(alpha: mid),
      Colors.white.withValues(alpha: edge),
      Colors.white.withValues(alpha: 0),
    ],
    stops: const [0.0, 0.14, 0.34, 0.5, 0.66, 0.86, 1.0],
  );
}

/// Band-local shine — perpendicular to the sweep travel direction.
LinearGradient dugnadMetalGlazeBandGradient({bool overContent = false}) {
  final peak = overContent ? 0.60 : 0.50;
  const mid = 0.32;
  final edge = overContent ? 0.12 : 0.11;
  return LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.white.withValues(alpha: 0),
      Colors.white.withValues(alpha: edge),
      Colors.white.withValues(alpha: mid),
      Colors.white.withValues(alpha: peak),
      Colors.white.withValues(alpha: mid),
      Colors.white.withValues(alpha: edge),
      Colors.white.withValues(alpha: 0),
    ],
    stops: const [0.0, 0.14, 0.34, 0.5, 0.66, 0.86, 1.0],
  );
}

/// Gradient travel angle — matches [dugnadMetalGlazeGradient] begin/end.
final double kDugnadMetalGlazeSweepAngle = math.atan2(0.6, 1.7);
({double opacity, double xFactor}) dugnadLbSheenAt(double t) {
  if (t < 0.04) {
    return (opacity: (t / 0.04) * 0.58, xFactor: -1.55);
  }
  if (t < 0.48) {
    final sweep = (t - 0.04) / 0.44;
    return (
      opacity: 0.58 + sweep * 0.22,
      xFactor: -1.55 + sweep * 3.9,
    );
  }
  return (opacity: 0, xFactor: 2.35);
}

/// Static ambient highlight — subtle polish on metal cards.
class DugnadMetalAmbientGlaze extends StatelessWidget {
  const DugnadMetalAmbientGlaze({
    super.key,
    required this.borderRadius,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `.lb-prize::before` / `.lb-entry::before`:
            // linear-gradient(180deg, rgba(255,255,255,.6), .14 55%, transparent)
            // over the top 58%. The previous 0.22 polish left metal cards dull
            // next to the HTML prototype.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.32, 0.58],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: const Alignment(0.55, 1.0),
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.38, 0.72],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated glaze sweep layer.
class _MetalGlazeSweepLayer extends StatelessWidget {
  const _MetalGlazeSweepLayer({
    required this.animation,
    required this.bandWidthFactor,
    required this.borderRadius,
    this.overContent = false,
  });

  final Animation<double> animation;
  final double bandWidthFactor;
  final double borderRadius;
  final bool overContent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final sheen = dugnadLbSheenAt(animation.value);
        if (sheen.opacity <= 0.01) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            if (w <= 0 || h <= 0) return const SizedBox.shrink();

            final bandWidth = w * bandWidthFactor;
            final angle = kDugnadMetalGlazeSweepAngle;
            final cos = math.cos(angle);
            final sin = math.sin(angle);
            // Long axis of the stripe (perpendicular to travel) must cover the
            // full card — portrait cards need more than a plain diagonal.
            final bandLength =
                (w * sin.abs() + h * cos.abs()) * 1.55 + bandWidth;
            final travel = math.sqrt(w * w + h * h) + bandLength;
            final t = (sheen.xFactor + 1.55) / 3.9;
            final along = -bandLength * 0.55 + t * travel;
            final cx = along * cos;
            final cy = along * sin;

            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: cx - bandWidth / 2,
                    top: cy - bandLength / 2,
                    width: bandWidth,
                    height: bandLength,
                    child: Transform.rotate(
                      angle: angle,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: sheen.opacity.clamp(
                          0,
                          overContent ? 0.85 : 0.50,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: dugnadMetalGlazeBandGradient(
                              overContent: overContent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Shared glaze loop length — keep call sites within ~±0.2s of this.
const kDugnadMetalGlazeDuration = Duration(milliseconds: 4200);

/// Animated + ambient glaze overlay.
class DugnadMetalGlazeOverlay extends StatefulWidget {
  const DugnadMetalGlazeOverlay({
    super.key,
    this.borderRadius = 16,
    this.duration = kDugnadMetalGlazeDuration,
    /// Cycle start offset in `[0, 1)` so stacked glazes don't sweep in sync.
    this.phase = 0,
    this.enabled = true,
    this.overContent = false,
  });

  final double borderRadius;
  final Duration duration;
  /// Where in the loop to begin (`0` = start, `0.5` = halfway). Same speed.
  final double phase;
  final bool enabled;
  /// When true, renders on top of text/UI with a brighter sweep.
  final bool overContent;

  @override
  State<DugnadMetalGlazeOverlay> createState() =>
      _DugnadMetalGlazeOverlayState();
}

class _DugnadMetalGlazeOverlayState extends State<DugnadMetalGlazeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = _normalizedPhase(widget.phase);
  }

  static double _normalizedPhase(double phase) {
    if (!phase.isFinite) return 0;
    final p = phase % 1.0;
    return p < 0 ? p + 1.0 : p;
  }

  @override
  void didUpdateWidget(covariant DugnadMetalGlazeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Treatment **A** (`animation: none`) — reset to the *declared initial*
  /// state, not the end state. These are sheens: their parked transform sits
  /// off-screen, so resetting hides them. Landing one at its end state would
  /// leave a white band across the card permanently.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = _normalizedPhase(widget.phase);
      return;
    }
      if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!widget.overContent)
            DugnadMetalAmbientGlaze(borderRadius: widget.borderRadius),
          if (!reduceMotion)
            _MetalGlazeSweepLayer(
              animation: _controller,
              bandWidthFactor: widget.overContent ? 0.58 : 0.62,
              borderRadius: widget.borderRadius,
              overContent: widget.overContent,
            )
          else if (widget.overContent)
            DugnadMetalAmbientGlaze(borderRadius: widget.borderRadius),
        ],
      ),
    );
  }
}

/// Card-level glaze clip — legacy wrapper; prefer [DugnadMetalGlazeOverlay] in a Stack.
class DugnadLbSheenClip extends StatelessWidget {
  const DugnadLbSheenClip({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.duration = kDugnadMetalGlazeDuration,
    this.phase = 0,
    this.enabled = true,
  });

  final Widget child;
  final double borderRadius;
  final Duration duration;
  final double phase;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: DugnadMetalGlazeOverlay(
              borderRadius: borderRadius,
              duration: duration,
              phase: phase,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular sheen on the metal star emblem — `.dg-pc-badge .sheen`.
class DugnadEmblemSheen extends StatefulWidget {
  const DugnadEmblemSheen({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 4200),
  });

  final Widget child;
  final Duration duration;

  @override
  State<DugnadEmblemSheen> createState() => _DugnadEmblemSheenState();
}

class _DugnadEmblemSheenState extends State<DugnadEmblemSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Treatment **A** (`animation: none`) — reset to the *declared initial*
  /// state, not the end state. These are sheens: their parked transform sits
  /// off-screen, so resetting hides them. Landing one at its end state would
  /// leave a white band across the card permanently.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      return;
    }
      if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipOval(
              child: _MetalGlazeSweepLayer(
                animation: _controller,
                bandWidthFactor: 0.72,
                borderRadius: 999,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Striped metal progress with marching lines — `lb-prog-stripes`.
class DugnadAnimatedMetalProgressBar extends StatefulWidget {
  const DugnadAnimatedMetalProgressBar({
    super.key,
    required this.metal,
    required this.progressPercent,
    this.height = 6,
    this.fadeEdges = true,
  });

  final String metal;
  final int progressPercent;
  final double height;
  final bool fadeEdges;

  @override
  State<DugnadAnimatedMetalProgressBar> createState() =>
      _DugnadAnimatedMetalProgressBarState();
}

class _DugnadAnimatedMetalProgressBarState
    extends State<DugnadAnimatedMetalProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _stripes;
  late final AnimationController _gloss;

  @override
  void initState() {
    super.initState();
    _stripes = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _gloss = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Treatment **A** (`animation: none`) — reset to the *declared initial*
  /// state, not the end state. These are sheens: their parked transform sits
  /// off-screen, so resetting hides them. Landing one at its end state would
  /// leave a white band across the card permanently.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      for (final c in [_stripes, _gloss]) {
        if (c.isAnimating) c.stop();
        c.value = 0;
      }
      return;
    }
      for (final c in [_stripes, _gloss]) {
        if (!c.isAnimating) c.repeat();
      }
  }

  @override
  void dispose() {
    _stripes.dispose();
    _gloss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.progressPercent.clamp(0, 100);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: PointsMetalTheme
                  .levelProgressTrack(widget.metal)
                  .withValues(alpha: 0.55),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct / 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: PointsMetalTheme.levelProgressFill(widget.metal),
                      ),
                    ),
                  ),
                  if (reduceMotion)
                    _MaybeFadedStripeOverlay(
                      fadeEdges: widget.fadeEdges,
                      child: CustomPaint(
                        // 14px 45° white hatch — prototype `.pc-rating-hero`
                        // fill (`rgba(255,255,255,.4)`, `background-size:14px`).
                        painter: MetalProgressStripePainter(
                          stripeColor: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                    )
                  else
                    AnimatedBuilder(
                      animation: _stripes,
                      builder: (context, _) {
                        return _MaybeFadedStripeOverlay(
                          fadeEdges: widget.fadeEdges,
                          child: CustomPaint(
                            painter: MetalProgressStripePainter(
                              stripeColor: Colors.white.withValues(alpha: 0.40),
                              offset: _stripes.value * 14,
                            ),
                          ),
                        );
                      },
                    ),
                  if (!reduceMotion)
                    _ProgressBarGlossSweep(animation: _gloss),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaybeFadedStripeOverlay extends StatelessWidget {
  const _MaybeFadedStripeOverlay({
    required this.fadeEdges,
    required this.child,
  });

  final bool fadeEdges;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!fadeEdges) return child;
    return _FadedStripeOverlay(child: child);
  }
}

/// Carryover mini graphic — metal badge → flying coin → next-season badge (`dg-co-fly`).
class DugnadCarryoverFlyGraphic extends StatefulWidget {
  const DugnadCarryoverFlyGraphic({
    super.key,
    required this.dotColor,
  });

  final Color dotColor;

  @override
  State<DugnadCarryoverFlyGraphic> createState() =>
      _DugnadCarryoverFlyGraphicState();
}

class _DugnadCarryoverFlyGraphicState extends State<DugnadCarryoverFlyGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Treatment **A** (`animation: none`) — reset to the *declared initial*
  /// state, not the end state. These are sheens: their parked transform sits
  /// off-screen, so resetting hides them. Landing one at its end state would
  /// leave a white band across the card permanently.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_fly.isAnimating) _fly.stop();
      _fly.value = 0;
      return;
    }
      if (!_fly.isAnimating) _fly.repeat();
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: context.dp(50),
      height: context.dp(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 11,
            child: Container(
              height: context.dp(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.dp(2)),
                color: theme.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 2,
            child: _CarryoverNode(
              color: widget.dotColor,
              child: Icon(Icons.star_rounded, size: context.dp(10), color: Colors.white),
            ),
          ),
          Positioned(
            right: 0,
            top: 2,
            child: _CarryoverNode(
              gradient: theme.shinyGradient,
              shadowColor: theme.primary.withValues(alpha: 0.35),
              child: Icon(Icons.auto_awesome, size: context.dp(11), color: Colors.white),
            ),
          ),
          if (!reduceMotion)
            AnimatedBuilder(
              animation: _fly,
              builder: (context, _) {
                final t = _fly.value;
                double opacity = 0;
                double dx = 0;
                double dy = 0;
                double scale = 0.5;

                if (t < 0.1) {
                  final p = t / 0.1;
                  opacity = p;
                  dx = 2 * p;
                  dy = -3 * p;
                  scale = 0.5 + 0.5 * p;
                } else if (t < 0.55) {
                  final p = (t - 0.1) / 0.45;
                  opacity = 1;
                  dx = 2 + 18 * p;
                  dy = -3;
                  scale = 1;
                } else if (t < 0.7) {
                  final p = (t - 0.55) / 0.15;
                  opacity = 1 - p;
                  dx = 20 + 10 * p;
                  dy = -3 + 3 * p;
                  scale = 1 - 0.5 * p;
                }

                return Positioned(
                  left: 4 + dx,
                  top: 12 + dy - 6.5,
                  child: Opacity(
                    opacity: opacity.clamp(0, 1),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: context.dp(13),
                        height: context.dp(13),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFE9A8), Color(0xFFE7B542)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD8A028).withValues(alpha: 0.7),
                              blurRadius: context.dp(3),
                              offset: const Offset(0, 1),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: context.dp(8),
                          color: Color(0xFF7A5410),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CarryoverNode extends StatelessWidget {
  const _CarryoverNode({
    required this.child,
    this.color,
    this.gradient,
    this.shadowColor,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(20),
      height: context.dp(20),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(context.dp(7)),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? ScSaasThemeTokens.text.withValues(alpha: 0.2)),
            blurRadius: context.dp(7),
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: child,
    );
  }
}
/// Fades stripe pattern at fill edges so lines don't cut off abruptly.
class _FadedStripeOverlay extends StatelessWidget {
  const _FadedStripeOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return ui.Gradient.linear(
          Offset.zero,
          Offset(bounds.width, 0),
          const [
            Color(0x00FFFFFF),
            Color(0x66FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          const [0.0, 0.06, 0.18, 0.76, 1.0],
        );
      },
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          return ui.Gradient.linear(
            Offset(0, bounds.height),
            Offset(0, 0),
            const [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            const [0.0, 0.5, 1.0],
          );
        },
        child: child,
      ),
    );
  }
}

/// Occasional gloss sweep across the fill — `.pc-rating-track > span::after`.
class _ProgressBarGlossSweep extends StatelessWidget {
  const _ProgressBarGlossSweep({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Ease-in-out pulse: visible ~35% of cycle, centred sweep.
        final t = animation.value;
        double opacity = 0;
        double x = -1.2;
        if (t > 0.12 && t < 0.55) {
          final p = (t - 0.12) / 0.43;
          opacity = (p < 0.5 ? p * 2 : (1 - p) * 2) * 0.55;
          x = -1.2 + p * 2.4;
        }
        if (opacity <= 0.01) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final band = constraints.maxWidth * 0.42;
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: constraints.maxWidth * 2.5,
                child: Transform.translate(
                  offset: Offset(x * band, 0),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: band,
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: const [0.2, 0.5, 0.8],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Public stripe painter with optional animated offset.
class MetalProgressStripePainter extends CustomPainter {
  MetalProgressStripePainter({
    required this.stripeColor,
    this.offset = 0,
  });

  final Color stripeColor;
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const cell = 14.0;
    const stripeWidth = cell * 0.5;
    final diagonal = size.height + size.width;

    for (var x = -diagonal + offset; x < diagonal; x += cell) {
      // Per-stripe soft alpha — avoids hard parallelogram edges.
      final centerX = x + stripeWidth * 0.5;
      final edgeFade = _horizontalFade(centerX, size.width);
      if (edgeFade <= 0.01) continue;

      paint.color = stripeColor.withValues(
        alpha: stripeColor.a * edgeFade,
      );

      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + stripeWidth, 0)
        ..lineTo(x + stripeWidth, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  double _horizontalFade(double x, double width) {
    const inFade = 0.14;
    const outStart = 0.68;
    final t = (x / width).clamp(0.0, 1.0);
    if (t < inFade) return t / inFade;
    if (t > outStart) return (1 - t) / (1 - outStart);
    return 1;
  }

  @override
  bool shouldRepaint(covariant MetalProgressStripePainter oldDelegate) {
    return oldDelegate.stripeColor != stripeColor ||
        oldDelegate.offset != offset;
  }
}

