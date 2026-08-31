import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// How [DugnadConfetti] pieces are spawned (progress-driven).
enum DugnadConfettiStyle {
  /// Falls from above the viewport (order-complete / welcome).
  rain,
}

/// Progress-driven canvas confetti (rain). For T2 celebration pops use
/// [DugnadDesignBurstConfetti] — Design `Confetti` in `gamify.jsx`.
class DugnadConfetti extends StatelessWidget {
  final Animation<double> progress;
  final List<Color>? colors;
  final bool includeStars;
  final bool fadeByHeight;
  final DugnadConfettiStyle style;
  final int count;

  const DugnadConfetti({
    super.key,
    required this.progress,
    this.colors,
    this.includeStars = true,
    this.fadeByHeight = false,
    this.style = DugnadConfettiStyle.rain,
    this.count = 130,
  });

  static const _colors = [
    Color(0xFF7F5FC4),
    Color(0xFF9B7FD4),
    Color(0xFFF7CF6B),
    Color(0xFFE0A93A),
    Color(0xFF22A769),
    Colors.white,
    Color(0xFF2D1B5B),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? _colors;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => CustomPaint(
          painter: _DugnadRainPainter(
            progress: progress.value.clamp(0.0, 1.0),
            colors: palette,
            includeStars: includeStars,
            fadeByHeight: fadeByHeight,
            count: count,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DugnadRainPainter extends CustomPainter {
  _DugnadRainPainter({
    required this.progress,
    required this.colors,
    required this.includeStars,
    required this.fadeByHeight,
    required this.count,
  });

  final double progress;
  final List<Color> colors;
  final bool includeStars;
  final bool fadeByHeight;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final timeFade = progress > 0.75 ? max(0.0, (1 - progress) / 0.25) : 1.0;
    final random = Random(42);
    for (var i = 0; i < count; i++) {
      final x = size.width * (0.04 + random.nextDouble() * 0.92);
      // Travel far enough that every piece clears the bottom by progress=1.
      final y = (-size.height * (0.08 + random.nextDouble() * 0.14)) +
          progress * size.height * (1.38 + random.nextDouble() * 0.28);
      final drift = sin((progress * 2.2 * pi) + random.nextDouble() * pi * 2) *
          (5 + random.nextDouble() * 13);
      final spin = progress * pi * (2 + random.nextDouble() * 5);
      final scale = 0.8 + random.nextDouble() * 0.7;
      final heightFade = fadeByHeight
          ? (1 - (y / (size.height * 0.55))).clamp(0.0, 1.0)
          : 1.0;
      final fade = timeFade * heightFade;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x + drift, y);
      canvas.rotate(spin);
      canvas.scale(scale);
      final shapeType = includeStars ? i % 5 : i % 3;
      if (shapeType == 0) {
        canvas.drawPath(_starPath(5.2, 2.6), paint);
      } else if (shapeType.isEven) {
        canvas.drawRect(const Rect.fromLTWH(-3, -4, 6, 8), paint);
      } else {
        canvas.drawOval(const Rect.fromLTWH(-3, -4, 6, 8), paint);
      }
      canvas.restore();
    }
  }

  Path _starPath(double outerRadius, double innerRadius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final isOuter = i.isEven;
      final radius = isOuter ? outerRadius : innerRadius;
      final angle = -pi / 2 + (pi / 5) * i;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _DugnadRainPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colors != colors ||
      oldDelegate.includeStars != includeStars ||
      oldDelegate.fadeByHeight != fadeByHeight ||
      oldDelegate.count != count;
}

/// Design `Confetti` from `gamify.jsx` / T2 celebrate-pops.
///
/// Pieces spawn around the **card band** (`y ≈ height * 0.30`), shoot up, then
/// fall and **spread across the full screen**. Not rain-from-top.
///
/// Shapes match the season-finale mock: short rects, round dots, small squares
/// (no stars).
class DugnadDesignBurstConfetti extends StatefulWidget {
  const DugnadDesignBurstConfetti({
    super.key,
    this.colors,
    this.count = 110,
    this.duration = const Duration(milliseconds: 6800),
    /// Multiplies gravity / terminal velocity vs the T2/T3 default (`1`).
    /// Ceremonial finales use `> 1` so pieces fall faster than the modal burst.
    this.fallSpeed = 1,
  });

  final List<Color>? colors;
  final int count;
  final Duration duration;
  final double fallSpeed;

  @override
  State<DugnadDesignBurstConfetti> createState() =>
      _DugnadDesignBurstConfettiState();
}

class _DugnadDesignBurstConfettiState extends State<DugnadDesignBurstConfetti>
    with SingleTickerProviderStateMixin {
  static const _fallbackColors = [
    Color(0xFFF7CF6B),
    Colors.white,
    Color(0xFF9BB8E8),
    Color(0xFF1B2A4A),
    Color(0xFFE0A93A),
    Color(0xFF7F5FC4),
  ];

  late final Ticker _ticker;
  final List<_LivePiece> _pieces = [];
  Size? _size;
  Duration _elapsed = Duration.zero;
  bool _seeded = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _seed(Size size) {
    _pieces.clear();
    final palette = widget.colors ?? _fallbackColors;
    final n = widget.count;
    final rng = Random();
    final w = size.width;
    final h = size.height;
    final speed = widget.fallSpeed.clamp(0.5, 3.0);
    for (var i = 0; i < n; i++) {
      final float = rng.nextDouble() < 0.22;
      // Img1 paper mix: short rects, round dots, small squares — no stars.
      final roll = rng.nextDouble();
      final shape = roll < 0.38
          ? _PieceShape.rect
          : roll < 0.72
              ? _PieceShape.circle
              : _PieceShape.square;
      final base = shape == _PieceShape.circle
          ? 3.5 + rng.nextDouble() * 4.5
          : 5.0 + rng.nextDouble() * 6.5;
      _pieces.add(
        _LivePiece(
          x: w * (0.5 + (rng.nextDouble() - 0.5) * 0.62),
          y: h * 0.30 + (rng.nextDouble() - 0.5) * 50,
          vx: (rng.nextDouble() - 0.5) * 3.4,
          vy: rng.nextDouble() * -3.2 - 1.1,
          g: ((float ? 0.014 : 0.026) + rng.nextDouble() * 0.018) * speed,
          vmax: ((float ? 0.85 : 1.35) + rng.nextDouble() * 0.55) * speed,
          drag: 0.991 + rng.nextDouble() * 0.005,
          pw: shape == _PieceShape.rect ? base * 0.75 : base,
          ph: shape == _PieceShape.rect ? base * 1.35 : base,
          rot: rng.nextDouble() * pi,
          vr: (rng.nextDouble() - 0.5) * 0.055,
          flipT: rng.nextDouble() * 6.3,
          flipSpd: 0.026 + rng.nextDouble() * 0.042,
          sway: 0.9 + rng.nextDouble() * 1.5,
          swayT: rng.nextDouble() * 6.3,
          swaySpd: 0.007 + rng.nextDouble() * 0.011,
          color: palette[i % palette.length],
          shape: shape,
        ),
      );
    }
    _seeded = true;
    _elapsed = Duration.zero;
    _done = false;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (_done || !_seeded || _size == null) return;
    final dtMs = (elapsed - _elapsed).inMicroseconds / 1000.0;
    _elapsed = elapsed;
    // Design advances ~1 physics step per rAF (~16ms). Cap catch-up.
    final steps = max(1, min(3, (dtMs / 16).round()));
    final h = _size!.height;
    final fadeWindow = min(2400.0, widget.duration.inMilliseconds * 0.42);
    final el = elapsed.inMilliseconds.toDouble();
    final fade = el > widget.duration.inMilliseconds - fadeWindow
        ? max(0.0, (widget.duration.inMilliseconds - el) / fadeWindow)
        : 1.0;

    for (final p in _pieces) {
      for (var s = 0; s < steps; s++) {
        p.vy += p.g;
        if (p.vy > p.vmax) p.vy = p.vmax;
        p.swayT += p.swaySpd;
        p.flipT += p.flipSpd;
        p.x += p.vx + sin(p.swayT) * p.sway;
        p.y += p.vy;
        p.vx *= p.drag;
        p.rot += p.vr;
      }
      final edge = p.y > h - 90 ? max(0.0, (h - p.y) / 90) : 1.0;
      p.alpha = (fade * edge).clamp(0.0, 1.0);
    }

    if (elapsed >= widget.duration) {
      _done = true;
      _ticker.stop();
      for (final p in _pieces) {
        p.alpha = 0;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size.width > 0 && size.height > 0 && !_seeded) {
            _size = size;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_seeded) _seed(size);
            });
          }
          return CustomPaint(
            painter: _LiveBurstPainter(pieces: List.of(_pieces)),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

enum _PieceShape { rect, circle, square }

class _LivePiece {
  _LivePiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.g,
    required this.vmax,
    required this.drag,
    required this.pw,
    required this.ph,
    required this.rot,
    required this.vr,
    required this.flipT,
    required this.flipSpd,
    required this.sway,
    required this.swayT,
    required this.swaySpd,
    required this.color,
    required this.shape,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double g;
  final double vmax;
  final double drag;
  final double pw;
  final double ph;
  double rot;
  final double vr;
  double flipT;
  final double flipSpd;
  final double sway;
  double swayT;
  final double swaySpd;
  final Color color;
  final _PieceShape shape;
  double alpha = 1;
}

class _LiveBurstPainter extends CustomPainter {
  _LiveBurstPainter({required this.pieces});

  final List<_LivePiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      if (p.alpha <= 0.01) continue;
      final flip = cos(p.flipT);
      final paint = Paint()
        ..color = p.color.withValues(alpha: flip < 0 ? p.alpha * 0.72 : p.alpha)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      canvas.scale(max(0.12, flip.abs()), 1);
      final rect =
          Rect.fromCenter(center: Offset.zero, width: p.pw, height: p.ph);
      switch (p.shape) {
        case _PieceShape.circle:
          canvas.drawOval(rect, paint);
        case _PieceShape.square:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.2)),
            paint,
          );
        case _PieceShape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LiveBurstPainter oldDelegate) => true;
}

/// Card-local paper bits — Design `.dgpp-confetti` on the T2 card.
class DugnadCardPaperConfetti extends StatelessWidget {
  const DugnadCardPaperConfetti({
    super.key,
    required this.progress,
    required this.colors,
  });

