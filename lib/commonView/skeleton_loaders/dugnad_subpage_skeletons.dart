import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constant/constant.dart';
import '../../theme/sc_saas_theme.dart';

/// Shared shimmer bones for dugnad sub-page skeletons.
class DugnadSkeletonScope extends StatelessWidget {
  const DugnadSkeletonScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colorShimmerBg,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class DugnadSkeletonBone extends StatelessWidget {
  const DugnadSkeletonBone({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

class DugnadSkeletonCard extends StatelessWidget {
  const DugnadSkeletonCard({
    super.key,
    required this.height,
    this.padding = const EdgeInsets.all(16),
  });

  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DugnadSkeletonScope(
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ScSaasThemeTokens.gray100),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DugnadSkeletonBone(width: 140, height: 14),
            SizedBox(height: 10),
            DugnadSkeletonBone(width: double.infinity, height: 12),
            SizedBox(height: 6),
            DugnadSkeletonBone(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Points screen — metal hero block + tier list cards.
class DugnadPointsFeedSkeleton extends StatelessWidget {
  const DugnadPointsFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonScope(
          child: Container(
            height: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DugnadSkeletonBone(
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DugnadSkeletonBone(width: 100, height: 11),
                          SizedBox(height: 8),
                          DugnadSkeletonBone(width: 130, height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                DugnadSkeletonBone(width: double.infinity, height: 12),
                SizedBox(height: 8),
                DugnadSkeletonBone(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const DugnadSkeletonCard(height: 120),
        const SizedBox(height: 14),
        const DugnadSkeletonCard(height: 96),
        const SizedBox(height: 14),
        const DugnadSkeletonCard(height: 140),
      ],
    );
  }
}

/// Missions / matches of the week — streak + challenge cards.
class DugnadMissionsFeedSkeleton extends StatelessWidget {
  const DugnadMissionsFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 88),
        SizedBox(height: 10),
        DugnadSkeletonCard(height: 120),
        SizedBox(height: 10),
        DugnadSkeletonCard(height: 120),
        SizedBox(height: 10),
        DugnadSkeletonCard(height: 96),
      ],
    );
  }
}

/// Referral share — share card + stats row.
class DugnadReferralFeedSkeleton extends StatelessWidget {
  const DugnadReferralFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DugnadSkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 148,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScSaasThemeTokens.gray100),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DugnadSkeletonBone(width: 160, height: 16),
                SizedBox(height: 12),
                DugnadSkeletonBone(width: double.infinity, height: 44),
                SizedBox(height: 10),
                DugnadSkeletonBone(width: double.infinity, height: 44),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: DugnadSkeletonCard(height: 72, padding: EdgeInsets.all(12))),
              SizedBox(width: 10),
              Expanded(child: DugnadSkeletonCard(height: 72, padding: EdgeInsets.all(12))),
            ],
          ),
          const SizedBox(height: 12),
          DugnadSkeletonCard(height: 100),
        ],
      ),
    );
  }
}

/// Supporter card — centered player card placeholder.
class DugnadSupporterCardSkeleton extends StatelessWidget {
  const DugnadSupporterCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DugnadSkeletonScope(
        child: Container(
          width: 300,
          height: 420,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ScSaasThemeTokens.gray100),
          ),
          child: const Column(
            children: [
              DugnadSkeletonBone(
                width: 88,
                height: 88,
                borderRadius: BorderRadius.all(Radius.circular(44)),
              ),
              SizedBox(height: 16),
              DugnadSkeletonBone(width: 160, height: 18),
              SizedBox(height: 8),
              DugnadSkeletonBone(width: 100, height: 12),
              Spacer(),
              DugnadSkeletonBone(width: double.infinity, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// Team detail — header stats + breakdown cards.
class DugnadTeamDetailFeedSkeleton extends StatelessWidget {
  const DugnadTeamDetailFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 132),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 160),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 120),
      ],
    );
  }
}

/// Career — stats row + badge grid.
class DugnadCareerFeedSkeleton extends StatelessWidget {
  const DugnadCareerFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 100),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: DugnadSkeletonCard(height: 72, padding: EdgeInsets.all(12))),
            SizedBox(width: 10),
            Expanded(child: DugnadSkeletonCard(height: 72, padding: EdgeInsets.all(12))),
          ],
        ),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 180),
      ],
    );
  }
}

