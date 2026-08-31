import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../dugnad/club_crest.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/dugnad_state.dart';
import '../campaign_delivery_utils.dart';
import '../campaign_strings.dart';
import '../models/campaign_order_pojo.dart';

/// Receipt outline — `.cp-card .paper` mask: rounded top + downward
/// isosceles teeth (`conic-gradient` tiles of [tooth] × [zig]).
Path cpReceiptZigzagPath(
  Size size, {
  required double zig,
  required double tooth,
  required double topRadius,
}) {
  final r = topRadius.clamp(0.0, size.width / 2);
  final top = math.max(0.0, size.height - zig);
  final bot = size.height;
  final pts = <Offset>[Offset(0, top)];
  var x = 0.0;
  var toApex = true;
  final step = tooth <= 0 ? size.width : tooth / 2;
  while (x < size.width && step > 0) {
    final nextX = x + step;
    final nextY = toApex ? bot : top;
    if (nextX >= size.width) {
      final t = (size.width - x) / (nextX - x);
      pts.add(Offset(size.width, pts.last.dy + (nextY - pts.last.dy) * t));
      break;
    }
    pts.add(Offset(nextX, nextY));
    x = nextX;
    toApex = !toApex;
  }

  final path = Path()
    ..moveTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..lineTo(size.width - r, 0)
    ..quadraticBezierTo(size.width, 0, size.width, r)
    ..lineTo(pts.last.dx, pts.last.dy);
  for (var i = pts.length - 2; i >= 0; i--) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  path.close();
  return path;
}

