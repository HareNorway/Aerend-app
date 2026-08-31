import '../../utils/utils.dart';
import 'gamification_models.dart';

enum DugnadBadgeTone { purple, gold, green, silver }

class DugnadBadgeItem {
  const DugnadBadgeItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.earned,
    this.isSeasonal = false,
    this.stoBonus = 0,
    this.earnedAt,
    this.progressLabel,
    this.howTo = '',
    this.howToSteps = const [],
  });

  final String id;
  final String name;
  final String subtitle;
  final String icon;
  final DugnadBadgeTone tone;
  final bool earned;
  final bool isSeasonal;
  final int stoBonus;
  final String? earnedAt;
  final String? progressLabel;
  final String howTo;
  final List<String> howToSteps;
}

class DugnadBadgeSections {
  const DugnadBadgeSections({
    required this.permanent,
    required this.seasonal,
    this.seasonLabel,
  });

  final List<DugnadBadgeItem> permanent;
  final List<DugnadBadgeItem> seasonal;
  final String? seasonLabel;

  List<DugnadBadgeItem> get all => [...permanent, ...seasonal];
}

/// Whether the user has an active Fast støtte subscription, inferred from
/// earned permanent badges (avoids a separate points-ledger fetch on profile).
bool dugnadHasSubscriptionFromCareer(GamificationCareer? career) {
  if (career == null) return false;
  return career.permanentBadges.any((b) {
    switch (b.badgeKey) {
      case 'support':
      case 'lagspiller':
      case 'veteran':
        return true;
      default:
        return false;
    }
  });
}

class DugnadBadgeProgressContext {
  const DugnadBadgeProgressContext({
    this.referrals = 0,
    this.hasSub = false,
    this.subMonths = 0,
    this.teamRank,
    this.completedWeeklyChallenges = 0,
    this.streakWeeks = 0,
    this.metricProgress = const {},
  });

  final int referrals;
  final bool hasSub;
  final int subMonths;
  final int? teamRank;
  final int completedWeeklyChallenges;
  final int streakWeeks;
  final Map<String, BadgeMetricProgress> metricProgress;
}

Map<String, BadgeMetricProgress> dugnadMergedBadgeProgress({
  GamificationCareer? career,
  GamificationProgress? progress,
}) {
  if ((career == null || career.badgeProgress.isEmpty) &&
      (progress == null || progress.badgeProgress.isEmpty)) {
    return const {};
  }
  return {
    ...progress?.badgeProgress ?? const {},
    ...career?.badgeProgress ?? const {},
  };
}

DugnadBadgeSections buildDugnadBadgeSections({
  StoBadgeCatalog? catalog,
  List<GamificationEarnedBadge> permanentEarned = const [],
  List<GamificationEarnedBadge> seasonalEarned = const [],
  DugnadBadgeProgressContext progress = const DugnadBadgeProgressContext(),
  String? seasonLabel,
}) {
  if (catalog == null || catalog.badges.isEmpty) {
    final legacy = buildDugnadBadges(
      referrals: progress.referrals,
      subMonths: progress.subMonths,
      hasSub: progress.hasSub,
    );
    return DugnadBadgeSections(permanent: legacy, seasonal: const []);
  }

  final permEarnedMap = {
    for (final b in permanentEarned) b.badgeKey: b,
  };
  final seasEarnedMap = {
    for (final b in seasonalEarned) b.badgeKey: b,
  };

  final permanent = <DugnadBadgeItem>[];
  final seasonal = <DugnadBadgeItem>[];

  for (final def in catalog.badges) {
    final earnedRow = def.isSeasonal
        ? seasEarnedMap[def.badgeKey]
        : permEarnedMap[def.badgeKey];
    final earned = earnedRow != null;
    final item = _badgeItemFromDefinition(
      def,
      earned: earned,
      earnedAt: earnedRow?.earnedAt,
      progress: progress,
    );
    if (def.isSeasonal) {
      seasonal.add(item);
    } else {
      permanent.add(item);
    }
  }

  return DugnadBadgeSections(
    permanent: permanent,
    seasonal: seasonal,
    seasonLabel: seasonLabel,
  );
}

