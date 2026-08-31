import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../commonView/ae_inset_surface.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_state.dart';
import 'points_metal_theme.dart';
import 'dugnad_club_theme.dart';
import 'gamification_models.dart';
import 'dugnad_sto_source_breakdown.dart';
import 'dugnad_sto_utils.dart';
import 'dugnad_form_utils.dart';
import 'metal_hero_tokens.dart';
import 'widgets/ae_metal_hero_surface.dart';
import 'widgets/ae_metal_progress_bar.dart';
import 'widgets/dugnad_metal_animations.dart';
import 'dugnad_badge_emblem.dart';
import 'dugnad_badge_sheet.dart';

/// Tier display name: club alias → backend label → metal label.
///
/// Pass [config] to honour club-specific alias names from the config API.
String dugnadMetalTierLabel(MetalTierInfo tier, {GamificationConfig? config}) {
  return dugnadTierDisplayName(tier, config: config);
}

/// Shared Phase 6 points / profile widgets (prototype: `.dg-ptschip`).
class DugnadPointsChip extends StatelessWidget {
  const DugnadPointsChip({
    super.key,
    required this.points,
    this.small = false,
  });

  final int points;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final padH = small ? 9.0 : 11.0;
    final padV = small ? 3.0 : 5.0;
    final padL = small ? 7.0 : 8.0;
    final iconSize = small ? 10.0 : 12.0;
    final fontSize = small ? 11.0 : 12.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(padL),
        context.dp(padV),
        context.dp(padH),
        context.dp(padV),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDE6B0), Color(0xFFF6D275)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.55),
            blurRadius: context.dp(10),
            offset: Offset(0, context.dp(4)),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: context.dp(iconSize),
            color: const Color(0xFFE0A93A),
          ),
          SizedBox(width: context.dp(small ? 4 : 5)),
          Text(
            languages.dugnadPointsChip(points),
            style: aeCaption(color: const Color(0xFF7A5410)).copyWith(
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              letterSpacing: fontSize * -0.01,
            ).dp(context),
          ),
        ],
      ),
    );
  }
}

class DugnadEarnPointsRow extends StatelessWidget {
  const DugnadEarnPointsRow({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.points,
    this.strong = false,
    this.onTap,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  /// Optional custom glyph (e.g. nav cube SVG). Wins over [icon] when set.
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final int points;
  final bool strong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        margin: EdgeInsets.only(bottom: context.dp(8)),
        padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(13)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          boxShadow: [
            BoxShadow(
              color: context.dugnadTheme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(10),
              offset: Offset(context.dp(0), context.dp(3)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(38),
              height: context.dp(38),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.dp(12)),
                gradient: strong
                    ? context.dugnadTheme.shinyGradient
                    : null,
                color: strong ? null : context.dugnadTheme.primaryTint,
              ),
              alignment: Alignment.center,
              child: iconWidget ??
                  Icon(
                    icon!,
                    size: context.dp(18),
                    color: strong ? Colors.white : context.dugnadTheme.primary,
                  ),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800).dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(subtitle, style: aeCaption().dp(context)),
                ],
              ),
            ),
            // `.lb-ways .pts` — green pill, star + "+N" only (no "poeng").
            _LbWaysPointsBadge(points: points),
          ],
        ),
      ),
    );
  }
}

/// Prototype `.lb-ways .pts` — success tint pill with star and `+N`.
class _LbWaysPointsBadge extends StatelessWidget {
  const _LbWaysPointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF22A769);
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(8),
        context.dp(5),
        context.dp(10),
        context.dp(5),
      ),
      decoration: BoxDecoration(
        color: const Color(0x1F22A769), // rgba(34,167,105,.12)
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: context.dp(12),
            color: color,
          ),
          SizedBox(width: context.dp(4)),
          Text(
            '+$points',
            style: TextStyle(
              fontSize: context.dp(12.5),
              fontWeight: FontWeight.w900,
              letterSpacing: context.dp(12.5) * -0.01,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DugnadConnectTeamCard extends StatelessWidget {
  const DugnadConnectTeamCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(top: context.dp(10)),
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: context.dugnadTheme.primaryTint,
          borderRadius: BorderRadius.circular(context.dp(16)),
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(38),
              height: context.dp(38),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(12)),
                boxShadow: [
                  BoxShadow(
                    color: context.dugnadTheme.text.withValues(alpha: 0.04),
                    blurRadius: context.dp(6),
                    offset: Offset(context.dp(0), context.dp(2)),
                  ),
                ],
              ),
              child: Icon(
                Icons.shield_outlined,
                size: context.dp(20),
                color: context.dugnadTheme.primary,
              ),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadConnectPointsTeam,
                    style: aeBody().copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.dugnadTheme.primaryHover,
                    ).dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    languages.dugnadConnectPointsTeamSub,
                    style: aeCaption(color: context.dugnadTheme.primary).dp(context),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ScSaasThemeTokens.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

