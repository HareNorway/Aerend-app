// Pojos for the dugnad sports-club API (D1 endpoints).

import '../../ui/kit/ae_theme.dart' show normalizeThemeColor;

class ClubListItem {
  final int id;
  final String name;
  final String? shortName;
  final String? logo;
  final String? area;
  final int sponsorStoreCount;
  final String? portalThemeColor;
  final String? portalBackgroundColor;

  const ClubListItem({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.area,
    this.sponsorStoreCount = 0,
    this.portalThemeColor,
    this.portalBackgroundColor,
  });

  factory ClubListItem.fromJson(Map<String, dynamic> json) {
    return ClubListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'] as String?,
      logo: json['logo'] as String?,
      area: _stripPostcode(json['area'] as String?),
      sponsorStoreCount: (json['sponsor_store_count'] as num?)?.toInt() ?? 0,
      portalThemeColor: normalizeThemeColor(
        json['portal_theme_color'] as String?,
      ),
      portalBackgroundColor: normalizeThemeColor(
        json['portal_background_color'] as String?,
      ),
    );
  }
}

class ClubDetail {
  final int id;
  final String name;
  final String? shortName;
  final String? logo;
  final String? area;
  final String clubPayoutType;
  final double clubPayoutValue;
  final int sponsorStoreCount;
  final String? portalThemeColor;
  final String? portalBackgroundColor;
  final List<ClubCampaignSummary> campaigns;
  final List<SponsorStore> sponsorStores;

  const ClubDetail({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.area,
    this.clubPayoutType = 'percent',
    this.clubPayoutValue = 10,
    this.sponsorStoreCount = 0,
    this.portalThemeColor,
    this.portalBackgroundColor,
    this.campaigns = const [],
    this.sponsorStores = const [],
  });

  factory ClubDetail.fromJson(Map<String, dynamic> json) {
    return ClubDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'] as String?,
      logo: json['logo'] as String?,
      area: _stripPostcode(json['area'] as String?),
      clubPayoutType: json['club_payout_type'] ?? 'percent',
      clubPayoutValue: (json['club_payout_value'] as num?)?.toDouble() ?? 10,
      sponsorStoreCount: (json['sponsor_store_count'] as num?)?.toInt() ?? 0,
      portalThemeColor: normalizeThemeColor(
        json['portal_theme_color'] as String?,
      ),
      portalBackgroundColor: normalizeThemeColor(
        json['portal_background_color'] as String?,
      ),
      campaigns:
          (json['campaigns'] as List?)
              ?.map((e) => ClubCampaignSummary.fromJson(e))
              .toList() ??
          [],
      sponsorStores:
          (json['sponsor_stores'] as List?)
              ?.map((e) => SponsorStore.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ClubCampaignSummary {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? heroImageUrl;
  final String? landingHeading;
  final String? landingIntroText;
  final String? clubName;
  final int? teamId;
  final String? teamName;
  final String? teamLogoUrl;
  final String? salesWindowEnd;
  final String? distributionDate;
  final String? distributionLocation;
  final int productCount;
  final double minPrice;
  final int totalOrdersCount;
  final double totalRevenueNok;
  final double? fundraisingGoalNok;
  final int? goalPercent;

  const ClubCampaignSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.heroImageUrl,
    this.landingHeading,
    this.landingIntroText,
    this.clubName,
    this.teamId,
    this.teamName,
    this.teamLogoUrl,
    this.salesWindowEnd,
    this.distributionDate,
    this.distributionLocation,
    this.productCount = 0,
    this.minPrice = 0,
    this.totalOrdersCount = 0,
    this.totalRevenueNok = 0,
    this.fundraisingGoalNok,
    this.goalPercent,
  });

  factory ClubCampaignSummary.fromJson(Map<String, dynamic> json) {
    return ClubCampaignSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'] as String?,
      heroImageUrl: json['hero_image_url'] as String?,
      landingHeading: json['landing_heading'] as String?,
      landingIntroText: json['landing_intro_text'] as String?,
      clubName: json['club_name'] as String?,
      teamId: (json['team_id'] as num?)?.toInt(),
      teamName: json['team_name'] as String?,
      teamLogoUrl: json['team_logo_url'] as String?,
      salesWindowEnd: json['sales_window_end'] as String?,
      distributionDate: json['distribution_date'] as String?,
      distributionLocation: json['distribution_location'] as String?,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
      totalOrdersCount: (json['total_orders_count'] as num?)?.toInt() ?? 0,
      totalRevenueNok: (json['total_revenue_nok'] as num?)?.toDouble() ?? 0,
      fundraisingGoalNok: (json['fundraising_goal_nok'] as num?)?.toDouble(),
      goalPercent: (json['goal_percent'] as num?)?.toInt(),
    );
  }

  String get displayTitle =>
      landingHeading != null && landingHeading!.trim().isNotEmpty
      ? landingHeading!.trim()
      : name;
}

class SponsorStore {
  final int id;
  final String name;
  final String? logo;
  final String? address;
  final int? deliveryTime;
  final int storeStatus;

  const SponsorStore({
    required this.id,
    required this.name,
    this.logo,
    this.address,
    this.deliveryTime,
    this.storeStatus = 0,
  });

