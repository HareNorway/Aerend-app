import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kit/bergen_kit.dart';

/// The design's `skinnSveip` — a soft white band that sweeps across a metal
/// surface every few seconds — and `medSnurr`, the conic highlight that turns
/// around the medal. Both stop under reduced motion and leave a static sheen.
class MegShine extends StatefulWidget {
  const MegShine({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 4600),
    this.delay = const Duration(milliseconds: 1200),
    this.bandFraction = .34,
    this.borderRadius,
    this.opacity = .85,
  });

  final Widget child;
  final Duration period;
  final Duration delay;
  final double bandFraction;
  final BorderRadius? borderRadius;
  final double opacity;

  @override
  State<MegShine> createState() => _MegShineState();
}

class _MegShineState extends State<MegShine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  bool _started = false;
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (BergenTokens.motion(context, widget.period) == Duration.zero) return;
    _delay = Timer(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // cubic-bezier(.4,0,.2,1): ease in-out, from just off the left to just off the right.
                  final t = Curves.easeInOut.transform(_c.value);
                  final x = -widget.bandFraction + t * (1 + widget.bandFraction * 2);
                  return FractionallySizedBox(
                    alignment: Alignment(-1 + 2 * x.clamp(0.0, 1.0), 0),
                    widthFactor: widget.bandFraction,
                    child: Transform(
                      transform: Matrix4.skewX(-.2),
                      alignment: Alignment.center,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: widget.opacity), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `medSnurr`: the conic arc of light turning behind the medal (inset -6px).
class MegSpinRing extends StatefulWidget {
  const MegSpinRing({super.key, required this.size, this.period = const Duration(milliseconds: 3200)});

  final double size;
  final Duration period;

  @override
  State<MegSpinRing> createState() => _MegSpinRingState();
}

class _MegSpinRingState extends State<MegSpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (BergenTokens.motion(context, widget.period) != Duration.zero) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.rotate(
        angle: _c.value * 2 * math.pi,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Color(0x00F2C14E), Color(0xF2FFF0BE), Color(0x00F2C14E), Color(0x00F2C14E)],
              stops: [0, .167, .36, 1],
            ),
          ),
        ),
      ),
    );
  }
}
