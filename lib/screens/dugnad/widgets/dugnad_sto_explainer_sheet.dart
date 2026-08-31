import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';

import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../donation_setup_screen.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_form_utils.dart';
import '../dugnad_formen_screen.dart';
import '../dugnad_models.dart';
import '../dugnad_points_widgets.dart';
import '../dugnad_sheet.dart';
import '../dugnad_sto_source_breakdown.dart';
import '../dugnad_sto_utils.dart';
import '../gamification_models.dart';
import '../kampanje_screen.dart';
import '../points_metal_theme.dart';
import '../referral_share_screen.dart';
import 'dugnad_metal_animations.dart';
import 'dugnad_subpage_shell.dart';

/// Bottom sheet that explains how the STØ rating is calculated.
///
/// Mirrors prototype `PcStatsSheet`: fixed `.dg-csheet-top` header, scrollable
/// `.dg-csheet-list` body with rating hero, source breakdown, tempo/season
/// notes, carryover, and boost actions.
class DugnadStoExplainerSheet extends StatelessWidget {
  const DugnadStoExplainerSheet({
    super.key,
    required this.rootContext,
    required this.summary,
    required this.breakdown,
    required this.earnedBadgeCount,
    this.config,
  });

  final BuildContext rootContext;
  final PointsSummary summary;
  final StoSourcePoints breakdown;
  final int earnedBadgeCount;
  final GamificationConfig? config;

