import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated hourglass — mirrors prototype `Hourglass` + `dg-hg-flip` / `dg-hg-fall`.
class AeHourglass extends StatefulWidget {
  const AeHourglass({
    super.key,
    required this.size,
    required this.color,
    this.fast = false,
    this.spin = true,
  });

  final double size;
  final Color color;
  final bool fast;
  final bool spin;

  @override
  State<AeHourglass> createState() => _AeHourglassState();
}

class _AeHourglassState extends State<AeHourglass>
    with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _sand;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.fast ? 1700 : 3400),
    );
    _sand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant AeHourglass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fast != oldWidget.fast) {
      _flip.duration = Duration(milliseconds: widget.fast ? 1700 : 3400);
    }
    _syncAnimations();
  }

  void _syncAnimations() {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) || !widget.spin;
    if (reduceMotion) {
      _flip.stop();
      _sand.stop();
      return;
    }
    if (!_flip.isAnimating) _flip.repeat();
    if (!_sand.isAnimating) _sand.repeat();
  }

  @override
  void dispose() {
    _flip.dispose();
    _sand.dispose();
    super.dispose();
  }

  /// `dg-hg-flip`: hold 0° until 82%, flip to 180° by 92%, hold.
  double _flipRadians(double t) {
    if (t <= 0.82) return 0;
    if (t >= 0.92) return math.pi;
    final p = Curves.easeInOut.transform((t - 0.82) / 0.10);
    return p * math.pi;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) || !widget.spin;

    if (reduceMotion) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _HourglassPainter(
            color: widget.color,
            streamScale: 0.65,
            streamOpacity: 0.5,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _sand]),
      builder: (context, child) {
        final sandT = _sand.value;
        final streamScale = sandT;
        final streamOpacity = sandT < 0.5
            ? 0.2 + (sandT / 0.5) * 0.8
            : 1.0 - ((sandT - 0.5) / 0.5) * 0.6;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.rotate(
            angle: _flipRadians(_flip.value),
            child: CustomPaint(
              painter: _HourglassPainter(
                color: widget.color,
                streamScale: streamScale,
                streamOpacity: streamOpacity,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({
    required this.color,
    required this.streamScale,
    required this.streamOpacity,
  });

  final Color color;
  final double streamScale;
  final double streamOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final glassStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Top and bottom caps.
    canvas.drawLine(const Offset(6, 3), const Offset(18, 3), stroke);
    canvas.drawLine(const Offset(6, 21), const Offset(18, 21), stroke);

    // Glass outline.
    final glass = Path()
      ..moveTo(6, 3)
      ..cubicTo(6, 8, 12, 9, 12, 12)
      ..cubicTo(12, 9, 18, 8, 18, 3)
      ..moveTo(6, 21)
      ..cubicTo(6, 16, 12, 15, 12, 12)
      ..cubicTo(12, 15, 18, 16, 18, 21);
    canvas.drawPath(glass, glassStroke);

    // Top sand.
    final topSand = Path()
      ..moveTo(8.4, 5.2)
      ..lineTo(15.6, 5.2)
      ..cubicTo(15, 8, 12, 8.7, 12, 10.4)
      ..cubicTo(12, 8.7, 9, 8, 8.4, 5.2)
      ..close();
    canvas.drawPath(
      topSand,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );

    // Bottom sand.
    final bottomSand = Path()
      ..moveTo(9, 18.6)
      ..cubicTo(9.6, 16.6, 11.8, 16, 12, 16)
      ..cubicTo(12.4, 16, 14.4, 16.6, 15, 18.6)
      ..close();
    canvas.drawPath(
      bottomSand,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Falling sand stream — `dg-hg-fall`.
    if (streamScale > 0.01) {
      canvas.save();
      canvas.translate(12, 11.4);
      canvas.scale(1, streamScale.clamp(0.0, 1.0));
      canvas.drawLine(
        Offset.zero,
        const Offset(0, 3.2),
        Paint()
          ..color = color.withValues(alpha: 0.7 * streamOpacity.clamp(0.0, 1.0))
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.streamScale != streamScale ||
        oldDelegate.streamOpacity != streamOpacity;
  }
}

/// Pulsing ring for urgent countdown — mirrors `dg-cd-pulse`.
class AeCountdownPulse extends StatefulWidget {
  const AeCountdownPulse({
    super.key,
    required this.color,
    required this.child,
    this.borderRadius = 999,
  });

  final Color color;
  final Widget child;
  final double borderRadius;

  @override
  State<AeCountdownPulse> createState() => _AeCountdownPulseState();
}

class _AeCountdownPulseState extends State<AeCountdownPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _expand = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  /// Started in initState and merely hidden in build, this kept
  /// running under reduced motion with a frame permanently scheduled.
  /// Gating in build is not gating (rule 16).
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      _motionStarted = false;
      return;
    }
    if (_motionStarted) return;
    _motionStarted = true;
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _expand,
      builder: (context, child) {
        final t = _controller.value;
        final opacity = t < 0.7 ? (1 - t / 0.7) * 0.4 : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (opacity > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: opacity),
                          blurRadius: 0,
                          spreadRadius: _expand.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