DugnadBadgeItem _badgeItemFromDefinition(
  StoBadgeDefinition def, {
  required bool earned,
  String? earnedAt,
  required DugnadBadgeProgressContext progress,
}) {
  final progressLabel = earned ? null : _lockedProgressLabel(def.badgeKey, progress);
  final copy = dugnadBadgeHowToCopy(def.badgeKey, def.triggerClass);

  return DugnadBadgeItem(
    id: def.badgeKey,
    name: def.name,
    subtitle: earned
        ? _earnedSubtitle(def.isSeasonal, earnedAt)
        : (progressLabel ?? _lockedSubtitle(def.badgeKey)),
    icon: dugnadBadgeIconForKey(def.badgeKey, def.icon),
    tone: dugnadBadgeToneForKey(def.badgeKey),
    earned: earned,
    isSeasonal: def.isSeasonal,
    stoBonus: def.pointBonus,
    earnedAt: earnedAt,
    progressLabel: progressLabel,
    howTo: copy.howTo,
    howToSteps: copy.steps,
  );
}

String _earnedSubtitle(bool seasonal, String? earnedAt) {
  if (seasonal) return languages.dugnadBadgeStatusActiveNow;
  final formatted = dugnadFormatBadgeEarnedDate(earnedAt);
  if (formatted != null) {
    return languages.dugnadBadgeEarnedAt(formatted);
  }
  return languages.dugnadBadgeUnlocked;
}

String dugnadBadgeUnlockSubtitle(String key) {
  switch (key) {
    case 'support':
      return languages.dugnadBadgeRegularSupporterSub;
    case 'lagspiller':
      return languages.dugnadBadgeTeamPlayerSub;
    case 'ambassador':
    case 'sesongambassador':
      return languages.dugnadBadgeAmbassadorSub;
    case 'veteran':
      return languages.dugnadBadgeVeteranSub;
    case 'hattrick':
      return languages.dugnadBadgeHatTrickSub;
    case 'assistkonge':
      return languages.dugnadBadgeAssistKingSub;
    case 'first':
      return languages.dugnadBadgeFirstSub;
    case 'oppdragsmester':
      return languages.dugnadBadgeMissionsMasterSub;
    case 'formuke':
      return languages.dugnadBadgeFormWeekSub;
    case 'sesongtopp':
      return languages.dugnadBadgeSeasonTopSub;
    case 'klubbengasjert':
      return languages.dugnadBadgeClubEngagedSub;
    case 'first_purchase':
      return languages.dugnadBadgeFirstPurchaseSub;
    case 'kampanje_hattrick':
      return languages.dugnadBadgePurchaseHattrickSub;
    case 'kampanje_10':
      return languages.dugnadBadgeTenBoxesSub;
    default:
      return languages.dugnadBadgeLockedGenericSub;
  }
}

String _lockedSubtitle(String key) => dugnadBadgeUnlockSubtitle(key);

String? _lockedProgressLabel(String key, DugnadBadgeProgressContext ctx) {
  switch (key) {
    case 'lagspiller':
      return languages.dugnadBadgeMonthsProgress(
        ctx.hasSub ? ctx.subMonths : 0,
        3,
      );
    case 'veteran':
      return languages.dugnadBadgeMonthsProgress(ctx.subMonths, 12);
    case 'ambassador':
    case 'sesongambassador':
      return languages.dugnadBadgeReferralsProgress(ctx.referrals, 5);
    case 'hattrick':
      return languages.dugnadBadgeReferralsProgress(ctx.referrals, 3);
    case 'assistkonge':
      return languages.dugnadBadgeReferralsProgress(ctx.referrals, 6);
    case 'oppdragsmester':
      return languages.dugnadBadgeWeeklyChallengesProgress(
        ctx.completedWeeklyChallenges,
        8,
      );
    case 'formuke':
      return languages.dugnadBadgeFormWeeksProgress(ctx.streakWeeks, 10);
    case 'sesongtopp':
      if (ctx.teamRank != null && ctx.teamRank! > 3) {
        final places = ctx.teamRank! - 3;
        return languages.dugnadBadgeSeasonRankProgress(ctx.teamRank!, places);
      }
      return null;
    case 'first_purchase':
    case 'kampanje_hattrick':
    case 'kampanje_10':
      {
        final snap = ctx.metricProgress[key];
        final goal = snap != null && snap.threshold > 0
            ? snap.threshold
            : (key == 'first_purchase'
                ? 1
                : key == 'kampanje_hattrick'
                    ? 3
                    : 10);
        return languages.dugnadBadgeBoxesProgress(snap?.current ?? 0, goal);
      }
    default:
      final fallback = ctx.metricProgress[key];
      if (fallback != null && fallback.threshold > 0) {
        return '${fallback.current}/${fallback.threshold}';
      }
      return null;
  }
}