  factory SponsorStore.fromJson(Map<String, dynamic> json) {
    return SponsorStore(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'] as String?,
      address: json['address'] as String?,
      deliveryTime: (json['delivery_time'] as num?)?.toInt(),
      storeStatus: (json['store_status'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClubTeamItem {
  final int id;
  final String name;
  final String? slug;
  final String? ageGroup;
  final String? description;
  final String? logoUrl;
  final int sortOrder;

  const ClubTeamItem({
    required this.id,
    required this.name,
    this.slug,
    this.ageGroup,
    this.description,
    this.logoUrl,
    this.sortOrder = 0,
  });

  factory ClubTeamItem.fromJson(Map<String, dynamic> json) {
    return ClubTeamItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] as String?,
      ageGroup: json['age_group'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  String get displaySubtitle {
    if (ageGroup != null && ageGroup!.trim().isNotEmpty)
      return ageGroup!.trim();
    return '';
  }
}

class MetalTierInfo {
  final String key;
  final String metal;
  final int minPoints;
  final String labelNo;
  final String titleSuffix;
  final String colorHex;
  final bool achieved;

  const MetalTierInfo({
    required this.key,
    required this.metal,
    required this.minPoints,
    required this.labelNo,
    required this.titleSuffix,
    this.colorHex = '',
    this.achieved = false,
  });

  factory MetalTierInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MetalTierInfo(
        key: 'supporter',
        metal: 'bronse',
        minPoints: 0,
        labelNo: 'Bronse',
        titleSuffix: 'supporter',
        colorHex: '#A46321',
      );
    }
    return MetalTierInfo(
      key: json['key']?.toString() ?? 'supporter',
      metal: json['metal']?.toString() ?? 'bronse',
      minPoints: (json['min_points'] as num?)?.toInt() ?? 0,
      labelNo: json['label_no']?.toString() ?? '',
      titleSuffix: json['title_suffix']?.toString() ?? '',
      colorHex: json['color_hex']?.toString() ?? '',
      achieved: json['achieved'] == true,
    );
  }
}

class PointsTeamProfile {
  final bool hasPointsTeam;
  final int? pointsTeamId;
  final String? pointsTeamName;
  final String? pointsTeamLogoUrl;
  final String? pointsTeamAgeGroup;
  final int? organizationId;
  final String? organizationName;
  final String? organizationShortName;
  final int totalPoints;
  final int lifetimePoints;
  final int seasonPoints;
  final int stoRating;
  final MetalTierInfo? currentTier;
  final MetalTierInfo? nextTier;
  final int progressionPercent;
  final int pointsToNextTier;
  final int campaignPurchasePoints;
  final int welcomeBonusPointsAwarded;
  final int referralJoinPointsAwarded;
  final int referralPopCursor;
  final List<UnseenReferralAward> unseenReferralAwards;
  final int missionPopCursor;
  final List<UnseenMissionAward> unseenMissionAwards;
  final String? configVersion;

  const PointsTeamProfile({
    this.hasPointsTeam = false,
    this.pointsTeamId,
    this.pointsTeamName,
    this.pointsTeamLogoUrl,
    this.pointsTeamAgeGroup,
    this.organizationId,
    this.organizationName,
    this.organizationShortName,
    this.totalPoints = 0,
    this.lifetimePoints = 0,
    this.seasonPoints = 0,
    this.stoRating = 40,
    this.currentTier,
    this.nextTier,
    this.progressionPercent = 0,
    this.pointsToNextTier = 0,
    this.campaignPurchasePoints = 50,
    this.welcomeBonusPointsAwarded = 0,
    this.referralJoinPointsAwarded = 0,
    this.referralPopCursor = 0,
    this.unseenReferralAwards = const [],
    this.missionPopCursor = 0,
    this.unseenMissionAwards = const [],
    this.configVersion,
  });

  factory PointsTeamProfile.fromJson(Map<String, dynamic> json) {
    final pointsTeamId = (json['points_team_id'] as num?)?.toInt();
    return PointsTeamProfile(
      hasPointsTeam: json['has_points_team'] == true ||
          json['has_points_team'] == 1 ||
          (pointsTeamId ?? 0) > 0,
      pointsTeamId: pointsTeamId,
      pointsTeamName: json['points_team_name'] as String?,
      pointsTeamLogoUrl: json['points_team_logo_url'] as String?,
      pointsTeamAgeGroup: json['points_team_age_group'] as String?,
      organizationId: (json['organization_id'] as num?)?.toInt(),
      organizationName: json['organization_name'] as String?,
      organizationShortName: json['organization_short_name'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      lifetimePoints:
          (json['lifetime_points'] as num?)?.toInt() ??
          (json['total_points'] as num?)?.toInt() ??
          0,
      seasonPoints: (json['season_points'] as num?)?.toInt() ?? 0,
      stoRating: (json['sto_rating'] as num?)?.toInt() ?? 40,
      currentTier: json['current_tier'] is Map
          ? MetalTierInfo.fromJson(
              Map<String, dynamic>.from(json['current_tier'] as Map),
            )
          : null,
      nextTier: json['next_tier'] is Map
          ? MetalTierInfo.fromJson(
              Map<String, dynamic>.from(json['next_tier'] as Map),
            )
          : null,
      progressionPercent: (json['progression_percent'] as num?)?.toInt() ?? 0,
      pointsToNextTier: (json['points_to_next_tier'] as num?)?.toInt() ?? 0,
      campaignPurchasePoints:
          (json['campaign_purchase_points'] as num?)?.toInt() ?? 50,
      welcomeBonusPointsAwarded:
          (json['welcome_bonus_points_awarded'] as num?)?.toInt() ?? 0,
      referralJoinPointsAwarded:
          (json['referral_join_points_awarded'] as num?)?.toInt() ?? 0,
      referralPopCursor: (json['referral_pop_cursor'] as num?)?.toInt() ?? 0,
      unseenReferralAwards: (json['unseen_referral_awards'] as List?)
              ?.whereType<Map>()
              .map((e) => UnseenReferralAward.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((e) => e.id > 0 && e.points > 0)
              .toList() ??
          const [],
      missionPopCursor: (json['mission_pop_cursor'] as num?)?.toInt() ?? 0,
      unseenMissionAwards: (json['unseen_mission_awards'] as List?)
              ?.whereType<Map>()
              .map((e) => UnseenMissionAward.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((e) => e.id > 0 && e.points > 0)
              .toList() ??
          const [],
      configVersion: json['config_version']?.toString(),
    );
  }
}

class UnseenReferralAward {
  final int id;
  final int points;

  const UnseenReferralAward({
    required this.id,
    required this.points,
  });

  factory UnseenReferralAward.fromJson(Map<String, dynamic> json) {
    return UnseenReferralAward(
      id: (json['id'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class UnseenMissionAward {
  final int id;
  final int points;
  final String action;

  const UnseenMissionAward({
    required this.id,
    required this.points,
    this.action = 'weekly_challenge_bonus',
  });

  factory UnseenMissionAward.fromJson(Map<String, dynamic> json) {
    return UnseenMissionAward(
      id: (json['id'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      action: (json['action'] as String?)?.trim().isNotEmpty == true
          ? (json['action'] as String).trim()
          : 'weekly_challenge_bonus',
    );
  }
}

class PointsActionCounts {
  final int campaignPurchases;
  final int donationCharges;
  final int referralConversions;

  const PointsActionCounts({
    this.campaignPurchases = 0,
    this.donationCharges = 0,
    this.referralConversions = 0,
  });

  factory PointsActionCounts.fromJson(Map<String, dynamic> json) {
    return PointsActionCounts(
      campaignPurchases: (json['campaign_purchases'] as num?)?.toInt() ?? 0,
      donationCharges: (json['donation_charges'] as num?)?.toInt() ?? 0,
      referralConversions: (json['referral_conversions'] as num?)?.toInt() ?? 0,
    );
  }
}

class PointsSummary {
  final int lifetimePoints;
  final int seasonPoints;
  final int stoRating;
  final MetalTierInfo? currentTier;
  final MetalTierInfo? nextTier;
  final int progressionPercent;
  final int pointsToNextTier;
  final List<MetalTierInfo> metalTiers;
  final PointsActionCounts actionCounts;
  final String configVersion;
  final String publicDisplayName;
  final String? seasonStartsAt;
  final String? seasonEndsAt;
  final int campaignPurchasePoints;

  const PointsSummary({
    this.lifetimePoints = 0,
    this.seasonPoints = 0,
    this.stoRating = 40,
    this.currentTier,
    this.nextTier,
    this.progressionPercent = 0,
    this.pointsToNextTier = 0,
    this.metalTiers = const [],
    this.actionCounts = const PointsActionCounts(),
    this.configVersion = '',
    this.publicDisplayName = '',
    this.seasonStartsAt,
    this.seasonEndsAt,
    this.campaignPurchasePoints = 50,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    final tiersRaw = json['metal_tiers'];
    final countsRaw = json['action_counts'];
    final seasonRaw = json['season'];
    return PointsSummary(
      lifetimePoints: (json['lifetime_points'] as num?)?.toInt() ?? 0,
      seasonPoints: (json['season_points'] as num?)?.toInt() ?? 0,
      stoRating: (json['sto_rating'] as num?)?.toInt() ?? 40,
      currentTier: json['current_tier'] is Map
          ? MetalTierInfo.fromJson(
              Map<String, dynamic>.from(json['current_tier'] as Map),
            )
          : null,
      nextTier: json['next_tier'] is Map
          ? MetalTierInfo.fromJson(
              Map<String, dynamic>.from(json['next_tier'] as Map),
            )
          : null,
      progressionPercent: (json['progression_percent'] as num?)?.toInt() ?? 0,
      pointsToNextTier: (json['points_to_next_tier'] as num?)?.toInt() ?? 0,
      metalTiers: tiersRaw is List
          ? tiersRaw
                .whereType<Map>()
                .map(
                  (e) => MetalTierInfo.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      actionCounts: countsRaw is Map
          ? PointsActionCounts.fromJson(Map<String, dynamic>.from(countsRaw))
          : const PointsActionCounts(),
      configVersion: json['config_version']?.toString() ?? '',
      publicDisplayName: json['public_display_name']?.toString() ?? '',
      seasonStartsAt: seasonRaw is Map
          ? seasonRaw['starts_at']?.toString()
          : null,
      seasonEndsAt: seasonRaw is Map ? seasonRaw['ends_at']?.toString() : null,
      campaignPurchasePoints:
          (json['campaign_purchase_points'] as num?)?.toInt() ?? 50,
    );
  }
}

/// One in-app notification row from POST dugnad/notifications.
class DugnadNotificationItem {
  final int id;
  final String category;
  final String typeKey;
  final String titleNo;
  final String bodyNo;
  final String? deepLinkKey;
  final Map<String, dynamic>? deepLinkPayload;
  final String iconKey;
  final String tone;
  final bool unread;
  final String? readAt;
  final String? createdAt;

  const DugnadNotificationItem({
    required this.id,
    this.category = 'system',
    this.typeKey = '',
    this.titleNo = '',
    this.bodyNo = '',
    this.deepLinkKey,
    this.deepLinkPayload,
    this.iconKey = 'bell',
    this.tone = 'purple',
    this.unread = true,
    this.readAt,
    this.createdAt,
  });

  factory DugnadNotificationItem.fromJson(Map<String, dynamic> json) {
    final payload = json['deep_link_payload'];
    return DugnadNotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'system',
      typeKey: json['type_key']?.toString() ?? '',
      titleNo: json['title_no']?.toString() ?? '',
      bodyNo: json['body_no']?.toString() ?? '',
      deepLinkKey: json['deep_link_key']?.toString(),
      deepLinkPayload: payload is Map
          ? Map<String, dynamic>.from(payload)
          : null,
      iconKey: json['icon_key']?.toString() ?? 'bell',
      tone: json['tone']?.toString() ?? 'purple',
      unread: json['unread'] == true || json['read_at'] == null,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  DugnadNotificationItem copyWith({bool? unread, String? readAt}) {
    return DugnadNotificationItem(
      id: id,
      category: category,
      typeKey: typeKey,
      titleNo: titleNo,
      bodyNo: bodyNo,
      deepLinkKey: deepLinkKey,
      deepLinkPayload: deepLinkPayload,
      iconKey: iconKey,
      tone: tone,
      unread: unread ?? this.unread,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class DugnadNotificationsPage {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<DugnadNotificationItem> notifications;

  const DugnadNotificationsPage({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.notifications = const [],
  });

  factory DugnadNotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'];
    return DugnadNotificationsPage(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      notifications: list is List
          ? list
              .whereType<Map>()
              .map((e) => DugnadNotificationItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}

/// Category-level in-app notification preferences (not push).
class DugnadNotificationPrefs {
  final bool points;
  final bool campaigns;
  final bool social;
  final bool system;

  const DugnadNotificationPrefs({
    this.points = true,
    this.campaigns = true,
    this.social = true,
    this.system = true,
  });

  factory DugnadNotificationPrefs.fromJson(Map<String, dynamic> json) {
    return DugnadNotificationPrefs(
      points: json['points'] != false,
      campaigns: json['campaigns'] != false,
      social: json['social'] != false,
      system: json['system'] != false,
    );
  }

  DugnadNotificationPrefs copyWith({
    bool? points,
    bool? campaigns,
    bool? social,
    bool? system,
  }) {
    return DugnadNotificationPrefs(
      points: points ?? this.points,
      campaigns: campaigns ?? this.campaigns,
      social: social ?? this.social,
      system: system ?? this.system,
    );
  }

  Map<String, dynamic> toUpdatePayload() => {
        'points': points,
        'campaigns': campaigns,
        'social': social,
        'system': system,
      };
}

class DugnadPrivacySettings {
  final String displayNamePref;
  final String effectiveDisplayNamePref;
  final String? nickname;
  final bool isVisible;
  final bool isMinor;
  final bool canChooseFullName;
  final List<String> allowedDisplayNamePrefs;
  final String legalFullName;
  final String publicDisplayName;
  final String anonymousLabel;

  const DugnadPrivacySettings({
    this.displayNamePref = 'first_initial',
    this.effectiveDisplayNamePref = 'first_initial',
    this.nickname,
    this.isVisible = true,
    this.isMinor = false,
    this.canChooseFullName = true,
    this.allowedDisplayNamePrefs = const [
      'full',
      'first_initial',
      'nickname',
      'anonymous',
    ],
    this.legalFullName = '',
    this.publicDisplayName = '',
    this.anonymousLabel = 'Anonym støttespiller',
  });

  factory DugnadPrivacySettings.fromJson(Map<String, dynamic> json) {
    final allowedRaw = json['allowed_display_name_prefs'];
    return DugnadPrivacySettings(
      displayNamePref: json['display_name_pref']?.toString() ?? 'first_initial',
      effectiveDisplayNamePref:
          json['effective_display_name_pref']?.toString() ??
          json['display_name_pref']?.toString() ??
          'first_initial',
      nickname: json['nickname']?.toString(),
      isVisible: json['is_visible'] == false ? false : true,
      isMinor: json['is_minor'] == true,
      canChooseFullName: json['can_choose_full_name'] != false,
      allowedDisplayNamePrefs: allowedRaw is List
          ? allowedRaw.map((e) => e.toString()).toList()
          : const ['full', 'first_initial', 'nickname', 'anonymous'],
      legalFullName: json['legal_full_name']?.toString() ?? '',
      publicDisplayName: json['public_display_name']?.toString() ?? '',
      anonymousLabel:
          json['anonymous_label']?.toString() ?? 'Anonym støttespiller',
    );
  }

  Map<String, dynamic> toUpdatePayload({
    required String displayNamePref,
    required String nickname,
    required bool isVisible,
  }) {
    return {
      'display_name_pref': displayNamePref,
      'nickname': nickname,
      'is_visible': isVisible,
    };
  }
}

class PointsLedgerEntry {
  final int id;
  final String action;
  final int points;
  final int teamId;
  final String? createdAt;
  final PointsLedgerMeta meta;

  const PointsLedgerEntry({
    required this.id,
    required this.action,
    required this.points,
    required this.teamId,
    this.createdAt,
    this.meta = const PointsLedgerMeta(),
  });

  factory PointsLedgerEntry.fromJson(Map<String, dynamic> json) {
    final metaRaw = json['meta'];
    return PointsLedgerEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      action: json['action']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      teamId: (json['team_id'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      meta: metaRaw is Map
          ? PointsLedgerMeta.fromJson(Map<String, dynamic>.from(metaRaw))
          : const PointsLedgerMeta(),
    );
  }
}

class PointsLedgerMeta {
  final bool isReversal;
  final int? referralSequence;
  final int? milestoneCount;
  final String? reversesAction;

  const PointsLedgerMeta({
    this.isReversal = false,
    this.referralSequence,
    this.milestoneCount,
    this.reversesAction,
  });

  factory PointsLedgerMeta.fromJson(Map<String, dynamic> json) {
    return PointsLedgerMeta(
      isReversal: json['is_reversal'] == true,
      referralSequence: (json['referral_sequence'] as num?)?.toInt(),
      milestoneCount: (json['milestone_count'] as num?)?.toInt(),
      reversesAction: json['reverses_action']?.toString(),
    );
  }
}

class PointsLedgerPage {
  final int page;
  final int perPage;
  final int total;
  final List<PointsLedgerEntry> entries;

  const PointsLedgerPage({
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.entries = const [],
  });

  factory PointsLedgerPage.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    return PointsLedgerPage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      entries: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      PointsLedgerEntry.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class LeaderboardTeamRow {
  final int rank;
  final int teamId;
  final String name;
  final String? slug;
  final String? ageGroup;
  final String? logoUrl;
  final int lagpoeng;
  final double krRaised;
  final int activeFamilies;
  final bool isUserTeam;
  final int rankMove;

  const LeaderboardTeamRow({
    required this.rank,
    required this.teamId,
    required this.name,
    this.slug,
    this.ageGroup,
    this.logoUrl,
    this.lagpoeng = 0,
    this.krRaised = 0,
    this.activeFamilies = 0,
    this.isUserTeam = false,
    this.rankMove = 0,
  });

  factory LeaderboardTeamRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardTeamRow(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      teamId: json['team_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] as String?,
      ageGroup: json['age_group'] as String?,
      logoUrl: json['logo_url'] as String?,
      lagpoeng: (json['lagpoeng'] as num?)?.toInt() ?? 0,
      krRaised: (json['kr_raised'] as num?)?.toDouble() ?? 0,
      activeFamilies: (json['active_families'] as num?)?.toInt() ?? 0,
      isUserTeam: json['is_user_team'] == true,
      rankMove: (json['rank_move'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardSeason {
  final String startsAt;
  final String endsAt;
  final String endsAtLabel;
  final int year;
  final int prizeNok;
  final int prizeZoneSize;
  final int teamGoalPoints;

  const LeaderboardSeason({
    required this.startsAt,
    required this.endsAt,
    required this.endsAtLabel,
    this.year = 0,
    this.prizeNok = 10000,
    this.prizeZoneSize = 3,
    this.teamGoalPoints = 6000,
  });

  factory LeaderboardSeason.fromJson(Map<String, dynamic> json) {
    return LeaderboardSeason(
      startsAt: json['starts_at'] ?? '',
      endsAt: json['ends_at'] ?? '',
      endsAtLabel: json['ends_at_label'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      prizeNok: (json['prize_nok'] as num?)?.toInt() ?? 10000,
      prizeZoneSize: (json['prize_zone_size'] as num?)?.toInt() ?? 3,
      teamGoalPoints: (json['team_goal_points'] as num?)?.toInt() ?? 6000,
    );
  }
}

class LeaderboardData {
  final int clubId;
  final String clubName;
  final String? clubShortName;
  final String? clubLogo;
  final LeaderboardSeason season;
  final int? viewerPointsTeamId;
  final int prizeZoneSize;
  final int? prizeZoneCutoffPoints;
  final List<LeaderboardTeamRow> teams;

  const LeaderboardData({
    required this.clubId,
    required this.clubName,
    this.clubShortName,
    this.clubLogo,
    required this.season,
    this.viewerPointsTeamId,
    this.prizeZoneSize = 3,
    this.prizeZoneCutoffPoints,
    this.teams = const [],
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>? ?? {};
    final seasonJson = json['season'] as Map<String, dynamic>? ?? {};
    final List rawTeams = json['teams'] ?? [];

    return LeaderboardData(
      clubId: club['id'] ?? 0,
      clubName: club['name'] ?? '',
      clubShortName: club['short_name'] as String?,
      clubLogo: club['logo'] as String?,
      season: LeaderboardSeason.fromJson(seasonJson),
      viewerPointsTeamId: (json['viewer_points_team_id'] as num?)?.toInt(),
      prizeZoneSize:
          (json['prize_zone_size'] as num?)?.toInt() ??
          (seasonJson['prize_zone_size'] as num?)?.toInt() ??
          3,
      prizeZoneCutoffPoints: (json['prize_zone_cutoff_points'] as num?)
          ?.toInt(),
      teams: rawTeams
          .map((e) => LeaderboardTeamRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LeaderboardScorerRow {
  const LeaderboardScorerRow({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.teamId,
    required this.teamName,
    required this.tierKey,
    required this.tierLabel,
    required this.tierTitle,
    required this.tierMetal,
    required this.stoRating,
    required this.goals,
    required this.assists,
    required this.markedsverdi,
    required this.kamper,
    required this.seasonPoints,
    required this.isViewer,
  });

  final int rank;
  final int userId;
  final String displayName;
  final int teamId;
  final String teamName;
  final String tierKey;
  final String tierLabel;
  final String tierTitle;
  final String tierMetal;
  final int stoRating;
  final int goals;
  final int assists;
  final int markedsverdi;
  final int kamper;
  final int seasonPoints;
  final bool isViewer;

  factory LeaderboardScorerRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardScorerRow(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name']?.toString() ?? '',
      teamId: (json['team_id'] as num?)?.toInt() ?? 0,
      teamName: json['team_name']?.toString() ?? '',
      tierKey: json['tier_key']?.toString() ?? 'supporter',
      tierLabel: json['tier_label']?.toString() ?? '',
      tierTitle: json['tier_title']?.toString() ?? '',
      tierMetal: json['tier_metal']?.toString() ?? 'bronse',
      stoRating: (json['sto_rating'] as num?)?.toInt() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      markedsverdi: (json['markedsverdi'] as num?)?.toInt() ?? 0,
      kamper: (json['kamper'] as num?)?.toInt() ?? 0,
      seasonPoints: (json['season_points'] as num?)?.toInt() ?? 0,
      isViewer: json['is_viewer'] == true,
    );
  }
}

class LeaderboardScorersData {
  const LeaderboardScorersData({
    required this.tab,
    required this.clubId,
    required this.clubName,
    this.clubLogo,
    required this.season,
    this.filterTeamId,
    this.viewerPointsTeamId,
    this.scorers = const [],
  });

  final String tab;
  final int clubId;
  final String clubName;
  final String? clubLogo;
  final LeaderboardSeason season;
  final int? filterTeamId;
  final int? viewerPointsTeamId;
  final List<LeaderboardScorerRow> scorers;

  factory LeaderboardScorersData.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>? ?? {};
    final seasonJson = json['season'] as Map<String, dynamic>? ?? {};
    final List raw = json['scorers'] ?? [];

    return LeaderboardScorersData(
      tab: json['tab']?.toString() ?? 'toppscorer',
      clubId: club['id'] ?? 0,
      clubName: club['name']?.toString() ?? '',
      clubLogo: club['logo'] as String?,
      season: LeaderboardSeason.fromJson(seasonJson),
      filterTeamId: (json['filter_team_id'] as num?)?.toInt(),
      viewerPointsTeamId: (json['viewer_points_team_id'] as num?)?.toInt(),
      scorers: raw
          .map((e) => LeaderboardScorerRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeamPointsBreakdownItem {
  const TeamPointsBreakdownItem({required this.id, required this.points});

  final String id;
  final int points;

  factory TeamPointsBreakdownItem.fromJson(Map<String, dynamic> json) {
    return TeamPointsBreakdownItem(
      id: json['id']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeamDetailData {
  const TeamDetailData({
    required this.clubId,
    required this.clubName,
    this.clubShortName,
    this.clubLogo,
    required this.season,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.rank,
    required this.teamCount,
    required this.lagpoeng,
    required this.krRaised,
    required this.activeFamilies,
    required this.isUserTeam,
    required this.goalPoints,
    required this.goalPercent,
    required this.breakdown,
    required this.hasActiveDonation,
    this.avgSto = 0,
    this.rankMove = 0,
    this.prizeZoneSize = 3,
    this.inPrizeZone = false,
    this.supportsTeam = false,
    this.supportViaOrg = false,
    this.donationAmountKr,
    this.captainUserId,
    this.squad = const [],
    this.squadAnonymousCount = 0,
    this.activeCampaign,
  });

  final int clubId;
  final String clubName;
  final String? clubShortName;
  final String? clubLogo;
  final LeaderboardSeason season;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int rank;
  final int teamCount;
  final int lagpoeng;
  final double krRaised;
  final int activeFamilies;
  final bool isUserTeam;
  final int goalPoints;
  final int goalPercent;
  final List<TeamPointsBreakdownItem> breakdown;
  final bool hasActiveDonation;
  final int avgSto;
  final int rankMove;
  final int prizeZoneSize;
  final bool inPrizeZone;
  final bool supportsTeam;
  final bool supportViaOrg;
  final double? donationAmountKr;
  final int? captainUserId;
  final List<LeaderboardScorerRow> squad;
  final int squadAnonymousCount;
  final ClubCampaignSummary? activeCampaign;

  factory TeamDetailData.fromJson(Map<String, dynamic> json) {
    final club = json['club'] as Map<String, dynamic>? ?? {};
    final seasonJson = json['season'] as Map<String, dynamic>? ?? {};
    final team = json['team'] as Map<String, dynamic>? ?? {};
    final List rawBreakdown = team['points_breakdown'] ?? [];
    final List rawSquad = team['squad'] ?? [];
    final campaignJson = json['active_campaign'];
    final captainId = (team['captain_user_id'] as num?)?.toInt();

    final squad = rawSquad.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      // Ensure captain flag flows into row via is_viewer-style parsing if needed.
      return LeaderboardScorerRow.fromJson(map);
    }).toList();

    return TeamDetailData(
      clubId: club['id'] ?? 0,
      clubName: club['name']?.toString() ?? '',
      clubShortName: club['short_name'] as String?,
      clubLogo: club['logo'] as String?,
      season: LeaderboardSeason.fromJson(seasonJson),
      teamId: team['team_id'] ?? 0,
      teamName: team['name']?.toString() ?? '',
      teamLogo: team['logo_url'] as String?,
      rank: (team['rank'] as num?)?.toInt() ?? 0,
      teamCount: (team['team_count'] as num?)?.toInt() ?? 0,
      lagpoeng: (team['lagpoeng'] as num?)?.toInt() ?? 0,
      krRaised: (team['kr_raised'] as num?)?.toDouble() ?? 0,
      activeFamilies: (team['active_families'] as num?)?.toInt() ?? 0,
      isUserTeam: team['is_user_team'] == true,
      goalPoints: (team['goal_points'] as num?)?.toInt() ?? 6000,
      goalPercent: (team['goal_percent'] as num?)?.toInt() ?? 0,
      breakdown: rawBreakdown
          .map(
            (e) => TeamPointsBreakdownItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      hasActiveDonation: team['has_active_donation'] == true,
      avgSto: (team['avg_sto'] as num?)?.toInt() ?? 0,
      rankMove: (team['rank_move'] as num?)?.toInt() ?? 0,
      prizeZoneSize: (team['prize_zone_size'] as num?)?.toInt() ?? 3,
      inPrizeZone: team['in_prize_zone'] == true,
      supportsTeam: team['supports_team'] == true ||
          team['has_active_donation'] == true,
      supportViaOrg: team['support_via_org'] == true,
      donationAmountKr: (team['donation_amount_kr'] as num?)?.toDouble(),
      captainUserId: captainId,
      squad: squad,
      squadAnonymousCount: (team['squad_anonymous_count'] as num?)?.toInt() ?? 0,
      activeCampaign: campaignJson is Map
          ? ClubCampaignSummary.fromJson(
              Map<String, dynamic>.from(campaignJson),
            )
          : null,
    );
  }

  bool isCaptain(LeaderboardScorerRow row) =>
      captainUserId != null && row.userId == captainUserId;
}

class ReferralSummary {
  final String referralCode;
  final String? referralToken;
  final String? referralLink;
  final int? organizationId;
  final String? organizationName;
  final String? organizationShortName;
  final String? organizationLogo;
  final String? clubSlug;
  final int convertedCount;
  final int pendingCount;
  final int ambassadorGoal;
  final int referralPoints;
  final List<ReferralRecord> pendingReferrals;
  final List<ReferralRecord> recentReferrals;
  final ReferralRecord? incomingReferral;

  const ReferralSummary({
    required this.referralCode,
    this.referralToken,
    this.referralLink,
    this.organizationId,
    this.organizationName,
    this.organizationShortName,
    this.organizationLogo,
    this.clubSlug,
    this.convertedCount = 0,
    this.pendingCount = 0,
    this.ambassadorGoal = 5,
    this.referralPoints = 100,
    this.pendingReferrals = const [],
    this.recentReferrals = const [],
    this.incomingReferral,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final pending =
        (json['pending_referrals'] as List?)
            ?.map((e) => ReferralRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <ReferralRecord>[];
    final recent =
        (json['recent_referrals'] as List?)
            ?.map((e) => ReferralRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        pending;
    final incoming = json['incoming_referral'];
    return ReferralSummary(
      referralCode: json['referral_code']?.toString() ?? '',
      referralToken: json['referral_token']?.toString(),
      referralLink: json['referral_link']?.toString(),
      organizationId: (json['organization_id'] as num?)?.toInt(),
      organizationName: json['organization_name']?.toString(),
      organizationShortName: json['organization_short_name']?.toString(),
      organizationLogo: json['organization_logo']?.toString(),
      clubSlug: json['club_slug']?.toString(),
      convertedCount: (json['converted_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      ambassadorGoal: (json['ambassador_goal'] as num?)?.toInt() ?? 5,
      referralPoints: (json['referral_points'] as num?)?.toInt() ?? 100,
      pendingReferrals: pending,
      recentReferrals: recent,
      incomingReferral: incoming is Map
          ? ReferralRecord.fromJson(Map<String, dynamic>.from(incoming))
          : null,
    );
  }
}

class ShareSummary {
  final String? shareToken;
  final String? shareLink;
  final int? organizationId;
  final String? organizationName;
  final String? organizationShortName;
  final String? clubSlug;

  const ShareSummary({
    this.shareToken,
    this.shareLink,
    this.organizationId,
    this.organizationName,
    this.organizationShortName,
    this.clubSlug,
  });

  factory ShareSummary.fromJson(Map<String, dynamic> json) {
    return ShareSummary(
      shareToken: json['share_token']?.toString(),
      shareLink: json['share_link']?.toString(),
      organizationId: (json['organization_id'] as num?)?.toInt(),
      organizationName: json['organization_name']?.toString(),
      organizationShortName: json['organization_short_name']?.toString(),
      clubSlug: json['club_slug']?.toString(),
    );
  }
}

class ReferralRecord {
  final int id;
  final String status;
  final int? referredUserId;
  final bool referredIsVerified;
  final String? referrerDisplayName;
  final String? referredDisplayName;
  final String? organizationName;
  final String? referralCode;
  final String? capturedAt;
  final String? convertedAt;

  const ReferralRecord({
    required this.id,
    required this.status,
    this.referredUserId,
    this.referredIsVerified = false,
    this.referrerDisplayName,
    this.referredDisplayName,
    this.organizationName,
    this.referralCode,
    this.capturedAt,
    this.convertedAt,
  });

  factory ReferralRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      referredUserId: (json['referred_user_id'] as num?)?.toInt(),
      referredIsVerified: json['referred_is_verified'] == true,
      referrerDisplayName: json['referrer_display_name']?.toString(),
      referredDisplayName: json['referred_display_name']?.toString(),
      organizationName: json['organization_name']?.toString(),
      referralCode: json['referral_code']?.toString(),
      capturedAt: json['captured_at']?.toString(),
      convertedAt: json['converted_at']?.toString(),
    );
  }
}

class ReferralValidationResult {
  final bool valid;
  final String? message;
  final String? code;
  final String? referrerDisplayName;
  final int? organizationId;
  final String? organizationName;
  final String? organizationShortName;
  final String? organizationLogo;
  final String? clubSlug;
  final String? referralCode;
  final String? referralToken;
  final String? referralLink;
  final int referralPoints;

  const ReferralValidationResult({
    required this.valid,
    this.message,
    this.code,
    this.referrerDisplayName,
    this.organizationId,
    this.organizationName,
    this.organizationShortName,
    this.organizationLogo,
    this.clubSlug,
    this.referralCode,
    this.referralToken,
    this.referralLink,
    this.referralPoints = 100,
  });

  factory ReferralValidationResult.fromJson(Map<String, dynamic> json) {
    return ReferralValidationResult(
      valid: json['valid'] == true,
      message: json['message']?.toString(),
      code: json['code']?.toString(),
      referrerDisplayName: json['referrer_display_name']?.toString(),
      organizationId: (json['organization_id'] as num?)?.toInt(),
      organizationName: json['organization_name']?.toString(),
      organizationShortName: json['organization_short_name']?.toString(),
      organizationLogo: json['organization_logo']?.toString(),
      clubSlug: json['club_slug']?.toString(),
      referralCode: json['referral_code']?.toString(),
      referralToken: json['referral_token']?.toString(),
      referralLink: json['referral_link']?.toString(),
      referralPoints: (json['referral_points'] as num?)?.toInt() ?? 100,
    );
  }
}

class DonationFeePreview {
  final int amountKr;
  final double netToBeneficiaryKr;
  final double totalFeeKr;
  final int estimatedPoints;

  const DonationFeePreview({
    required this.amountKr,
    required this.netToBeneficiaryKr,
    required this.totalFeeKr,
    this.estimatedPoints = 0,
  });

  factory DonationFeePreview.fromJson(Map<String, dynamic> json) {
    return DonationFeePreview(
      amountKr: (json['amount_kr'] as num?)?.toInt() ?? 0,
      netToBeneficiaryKr:
          (json['net_to_beneficiary_kr'] as num?)?.toDouble() ?? 0,
      totalFeeKr: (json['total_fee_kr'] as num?)?.toDouble() ?? 0,
      estimatedPoints: (json['estimated_points'] as num?)?.toInt() ?? 0,
    );
  }
}

class DonationSubscriptionRecord {
  final int id;
  final String status;
  final String beneficiaryType;
  final int organizationId;
  final String? organizationName;
  final int? teamId;
  final String? teamName;
  final double amountKr;
  final int currentStreakMonths;
  final String? nextChargeAt;
  final double? pendingAmountKr;

  const DonationSubscriptionRecord({
    required this.id,
    required this.status,
    required this.beneficiaryType,
    required this.organizationId,
    this.organizationName,
    this.teamId,
    this.teamName,
    required this.amountKr,
    this.currentStreakMonths = 0,
    this.nextChargeAt,
    this.pendingAmountKr,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isPaused => status == 'paused';

  bool get isManageable => isActive || isPaused;

  String get targetLabel {
    if (beneficiaryType == 'organization') {
      return organizationName ?? '';
    }
    return teamName ?? organizationName ?? '';
  }

  factory DonationSubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return DonationSubscriptionRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      beneficiaryType: json['beneficiary_type']?.toString() ?? 'team',
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      organizationName: json['organization_name']?.toString(),
      teamId: (json['team_id'] as num?)?.toInt(),
      teamName: json['team_name']?.toString(),
      amountKr: (json['amount_kr'] as num?)?.toDouble() ?? 0,
      currentStreakMonths:
          (json['current_streak_months'] as num?)?.toInt() ?? 0,
      nextChargeAt: json['next_charge_at']?.toString(),
      pendingAmountKr: (json['pending_amount_kr'] as num?)?.toDouble(),
    );
  }
}

class DonationCreateResult {
  final DonationSubscriptionRecord? subscription;
  final String? confirmationUrl;

  const DonationCreateResult({this.subscription, this.confirmationUrl});

  factory DonationCreateResult.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    final vipps = json['vipps'];
    return DonationCreateResult(
      subscription: sub is Map
          ? DonationSubscriptionRecord.fromJson(Map<String, dynamic>.from(sub))
          : null,
      confirmationUrl: vipps is Map
          ? vipps['confirmation_url']?.toString()
          : null,
    );
  }
}

/// Strip a leading Norwegian postcode from an area string.
/// "5221 Nesttun" → "Nesttun". "Bergen" → "Bergen". null → null.
String? _stripPostcode(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  final match = RegExp(r'^\d{4}\s+').firstMatch(trimmed);
  if (match != null) return trimmed.substring(match.end);
  return trimmed;
}
