import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Season-final gold cup (`.dgseq-cup` in `Design/dugnad/gamify.css`).
///
/// Gold gradient disc + teardrop laurel nubs that pop in around the rim.
class DugnadBeadBadge extends StatefulWidget {
  const DugnadBeadBadge({
    super.key,
    required this.child,
    this.size = 168,
    this.beadCount = 14,
    this.reduceMotion = false,
    /// When null, uses design gold gradient (`#fff2c4 → #e0a93a`).
    this.color,
    this.beadColor,
    this.discColors,
    this.glowColor,
  });

  static const Color kLaurelGold = Color(0xFFE8C25C);
  static const Color kLaurelSilver = Color(0xFFC9D2DD);
  static const Color kLaurelBronze = Color(0xFFD79A63);

  static const List<Color> kDiscGold = [
    Color(0xFFFFF2C4),
    Color(0xFFF7D27A),
    Color(0xFFE0A93A),
  ];
  static const List<Color> kDiscSilver = [
    Color(0xFFFDFEFE),
    Color(0xFFE2E8EF),
    Color(0xFFBCC6D2),
  ];
  static const List<Color> kDiscBronze = [
    Color(0xFFF8E2C8),
    Color(0xFFE2AC76),
    Color(0xFFC1834B),
  ];

  final Widget child;
  final double size;
  final int beadCount;
  final bool reduceMotion;
  final Color? color;
  final Color? beadColor;
  /// When set, overrides [color]-derived disc fill (T9 gold / T15 silver|bronze).
  final List<Color>? discColors;
  final Color? glowColor;

  Color get resolvedBeadColor => beadColor ?? kLaurelGold;

  @override
  State<DugnadBeadBadge> createState() => _DugnadBeadBadgeState();
}

class _DugnadBeadBadgeState extends State<DugnadBeadBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final AnimationController _pulse;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final beadMs = (420 + widget.beadCount * 24).clamp(700, 1400);
    _pop = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: beadMs),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.reduceMotion) {
      _pop.value = 1;
      _pulse.value = 1;
      return;
    }
    _pulse.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _pop.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // Design: cup 168, disc 118 → ~0.70
    final core = size * (118 / 168);
    // Laurels sit at translateY(-76) in a 168 box → radius ~0.452
    final ringR = size * (76 / 168);
    final beadLen = size * (17 / 168);
    final beadW = size * (8 / 168);

    // `.dgseq-cup-in`: scale(.4) rotate(-16deg) → identity
    final cupAnim = widget.reduceMotion
        ? const AlwaysStoppedAnimation(1.0)
        : CurvedAnimation(
            parent: _pulse,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          );

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _pulse]),
        builder: (context, _) {
          final t = cupAnim.value.clamp(0.0, 1.0);
          // Soft overshoot without Curves.easeOutBack (avoids t>1 crashes).
          final bounce = t < 0.72
              ? Curves.easeOutCubic.transform(t / 0.72)
              : 1.0 +
                  (1.0 - Curves.easeOutCubic.transform((t - 0.72) / 0.28)) *
                      0.04;
          final scale = 0.4 + 0.6 * bounce.clamp(0.0, 1.08);
          final rot = (-16 * (1 - t)) * (math.pi / 180);

          return Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: scale.clamp(0.35, 1.08),
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < widget.beadCount; i++)
                      _laurel(
                        index: i,
                        ringR: ringR,
                        beadLen: beadLen,
                        beadW: beadW,
                      ),
                    _goldDisc(core: core, child: widget.child),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _goldDisc({required double core, required Widget child}) {
    final accent = widget.color;
    final colors = widget.discColors ??
        (accent == null
            ? DugnadBeadBadge.kDiscGold
            : [
                Color.lerp(accent, Colors.white, 0.35)!,
                accent,
                Color.lerp(accent, const Color(0xFF8A6010), 0.22)!,
              ]);
    final glow = widget.glowColor ??
        (colors.length > 1 ? colors[1] : const Color(0xFFD8A028));

    return Container(
      width: core,
      height: core,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-0.35, -1),
          end: const Alignment(0.45, 1),
          colors: colors,
          stops: const [0.0, 0.44, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.55),
            blurRadius: core * 0.28,
            offset: Offset(0, core * 0.12),
            spreadRadius: -core * 0.06,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.55),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  Widget _laurel({
    required int index,
    required double ringR,
    required double beadLen,
    required double beadW,
  }) {
    final n = widget.beadCount;
    // Stagger like CSS: delay = 0.42s + (r / 25.7deg) * 24ms relative to pop.
    final start = (0.08 + index / n * 0.72).clamp(0.0, 0.92);
    final end = (start + 0.28).clamp(0.0, 1.0);
    final t = widget.reduceMotion
        ? 1.0
        : Interval(start, end, curve: Curves.easeOutCubic)
            .transform(_pop.value.clamp(0.0, 1.0));
    final angle = (index / n) * math.pi * 2;
    final opacity = (0.95 * t).clamp(0.0, 1.0);
    final scale = 0.3 + 0.7 * t;
    // CSS: translateY from -40 → -76 while rotating
    final travel = ringR * (0.52 + 0.48 * t);

    return Transform.rotate(
      angle: angle,
      child: Transform.translate(
        offset: Offset(0, -travel),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: beadW,
              height: beadLen,
              decoration: BoxDecoration(
                color: widget.resolvedBeadColor,
                // Teardrop: fat end away from disc (CSS 60% 60% 40% 40%).
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(beadW * 0.75),
                  topRight: Radius.circular(beadW * 0.75),
                  bottomLeft: Radius.circular(beadW * 0.45),
                  bottomRight: Radius.circular(beadW * 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.resolvedBeadColor.withValues(alpha: 0.35),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft rotating searchlight wedges for ceremonial backdrops (`.dgseq-rays`).
class DugnadSpotlightRays extends StatelessWidget {
  const DugnadSpotlightRays({
    super.key,
    required this.progress,
    this.color = Colors.white,
    this.beamCount = 12,
  });

  final Animation<double> progress;
  final Color color;
  final int beamCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return CustomPaint(
          painter: _SpotlightPainter(
            progress: progress.value,
            color: color,
            beamCount: beamCount,
          ),
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.progress,
    required this.color,
    required this.beamCount,
  });

  final double progress;
  final Color color;
  final int beamCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * 0.34);
    final radius = size.longestSide * 0.95;

    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.32, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.55));
    canvas.drawCircle(center, radius * 0.55, wash);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);

    // Conic-style wedges: thin bright slice, then gap (matches dgseq-rays).
    final step = (math.pi * 2) / beamCount;
    for (var i = 0; i < beamCount; i++) {
      canvas.save();
      canvas.rotate(i * step);
      final half = step * 0.12;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: i.isEven ? 0.13 : 0.08),
            color.withValues(alpha: 0.03),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(
          Rect.fromLTWH(-radius * 0.15, -radius, radius * 0.3, radius),
        );
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-radius * math.sin(half), -radius)
        ..lineTo(radius * math.sin(half), -radius)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.beamCount != beamCount;
  }
}
