import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../metal_hero_tokens.dart';
import '../points_metal_theme.dart';

/// `.lb-level-prog` — **four independent timelines on one bar.**
///
/// ```css
/// lb-prog-fill    1.05s cubic-bezier(.22,1,.36,1) .1s both   scaleX(0) -> scaleX(1)
/// lb-prog-glow    2.4s  ease-in-out 1.15s infinite           box-shadow pulse
/// lb-prog-stripes .62s  linear      infinite                 background-position 0 -> 15px
/// lb-prog-sweep   2.8s  ease-in-out 1.3s  infinite           translateX(-120%) -> 120% by 55%
/// ```
///
/// They are deliberately kept on separate controllers. Collapsing them into
/// one tween makes the bar pulse in lockstep, which reads as a loading
/// indicator rather than a layered metal surface — the stripes run 4× faster
/// than the glow and the sweep rests for 45% of its period.
///
/// Every timeline is gated on `MediaQuery.disableAnimationsOf`, matching the
/// `@media (prefers-reduced-motion: reduce)` block that disables all four and
/// hides the sweep outright.
class AeMetalProgressBar extends StatefulWidget {
  const AeMetalProgressBar({
    super.key,
    required this.metal,
    required this.value,
    this.height = 9,
  });

  /// 0..1
  final double value;
  final String metal;

  /// `.lb-level-prog { height: 9px }`; `.pc-rating-track` uses 8.
  final double height;

  @override
  State<AeMetalProgressBar> createState() => _AeMetalProgressBarState();
}

class _AeMetalProgressBarState extends State<AeMetalProgressBar>
    with TickerProviderStateMixin {
  // One controller per CSS animation — see the class doc for why.
  // Constructed eagerly in initState rather than `late final`: under reduced
  // motion none of them is read during build, and lazily-created tickers
  // leave TickerProviderStateMixin with an unstable set.
  late final AnimationController _fill;
  late final AnimationController _glow;
  late final AnimationController _stripes;
  late final AnimationController _sweep;
  late final Animation<double> _fillCurve;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _stripes = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _fillCurve = CurvedAnimation(
      parent: _fill,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
  }

  bool _started = false;
  bool _disposed = false;

  /// The CSS `animation-delay`s are real timers and must be cancellable — a
  /// pending one firing after deactivation re-registers the controller with
  /// the ticker and blows up on the TickerMode lookup.
  final List<Timer> _delays = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start here rather than initState: reduced motion has to be read from
    // MediaQuery, and under it the controllers must never run at all — not
    // merely be ignored at paint time. Leaving them spinning burns battery
    // and keeps a frame permanently scheduled.
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    // Delays: fill .1s, glow 1.15s, sweep 1.3s. Stripes start immediately.
    _start(_fill, const Duration(milliseconds: 100), repeat: false);
    _start(_glow, const Duration(milliseconds: 1150), reverse: true);
    _start(_stripes, Duration.zero);
    _start(_sweep, const Duration(milliseconds: 1300));
  }

  void _start(
    AnimationController c,
    Duration delay, {
    bool repeat = true,
    bool reverse = false,
  }) {
    if (delay == Duration.zero) {
      repeat ? c.repeat(reverse: reverse) : c.forward();
      return;
    }
    _delays.add(Timer(delay, () {
      // `mounted` stays true between deactivate and dispose, so guard on both.
      if (_disposed || !mounted) return;
      repeat ? c.repeat(reverse: reverse) : c.forward();
    }));
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _delays) {
      t.cancel();
    }
    _delays.clear();
    _fill.dispose();
    _glow.dispose();
    _stripes.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PointsMetalTheme.familyATokens(widget.metal);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final h = context.dp(widget.height);
    final value = widget.value.clamp(0.0, 1.0);

    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.progTrack,
            // Matches `.lb-level-prog { box-shadow: inset 0 1px 2px rgba(0,0,0,.14) }`
            // so the empty track reads clearly on light metal ramps (esp. solv).
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 2,
                offset: const Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              // Reduced motion: the fill is present but static.
              animation: reduce ? const AlwaysStoppedAnimation(1.0) : _fillCurve,
              builder: (context, child) {
                final f = reduce ? 1.0 : _fillCurve.value;
                return FractionallySizedBox(
                  widthFactor: (value * f).clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: _buildFill(context, t, h, reduce),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFill(
    BuildContext context,
    AeMetalHeroTokens t,
    double h,
    bool reduce,
  ) {
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        gradient: t.progressFill,
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!reduce) _stripeLayer(context),
            // `> span::after { display: none }` under reduced motion.
            if (!reduce) _sweepLayer(),
          ],
        ),
      ),
    );

    if (reduce) return fill;

    // lb-prog-glow — an outer white bloom pulsing 5px -> 13px.
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final g = Curves.easeInOut.transform(_glow.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.55 + 0.30 * g),
                blurRadius: context.dp(5 + 8 * g),
                spreadRadius: context.dp(-1 + 1 * g),
              ),
            ],
          ),
          child: child,
        );
      },
      child: fill,
    );
  }

  /// `> span::before` — a 45deg repeating stripe tile translated one full
  /// tile (15px) per cycle. A translation, not a fade.
  Widget _stripeLayer(BuildContext context) {
    final tile = context.dp(15);
    return AnimatedBuilder(
      animation: _stripes,
      builder: (context, _) {
        return ClipRect(
          child: Transform.translate(
            offset: Offset(_stripes.value * tile, 0),
            child: CustomPaint(
              painter: _StripePainter(
                tile: tile,
                color: Colors.white.withValues(alpha: 0.28),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  /// `> span::after` — a white band crossing left→right, then resting.
  /// `0% -> -120%`, `55% -> 120%`, holding to 100%.
  Widget _sweepLayer() {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) {
        final v = _sweep.value;
        final progress =
            v <= 0.55 ? Curves.easeInOut.transform(v / 0.55) : 1.0;
        final dx = -1.2 + progress * 2.4;
        return FractionalTranslation(
          translation: Offset(dx, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

/// 45deg stripes at a 15px tile — CSS `background-size: 15px 15px`.
class _StripePainter extends CustomPainter {
  const _StripePainter({required this.tile, required this.color});

  final double tile;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Two bands per tile, drawn as skewed parallelograms.
    for (double x = -size.height - tile; x < size.width + tile; x += tile) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + tile / 2, 0)
        ..lineTo(x + tile / 2, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.tile != tile || old.color != color;
}