class DugnadProfilePointsCard extends StatelessWidget {
  const DugnadProfilePointsCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.teamRank,
    this.teamPlaceRank,
    this.teamPlaceTotal,
    this.config,
  });

  final PointsSummary summary;
  final VoidCallback onTap;
  final int? teamRank;
  final int? teamPlaceRank;
  final int? teamPlaceTotal;
  final GamificationConfig? config;

  @override
  Widget build(BuildContext context) {
    dugnadApplyMetalColorOverrides(config: config, summary: summary);
    final tier = summary.currentTier;
    // 0 pts = Bronse surface + star (never a grey/silver empty shell).
    final metal = summary.lifetimePoints <= 0
        ? 'bronse'
        : (tier?.metal ?? 'bronse');
    final ds = DugnadState.instance;
    final hasTeam = ds.hasPointsTeam;
    final nextTier = summary.nextTier;
    final nextSto = nextTier == null
        ? null
        : dugnadStoRatingAtNextMetalTier(
            nextTier: nextTier,
            config: config,
          );

    // The profile points card IS the pale points surface (prototype
    // `.dg-points-card.metal-*`), same family as the home anchor — a light metal
    // gradient on a near-white card with a metal border, NOT the saturated
    // STØ/player card (`.dg-playercard`). Dark metal ink reads on the pale surface.
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    final sub = fg.withValues(alpha: metal == 'bronse' ? 0.75 : 0.64);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: PointsMetalTheme.pointsCardDecoration(metal, radius: 20),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(15), context.dp(16), context.dp(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DugnadEmblemSheen(
                        child: DugnadMetalStarEmblem(metal: metal, size: context.dp(56)),
                      ),
                      SizedBox(width: context.dp(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: context.dp(9),
                                  height: context.dp(9),
                                  decoration: BoxDecoration(
                                    color: fg.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.dp(6)),
                                Text(
                                  (tier != null
                                          ? dugnadTierDisplayName(tier, config: config)
                                          : 'Bronse')
                                      .toUpperCase(),
                                  style: aeCaption(color: sub).copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 10 * 0.06,
                                    fontSize: 10,
                                  ).dp(context),
                                ),
                              ],
                            ),
                            SizedBox(height: context.dp(4)),
                            RichText(
                              text: TextSpan(
                                style: aeH2(color: fg).copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 23 * -0.02,
                                ).dp(context),
                                children: [
                                  TextSpan(text: '${summary.lifetimePoints}'),
                                  TextSpan(
                                    text: ' ${languages.dugnadPointsUnit}',
                                    style: aeBody(color: sub).copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ).dp(context),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.dp(3)),
                            Text(
                              _profileStatusLine(tier?.titleSuffix ?? '', hasTeam),
                              style: aeCaption(color: sub)
                                  .copyWith(fontWeight: FontWeight.w600).dp(context),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: fg.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  if (nextTier != null) ...[
                    SizedBox(height: context.dp(12)),
                    Text(
                      nextSto != null
                          ? languages.dugnadPointsToNextWithSto(
                              summary.pointsToNextTier,
                              nextTier.titleSuffix,
                              nextSto,
                              languages.dugnadStoPosition,
                            )
                          : languages.dugnadPointsToNext(
                              summary.pointsToNextTier,
                              nextTier.titleSuffix,
                            ),
                      style: aeCaption(color: fg).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.3,
                      ).dp(context),
                    ),
                    SizedBox(height: context.dp(7)),
                    DugnadAnimatedMetalProgressBar(
                      metal: metal,
                      progressPercent: summary.progressionPercent,
                      fadeEdges: false,
                    ),
                  ],
                  if (hasTeam) ...[
                    SizedBox(height: context.dp(13)),
                    Divider(
                      height: 1,
                      color: fg.withValues(alpha: 0.22),
                    ),
                    SizedBox(height: context.dp(12)),
                    Row(
                      children: [
                        ClubCrest(
                          name: ds.pointsTeamName,
                          logoUrl: ds.pointsTeamLogo.isEmpty
                              ? null
                              : ds.pointsTeamLogo,
                          size: context.dp(30),
                        ),
                        SizedBox(width: context.dp(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ds.pointsTeamName,
                                style: aeBody(color: fg)
                                    .copyWith(fontWeight: FontWeight.w900).dp(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: context.dp(11),
                                    color: sub,
                                  ),
                                  SizedBox(width: context.dp(4)),
                                  Expanded(
                                    child: Text(
                                      DugnadClubBranding.fullName(),
                                      style: aeCaption(color: sub)
                                          .copyWith(fontWeight: FontWeight.w700).dp(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (teamPlaceRank != null &&
                            teamPlaceTotal != null &&
                            teamPlaceTotal! > 0)
                          DugnadTeamPlaceChip(
                            rank: teamPlaceRank!,
                            total: teamPlaceTotal!,
                            metal: metal,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Positioned.fill(
              child: DugnadMetalGlazeOverlay(
                borderRadius: 20,
                phase: 0,
                overContent: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _profileStatusLine(String tierName, bool hasTeam) {
    if (tierName.isEmpty) return '';
    if (!hasTeam) {
      return languages.dugnadHeroNotConnected(tierName);
    }
    return tierName;
  }
}

class DugnadTeamPlaceChip extends StatelessWidget {
  const DugnadTeamPlaceChip({
    required this.rank,
    required this.total,
    required this.metal,
    this.onTap,
  });

  final int rank;
  final int total;
  final String metal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dp(13));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(11),
            vertical: context.dp(5),
          ),
          decoration: BoxDecoration(
            // Frosted-white inset — sits on a vivid metal card (profile / anchor).
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: PointsMetalTheme.pcEntryShadowColor(metal)
                    .withValues(alpha: 0.28),
                blurRadius: context.dp(8),
                offset: Offset(context.dp(0), context.dp(3)),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                // opacity .72 on the label, not a flatter grey.
                languages.dugnadYourPlaceLabel.toUpperCase(),
                style: aeCaption(
                  color: ScSaasThemeTokens.gray500.withValues(alpha: 0.72),
                ).copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 8 * 0.05,
                ).dp(context),
              ),
              Text(
                languages.dugnadYourPlaceRank(rank, total),
                style: aeBody().copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  height: 1.25,
                  letterSpacing: 17 * -0.02,
                  // The design opts this numeral in explicitly while leaving home's
                  // big points total proportional — tabular figures are selective
                  // here, not a house default. Without it a rank moving #7 -> #11
                  // jitters horizontally on every refresh.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ).dp(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DugnadLevelHeroCard extends StatelessWidget {
  const DugnadLevelHeroCard({
    super.key,
    required this.points,
    required this.tier,
    required this.nextTier,
    required this.progressPercent,
    required this.pointsToNext,
    required this.tierCount,
    required this.activeTierIndex,
    required this.stoRating,
    this.nextTierStoRating,
    this.config,
  });

  final int points;
  final MetalTierInfo? tier;
  final MetalTierInfo? nextTier;
  final int progressPercent;
  final int pointsToNext;
  final int tierCount;
  final int activeTierIndex;
  final int stoRating;
  final int? nextTierStoRating;
  final GamificationConfig? config;

  @override
  Widget build(BuildContext context) {
    final metal = tier?.metal ?? 'bronse';
    final tierLabel = tier != null ? dugnadMetalTierLabel(tier!, config: config) : '';
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);

    // `.lb-level` is Family A at the **hero** scale — a brighter inset and a
    // larger drop than home's card, per tone and non-proportionally.
    // AeMetalHeroSurface owns the ramp, both off-canvas radial overlays and
    // the faked inset; this card previously painted the ramp alone, which is
    // what made it read as coloured plastic rather than lit metal.
    return AeMetalHeroSurface(
      metal: metal,
      scale: AeMetalSurfaceScale.hero,
      radius: 20,
      child: Stack(
        children: [
          Positioned.fill(
            child: DugnadMetalAmbientGlaze(borderRadius: context.dp(20)),
          ),
            Padding(
            padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(18), context.dp(18), context.dp(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DugnadEmblemSheen(
                      child: Container(
                        width: context.dp(56),
                        height: context.dp(56),
                        decoration:
                            PointsMetalTheme.levelHeroBadgeDecoration(metal),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.star_rounded,
                          size: context.dp(26),
                          color: PointsMetalTheme.levelHeroBadgeIconColor(metal),
                        ),
                      ),
                    ),
                    SizedBox(width: context.dp(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: aeH2(color: fg).copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 30 * -0.03,
                                height: 1,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ).dp(context),
                              children: [
                                TextSpan(text: '$points'),
                                TextSpan(
                                  text: ' ${languages.dugnadPointsUnit}',
                                  style: TextStyle(
                                    fontSize: context.dp(12),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: context.dp(12) * 0.02,
                                    color: fg.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: context.dp(5)),
                          Text(
                            '$tierLabel · $dugnadStoRatingLabel $stoRating',
                            style: TextStyle(
                              fontSize: context.dp(14),
                              fontWeight: FontWeight.w800,
                              color: fg.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.dp(15)),
                // `.lb-level-prog` runs four independent timelines — fill,
                // glow, stripes and sweep — at 1050/2400/620/2800ms with
                // 100/1150/1300ms delays. Collapsing them into one tween makes
                // the bar pulse in lockstep and read as a loading indicator.
                AeMetalProgressBar(
                  metal: metal,
                  value: progressPercent / 100,
                ),
                SizedBox(height: context.dp(9)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        nextTier != null
                            ? (nextTierStoRating != null
                                ? languages.dugnadPointsToNextWithSto(
                                    pointsToNext,
                                    dugnadMetalTierLabel(
                                      nextTier!,
                                      config: config,
                                    ),
                                    nextTierStoRating!,
                                    dugnadStoRatingLabel,
                                  )
                                : languages.dugnadPointsToNext(
                                    pointsToNext,
                                    dugnadMetalTierLabel(
                                      nextTier!,
                                      config: config,
                                    ),
                                  ))
                            : languages.dugnadHighestTierReached,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.dp(11.5),
                          color: fg.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(tierCount, (i) {
                        final active = i == activeTierIndex;
                        return Container(
                          width: context.dp(7),
                          height: context.dp(7),
                          margin: EdgeInsets.only(left: context.dp(5)),
                          decoration: BoxDecoration(
                            color: PointsMetalTheme.levelStepDot(
                              metal,
                              active: active,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: DugnadMetalGlazeOverlay(
              borderRadius: context.dp(20),
              phase: 0,
              overContent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class DugnadLevelLadder extends StatelessWidget {
  const DugnadLevelLadder({
    super.key,
    required this.tiers,
    required this.previewIndex,
    required this.currentTierIndex,
    required this.onPreview,
    required this.actualStoRating,
    this.isPreviewing = false,
    this.stoTierThresholds = const [],
    this.config,
  });

  final List<MetalTierInfo> tiers;
  final int previewIndex;
  final int currentTierIndex;
  final ValueChanged<int> onPreview;
  final int actualStoRating;
  final bool isPreviewing;
  final List<StoTierThreshold> stoTierThresholds;
  final GamificationConfig? config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiers.length; i++) ...[
                if (i > 0) SizedBox(width: context.dp(7)),
                Expanded(
                  child: _LadderStepCard(
                    tier: tiers[i],
                    config: config,
                    isOn: i == currentTierIndex,
                    isDone: i < currentTierIndex,
                    isLocked: i > currentTierIndex,
                    onTap: null,
                    stoRating: dugnadLadderStepStoRating(
                      isOn: i == currentTierIndex,
                      isPreviewing: false,
                      actualStoRating: actualStoRating,
                      metal: tiers[i].metal,
                      tiers: stoTierThresholds,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LadderStepCard extends StatelessWidget {
  const _LadderStepCard({
    required this.tier,
    required this.isOn,
    required this.isDone,
    required this.isLocked,
    required this.onTap,
    required this.stoRating,
    this.config,
  });

  final MetalTierInfo tier;
  final GamificationConfig? config;
  final bool isOn;
  final bool isDone;
  final bool isLocked;
  final VoidCallback? onTap;
  final int stoRating;

  @override
  Widget build(BuildContext context) {
    final metal = tier.metal;

    BoxDecoration decoration;
    if (isLocked) {
      decoration = BoxDecoration(
        color: const Color(0xFFF7F6F9),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(color: Colors.transparent, width: context.dp(1.5)),
        boxShadow: [
          BoxShadow(
            color: context.dugnadTheme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(3),
            offset: Offset(context.dp(0), context.dp(1)),
          ),
        ],
      );
    } else {
      final theme = context.dugnadTheme;
      decoration = BoxDecoration(
        // `.lb-ladder .step.metal-*` is 135deg with a 48% midpoint -- the same
        // Family A ramp as .lb-level and M_BG, not a two-stop reduction.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: PointsMetalTheme.ladderStepMetalGradient(metal),
          stops: const [0.0, 0.48, 1.0],
        ),
        borderRadius: BorderRadius.circular(context.dp(14)),
        border: Border.all(
          color: isOn
              ? theme.primary
              : PointsMetalTheme.ladderStepBorder(metal),
          width: context.dp(1.5),
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.16),
                  blurRadius: context.dp(0),
                  spreadRadius: context.dp(3),
                ),
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.5),
                  blurRadius: context.dp(24),
                  spreadRadius: context.dp(-16),
                  offset: Offset(context.dp(0), context.dp(12)),
                ),
              ]
            : [
                BoxShadow(
                  color: ScSaasThemeTokens.text.withValues(alpha: 0.05),
                  blurRadius: context.dp(3),
                  offset: Offset(context.dp(0), context.dp(1)),
                ),
              ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // `.lb-ladder .step { padding: 12px 6px }`
        padding: EdgeInsets.fromLTRB(context.dp(6), context.dp(12), context.dp(6), context.dp(12)),
        decoration: decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _LadderDot(
              isDone: isDone,
              isOn: isOn,
              isLocked: isLocked,
            ),
            SizedBox(height: context.dp(8)),
            Text(
              dugnadMetalTierLabel(tier, config: config),
              style: TextStyle(
                fontSize: context.dp(10),
                fontWeight: FontWeight.w800,
                color: isLocked
                    ? ScSaasThemeTokens.gray500
                    : ScSaasThemeTokens.text,
                letterSpacing: -0.01 * 10,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.dp(4)),
            Text(
              '$dugnadStoRatingLabel $stoRating',
              style: TextStyle(
                fontSize: context.dp(11.5),
                fontWeight: FontWeight.w900,
                color: isLocked
                    ? const Color(0xFF9890A8)
                    : context.dugnadTheme.primaryHover,
                letterSpacing: -0.01 * 11.5,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.dp(3)),
            Text(
              '${tier.minPoints} p',
              style: TextStyle(
                fontSize: context.dp(9.5),
                fontWeight: FontWeight.w700,
                color: isLocked
                    ? const Color(0xFF9890A8)
                    : ScSaasThemeTokens.gray500,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DugnadStoSourceBreakdown extends StatelessWidget {
  const DugnadStoSourceBreakdown({
    super.key,
    required this.breakdown,
    required this.stoRating,
    required this.earnedBadgeCount,
  });

  final StoSourcePoints breakdown;
  final int stoRating;
  final int earnedBadgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final rows = [
      _StoSourceRowData(
        iconName: 'share',
        tone: DugnadBadgeTone.purple,
        title: languages.dugnadStoSourceActivityTitle,
        subtitle: languages.dugnadStoSourceActivitySub,
        points: breakdown.activityPoints,
      ),
      _StoSourceRowData(
        iconName: 'box',
        tone: DugnadBadgeTone.gold,
        title: languages.dugnadStoSourceCampaignTitle,
        subtitle: languages.dugnadStoSourceCampaignSub,
        points: breakdown.campaignPoints,
      ),
      _StoSourceRowData(
        iconName: 'star',
        tone: DugnadBadgeTone.green,
        title: languages.dugnadStoSourceBadgeTitle,
        subtitle: languages.dugnadStoSourceBadgeSub(earnedBadgeCount),
        points: breakdown.badgePoints,
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(top: context.dp(6)),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(9)),
          child: Text(
            languages.dugnadStoSourceSectionTitle.toUpperCase(),
            style: AeDugnadText.sectionLabel().dp(context),
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: context.dp(8)),
              _StoSourceRow(data: rows[i]),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(6), context.dp(8), context.dp(6), context.dp(0)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.dugnadSeasonPointsThisYear,
                      style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ).dp(context),
                    ),
                  ),
                  Text(
                    '= ${breakdown.seasonTotal}',
                    style: aeBody(color: theme.text).copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 15 * -0.01,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ).dp(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.dp(2)),
            Container(
              padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(12), context.dp(14), context.dp(12)),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(context.dp(14)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.6),
                    blurRadius: context.dp(16),
                    offset: Offset(context.dp(0), context.dp(6)),
                    spreadRadius: context.dp(-8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languages.dugnadYourStoRating,
                          style: TextStyle(
                            fontSize: context.dp(13.5),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: context.dp(13.5) * -0.01,
                          ),
                        ),
                        SizedBox(height: context.dp(1)),
                        Text(
                          languages.dugnadStoRatingFromPoints,
                          style: TextStyle(
                            fontSize: context.dp(11),
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$stoRating',
                    style: TextStyle(
                      fontSize: context.dp(26),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: context.dp(26) * -0.03,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }
}

class _StoSourceRowData {
  const _StoSourceRowData({
    required this.iconName,
    this.tone = DugnadBadgeTone.purple,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String iconName;
  final DugnadBadgeTone tone;
  final String title;
  final String subtitle;
  final int points;
}

class _StoSourceRow extends StatelessWidget {
  const _StoSourceRow({required this.data});

  final _StoSourceRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(13), context.dp(11), context.dp(13), context.dp(11)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(14)),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(2),
            offset: Offset(context.dp(0), context.dp(1)),
          ),
        ],
      ),
      child: Row(
        children: [
          // Figma `BadgeEmblem` — purple tone remaps to club shiny; gold/green stay.
          DugnadBadgeEmblem(
            iconName: data.iconName,
            tone: data.tone,
            locked: false,
            size: context.dp(38),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: aeBody(color: theme.text).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 14 * -0.01,
                  ).dp(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.dp(1)),
                Text(
                  data.subtitle,
                  style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ).dp(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: context.dp(8)),
          _StoSourcePointsValue(points: data.points),
        ],
      ),
    );
  }
}

class _StoSourcePointsValue extends StatelessWidget {
  const _StoSourcePointsValue({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final accent = context.dugnadTheme.primaryHover;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: context.dp(13.5),
          fontWeight: FontWeight.w900,
          letterSpacing: context.dp(13.5) * -0.01,
          color: accent,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        children: [
          TextSpan(text: '+$points'),
          TextSpan(
            text: ' ${languages.dugnadPointsShortSuffix}',
            style: TextStyle(
              fontSize: context.dp(10.5),
              fontWeight: FontWeight.w800,
              color: accent.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class DugnadStoCardPillarEntry extends StatelessWidget {
  const DugnadStoCardPillarEntry({
    super.key,
    required this.metal,
    required this.stoRating,
    required this.tierLabel,
    required this.onTap,
  });

  final String metal;
  final int stoRating;
  final String tierLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    final shadowMetal = PointsMetalTheme.pcEntryShadowColor(metal);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(15), context.dp(16), context.dp(15)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: PointsMetalTheme.pcEntryMetalGradient(metal),
                  stops: PointsMetalTheme.pcEntryMetalGradientStops,
                ),
                borderRadius: BorderRadius.circular(context.dp(18)),
                boxShadow: [
                  BoxShadow(
                    color: shadowMetal.withValues(alpha: 0.6),
                    blurRadius: context.dp(26),
                    offset: Offset(context.dp(0), context.dp(14)),
                    spreadRadius: context.dp(-16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 60),
                    padding: EdgeInsets.fromLTRB(context.dp(13), context.dp(8), context.dp(13), context.dp(8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(context.dp(14)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: context.dp(0),
                          offset: Offset(context.dp(0), context.dp(1)),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: context.dp(3),
                          offset: Offset(context.dp(0), context.dp(1)),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$stoRating',
                          style: TextStyle(
                            fontSize: context.dp(33),
                            fontWeight: FontWeight.w900,
                            letterSpacing: context.dp(33) * -0.04,
                            color: fg,
                            height: 0.88,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: context.dp(3), top: context.dp(3)),
                          child: Text(
                            dugnadStoRatingLabel,
                            style: TextStyle(
                              fontSize: context.dp(10.5),
                              fontWeight: FontWeight.w900,
                              letterSpacing: context.dp(10.5) * 0.08,
                              color: fg.withValues(alpha: 0.72),
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.dp(15)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languages.dugnadStoCardPillarTitle,
                          style: TextStyle(
                            fontSize: context.dp(15),
                            fontWeight: FontWeight.w900,
                            letterSpacing: context.dp(15) * -0.01,
                            color: fg,
                          ),
                        ),
                        SizedBox(height: context.dp(2)),
                        Text(
                          languages.dugnadStoCardPillarSubtitle(
                            tierLabel,
                            dugnadMetalDisplayLabel(metal),
                          ),
                          style: TextStyle(
                            fontSize: context.dp(12),
                            fontWeight: FontWeight.w700,
                            color: fg.withValues(alpha: 0.72),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: context.dp(18),
                    color: fg.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: DugnadMetalAmbientGlaze(borderRadius: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LadderDot extends StatelessWidget {
  const _LadderDot({
    required this.isDone,
    required this.isOn,
    required this.isLocked,
  });

  final bool isDone;
  final bool isOn;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: context.dp(24),
        height: context.dp(24),
        decoration: BoxDecoration(
          color: const Color(0x2922A769),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: context.dp(12),
          color: Color(0xFF22A769),
        ),
      );
    }
    if (isOn) {
      final theme = context.dugnadTheme;
      return Container(
        width: context.dp(24),
        height: context.dp(24),
        decoration: BoxDecoration(
          gradient: theme.shinyGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.6),
              blurRadius: context.dp(10),
              spreadRadius: context.dp(-4),
              offset: Offset(context.dp(0), context.dp(4)),
            ),
          ],
        ),
        child: Icon(
          Icons.star_rounded,
          size: context.dp(11),
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: context.dp(24),
      height: context.dp(24),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.gray100,
        shape: BoxShape.circle,
      ),
    );
  }
}

class DugnadTeamSectionCard extends StatelessWidget {
  const DugnadTeamSectionCard({
    super.key,
    required this.hasTeam,
    required this.teamName,
    required this.onTap,
    this.teamRank,
    this.teamTotal,
  });

  final bool hasTeam;
  final String teamName;
  final VoidCallback onTap;
  final int? teamRank;
  final int? teamTotal;

  @override
  Widget build(BuildContext context) {
    final subtitle = hasTeam
        ? (teamRank != null &&
                teamTotal != null &&
                teamRank! > 0 &&
                teamTotal! > 0
            ? languages.dugnadTeamPointsCount(teamRank!, teamTotal!)
            : languages.dugnadConnectPointsTeamSub)
        : languages.dugnadConnectPointsTeamSub;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(
            color: Color.lerp(
              context.dugnadTheme.primaryTint,
              context.dugnadTheme.primary,
              0.28,
            )!,
            width: context.dp(1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: context.dugnadTheme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: Offset(context.dp(0), context.dp(2)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(44),
              height: context.dp(44),
              decoration: BoxDecoration(
                color: context.dugnadTheme.primaryTint,
                borderRadius: BorderRadius.circular(context.dp(12)),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: context.dp(20),
                color: context.dugnadTheme.primaryHover,
              ),
            ),
            SizedBox(width: context.dp(13)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasTeam ? teamName : languages.dugnadConnectPointsTeam,
                    style: aeBody().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: -0.01 * 14.5,
                    ).dp(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    subtitle,
                    style: aeCaption().copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ).dp(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasTeam)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(8)),
                decoration: BoxDecoration(
                  color: context.dugnadTheme.primaryTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  languages.dugnadChangeTeam,
                  style: aeLabel(color: context.dugnadTheme.primaryHover).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ).dp(context),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: ScSaasThemeTokens.gray300,
              ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-form-entry` — compact form row on the points screen.
class DugnadFormEntryCard extends StatelessWidget {
  const DugnadFormEntryCard({
    super.key,
    required this.status,
    required this.onTap,
  });

  final DugnadFormStatus status;
  final VoidCallback onTap;

  String _statusLabel() {
    switch (status) {
      case DugnadFormStatus.up:
        return languages.dugnadFormStatusUp;
      case DugnadFormStatus.flat:
        return languages.dugnadFormStatusFlat;
      case DugnadFormStatus.down:
        return languages.dugnadFormStatusDown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(
            color: ScSaasThemeTokens.gray100,
            width: context.dp(1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: context.dugnadTheme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: Offset(context.dp(0), context.dp(2)),
            ),
          ],
        ),
        child: Row(
          children: [
            DugnadFormArrow(status: status, size: context.dp(22)),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadFormEntryTitle(_statusLabel()),
                    style: aeBody().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ).dp(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.dp(1)),
                  Text(
                    languages.dugnadFormEntrySubtitle,
                    style: aeCaption().copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ).dp(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.dp(18),
              color: ScSaasThemeTokens.gray300,
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-missions-entry` — club gradient missions CTA.
class DugnadMissionsEntryCard extends StatelessWidget {
  const DugnadMissionsEntryCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(15), context.dp(16), context.dp(15)),
              decoration: BoxDecoration(
                gradient: theme.shinyGradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.6),
                    blurRadius: context.dp(28),
                    offset: Offset(context.dp(0), context.dp(14)),
                    spreadRadius: context.dp(-14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: context.dp(42),
                    height: context.dp(42),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(context.dp(13)),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: context.dp(20),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: context.dp(13)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languages.dugnadMissionsEntryTitle,
                          style: TextStyle(
                            fontSize: context.dp(15.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: context.dp(15.5) * -0.01,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: context.dp(1)),
                        Text(
                          languages.dugnadMissionsEntrySubtitle,
                          style: TextStyle(
                            fontSize: context.dp(12.5),
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: context.dp(30),
                    height: context.dp(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: context.dp(18),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-kaptein` — top team contributor badge.
class DugnadKapteinChip extends StatelessWidget {
  const DugnadKapteinChip({
    super.key,
    required this.teamName,
  });

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        gradient: theme.shinyGradient,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.7),
            blurRadius: context.dp(28),
            offset: Offset(context.dp(0), context.dp(14)),
            spreadRadius: context.dp(-16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(46),
            height: context.dp(46),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(context.dp(13)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text('🏅', style: TextStyle(fontSize: context.dp(24), height: 1)),
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadKapteinTitle(teamName),
                  style: TextStyle(
                    fontSize: context.dp(15),
                    fontWeight: FontWeight.w900,
                    letterSpacing: context.dp(15) * -0.01,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  languages.dugnadKapteinSubtitle,
                  style: TextStyle(
                    fontSize: context.dp(11.5),
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(5)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              languages.dugnadKapteinBadge,
              style: TextStyle(
                fontSize: context.dp(10),
                fontWeight: FontWeight.w900,
                letterSpacing: context.dp(10) * 0.04,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Player role chip when the viewer is not the team captain.
class DugnadPlayerChip extends StatelessWidget {
  const DugnadPlayerChip({
    super.key,
    required this.teamName,
  });

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(
          color: ScSaasThemeTokens.gray100,
          width: context.dp(1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.05),
            blurRadius: context.dp(4),
            offset: Offset(context.dp(0), context.dp(2)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(46),
            height: context.dp(46),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(context.dp(13)),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: context.dp(22),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(width: context.dp(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadPlayerTitle(teamName),
                  style: aeBody().copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 15 * -0.01,
                  ).dp(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  languages.dugnadPlayerSubtitle,
                  style: aeCaption().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ).dp(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(5)),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              languages.dugnadPlayerBadge,
              style: aeLabel(color: theme.primaryHover).copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 10 * 0.04,
              ).dp(context),
            ),
          ),
        ],
      ),
    );
  }
}

class DugnadSupporterCardEntry extends StatelessWidget {
  const DugnadSupporterCardEntry({
    super.key,
    required this.tierName,
    required this.points,
    required this.metal,
    required this.onTap,
  });

  final String tierName;
  final int points;
  final String metal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(14)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PointsMetalTheme.bannerBackground(metal),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(context.dp(16)),
          border: Border.all(color: ScSaasThemeTokens.border),
        ),
        child: Row(
          children: [
            // The shiny family is inset-led; AeSurface.shiny painted the outer
            // drop alone and left the surface flat.
            SizedBox(
              width: context.dp(42),
              height: context.dp(42),
              child: AeInsetSurface.shinySm(
                isCircle: true,
                child: Center(
                  child: Icon(Icons.shield_outlined, size: context.dp(20)),
                ),
              ),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadShowSupporterCard,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800).dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    languages.dugnadSupporterCardLine(tierName, points),
                    style: aeCaption().dp(context),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ScSaasThemeTokens.gray500),
          ],
        ),
      ),
    );
  }
}

class DugnadDineMerker extends StatelessWidget {
  const DugnadDineMerker({
    super.key,
    required this.sections,
  });

  final DugnadBadgeSections sections;

  @override
  Widget build(BuildContext context) {
    final permEarned = sections.permanent.where((b) => b.earned).length;
    final seasEarned = sections.seasonal.where((b) => b.earned).length;
    final seasonTag = dugnadFormatSeasonTag(sections.seasonLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sections.permanent.isNotEmpty) ...[
          _DugnadMerkeHead(
            title: languages.dugnadPermanentBadgesTitle,
            subtitle: languages.dugnadPermanentBadgesSub,
            count: '$permEarned/${sections.permanent.length}',
            showRefresh: false,
          ),
          DugnadBadgeGrid(
            badges: sections.permanent,
            onBadgeTap: (b) => showDugnadBadgeSheet(context, badge: b),
          ),
        ],
        if (sections.seasonal.isNotEmpty) ...[
          if (sections.permanent.isNotEmpty) SizedBox(height: context.dp(18)),
          _DugnadMerkeHead(
            title: languages.dugnadSeasonalBadgesTitle,
            subtitle: languages.dugnadSeasonalBadgesSub,
            count: '$seasEarned/${sections.seasonal.length}',
            seasonTag: seasonTag.isNotEmpty ? seasonTag : null,
          ),
          DugnadBadgeGrid(
            badges: sections.seasonal,
            season: true,
            onBadgeTap: (b) => showDugnadBadgeSheet(context, badge: b),
          ),
        ],
      ],
    );
  }
}

class _DugnadMerkeHead extends StatelessWidget {
  const _DugnadMerkeHead({
    required this.title,
    required this.subtitle,
    required this.count,
    this.seasonTag,
    this.showRefresh = true,
  });

  final String title;
  final String subtitle;
  final String count;
  final String? seasonTag;
  final bool showRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(11)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: aeBody().copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 13 * -0.01,
                        ).dp(context),
                      ),
                    ),
                    if (seasonTag != null) ...[
                      SizedBox(width: context.dp(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(7),
                          vertical: context.dp(2),
                        ),
                        decoration: BoxDecoration(
                          // 135deg — without begin/end Flutter sweeps
                          // horizontally, not diagonally.
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFE9A8), Color(0xFFF6CF6B)],
                          ),
                          borderRadius: BorderRadius.circular(context.dp(6)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD8A028).withValues(alpha: 0.4),
                              blurRadius: context.dp(2),
                              offset: Offset(context.dp(0), context.dp(1)),
                            ),
                          ],
                        ),
                        child: Text(
                          seasonTag!,
                          style: TextStyle(
                            fontSize: context.dp(10),
                            fontWeight: FontWeight.w900,
                            // .04em at 10px is 0.4px, not 0.04px.
                            letterSpacing: context.dp(10) * 0.04,
                            color: Color(0xFF9A6B12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.dp(3)),
                Row(
                  children: [
                    if (showRefresh) ...[
                      Icon(
                        Icons.refresh_rounded,
                        size: context.dp(11),
                        color: theme.primary,
                      ),
                      SizedBox(width: context.dp(5)),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: aeCaption().copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ).dp(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.dp(10)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(4)),
            decoration: BoxDecoration(
              color: theme.primaryTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: context.dp(12),
                fontWeight: FontWeight.w900,
                color: theme.primaryHover,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DugnadBadgeGrid extends StatelessWidget {
  const DugnadBadgeGrid({
    super.key,
    required this.badges,
    this.season = false,
    this.onBadgeTap,
  });

  final List<DugnadBadgeItem> badges;
  final bool season;
  final ValueChanged<DugnadBadgeItem>? onBadgeTap;

  static const double _gap = 9;
  static const double _emblemSize = 42;

  @override
  Widget build(BuildContext context) {
    final rows = <List<DugnadBadgeItem>>[];
    for (var i = 0; i < badges.length; i += 2) {
      final end = i + 2 <= badges.length ? i + 2 : badges.length;
      rows.add(badges.sublist(i, end));
    }

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: _gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _DugnadBadgeCell(
                  badge: rows[r][0],
                  season: season,
                  onTap: onBadgeTap,
                )),
                const SizedBox(width: _gap),
                Expanded(
                  child: rows[r].length > 1
                      ? _DugnadBadgeCell(
                          badge: rows[r][1],
                          season: season,
                          onTap: onBadgeTap,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DugnadBadgeCell extends StatelessWidget {
  const _DugnadBadgeCell({
    required this.badge,
    this.season = false,
    this.onTap,
  });

  final DugnadBadgeItem badge;
  final bool season;
  final ValueChanged<DugnadBadgeItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    final theme = context.dugnadTheme;
    final stoBonus = badge.stoBonus;

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(badge),
      child: Opacity(
        opacity: earned ? 1 : 0.68,
        child: Container(
          padding: EdgeInsets.fromLTRB(context.dp(12), context.dp(11), context.dp(10), context.dp(11)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(14)),
            border: Border.all(
              color: earned
                  ? (season
                      ? const Color(0x66D8A028)
                      : Color.lerp(
                            theme.primaryTint,
                            theme.primary,
                            0.22,
                          )!)
                  : Colors.transparent,
              width: context.dp(1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: context.dp(3),
                offset: Offset(context.dp(0), context.dp(1)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DugnadBadgeEmblem(
                iconName: badge.icon,
                tone: badge.tone,
                locked: !earned,
                size: DugnadBadgeGrid._emblemSize,
              ),
              SizedBox(width: context.dp(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      badge.name,
                      style: aeBody().copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: -0.01 * 12.5,
                        height: 1.2,
                        color: earned
                            ? theme.text
                            : ScSaasThemeTokens.gray500,
                      ).dp(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      badge.subtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500)
                          .copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        height: 1.25,
                      ).dp(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stoBonus > 0) ...[
                      SizedBox(height: context.dp(5)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(6),
                          vertical: context.dp(3),
                        ),
                        decoration: BoxDecoration(
                          color: earned
                              ? (season
                                  ? const Color(0xFFFBF1D6)
                                  : theme.primaryTint)
                              : ScSaasThemeTokens.gray100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          earned
                              ? languages.dugnadBadgeStoEarned(stoBonus)
                              : languages.dugnadBadgeStoUnlock(stoBonus),
                          style: TextStyle(
                            fontSize: context.dp(9),
                            fontWeight: FontWeight.w900,
                            letterSpacing: context.dp(9) * 0.01,
                            color: earned
                                ? (season
                                    ? const Color(0xFF9A6B12)
                                    : theme.primaryHover)
                                : ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: context.dp(16),
                color: ScSaasThemeTokens.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DugnadProfileBadgesPreview extends StatelessWidget {
  const DugnadProfileBadgesPreview({
    super.key,
    required this.badges,
    required this.onTap,
  });

  final List<DugnadBadgeItem> badges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((b) => b.earned).length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Clip emblems to the card so a dense row never spills past the radius.
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.all(context.dp(14)),
        decoration: AeSurface.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OverlappingBadgeRow(badges: badges),
            SizedBox(height: context.dp(12)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: context.dp(12)),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ScSaasThemeTokens.gray100,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.dugnadBadgesUnlocked(earned, badges.length),
                      style: aeCaption().dp(context),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dp(12),
                      vertical: context.dp(6),
                    ),
                    decoration: BoxDecoration(
                      color: context.dugnadTheme.primaryTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languages.dugnadSeeAllBadges,
                          style: aeLabel(color: context.dugnadTheme.primary)
                              .dp(context),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: context.dp(16),
                          color: context.dugnadTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-row badge strip (design `.dg-prof-badges .emblems`).
///
/// Always fills the card width — emblems share space evenly and may visually
/// overlap when there are many, but never expand past the card edge.
class _OverlappingBadgeRow extends StatelessWidget {
  const _OverlappingBadgeRow({required this.badges});

  final List<DugnadBadgeItem> badges;

  @override
  Widget build(BuildContext context) {
    const double size = 40;
    const double ring = 2;
    const double tile = size + ring * 2;

    if (badges.isEmpty) return const SizedBox(height: tile);

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = badges.length;
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return SizedBox(height: tile, width: double.infinity);
        }

        // Fit exactly in [0, maxW]. Never clamp step upward — that was what
        // pushed the row past the card (17 badges × min stride).
        final step = n > 1 ? (maxW - tile) / (n - 1) : 0.0;

        return SizedBox(
          height: tile,
          width: maxW,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (int i = 0; i < n; i++)
                Positioned(
                  left: (i * step).clamp(0.0, maxW > tile ? maxW - tile : 0.0),
                  child: Container(
                    padding: const EdgeInsets.all(ring),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: DugnadBadgeEmblem(
                      iconName: badges[i].icon,
                      tone: badges[i].tone,
                      locked: !badges[i].earned,
                      size: size,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DugnadMetalStarEmblem extends StatelessWidget {
  const DugnadMetalStarEmblem({
    super.key,
    required this.metal,
    required this.size,
  });

  final String metal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: PointsMetalTheme.gradientForMetal(metal),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.dugnadTheme.text.withValues(alpha: 0.18),
                  blurRadius: context.dp(14),
                  offset: Offset(context.dp(0), context.dp(6)),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: context.dp(0),
                  offset: Offset(context.dp(0), context.dp(1)),
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: PointsMetalTheme.emblemCoreGradient(metal),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: context.dp(2),
              ),
            ),
            child: Icon(
              Icons.star_rounded,
              size: size * 0.34,
              color: PointsMetalTheme.emblemStarColor(metal),
            ),
          ),
          Positioned(
            top: size * 0.07,
            left: size * 0.14,
            right: size * 0.14,
            child: Container(
              height: size * 0.34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int dugnadTierIndexForPoints(List<MetalTierInfo> tiers, int points) {
  if (tiers.isEmpty) return 0;
  var idx = 0;
  for (var i = 0; i < tiers.length; i++) {
    if (points >= tiers[i].minPoints) idx = i;
  }
  return idx;
}

int dugnadDisplayPointsForPreview({
  required List<MetalTierInfo> tiers,
  required int actualPoints,
  required int previewIndex,
  required int currentTierIndex,
}) {
  if (previewIndex == currentTierIndex) return actualPoints;
  if (previewIndex < tiers.length) return tiers[previewIndex].minPoints;
  return actualPoints;
}

MetalTierInfo? dugnadTierAtIndex(List<MetalTierInfo> tiers, int index) {
  if (index < 0 || index >= tiers.length) return null;
  return tiers[index];
}

String dugnadLastTierPrefKey() {
  return '${prefGetInt(prefUserId)}_${DugnadState.instance.clubId}';
}
