import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commonView/circle_nav_bar.dart';
import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../dugnad_models.dart';
import 'ae_sheen.dart';

// `.dg-refnudge` tokens from Custom Dugnad.html / ReferNudge.
const _kInk = Color(0xFF3F2C07);
const _kEyebrow = Color(0xFF936410);
const _kBody = Color(0xFF7A5410);
const _kCloseFg = Color(0xFF6A4A10);
const _kLinkFg = Color(0xFF6A4A10);
const _kCreamBorder = Color(0x73D69E28); // rgba(214,158,40,.45)
const _kLinkBorder = Color(0x59D69E28); // rgba(214,158,40,.35)
const _kCardBorder = Color(0x99D69E28); // rgba(214,158,40,.6)
const _kCopyDoneTop = Color(0xFF1F8A5B);
const _kCopyDoneBot = Color(0xFF15724A);
const _kCopyDoneFg = Color(0xFFEAFFF4);
const _kCopyIdleFg = Color(0xFFFFE9A8);
const _kSheenPeriod = Duration(milliseconds: 5200);

/// Floating referral promo — `.dg-refnudge` above the tab bar on home open.
Future<void> showDugnadReferralPromoSheet(
  BuildContext context, {
  required ReferralSummary summary,
}) async {
  final link = summary.referralLink?.trim() ?? '';
  if (link.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.06),
    isDismissible: true,
    enableDrag: false,
    builder: (ctx) {
      final screenH = MediaQuery.sizeOf(ctx).height;
      // `.dg-refnudge { bottom: 98px }` — sit just above the floating pill.
      const gapAboveNav = 10.0;
      final bottomInset = aePillNavReservedHeight(ctx) + gapAboveNav;

      return SizedBox(
        height: screenH,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(12),
              0,
              context.dp(12),
              bottomInset,
            ),
            child: _DugnadReferralPromoCard(
              referralLink: link,
              referralPoints: summary.referralPoints,
              onClose: () async {
                await prefSetString(prefDugnadReferralPromoDismissed, '1');
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      );
    },
  );

  await prefSetString(prefDugnadReferralPromoDismissed, '1');
}

class _DugnadReferralPromoCard extends StatelessWidget {
  const _DugnadReferralPromoCard({
    required this.referralLink,
    required this.referralPoints,
    required this.onClose,
  });