/// Resolve a distinct emblem icon for a badge. Honours an explicit,
/// meaningful backend icon; otherwise derives one from the badge key so
/// badges never all fall back to the generic shield.
String dugnadBadgeIconForKey(String key, String provided) {
  final p = provided.trim().toLowerCase();
  if (p.isNotEmpty && p != 'shield' && p != 'badge') return p;

  switch (key) {
    case 'support':
      return 'heart';
    case 'lagspiller':
      return 'shield';
    case 'ambassador':
      return 'share';
    case 'sesongambassador':
      return 'shield';
    case 'veteran':
      return 'medal';
    case 'loyal':
      return 'crown';
    case 'hattrick':
      return 'zap';
    case 'assistkonge':
      return 'boot';
    case 'first':
      return 'flag';
    case 'oppdragsmester':
      return 'target';
    case 'formuke':
      return 'flame';
    case 'sesongtopp':
      return 'trophy';
    case 'klubbengasjert':
      return 'people';
    case 'first_purchase':
      return 'box';
    case 'kampanje_hattrick':
      return 'sparkle';
    case 'kampanje_10':
      return 'rocket';
    default:
      return 'star';
  }
}

DugnadBadgeTone dugnadBadgeToneForKey(String key) {
  switch (key) {
    case 'hattrick':
    case 'kampanje_hattrick':
    case 'kampanje_10':
    case 'ambassador':
    case 'sesongambassador':
    case 'sesongtopp':
    case 'loyal':
      return DugnadBadgeTone.gold;
    case 'lagspiller':
    case 'formuke':
    case 'klubbengasjert':
      return DugnadBadgeTone.green;
    case 'veteran':
      return DugnadBadgeTone.silver;
    default:
      return DugnadBadgeTone.purple;
  }
}

class DugnadBadgeHowToCopy {
  const DugnadBadgeHowToCopy({
    required this.howTo,
    this.steps = const [],
  });

  final String howTo;
  final List<String> steps;
}

DugnadBadgeHowToCopy dugnadBadgeHowToCopy(String key, String triggerClass) {
  switch (key) {
    case 'support':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowSupport,
        steps: [
          languages.dugnadBadgeHowSupportStep1,
          languages.dugnadBadgeHowSupportStep2,
          languages.dugnadBadgeHowSupportStep3,
        ],
      );
    case 'lagspiller':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowLagspiller,
        steps: [
          languages.dugnadBadgeHowLagspillerStep1,
          languages.dugnadBadgeHowLagspillerStep2,
          languages.dugnadBadgeHowLagspillerStep3,
        ],
      );
    case 'first':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowFirst,
        steps: [
          languages.dugnadBadgeHowFirstStep1,
          languages.dugnadBadgeHowFirstStep2,
          languages.dugnadBadgeHowFirstStep3,
        ],
      );
    case 'hattrick':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowHattrick,
        steps: [
          languages.dugnadBadgeHowHattrickStep1,
          languages.dugnadBadgeHowHattrickStep2,
          languages.dugnadBadgeHowHattrickStep3,
        ],
      );
    case 'veteran':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowVeteran,
        steps: [
          languages.dugnadBadgeHowVeteranStep1,
          languages.dugnadBadgeHowVeteranStep2,
          languages.dugnadBadgeHowVeteranStep3,
        ],
      );
    case 'sesongambassador':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowSeasonAmbassador,
        steps: [
          languages.dugnadBadgeHowSeasonAmbassadorStep1,
          languages.dugnadBadgeHowSeasonAmbassadorStep2,
          languages.dugnadBadgeHowSeasonAmbassadorStep3,
        ],
      );
    case 'oppdragsmester':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowMissionsMaster,
        steps: [
          languages.dugnadBadgeHowMissionsMasterStep1,
          languages.dugnadBadgeHowMissionsMasterStep2,
          languages.dugnadBadgeHowMissionsMasterStep3,
        ],
      );
    case 'klubbengasjert':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowClubEngaged,
        steps: [
          languages.dugnadBadgeHowClubEngagedStep1,
          languages.dugnadBadgeHowClubEngagedStep2,
          languages.dugnadBadgeHowClubEngagedStep3,
        ],
      );
    case 'formuke':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowFormWeek,
        steps: [
          languages.dugnadBadgeHowFormWeekStep1,
          languages.dugnadBadgeHowFormWeekStep2,
          languages.dugnadBadgeHowFormWeekStep3,
        ],
      );
    case 'sesongtopp':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowSeasonTop,
        steps: [
          languages.dugnadBadgeHowSeasonTopStep1,
          languages.dugnadBadgeHowSeasonTopStep2,
          languages.dugnadBadgeHowSeasonTopStep3,
        ],
      );
    case 'first_purchase':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowFirstPurchase,
        steps: [
          languages.dugnadBadgeHowFirstPurchaseStep1,
          languages.dugnadBadgeHowFirstPurchaseStep2,
          languages.dugnadBadgeHowFirstPurchaseStep3,
        ],
      );
    case 'kampanje_hattrick':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowPurchaseHattrick,
        steps: [
          languages.dugnadBadgeHowPurchaseHattrickStep1,
          languages.dugnadBadgeHowPurchaseHattrickStep2,
          languages.dugnadBadgeHowPurchaseHattrickStep3,
        ],
      );
    case 'kampanje_10':
      return DugnadBadgeHowToCopy(
        howTo: languages.dugnadBadgeHowTenBoxes,
        steps: [
          languages.dugnadBadgeHowTenBoxesStep1,
          languages.dugnadBadgeHowTenBoxesStep2,
          languages.dugnadBadgeHowTenBoxesStep3,
        ],
      );
    default:
      return DugnadBadgeHowToCopy(
        howTo: triggerClass == 'tenure'
            ? languages.dugnadBadgeHowTenureGeneric
            : triggerClass == 'locality'
                ? languages.dugnadBadgeHowLocalityGeneric
                : languages.dugnadBadgeHowActivityGeneric,
        steps: [
          languages.dugnadBadgeHowGenericStep1,
          languages.dugnadBadgeHowGenericStep2,
          languages.dugnadBadgeHowGenericStep3,
        ],
      );
  }
}

String? dugnadFormatBadgeEarnedDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final date = DateTime.parse(raw);
    final month = _norwegianMonthShort(date.month);
    return '$month. ${date.year}';
  } catch (_) {
    return null;
  }
}

String dugnadFormatSeasonTag(String? label) {
  if (label == null || label.trim().isEmpty) return '';
  final match = RegExp(r'(\d{2,4})\s*/\s*(\d{2})').firstMatch(label);
  if (match == null) return label.trim();
  final start = match.group(1)!;
  final end = match.group(2)!;
  final shortStart =
      start.length > 2 ? start.substring(start.length - 2) : start;
  return '$shortStart/$end';
}

String _norwegianMonthShort(int month) {
  const months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'mai',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'des',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

/// Legacy fallback when `sto_badges` config is unavailable.
List<DugnadBadgeItem> buildDugnadBadges({
  required int referrals,
  required int subMonths,
  required bool hasSub,
}) {
  return [
    DugnadBadgeItem(
      id: 'support',
      name: languages.dugnadBadgeRegularSupporter,
      subtitle: languages.dugnadBadgeRegularSupporterSub,
      icon: 'heart',
      tone: DugnadBadgeTone.purple,
      earned: hasSub,
      stoBonus: 20,
    ),
    DugnadBadgeItem(
      id: 'ambassador',
      name: languages.dugnadBadgeAmbassador,
      subtitle: referrals >= 5
          ? languages.dugnadBadgeUnlocked
          : languages.dugnadBadgeReferProgress(referrals),
      icon: 'share',
      tone: DugnadBadgeTone.gold,
      earned: referrals >= 5,
      stoBonus: 30,
    ),
    DugnadBadgeItem(
      id: 'lagspiller',
      name: languages.dugnadBadgeTeamPlayer,
      subtitle: languages.dugnadBadgeTeamPlayerSub,
      icon: 'shield',
      tone: DugnadBadgeTone.green,
      earned: hasSub && subMonths >= 3,
      stoBonus: 20,
    ),
    DugnadBadgeItem(
      id: 'veteran',
      name: languages.dugnadBadgeVeteran,
      subtitle: subMonths >= 12
          ? languages.dugnadBadgeUnlocked
          : languages.dugnadBadgeVeteranProgress(subMonths),
      icon: 'star',
      tone: DugnadBadgeTone.silver,
      earned: subMonths >= 12,
      stoBonus: 40,
    ),
    DugnadBadgeItem(
      id: 'hattrick',
      name: languages.dugnadBadgeHatTrick,
      subtitle: referrals >= 3
          ? languages.dugnadBadgeUnlocked
          : languages.dugnadBadgeHatTrickSub,
      icon: 'zap',
      tone: DugnadBadgeTone.gold,
      earned: referrals >= 3,
      stoBonus: 20,
    ),
    DugnadBadgeItem(
      id: 'assistkonge',
      name: languages.dugnadBadgeAssistKing,
      subtitle: referrals > 5
          ? languages.dugnadBadgeUnlocked
          : languages.dugnadBadgeAssistProgress(referrals.clamp(0, 6)),
      icon: 'share',
      tone: DugnadBadgeTone.gold,
      earned: referrals > 5,
      stoBonus: 30,
    ),
  ];
}
