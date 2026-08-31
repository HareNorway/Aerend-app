// Gamification config + progress models (Chunk E).

import 'celebration_models.dart';

class MetalCarryoverEntry {
  final String tierKey;
  final int carryoverPoints;

  const MetalCarryoverEntry({
    required this.tierKey,
    this.carryoverPoints = 0,
  });

  factory MetalCarryoverEntry.fromJson(Map<String, dynamic> json) {
    return MetalCarryoverEntry(
      tierKey: json['tier_key']?.toString() ?? '',
      carryoverPoints: (json['carryover_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoRatingThreshold {
  final int pointsRequired;
  final int ratingValue;

  const StoRatingThreshold({
    required this.pointsRequired,
    required this.ratingValue,
  });

  factory StoRatingThreshold.fromJson(Map<String, dynamic> json) {
    return StoRatingThreshold(
      pointsRequired: (json['points_required'] as num?)?.toInt() ?? 0,
      ratingValue: (json['rating_value'] as num?)?.toInt() ?? 40,
    );
  }
}

class StoTierThreshold {
  final String tierKey;
  final int ratingMin;
  final int ratingMax;
  final String label;
  final String colorHex;

  const StoTierThreshold({
    required this.tierKey,
    required this.ratingMin,
    required this.ratingMax,
    this.label = '',
    this.colorHex = '',
  });

  factory StoTierThreshold.fromJson(Map<String, dynamic> json) {
    return StoTierThreshold(
      tierKey: json['tier_key']?.toString() ?? '',
      ratingMin: (json['rating_min'] as num?)?.toInt() ?? 0,
      ratingMax: (json['rating_max'] as num?)?.toInt() ?? 99,
      label: json['label']?.toString() ?? '',
      colorHex: json['color_hex']?.toString() ?? '',
    );
  }
}

class GamificationConfig {
  final String configVersion;
  final Map<String, bool> features;
  final GamificationModules? modules;
  final List<MetalCarryoverEntry> metalCarryover;
  final List<StoRatingThreshold> stoRatingThresholds;
  final List<StoTierThreshold> stoTierThresholds;
  final SeasonCarryoverSettings? seasonCarryover;
  final MembershipPointsConfig? membershipPoints;
  final StoBadgeCatalog? stoBadges;

  /// Club-specific tier display names, keyed by tier_key (e.g. `gull`).
  final Map<String, String> clubTierAliases;

  /// Member shop flag from `GET dugnad/config` → `club_shop`.
  final ClubShopConfig? clubShop;

  final CelebrationConfig celebrationConfig;

  const GamificationConfig({
    required this.configVersion,
    this.features = const {},
    this.modules,
    this.metalCarryover = const [],
    this.stoRatingThresholds = const [],
    this.stoTierThresholds = const [],
    this.seasonCarryover,
    this.membershipPoints,
    this.stoBadges,
    this.clubTierAliases = const {},
    this.clubShop,
    this.celebrationConfig = const CelebrationConfig(),
  });

  factory GamificationConfig.fromJson(Map<String, dynamic> json) {
    final featureList = json['gamification_features'] as List? ?? [];
    final flags = <String, bool>{};
    for (final row in featureList) {
      if (row is Map) {
        final key = row['feature_key']?.toString();
        if (key != null) {
          flags[key] = row['enabled'] == true;
        }
      }
    }

    final modulesRaw = json['gamification_modules'];
    final carryoverRaw = json['carryover'];
    final aliasesRaw = json['club_tier_aliases'];
    final aliases = <String, String>{};
    if (aliasesRaw is Map) {
      aliasesRaw.forEach((key, value) {
        final k = key?.toString().trim() ?? '';
        final v = value?.toString().trim() ?? '';
        if (k.isNotEmpty && v.isNotEmpty) {
          aliases[k] = v;
        }
      });
    }
    return GamificationConfig(
      configVersion: json['config_version']?.toString() ?? '',
      features: flags,
      modules: modulesRaw is Map
          ? GamificationModules.fromJson(Map<String, dynamic>.from(modulesRaw))
          : null,
      metalCarryover: (json['metal_carryover'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MetalCarryoverEntry.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      stoRatingThresholds: (json['sto_rating_thresholds'] as List? ?? [])
          .whereType<Map>()
          .map((e) => StoRatingThreshold.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      stoTierThresholds: (json['sto_tier_thresholds'] as List? ?? [])
          .whereType<Map>()
          .map((e) => StoTierThreshold.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      seasonCarryover: carryoverRaw is Map
          ? SeasonCarryoverSettings.fromJson(
              Map<String, dynamic>.from(carryoverRaw),
            )
          : null,
      membershipPoints: json['membership_points'] is Map
          ? MembershipPointsConfig.fromJson(
              Map<String, dynamic>.from(json['membership_points'] as Map),
            )
          : null,
      stoBadges: json['sto_badges'] is Map
          ? StoBadgeCatalog.fromJson(
              Map<String, dynamic>.from(json['sto_badges'] as Map),
            )
          : null,
      clubTierAliases: aliases,
      clubShop: json['club_shop'] is Map
          ? ClubShopConfig.fromJson(
              Map<String, dynamic>.from(json['club_shop'] as Map),
            )
          : null,
      celebrationConfig: CelebrationConfig.fromJson(
        json['celebration_config'] is Map
            ? Map<String, dynamic>.from(json['celebration_config'] as Map)
            : null,
      ),
    );
  }

  /// Home Klubbshop card + Shop tab: enabled and a visible collection.
  bool get showClubShopEntry => clubShop?.showEntry == true;

  bool isEnabled(String key) => features[key] ?? false;

  /// Resolved colour hex for a metal tier from admin config, or '' if unset.
  String colorHexForMetal(String metal) {
    for (final tier in stoTierThresholds) {
      if (tier.tierKey == metal && tier.colorHex.trim().isNotEmpty) {
        return tier.colorHex.trim();
      }
    }
    return '';
  }

  /// Map of metal (tier_key) => colour hex for all configured tiers.
  Map<String, String> metalColorMap() {
    final map = <String, String>{};
    for (final tier in stoTierThresholds) {
      if (tier.tierKey.trim().isNotEmpty && tier.colorHex.trim().isNotEmpty) {
        map[tier.tierKey.trim()] = tier.colorHex.trim();
      }
    }
    return map;
  }

  int carryoverPointsForMetal(String metal) {
    for (final row in metalCarryover) {
      if (row.tierKey == metal) return row.carryoverPoints;
    }
    return 0;
  }
}

class ClubShopConfig {
  final bool enabled;
  final bool hasVisibleCollection;
  final bool showEntry;
  final String? _collectionName;
  final String? _partnerName;

  const ClubShopConfig({
    this.enabled = false,
    this.hasVisibleCollection = false,
    this.showEntry = false,
    String? collectionName,
    String? partnerName,
  })  : _collectionName = collectionName,
        _partnerName = partnerName;

  String get collectionName => _collectionName ?? '';
  String get partnerName => _partnerName ?? '';

  factory ClubShopConfig.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabled'] == true;
    final hasCollection = json['has_visible_collection'] == true;
    final show = json['show_entry'];
    return ClubShopConfig(
      enabled: enabled,
      hasVisibleCollection: hasCollection,
      showEntry: show is bool ? show : (enabled && hasCollection),
      collectionName: _clubShopString(json['collection_name']),
      partnerName: _clubShopString(json['partner_name']),
    );
  }
}

String? _clubShopString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

class MembershipPointsConfig {
  final bool enabled;
  final int pointsPer100Kr;
  final String roundingMode;

  const MembershipPointsConfig({
    this.enabled = false,
    this.pointsPer100Kr = 10,
    this.roundingMode = 'nearest',
  });

  factory MembershipPointsConfig.fromJson(Map<String, dynamic> json) {
    return MembershipPointsConfig(
      enabled: json['enabled'] == true,
      pointsPer100Kr: (json['points_per_100_kr'] as num?)?.toInt() ?? 10,
      roundingMode: json['rounding_mode']?.toString() ?? 'nearest',
    );
  }

  /// Typical monthly points at 100 kr/month (admin formula preview).
  int pointsPerMonthAt100Kr() => pointsPer100Kr;
}

class StoBadgeCatalog {
  final int maxTotalPointBonus;
  final String capStrategy;
  final List<StoBadgeDefinition> badges;

  const StoBadgeCatalog({
    this.maxTotalPointBonus = 150,
    this.capStrategy = 'hard',
    this.badges = const [],
  });

  factory StoBadgeCatalog.fromJson(Map<String, dynamic> json) {
    return StoBadgeCatalog(
      maxTotalPointBonus:
          (json['max_total_point_bonus'] as num?)?.toInt() ?? 150,
      capStrategy: json['cap_strategy']?.toString() ?? 'hard',
      badges: (json['badges'] as List? ?? [])
          .whereType<Map>()
          .map((e) => StoBadgeDefinition.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class StoBadgeDefinition {
  final String badgeKey;
  final String name;
  final String icon;
  final String badgeType;
  final String triggerClass;
  final int pointBonus;

  const StoBadgeDefinition({
    required this.badgeKey,
    required this.name,
    this.icon = 'shield',
    this.badgeType = 'permanent',
    this.triggerClass = 'activity',
    this.pointBonus = 0,
  });

  bool get isSeasonal => badgeType == 'seasonal';

  factory StoBadgeDefinition.fromJson(Map<String, dynamic> json) {
    return StoBadgeDefinition(
      badgeKey: json['badge_key']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_no']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'shield',
      badgeType: json['badge_type']?.toString() ?? 'permanent',
      triggerClass: json['trigger_class']?.toString() ?? 'activity',
      pointBonus: (json['point_bonus'] as num?)?.toInt() ?? 0,
    );
  }
}

class BadgeMetricProgress {
  final String metric;
  final int current;
  final int threshold;

  const BadgeMetricProgress({
    this.metric = '',
    this.current = 0,
    this.threshold = 0,
  });

  factory BadgeMetricProgress.fromJson(Map<String, dynamic> json) {
    return BadgeMetricProgress(
      metric: json['metric']?.toString() ?? '',
      current: (json['current'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, BadgeMetricProgress> parseMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, BadgeMetricProgress>{};
    raw.forEach((key, value) {
      if (value is Map) {
        out[key.toString()] = BadgeMetricProgress.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });
    return out;
  }
}

class SeasonCarryoverTier {
  final int ratingMin;
  final int ratingMax;
  final int carryoverPercent;

  const SeasonCarryoverTier({
    required this.ratingMin,
    required this.ratingMax,
    required this.carryoverPercent,
  });

  factory SeasonCarryoverTier.fromJson(Map<String, dynamic> json) {
    return SeasonCarryoverTier(
      ratingMin: (json['rating_min'] as num?)?.toInt() ?? 40,
      ratingMax: (json['rating_max'] as num?)?.toInt() ?? 59,
      carryoverPercent: (json['carryover_percent'] as num?)?.toInt() ?? 0,
    );
  }
}

class SeasonCarryoverSettings {
  final bool enabled;
  final int absoluteCapPoints;
  final int rookieBoostPoints;
  final int newToClubBoostPoints;
  final List<SeasonCarryoverTier> tiers;

  const SeasonCarryoverSettings({
    this.enabled = false,
    this.absoluteCapPoints = 0,
    this.rookieBoostPoints = 0,
    this.newToClubBoostPoints = 0,
    this.tiers = const [],
  });

  factory SeasonCarryoverSettings.fromJson(Map<String, dynamic> json) {
    return SeasonCarryoverSettings(
      enabled: json['enabled'] == true,
      absoluteCapPoints: (json['absolute_cap_points'] as num?)?.toInt() ?? 0,
      rookieBoostPoints: (json['rookie_boost_points'] as num?)?.toInt() ?? 0,
      newToClubBoostPoints:
          (json['new_to_club_boost_points'] as num?)?.toInt() ?? 0,
      tiers: (json['tiers'] as List? ?? [])
          .whereType<Map>()
          .map((e) => SeasonCarryoverTier.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class GamificationTransferWindow {
  final String seasonKey;
  final String windowType;
  final String? opensAt;
  final String? closesAt;
  final bool enabled;
  final bool deadlineDayCountdown;
  final bool autoPromoteEnabled;

  const GamificationTransferWindow({
    this.seasonKey = '',
    this.windowType = '',
    this.opensAt,
    this.closesAt,
    this.enabled = false,
    this.deadlineDayCountdown = false,
    this.autoPromoteEnabled = false,
  });

  factory GamificationTransferWindow.fromJson(Map<String, dynamic> json) {
    return GamificationTransferWindow(
      seasonKey: json['season_key']?.toString() ?? '',
      windowType: json['window_type']?.toString() ?? '',
      opensAt: json['opens_at']?.toString(),
      closesAt: json['closes_at']?.toString(),
      enabled: json['enabled'] == true,
      deadlineDayCountdown: json['deadline_day_countdown'] == true,
      autoPromoteEnabled: json['auto_promote_enabled'] == true,
    );
  }
}

class GamificationModules {
  final GamificationFormConfig? form;
  final GamificationStreakConfig? streaks;
  final GamificationWeeklyChallenges? weeklyChallenges;
  final List<GamificationSeasonGoal> seasonGoals;
  final GamificationActiveSeason? activeSeason;
  final GamificationTransferWindow? transferWindow;

  const GamificationModules({
    this.form,
    this.streaks,
    this.weeklyChallenges,
    this.seasonGoals = const [],
    this.activeSeason,
    this.transferWindow,
  });

  factory GamificationModules.fromJson(Map<String, dynamic> json) {
    return GamificationModules(
      form: json['form'] is Map
          ? GamificationFormConfig.fromJson(
              Map<String, dynamic>.from(json['form'] as Map),
            )
          : null,
      streaks: json['streaks'] is Map
          ? GamificationStreakConfig.fromJson(
              Map<String, dynamic>.from(json['streaks'] as Map),
            )
          : null,
      weeklyChallenges: json['weekly_challenges'] is Map
          ? GamificationWeeklyChallenges.fromJson(
              Map<String, dynamic>.from(json['weekly_challenges'] as Map),
            )
          : null,
      seasonGoals: (json['season_goals'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationSeasonGoal.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      activeSeason: json['active_season'] is Map
          ? GamificationActiveSeason.fromJson(
              Map<String, dynamic>.from(json['active_season'] as Map),
            )
          : null,
      transferWindow: json['transfer_window'] is Map
          ? GamificationTransferWindow.fromJson(
              Map<String, dynamic>.from(json['transfer_window'] as Map),
            )
          : null,
    );
  }
}

class GamificationFormConfig {
  final int formValue;
  final int warningThreshold;
  final List<GamificationFormRule> rules;

  const GamificationFormConfig({
    this.formValue = 70,
    this.warningThreshold = 55,
    this.rules = const [],
  });

  factory GamificationFormConfig.fromJson(Map<String, dynamic> json) {
    final decay = json['decay'];
    final warning = decay is Map ? (decay['warning_threshold'] as num?)?.toInt() : null;
    return GamificationFormConfig(
      warningThreshold: warning ?? 55,
      rules: (json['rules'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationFormRule.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }

  GamificationFormRule? ruleFor(String actionKey) {
    for (final rule in rules) {
      if (rule.actionKey == actionKey) return rule;
    }
    return null;
  }
}

class GamificationFormRule {
  final String actionKey;
  final int formPoints;
  final int dailyCap;
  final bool enabled;

  const GamificationFormRule({
    required this.actionKey,
    this.formPoints = 0,
    this.dailyCap = 0,
    this.enabled = true,
  });

  factory GamificationFormRule.fromJson(Map<String, dynamic> json) {
    return GamificationFormRule(
      actionKey: json['action_key']?.toString() ?? '',
      formPoints: (json['form_points'] as num?)?.toInt() ?? 0,
      dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] == true || json['enabled'] == 1,
    );
  }
}

class GamificationFormPoint {
  final String date;
  final int value;

  const GamificationFormPoint({required this.date, required this.value});

  factory GamificationFormPoint.fromJson(Map<String, dynamic> json) {
    return GamificationFormPoint(
      date: json['date']?.toString() ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

class GamificationStreakConfig {
  final List<GamificationStreakThreshold> thresholds;

  const GamificationStreakConfig({this.thresholds = const []});

  factory GamificationStreakConfig.fromJson(Map<String, dynamic> json) {
    return GamificationStreakConfig(
      thresholds: (json['thresholds'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationStreakThreshold.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class GamificationStreakThreshold {
  final int weeksRequired;
  final int bonusForm;
  final int bonusPoints;

  const GamificationStreakThreshold({
    required this.weeksRequired,
    this.bonusForm = 0,
    this.bonusPoints = 0,
  });

  factory GamificationStreakThreshold.fromJson(Map<String, dynamic> json) {
    return GamificationStreakThreshold(
      weeksRequired: (json['weeks_required'] as num?)?.toInt() ?? 0,
      bonusForm: (json['bonus_form'] as num?)?.toInt() ?? 0,
      bonusPoints: (json['bonus_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class GamificationWeeklyChallenges {
  final List<GamificationWeeklyChallenge> pool;
  final GamificationWeekMeta? week;
  final String rotationMode;

  const GamificationWeeklyChallenges({
    this.pool = const [],
    this.week,
    this.rotationMode = 'manual',
  });

  factory GamificationWeeklyChallenges.fromJson(Map<String, dynamic> json) {
    return GamificationWeeklyChallenges(
      pool: (json['pool'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationWeeklyChallenge.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      week: json['week'] is Map
          ? GamificationWeekMeta.fromJson(
              Map<String, dynamic>.from(json['week'] as Map),
            )
          : null,
      rotationMode: json['rotation_mode']?.toString() ?? 'manual',
    );
  }
}

class GamificationWeekMeta {
  final String weekKey;
  final int daysRemaining;
  final int secondsRemaining;

  const GamificationWeekMeta({
    required this.weekKey,
    this.daysRemaining = 0,
    this.secondsRemaining = 0,
  });

  factory GamificationWeekMeta.fromJson(Map<String, dynamic> json) {
    return GamificationWeekMeta(
      weekKey: json['week_key']?.toString() ?? '',
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      secondsRemaining: (json['seconds_remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class GamificationWeeklyChallenge {
  final String challengeKey;
  final String titleNo;
  final String descriptionNo;
  final String goalType;
  final int goalCount;
  final int rewardPoints;
  final int rewardForm;

  const GamificationWeeklyChallenge({
    required this.challengeKey,
    required this.titleNo,
    this.descriptionNo = '',
    this.goalType = '',
    this.goalCount = 1,
    this.rewardPoints = 0,
    this.rewardForm = 0,
  });

  factory GamificationWeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return GamificationWeeklyChallenge(
      challengeKey: json['challenge_key']?.toString() ?? '',
      titleNo: json['title_no']?.toString() ?? '',
      descriptionNo: json['description_no']?.toString() ?? '',
      goalType: json['goal_type']?.toString() ?? '',
      goalCount: (json['goal_count'] as num?)?.toInt() ?? 1,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      rewardForm: (json['reward_form'] as num?)?.toInt() ?? 0,
    );
  }
}

class GamificationSeasonGoal {
  final String goalKey;
  final String titleNo;
  final String descriptionNo;
  final String goalType;
  final int goalCount;
  final int rewardPoints;
  final int rewardForm;
  final String? badgeKey;
  final bool inherited;

  const GamificationSeasonGoal({
    required this.goalKey,
    required this.titleNo,
    this.descriptionNo = '',
    this.goalType = '',
    this.goalCount = 1,
    this.rewardPoints = 0,
    this.rewardForm = 0,
    this.badgeKey,
    this.inherited = false,
  });

  factory GamificationSeasonGoal.fromJson(Map<String, dynamic> json) {
    return GamificationSeasonGoal(
      goalKey: json['goal_key']?.toString() ?? '',
      titleNo: json['title_no']?.toString() ?? '',
      descriptionNo: json['description_no']?.toString() ?? '',
      goalType: json['goal_type']?.toString() ?? '',
      goalCount: (json['goal_count'] as num?)?.toInt() ?? 1,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      rewardForm: (json['reward_form'] as num?)?.toInt() ?? 0,
      badgeKey: json['badge_key']?.toString(),
      inherited: json['inherited'] == true,
    );
  }
}

class GamificationActiveSeason {
  final int seasonId;
  final String? label;
  final String? endsAt;

  const GamificationActiveSeason({
    required this.seasonId,
    this.label,
    this.endsAt,
  });

  factory GamificationActiveSeason.fromJson(Map<String, dynamic> json) {
    return GamificationActiveSeason(
      seasonId: (json['season_id'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString(),
      endsAt: json['ends_at']?.toString(),
    );
  }
}

class GamificationProgress {
  final GamificationWeekMeta? week;
  final int streakWeeks;
  final int formValue;
  final bool formWarning;
  final String formState;
  final int formFloor;
  final int formWarningThreshold;
  final List<GamificationFormPoint> formHistory;
  final List<GamificationChallengeProgress> weeklyChallenges;
  final List<GamificationGoalProgress> seasonGoals;
  final GamificationActiveSeason? activeSeason;
  final List<GamificationEarnedBadge> earnedBadges;
  final Map<String, BadgeMetricProgress> badgeProgress;
  final bool teamRequired;

  const GamificationProgress({
    this.week,
    this.streakWeeks = 0,
    this.formValue = 70,
    this.formWarning = false,
    this.formState = 'flat',
    this.formFloor = 40,
    this.formWarningThreshold = 55,
    this.formHistory = const [],
    this.weeklyChallenges = const [],
    this.seasonGoals = const [],
    this.activeSeason,
    this.earnedBadges = const [],
    this.badgeProgress = const {},
    this.teamRequired = false,
  });

  factory GamificationProgress.fromJson(Map<String, dynamic> json) {
    if (json['team_required'] == true) {
      return const GamificationProgress(teamRequired: true);
    }

    final streak = json['streak'];
    final form = json['form'];

    return GamificationProgress(
      week: json['week'] is Map
          ? GamificationWeekMeta.fromJson(
              Map<String, dynamic>.from(json['week'] as Map),
            )
          : null,
      streakWeeks: streak is Map
          ? (streak['current_weeks'] as num?)?.toInt() ?? 0
          : 0,
      formValue: form is Map ? (form['value'] as num?)?.toInt() ?? 70 : 70,
      formWarning: form is Map && form['warning'] == true,
      formState: form is Map ? (form['state']?.toString() ?? 'flat') : 'flat',
      formFloor: form is Map ? (form['floor'] as num?)?.toInt() ?? 40 : 40,
      formWarningThreshold:
          form is Map ? (form['warning_threshold'] as num?)?.toInt() ?? 55 : 55,
      formHistory: form is Map
          ? ((form['history'] as List? ?? [])
              .whereType<Map>()
              .map((e) => GamificationFormPoint.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList())
          : const [],
      weeklyChallenges: (json['weekly_challenges'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationChallengeProgress.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      seasonGoals: (json['season_goals'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationGoalProgress.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      activeSeason: json['active_season'] is Map
          ? GamificationActiveSeason.fromJson(
              Map<String, dynamic>.from(json['active_season'] as Map),
            )
          : null,
      earnedBadges: _parseEarnedBadges(json['earned_badges']),
      badgeProgress: BadgeMetricProgress.parseMap(json['badge_progress']),
    );
  }

  static List<GamificationEarnedBadge> _parseEarnedBadges(dynamic raw) {
    if (raw is! Map) return const [];
    final out = <GamificationEarnedBadge>[];
    for (final list in [
      raw['permanent'] as List? ?? [],
      raw['seasonal'] as List? ?? [],
    ]) {
      for (final item in list.whereType<Map>()) {
        out.add(GamificationEarnedBadge.fromJson(
          Map<String, dynamic>.from(item),
        ));
      }
    }
    return out;
  }
}

class GamificationChallengeProgress {
  final int slot;
  final String challengeKey;
  final String titleNo;
  final String descriptionNo;
  final int goalCount;
  final int progressCount;
  final bool completed;
  final int rewardPoints;

  const GamificationChallengeProgress({
    required this.slot,
    required this.challengeKey,
    required this.titleNo,
    this.descriptionNo = '',
    this.goalCount = 1,
    this.progressCount = 0,
    this.completed = false,
    this.rewardPoints = 0,
  });

  factory GamificationChallengeProgress.fromJson(Map<String, dynamic> json) {
    return GamificationChallengeProgress(
      slot: (json['slot'] as num?)?.toInt() ?? 0,
      challengeKey: json['challenge_key']?.toString() ?? '',
      titleNo: json['title_no']?.toString() ?? '',
      descriptionNo: json['description_no']?.toString() ?? '',
      goalCount: (json['goal_count'] as num?)?.toInt() ?? 1,
      progressCount: (json['progress_count'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
    );
  }

  double get progressFraction =>
      goalCount > 0 ? (progressCount / goalCount).clamp(0.0, 1.0) : 0;
}

class GamificationGoalProgress {
  final String goalKey;
  final String titleNo;
  final String descriptionNo;
  final int goalCount;
  final int progressCount;
  final bool completed;
  final int rewardPoints;
  final bool inherited;

  const GamificationGoalProgress({
    required this.goalKey,
    required this.titleNo,
    this.descriptionNo = '',
    this.goalCount = 1,
    this.progressCount = 0,
    this.completed = false,
    this.rewardPoints = 0,
    this.inherited = false,
  });

  factory GamificationGoalProgress.fromJson(Map<String, dynamic> json) {
    return GamificationGoalProgress(
      goalKey: json['goal_key']?.toString() ?? '',
      titleNo: json['title_no']?.toString() ?? '',
      descriptionNo: json['description_no']?.toString() ?? '',
      goalCount: (json['goal_count'] as num?)?.toInt() ?? 1,
      progressCount: (json['progress_count'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      inherited: json['inherited'] == true,
    );
  }

  double get progressFraction =>
      goalCount > 0 ? (progressCount / goalCount).clamp(0.0, 1.0) : 0;
}

class GamificationEarnedBadge {
  final String badgeKey;
  final String nameNo;
  final String icon;
  final String? earnedAt;

  const GamificationEarnedBadge({
    required this.badgeKey,
    required this.nameNo,
    this.icon = 'shield',
    this.earnedAt,
  });

  factory GamificationEarnedBadge.fromJson(Map<String, dynamic> json) {
    return GamificationEarnedBadge(
      badgeKey: json['badge_key']?.toString() ?? '',
      nameNo: json['name_no']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'shield',
      earnedAt: json['earned_at']?.toString(),
    );
  }
}

class GamificationCareer {
  final int lifetimePoints;
  final String? lifetimeSince;
  final List<GamificationEarnedBadge> permanentBadges;
  final List<GamificationEarnedBadge> seasonalBadges;
  final List<GamificationSeasonArchive> seasonArchives;
  final List<CareerAffiliationEntry> affiliations;
  final GamificationActiveSeason? activeSeason;
  final Map<String, BadgeMetricProgress> badgeProgress;

  const GamificationCareer({
    this.lifetimePoints = 0,
    this.lifetimeSince,
    this.permanentBadges = const [],
    this.seasonalBadges = const [],
    this.seasonArchives = const [],
    this.affiliations = const [],
    this.activeSeason,
    this.badgeProgress = const {},
  });

  factory GamificationCareer.fromJson(Map<String, dynamic> json) {
    final earned = json['earned_badges'];
    final permanent = earned is Map
        ? (earned['permanent'] as List? ?? [])
            .whereType<Map>()
            .map((e) => GamificationEarnedBadge.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <GamificationEarnedBadge>[];
    final seasonal = earned is Map
        ? (earned['seasonal'] as List? ?? [])
            .whereType<Map>()
            .map((e) => GamificationEarnedBadge.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <GamificationEarnedBadge>[];

    return GamificationCareer(
      lifetimePoints: (json['lifetime_points'] as num?)?.toInt() ?? 0,
      lifetimeSince: json['lifetime_since']?.toString(),
      permanentBadges: permanent,
      seasonalBadges: seasonal,
      seasonArchives: (json['season_archives'] as List? ?? [])
          .whereType<Map>()
          .map((e) => GamificationSeasonArchive.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      affiliations: (json['affiliations'] as List? ?? [])
          .whereType<Map>()
          .map((e) => CareerAffiliationEntry.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      activeSeason: json['active_season'] is Map
          ? GamificationActiveSeason.fromJson(
              Map<String, dynamic>.from(json['active_season'] as Map),
            )
          : null,
      badgeProgress: BadgeMetricProgress.parseMap(json['badge_progress']),
    );
  }
}

class GamificationSeasonArchive {
  final int seasonId;
  final String seasonLabel;
  final int finalRating;
  final String finalTierKey;
  final String tierLabel;
  final String clubName;
  final String teamName;
  final String? teamsNote;
  final int seasonPoints;
  final int appliedCarryover;
  final String? archivedAt;

  const GamificationSeasonArchive({
    required this.seasonId,
    this.seasonLabel = '',
    this.finalRating = 40,
    this.finalTierKey = '',
    this.tierLabel = '',
    this.clubName = '',
    this.teamName = '',
    this.teamsNote,
    this.seasonPoints = 0,
    this.appliedCarryover = 0,
    this.archivedAt,
  });

  String get metalKey {
    final key = finalTierKey.trim().toLowerCase();
    if (key.isNotEmpty) return key;
    final label = tierLabel.toLowerCase();
    if (label.contains('plat')) return 'platina';
    if (label.contains('gull') || label.contains('gold')) return 'gull';
    if (label.contains('sølv') || label.contains('solv') || label.contains('silver')) {
      return 'solv';
    }
    return 'bronse';
  }

  factory GamificationSeasonArchive.fromJson(Map<String, dynamic> json) {
    return GamificationSeasonArchive(
      seasonId: (json['season_id'] as num?)?.toInt() ?? 0,
      seasonLabel: json['season_label']?.toString() ?? '',
      finalRating: (json['final_rating'] as num?)?.toInt() ?? 40,
      finalTierKey: json['final_tier_key']?.toString() ?? '',
      tierLabel: json['tier_label']?.toString() ?? '',
      clubName: json['club_name']?.toString() ?? '',
      teamName: json['team_name']?.toString() ?? '',
      teamsNote: json['teams_note']?.toString(),
      seasonPoints: (json['season_points'] as num?)?.toInt() ?? 0,
      appliedCarryover: (json['applied_carryover'] as num?)?.toInt() ?? 0,
      archivedAt: json['archived_at']?.toString(),
    );
  }
}

class CareerAffiliationEntry {
  final int organizationId;
  final String clubName;
  final String? clubShortName;
  final String? clubLogoUrl;
  final String role;
  final String seasonsLabel;
  final bool isCurrent;
  final String? fromDate;
  final String? toDate;

  const CareerAffiliationEntry({
    required this.organizationId,
    required this.clubName,
    this.clubShortName,
    this.clubLogoUrl,
    this.role = 'current',
    this.seasonsLabel = '',
    this.isCurrent = false,
    this.fromDate,
    this.toDate,
  });

  factory CareerAffiliationEntry.fromJson(Map<String, dynamic> json) {
    return CareerAffiliationEntry(
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      clubName: json['club_name']?.toString() ?? '',
      clubShortName: json['club_short_name']?.toString(),
      clubLogoUrl: json['club_logo_url']?.toString(),
      role: json['role']?.toString() ?? 'current',
      seasonsLabel: json['seasons_label']?.toString() ?? '',
      isCurrent: json['is_current'] == true,
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
    );
  }
}