/// Receipt card shell — `.cp-card` drop-shadow on the zigzag, not a box-shadow
/// on the rounded rect (that would hang as a slab under the teeth).
class CpReceiptPaper extends StatelessWidget {
  const CpReceiptPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final zig = context.dp(9);
    final tooth = context.dp(17);
    final radius = context.dp(20);
    return CustomPaint(
      painter: _ZigzagDropShadowPainter(
        zig: zig,
        tooth: tooth,
        topRadius: radius,
        color: context.dugnadTheme.ink,
      ),
      child: ClipPath(
        clipper: CpZigzagClipper(zig: zig, tooth: tooth, topRadius: radius),
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(bottom: zig),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ZigzagDropShadowPainter extends CustomPainter {
  _ZigzagDropShadowPainter({
    required this.zig,
    required this.tooth,
    required this.topRadius,
    required this.color,
  });

  final double zig;
  final double tooth;
  final double topRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = cpReceiptZigzagPath(
      size,
      zig: zig,
      tooth: tooth,
      topRadius: topRadius,
    );
    // `filter: drop-shadow(0 1px 1px) drop-shadow(0 13px 22px)` — follows the
    // cut. A BoxDecoration shadow would be rectangular and sit under the teeth.
    canvas.save();
    canvas.translate(0, 1);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
    canvas.translate(0, 12);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ZigzagDropShadowPainter old) =>
      old.zig != zig ||
      old.tooth != tooth ||
      old.topRadius != topRadius ||
      old.color != color;
}

class CpZigzagClipper extends CustomClipper<Path> {
  CpZigzagClipper({
    required this.zig,
    required this.tooth,
    required this.topRadius,
  });

  final double zig;
  final double tooth;
  final double topRadius;

  @override
  Path getClip(Size size) => cpReceiptZigzagPath(
        size,
        zig: zig,
        tooth: tooth,
        topRadius: topRadius,
      );

  @override
  bool shouldReclip(covariant CpZigzagClipper old) =>
      old.zig != zig || old.tooth != tooth || old.topRadius != topRadius;
}

/// `1.5px dashed` hairline — Flutter has no dashed [BorderSide].
class CpDashedHairline extends StatelessWidget {
  const CpDashedHairline({super.key, required this.color, this.strokeWidth = 1.5});

  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: strokeWidth,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Club crest for a purchase receipt — never the team photo.
/// Uses the order's `club_logo`, then the selected club's logo.
String? campaignClubCrestUrl(CampaignMyOrder order) {
  final fromOrder = (order.clubLogo ?? '').trim();
  if (fromOrder.isNotEmpty) return fromOrder;
  final selected = DugnadState.instance.clubLogo.trim();
  return selected.isEmpty ? null : selected;
}

class CpCrest extends StatelessWidget {
  const CpCrest({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 40,
  });

  final String name;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final url = ClubCrest.resolveClubMediaUrl(logoUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.dp(12)),
      child: ColoredBox(
        color: theme.primaryTint,
        child: SizedBox(
          width: size,
          height: size,
          child: url == null
              ? Center(
                  child: Text(
                    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                    style: aeTitle(color: theme.primary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    color: theme.primary,
                    size: size * 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class CpReceiptHeader extends StatelessWidget {
  const CpReceiptHeader({super.key, required this.order});

  final CampaignMyOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final bought = campaignDayLabel(order.boughtAt);
    final teamBits = [
      if ((order.clubName ?? '').trim().isNotEmpty) order.clubName!.trim(),
      if ((order.teamName ?? '').trim().isNotEmpty) order.teamName!.trim(),
    ];
    final summaryBits = [
      if ((order.productSummary ?? '').trim().isNotEmpty)
        order.productSummary!.trim(),
      if (teamBits.isNotEmpty) teamBits.join(' '),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(16),
        context.dp(15),
        context.dp(16),
        context.dp(13),
      ),
      child: Row(
        children: [
          CpCrest(
            name: order.clubName ?? order.campaignName ?? '',
            logoUrl: campaignClubCrestUrl(order),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CampaignStrings.receiptBought(bought).toUpperCase(),
                  style: aeOverline(
                    color: theme.primaryHover.withValues(alpha: 0.8),
                  ).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    letterSpacing: 9.5 * 0.1,
                  ),
                ),
                SizedBox(height: context.dp(3)),
                Text(
                  order.campaignName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: aeTitle(color: theme.ink).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    letterSpacing: 14.5 * -0.01,
                  ),
                ),
                if (summaryBits.isNotEmpty) ...[
                  SizedBox(height: context.dp(2)),
                  Text(
                    summaryBits.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CpDottedRow extends StatelessWidget {
  const CpDottedRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.44,
          ),
        ),
        SizedBox(width: context.dp(7)),
        Expanded(
          child: CustomPaint(
            painter: _DotsPainter(
              color: theme.primary.withValues(alpha: 0.28),
            ),
            child: const SizedBox(height: 6),
          ),
        ),
        SizedBox(width: context.dp(7)),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.5,
          ),
          child: valueWidget ??
              Text(
                value,
                textAlign: TextAlign.right,
                style: aeCaption(color: theme.ink).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 12.5 * -0.01,
                  height: 1.35,
                ),
              ),
        ),
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 4.0;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, y), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}

class CpMethodTag extends StatelessWidget {
  const CpMethodTag({super.key, required this.pickup});

  final bool pickup;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(7),
        context.dp(3),
        context.dp(9),
        context.dp(3),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pickup ? Icons.storefront_outlined : Icons.local_shipping_outlined,
            size: 11,
            color: theme.primary,
          ),
          SizedBox(width: context.dp(5)),
          Text(
            pickup
                ? CampaignStrings.methodPickup
                : CampaignStrings.methodDelivery,
            style: aeCaption(color: theme.primaryHover).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class CpPointsStamp extends StatelessWidget {
  const CpPointsStamp({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final radius = context.dp(11);
    final border = Color.lerp(Colors.white, theme.primary, 0.42)!;
    final fill = Color.lerp(Colors.white, theme.primary, 0.07)!;
    final unitColor = Color.lerp(Colors.white, theme.primaryHover, 0.72)!;
    return Transform.rotate(
      angle: -3.5 * math.pi / 180,
      child: CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: border,
          radius: radius,
          strokeWidth: 1.5,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.dp(6),
            context.dp(5),
            context.dp(11),
            context.dp(5),
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.dp(21),
                height: context.dp(21),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: theme.shinyGradient,
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: context.dp(11),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: context.dp(6)),
              Text(
                '+$points',
                style: aeCaption(color: theme.primaryHover).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 16 * -0.02,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(width: context.dp(6)),
              Text(
                CampaignStrings.pointsUnit.toUpperCase(),
                style: aeCaption(color: unitColor).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    const dash = 4.0;
    const gap = 3.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

/// Place / address lines for the current or target method (location only).
({String title, String subtitle}) campaignLocationParts(
  CampaignMyOrder order, {
  required bool pickup,
}) {
  if (pickup) {
    final raw = (order.distributionLocation ?? '').trim();
    if (raw.isEmpty) {
      return (title: (order.clubName ?? '').trim(), subtitle: '');
    }
    return splitSavedAddress(raw);
  }
  final addr = (order.deliveryAddress ?? '').trim();
  return (
    title: addr.isEmpty ? CampaignStrings.yourAddress : addr,
    subtitle: '',
  );
}

String campaignLocationLine(CampaignMyOrder order, {required bool pickup}) {
  final parts = campaignLocationParts(order, pickup: pickup);
  return [
    if (parts.title.isNotEmpty) parts.title,
    if (parts.subtitle.isNotEmpty) parts.subtitle,
  ].join(', ');
}
