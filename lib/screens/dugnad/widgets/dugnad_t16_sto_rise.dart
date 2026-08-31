import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../celebration_models.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_sto_utils.dart';
import '../points_metal_theme.dart';
import 'dugnad_metal_animations.dart';

/// T16 — STØ rating rose. Metal badge, lottery digits, +Δ chip, ring + bar.
class DugnadT16StoRiseBody extends StatefulWidget {
  const DugnadT16StoRiseBody({
    super.key,
    required this.item,
    required this.reduceMotion,
  });

  final PendingCelebration item;
  final bool reduceMotion;

  @override
  State<DugnadT16StoRiseBody> createState() => _DugnadT16StoRiseBodyState();
}

class _DugnadT16StoRiseBodyState extends State<DugnadT16StoRiseBody>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _pill;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.reduceMotion) {
      _main.value = 1;
      _pill.value = 1;
      return;
    }
    if (_main.status == AnimationStatus.dismissed) {
      _main.forward();
      _pill.forward();
    }
  }

  @override
  void dispose() {
    _main.dispose();
    _pill.dispose();
    super.dispose();
  }

  int get _from => widget.item.intPayload('previous_sto') ?? 0;
  int get _to => widget.item.intPayload('new_sto') ?? _from;
  int get _delta {
    final d = widget.item.intPayload('delta');
    if (d != null && d > 0) return d;
    return math.max(0, _to - _from);
  }

  String get _metal {
    final m = (widget.item.stringPayload('metal') ?? '').trim().toLowerCase();
    if (m.isNotEmpty) return m;
    return dugnadMetalForRating(_to);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final l10n = AppLocalizations.of(context)!;
    final metal = _metal;
    final disc = PointsMetalTheme.stoRiseDisc(metal);
    final fg = disc.ink;
    // `.dgcp-sto .lbl` — `color-mix(in srgb, var(--mi) 92%, #000)`.
    final stoFg = Color.lerp(fg, Colors.black, 0.08)!;
    final rawNext = widget.item.stringPayload('next_metal_label')?.trim();
    final nextLabel = (rawNext != null && rawNext.isNotEmpty)
        ? rawNext
        : _fallbackNextLabel(widget.item.stringPayload('next_metal'));
    final remaining = widget.item.intPayload('remaining_to_next') ?? 0;
    final endPct = (widget.item.intPayload('progress_percent') ?? 0).clamp(0, 100);
    final startPct =
        (widget.item.intPayload('previous_progress_percent') ?? 0).clamp(0, 100);
    final reason = _reason(l10n, widget.item.stringPayload('action') ?? '');
    final atMax = nextLabel == null || nextLabel.isEmpty || remaining <= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: context.dp(108),
          height: context.dp(108),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _MetalStoBadge(
                metal: metal,
                size: context.dp(92),
                progress: widget.reduceMotion ? endPct / 100 : null,
                progressAnimation: widget.reduceMotion
                    ? null
                    : CurvedAnimation(
                        parent: _main,
                        curve: const Interval(0.22, 0.92, curve: Curves.easeOutCubic),
                      ),
                startProgress: startPct / 100,
                endProgress: endPct / 100,
                reduceMotion: widget.reduceMotion,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _main,
                      builder: (context, _) {
                        return _SlotNumber(
                          from: _from,
                          to: _to,
                          t: widget.reduceMotion ? 1 : _main.value,
                          style: aeH2(color: fg).copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            leadingDistribution: TextLeadingDistribution.even,
                            letterSpacing: -0.04 * 38,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.50),
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.dp(3)),
                    Text(
                      dugnadStoRatingLabel,
                      style: aeLabel(color: stoFg).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        height: 1,
                        letterSpacing: 0.20 * 10,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.55),
                            offset: const Offset(0, 1),
                          ),
                          Shadow(
                            color: Color.lerp(fg, Colors.black, 0.35)!
                                .withValues(alpha: 0.30),
                            offset: const Offset(0, -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_delta > 0)
                Positioned(
                  right: -context.dp(4),
                  top: context.dp(26),
                  child: _GainChip(
                    delta: _delta,
                    accent: theme.primary,
                    animation: _pill,
                    reduceMotion: widget.reduceMotion,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.dp(18)),
        Text(
          l10n.celebrationTitleT16.toUpperCase(),
          textAlign: TextAlign.center,
          style: aeLabel(color: theme.ink).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.15,
          ),
        ),
        SizedBox(height: context.dp(8)),
        AnimatedBuilder(
          animation: _main,
          builder: (context, _) {
            final shownTo = widget.reduceMotion
                ? _to
                : _countUp(_from, _to, _main.value);
            return Text(
              '$_from → $shownTo $dugnadStoRatingLabel',
              textAlign: TextAlign.center,
              style: aeTitle(color: theme.ink).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
          },
        ),
        if (reason.isNotEmpty) ...[
          SizedBox(height: context.dp(6)),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: aeBody(color: const Color(0xFF6B6580)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
        SizedBox(height: context.dp(16)),
        AnimatedBuilder(
          animation: _main,
          builder: (context, _) {
            final t = widget.reduceMotion
                ? 1.0
                : const Interval(0.22, 0.92, curve: Curves.easeOutCubic)
                    .transform(_main.value.clamp(0.0, 1.0));
            final pct = (startPct + (endPct - startPct) * t).round();
            return DugnadAnimatedMetalProgressBar(
              metal: metal,
              progressPercent: pct,
              height: context.dp(7),
            );
          },
        ),
        SizedBox(height: context.dp(10)),
        Text.rich(
          TextSpan(
            children: atMax
                ? [
                    TextSpan(
                      text: l10n.celebrationStoAtTopLeague(
                        _leagueLabel(metal),
                      ),
                    ),
                  ]
                : [
                    TextSpan(
                      text: '$remaining $dugnadStoRatingLabel',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: l10n.celebrationStoRemainingSuffix(nextLabel),
                    ),
                  ],
          ),
          textAlign: TextAlign.center,
          style: aeBody(color: theme.ink).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  String? _fallbackNextLabel(String? key) {
    final k = (key ?? '').trim().toLowerCase();
    if (k.isEmpty) return null;
    return dugnadMetalDisplayLabel(k);
  }

  String _leagueLabel(String metal) => dugnadMetalDisplayLabel(metal);

  String _reason(AppLocalizations l10n, String action) {
    switch (action) {
      case 'campaign_purchase':
        return l10n.celebrationStoReasonCampaign;
      case 'subscription_donation':
        return l10n.celebrationStoReasonDonation;
      case 'referral':
      case 'referred_join':
      case 'referral_milestone':
        return l10n.celebrationStoReasonReferral;
      case 'badge_unlock':
        return l10n.celebrationStoReasonBadge;
      case 'weekly_challenge_bonus':
        return l10n.celebrationStoReasonChallenge;
      case 'season_goal_bonus':
        return l10n.celebrationStoReasonSeasonGoal;
      case 'streak_bonus':
        return l10n.celebrationStoReasonStreak;
      case 'club_shop_purchase':
        return l10n.celebrationStoReasonShop;
      case 'welcome_bonus':
        return l10n.celebrationStoReasonWelcome;
      case 'tour_complete':
        return l10n.celebrationStoReasonTour;
      case 'season_carryover':
        return l10n.celebrationStoReasonCarryover;
      default:
        return l10n.celebrationStoReasonDefault;
    }
  }
}

class _MetalStoBadge extends StatelessWidget {
  const _MetalStoBadge({
    required this.metal,
    required this.size,
    required this.child,
    required this.startProgress,
    required this.endProgress,
    required this.reduceMotion,
    this.progress,
    this.progressAnimation,
  });

  final String metal;
  final double size;
  final Widget child;
  final double startProgress;
  final double endProgress;
  final bool reduceMotion;
  final double? progress;
  final Animation<double>? progressAnimation;

  @override
  Widget build(BuildContext context) {
    final disc = PointsMetalTheme.stoRiseDisc(metal);
    final rim = Color.lerp(disc.m2, Colors.black, 0.72)!;
    final contact = Color.lerp(disc.ink, Colors.black, 0.25)!;
    // `.dgcp-sto .arc` — 4px inset, ~4px white stroke hugging the disc rim.
    final ringInset = context.dp(4);
    final ringStroke = context.dp(4);
    Widget ring({required double p}) {
      return CustomPaint(
        size: Size.square(size),
        painter: _StoRingPainter(
          progress: p.clamp(0.0, 1.0),
          track: Colors.white.withValues(alpha: 0.16),
          fill: Colors.white.withValues(alpha: 0.90),
          stroke: ringStroke,
          inset: ringInset,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: rim,
            blurRadius: 0,
            spreadRadius: context.dp(1.5),
          ),
          BoxShadow(
            color: contact.withValues(alpha: 0.28),
            blurRadius: context.dp(3),
            offset: Offset(0, context.dp(2)),
          ),
          BoxShadow(
            color: disc.m2.withValues(alpha: 0.82),
            blurRadius: context.dp(34),
            offset: Offset(0, context.dp(18)),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _StoDiscPainter(m1: disc.m1, m2: disc.m2),
            ),
            if (progressAnimation != null)
              AnimatedBuilder(
                animation: progressAnimation!,
                builder: (context, _) {
                  final t = progressAnimation!.value.clamp(0.0, 1.0);
                  return ring(
                    p: startProgress + (endProgress - startProgress) * t,
                  );
                },
              )
            else
              ring(p: progress ?? endProgress),
            Center(child: child),
            if (!reduceMotion) const _StoDiscSheen(),
          ],
        ),
      ),
    );
  }
}

/// `.dgcp-sto .disc` layers — linear 155°, conic metal turn, specular, bounce.
class _StoDiscPainter extends CustomPainter {
  _StoDiscPainter({required this.m1, required this.m2});

  final Color m1;
  final Color m2;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.42, -0.91),
          end: const Alignment(0.42, 0.91),
          colors: [m1, m2],
        ).createShader(rect),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          startAngle: 120 * math.pi / 180,
          colors: [
            Color.lerp(m2, Colors.black, 0.62)!,
            m1,
            m2,
            Color.lerp(m2, Colors.black, 0.55)!,
            Color.lerp(m2, Colors.black, 0.62)!,
          ],
          stops: const [0.0, 92 / 360, 200 / 360, 300 / 360, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.32, 0.68),
          radius: 0.52,
          colors: [
            Color.lerp(m2, Colors.white, 0.12)!.withValues(alpha: 0.88),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.04, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.36, -0.52),
          radius: 0.46,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final inset = 3.0;
    final inner = Rect.fromCircle(center: c, radius: r - inset);
    canvas.drawCircle(
      c,
      r - inset,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
            Color.lerp(m2, Colors.black, 0.45)!.withValues(alpha: 0.16),
          ],
          stops: const [0.0, 0.34, 1.0],
        ).createShader(inner),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StoDiscPainter oldDelegate) {
    return oldDelegate.m1 != m1 || oldDelegate.m2 != m2;
  }
}