  final Animation<double> progress;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value.clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 12; i++)
                    _bit(
                      i: i,
                      t: t,
                      color: colors[i % colors.length],
                      cx: cx,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _bit({
    required int i,
    required double t,
    required Color color,
    required double cx,
  }) {
    // Design: 1.15s, delay 0.1s + i*22ms on a ~2.8s enter/confetti controller.
    final delay = (100 + i * 22) / 2800.0;
    final span = 1150 / 2800.0;
    final u = ((t - delay) / span).clamp(0.0, 1.0);
    if (u <= 0) return const SizedBox.shrink();

    final curved = const Cubic(0.15, 0.7, 0.4, 1).transform(u);
    final opacity = u < 0.14
        ? u / 0.14
        : (1 - ((u - 0.14) / 0.86)).clamp(0.0, 1.0);
    final dx = (i - 5.5) * 26 * curved;
    final dy = (78 + i * 7) * curved;
    final rot = i * 96 * curved * pi / 180;
    final scale = 0.6 + 0.4 * curved;
    final round = i % 4 == 2;
    final bw = round ? 6.0 : 7.0;
    final bh = round ? 6.0 : 9.0;

    return Positioned(
      left: cx + dx - bw / 2,
      top: 34 + dy - bh / 2,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: bw,
              height: bh,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(round ? 99 : 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
