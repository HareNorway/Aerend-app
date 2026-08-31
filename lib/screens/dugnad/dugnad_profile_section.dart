import 'dart:convert';

import 'package:aerend_customer/screens/campaign/campaign_my_orders_screen.dart';
import 'package:aerend_customer/screens/campaign/campaign_purchases_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../common/helpAndSupport/help_and_support.dart';
import '../../utils/utils.dart';
import '../common/account/account_detail.dart';
import '../common/account/application_setting.dart';
import '../common/signUp/sign_up.dart';
import '../common/manageAddress/manage_address.dart';
import '../common/manageAddress/manage_address_dl.dart';
import 'club_sheet.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_club_theme.dart';
import 'gamification_models.dart';
import 'dugnad_models.dart';
import 'dugnad_points_screen.dart';
import 'dugnad_points_widgets.dart';
import 'dugnad_profile_widgets.dart';
import 'dugnad_state.dart';
import '../../commonView/skeleton_loaders/dugnad_feed_skeleton.dart';
import '../../services/dugnad_data_cache.dart';
import 'donation_setup_screen.dart';
import 'dugnad_privacy_screen.dart';
import 'dugnad_notification_prefs_screen.dart';
import 'kampanje_screen.dart';
import 'leaderboard_screen.dart';
import 'points_team_picker_screen.dart';
import 'referral_share_screen.dart';
import 'season_recap_screen.dart';
import 'career_screen.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'tour/dugnad_tour_controller.dart';
import 'tour/dugnad_tour_overlay.dart';
import 'transfer_window_screen.dart';
import 'supporter_card_screen.dart';
import 'widgets/dugnad_home_anchor_card.dart';
import 'widgets/dugnad_locked_module.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/incoming_referral_banner.dart';

/// Dugnad profile content matching offers.jsx ProfileScreen layout.
class DugnadProfileSection extends StatefulWidget {
  const DugnadProfileSection({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.onLogout,
  });

  final String userName;
  final String avatarUrl;
  final VoidCallback onLogout;

  @override
  State<DugnadProfileSection> createState() => _DugnadProfileSectionState();
}

