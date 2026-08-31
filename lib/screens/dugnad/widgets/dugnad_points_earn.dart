import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../../../utils/utils.dart';
import 'ae_sheen.dart';

const _kGoldText = Color(0xFF7A5410);
const _kGoldSub = Color(0xFF9A6B12);
const _kGoldStart = Color(0xFFFFF6DB);
const _kGoldEnd = Color(0xFFFDEDBF);
const _kGoldBorder = Color(0x57D8A028);
const _kCoinStart = Color(0xFFF7D979);
const _kCoinEnd = Color(0xFFE0A93A);

/// Points earn card — mirrors prototype `PointsEarn` / `.dg-ptsearn`.
class DugnadPointsEarn extends StatefulWidget {
  const DugnadPointsEarn({
    super.key,
    required this.points,
    required this.title,
    required this.subtitle,
  });

  final int points;
  final String title;
  final String subtitle;

  @override
  State<DugnadPointsEarn> createState() => _DugnadPointsEarnState();
}

class _DugnadPointsEarnState extends State<DugnadPointsEarn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump;
  int _displayPoints = 0;

  @override
  void initState() {
    super.initState();
    _displayPoints = widget.points;
    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant DugnadPointsEarn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      _animateTo(widget.points);
      if (!MediaQuery.disableAnimationsOf(context)) {
        _bump.forward(from: 0);
      }
    }
  }

  Future<void> _animateTo(int target) async {
    final start = _displayPoints;
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      setState(() {
        _displayPoints = start + ((target - start) * i / steps).round();
      });
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(11)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGoldStart, _kGoldEnd],
        ),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: _kGoldBorder, width: context.dp(1.5)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.08).animate(
              CurvedAnimation(parent: _bump, curve: Curves.easeOut),
            ),
            child: const _CoinIcon(),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AeDugnadText.pointsEarnTitle(color: _kGoldText).dp(context),
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  widget.subtitle,
                  style: AeDugnadText.pointsEarnSub(color: _kGoldSub).dp(context),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.12).animate(
              CurvedAnimation(parent: _bump, curve: Curves.easeOut),
            ),
            child: Column(
              children: [
                Text(
                  '+$_displayPoints',
                  style: TextStyle(
                    fontSize: context.dp(22),
                    fontWeight: FontWeight.w900,
                    color: _kGoldSub,
                    letterSpacing: context.dp(22) * -0.02,
                    height: 1,
                  ),
                ),
                Text(
                  languages.dugnadPointsUnit,
                  style: TextStyle(
                    fontSize: context.dp(9),
                    fontWeight: FontWeight.w800,
                    color: _kGoldSub.withValues(alpha: 0.8),
                    letterSpacing: context.dp(9) * 0.04,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon();

  @override
  Widget build(BuildContext context) {
    final radius = context.dp(11);
    return Container(
      width: context.dp(38),
      height: context.dp(38),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCoinStart, _kCoinEnd],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.7),
            blurRadius: context.dp(14),
            offset: Offset(context.dp(0), context.dp(6)),
            spreadRadius: context.dp(-6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.star_rounded, color: Colors.white, size: context.dp(19)),
            // `.dg-ptsearn .coin::after` — lb-sheen (sweep then dwell), not a
            // linear crawl. Softer peak than CSS 0.75 so the star stays readable.
            const Positioned.fill(
              child: AeSheen(
                curve: AeSheenCurve.lbSheen,
                period: Duration(milliseconds: 6500),
                bandWidthFactor: 0.55,
                highlight: Color(0x55FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
