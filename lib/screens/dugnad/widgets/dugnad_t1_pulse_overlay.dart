import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_theme.dart';

/// Clamp to [0, 1] before [Curve.transform] / alpha (float drift → 1.0000000000000002).
double _unit(double v) => v.clamp(0.0, 1.0);

/// T1 points-gain FX on the home anchor card — Design `.dg-pcard.gaining`
/// (`gamify.css` / `club-select.jsx`): light sweep, emblem sparks, gold star
/// coins flying from the badge toward the points total, and a rising `+X` pill.
///
/// Ring wash uses club [DugnadClubThemePalette.background] (secondary) at low
/// opacity; the card border and pill/sparks use primary.
class DugnadT1PulseOverlay extends StatefulWidget {
  const DugnadT1PulseOverlay({
    super.key,
    required this.delta,
    this.accent,
  });

  final int delta;

  /// Club primary for border / pill / sparks (falls back to theme primary).
  final Color? accent;

  @override
  State<DugnadT1PulseOverlay> createState() => _DugnadT1PulseOverlayState();
}

class _DugnadT1PulseOverlayState extends State<DugnadT1PulseOverlay>
    with SingleTickerProviderStateMixin {
  static const _goldLight = Color(0xFFF7D979);
  static const _goldMid = Color(0xFFE0A93A);
  static const _goldDark = Color(0xFFC2871C);

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else if (_ctrl.status == AnimationStatus.dismissed) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    // Sparks / gain pill stay on club primary; the wash uses secondary so the
    // metal card does not go muddy-dark under a primary tint.
    final accent = widget.accent ?? theme.primary;
    final secondary = theme.background;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = reduce ? 1.0 : _unit(_ctrl.value);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              if (!reduce) ...[
                _ringGlow(
                  context,
                  primary: accent,
                  secondary: secondary,
                  t: t,
                ),
                _sweep(context, t),
                _sparks(context, accent, t),
                _coins(context, t),
              ],
              _gainPill(context, accent, t, reduce: reduce),
            ],
          );
        },
      ),
    );
  }

  /// `.dg-pcard.gaining::after` — light secondary wash + primary border, 1.15s.
  Widget _ringGlow(
    BuildContext context, {
    required Color primary,
    required Color secondary,
    required double t,
  }) {
    final local = _unit(t / (1150 / 1600));
    double opacity;
    if (local <= 0) {
      opacity = 0;
    } else if (local < 0.12) {
      opacity = local / 0.12;
    } else {
      opacity = 1 - ((local - 0.12) / 0.88);
    }
    opacity = _unit(opacity);
    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.dp(16)),
          // Secondary wash at low alpha — readable metal, not a primary veil.
          color: secondary.withValues(alpha: 0.22 * opacity),
          border: Border.all(
            color: primary.withValues(alpha: 0.92 * opacity),
            width: 2,
          ),
        ),
      ),
    );
  }

  /// `.dg-pcsweep` — light band across the card, 0.85s.
  Widget _sweep(BuildContext context, double t) {
    final local = _unit(t / (850 / 1600));
    if (local <= 0 || local >= 1) return const SizedBox.shrink();
    final x =
        -1.1 + 2.2 * const Cubic(0.3, 0.7, 0.35, 1).transform(local);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final band = constraints.maxWidth * 0.55;
          return ClipRRect(
            borderRadius: BorderRadius.circular(context.dp(16)),
            child: Transform.translate(
              offset: Offset(x * constraints.maxWidth, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: band,
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.34, 0.5, 0.66],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// `.dg-pcspark` — 9 accent rays from the emblem, 0.72s staggered.
  Widget _sparks(BuildContext context, Color accent, double t) {
    final origin = Offset(context.dp(35), context.dp(42));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < 9; i++)
          _spark(
            context,
            accent: accent,
            origin: origin,
            index: i,
            t: t,
          ),
      ],
    );
  }

  Widget _spark(
    BuildContext context, {
    required Color accent,
    required Offset origin,
    required int index,
    required double t,
  }) {
    final delayMs = (index % 3) * 40;
    final start = delayMs / 1600.0;
    const span = 720 / 1600;
    final local = _unit((t - start) / span);
    if (local <= 0) return const SizedBox.shrink();

    final curved = Curves.easeOutCubic.transform(local);
    double opacity;
    if (local < 0.3) {
      opacity = 0.95 * (local / 0.3);
    } else {
      opacity = 0.95 * (1 - (local - 0.3) / 0.7);
    }
    final angle = index * 40 * math.pi / 180;
    final lift = curved * context.dp(30);
    final scaleY = 0.4 + 0.6 * curved;

    final w = context.dp(2.5);
    final h = context.dp(11);
    return Positioned(
      left: origin.dx - w / 2,
      top: origin.dy - h / 2,
      child: Transform.rotate(
        angle: angle,
        child: Transform.translate(
          offset: Offset(0, -lift),
          child: Opacity(
            opacity: _unit(opacity),
            child: Transform.scale(
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `.dg-pccoins` — gold star discs from emblem toward the points number.
  Widget _coins(BuildContext context, double t) {
    final origin = Offset(context.dp(35), context.dp(42));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < 4; i++)
          _coin(context, origin: origin, index: i, t: t),
      ],
    );
  }

  Widget _coin(
    BuildContext context, {
    required Offset origin,
    required int index,
    required double t,
  }) {
    final delayMs = index * 70.0;
    final start = delayMs / 1600;
    const span = 820 / 1600;
    final local = _unit((t - start) / span);
    if (local <= 0) return const SizedBox.shrink();

    final midX = context.dp(6);
    final midY = -context.dp(6);
    final endX = context.dp(34 + index * 7.0);
    final endY = -context.dp(26);

    late final double opacity;
    late final double scale;
    late final Offset delta;
    if (local < 0.18) {
      final u = _unit(local / 0.18);
      opacity = u;
      scale = 0.5 + 0.5 * u;
      delta = Offset(midX * u, midY * u);
    } else {
      final fly = const Cubic(0.3, 0.72, 0.36, 1)
          .transform(_unit((local - 0.18) / 0.82));
      opacity = _unit(1 - fly * 0.95);
      scale = 1 - 0.38 * fly;
      delta = Offset(
        midX + (endX - midX) * fly,
        midY + (endY - midY) * fly,
      );
    }

    final size = context.dp(17);
    return Positioned(
      left: origin.dx + delta.dx - size / 2,
      top: origin.dy + delta.dy - size / 2,
      child: Opacity(
        opacity: _unit(opacity),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment(-0.4, -0.7),
                end: Alignment(0.5, 0.85),
                colors: [_goldLight, _goldMid, _goldDark],
                stops: [0, 0.62, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x6678500A),
                  blurRadius: context.dp(3),
                  offset: Offset(0, context.dp(1)),
                ),
              ],
            ),
            child: Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: context.dp(9),
            ),
          ),
        ),
      ),
    );
  }

  /// `.dg-pcgain` — `+X` pill at left/bottom that rises and fades, 1.6s.
  Widget _gainPill(
    BuildContext context,
    Color accent,
    double t, {
    required bool reduce,
  }) {
    double opacity;
    double dy;
    double scale;
    double rot;
    if (reduce) {
      opacity = 1;
      dy = -context.dp(18);
      scale = 1;
      rot = 0;
    } else if (t < 0.18) {
      final u = _unit(t / 0.18);
      opacity = u;
      dy = context.dp(10) * (1 - u);
      scale = 0.6 + 0.52 * u;
      rot = (-8 + 10 * u) * math.pi / 180;
    } else if (t < 0.32) {
      final u = _unit((t - 0.18) / 0.14);
      opacity = 1;
      dy = -context.dp(2) * u;
      scale = 1.12 - 0.14 * u;
      rot = (2 - 2 * u) * math.pi / 180;
    } else if (t < 0.70) {
      final u = _unit((t - 0.32) / 0.38);
      opacity = 1;
      dy = -context.dp(2) - context.dp(16) * u;
      scale = 0.98 + 0.02 * u;
      rot = 0;
    } else {
      final u = _unit((t - 0.70) / 0.30);
      opacity = 1 - u;
      dy = -context.dp(18) - context.dp(12) * u;
      scale = 1 - 0.08 * u;
      rot = 0;
    }

    return Positioned(
      left: context.dp(58),
      bottom: context.dp(26),
      child: Opacity(
        opacity: _unit(opacity),
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  context.dp(7),
                  context.dp(4),
                  context.dp(9),
                  context.dp(4),
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(context.dp(999)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.75),
                      blurRadius: context.dp(10),
                      offset: Offset(0, context.dp(3)),
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: context.dp(11),
                    ),
                    SizedBox(width: context.dp(3)),
                    Text(
                      '+${widget.delta}',
                      style: aeLabel(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 13 * -0.02,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot scale bump for the metal emblem — Design `.dg-pcbadge-bump`.
class DugnadT1BadgeBump extends StatefulWidget {
  const DugnadT1BadgeBump({super.key, required this.child});

  final Widget child;

  @override
  State<DugnadT1BadgeBump> createState() => _DugnadT1BadgeBumpState();
}

class _DugnadT1BadgeBumpState extends State<DugnadT1BadgeBump>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else if (_ctrl.status == AnimationStatus.dismissed) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _unit(_ctrl.value);
        double scale = 1;
        double rot = 0;
        if (t < 0.30) {
          final u = _unit(t / 0.30);
          scale = 1 + 0.14 * Curves.easeOutBack.transform(u);
          rot = -6 * u * math.pi / 180;
        } else if (t < 0.60) {
          final u = _unit((t - 0.30) / 0.30);
          scale = 1.14 - 0.16 * u;
          rot = (-6 + 8 * u) * math.pi / 180;
        } else {
          final u = _unit((t - 0.60) / 0.40);
          scale = 0.98 + 0.02 * u;
          rot = (2 - 2 * u) * math.pi / 180;
        }
        return Transform.rotate(
          angle: rot,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// One-shot number pop — Design `.dg-pcnum-pulse`.
class DugnadT1NumPulse extends StatefulWidget {
  const DugnadT1NumPulse({super.key, required this.child});

  final Widget child;

  @override
  State<DugnadT1NumPulse> createState() => _DugnadT1NumPulseState();
}

class _DugnadT1NumPulseState extends State<DugnadT1NumPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else if (_ctrl.status == AnimationStatus.dismissed) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _unit(_ctrl.value);
        double scale = 1;
        if (t < 0.34) {
          scale = 1 + 0.16 * Curves.easeOutBack.transform(_unit(t / 0.34));
        } else if (t < 0.62) {
          scale = 1.16 - 0.18 * _unit((t - 0.34) / 0.28);
        } else {
          scale = 0.98 + 0.02 * _unit((t - 0.62) / 0.38);
        }
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
