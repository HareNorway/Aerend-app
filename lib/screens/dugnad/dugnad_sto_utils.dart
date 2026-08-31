import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import 'dugnad_models.dart';
import 'gamification_models.dart';
import 'points_metal_theme.dart';

const dugnadMetalOrder = ['bronse', 'solv', 'gull', 'platina'];

/// Product label for STØ ratings — always «STØ», never translated to SUP.
const dugnadStoRatingLabel = 'STØ';

String dugnadMetalDisplayLabel(String metal) {
  switch (metal) {
    case 'solv':
      return languages.dugnadDonationTierSilver;
    case 'gull':
      return languages.dugnadDonationTierGold;
    case 'platina':
      return languages.dugnadDonationTierPlatinum;
    case 'bronse':
    default:
      return languages.dugnadDonationTierBronze;
  }
}

/// Register admin-configured metal colours so every card visual can use them.
///
/// Merges colours from the points summary tiers (per-user) with the admin
/// `sto_tier_thresholds` colours from config, both keyed by metal/tier_key.
void dugnadApplyMetalColorOverrides({
  GamificationConfig? config,
  PointsSummary? summary,
}) {
  final map = <String, String>{};
  if (config != null) {
    config.metalColorMap().forEach((key, hex) {
      map[key.toLowerCase()] = hex;
    });
  }
  if (summary != null) {
    for (final tier in summary.metalTiers) {
      final metal = tier.metal.trim().toLowerCase();
      final hex = tier.colorHex.trim();
      if (metal.isNotEmpty && hex.isNotEmpty) {
        map[metal] = hex;
      }
    }
  }
  PointsMetalTheme.applyColorOverrides(map);
}

/// Display name for a metal tier: club alias → backend label → metal label.
String dugnadTierDisplayName(
  MetalTierInfo tier, {
  GamificationConfig? config,
}) {
  final alias = config?.clubTierAliases[tier.metal]?.trim() ?? '';
  if (alias.isNotEmpty) return alias;
  if (tier.labelNo.trim().isNotEmpty) return tier.labelNo.trim();
  return dugnadMetalDisplayLabel(tier.metal);
}

/// Metal tier from STØ rating using admin `sto_tier_thresholds` when available.
String? dugnadMetalForRatingFromConfig(
  int rating,
  List<StoTierThreshold> tiers,
) {
  for (final tier in tiers) {
    if (rating >= tier.ratingMin && rating <= tier.ratingMax) {
      return tier.tierKey;
    }
  }
  return null;
}

/// Legacy fallback when config tiers are missing (prototype defaults).
String dugnadMetalForRating(int rating) {
  if (rating >= 99) return 'platina';
  if (rating >= 93) return 'gull';
  if (rating >= 84) return 'solv';
  return 'bronse';
}

/// Prototype `DG_STO_CHIP` colours for snitt-STØ / list chips.
///
/// Resolves metal from [rating], then uses [PointsMetalTheme.stoChipColors]
/// so admin-configured metal hexes tint every STØ chip.
({Color bg, Color fg}) dugnadStoChipColors(int rating) {
  return PointsMetalTheme.stoChipColors(dugnadMetalForRating(rating));
}

List<String> dugnadOrderedMetalKeys(List<StoTierThreshold> tiers) {
  if (tiers.isEmpty) return dugnadMetalOrder;
  final sorted = List<StoTierThreshold>.from(tiers)
    ..sort((a, b) => a.ratingMin.compareTo(b.ratingMin));
  return sorted.map((t) => t.tierKey).where((k) => k.isNotEmpty).toList();
}

int? dugnadMinRatingForMetalFromConfig(
  String metal,
  List<StoTierThreshold> tiers,
) {
  for (final tier in tiers) {
    if (tier.tierKey == metal) return tier.ratingMin;
  }
  return null;
}

int dugnadMinRatingForMetal(String metal) {
  switch (metal) {
    case 'platina':
      return 99;
    case 'gull':
      return 93;
    case 'solv':
      return 84;
    default:
      return 40;
  }
}

/// STØ on hero / pillar / active ladder step — actual rating unless previewing.
int dugnadDisplayStoRating({
  required bool isPreviewing,
  required int actualStoRating,
  required String metal,
  List<StoTierThreshold> tiers = const [],
}) {
  if (!isPreviewing) return actualStoRating;
  return dugnadTierStoRatingForMetal(metal, tiers);
}

