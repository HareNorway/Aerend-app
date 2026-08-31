import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'points_history_screen.dart';
import 'points_metal_theme.dart';
import 'dugnad_club_theme.dart';

/// Progression banner + metal tier cards (Phase 6).
class PointsProgressionSection extends StatefulWidget {
  const PointsProgressionSection({super.key});

  @override
  State<PointsProgressionSection> createState() =>
      _PointsProgressionSectionState();
}

class _PointsProgressionSectionState extends State<PointsProgressionSection> {
  final DugnadRepo _repo = DugnadRepo();
  PointsSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!isLoggedIn()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final summary = await _repo.getPointsSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn()) return const SizedBox.shrink();
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dp(20), vertical: context.dp(8)),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    final metal = summary.currentTier?.metal ?? 'bronse';
    final bannerBg = PointsMetalTheme.bannerBackground(metal);
    final accent = PointsMetalTheme.colorForMetal(metal);

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(20), context.dp(4), context.dp(20), context.dp(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PointsHistoryScreen()),
            ),
            child: Container(
              padding: EdgeInsets.all(context.dp(16)),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: BorderRadius.circular(context.dp(18)),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(10),
                          vertical: context.dp(4),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: PointsMetalTheme.gradientForMetal(metal),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          summary.currentTier?.titleSuffix ??
                              summary.currentTier?.labelNo ??
                              'Bronse',
                          style: aeCaption(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ).dp(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'STØ ${summary.stoRating}',
                        style: aeH2().copyWith(
                          fontSize: 22,
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ).dp(context),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dp(12)),
                  Text(
                    languages.dugnadPointsTeamTotal(summary.lifetimePoints),
                    style: aeBody().copyWith(fontWeight: FontWeight.w700).dp(context),
                  ),
                  if (summary.nextTier != null) ...[
                    SizedBox(height: context.dp(4)),
                    Text(
                      '${summary.pointsToNextTier} poeng til ${summary.nextTier!.titleSuffix}',
                      style: aeCaption(color: ScSaasThemeTokens.gray500).dp(context),
                    ),
                  ],
                  SizedBox(height: context.dp(10)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: summary.progressionPercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      color: accent,
                    ),
                  ),
                  SizedBox(height: context.dp(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${summary.seasonPoints} sesongpoeng',
                        style: aeCaption(color: ScSaasThemeTokens.gray500).dp(context),
                      ),
                      Text(
                        languages.dugnadPointsHistoryLink,
                        style: aeCaption(color: context.dugnadTheme.primary)
                            .copyWith(fontWeight: FontWeight.w700).dp(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (summary.metalTiers.isNotEmpty) ...[
            SizedBox(height: context.dp(12)),
            SizedBox(
              height: context.dp(92),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summary.metalTiers.length,
                separatorBuilder: (_, __) => SizedBox(width: context.dp(10)),
                itemBuilder: (context, index) {
                  final tier = summary.metalTiers[index];
                  final tierColor = PointsMetalTheme.colorForMetal(tier.metal);
                  final active = tier.achieved;
                  return Container(
                    width: context.dp(120),
                    padding: EdgeInsets.all(context.dp(12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.dp(14)),
                      boxShadow: ScSaasThemeTokens.shadowCard,
                      border: Border.all(
                        color: active
                            ? tierColor.withValues(alpha: 0.55)
                            : ScSaasThemeTokens.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tier.labelNo,
                          style: aeCaption(
                            color: active
                                ? tierColor
                                : ScSaasThemeTokens.gray500,
                          ).copyWith(fontWeight: FontWeight.w800).dp(context),
                        ),
                        const Spacer(),
                        Text(
                          tier.titleSuffix,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: aeCaption().copyWith(
                            fontSize: 10,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                          ).dp(context),
                        ),
                        SizedBox(height: context.dp(4)),
                        Text(
                          '${tier.minPoints}+',
                          style: aeCaption(color: ScSaasThemeTokens.gray500)
                              .copyWith(fontSize: 10).dp(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
