import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../services/dugnad_data_cache.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_points_widgets.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'donation_setup_screen.dart';
import 'kampanje_screen.dart';
import 'points_history_screen.dart';
import 'points_team_picker_screen.dart';
import 'referral_share_screen.dart';
import 'supporter_card_screen.dart';
import 'tier_level_up_screen.dart';
import 'gamification_models.dart';
import 'dugnad_sto_source_breakdown.dart';
import 'dugnad_sto_utils.dart';
import 'dugnad_form_utils.dart';
import 'dugnad_formen_screen.dart';
import 'dugnad_missions_screen.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_rise_in.dart';

/// Full "Dine poeng" screen — tier ladder, team, badges, earn paths (prototype: YourPointsScreen).
class DugnadPointsScreen extends StatefulWidget {
  const DugnadPointsScreen({super.key});

  @override
  State<DugnadPointsScreen> createState() => _DugnadPointsScreenState();
}

class _DugnadPointsScreenState extends State<DugnadPointsScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final DugnadDataCache _cache = DugnadDataCache.instance;
  PointsSummary? _summary;
  LeaderboardData? _leaderboard;
  List<DugnadBadgeItem> _badges = const [];
  DugnadBadgeSections _badgeSections = const DugnadBadgeSections(
    permanent: [],
    seasonal: [],
  );
  StoSourcePoints? _stoBreakdown;
  GamificationConfig? _gamificationConfig;
  GamificationProgress? _gamificationProgress;
  bool? _isTeamCaptain;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _seedFromCache();
    _load();
  }

  void _seedFromCache() {
    final clubId = DugnadState.instance.clubId;
    final teamId = DugnadState.instance.hasPointsTeam
        ? DugnadState.instance.pointsTeamId
        : null;
    final summary = _cache.peekPointsSummary();
    final config = DugnadState.instance.hasClub
        ? _cache.peek<GamificationConfig>(
            DugnadDataCache.gamificationConfigKey(clubId),
          )
        : null;
    final career = DugnadState.instance.hasClub
        ? _cache.peek<GamificationCareer>(
            DugnadDataCache.gamificationCareerKey(clubId, teamId),
          )
        : null;
    final referral = DugnadState.instance.hasClub
        ? _cache.peek<ReferralSummary>('referralSummary:$clubId')
        : null;
    final board = DugnadState.instance.hasClub
        ? _cache.peekLeaderboard(clubId)
        : null;

    if (summary == null) return;

    _applyLoadedData(
      summary: summary,
      referral: referral,
      board: board,
      gamificationConfig: config,
      gamificationCareer: career,
    );
    _loading = false;
  }

  void _applyLoadedData({
    required PointsSummary? summary,
    ReferralSummary? referral,
    LeaderboardData? board,
    GamificationConfig? gamificationConfig,
    GamificationCareer? gamificationCareer,
    GamificationProgress? gamificationProgress,
    bool? isTeamCaptain,
    StoSourcePoints? stoBreakdown,
  }) {
    final hasSub = dugnadHasSubscriptionFromCareer(gamificationCareer);

    LeaderboardTeamRow? teamRow;
    if (board != null && DugnadState.instance.hasPointsTeam) {
      for (final row in board.teams) {
        if (row.teamId == DugnadState.instance.pointsTeamId) {
          teamRow = row;
          break;
        }
      }
    }
    final completedWeekly = gamificationProgress?.weeklyChallenges
            .where((c) => c.completed)
            .length ??
        0;
    final badgeSections = buildDugnadBadgeSections(
      catalog: gamificationConfig?.stoBadges,
      permanentEarned: gamificationCareer?.permanentBadges ?? const [],
      seasonalEarned: gamificationCareer?.seasonalBadges ?? const [],
      seasonLabel: gamificationCareer?.activeSeason?.label ??
          gamificationProgress?.activeSeason?.label,
      progress: DugnadBadgeProgressContext(
        referrals: referral?.convertedCount ?? 0,
        hasSub: hasSub,
        teamRank: teamRow?.rank,
        completedWeeklyChallenges: completedWeekly,
        streakWeeks: gamificationProgress?.streakWeeks ?? 0,
        metricProgress: dugnadMergedBadgeProgress(
          career: gamificationCareer,
          progress: gamificationProgress,
        ),
      ),
    );

    _summary = summary ?? _summary;
    _leaderboard = board ?? _leaderboard;
    _badgeSections = badgeSections;
    _badges = badgeSections.all.isNotEmpty
        ? badgeSections.all
        : buildDugnadBadges(
            referrals: referral?.convertedCount ?? 0,
            subMonths: 0,
            hasSub: hasSub,
          );
    if (stoBreakdown != null) _stoBreakdown = stoBreakdown;
    if (gamificationConfig != null) _gamificationConfig = gamificationConfig;
    if (gamificationProgress != null) {
      _gamificationProgress = gamificationProgress;
    }
    if (isTeamCaptain != null) _isTeamCaptain = isTeamCaptain;
  }

  Future<void> _load() async {
    final hasCachedSummary = _summary != null;
    if (mounted && !hasCachedSummary) {
      setState(() => _loading = true);
    }

    try {
      final clubId = DugnadState.instance.clubId;
      final hasClub = DugnadState.instance.hasClub;
      final hasTeam = DugnadState.instance.hasPointsTeam;
      final teamId = hasTeam ? DugnadState.instance.pointsTeamId : null;

      final results = await Future.wait<dynamic>([
        _cache.getPointsSummary(),
        hasClub
            ? _cache.getReferralSummary(organizationId: clubId)
            : Future.value(null),
        hasClub ? _cache.getLeaderboard(clubId) : Future.value(null),
        hasClub
            ? _cache.getGamificationConfig(
                organizationId: clubId,
                teamId: teamId,
              )
            : Future.value(null),
        hasClub
            ? _cache.getGamificationCareer(
                organizationId: clubId,
                teamId: teamId,
              )
            : Future.value(null),
        hasClub && hasTeam
            ? _repo.getGamificationProgress(
                organizationId: clubId,
                teamId: teamId!,
              )
            : Future.value(null),
        hasClub && hasTeam
            ? _repo.getLeaderboardScorers(
                clubId,
                tab: 'toppscorer',
                teamId: teamId!,
              )
            : Future.value(null),
      ]);

      final summary = results[0] as PointsSummary?;
      final referral = results[1] as ReferralSummary?;
      final board = results[2] as LeaderboardData?;
      final gamificationConfig = results[3] as GamificationConfig?;
      final gamificationCareer = results[4] as GamificationCareer?;
      final gamificationProgress = results[5] as GamificationProgress?;
      final scorers = results[6] as LeaderboardScorersData?;

      bool? isTeamCaptain;
      if (scorers != null) {
        for (final row in scorers.scorers) {
          if (row.isViewer) {
            isTeamCaptain = row.rank == 1;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _applyLoadedData(
          summary: summary,
          referral: referral,
          board: board,
          gamificationConfig: gamificationConfig,
          gamificationCareer: gamificationCareer,
          gamificationProgress: gamificationProgress,
          isTeamCaptain: isTeamCaptain,
        );
        _loading = false;
      });

      if (summary != null) {
        unawaited(_loadStoBreakdown(summary));
        await _maybeShowLevelUp(summary);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStoBreakdown(PointsSummary summary) async {
    try {
      final ledgerEntries = await _repo.getAllPointsLedgerEntries();
      if (!mounted) return;
      final breakdown = computeStoSourceBreakdown(
        entries: ledgerEntries,
        seasonPoints: summary.seasonPoints,
        seasonStartsAt: summary.seasonStartsAt,
        seasonEndsAt: summary.seasonEndsAt,
      );
      if (!mounted) return;
      setState(() => _stoBreakdown = breakdown);
    } catch (_) {}
  }

  Future<void> _maybeShowLevelUp(PointsSummary summary) async {
    final storageKey = '${prefDugnadLastSeenTierKey}_${dugnadLastTierPrefKey()}';
    final stored = prefGetString(storageKey);
    final tiers = summary.metalTiers;
    final currentIdx = dugnadTierIndexForPoints(tiers, summary.lifetimePoints);
    final currentTier = summary.currentTier;
    if (currentTier == null) return;

    if (stored.isEmpty) {
      await prefSetString(storageKey, currentTier.key);
      return;
    }

    final storedIdx = tiers.indexWhere((t) => t.key == stored);
    if (storedIdx >= 0 && currentIdx > storedIdx && mounted) {
      final fromTier = tiers[storedIdx];
      final stoTiers = _gamificationConfig?.stoTierThresholds ?? const [];
      await TierLevelUpScreen.show(
        context,
        fromTier: fromTier,
        toTier: currentTier,
        fromStoRating: dugnadTierStoRatingForMetal(fromTier.metal, stoTiers),
        toStoRating: summary.stoRating,
        points: summary.lifetimePoints,
        displayName: summary.publicDisplayName.trim().isNotEmpty
            ? summary.publicDisplayName.trim()
            : prefGetString(prefUserName),
        purchases: summary.actionCounts.campaignPurchases,
        referrals: summary.actionCounts.referralConversions,
        badges: _badges.where((b) => b.earned).take(3).toList(),
        formStatus: _gamificationProgress != null
            ? dugnadFormStatusFromProgress(_gamificationProgress!)
            : null,
        nextTier: summary.nextTier,
      );
    }
    await prefSetString(storageKey, currentTier.key);
  }

  Future<void> _pickTeam() async {
    if (!DugnadState.instance.hasClub) return;
    await openPointsTeamPicker(context);
    if (mounted) await _load();
  }

  LeaderboardTeamRow? _selectedTeamRow() {
    final board = _leaderboard;
    if (board == null || !DugnadState.instance.hasPointsTeam) return null;
    for (final row in board.teams) {
      if (row.teamId == DugnadState.instance.pointsTeamId) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubLogo =
        DugnadState.instance.clubLogo.isEmpty ? null : DugnadState.instance.clubLogo;

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: context.aeTheme.primary,
        body: AeScrollBody(
                hero: AeHero(
                  clubName: clubName,
                  clubLogo: clubLogo,
                  title: languages.dugnadYourPoints,
                  onBack: () => Navigator.of(context).pop(),
                ),
                bottomPadding: 100,
                itemGap: 14,
                topPadding: 18,
                feedRadius: 22,
                overlap: 12,
                children: _loading && _summary == null
                    ? const [DugnadPointsFeedSkeleton()]
                    : _buildFeed(),
              ),
      ),
    );
  }

  List<Widget> _buildFeed() {
    final summary = _summary;
    if (summary == null) {
      return [
        Text(
          languages.dugnadPointsHistoryEmpty,
          style: aeBody(color: ScSaasThemeTokens.gray500),
          textAlign: TextAlign.center,
        ),
      ];
    }

    dugnadApplyMetalColorOverrides(
      config: _gamificationConfig,
      summary: summary,
    );
    final tiers = summary.metalTiers.isNotEmpty
        ? summary.metalTiers
        : [
            if (summary.currentTier != null) summary.currentTier!,
          ];
    final currentIdx =
        dugnadTierIndexForPoints(tiers, summary.lifetimePoints);
    final displayTier = tiers[currentIdx.clamp(0, tiers.length - 1)];
    final nextTier = currentIdx + 1 < tiers.length
        ? tiers[currentIdx + 1]
        : null;
    final displayPoints = summary.lifetimePoints;
    var progress = 100;
    var pointsToNext = 0;
    if (nextTier != null) {
      final span = nextTier.minPoints - displayTier.minPoints;
      progress = span > 0
          ? (((displayPoints - displayTier.minPoints) / span) * 100).round()
          : 0;
      pointsToNext = max(0, nextTier.minPoints - displayPoints);
    }

    final ds = DugnadState.instance;
    final teamRow = _selectedTeamRow();
    final stoTiers = _gamificationConfig?.stoTierThresholds ?? const [];
    final displayStoRating = summary.stoRating;
    final stoBreakdown = _stoBreakdown ??
        computeStoSourceBreakdown(
          entries: const [],
          seasonPoints: summary.seasonPoints,
        );

    return [
      _rise('hero', 120, DugnadLevelHeroCard(
        points: displayPoints,
        tier: displayTier,
        nextTier: nextTier,
        progressPercent: progress,
        pointsToNext: pointsToNext,
        tierCount: tiers.length,
        activeTierIndex: currentIdx,
        stoRating: displayStoRating,
        nextTierStoRating: nextTier != null
            ? dugnadStoRatingAtNextMetalTier(
                nextTier: nextTier,
                config: _gamificationConfig,
              )
            : null,
        config: _gamificationConfig,
      )),
      _rise('ladder', 190, DugnadLevelLadder(
        tiers: tiers,
        previewIndex: currentIdx,
        currentTierIndex: currentIdx,
        onPreview: (_) {},
        actualStoRating: summary.stoRating,
        isPreviewing: false,
        stoTierThresholds: stoTiers,
        config: _gamificationConfig,
      )),
      if (stoBreakdown.seasonTotal > 0)
        _rise('stoBreakdown', 260, DugnadStoSourceBreakdown(
          breakdown: stoBreakdown,
          stoRating: displayStoRating,
          earnedBadgeCount: _badges.where((b) => b.earned).length,
        )),
      _rise('cardPillar', 330, DugnadStoCardPillarEntry(
        metal: displayTier.metal,
        stoRating: displayStoRating,
        tierLabel: dugnadMetalTierLabel(displayTier, config: _gamificationConfig),
        onTap: () => openScreen(context, const SupporterCardScreen()),
      )),
      _rise('teamSection', 400, AeSectionBlock(
        label: languages.dugnadYourTeam,
        children: [
          DugnadTeamSectionCard(
            hasTeam: ds.hasPointsTeam,
            teamName: ds.pointsTeamName,
            teamRank: teamRow?.rank,
            teamTotal: _leaderboard?.teams.length,
            onTap: _pickTeam,
          ),
          if (_gamificationProgress != null &&
              !_gamificationProgress!.teamRequired) ...[
            SizedBox(height: context.dp(9)),
            DugnadFormEntryCard(
              status: dugnadFormStatusFromProgress(
                _gamificationProgress!,
                warningThreshold: _gamificationConfig?.modules?.form
                        ?.warningThreshold ??
                    55,
              ),
              onTap: () =>
                  openScreen(context, const DugnadFormenScreen()),
            ),
            SizedBox(height: context.dp(9)),
            DugnadMissionsEntryCard(
              onTap: () =>
                  openScreen(context, const DugnadMissionsScreen()),
            ),
          ],
          if (ds.hasPointsTeam && _isTeamCaptain != null) ...[
            SizedBox(height: context.dp(9)),
            if (_isTeamCaptain!)
              DugnadKapteinChip(teamName: ds.pointsTeamName)
            else
              DugnadPlayerChip(teamName: ds.pointsTeamName),
          ],
        ],
      ), duration: 550),
      _rise('badgesSection', 450, AeSectionBlock(
        label: languages.dugnadYourBadges,
        children: [
          DugnadDineMerker(sections: _badgeSections),
        ],
      ), duration: 550),
      _rise('earnSection', 500, AeSectionBlock(
        label: languages.dugnadHowYouEarnPoints,
        children: [
          DugnadEarnPointsRow(
            icon: Icons.share_rounded,
            title: languages.dugnadReferFriend,
            subtitle: languages.dugnadReferFriendSub,
            points: 100,
            strong: true,
            onTap: () => openScreen(context, const ReferralShareScreen()),
          ),
          DugnadEarnPointsRow(
            icon: Icons.inventory_2_outlined,
            title: languages.dugnadBuyCampaign,
            subtitle: languages.dugnadBuyCampaignSub,
            points: 50,
            onTap: () => openScreen(context, const KampanjeScreen()),
          ),
          DugnadEarnPointsRow(
            icon: Icons.favorite_rounded,
            title: languages.dugnadRegularSupport,
            subtitle: languages.dugnadRegularSupportSub,
            points: 20,
            onTap: () => openScreen(context, const DonationSetupScreen()),
          ),
          SizedBox(height: context.dp(8)),
          Center(
            child: TextButton(
              onPressed: () => openScreen(context, const PointsHistoryScreen()),
              child: Text(languages.dugnadPointsHistoryLink),
            ),
          ),
        ],
      ), duration: 550),
    ];
  }

  /// Entrance stagger wrapper — keyed so that later stream/cache-driven
  /// rebuilds (and the optional STO-breakdown block appearing) reuse the
  /// existing animation state instead of replaying it.
  Widget _rise(String id, int delayMs, Widget child, {int duration = 600}) {
    return AeRiseIn(
      key: ValueKey('pointsRise-$id'),
      delay: Duration(milliseconds: delayMs),
      duration: Duration(milliseconds: duration),
      child: child,
    );
  }
}