/// `.dgcp-sto .sheen` — 108° band, two passes after the disc lands.
class _StoDiscSheen extends StatefulWidget {
  const _StoDiscSheen();

  @override
  State<_StoDiscSheen> createState() => _StoDiscSheenState();
}

class _StoDiscSheenState extends State<_StoDiscSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;
  int _cycles = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _sheen.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _cycles += 1;
      if (_cycles < 2) _sheen.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_sheen.isAnimating) _sheen.stop();
      _sheen.value = 0;
      return;
    }
    if (_started) return;
    _started = true;
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted && _cycles == 0) _sheen.forward();
    });
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sheen,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final t = const Cubic(0.36, 0.1, 0.3, 1)
                  .transform(_sheen.value.clamp(0.0, 1.0));
              final dx = constraints.maxWidth * (-1.30 + 2.60 * t);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.31, -1),
                        end: const Alignment(0.31, 1),
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.30, 0.42, 0.50, 0.58, 0.70],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StoRingPainter extends CustomPainter {
  _StoRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.stroke,
    required this.inset,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double stroke;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Rim lip outside the stroke, then the white arc — around the face, not
    // orbiting inside it.
    final r = size.width / 2 - inset - stroke / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(covariant _StoRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.track != track ||
        oldDelegate.fill != fill ||
        oldDelegate.stroke != stroke ||
        oldDelegate.inset != inset;
  }
}


