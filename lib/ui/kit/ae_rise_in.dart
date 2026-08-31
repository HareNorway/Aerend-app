import 'dart:async';

import 'package:flutter/material.dart';

/// Staggered rise + fade entrance — mirrors prototype `dg-rise-in` / `dg-fade`.
class AeRiseIn extends StatefulWidget {
  const AeRiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offsetY = 18,
    this.beginOpacity = 0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  /// Opacity the element starts from. `@keyframes au-rise` starts at 0, but
  /// `@keyframes dg-onb-rise` starts at .4 — a tighter, less blinky entrance.
  final double beginOpacity;

  @override
  State<AeRiseIn> createState() => _AeRiseInState();
}

class _AeRiseInState extends State<AeRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _opacity;

  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    _opacity =
        Tween<double>(begin: widget.beginOpacity, end: 1).animate(_curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The gate belongs here, not in initState — inherited-widget lookups are
    // illegal there. It also re-fires if the user toggles the accessibility
    // setting at runtime, hence the _started guard.
    if (MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      _controller.value = 1.0; // land at the end state, do not animate
      return;
    }
    if (_started) return;
    _started = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // A cancellable Timer, not a fire-and-forget Future: `mounted` stays
      // true through deactivation, so it alone cannot prevent a late callback
      // from re-registering the controller and tripping the TickerMode lookup.
      _delayTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return widget.child;

    // Fixed-pixel translate — `@keyframes au-rise` moves every element the
    // same 16–18px regardless of its own height.
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - _curve.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Gentle pulse for referral share icon — mirrors `dg-ref-share`.
class AePulseIcon extends StatefulWidget {
  const AePulseIcon({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 5),
  });

  final Widget child;
  final Duration duration;

  @override
  State<AePulseIcon> createState() => _AePulseIconState();
}

class _AePulseIconState extends State<AePulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Reduced motion must stop the controller, not merely hide its output —
  /// a running controller keeps a frame permanently scheduled.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Subtle breathe on campaign CTA — mirrors `campcta-breathe`.
class AeBreathe extends StatefulWidget {
  const AeBreathe({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<AeBreathe> createState() => _AeBreatheState();
}

class _AeBreatheState extends State<AeBreathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1, end: 1.012).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  /// Reduced motion must stop the controller, not merely hide its output —
  /// a running controller keeps a frame permanently scheduled.
  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Icon pop / arrow nudge on the buy-from-club CTA — mirrors `campcta-pop` / `campcta-arrow`.
class AeCampCtaMotion extends StatefulWidget {
  const AeCampCtaMotion({
    super.key,
    required this.child,
    this.iconPop = false,
    this.duration = const Duration(milliseconds: 3400),
  });

  final Widget child;
  final bool iconPop;
  final Duration duration;

  @override
  State<AeCampCtaMotion> createState() => _AeCampCtaMotionState();
}

class _AeCampCtaMotionState extends State<AeCampCtaMotion>
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

  /// Reduced motion must stop the controller, not merely hide its output —
  /// a running controller keeps a frame permanently scheduled.
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

  double _lerpSegment(
    double t,
    double start,
    double end,
    double from,
    double to,
  ) {
    if (t < start) return from;
    if (t >= end) return to;
    final p = (t - start) / (end - start);
    return from + (to - from) * p;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (widget.iconPop) {
          final scale = t < 0.72 || t >= 1
              ? 1.0
              : t < 0.80
                  ? _lerpSegment(t, 0.72, 0.80, 1, 1.12)
                  : t < 0.88
                      ? _lerpSegment(t, 0.80, 0.88, 1.12, 1.04)
                      : _lerpSegment(t, 0.88, 1, 1.04, 1);
          final rotate = t < 0.72 || t >= 1
              ? 0.0
              : t < 0.80
                  ? _lerpSegment(t, 0.72, 0.80, 0, -0.105)
                  : t < 0.88
                      ? _lerpSegment(t, 0.80, 0.88, -0.105, 0.052)
                      : _lerpSegment(t, 0.88, 1, 0.052, 0);
          return Transform.rotate(
            angle: rotate,
            child: Transform.scale(scale: scale, child: child),
          );
        }

        final dx = t >= 0.72 && t < 0.82
            ? _lerpSegment(t, 0.72, 0.82, 0, 3)
            : 0.0;
        final dy = t >= 0.72 && t < 0.82
            ? _lerpSegment(t, 0.72, 0.82, 0, -3)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Sheen sweep overlay — mirrors `lb-sheen` on `.dg-campcta-shine`.
