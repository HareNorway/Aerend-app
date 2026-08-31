import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../dugnad/dugnad_celebration_orchestrator.dart';
import '../../../ui/kit/ae_theme.dart';
import '../campaign_strings.dart';
import '../campaign_tracker_controller.dart';
import '../models/campaign_order_pojo.dart';
import 'campaign_tracker_countdown.dart';

/// Appear: `.cp-tracker` `cp-tracker-in` `.5s cubic-bezier(.2,1.3,.4,1)`.
const Cubic _kTrackerIn = Cubic(0.2, 1.3, 0.4, 1);

/// Dismiss: `.cp-tracker.leaving` `cp-tracker-out` `.42s cubic-bezier(.4,0,.6,1)`.
const Cubic _kTrackerOut = Cubic(0.4, 0, 0.6, 1);

/// Persistent, club-themed, NON-BLOCKING tracker pill shown above the nav across
/// dugnad tabs. Reads server state (never re-derives it) and hides under the same
/// suppression rule celebrations use. Tapping opens the overview (Chunk 6);
/// the X dismisses one purchase for the rest of the session (in memory only).
class CampaignTracker extends StatefulWidget {
  const CampaignTracker({
    super.key,
    required this.onOpenOverview,
    this.controller,
  });

  /// Invoked when the pill/chevron is tapped. Dismissed purchases stay dismissed
  /// for the session — opening the overview does not bring their pills back.
  final VoidCallback onOpenOverview;

  /// Injectable for tests; defaults to the app-scoped singleton.
  final CampaignTrackerController? controller;

  @override
  State<CampaignTracker> createState() => _CampaignTrackerState();
}

class _CampaignTrackerState extends State<CampaignTracker> {
  Timer? _suppressionPoll;
  Timer? _leaveTimer;
  bool _leaving = false;
  String? _leavingOrderNo;

  CampaignTrackerController get _controller =>
      widget.controller ?? CampaignTrackerController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    DugnadCelebrationOrchestrator.instance.blockedListenable
        .addListener(_rebuild);
    // Catch tour/loading suppression transitions the notifier can't observe.
    _suppressionPoll = Timer.periodic(const Duration(seconds: 1), (_) {
      DugnadCelebrationOrchestrator.instance.refreshBlockedState();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.ensureLoaded();
    });
  }

  @override
  void dispose() {
    _suppressionPoll?.cancel();
    _leaveTimer?.cancel();
    _controller.removeListener(_rebuild);
    DugnadCelebrationOrchestrator.instance.blockedListenable
        .removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _dismiss(String orderNo) {
    if (_leaving) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _controller.dismiss(orderNo);
      return;
    }
    setState(() {
      _leaving = true;
      _leavingOrderNo = orderNo;
    });
    _leaveTimer?.cancel();
    _leaveTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      final id = _leavingOrderNo;
      _leaving = false;
      _leavingOrderNo = null;
      if (id != null) _controller.dismiss(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Same suppression signal as celebrations — no duplicated three-way check.
    if (DugnadCelebrationOrchestrator.instance.isBlocked) {
      return const SizedBox.shrink();
    }

    final order = _controller.soonest;
    if (order == null || order.windowStart == null) {
      return const SizedBox.shrink();
    }

    final reduced = MediaQuery.disableAnimationsOf(context);
    final pill = _buildPill(context, order);

    // Appear `cp-tracker-in`; dismiss `cp-tracker-out` (scale + sink). Instant
    // under reduced motion.
    return TweenAnimationBuilder<double>(
      key: ValueKey(order.orderNo),
      tween: Tween(begin: 0, end: _leaving ? 0 : 1),
      duration: reduced
          ? Duration.zero
          : Duration(milliseconds: _leaving ? 420 : 500),
      curve: _leaving ? _kTrackerOut : _kTrackerIn,
      builder: (context, t, child) {
        final v = t.clamp(0.0, 1.0);
        Widget layered = child!;
        if (_leaving) {
          layered = Transform.scale(scale: 0.9 + 0.1 * v, child: layered);
        }
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: layered,
          ),
        );
      },
      child: IgnorePointer(ignoring: _leaving, child: pill),
    );
  }

  Widget _buildPill(BuildContext context, CampaignMyOrder order) {
    final theme = context.aeTheme;
    final delivery = order.deliveryMethod == 'delivery';
    final locked = order.state == CampaignPurchaseState.locked;
    final more = _controller.activeCount - 1;
    final progress =
        trackerProgress(_parse(order.createdAt), order.windowStart!);
    final radius = BorderRadius.circular(context.dp(18));

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0x42140C28),
              blurRadius: context.dp(4),
              offset: Offset(0, context.dp(2)),
            ),
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.8),
              blurRadius: context.dp(34),
              offset: Offset(0, context.dp(16)),
              spreadRadius: -context.dp(12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Non-positioned: this is what gives the pill its height. The
              // home shell mounts us in Positioned(left/right/bottom) with no
              // height, so maxHeight is infinite — a stretch Row would pass
              // that infinity to children and RenderOpacity would never finish
              // layout (`parentDataDirty` every frame).
              Padding(
                padding: EdgeInsets.only(right: context.dp(42)),
                child: InkWell(
                  onTap: widget.onOpenOverview,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.dp(10), context.dp(10),
                        context.dp(6), context.dp(10)),
                    child: Row(
                      children: [
                        _methodIcon(context,
                            delivery: delivery, locked: locked),
                        SizedBox(width: context.dp(11)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      order.campaignName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.dp(13),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: context.dp(13) * -0.01,
                                      ),
                                    ),
                                  ),
                                  if (more >= 1) ...[
                                    SizedBox(width: context.dp(6)),
                                    _moreBadge(context, more),
                                  ],
                                ],
                              ),
                              SizedBox(height: context.dp(2)),
                              TrackerCountdown(
                                windowStart: order.windowStart!,
                                size: TrackerCountdownSize.sm,
                                textColor: Colors.white,
                              ),
                              _Rail(
                                progress: progress,
                                iconColor: theme.primaryHover,
                                near: locked,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.dp(4)),
                        Icon(Icons.chevron_right,
                            size: context.dp(15),
                            color: Colors.white.withValues(alpha: 0.62)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: context.dp(42),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _dismiss(order.orderNo),
                      child: Center(
                        child: Icon(Icons.close,
                            size: context.dp(14),
                            color: Colors.white.withValues(alpha: 0.72)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 1,
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodIcon(BuildContext context,
      {required bool delivery, required bool locked}) {
    return SizedBox(
      key: ValueKey(delivery ? 'cp-tracker-delivery' : 'cp-tracker-pickup'),
      width: context.dp(36),
      height: context.dp(36),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(context.dp(12)),
            ),
            alignment: Alignment.center,
            child: CustomPaint(
              size: Size.square(context.dp(16)),
              painter: _LucideIconPainter(
                kind: delivery ? _LucideKind.truck : _LucideKind.store,
                color: Colors.white,
              ),
            ),
          ),
          if (locked)
            Positioned(
              right: -context.dp(4),
              bottom: -context.dp(4),
              child: Container(
                width: context.dp(17),
                height: context.dp(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x66140C28),
                      blurRadius: context.dp(3),
                      offset: Offset(0, context.dp(1)),
                    ),
                  ],
                ),
                child: Icon(Icons.lock,
                    size: context.dp(9),
                    color: context.aeTheme.primaryHover),
              ),
            ),
        ],
      ),
    );
  }

  Widget _moreBadge(BuildContext context, int more) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(6), vertical: context.dp(2)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        CampaignStrings.trackerMore(more),
        style: TextStyle(
          fontSize: context.dp(10),
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  DateTime? _parse(String? iso) =>
      (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);
}

