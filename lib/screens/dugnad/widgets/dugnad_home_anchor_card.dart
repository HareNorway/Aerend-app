import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../club_crest.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_t1_controller.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_models.dart';
import '../dugnad_points_widgets.dart';
import '../dugnad_state.dart';
import '../dugnad_sto_utils.dart';
import '../gamification_models.dart';
import '../metal_hero_tokens.dart';
import '../points_metal_theme.dart';
import 'dugnad_t1_pulse_overlay.dart';
import 'ae_metal_hero_surface.dart';
import 'dugnad_metal_animations.dart';

/// Home-screen points anchor card (prototype: `DGPointsCard` in club-select.jsx).
class DugnadHomeAnchorCard extends StatefulWidget {
  const DugnadHomeAnchorCard({
    super.key,
    required this.summary,
    required this.config,
    required this.teamRank,
    required this.teamTotal,
    required this.onOpenPoints,
    required this.onOpenStoCard,
    required this.onConnectTeam,
    this.onOpenLeaderboard,
    this.isGuest = false,
    /// Browse-without-club preview — force a metal tone (e.g. `solv`) so coral
    /// theme tint does not bleed through the lock blur.
    this.previewMetal,
    /// When a team is selected, show the "Din plass" chip (home + profile).
    this.showTeamRank = true,
    /// Profile omits the season-carryover strip.
    this.showSeasonCarryover = true,
    /// T1 inline count-up override (lifetime total shown on card).
    this.displayLifetimePoints,
  });

  final PointsSummary? summary;
  final GamificationConfig? config;
  final int? teamRank;
  final int? teamTotal;
  final VoidCallback onOpenPoints;
  final VoidCallback onOpenStoCard;
  final VoidCallback onConnectTeam;
  /// "Din plass" rank chip — opens the leaderboard tab when set.
  final VoidCallback? onOpenLeaderboard;
  final bool isGuest;
  final String? previewMetal;
  final bool showTeamRank;
  final bool showSeasonCarryover;
  final int? displayLifetimePoints;

  @override
  State<DugnadHomeAnchorCard> createState() => _DugnadHomeAnchorCardState();
}

class _DugnadHomeAnchorCardState extends State<DugnadHomeAnchorCard> {
  bool _isCardVisible(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return false;
    return TickerMode.of(context);
  }

  @override
  void initState() {
    super.initState();
    DugnadT1Controller.instance.attachCard();
    final pts = widget.summary?.lifetimePoints;
    if (pts != null) {
      DugnadT1Controller.instance.syncBaseline(pts);
    }
  }