/// STØ label on a ladder step — active step shows actual rating when not previewing.
int dugnadLadderStepStoRating({
  required bool isOn,
  required bool isPreviewing,
  required int actualStoRating,
  required String metal,
  List<StoTierThreshold> tiers = const [],
}) {
  if (isOn && !isPreviewing) return actualStoRating;
  return dugnadTierStoRatingForMetal(metal, tiers);
}

/// STØ rating shown for a metal tier on level cards (prototype: DG_STO_RATING).
int dugnadTierStoRatingForMetal(
  String metal, [
  List<StoTierThreshold> tiers = const [],
]) {
  final fromConfig = dugnadMinRatingForMetalFromConfig(metal, tiers);
  if (fromConfig != null) return fromConfig;
  switch (metal) {
    case 'platina':
      return 99;
    case 'gull':
      return 93;
    case 'solv':
      return 84;
    case 'bronse':
      return 74;
    default:
      return 84;
  }
}

String? dugnadMetalLabelFromTiers(List<MetalTierInfo> tiers, String metal) {
  for (final tier in tiers) {
    if (tier.metal == metal && tier.labelNo.trim().isNotEmpty) {
      return tier.labelNo.trim();
    }
  }
  return null;
}

class DugnadCarryoverPreview {
  final String? metal;
  final int appliedPoints;
  final int currentPercent;
  final SeasonCarryoverTier? nextTier;
  final int? nextTierPoints;
  final int? nextTierMinRating;

  const DugnadCarryoverPreview({
    this.metal,
    required this.appliedPoints,
    this.currentPercent = 0,
    this.nextTier,
    this.nextTierPoints,
    this.nextTierMinRating,
  });

  bool get atMax => nextTier == null;
}

SeasonCarryoverTier? dugnadSeasonCarryoverTierForRating(
  int stoRating,
  List<SeasonCarryoverTier> tiers,
) {
  for (final tier in tiers) {
    if (stoRating >= tier.ratingMin && stoRating <= tier.ratingMax) {
      return tier;
    }
  }
  return null;
}

List<SeasonCarryoverTier> _sortedSeasonCarryoverTiers(
  List<SeasonCarryoverTier> tiers,
) {
  return List<SeasonCarryoverTier>.from(tiers)
    ..sort((a, b) => a.ratingMin.compareTo(b.ratingMin));
}

/// Mirrors admin Sesong-carryover simulator: percent of season points, capped.
int dugnadSeasonCarryoverPoints({
  required int stoRating,
  required int seasonPoints,
  required SeasonCarryoverSettings settings,
}) {
  if (!settings.enabled || seasonPoints <= 0 || settings.tiers.isEmpty) {
    return 0;
  }

  final tier = dugnadSeasonCarryoverTierForRating(stoRating, settings.tiers);
  if (tier == null || tier.carryoverPercent <= 0) return 0;

  final raw = (seasonPoints * tier.carryoverPercent / 100).round();
  final cap = settings.absoluteCapPoints;
  if (cap <= 0) return raw;
  return raw < cap ? raw : cap;
}

/// Carryover preview from sesong-carryover config + live points summary.
DugnadCarryoverPreview dugnadCarryoverPreview({
  required int stoRating,
  required int seasonPoints,
  required GamificationConfig config,
}) {
  final settings = config.seasonCarryover;
  if (settings == null || !settings.enabled) {
    return const DugnadCarryoverPreview(appliedPoints: 0);
  }

  final sorted = _sortedSeasonCarryoverTiers(settings.tiers);
  final current = dugnadSeasonCarryoverTierForRating(stoRating, sorted);
  final metal = dugnadMetalForRatingFromConfig(stoRating, config.stoTierThresholds) ??
      dugnadMetalForRating(stoRating);
  final applied = dugnadSeasonCarryoverPoints(
    stoRating: stoRating,
    seasonPoints: seasonPoints,
    settings: settings,
  );

  SeasonCarryoverTier? nextTier;
  if (current != null) {
    final index = sorted.indexWhere(
      (tier) =>
          tier.ratingMin == current.ratingMin &&
          tier.ratingMax == current.ratingMax,
    );
    if (index >= 0 && index < sorted.length - 1) {
      nextTier = sorted[index + 1];
    }
  }

  return DugnadCarryoverPreview(
    metal: metal,
    appliedPoints: applied,
    currentPercent: current?.carryoverPercent ?? 0,
    nextTier: nextTier,
    nextTierPoints: nextTier == null
        ? null
        : dugnadSeasonCarryoverPoints(
            stoRating: nextTier.ratingMin,
            seasonPoints: seasonPoints,
            settings: settings,
          ),
    nextTierMinRating: nextTier?.ratingMin,
  );
}