  static Future<void> show(
    BuildContext context, {
    required PointsSummary summary,
    required StoSourcePoints breakdown,
    required int earnedBadgeCount,
    GamificationConfig? config,
  }) {
    // `.dg-csheet { background: var(--ae-lavender) }` — club lavender, not white.
    final sheetBg = context.dugnadTheme.background;
    return showDugnadSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      builder: (sheetContext) => DugnadStoExplainerSheet(
        rootContext: context,
        summary: summary,
        breakdown: breakdown,
        earnedBadgeCount: earnedBadgeCount,
        config: config,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetBg = context.dugnadTheme.background;
    final radius = context.dp(kDugnadSheetRadius);
    return DugnadFixedTypography(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        child: ColoredBox(
          color: sheetBg,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.92,
            child: Column(
              children: [
                // `.dg-csheet-top` — opaque so scroll content never shows through.
                _SheetHeader(
                  background: sheetBg,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(18),
                      context.dp(6),
                      context.dp(18),
                      context.dp(22) + bottomInset,
                    ),
                    children: _content(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final tiers = summary.metalTiers.isNotEmpty
        ? summary.metalTiers
        : [if (summary.currentTier != null) summary.currentTier!];
    final points = summary.lifetimePoints;

    var currentIdx = 0;
    for (var i = 0; i < tiers.length; i++) {
      if (points >= tiers[i].minPoints) currentIdx = i;
    }
    final displayTier =
        tiers.isNotEmpty ? tiers[currentIdx] : summary.currentTier;
    final nextTier =
        currentIdx + 1 < tiers.length ? tiers[currentIdx + 1] : null;
    final metal = displayTier?.metal ?? 'bronse';
    final stoTiers = config?.stoTierThresholds ?? const [];

    var progress = 100;
    var pointsToNext = 0;
    if (nextTier != null && displayTier != null) {
      final span = nextTier.minPoints - displayTier.minPoints;
      progress = span > 0
          ? (((points - displayTier.minPoints) / span) * 100).round()
          : 0;
      pointsToNext = max(0, nextTier.minPoints - points);
    }

    return [
      _HeaderCard(
        stoRating: summary.stoRating,
        tierName: _tierName(displayTier),
        metal: metal,
        progressPercent: progress.clamp(0, 100),
        pointsToNext: nextTier == null ? null : pointsToNext,
        nextTierName: nextTier == null ? null : _tierName(nextTier),
        nextSto: nextTier == null
            ? null
            : dugnadStoRatingAtNextMetalTier(
                nextTier: nextTier,
                config: config,
              ),
      ),
      SizedBox(height: context.dp(17)),
      DugnadStoSourceBreakdown(
        breakdown: breakdown,
        stoRating: summary.stoRating,
        earnedBadgeCount: earnedBadgeCount,
      ),
      SizedBox(height: context.dp(8)),
      const _TempoNote(),
      SizedBox(height: context.dp(8)),
      const _SeasonFarmNote(),
      if (_hasCarryover) ...[
        SizedBox(height: context.dp(17)),
        _CarryoverSection(
          currentMetal: metal,
          stoTiers: stoTiers,
          config: config!,
        ),
      ],
      SizedBox(height: context.dp(17)),
      _BoostSection(onOpen: _open),
    ];
  }

  bool get _hasCarryover {
    return config?.metalCarryover.isNotEmpty ?? false;
  }

  String _tierName(MetalTierInfo? tier) {
    if (tier == null) return '';
    final suffix = tier.titleSuffix.trim();
    if (suffix.isNotEmpty) return suffix;
    return dugnadTierDisplayName(tier, config: config);
  }

  void _open(Widget screen) {
    Navigator.of(rootContext).pop();
    openScreen(rootContext, screen);
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose, required this.background});

  final VoidCallback onClose;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return ColoredBox(
      color: background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.dp(18), context.dp(10), context.dp(18), context.dp(14)),
        child: Column(
          children: [
            // `.dg-msheet-grab` — 40×5 gray pill.
            const DugnadSheetHandle(bottom: 12),
            Row(
              children: [
                Expanded(
                  // `.dg-csheet-top .hd h2` — 20px / 800 / club midnight.
                  child: Text(
                    languages.dugnadStoExplainerTitle,
                    style: aeH2(color: theme.text).copyWith(
                      fontSize: context.dp(20),
                      letterSpacing: context.dp(20) * -0.02,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: context.dp(34),
                    height: context.dp(34),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: theme.text.withValues(alpha: 0.12),
                          blurRadius: context.dp(3),
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: context.dp(18),
                      color: theme.text,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.stoRating,
    required this.tierName,
    required this.metal,
    required this.progressPercent,
    this.pointsToNext,
    this.nextTierName,
    this.nextSto,
  });

  final int stoRating;
  final String tierName;
  final String metal;
  final int progressPercent;
  final int? pointsToNext;
  final String? nextTierName;
  final int? nextSto;

  @override
  Widget build(BuildContext context) {
    // `.pc-rating-hero.metal-*` — Family B pale 150° ramp (not Family A hero).
    final gradient = PointsMetalTheme.cardGradientForMetal(metal);
    final ink = _pcRatingHeroInk(metal);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: PointsMetalTheme.colorForMetal(metal).withValues(alpha: 0.45),
            blurRadius: context.dp(30),
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        // CSS `linear-gradient(150deg, …)`.
                        begin: const Alignment(-0.35, -1),
                        end: const Alignment(0.35, 1),
                        colors: gradient,
                      ),
                    ),
                  ),
                  const DugnadMetalAmbientGlaze(borderRadius: 18),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(17), context.dp(16), context.dp(17), context.dp(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Design: flex-end align rating + "STØ · tier".
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$stoRating',
                        style: aeH2(color: ink).copyWith(
                          fontSize: 44,
                          height: 0.85,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.03 * 44,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: context.dp(5)),
                          child: Text(
                            '$dugnadStoRatingLabel · $tierName',
                            style: aeCaption(color: ink).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: ink.withValues(alpha: 0.72),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pointsToNext != null && nextTierName != null) ...[
                    SizedBox(height: context.dp(14)),
                    DugnadAnimatedMetalProgressBar(
                      metal: metal,
                      progressPercent: progressPercent,
                      height: context.dp(8),
                    ),
                    SizedBox(height: context.dp(9)),
                    // Design: <b style={{ fontSize: 15.5 }}>{toNext} poeng</b> til …
                    Text.rich(
                      TextSpan(
                        style: aeCaption(color: ink).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 13 * -0.01,
                          color: ink.withValues(alpha: 0.92),
                        ),
                        children: [
                          TextSpan(
                            text: '$pointsToNext ${languages.dugnadPointsUnit}',
                            style: TextStyle(
                              fontSize: context.dp(15.5),
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                          TextSpan(text: ' til $nextTierName'),
                          if (nextSto != null)
                            TextSpan(
                              text: ' ($nextSto $dugnadStoRatingLabel)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ink.withValues(alpha: 0.72),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: context.dp(11)),
                    Text(
                      languages.dugnadHighestTierReached,
                      style: aeCaption(color: ink).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: ink.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // `.pc-rating-hero::after` sheen.
            const Positioned.fill(
              child: DugnadMetalGlazeOverlay(
                borderRadius: 18,
                phase: 0.22,
                overContent: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.pc-rating-hero.metal-* { color: … }` from dugnad.css.
Color _pcRatingHeroInk(String metal) {
  switch (metal) {
    case 'solv':
      return const Color(0xFF3F4A57);
    case 'gull':
      return const Color(0xFF6A4C0E);
    case 'platina':
      return const Color(0xFF3D4B70);
    case 'bronse':
    default:
      return const Color(0xFF4A2C12);
  }
}

class _TempoNote extends StatelessWidget {
  const _TempoNote();

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(12), context.dp(10), context.dp(12), context.dp(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(context.dp(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DugnadFormArrow(
            status: DugnadFormStatus.up,
            size: context.dp(15),
            chip: true,
            showLabel: false,
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: aeCaption(color: const Color(0xFF5A5470)).copyWith(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '${languages.dugnadStoTempoTitle}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  TextSpan(text: languages.dugnadStoTempoNote),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonFarmNote extends StatelessWidget {
  const _SeasonFarmNote();

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(12), context.dp(10), context.dp(12), context.dp(10)),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(
              Icons.autorenew_rounded,
              size: context.dp(14),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(width: context.dp(7)),
          Expanded(
            child: Builder(
              builder: (context) {
                final note = languages.dugnadStoSeasonFarmNote;
                final emphasis = languages.dugnadStoSeasonFarmEmphasis;
                final base = aeCaption(color: theme.primaryHover).copyWith(
                  fontSize: 11.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                );
                final idx = note.indexOf(emphasis);
                if (idx < 0) {
                  return Text(note, style: base);
                }
                return Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(text: note.substring(0, idx)),
                      TextSpan(
                        text: emphasis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: note.substring(idx + emphasis.length)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarryoverSection extends StatelessWidget {
  const _CarryoverSection({
    required this.currentMetal,
    required this.stoTiers,
    required this.config,
  });

  final String currentMetal;
  final List<StoTierThreshold> stoTiers;
  final GamificationConfig config;

  /// Flat carryover points for a metal (fixed model). 0 if absent from config.
  int _pointsFor(String metal) {
    return dugnadMetalCarryoverPointsForTier(metal, config) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final currentIdx = dugnadMetalOrder.indexOf(currentMetal);
    final nextMetal = currentIdx >= 0 && currentIdx + 1 < dugnadMetalOrder.length
        ? dugnadMetalOrder[currentIdx + 1]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), 0, context.dp(2), context.dp(4)),
          child: Text(
            languages.dugnadCarryoverPerLevelTitle.toUpperCase(),
            style: AeDugnadText.sectionLabel(),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), 0, context.dp(2), context.dp(10)),
          child: Text(
            languages.dugnadCarryoverPerLevelSubPoints,
            style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        for (var i = 0; i < dugnadMetalOrder.length; i++) ...[
          if (i > 0) SizedBox(height: context.dp(7)),
          _CarryoverRow(
            metal: dugnadMetalOrder[i],
            label: dugnadMetalDisplayLabel(dugnadMetalOrder[i]),
            points: _pointsFor(dugnadMetalOrder[i]),
            isCurrent: dugnadMetalOrder[i] == currentMetal,
          ),
        ],
        SizedBox(height: context.dp(9)),
        // Design highlight: purple-600 / club primary, 12 radius, star + 12px copy.
        Container(
          padding: EdgeInsets.fromLTRB(
            context.dp(12),
            context.dp(10),
            context.dp(12),
            context.dp(10),
          ),
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(context.dp(12)),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.6),
                blurRadius: context.dp(16),
                offset: Offset(0, context.dp(6)),
                spreadRadius: context.dp(-9),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: context.dp(14),
                color: Colors.white,
              ),
              SizedBox(width: context.dp(8)),
              Expanded(
                child: Text(
                  nextMetal == null
                      ? languages.dugnadCarryoverMaxLine(
                          dugnadMetalDisplayLabel(currentMetal),
                        )
                      : languages.dugnadCarryoverHighlightPoints(
                          dugnadMetalDisplayLabel(nextMetal),
                          dugnadTierStoRatingForMetal(nextMetal, stoTiers),
                          _pointsFor(nextMetal),
                        ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.dp(12),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Prototype `METAL_ACCENT` for carryover rows (PcStatsSheet).
class _CarryoverMetalAccent {
  const _CarryoverMetalAccent({
    required this.bg,
    required this.tx,
    required this.dot,
  });

  final Color bg;
  final Color tx;
  final Color dot;

  static _CarryoverMetalAccent forMetal(String metal) {
    switch (metal) {
      case 'solv':
        return const _CarryoverMetalAccent(
          bg: Color(0xFFEEF1F5),
          tx: Color(0xFF3F4A57),
          dot: Color(0xFF8995A3),
        );
      case 'gull':
        return const _CarryoverMetalAccent(
          bg: Color(0xFFFBF1D8),
          tx: Color(0xFF7A5A12),
          dot: Color(0xFFC2871C),
        );
      case 'platina':
        return const _CarryoverMetalAccent(
          bg: Color(0xFFEEF2FB),
          tx: Color(0xFF38426B),
          dot: Color(0xFF8D9CC7),
        );
      case 'bronse':
      default:
        return const _CarryoverMetalAccent(
          bg: Color(0xFFF4E6D6),
          tx: Color(0xFF7A4A1F),
          dot: Color(0xFFA46321),
        );
    }
  }
}

class _CarryoverRow extends StatelessWidget {
  const _CarryoverRow({
    required this.metal,
    required this.label,
    required this.points,
    required this.isCurrent,
  });

  final String metal;
  final String label;
  final int points;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final accent = _CarryoverMetalAccent.forMetal(metal);
    final bg = isCurrent ? accent.bg : Colors.white;
    final borderColor = isCurrent ? accent.dot : const Color(0xFFEEECF5);
    final labelColor = isCurrent ? accent.tx : theme.text;
    // Design: current → metal tx; else → `--ae-purple-700` (club primaryHover).
    final pointsColor = isCurrent ? accent.tx : theme.primaryHover;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.dp(12),
        context.dp(10),
        context.dp(12),
        context.dp(10),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.dp(13)),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? null
            : [
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.04),
                  blurRadius: context.dp(2),
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(12),
            height: context.dp(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.dot,
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: context.dp(13.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(13.5) * -0.01,
                      color: labelColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent) ...[
                  SizedBox(width: context.dp(7)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dp(7),
                      vertical: context.dp(2),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      languages.dugnadCarryoverYourLevelTag,
                      style: TextStyle(
                        fontSize: context.dp(10.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(10.5) * 0.05,
                        color: accent.tx,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.dp(8)),
          // `inline-flex; align-items: baseline; gap: 3` — number then "poeng".
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: context.dp(14),
                fontWeight: FontWeight.w900,
                color: pointsColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                TextSpan(text: '$points'),
                TextSpan(
                  text: ' ${languages.dugnadPointsUnit}',
                  style: TextStyle(
                    fontSize: context.dp(10.5),
                    fontWeight: FontWeight.w800,
                    color: pointsColor.withValues(alpha: 0.62),
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

class _BoostSection extends StatelessWidget {
  const _BoostSection({required this.onOpen});

  final void Function(Widget screen) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(10)),
          child: Text(
            languages.dugnadStoIncreaseTitle.toUpperCase(),
            style: AeDugnadText.sectionLabel(),
          ),
        ),
        DugnadEarnPointsRow(
          icon: Icons.share_rounded,
          title: languages.dugnadStoBoostReferTitle,
          subtitle: languages.dugnadStoBoostReferSub,
          points: 100,
          strong: true,
          onTap: () => onOpen(const ReferralShareScreen()),
        ),
        DugnadEarnPointsRow(
          icon: Icons.inventory_2_outlined,
          title: languages.dugnadStoBoostCampaignTitle,
          subtitle: languages.dugnadStoBoostCampaignSub,
          points: 50,
          strong: true,
          onTap: () => onOpen(const KampanjeScreen()),
        ),
        DugnadEarnPointsRow(
          icon: Icons.favorite_rounded,
          title: languages.dugnadStoBoostMembershipTitle,
          subtitle: languages.dugnadStoBoostMembershipSub,
          points: 20,
          strong: true,
          onTap: () => onOpen(const DonationSetupScreen()),
        ),
        _FormBoostRow(onTap: () => onOpen(const DugnadFormenScreen())),
      ],
    );
  }
}

class _FormBoostRow extends StatelessWidget {
  const _FormBoostRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.dp(14), vertical: context.dp(13)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(16)),
          boxShadow: [
            BoxShadow(
              color: theme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(10),
              offset: const Offset(0, 3),
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
                gradient: theme.shinyGradient,
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: context.dp(18),
                color: Colors.white,
              ),
            ),
            SizedBox(width: context.dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadStoBoostFormTitle,
                    style: aeBody().copyWith(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(languages.dugnadStoBoostFormSub, style: aeCaption()),
                ],
              ),
            ),
            DugnadFormArrow(
              status: DugnadFormStatus.up,
              size: context.dp(13),
              chip: true,
              showLabel: false,
            ),
          ],
        ),
      ),
    );
  }
}
