import 'dart:async';

import 'package:flutter/material.dart';

/// The two sheen keyframes in this design. They are **different shapes**, not
/// one animation at two speeds.
///
/// The dwell is the effect. A linear tween across the full period gives a
/// constant slow crawl, and no duration value fixes that — which is what
/// `DugnadSheenOverlay` did (`-160 + value * 320` over 7.6s).
enum AeSheenCurve {
  /// `lb-sheen` — sweep first, then wait.
  ///
  /// ```css
  /// 0%   { opacity: 0; transform: translateX(-160%) skewX(-16deg); }
  /// 6%   { opacity: 1; }
  /// 24%  { opacity: 0; transform: translateX(240%) skewX(-16deg); }
  /// 100% { opacity: 0; transform: translateX(240%) skewX(-16deg); }
  /// ```
  ///
  /// Travel is 400% of the band's own width, the skew is persistent, and the
  /// band is parked invisible for 76% of the cycle.
  lbSheen,

  /// `pc-sheen` — wait, then sweep.
  ///
  /// ```css
  /// 0%,55%   { transform: translateX(-100%); }
  /// 72%,100% { transform: translateX(100%); }
  /// ```
  ///
  /// No skew and no opacity envelope; the band's own gradient supplies its
  /// visibility.
  pcSheen,
}

/// A single sheen band swept across its parent.
///
/// Mount inside a `Stack` over the surface being lit, typically via
/// `Positioned.fill`. The parent must clip.
///
/// **Each element keeps its own period.** `lb-sheen` runs at 6.5s, 8.4s and
/// 8.8s on different elements and `pc-sheen` at 9s and 10s — five elements,
/// five periods. Read the period from the element's own rule and never
/// propagate one across a keyframe's users.
class AeSheen extends StatefulWidget {
  const AeSheen({
    super.key,
    required this.period,
    this.curve = AeSheenCurve.lbSheen,
    this.delay,
    this.bandWidthFactor = 0.45,
    this.highlight = const Color(0x73FFFFFF),
  });

  /// This element's own period, from its own CSS rule.
  final Duration period;

  final AeSheenCurve curve;

  /// CSS `animation-delay`. Modelled as a cancellable [Timer], never a
  /// fire-and-forget `Future.delayed`: `mounted` stays true between deactivate
  /// and dispose, so a late callback can re-register the controller and assert
  /// on the `TickerMode` lookup.
  final Duration? delay;

  /// Band width as a fraction of the parent. `.dg-pc-sheen` is 45%.
  final double bandWidthFactor;

  /// Peak colour of the band's own gradient.
  final Color highlight;

  @override
  State<AeSheen> createState() => _AeSheenState();
}

class _AeSheenState extends State<AeSheen> with SingleTickerProviderStateMixin {
  // Declared late but **assigned eagerly in initState**, never with a lazy
  // `late final x = expr` initialiser: under reduced motion that field is
  // never read, which leaves TickerProviderStateMixin with an unstable ticker
  // set and throws on the next lookup.
  late final AnimationController _controller;

  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The gate belongs here, not in initState: inherited lookups are illegal
    // there, and this re-fires when the user toggles the setting at runtime.
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AeSheen old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) {
      _controller.duration = widget.period;
    }
  }

  void _syncMotion() {
    final reduced = MediaQuery.disableAnimationsOf(context);

    if (reduced) {
      _delayTimer?.cancel();
      _delayTimer = null;
      _started = false;
      if (_controller.isAnimating) _controller.stop();
      // Treatment A: `animation: none` resets to the *declared initial* state,
      // which for a sheen is parked off-screen and invisible. Landing it at
      // the end state leaves a permanent white band across the surface.
      _controller.value = 0;
      return;
    }

    if (_started) return;
    _started = true;

    if (widget.delay == null) {
      _controller.repeat();
      return;
    }
    _delayTimer = Timer(widget.delay!, () {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Band offset in multiples of its own width, plus its opacity.
  ///
  /// Both come from the keyframes rather than from a tween across the whole
  /// period — the interval *is* the animation.
  (double, double) _frame(double t) {
    switch (widget.curve) {
      case AeSheenCurve.lbSheen:
        if (t >= 0.24) return (2.4, 0.0); // parked right, invisible
        final p = Curves.easeInOut.transform((t / 0.24).clamp(0.0, 1.0));
        final x = -1.6 + p * 4.0; // -160% -> 240%
        // opacity 0 -> 1 by 6%, -> 0 by 24%
        final o = t <= 0.06
            ? (t / 0.06)
            : (1.0 - ((t - 0.06) / (0.24 - 0.06)));
        return (x, o.clamp(0.0, 1.0));
      case AeSheenCurve.pcSheen:
        if (t <= 0.55) return (-1.0, 1.0); // parked left
        if (t >= 0.72) return (1.0, 1.0); // parked right
        final p =
            Curves.easeInOut.transform(((t - 0.55) / (0.72 - 0.55)).clamp(0.0, 1.0));
        return (-1.0 + p * 2.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final bandWidth = parentWidth * widget.bandWidthFactor;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final (x, opacity) = _frame(_controller.value);
              if (opacity <= 0) return const SizedBox.shrink();

              // CSS stops, not a shared needle: lb-sheen is
              // `transparent, color, transparent` (even); pc-sheen on the
              // player card is `transparent 40%, color 50%, transparent 60%`.
              final stops = switch (widget.curve) {
                AeSheenCurve.lbSheen => const [0.0, 0.5, 1.0],
                AeSheenCurve.pcSheen => const [0.4, 0.5, 0.6],
              };

              Widget band = Container(
                width: bandWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // 125deg on pc-sheen, 100deg on lb-sheen's users; both are
                    // shallow diagonals across a tall thin band.
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.highlight.withValues(alpha: 0),
                      widget.highlight,
                      widget.highlight.withValues(alpha: 0),
                    ],
                    stops: stops,
                  ),
                ),
              );

              if (widget.curve == AeSheenCurve.lbSheen) {
                // skewX(-16deg); tan(16 deg) = 0.2867.
                band = Transform(
                  transform: Matrix4.skewX(-0.2867),
                  alignment: Alignment.center,
                  child: band,
                );
              }

              return Stack(
                children: [
                  Positioned(
                    left: x * bandWidth,
                    top: 0,
                    bottom: 0,
                    width: bandWidth,
                    child: Opacity(opacity: opacity, child: band),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