/// Kampanje list — campaign card placeholders.
class DugnadKampanjeListSkeleton extends StatelessWidget {
  const DugnadKampanjeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 200),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 200),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 200),
      ],
    );
  }
}

/// Season recap — tall highlight cards + stats.
/// Season recap — mirrors `.rc-feed` layout: hero + 2×2 stats + finish + entry.
/// Lives on lavender feed (light-over-light), never on the dark hero.
class DugnadSeasonRecapSkeleton extends StatelessWidget {
  const DugnadSeasonRecapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DugnadSkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.rc-hero`
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DugnadSkeletonBone(width: 110, height: 11),
                SizedBox(height: 10),
                DugnadSkeletonBone(width: 220, height: 22),
                SizedBox(height: 10),
                DugnadSkeletonBone(width: double.infinity, height: 12),
                SizedBox(height: 6),
                DugnadSkeletonBone(width: 180, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // `.rc-stats` 2×2
          const Row(
            children: [
              Expanded(child: _RecapStatSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _RecapStatSkeleton()),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _RecapStatSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _RecapStatSkeleton()),
            ],
          ),
          const SizedBox(height: 14),
          // `.rc-finish`
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 14),
          // `.dg-pc-entry`
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 14),
          // Share CTA
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapStatSkeleton extends StatelessWidget {
  const _RecapStatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DugnadSkeletonBone(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 10),
          DugnadSkeletonBone(width: 64, height: 18),
          SizedBox(height: 6),
          DugnadSkeletonBone(width: 88, height: 11),
        ],
      ),
    );
  }
}

/// Transfer window — option rows (icon + title/sub + chevron), not stacked text cards.
class DugnadTransferWindowSkeleton extends StatelessWidget {
  const DugnadTransferWindowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    const iconRadius = BorderRadius.all(Radius.circular(13));
    return DugnadSkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: DugnadSkeletonBone(width: 92, height: 11),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 5; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: ScSaasThemeTokens.gray100),
              ),
              child: const Row(
                children: [
                  DugnadSkeletonBone(
                    width: 44,
                    height: 44,
                    borderRadius: iconRadius,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DugnadSkeletonBone(width: 128, height: 14),
                        SizedBox(height: 6),
                        DugnadSkeletonBone(width: 188, height: 12),
                      ],
                    ),
                  ),
                  DugnadSkeletonBone(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ],
              ),
            ),
            if (i < 4) const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ScSaasThemeTokens.gray100),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: DugnadSkeletonBone(width: 220, height: 12),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScSaasThemeTokens.gray100),
            ),
            child: const Row(
              children: [
                DugnadSkeletonBone(
                  width: 40,
                  height: 40,
                  borderRadius: iconRadius,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DugnadSkeletonBone(width: 96, height: 13),
                      SizedBox(height: 6),
                      DugnadSkeletonBone(width: 160, height: 11),
                    ],
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

/// Donation setup / manage — recipient + amount + frequency.
class DugnadDonationSkeleton extends StatelessWidget {
  const DugnadDonationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 120),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 160),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 100),
      ],
    );
  }
}

/// Formen screen — team form + match list.
class DugnadFormenSkeleton extends StatelessWidget {
  const DugnadFormenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 88),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 72),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 72),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 72),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 72),
        SizedBox(height: 12),
        DugnadSkeletonCard(height: 72),
      ],
    );
  }
}

/// Privacy — toggle cards.
class DugnadPrivacySkeleton extends StatelessWidget {
  const DugnadPrivacySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSkeletonCard(height: 80),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 80),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 80),
        SizedBox(height: 14),
        DugnadSkeletonCard(height: 120),
      ],
    );
  }
}

/// Points history — list items.
class DugnadPointsHistorySkeleton extends StatelessWidget {
  const DugnadPointsHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DugnadSkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(8, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScSaasThemeTokens.gray100),
            ),
            child: const Row(
              children: [
                DugnadSkeletonBone(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(18))),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DugnadSkeletonBone(width: 140, height: 12),
                      SizedBox(height: 6),
                      DugnadSkeletonBone(width: 80, height: 10),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                DugnadSkeletonBone(width: 48, height: 16),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
