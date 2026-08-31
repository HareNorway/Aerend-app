import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_hourglass.dart';
import '../campaign_strings.dart';

/// Countdown intensifies in the final 26h — mirrors the prototype `.cp-*.soon`.
const Duration kTrackerSoonThreshold = Duration(hours: 26);

enum TrackerCountdownSize { full, row, sm }

/// --- Pure time helpers (unit-testable; all on ABSOLUTE instants, no tz math) ---

/// Time left to [windowStart]. Clamped at zero (never negative).
Duration trackerRemaining(DateTime windowStart, {DateTime? now}) {
  final diff = windowStart.difference(now ?? DateTime.now());
  return diff.isNegative ? Duration.zero : diff;
}

/// "Soon" (final-stretch) state: within [kTrackerSoonThreshold] but not expired.
bool trackerIsSoon(Duration remaining) =>
    remaining > Duration.zero && remaining < kTrackerSoonThreshold;

/// Journey progress 0..1 = (now - boughtAt) / (windowStart - boughtAt).
/// Falls back to a 30-day span when [boughtAt] is unknown (prototype parity).
double trackerProgress(DateTime? boughtAt, DateTime windowStart, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final start = boughtAt ?? windowStart.subtract(const Duration(days: 30));
  final span = windowStart.difference(start).inMilliseconds;
  if (span <= 0) return 1;
  final done = n.difference(start).inMilliseconds / span;
  return done.clamp(0.0, 1.0);
}

class _Unit {
  const _Unit(this.value, this.label);
  final int value;
  final String label;
}

/// Ordered units for the countdown, largest first (prototype d/h/m/s logic).
List<_Unit> trackerUnits(Duration r) {
  final s = r.inSeconds;
  final d = s ~/ 86400;
  final h = (s % 86400) ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (d > 0) {
    return [
      _Unit(d, d == 1 ? CampaignStrings.unitDay : CampaignStrings.unitDays),
      _Unit(h, CampaignStrings.unitHours),
      _Unit(m, CampaignStrings.unitMin),
    ];
  }
  if (h > 0) {
    return [
      _Unit(h, h == 1 ? CampaignStrings.unitHour : CampaignStrings.unitHours),
      _Unit(m, CampaignStrings.unitMin),
      _Unit(sec, CampaignStrings.unitSec),
    ];
  }
  return [
    _Unit(m, CampaignStrings.unitMin),
    _Unit(sec, CampaignStrings.unitSec),
  ];
}

/// A self-ticking countdown toward an absolute [windowStart]. Shows relative time
/// only (no wall-clock). Numbers update each second even under reduced motion;
/// only the "soon" pulse is animation and it is reduced-motion-guarded.
class TrackerCountdown extends StatefulWidget {
  const TrackerCountdown({
    super.key,
    required this.windowStart,
    this.size = TrackerCountdownSize.full,
    this.textColor,
  });

  final DateTime windowStart;
  final TrackerCountdownSize size;

  /// Overrides the non-soon number/label colour (e.g. white on the coloured
  /// tracker pill). Defaults to the club theme's text colour.
  final Color? textColor;

  @override
  State<TrackerCountdown> createState() => _TrackerCountdownState();
}

class _TrackerCountdownState extends State<TrackerCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final remaining = trackerRemaining(widget.windowStart);
    final soon = trackerIsSoon(remaining);
    final expired = remaining <= Duration.zero;

    final all = trackerUnits(remaining);
    // Row variant stands beside the dial (which owns the largest unit) → next two.
    final cells = widget.size == TrackerCountdownSize.row
        ? all.skip(1).toList()
        : all;

    final numColor = expired
        ? ScSaasThemeTokens.gray500
        : soon
            ? ScSaasThemeTokens.danger
            : (widget.textColor ?? theme.text);

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0 && widget.size == TrackerCountdownSize.full)
            _sep(context, numColor),
          _cell(context, cells[i], numColor),
        ],
      ],
    );

    if (soon) {
      // Reduced-motion-safe pulse (returns child directly when animations off).
      return DugnadCountdownPulse(color: ScSaasThemeTokens.danger, child: row);
    }
    return row;
  }

  double _numSize(BuildContext c) {
    switch (widget.size) {
      case TrackerCountdownSize.full:
        return c.dp(23);
      case TrackerCountdownSize.row:
        return c.dp(16);
      case TrackerCountdownSize.sm:
        return c.dp(12.5);
    }
  }

  Widget _cell(BuildContext c, _Unit u, Color numColor) {
    final small = widget.size != TrackerCountdownSize.full;
    final sm = widget.size == TrackerCountdownSize.sm;
    final numStyle = TextStyle(
      fontSize: _numSize(c),
      fontWeight: FontWeight.w800,
      color: numColor,
      letterSpacing: _numSize(c) * -0.01,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lblStyle = TextStyle(
      fontSize: sm ? c.dp(8.5) : c.dp(9.5),
      fontWeight: FontWeight.w800,
      color: numColor.withValues(alpha: small ? 0.72 : 1),
      letterSpacing: sm ? c.dp(8.5) * 0.04 : c.dp(9.5) * 0.05,
    );
    // full → number over label (column); row/sm → inline.
    if (widget.size == TrackerCountdownSize.full) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: c.dp(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(u.value.toString().padLeft(2, '0'), style: numStyle),
            SizedBox(height: c.dp(2)),
            Text(u.label.toUpperCase(), style: lblStyle),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(right: c.dp(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            sm ? u.value.toString().padLeft(2, '0') : '${u.value}',
            style: numStyle,
          ),
          SizedBox(width: c.dp(2)),
          Text(sm ? u.label.toUpperCase() : u.label, style: lblStyle),
        ],
      ),
    );
  }

  Widget _sep(BuildContext c, Color color) => Padding(
        padding: EdgeInsets.symmetric(horizontal: c.dp(3)),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: c.dp(19),
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.45),
          ),
        ),
      );
}