class _DugnadProfileSectionState extends State<DugnadProfileSection> {
  final DugnadDataCache _cache = DugnadDataCache.instance;
  PointsSummary? _summary;
  ReferralSummary? _referralSummary;
  GamificationConfig? _config;
  List<DugnadBadgeItem> _badges = const [];
  LeaderboardData? _leaderboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _seedFromCache();
    _load();
    DugnadState.instance.revision.addListener(_loadSilent);
  }

  void _seedFromCache() {
    final clubId = DugnadState.instance.clubId;
    final teamId = DugnadState.instance.hasPointsTeam
        ? DugnadState.instance.pointsTeamId
        : null;
    _summary = _cache.peekPointsSummary();
    _referralSummary = DugnadState.instance.hasClub
        ? _cache.peek<ReferralSummary>('referralSummary:$clubId')
        : null;
    _leaderboard = DugnadState.instance.hasClub
        ? _cache.peekLeaderboard(clubId)
        : null;
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
    if (_summary != null || career != null) {
      _applyGamificationData(
        summary: _summary,
        referral: _referralSummary,
        board: _leaderboard,
        config: config,
        career: career,
      );
      _loading = false;
    }
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_loadSilent);
    super.dispose();
  }

  void _loadSilent() {
    if (mounted) _load(forceRefresh: true);
  }

  void _applyGamificationData({
    PointsSummary? summary,
    ReferralSummary? referral,
    LeaderboardData? board,
    GamificationConfig? config,
    GamificationCareer? career,
  }) {
    final hasSub = dugnadHasSubscriptionFromCareer(career);

    LeaderboardTeamRow? teamRow;
    if (board != null && DugnadState.instance.hasPointsTeam) {
      for (final row in board.teams) {
        if (row.teamId == DugnadState.instance.pointsTeamId) {
          teamRow = row;
          break;
        }
      }
    }

    final sections = buildDugnadBadgeSections(
      catalog: config?.stoBadges,
      permanentEarned: career?.permanentBadges ?? const [],
      seasonalEarned: career?.seasonalBadges ?? const [],
      seasonLabel: career?.activeSeason?.label,
      progress: DugnadBadgeProgressContext(
        referrals: referral?.convertedCount ?? 0,
        hasSub: hasSub,
        teamRank: teamRow?.rank,
        metricProgress: dugnadMergedBadgeProgress(career: career),
      ),
    );

    _summary = summary ?? _summary;
    _referralSummary = referral ?? _referralSummary;
    _leaderboard = board ?? _leaderboard;
    if (config != null) _config = config;
    _badges = sections.all.isNotEmpty
        ? sections.all
        : buildDugnadBadges(
            referrals: referral?.convertedCount ?? 0,
            subMonths: 0,
            hasSub: hasSub,
          );
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!isLoggedIn()) {
      _seedFromCache();
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final clubId = DugnadState.instance.clubId;
      final hasClub = DugnadState.instance.hasClub;
      final teamId = DugnadState.instance.hasPointsTeam
          ? DugnadState.instance.pointsTeamId
          : null;
      final hasCachedContent = _summary != null;
      if (mounted && !hasCachedContent) {
        setState(() => _loading = true);
      }

      final results = await Future.wait<dynamic>([
        _cache.getPointsSummary(forceRefresh: forceRefresh),
        hasClub
            ? _cache.getReferralSummary(
                organizationId: clubId,
                forceRefresh: forceRefresh,
              )
            : Future.value(null),
        hasClub
            ? _cache.getLeaderboard(clubId, forceRefresh: forceRefresh)
            : Future.value(null),
        hasClub
            ? _cache.getGamificationConfig(
                organizationId: clubId,
                teamId: teamId,
                forceRefresh: forceRefresh,
              )
            : Future.value(null),
        hasClub
            ? _cache.getGamificationCareer(
                organizationId: clubId,
                teamId: teamId,
                forceRefresh: forceRefresh,
              )
            : Future.value(null),
      ]);

      final summary = results[0] as PointsSummary?;
      final referral = results[1] as ReferralSummary?;
      final board = results[2] as LeaderboardData?;
      final config = results[3] as GamificationConfig?;
      final career = results[4] as GamificationCareer?;
      if (!mounted) return;

      setState(() {
        _applyGamificationData(
          summary: summary,
          referral: referral,
          board: board,
          config: config,
          career: career,
        );
        _loading = false;
      });
    } catch (_) {
      // Never leave Profile stuck on a blank loading state (e.g. HTTP 401
      // from gamification endpoints when the session token mismatches).
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTeam() async {
    if (!DugnadState.instance.hasClub) return;
    await openPointsTeamPicker(context);
    if (mounted) {
      setState(() {});
      _load();
    }
  }

  LeaderboardTeamRow? _selectedTeamRow() {
    final board = _leaderboard;
    if (board == null || !DugnadState.instance.hasPointsTeam) return null;
    for (final row in board.teams) {
      if (row.teamId == DugnadState.instance.pointsTeamId) return row;
    }
    return null;
  }

  Future<void> _switchClub() async {
    final ds = DugnadState.instance;
    final club = await showClubSheet(
      context,
      currentClub: ds.hasClub
          ? ClubListItem(
              id: ds.clubId,
              name: ds.clubName,
              shortName: ds.clubShortName.isEmpty ? null : ds.clubShortName,
              logo: ds.clubLogo.isEmpty ? null : ds.clubLogo,
              area: ds.clubArea.isEmpty ? null : ds.clubArea,
              portalThemeColor: ds.clubPortalThemeColor.isEmpty
                  ? null
                  : ds.clubPortalThemeColor,
              portalBackgroundColor: ds.clubPortalBackgroundColor.isEmpty
                  ? null
                  : ds.clubPortalBackgroundColor,
            )
          : null,
    );
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
      setState(() {});
      _load();
    }
  }

  /// Profile "Change team in Club" — skip club select, open current-club team picker.
  Future<void> _switchClubAndTeam() async {
    if (!DugnadState.instance.hasClub) return;
    final changed = await openPointsTeamPicker(
      context,
      mode: PointsTeamPickerMode.switchTeam,
    );
    if (!mounted) return;
    if (changed == true) {
      setState(() {});
      _load();
    }
  }

  Future<void> _openCreateAccount() async {
    HapticFeedback.lightImpact();
    await openScreenWithResult(context, const SignUp(returnOnSuccess: true));
    if (mounted) setState(() {});
  }

  Widget _lockBrowseSection(String guestLabel, String clubLabel, Widget child) {
    final hasClub = DugnadState.instance.hasClub;
    final locked = !hasClub || !isLoggedIn();
    if (!locked) return child;
    return DugnadLockedModule(
      locked: true,
      label: hasClub ? guestLabel : clubLabel,
      onUnlock: hasClub ? _openCreateAccount : _switchClub,
      hBleed: context.dp(18),
      child: child,
    );
  }

  void _openPoints() => openScreen(context, const DugnadPointsScreen());

  void _openPurchases() {
    openScreen(context, const CampaignPurchasesScreen());
  }

  void _openLeaderboard() {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != null) {
      home.switchToTab(HomeMainV1State.dugnadLeaderboardTabIndex);
      return;
    }
    openScreen(context, const LeaderboardScreen());
  }

  /// "Take the tour again" — starts the walkthrough directly (no prompt card).
  /// Switches to the club-home tab first, since the tour spotlights DGHome.
  Future<void> _startTourAgain() async {
    // Instant jump: animateToPage is 1s, and resolveSteps drops any club-home
    // target that is not laid out yet → "1 / 4" (welcome + sto + form + done).
    context
        .findAncestorStateOfType<HomeMainV1State>()
        ?.switchToTab(0, animate: false);
    final knownAbsent = DugnadTourController.computeKnownAbsent(
      hasEarnedBadges: _badges.any((b) => b.earned),
    );
    // DGHome remounts after leaving profile — wait until the points card key
    // is attached before resolving the live step list.
    await DugnadTourController.waitUntilClubHomeReady();
    if (!mounted) return;
    final controller = DugnadTourController();
    DugnadTourOverlay.show(controller);
    // Same mount-before-start ordering as DGHome._launchTour.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isFinished) return;
      controller.start(knownAbsent: knownAbsent);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!DugnadState.instance.hasClub) {
      return DugnadClubThemeScope(
        palette: DugnadClubThemePalette.reenPreClub,
        child: _buildContent(context),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final summary = _summary;
    final ds = DugnadState.instance;
    final guest = !isLoggedIn();
    final clubShort = ds.clubShortName.isNotEmpty
        ? ds.clubShortName
        : DugnadClubBranding.compactName();
    final teamRow = _selectedTeamRow();
    final hasTeam = ds.hasPointsTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (guest) ...[
          _GuestProfileCard(
            onTap: _openCreateAccount,
          ),
          SizedBox(height: context.dp(16)),
          _GuestCreateAccountCta(
            hasClub: ds.hasClub,
            onTap: ds.hasClub ? _openCreateAccount : _switchClub,
          ),
        ] else
          DugnadProfileHead(
            name: widget.userName,
            email: prefGetString(prefEmail),
            avatarUrl: widget.avatarUrl,
            onEdit: () => openScreenWithResult(context, const AccountDetail()),
          ),
        if (!guest && !ds.hasClub) ...[
          SizedBox(height: context.dp(18)),
          _GuestCreateAccountCta(
            hasClub: false,
            onTap: _switchClub,
          ),
        ],
        if (_loading && summary == null) ...[
          SizedBox(height: context.dp(12)),
          LinearProgressIndicator(
            minHeight: 2,
            color: context.dugnadTheme.primary,
            backgroundColor:
                context.dugnadTheme.primary.withValues(alpha: 0.12),
          ),
        ],
        SizedBox(height: context.dp(18)),
        // Design `.dg-prof-tour` — app walkthrough entry (offers.jsx).
        if (!guest) ...[
          DugnadProfileTourCard(onTap: _startTourAgain),
          SizedBox(height: context.dp(18)),
          IncomingReferralBanner(summary: _referralSummary),
        ],
        DugnadSectionLabel(languages.dugnadYourPoints),
        SizedBox(height: context.dp(8)),
        _lockBrowseSection(
          languages.dugnadGateCollectPoints,
          languages.dugnadGateChooseClubCollectPoints,
          !ds.hasClub
              ? DugnadHomeAnchorCard(
                  summary: null,
                  config: _config,
                  teamRank: null,
                  teamTotal: _leaderboard?.teams.length,
                  isGuest: false,
                  previewMetal: 'solv',
                  onOpenPoints: _switchClub,
                  onOpenStoCard: _switchClub,
                  onConnectTeam: _switchClub,
                  onOpenLeaderboard: _openLeaderboard,
                  showSeasonCarryover: false,
                )
              : guest
                  ? DugnadHomeAnchorCard(
                      summary: summary,
                      config: _config,
                      teamRank: teamRow?.rank,
                      teamTotal: _leaderboard?.teams.length,
                      isGuest: true,
                      onOpenPoints: _openPoints,
                      onOpenStoCard: () =>
                          openScreen(context, const SupporterCardScreen()),
                      onConnectTeam: _pickTeam,
                      onOpenLeaderboard: _openLeaderboard,
                      showSeasonCarryover: false,
                    )
                  : summary == null
                      ? const DugnadAnchorCardSkeleton()
                      : DugnadHomeAnchorCard(
                          summary: summary,
                          config: _config,
                          teamRank: teamRow?.rank,
                          teamTotal: _leaderboard?.teams.length,
                          onOpenPoints: _openPoints,
                          onOpenStoCard: () =>
                              openScreen(context, const SupporterCardScreen()),
                          onConnectTeam: _pickTeam,
                          onOpenLeaderboard: _openLeaderboard,
                          showSeasonCarryover: false,
                        ),
        ),
        if (!guest) ...[
          SizedBox(height: context.dp(18)),
          DugnadProfilePurchasesCard(onTap: _openPurchases),
        ],
        SizedBox(height: context.dp(18)),
        DugnadSectionLabel(languages.dugnadEarnMorePoints),
        SizedBox(height: context.dp(8)),
        _lockBrowseSection(
          languages.dugnadGateBuyAndEarn,
          languages.dugnadGateChooseClubBuyAndEarn,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DugnadEarnPointsRow(
                icon: Icons.share_rounded,
                title: languages.dugnadReferFriendsToClub(clubShort),
                subtitle: languages.dugnadReferFriendsEarnSub,
                points: 100,
                strong: true,
                onTap: () => openScreen(context, const ReferralShareScreen()),
              ),
              DugnadEarnPointsRow(
                iconWidget: SvgPicture.asset(
                  'assets/svgs/menu/box.svg',
                  width: context.dp(18),
                  height: context.dp(18),
                  colorFilter: ColorFilter.mode(
                    context.dugnadTheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                title: languages.dugnadBuyFoodbox,
                subtitle: languages.dugnadBuyFoodboxSub,
                points: 50,
                onTap: () => openScreen(context, const KampanjeScreen()),
              ),
              DugnadEarnPointsRow(
                icon: Icons.favorite_rounded,
                title: languages.dugnadSupportRegularly,
                subtitle: languages.dugnadSupportRegularlySub,
                points: 20,
                onTap: () => openScreen(context, const DonationSetupScreen()),
              ),
            ],
          ),
        ),
        SizedBox(height: context.dp(18)),
        DugnadSectionLabel(languages.dugnadYourBadges),
        SizedBox(height: context.dp(8)),
        _lockBrowseSection(
          languages.dugnadGateUnlockBadges,
          languages.dugnadGateChooseClubBadges,
          DugnadProfileBadgesPreview(badges: _badges, onTap: _openPoints),
        ),
        SizedBox(height: context.dp(18)),
        DugnadSectionLabel(languages.dugnadMyClub),
        DugnadProfileClubCard(
          clubName: ds.hasClub
              ? DugnadClubBranding.fullName()
              : languages.dugnadNoClubSelected,
          clubArea: ds.clubArea,
          clubLogo: ds.clubLogo.isEmpty ? null : ds.clubLogo,
          onSwitch: _switchClub,
        ),
        SizedBox(height: context.dp(18)),
        _lockBrowseSection(
          languages.dugnadGateCompete,
          languages.dugnadGateChooseClubCompete,
          DugnadProfileChangeClubTeamCard(onTap: _switchClubAndTeam),
        ),
        SizedBox(height: context.dp(18)),
        DugnadSectionLabel(languages.dugnadLeaderboardSectionTitle),
        SizedBox(height: context.dp(8)),
        _lockBrowseSection(
          languages.dugnadGateCompete,
          languages.dugnadGateChooseClubCompete,
          DugnadProfileListCard(
            children: [
              DugnadProfileListRow(
                title: hasTeam && teamRow != null && teamRow.rank > 0
                    ? languages.dugnadLeaderboardTeamSelectedTitle(
                        ds.pointsTeamName,
                        teamRow.rank,
                      )
                    : languages.dugnadLeaderboardTitle,
                subtitle: hasTeam && teamRow != null
                    ? languages.dugnadLeaderboardTeamSelectedSub
                    : languages.dugnadLeaderboardProfileSubtitle,
                icon: Icons.star_rounded,
                amberIcon: true,
                onTap: hasTeam
                    ? () => openScreen(context, const LeaderboardScreen())
                    : _pickTeam,
              ),
              const DugnadProfileListDivider(),
              DugnadProfileListRow(
                title: languages.dugnadSupporterCardTitle,
                subtitle: languages.dugnadSupporterCardProfileSub,
                icon: Icons.shield_outlined,
                onTap: () => openScreen(context, const SupporterCardScreen()),
              ),
              const DugnadProfileListDivider(),
              DugnadProfileListRow(
                title: languages.dugnadSeasonRecapTitle,
                subtitle: languages.dugnadSeasonRecapSub,
                icon: Icons.flag_outlined,
                onTap: () => openScreen(context, const SeasonRecapScreen()),
              ),
              const DugnadProfileListDivider(),
              DugnadProfileListRow(
                title: languages.dugnadTransitionWindowTitle,
                subtitle: languages.dugnadTransitionWindowSub,
                icon: Icons.autorenew_rounded,
                onTap: () => openScreen(context, const TransferWindowScreen()),
              ),
              const DugnadProfileListDivider(),
              DugnadProfileListRow(
                title: languages.dugnadCareerTitle,
                subtitle: languages.dugnadCareerSub,
                icon: Icons.science_outlined,
                onTap: () => openScreen(context, const CareerScreen()),
              ),
            ],
          ),
        ),
        SizedBox(height: context.dp(18)),
        DugnadSectionLabel(languages.dugnadProfileAccountSection),
        SizedBox(height: context.dp(8)),
        _lockBrowseSection(
          languages.dugnadGateSeeAccountAndPayments,
          languages.dugnadGateChooseClubAccount,
          DugnadProfileAccountSection(onAddressRefresh: () => setState(() {})),
        ),
        if (!guest) ...[
          SizedBox(height: context.dp(14)),
          DugnadProfileLogoutButton(onTap: widget.onLogout),
        ],
      ],
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(18)),
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(60),
              height: context.dp(60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: theme.primary,
                size: context.dp(30),
              ),
            ),
            SizedBox(width: context.dp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          languages.dugnadProfileGuestTitle,
                          style: aeH3(color: theme.text).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: context.dp(8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(10),
                          vertical: context.dp(4),
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          languages.dugnadProfileGuestBadge,
                          style: aeLabel(color: theme.primary)
                              .copyWith(fontSize: 11, fontWeight: FontWeight.w800)
                              .dp(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dp(6)),
                  Text(
                    languages.dugnadProfileGuestBody,
                    style: aeBody(color: ScSaasThemeTokens.gray500)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.35,
                        )
                        .dp(context),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(8)),
            Icon(
              Icons.chevron_right_rounded,
              color: ScSaasThemeTokens.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCreateAccountCta extends StatelessWidget {
  const _GuestCreateAccountCta({
    required this.onTap,
    this.hasClub = true,
  });

  final VoidCallback onTap;
  final bool hasClub;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(16)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary,
              theme.primaryHover,
            ],
          ),
          borderRadius: BorderRadius.circular(context.dp(18)),
          boxShadow: theme.shadowButton,
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(44),
              height: context.dp(44),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(context.dp(13)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: context.dp(22),
              ),
            ),
            SizedBox(width: context.dp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasClub
                        ? languages.dugnadProfileGuestCtaTitle
                        : languages.dugnadChooseYourClubTitle,
                    style: aeH3(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 16.5)
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    hasClub
                        ? languages.dugnadProfileGuestCtaBody
                        : languages.dugnadChooseYourClubBody,
                    style: aeBody(color: Colors.white.withValues(alpha: 0.96))
                        .copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.28,
                        )
                        .dp(context),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(8)),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// KONTO rows — kept items + design extras.