class _SlotNumber extends StatelessWidget {
  const _SlotNumber({
    required this.from,
    required this.to,
    required this.t,
    required this.style,
  });

  final int from;
  final int to;
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final u = t.clamp(0.0, 1.0);
    if (u >= 0.995) {
      return Text('$to', style: style);
    }
    final width = math.max(from.abs().toString().length, to.abs().toString().length);
    final a = from.abs().toString().padLeft(width, '0');
    final b = to.abs().toString().padLeft(width, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < width; i++)
          _SlotDigit(
            fromDigit: int.parse(a[i]),
            toDigit: int.parse(b[i]),
            t: u,
            extraTurns: 2 + (width - 1 - i),
            finishBy: 0.62 + 0.38 * ((i + 1) / width),
            style: style,
          ),
      ],
    );
  }
}

class _SlotDigit extends StatelessWidget {
  const _SlotDigit({
    required this.fromDigit,
    required this.toDigit,
    required this.t,
    required this.extraTurns,
    required this.finishBy,
    required this.style,
  });

  final int fromDigit;
  final int toDigit;
  final double t;
  final int extraTurns;
  final double finishBy;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 38.0;
    final h = fontSize * 1.15;
    final w = math.max(fontSize * 0.62, 1.0);
    final local = finishBy <= 0 ? 1.0 : (t / finishBy).clamp(0.0, 1.0);
    if (local >= 0.995) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            '$toDigit',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      );
    }
    final eased = Curves.easeOutCubic.transform(local);
    final delta = ((toDigit - fromDigit) + extraTurns * 10);
    final pos = fromDigit + delta * eased;
    final y = (pos % 10) * h;

    return ClipRect(
      child: SizedBox(
        width: w,
        height: h,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: w,
          maxWidth: w,
          minHeight: h * 20,
          maxHeight: h * 20,
          child: Transform.translate(
            offset: Offset(0, -y),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var n = 0; n < 20; n++)
                  SizedBox(
                    width: w,
                    height: h,
                    child: Center(
                      child: Text(
                        '${n % 10}',
                        textAlign: TextAlign.center,
                        style: style,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int _countUp(int from, int to, double t) {
  final u = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
  return from + ((to - from) * u).round();
}

class _GainChip extends StatelessWidget {
  const _GainChip({
    required this.delta,
    required this.accent,
    required this.animation,
    required this.reduceMotion,
  });

  final int delta;
  final Color accent;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = reduceMotion ? 1.0 : animation.value.clamp(0.0, 1.0);
        double opacity;
        double dy;
        double scale;
        double rot;
        if (reduceMotion) {
          opacity = 1;
          dy = -context.dp(6);
          scale = 1;
          rot = 0;
        } else if (t < 0.18) {
          final u = (t / 0.18).clamp(0.0, 1.0);
          opacity = u;
          dy = context.dp(10) * (1 - u);
          scale = 0.6 + 0.52 * u;
          rot = (-8 + 10 * u) * math.pi / 180;
        } else if (t < 0.32) {
          final u = ((t - 0.18) / 0.14).clamp(0.0, 1.0);
          opacity = 1;
          dy = -context.dp(2) * u;
          scale = 1.12 - 0.14 * u;
          rot = (2 - 2 * u) * math.pi / 180;
        } else if (t < 0.70) {
          final u = ((t - 0.32) / 0.38).clamp(0.0, 1.0);
          opacity = 1;
          dy = -context.dp(2) - context.dp(16) * u;
          scale = 0.98 + 0.02 * u;
          rot = 0;
        } else {
          final u = ((t - 0.70) / 0.30).clamp(0.0, 1.0);
          opacity = 1 - u;
          dy = -context.dp(18) - context.dp(12) * u;
          scale = 1 - 0.08 * u;
          rot = 0;
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: context.dp(44),
                  height: context.dp(44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.north_east_rounded,
                        color: Colors.white,
                        size: context.dp(11),
                      ),
                      Text(
                        '+$delta',
                        style: aeLabel(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