  final String referralLink;
  final int referralPoints;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = context.dp(24);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // linear-gradient(158deg, #fff0c2 0%, #f8d779 46%, #ecbd4e 100%)
          gradient: const LinearGradient(
            begin: Alignment(-0.55, -1.0),
            end: Alignment(0.55, 1.0),
            colors: [Color(0xFFFFF0C2), Color(0xFFF8D779), Color(0xFFECBD4E)],
            stops: [0.0, 0.46, 1.0],
          ),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: _kCardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.55),
              blurRadius: 0,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF78500C).withValues(alpha: 0.3),
              blurRadius: context.dp(14),
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: const Color(0xFF78500C).withValues(alpha: 0.62),
              blurRadius: context.dp(56),
              offset: const Offset(0, 28),
              spreadRadius: -14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: Stack(
            children: [
              // `.dg-refnudge::after` — soft top-right highlight.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.72, -1.3),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.68],
                      ),
                    ),
                  ),
                ),
              ),
              // `.dg-refnudge-sheen` — lightning sweep across the card.
              const Positioned.fill(
                child: AeSheen(
                  period: _kSheenPeriod,
                  delay: Duration(milliseconds: 500),
                  bandWidthFactor: 0.42,
                  highlight: Color(0xB3FFFFFF),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dp(16),
                  context.dp(15),
                  context.dp(16),
                  context.dp(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CoinsBadge(size: 44, iconSize: 23, radius: 13),
                        SizedBox(width: context.dp(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomPaint(
                                    size: Size(context.dp(11), context.dp(11)),
                                    painter: const _SparklePainter(
                                      color: _kEyebrow,
                                      filled: true,
                                    ),
                                  ),
                                  SizedBox(width: context.dp(5)),
                                  Flexible(
                                    child: Text(
                                      languages.dugnadReferralPromoEyebrow,
                                      style: TextStyle(
                                        color: _kEyebrow,
                                        fontSize: context.dp(11),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: context.dp(11) * 0.06,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.dp(4)),
                              Text(
                                languages.dugnadReferralPromoTitle,
                                style: AeDugnadText.bannerTitle(color: _kInk)
                                    .copyWith(
                                  fontSize: context.dp(17),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: context.dp(17) * -0.015,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.dp(8)),
                        _CloseButton(onTap: onClose),
                      ],
                    ),
                    SizedBox(height: context.dp(12)),
                    _BenefitCard(points: referralPoints),
                    SizedBox(height: context.dp(10)),
                    _LinkPill(link: referralLink),
                    SizedBox(height: context.dp(9)),
                    _CopyButton(referralLink: referralLink),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.dg-refnudge-ic` / `.dg-refnudge-earn .coin` — gold tile + coins icon + sheen.
class _CoinsBadge extends StatelessWidget {
  const _CoinsBadge({
    required this.size,
    required this.iconSize,
    required this.radius,
    this.sheenDelay,
  });

  final double size;
  final double iconSize;
  final double radius;
  final Duration? sheenDelay;

  @override
  Widget build(BuildContext context) {
    final s = context.dp(size);
    final r = context.dp(radius);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        // linear-gradient(150deg, #ffe49a, #e7b542 60%, #cf971f)
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1.0),
          end: Alignment(0.5, 1.0),
          colors: [Color(0xFFFFE49A), Color(0xFFE7B542), Color(0xFFCF971F)],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFFBE871E).withValues(alpha: 0.8),
            blurRadius: context.dp(16),
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(context.dp(iconSize), context.dp(iconSize)),
              painter: const _CoinsPainter(color: Colors.white),
            ),
            // `.dg-refnudge-ic::after` / `.coin::after`
            Positioned.fill(
              child: AeSheen(
                period: _kSheenPeriod,
                delay: sheenDelay,
                bandWidthFactor: 0.60,
                highlight: const Color(0xD9FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `.dg-refnudge-x` — 28×28, radius 9, tinted brown (not a white circle).
    return Material(
      color: const Color(0x2178500C), // rgba(120,80,12,.13)
      borderRadius: BorderRadius.circular(context.dp(9)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(9)),
        child: SizedBox(
          width: context.dp(28),
          height: context.dp(28),
          child: Icon(
            Icons.close_rounded,
            size: context.dp(16),
            color: _kCloseFg,
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    // `.dg-refnudge-earn`
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(12),
        vertical: context.dp(9),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: _kCreamBorder),
      ),
      child: Row(
        children: [
          const _CoinsBadge(
            size: 32,
            iconSize: 17,
            radius: 9,
            sheenDelay: Duration(milliseconds: 250),
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: context.dp(13),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _kBody,
                ),
                children: [
                  TextSpan(
                    text: languages.dugnadReferralPromoBenefitBold(points),
                    style: TextStyle(
                      fontSize: context.dp(15.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: context.dp(15.5) * -0.01,
                      color: _kInk,
                    ),
                  ),
                  TextSpan(text: languages.dugnadReferralPromoBenefitSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPill extends StatelessWidget {
  const _LinkPill({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    // `.dg-refnudge-link`
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(12),
        vertical: context.dp(9),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(context.dp(13)),
        border: Border.all(color: _kLinkBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: context.dp(13),
            color: _kLinkFg,
          ),
          SizedBox(width: context.dp(7)),
          Expanded(
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _kLinkFg,
                fontSize: context.dp(12.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-refnudge-copy` — idle brown → `.done` green after copy.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.referralLink});

  final String referralLink;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _onCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.referralLink));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.dp(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copied ? null : _onCopy,
        borderRadius: BorderRadius.circular(r),
        child: Ink(
          height: context.dp(48),
          decoration: BoxDecoration(
            // idle: linear-gradient(135deg, #4a3408, #6a4a0e)
            // done:  linear-gradient(135deg, #1f8a5b, #15724a)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _copied
                  ? const [_kCopyDoneTop, _kCopyDoneBot]
                  : const [Color(0xFF4A3408), Color(0xFF6A4A0E)],
            ),
            borderRadius: BorderRadius.circular(r),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: (_copied ? _kCopyDoneBot : const Color(0xFF4A3408))
                    .withValues(alpha: 0.75),
                blurRadius: context.dp(18),
                offset: const Offset(0, 8),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: Stack(
              children: [
                // `.dg-refnudge-copy::after` — sheen only while idle.
                if (!_copied)
                  const Positioned.fill(
                    child: AeSheen(
                      period: _kSheenPeriod,
                      delay: Duration(milliseconds: 900),
                      bandWidthFactor: 0.45,
                      highlight: Color(0x73FFE9A8),
                    ),
                  ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied
                            ? Icons.check_rounded
                            : Icons.content_copy_rounded,
                        size: context.dp(17),
                        color: _copied ? _kCopyDoneFg : _kCopyIdleFg,
                      ),
                      SizedBox(width: context.dp(8)),
                      Text(
                        _copied
                            ? languages.dugnadReferralPromoLinkCopied
                            : languages.dugnadReferralPromoCopyLink,
                        style: TextStyle(
                          color: _copied ? _kCopyDoneFg : _kCopyIdleFg,
                          fontSize: context.dp(15),
                          fontWeight: FontWeight.w900,
                          letterSpacing: context.dp(15) * -0.01,
                        ),
                      ),
                    ],
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

/// Lucide-style `coins` from `ui_kits/icons.jsx`.
class _CoinsPainter extends CustomPainter {
  const _CoinsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(const Offset(8, 8), 5, paint);
    canvas.drawPath(
      Path()
        ..moveTo(18.1, 6.3)
        ..arcToPoint(
          const Offset(18.1, 15.7),
          radius: const Radius.circular(5),
          clockwise: true,
        ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(16, 19.5)
        ..arcToPoint(
          const Offset(8, 19.5),
          radius: const Radius.circular(5),
          clockwise: true,
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Lucide-style filled `sparkle` from `ui_kits/icons.jsx`.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color, this.filled = false});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final path = Path()
      ..moveTo(12, 2)
      ..lineTo(14, 9)
      ..lineTo(21, 12)
      ..lineTo(14, 15)
      ..lineTo(12, 22)
      ..lineTo(10, 15)
      ..lineTo(3, 12)
      ..lineTo(10, 9)
      ..close();
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}
