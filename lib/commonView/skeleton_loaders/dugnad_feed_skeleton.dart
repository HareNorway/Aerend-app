import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constant/constant.dart';
import '../../theme/ae_typography.dart';
import '../../theme/sc_saas_theme.dart';

/// Placeholder feed while dugnad Hjem data loads — layout mirrors
/// [DugnadHomeAnchorCard], [DugnadEarnPointsEntry], [DugnadCampaignCarousel].
class DugnadFeedSkeleton extends StatelessWidget {
  const DugnadFeedSkeleton({super.key, required this.padding});

  final double padding;

  static const double _feedGap = AeDugnadSpace.homeFeedGap;
  static const double _campaignCardWidthFraction = 0.72;
  static const double _campaignCardGap = 14;

  @override
  Widget build(BuildContext context) {
    final viewportWidth =
        MediaQuery.sizeOf(context).width;
    final cardWidth = viewportWidth * _campaignCardWidthFraction;

    // Sheet ([DugnadRoundedFeedSheet]) owns the lavender fill — do not paint a
    // full-bleed rect here or it squares the top radius when the sheet does
    // not clip (and is redundant when it does).
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        AeDugnadSpace.homeFeedPadTop,
        padding,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DugnadAnchorCardSkeleton(),
          SizedBox(height: _feedGap),
          const _EarnPointsRowSkeleton(),
          SizedBox(height: _feedGap),
            _CampaignSectionSkeleton(
              viewportWidth: viewportWidth,
              cardWidth: cardWidth,
              cardGap: _campaignCardGap,
            ),
          ],
        ),
    );
  }
}

/// One shimmer scope — children are flat bones, not nested Shimmer widgets.
class _ShimmerScope extends StatelessWidget {
  const _ShimmerScope({
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? colorShimmerBg,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.color = Colors.white,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Large points/anchor card skeleton — neutral silver shimmer.
/// Used on Hjem feed and Profil until [PointsSummary] is loaded.
class DugnadAnchorCardSkeleton extends StatelessWidget {
  const DugnadAnchorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ScSaasThemeTokens.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Bone(
                  width: 42,
                  height: 42,
                  borderRadius: BorderRadius.all(Radius.circular(21)),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 96, height: 10),
                      SizedBox(height: 6),
                      _Bone(width: 118, height: 26),
                      SizedBox(height: 5),
                      _Bone(width: 88, height: 11),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                _Bone(
                  width: 92,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _Bone(width: double.infinity, height: 12),
            const SizedBox(height: 7),
            const _Bone(
              width: double.infinity,
              height: 6,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: ScSaasThemeTokens.gray100),
            const SizedBox(height: 11),
            Row(
              children: const [
                _Bone(
                  width: 30,
                  height: 30,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 108, height: 13),
                      SizedBox(height: 4),
                      _Bone(width: 92, height: 10),
                    ],
                  ),
                ),
                _Bone(
                  width: 104,
                  height: 38,
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnPointsRowSkeleton extends StatelessWidget {
  const _EarnPointsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Bone(width: 15, height: 15),
                      SizedBox(width: 7),
                      Expanded(child: _Bone(width: double.infinity, height: 15)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.only(left: 22),
                    child: _Bone(width: 210, height: 12),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            _Bone(
              width: 28,
              height: 28,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignSectionSkeleton extends StatelessWidget {
  const _CampaignSectionSkeleton({
    required this.viewportWidth,
    required this.cardWidth,
    required this.cardGap,
  });

  final double viewportWidth;
  final double cardWidth;
  final double cardGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShimmerScope(
          child: Row(
            children: [
              const Expanded(child: _Bone(width: double.infinity, height: 11)),
              const SizedBox(width: 8),
              const _Bone(width: 48, height: 11),
              const SizedBox(width: 8),
              const _Bone(
                width: 30,
                height: 30,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              const SizedBox(width: 4),
              const _Bone(
                width: 30,
                height: 30,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardWidth,
          child: OverflowBox(
            maxWidth: viewportWidth,
            minWidth: viewportWidth,
            alignment: Alignment.center,
            child: SizedBox(
              width: viewportWidth,
              height: cardWidth,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CampaignPeekSkeleton(width: cardWidth, gap: cardGap),
                      SizedBox(width: cardGap),
                      _CampaignCardSkeleton(width: cardWidth),
                      SizedBox(width: cardGap),
                      _CampaignPeekSkeleton(width: cardWidth, gap: cardGap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ShimmerScope(
              child: Row(
                children: const [
                  _Bone(
                    width: 20,
                    height: 6,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  SizedBox(width: 7),
                  _Bone(
                    width: 6,
                    height: 6,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  SizedBox(width: 7),
                  _Bone(
                    width: 6,
                    height: 6,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CampaignPeekSkeleton extends StatelessWidget {
  const _CampaignPeekSkeleton({
    required this.width,
    required this.gap,
  });

  final double width;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.58,
      child: Transform.scale(
        scale: 0.935,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gap / 2),
          child: _CampaignCardSkeleton(width: width),
        ),
      ),
    );
  }
}

/// Mirrors [DugnadCampMiniCard]: square card with ~58% banner / ~42% body.
class _CampaignCardSkeleton extends StatelessWidget {
  const _CampaignCardSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: _ShimmerScope(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ScSaasThemeTokens.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 58,
                child: Stack(
                  fit: StackFit.expand,
                  children: const [
                    _Bone(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _Bone(
                        width: 118,
                        height: 24,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _Bone(
                        width: 96,
                        height: 24,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 42,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Bone(width: double.infinity, height: 15),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          _Bone(width: 12, height: 12),
                          SizedBox(width: 5),
                          Expanded(child: _Bone(width: double.infinity, height: 11)),
                          SizedBox(width: 8),
                          _Bone(
                            width: 68,
                            height: 22,
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Expanded(child: _Bone(width: double.infinity, height: 12)),
                          SizedBox(width: 8),
                          Expanded(child: _Bone(width: double.infinity, height: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