  @override
  void dispose() {
    DugnadT1Controller.instance.detachCard();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DugnadHomeAnchorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    DugnadT1Controller.instance.setCardVisible(_isCardVisible(context));
    final prev = oldWidget.summary?.lifetimePoints;
    final next = widget.summary?.lifetimePoints;
    if (prev != null && next != null) {
      if (next > prev) {
        if (!_isCardVisible(context) ||
            MediaQuery.disableAnimationsOf(context)) {
          DugnadT1Controller.instance.applyInstant(next);
        } else {
          unawaited(
            DugnadT1Controller.instance.onPointsIncreased(
              previous: prev,
              next: next,
            ),
          );
        }
      } else if (next != prev && !DugnadT1Controller.instance.isPulsing) {
        DugnadT1Controller.instance.syncBaseline(next);
      }
    } else if (next != null) {
      DugnadT1Controller.instance.syncBaseline(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    DugnadT1Controller.instance.setCardVisible(_isCardVisible(context));
    return ListenableBuilder(
      listenable: DugnadT1Controller.instance,
      builder: (context, _) {
        final t1 = DugnadT1Controller.instance;
        return _DugnadHomeAnchorCardBody(
          summary: widget.summary,
          config: widget.config,
          teamRank: widget.teamRank,
          teamTotal: widget.teamTotal,
          onOpenPoints: widget.onOpenPoints,
          onOpenStoCard: widget.onOpenStoCard,
          onConnectTeam: widget.onConnectTeam,
          onOpenLeaderboard: widget.onOpenLeaderboard,
          isGuest: widget.isGuest,
          previewMetal: widget.previewMetal,
          showTeamRank: widget.showTeamRank,
          showSeasonCarryover: widget.showSeasonCarryover,
          displayLifetimePoints:
              widget.displayLifetimePoints ?? t1.displayPoints,
          pulseDelta: t1.pulseDelta,
        );
      },
    );
  }
}

class _DugnadHomeAnchorCardBody extends StatelessWidget {
  const _DugnadHomeAnchorCardBody({
    required this.summary,
    required this.config,
    required this.teamRank,
    required this.teamTotal,
    required this.onOpenPoints,
    required this.onOpenStoCard,
    required this.onConnectTeam,
    this.onOpenLeaderboard,
    this.isGuest = false,
    this.previewMetal,
    this.showTeamRank = true,
    this.showSeasonCarryover = true,
    this.displayLifetimePoints,
    this.pulseDelta,
  });

  final PointsSummary? summary;
  final GamificationConfig? config;
  final int? teamRank;
  final int? teamTotal;
  final VoidCallback onOpenPoints;
  final VoidCallback onOpenStoCard;
  final VoidCallback onConnectTeam;
  final VoidCallback? onOpenLeaderboard;
  final bool isGuest;
  final String? previewMetal;
  final bool showTeamRank;
  final bool showSeasonCarryover;
  final int? displayLifetimePoints;
  /// T1 gain amount — when set, plays Design `.dg-pcard.gaining` FX.
  final int? pulseDelta;

  @override
  Widget build(BuildContext context) {
    final data = summary ?? const PointsSummary();
    dugnadApplyMetalColorOverrides(config: config, summary: data);
    final browsePreview = previewMetal != null;
    // Guests get the gray empty shell. Logged-in users at 0 points are still
    // Bronse — same Family A metal card as everyone else (not the empty shell).
    final empty = isGuest && !browsePreview;
    final tier = data.currentTier ??
        _tierAtOrBelow(data.metalTiers, data.lifetimePoints) ??
        (data.metalTiers.isNotEmpty ? data.metalTiers.first : null);
    final metal = previewMetal ?? tier?.metal ?? 'bronse';
    final tierName = previewMetal != null
        ? dugnadMetalDisplayLabel(previewMetal!)
        : tier != null
            ? dugnadTierDisplayName(tier, config: config)
            : dugnadMetalDisplayLabel(metal);
    final ds = DugnadState.instance;
    final hasTeam = ds.hasPointsTeam;
    final nextTier = data.nextTier ??
        _nextTierAbove(data.metalTiers, data.lifetimePoints);
    final carryoverPts = _carryoverPoints(data, config);
    final showCarryover =
        showSeasonCarryover && !empty && carryoverPts > 0;

    if (empty) {
      return _EmptyAnchorCard(
        onTap: onOpenPoints,
        onConnectTeam: hasTeam ? null : onConnectTeam,
        hasTeam: hasTeam,
        teamRank: teamRank,
        teamTotal: teamTotal,
        isGuest: isGuest,
      );
    }

    final nextSto = nextTier == null
        ? null
        : dugnadStoRatingAtNextMetalTier(
            nextTier: nextTier,
            config: config,
          );
    final nextLabel = nextTier == null
        ? ''
        : (nextTier.titleSuffix.trim().isNotEmpty
            ? nextTier.titleSuffix
            : dugnadTierDisplayName(nextTier, config: config));
    final pointsToNext = nextTier == null
        ? 0
        : (data.nextTier != null
            ? data.pointsToNextTier
            : (nextTier.minPoints - data.lifetimePoints)
                .clamp(0, 1 << 30)
                .toInt());
    final progressionPercent = nextTier == null
        ? 100
        : (data.nextTier != null
            ? data.progressionPercent
            : _progressionToward(
                points: data.lifetimePoints,
                currentMin: tier?.minPoints ?? 0,
                nextMin: nextTier.minPoints,
              ));

    // `DGClubHome` and Profile both mount `DGPointsCard` — Family A saturated
    // 135deg 3-stop ramp (`M_BG`/`M_SHADOW`), STØ-kort pill, in-card connect.
    // NOT the pale `.dg-points-card` Family B shell.
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    // Secondary ink on pale metal cards — match STØ sheet legibility (~72%).
    final sub = fg.withValues(alpha: metal == 'bronse' ? 0.75 : 0.72);
    // Hairline / press-tints that read on the pale surface (prototype `.dg-pc-team`
    // border ≈ dark metal ink at low alpha); white dividers vanish on pale gold.
    final hairline = fg.withValues(alpha: 0.12);

    final gaining = pulseDelta != null && pulseDelta! > 0;
    Widget emblem = DugnadEmblemSheen(
      child: DugnadMetalStarEmblem(
        metal: metal,
        size: context.dp(42),
      ),
    );
    if (gaining) {
      emblem = DugnadT1BadgeBump(key: ValueKey('t1-badge-$pulseDelta'), child: emblem);
    }

    Widget pointsLine = RichText(
      text: TextSpan(
        style: aeH2()
            .copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 24 * -0.02,
              height: 1,
              color: fg,
            )
            .dp(context),
        children: [
          TextSpan(
            text: '${displayLifetimePoints ?? data.lifetimePoints}',
          ),
          TextSpan(
            text: ' ${languages.dugnadPointsUnit}',
            style: aeBody(color: sub)
                .copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1,
                )
                .dp(context),
          ),
        ],
      ),
    );
    if (gaining) {
      pointsLine = DugnadT1NumPulse(
        key: ValueKey('t1-num-$pulseDelta'),
        child: pointsLine,
      );
    }

    return AeMetalHeroSurface(
      metal: metal,
      // Home is the dimmer/tighter of Family A's two surface scales: a lower
      // inset alpha per tone and a `0 14px 26px -16px` drop.
      scale: AeMetalSurfaceScale.home,
      radius: 16,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenPoints();
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(14),
                      context.dp(12),
                      context.dp(14),
                      context.dp(0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        emblem,
                        SizedBox(width: context.dp(13)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: context.dp(7),
                                    height: context.dp(7),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors:
                                            PointsMetalTheme.gradientForMetal(
                                              metal,
                                            ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: context.dp(6)),
                                  Text(
                                    tierName.toUpperCase(),
                                    style: aeCaption(color: fg)
                                        .copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 10.5 * 0.07,
                                          fontSize: 10.5,
                                        )
                                        .dp(context),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.dp(2)),
                              pointsLine,
                              SizedBox(height: context.dp(3)),
                              Text(
                                _statusLine(
                                  (tier?.titleSuffix.trim().isNotEmpty ?? false)
                                      ? tier!.titleSuffix
                                      : tierName,
                                  hasTeam,
                                ),
                                style: aeCaption(color: sub)
                                    .copyWith(fontWeight: FontWeight.w600)
                                    .dp(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _StoCardChip(
                          stoRating: data.stoRating,
                          onTap: onOpenStoCard,
                          ink: fg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (nextTier != null && !browsePreview) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(14),
                    context.dp(10),
                    context.dp(14),
                    context.dp(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        nextSto != null
                            ? languages.dugnadPointsToNextWithSto(
                                pointsToNext,
                                nextLabel,
                                nextSto,
                                languages.dugnadStoPosition,
                              )
                            : languages.dugnadPointsToNext(
                                pointsToNext,
                                nextLabel,
                              ),
                        style: aeCaption(color: fg)
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              height: 1.3,
                            )
                            .dp(context),
                      ),
                      SizedBox(height: context.dp(7)),
                      DugnadAnimatedMetalProgressBar(
                        metal: metal,
                        progressPercent: progressionPercent,
                        fadeEdges: false,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: hairline),
              ],
              if (hasTeam) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(14),
                    context.dp(11),
                    context.dp(14),
                    context.dp(12),
                  ),
                  child: Row(
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
                                  .copyWith(fontWeight: FontWeight.w900)
                                  .dp(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: context.dp(11),
                                  color: PointsMetalTheme.colorForMetal(metal),
                                ),
                                SizedBox(width: context.dp(4)),
                                Expanded(
                                  child: Text(
                                    DugnadClubBranding.fullName(),
                                    style: aeCaption(color: sub)
                                        .copyWith(fontWeight: FontWeight.w700)
                                        .dp(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (showTeamRank &&
                          teamRank != null &&
                          teamTotal != null &&
                          teamRank! > 0 &&
                          teamTotal! > 0)
                        DugnadTeamPlaceChip(
                          rank: teamRank!,
                          total: teamTotal!,
                          metal: metal,
                          onTap: onOpenLeaderboard,
                        ),
                    ],
                  ),
                ),
              ] else if (!hasTeam)
                Material(
                  color: fg.withValues(alpha: 0.06),
                  child: InkWell(
                    // Haptic fires in the onConnectTeam handler (_pickPointsTeam).
                    onTap: onConnectTeam,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.dp(10),
                        horizontal: context.dp(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: context.dp(15),
                            color: browsePreview
                                ? fg
                                : context.dugnadTheme.primaryHover,
                          ),
                          SizedBox(width: context.dp(7)),
                          Text(
                            languages.dugnadConnectPointsToTeam,
                            style: aeBody()
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: browsePreview
                                      ? fg
                                      : context.dugnadTheme.primaryHover,
                                  fontSize: 13,
                                )
                                .dp(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showCarryover) ...[
                Divider(height: 1, color: hairline),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(14),
                    context.dp(9),
                    context.dp(14),
                    context.dp(11),
                  ),
                  child: Row(
                    children: [
                      DugnadCarryoverFlyGraphic(
                        dotColor: PointsMetalTheme.colorForMetal(metal),
                      ),
                      SizedBox(width: context.dp(11)),
                      Expanded(
                        child: Text(
                          languages.dugnadSeasonCarryoverLine(carryoverPts),
                          style: aeCaption(color: sub)
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                height: 1.35,
                              )
                              .dp(context),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(8),
                          vertical: context.dp(3),
                        ),
                        decoration: BoxDecoration(
                          color: PointsMetalTheme.colorForMetal(
                            metal,
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          languages.dugnadNowTier(tierName),
                          style: aeCaption(color: fg)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              )
                              .dp(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const Positioned.fill(
            child: DugnadMetalGlazeOverlay(
              borderRadius: 16,
              phase: 0,
              overContent: true,
            ),
          ),
          if (gaining)
            Positioned.fill(
              child: DugnadT1PulseOverlay(
                key: ValueKey('t1-fx-$pulseDelta'),
                delta: pulseDelta!,
                accent: context.dugnadTheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _statusLine(String tierName, bool hasTeam) {
    if (tierName.isEmpty) return '';
    if (!hasTeam) return languages.dugnadHeroNotConnected(tierName);
    return tierName;
  }

  int _carryoverPoints(PointsSummary data, GamificationConfig? cfg) {
    if (cfg == null) return 0;
    // Fixed per-metal carryover (what the rollover actually awards). Returns 0
    // when config.metalCarryover is missing/empty; the caller's `> 0` gate then
    // hides the row rather than showing a wrong (percent) or zero number.
    return dugnadMetalCarryoverPreview(
          stoRating: data.stoRating,
          config: cfg,
        ).appliedPoints ??
        0;
  }
}

MetalTierInfo? _tierAtOrBelow(List<MetalTierInfo> tiers, int points) {
  if (tiers.isEmpty) return null;
  MetalTierInfo? best;
  for (final t in tiers) {
    if (points >= t.minPoints) best = t;
  }
  return best;
}

MetalTierInfo? _nextTierAbove(List<MetalTierInfo> tiers, int points) {
  MetalTierInfo? next;
  for (final t in tiers) {
    if (t.minPoints > points) {
      if (next == null || t.minPoints < next.minPoints) next = t;
    }
  }
  return next;
}

int _progressionToward({
  required int points,
  required int currentMin,
  required int nextMin,
}) {
  final span = nextMin - currentMin;
  if (span <= 0) return 100;
  return (((points - currentMin) / span) * 100).round().clamp(0, 100);
}

class _EmptyAnchorCard extends StatelessWidget {
  const _EmptyAnchorCard({
    required this.onTap,
    required this.onConnectTeam,
    required this.hasTeam,
    required this.teamRank,
    required this.teamTotal,
    required this.isGuest,
  });

  final VoidCallback onTap;
  final VoidCallback? onConnectTeam;
  final bool hasTeam;
  final int? teamRank;
  final int? teamTotal;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    const metal = 'bronse';
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    final sub = fg.withValues(alpha: 0.75);

    return Container(
      decoration: PointsMetalTheme.pointsCardDecoration(metal, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dp(14),
                  context.dp(12),
                  context.dp(14),
                  context.dp(12),
                ),
                child: Row(
                  children: [
                    DugnadEmblemSheen(
                      child: DugnadMetalStarEmblem(
                        metal: metal,
                        size: context.dp(42),
                      ),
                    ),
                    SizedBox(width: context.dp(13)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languages.dugnadYourPoints,
                            style: aeCaption(color: fg)
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 10.5 * 0.07,
                                  fontSize: 10.5,
                                )
                                .dp(context),
                          ),
                          SizedBox(height: context.dp(2)),
                          RichText(
                            text: TextSpan(
                              style: aeH2()
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    color: fg,
                                  )
                                  .dp(context),
                              children: [
                                const TextSpan(text: '0'),
                                TextSpan(
                                  text: ' ${languages.dugnadPointsUnit}',
                                  style: aeBody(color: sub)
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      )
                                      .dp(context),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: context.dp(3)),
                          Text(
                            isGuest
                                ? languages.dugnadSignInForPoints
                                : languages.dugnadNoPointsYet,
                            style: aeCaption(
                              color: sub,
                            ).copyWith(fontWeight: FontWeight.w600).dp(context),
                          ),
                        ],
                      ),
                    ),
                    _StoCardChip(stoRating: null, onTap: onTap, ink: fg),
                  ],
                ),
              ),
            ),
          ),
          if (!hasTeam && onConnectTeam != null)
            Material(
              color: context.dugnadTheme.primaryTint.withValues(alpha: 0.35),
              child: InkWell(
                // Haptic fires in the onConnectTeam handler (_pickPointsTeam).
                onTap: onConnectTeam,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.dp(10),
                    horizontal: context.dp(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: context.dp(15),
                        color: context.dugnadTheme.primaryHover,
                      ),
                      SizedBox(width: context.dp(7)),
                      Text(
                        languages.dugnadConnectPointsToTeam,
                        style: aeBody()
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.dugnadTheme.primaryHover,
                              fontSize: 13,
                            )
                            .dp(context),
                      ),
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

class _StoCardChip extends StatelessWidget {
  const _StoCardChip({required this.stoRating, required this.onTap, this.ink});

  final int? stoRating;
  final VoidCallback onTap;

  /// Metal ink used for the label/rating on the vivid card; falls back to the
  /// default (midnight) on the empty-state card.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final labelColor = ink ?? ScSaasThemeTokens.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(context.dp(12)),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.dp(10),
            context.dp(6),
            context.dp(8),
            context.dp(6),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: stoRating == null ? 1 : 0.92),
            borderRadius: BorderRadius.circular(context.dp(12)),
            border: Border.all(
              color: stoRating == null
                  ? const Color(0xFFE6E7EC)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: stoRating == null
                ? null
                : [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.75),
                      blurRadius: context.dp(0),
                      offset: Offset(context.dp(0), context.dp(1)),
                    ),
                    BoxShadow(
                      color: ScSaasThemeTokens.text.withValues(alpha: 0.12),
                      blurRadius: context.dp(11),
                      offset: Offset(context.dp(0), context.dp(4)),
                      spreadRadius: context.dp(-5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: context.dp(12),
                color: labelColor,
              ),
              SizedBox(width: context.dp(4)),
              Text(
                languages.dugnadStoCardButton,
                style: aeCaption(color: labelColor)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 11.5)
                    .dp(context),
              ),
              if (stoRating != null) ...[
                SizedBox(width: context.dp(5)),
                Container(
                  constraints: const BoxConstraints(minWidth: 21),
                  padding: EdgeInsets.symmetric(horizontal: context.dp(5)),
                  height: context.dp(17),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ScSaasThemeTokens.text.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$stoRating',
                    style: aeCaption(color: labelColor)
                        .copyWith(fontWeight: FontWeight.w900, fontSize: 12)
                        .dp(context),
                  ),
                ),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: context.dp(13),
                color: ScSaasThemeTokens.gray500.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