// ── Fixed per-metal carryover (canonical model) ─────────────────────────────
// The rollover job awards a FLAT carryover by final metal tier (backend
// SeasonRolloverService::carryoverPointsForTier → metal_carryover_config), NOT
// the percent-of-season-points model above. These helpers mirror the backend so
// the UI shows the number that actually lands in the ledger. The percent helpers
// above are kept (still served by the config API) but no longer drive display.

/// Flat carryover points for a metal tier from config (`metal_carryover`).
/// Returns null when the tier isn't present — callers must HIDE the number,
/// never fall back to the percent model and never show 0.
int? dugnadMetalCarryoverPointsForTier(
  String metalKey,
  GamificationConfig config,
) {
  for (final entry in config.metalCarryover) {
    if (entry.tierKey == metalKey) return entry.carryoverPoints;
  }
  return null;
}

class DugnadMetalCarryover {
  final String? metal;
  final int? appliedPoints;
  final String? nextMetal;
  final int? nextMetalPoints;

  const DugnadMetalCarryover({
    this.metal,
    this.appliedPoints,
    this.nextMetal,
    this.nextMetalPoints,
  });

  /// True only when there is a real, positive carryover to show.
  bool get hasValue => appliedPoints != null && appliedPoints! > 0;
  bool get atMax => nextMetal == null;
}

/// Fixed per-metal carryover preview. Resolves the metal tier the same way the
/// backend does (config STØ thresholds → metal, existing helpers) and looks up
/// the flat carryover for the current + next metal. Returns an empty preview
/// (appliedPoints null → hidden) when `metal_carryover` is missing/empty.
DugnadMetalCarryover dugnadMetalCarryoverPreview({
  required int stoRating,
  required GamificationConfig config,
}) {
  if (config.metalCarryover.isEmpty) {
    return const DugnadMetalCarryover();
  }
  final metal =
      dugnadMetalForRatingFromConfig(stoRating, config.stoTierThresholds) ??
          dugnadMetalForRating(stoRating);
  final applied = dugnadMetalCarryoverPointsForTier(metal, config);

  final order = dugnadOrderedMetalKeys(config.stoTierThresholds);
  String? nextMetal;
  int? nextPoints;
  final idx = order.indexOf(metal);
  if (idx >= 0 && idx < order.length - 1) {
    nextMetal = order[idx + 1];
    nextPoints = dugnadMetalCarryoverPointsForTier(nextMetal, config);
  }

  return DugnadMetalCarryover(
    metal: metal,
    appliedPoints: applied,
    nextMetal: nextMetal,
    nextMetalPoints: nextPoints,
  );
}

/// Interpolate base STØ rating from lifetime points (mirrors PointsEngine curve).
int dugnadStoRatingAtPoints(
  int lifetimePoints,
  List<StoRatingThreshold> thresholds,
) {
  if (thresholds.isEmpty) return 40;

  final sorted = List<StoRatingThreshold>.from(thresholds)
    ..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));

  if (lifetimePoints <= 0) {
    return sorted.first.ratingValue;
  }

  var lowerPoints = 0;
  var lowerRating = sorted.first.ratingValue.toDouble();

  for (final row in sorted) {
    if (row.pointsRequired == 0) continue;
    if (lifetimePoints < row.pointsRequired) {
      final span = row.pointsRequired - lowerPoints;
      if (span <= 0) return row.ratingValue;
      final progress = (lifetimePoints - lowerPoints) / span;
      return (lowerRating + progress * (row.ratingValue - lowerRating)).round();
    }
    lowerPoints = row.pointsRequired;
    lowerRating = row.ratingValue.toDouble();
  }

  return lowerRating.round().clamp(40, 99);
}

/// STØ at the next metal league's point threshold — the number in
/// «X poeng til Y (N STØ)» on home, points, and the STØ explainer.
int? dugnadStoRatingAtNextMetalTier({
  required MetalTierInfo nextTier,
  GamificationConfig? config,
}) {
  final thresholds = config?.stoRatingThresholds ?? const [];
  if (thresholds.isEmpty) return null;
  return dugnadStoRatingAtPoints(nextTier.minPoints, thresholds);
}