/// Circular dial (~92px): ring fills by [progress], goal tick at 12 o'clock,
/// hand-dot on the arc (`.cp-hand-pulse`). Face is a white disc with the
/// largest remaining unit. Pulse is reduced-motion-gated.
class TrackerDial extends StatefulWidget {
  const TrackerDial({
    super.key,
    required this.windowStart,
    this.boughtAt,
    this.size = 92,
  });

  final DateTime windowStart;
  final DateTime? boughtAt;
  final double size;

  @override
  State<TrackerDial> createState() => _TrackerDialState();
}

class _TrackerDialState extends State<TrackerDial>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse;
  bool _pulseStarted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant TrackerDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final remaining = trackerRemaining(widget.windowStart);
    final soon = trackerIsSoon(remaining);
    _pulse.duration = Duration(milliseconds: soon ? 1400 : 2600);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseStarted = false;
      if (_pulse.isAnimating) _pulse.stop();
      _pulse.value = 0;
      return;
    }
    if (!_pulseStarted) {
      _pulseStarted = true;
      _pulse.repeat();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final remaining = trackerRemaining(widget.windowStart);
    final soon = trackerIsSoon(remaining);
    final progress = trackerProgress(widget.boughtAt, widget.windowStart);
    final ringColor = theme.primary;
    final big = trackerUnits(remaining).first;
    final dim = context.dp(widget.size);
    final face = context.dp(74);
    final reduce = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: dim,
      height: dim,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final pulseT = reduce ? 0.0 : (1 - (2 * (_pulse.value - 0.5)).abs());
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(dim, dim),
                painter: _DialRingPainter(
                  progress: progress,
                  ringColor: ringColor,
                  trackColor: Color.lerp(Colors.white, theme.primary, 0.42)!,
                ),
              ),
              Container(
                width: face,
                height: face,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      spreadRadius: 1.5,
                    ),
                    BoxShadow(
                      color: const Color(0x1A140C28),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: const Color(0x42140C28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -7,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${big.value}',
                      style: TextStyle(
                        fontSize: context.dp(30),
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: context.dp(30) * -0.03,
                        color: soon ? theme.primaryHover : theme.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(height: context.dp(3)),
                    Text(
                      big.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: context.dp(9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(9) * 0.11,
                        color: theme.primaryHover,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: Size(dim, dim),
                painter: _DialHandPainter(
                  progress: progress,
                  goalColor:
                      Color.lerp(Colors.white, theme.primaryHover, 0.55)!,
                  handColor: theme.primaryHover,
                  handGlow: theme.primary.withValues(alpha: 0.70 * pulseT),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialRingPainter extends CustomPainter {
  _DialRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 7.0;
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialRingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

class _DialHandPainter extends CustomPainter {
  _DialHandPainter({
    required this.progress,
    required this.goalColor,
    required this.handColor,
    required this.handGlow,
  });

  final double progress;
  final Color goalColor;
  final Color handColor;
  final Color handGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 7.0;
    final radius = (size.width - stroke) / 2;
    final tick = Paint()
      ..color = goalColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, 9), tick);

    final ang = -math.pi / 2 + 2 * math.pi * progress.clamp(0.0, 1.0);
    final hx = center.dx + radius * math.cos(ang);
    final hy = center.dy + radius * math.sin(ang);
    if (handGlow.a > 0.01) {
      canvas.drawCircle(
        Offset(hx, hy),
        8,
        Paint()
          ..color = handGlow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(Offset(hx, hy), 6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(hx, hy), 4, Paint()..color = handColor);
  }

  @override
  bool shouldRepaint(covariant _DialHandPainter old) =>
      old.progress != progress ||
      old.goalColor != goalColor ||
      old.handColor != handColor ||
      old.handGlow != handGlow;
}

/// Label above the countdown: "Leveres om" / "Kan hentes om".
String trackerCountdownLabel(bool delivery) => delivery
    ? CampaignStrings.countdownDeliverIn
    : CampaignStrings.countdownPickupIn;