class DugnadProfileAccountSection extends StatelessWidget {
  const DugnadProfileAccountSection({
    super.key,
    required this.onAddressRefresh,
  });

  final VoidCallback onAddressRefresh;

  String _deliveryAddressLine() {
    try {
      final raw = prefGetString(prefNewDeliveryAddress).trim();
      if (raw.isEmpty) return languages.addDeliveryAddress;
      if (raw.startsWith('{')) {
        return AddressListItem.fromJson(jsonDecode(raw)).address.trim();
      }
      return raw;
    } catch (_) {
      return languages.addDeliveryAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DugnadProfileListCard(
      children: [
        // Campaign order history (matkasse purchases).
        DugnadProfileListRow(
          title: languages.orderHistory,
          iconWidget: SvgPicture.asset(
            'assets/svgs/order_history.svg',
            width: context.dp(18),
            height: context.dp(18),
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              context.dugnadTheme.primary,
              BlendMode.srcIn,
            ),
          ),
          onTap: () => openScreenWithResult(
            context,
            const CampaignMyOrdersScreen(),
          ),
        ),
        const DugnadProfileListDivider(),
        DugnadProfileListRow(
          title: languages.dugnadCustomerSupport,
          icon: Icons.headset_mic_outlined,
          onTap: () => openScreenWithResult(context, const HelpAndSupport()),
        ),
        const DugnadProfileListDivider(),
        DugnadProfileListRow(
          title: languages.dugnadSettings,
          icon: Icons.settings_outlined,
          onTap: () =>
              openScreenWithResult(context, const ApplicationSetting()),
        ),
        const DugnadProfileListDivider(),
        DugnadProfileListRow(
          title: languages.deliveryAddress,
          subtitle: _deliveryAddressLine(),
          icon: Icons.location_on_outlined,
          onTap: () async {
            await openScreenWithResult(context, const ManageAddress());
            onAddressRefresh();
          },
        ),
        const DugnadProfileListDivider(),
        DugnadProfileListRow(
          title: 'Varslingsinnstillinger',
          subtitle: 'Poeng, kampanjer, sosialt og system',
          icon: Icons.notifications_none_rounded,
          onTap: () =>
              openScreen(context, const DugnadNotificationPrefsScreen()),
        ),
        const DugnadProfileListDivider(),
        DugnadProfileListRow(
          title: languages.dugnadVisibilityTitle,
          subtitle: languages.dugnadVisibilitySub,
          icon: Icons.shield_outlined,
          onTap: () => openScreen(context, const DugnadPrivacyScreen()),
        ),
      ],
    );
  }
}