/// Decorative rail matching `.cp-rail`: filled track, destination dot, and a
/// white truck marker that hops along [progress] (`cp-pkg-hop`).
class _Rail extends StatefulWidget {
  const _Rail({
    required this.progress,
    required this.iconColor,
    required this.near,
  });
  final double progress;
  final Color iconColor;
  final bool near;

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> with SingleTickerProviderStateMixin {
  late final AnimationController _hop;
  late final Animation<double> _lift;

  /// CSS `animation-timing-function: cubic-bezier(.3,.8,.4,1)`.
  static const _ease = Cubic(0.3, 0.8, 0.4, 1);

  @override
  void initState() {
    super.initState();
    _hop = AnimationController(vsync: this, duration: _duration);
    // Keyframes of `cp-pkg-hop`: hold, hop −4px/−6°, land, nibble −1.5px/−2°.
    _lift = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 62),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: _ease)),
          weight: 8),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: _ease)),
          weight: 10),
      TweenSequenceItem(
          tween:
              Tween<double>(begin: 0, end: 0.375).chain(CurveTween(curve: _ease)),
          weight: 6),
      TweenSequenceItem(
          tween:
              Tween<double>(begin: 0.375, end: 0).chain(CurveTween(curve: _ease)),
          weight: 14),
    ]).animate(_hop);
  }

  Duration get _duration =>
      Duration(milliseconds: widget.near ? 1500 : 2600);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHop();
  }

  @override
  void didUpdateWidget(covariant _Rail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.near != widget.near) {
      _hop.duration = _duration;
    }
    _syncHop();
  }

  void _syncHop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _hop.stop();
      _hop.value = 0;
      return;
    }
    if (!_hop.isAnimating) _hop.repeat();
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Painted, not Transform+Stack: a hopping Transform inside a clipped
    // Stack marks semantics parentData dirty every frame and asserts
    // `!semantics.parentDataDirty` (prototype rail is `aria-hidden`).
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.dp(2), context.dp(5), context.dp(2), context.dp(1)),
        child: SizedBox(
          width: double.infinity,
          height: context.dp(12),
          child: AnimatedBuilder(
            animation: _lift,
            builder: (context, _) => CustomPaint(
              key: const ValueKey('cp-tracker-rail-truck'),
              painter: _RailPainter(
                progress: widget.progress.clamp(0.0, 1.0),
                lift: _lift.value,
                iconColor: widget.iconColor,
                pkgSize: context.dp(18),
                destSize: context.dp(8),
                trackH: context.dp(2.5),
                hopPx: context.dp(4),
                pkgTop: -context.dp(3),
                trackTop: context.dp(5),
                destTop: context.dp(2),
                pkgRadius: context.dp(6),
                iconSize: context.dp(10),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.cp-rail` track, fill, dest dot, and hopping `.pkg` truck.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.progress,
    required this.lift,
    required this.iconColor,
    required this.pkgSize,
    required this.destSize,
    required this.trackH,
    required this.hopPx,
    required this.pkgTop,
    required this.trackTop,
    required this.destTop,
    required this.pkgRadius,
    required this.iconSize,
  });

  final double progress;
  final double lift;
  final Color iconColor;
  final double pkgSize;
  final double destSize;
  final double trackH;
  final double hopPx;
  final double pkgTop;
  final double trackTop;
  final double destTop;
  final double pkgRadius;
  final double iconSize;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final trackRect = RRect.fromLTRBR(
      0,
      trackTop,
      size.width,
      trackTop + trackH,
      Radius.circular(trackH),
    );
    canvas.drawRRect(trackRect, trackPaint);

    final fillW = size.width * progress;
    if (fillW > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          trackTop,
          fillW,
          trackTop + trackH,
          Radius.circular(trackH),
        ),
        fillPaint,
      );
    }

    final destC = Offset(size.width - destSize / 2, destTop + destSize / 2);
    canvas.drawCircle(
      destC,
      destSize / 2 + 2,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      destC,
      destSize / 2,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    final pkgLeft = fillW - pkgSize / 2;
    final pkgCy = pkgTop + pkgSize / 2;
    final pkgCx = pkgLeft + pkgSize / 2;
    canvas.save();
    canvas.translate(pkgCx, pkgCy - hopPx * lift);
    canvas.rotate(-6 * math.pi / 180 * lift);
    canvas.translate(-pkgSize / 2, -pkgSize / 2);

    final pkgRRect =
        RRect.fromLTRBR(0, 0, pkgSize, pkgSize, Radius.circular(pkgRadius));
    canvas.drawRRect(
      pkgRRect.shift(const Offset(0, 1)),
      Paint()
        ..color = const Color(0x66140C28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawRRect(pkgRRect, Paint()..color = Colors.white);

    final iconOrigin = Offset(
      (pkgSize - iconSize) / 2,
      (pkgSize - iconSize) / 2,
    );
    _paintLucideIcon(
      canvas,
      Rect.fromLTWH(iconOrigin.dx, iconOrigin.dy, iconSize, iconSize),
      _LucideKind.truck,
      iconColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RailPainter old) =>
      old.progress != progress ||
      old.lift != lift ||
      old.iconColor != iconColor ||
      old.pkgSize != pkgSize;
}

enum _LucideKind { truck, store }

class _LucideIconPainter extends CustomPainter {
  const _LucideIconPainter({required this.kind, required this.color});

  final _LucideKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLucideIcon(canvas, Offset.zero & size, kind, color);
  }

  @override
  bool shouldRepaint(covariant _LucideIconPainter old) =>
      old.kind != kind || old.color != color;
}

/// Lucide `truck` / `store` from `DesignLatest/ui_kits/icons.jsx`, 24×24 viewBox.
void _paintLucideIcon(
  Canvas canvas,
  Rect box,
  _LucideKind kind,
  Color color,
) {
  canvas.save();
  canvas.translate(box.left, box.top);
  canvas.scale(box.width / 24, box.height / 24);
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  switch (kind) {
    case _LucideKind.truck:
      canvas.drawRect(const Rect.fromLTWH(2.5, 6.5, 10.5, 10), stroke);
      final bed = Path()
        ..moveTo(13, 10.5)
        ..lineTo(17, 10.5)
        ..lineTo(20.5, 14)
        ..lineTo(20.5, 16.5)
        ..lineTo(13, 16.5)
        ..close();
      canvas.drawPath(bed, stroke);
      canvas.drawCircle(const Offset(6.75, 18), 1.75, stroke);
      canvas.drawCircle(const Offset(16.75, 18), 1.75, stroke);
    case _LucideKind.store:
      final roof = Path()
        ..moveTo(3, 9)
        ..lineTo(4.5, 4)
        ..lineTo(19.5, 4)
        ..lineTo(21, 9);
      canvas.drawPath(roof, stroke);
      canvas.drawRect(const Rect.fromLTWH(4, 9, 16, 11), stroke);
      final awning = Path()
        ..moveTo(3, 9)
        ..arcToPoint(const Offset(9, 9),
            radius: const Radius.circular(3), clockwise: false)
        ..arcToPoint(const Offset(15, 9),
            radius: const Radius.circular(3), clockwise: false)
        ..arcToPoint(const Offset(21, 9),
            radius: const Radius.circular(3), clockwise: false);
      canvas.drawPath(awning, stroke);
      canvas.drawRect(const Rect.fromLTWH(9, 14, 6, 6), stroke);
  }
  canvas.restore();
}
