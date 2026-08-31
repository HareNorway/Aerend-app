import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_feed_skeleton.dart';
import '../../commonView/surface_decorations.dart';
import '../../services/dugnad_data_cache.dart';
import '../../commonView/circle_nav_bar.dart';
import '../../theme/design_scale.dart';
import '../../theme/reen_pre_club_theme.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../common/signUp/sign_up.dart';
import '../common/manageAddress/manage_address_dl.dart';
import 'widgets/dugnad_address_drawer.dart';
import '../deliveryService/storeDetail/store_detail.dart';
import 'club_crest.dart';
import 'celebration_debug_flags.dart';
import 'club_sheet.dart';
import 'dugnad_celebration_orchestrator.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_state.dart';
import 'leaderboard_screen.dart';
import 'referral_share_screen.dart';
import 'membership_sheet.dart';
import 'widgets/dugnad_bell_button.dart';
import 'dugnad_points_screen.dart';
import 'points_team_picker_screen.dart';
import 'supporter_card_screen.dart';
import 'donation_flow.dart';
import 'dugnad_missions_screen.dart';
import 'transfer_window_screen.dart';
import 'gamification_models.dart';
import 'shop/club_shop_screen.dart';
import 'widgets/dugnad_campaign_carousel.dart';
import 'widgets/dugnad_club_shop_entry.dart';
import 'widgets/dugnad_earn_sheet.dart';
import 'widgets/dugnad_feed_entry_banner.dart';
import 'widgets/dugnad_home_anchor_card.dart';
import 'widgets/dugnad_choose_club_widgets.dart';
import 'widgets/dugnad_locked_module.dart';
import 'widgets/dugnad_rise_in.dart';
import 'widgets/dugnad_referral_promo_sheet.dart';
import 'widgets/dugnad_rounded_feed_sheet.dart';
import 'widgets/dugnad_season_finale_card.dart';
import 'widgets/celebration_debug_panel.dart';
import 'widgets/incoming_referral_banner.dart';
import 'tour/dugnad_tour_controller.dart';
import 'tour/dugnad_tour_keys.dart';
import 'tour/dugnad_tour_overlay.dart';
import 'tour/dugnad_tour_prompt.dart';

/// Dugnad home screen — index 0 when dugnad mode is active.
///
/// Design spec: dugnad/club-select.jsx → DGClubHome + dugnad/dugnad.css.
class DGHome extends StatefulWidget {
  const DGHome({super.key});

  @override
  State<DGHome> createState() => DGHomeState();
}

class DGHomeState extends State<DGHome> {
  static const bool _showClubWheel = false;

  final DugnadDataCache _cache = DugnadDataCache.instance;

  // Data
  List<ClubListItem> _allClubs = [];
  ClubDetail? _clubDetail;
  List<SponsorStore> _sponsors = [];
  PointsSummary? _pointsSummary;
  LeaderboardData? _leaderboard;
  GamificationConfig? _gamificationConfig;
  GamificationCareer? _gamificationCareer;
  ReferralSummary? _referralSummary;
  bool _seasonFinaleDismissed = false;
  bool _referralPromoShown = false;
  bool _loading = true;
  bool _loadInProgress = false;

  /// Owns the home feed scroll position so the guided tour can follow it
  /// (Chunk 3). Attached to the [CustomScrollView] in [build].
  final ScrollController _scrollController = ScrollController();

  /// Exposed so the tour can read/observe the feed scroll position.
  ScrollController get tourScrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _seasonFinaleDismissed =
        prefGetString(prefDugnadSeasonFinaleDismissed) == '1';
    _seedFromCache();
    _loadData();
    DugnadState.instance.revision.addListener(_onStateChanged);
  }

  void _seedFromCache() {
    if (!DugnadState.instance.hasClub) return;
    final clubId = DugnadState.instance.clubId;
    final teamId = DugnadState.instance.hasPointsTeam
        ? DugnadState.instance.pointsTeamId
        : null;
    _clubDetail = _cache.peekClubDetail(clubId);
    _pointsSummary = _cache.peekPointsSummary();
    _leaderboard = _cache.peekLeaderboard(clubId);
    _gamificationConfig = _cache.peek<GamificationConfig>(
      DugnadDataCache.gamificationConfigKey(clubId),
    );
    _gamificationCareer = _cache.peek<GamificationCareer>(
      DugnadDataCache.gamificationCareerKey(clubId, teamId),
    );
    _referralSummary = _cache.peek<ReferralSummary>('referralSummary:$clubId');
    if (_pointsSummary != null || _clubDetail != null) {
      _loading = false;
    }
  }

  void _onStateChanged() {
    if (mounted) _loadData(forceRefresh: true);
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_loadInProgress) return;
    _loadInProgress = true;

    try {
      if (!DugnadState.instance.hasClub) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final hasCachedContent = _pointsSummary != null || _clubDetail != null;
      if (mounted && !hasCachedContent) {
        setState(() => _loading = true);
      }

      final clubId = DugnadState.instance.clubId;
      final loggedIn = isLoggedIn();
      final teamId = DugnadState.instance.pointsTeamId > 0
          ? DugnadState.instance.pointsTeamId
          : null;

      final bundle = await _cache.loadHomeBundle(
        clubId: clubId,
        loggedIn: loggedIn,
        teamId: teamId,
        forceRefresh: forceRefresh,
      );

      _allClubs = bundle.clubs;
      _clubDetail = bundle.clubDetail ?? _clubDetail;
      _sponsors = bundle.sponsors;
      _pointsSummary = bundle.pointsSummary ?? _pointsSummary;
      _leaderboard = bundle.leaderboard ?? _leaderboard;
      _gamificationConfig = bundle.gamificationConfig ?? _gamificationConfig;
      _gamificationCareer = bundle.gamificationCareer ?? _gamificationCareer;
      _referralSummary = bundle.referralSummary ?? _referralSummary;

      await _syncClubBrandingFromApi();

      if (mounted) {
        setState(() => _loading = false);
        // Golden referral nudge first; tour prompt immediately after it closes
        // (or right away if the nudge is not shown). Do not fire both at once —
        // the tour used to bail while the sheet was on top and only reappeared
        // on a later home reload.
        unawaited(_presentHomeEntryPrompts());
      }
    } finally {
      _loadInProgress = false;
    }
  }

  Future<void> _syncClubBrandingFromApi() async {
    final clubId = DugnadState.instance.clubId;
    String? logo = _clubDetail?.logo;
    String? area = _clubDetail?.area;
    String? name = _clubDetail?.name;
    String? shortName = _clubDetail?.shortName;
    String? portalThemeColor = _clubDetail?.portalThemeColor;
    String? portalBackgroundColor = _clubDetail?.portalBackgroundColor;

    for (final club in _allClubs) {
      if (club.id == clubId) {
        if (logo == null || logo.isEmpty) logo = club.logo;
        if (area == null || area.isEmpty) area = club.area;
        if (name == null || name.isEmpty) name = club.name;
        if (shortName == null || shortName.isEmpty) {
          shortName = club.shortName;
        }
        portalThemeColor ??= club.portalThemeColor;
        portalBackgroundColor ??= club.portalBackgroundColor;
        break;
      }
    }

    await DugnadState.instance.syncClubBranding(
      logo: logo,
      area: area,
      name: name,
      shortName: shortName,
      portalThemeColor: portalThemeColor,
      portalBackgroundColor: portalBackgroundColor,
    );
  }

  String? get _clubLogoUrl {
    final fromDetail = _clubDetail?.logo;
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;

    final fromState = DugnadState.instance.clubLogo;
    if (fromState.isNotEmpty) return fromState;

    for (final club in _allClubs) {
      if (club.id == DugnadState.instance.clubId) {
        final fromList = club.logo;
        if (fromList != null && fromList.isNotEmpty) return fromList;
        break;
      }
    }
    return null;
  }

  Future<void> _pickClub() async {
    HapticFeedback.lightImpact();
    final club = await showClubSheet(
      context,
      currentClub: DugnadState.instance.hasClub
          ? ClubListItem(
              id: DugnadState.instance.clubId,
              name: DugnadState.instance.clubName,
              shortName: DugnadState.instance.clubShortName.isEmpty
                  ? null
                  : DugnadState.instance.clubShortName,
              logo: DugnadState.instance.clubLogo.isEmpty
                  ? null
                  : DugnadState.instance.clubLogo,
              area: DugnadState.instance.clubArea.isEmpty
                  ? null
                  : DugnadState.instance.clubArea,
            )
          : null,
    );
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
      _loadData();
    }
  }

  double _pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 430) return 24;
    return context.dp(AeDugnadSpace.pageH);
  }

  double _feedGap(BuildContext context) =>
      context.dp(AeDugnadSpace.homeFeedGap);

  @override
  Widget build(BuildContext context) {
    final hasClub = DugnadState.instance.hasClub;
    final pagePad = _pagePadding(context);
    final feedGap = _feedGap(context);
    final heroColor =
        hasClub ? context.dugnadTheme.primary : ReenPreClubTokens.navy;

    // `.h-hero` + `.h-feed` must live in ONE sliver. Translating the feed up
    // over a *previous* sliver gets clipped by [CustomScrollView] (default
    // Clip.hardEdge) — that sliced off the 24px top radius and left a flat
    // purple seam (pixel-confirmed vs design).
    final overlap = context.dp(AeDugnadSpace.homeFeedOverlap);
    final Widget feedChild;
    if (_loading && _pointsSummary == null && _clubDetail == null) {
      feedChild = DugnadFeedSkeleton(padding: pagePad);
    } else {
      feedChild = Padding(
        padding: EdgeInsets.fromLTRB(
          pagePad,
          context.dp(AeDugnadSpace.homeFeedPadTop),
          pagePad,
          context.dp(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasClub && _showClubWheel && _allClubs.length > 1) ...[
              _buildTeamWheel(),
              SizedBox(height: feedGap),
            ],
            if (!hasClub)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DugnadRiseIn(
                    child: DugnadChooseClubHomeCard(onTap: _pickClub),
                  ),
                  SizedBox(height: feedGap),
                  DugnadRiseIn(
                    delay: const Duration(milliseconds: 100),
                    child: _lockSection(
                      languages.dugnadGateCollectPoints,
                      languages.dugnadGateChooseClubCollectPoints,
                      DugnadHomeAnchorCard(
                        summary: null,
                        config: _gamificationConfig,
                        teamRank: null,
                        teamTotal: _leaderboard?.teams.length,
                        isGuest: false,
                        previewMetal: 'solv',
                        onOpenPoints: _pickClub,
                        onOpenStoCard: _pickClub,
                        onConnectTeam: _pickClub,
                        onOpenLeaderboard: _openLeaderboard,
                      ),
                    ),
                  ),
                ],
              )
            else
              DugnadRiseIn(
                child: KeyedSubtree(
                  key: DugnadTourKeys.register(DugnadTourTarget.points),
                  child: _lockSection(
                    languages.dugnadGateCollectPoints,
                    languages.dugnadGateChooseClubCollectPoints,
                    _buildAnchorCard(),
                  ),
                ),
              ),
            if (hasClub) ...[
              if (kDebugMode && CelebrationDebugFlags.showPanel)
                const CelebrationDebugPanel(),
              // Gap belongs to the feed stack (card → finale), not the debug
              // panel — otherwise turning the panel off collapses the cards.
              if (_showSeasonFinale) ...[
                SizedBox(height: feedGap),
                DugnadRiseIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildSeasonFinaleSection(),
                ),
              ],
            ],
            if (hasClub) SizedBox(height: feedGap),
            if (hasClub && isLoggedIn()) ...[
              IncomingReferralBanner(summary: _referralSummary),
              SizedBox(height: feedGap),
            ],
            DugnadRiseIn(
              delay: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: DugnadTourKeys.register(DugnadTourTarget.earn),
                child: hasClub
                    ? _lockSection(
                        languages.dugnadGateBuyAndEarn,
                        languages.dugnadGateChooseClubBuyAndEarn,
                        _buildEarnPointsEntry(),
                      )
                    : _buildEarnPointsEntry(),
              ),
            ),
            if (hasClub &&
                _gamificationConfig?.showClubShopEntry == true &&
                isLoggedIn()) ...[
              SizedBox(height: feedGap),
              DugnadRiseIn(
                delay: const Duration(milliseconds: 230),
                child: DugnadClubShopEntry(onTap: _openClubShop),
              ),
            ],
            SizedBox(height: feedGap),
            DugnadRiseIn(
              delay: const Duration(milliseconds: 260),
              child: _lockSection(
                languages.dugnadGateBuyAndEarn,
                languages.dugnadGateChooseClubBuyAndEarn,
                _buildCampaignCarousel(),
                vBleed: hasClub ? null : 0,
              ),
            ),
            SizedBox(height: feedGap),
            _buildHomeModuleEntries(hasClub: hasClub),
            if (hasClub && _sponsors.isNotEmpty) ...[
              SizedBox(height: feedGap),
              _lockSection(
                languages.dugnadGateBuyAndEarn,
                languages.dugnadGateChooseClubBuyAndEarn,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSponsorBanner(),
                    SizedBox(height: context.dp(12)),
                    _buildSponsorStores(),
                  ],
                ),
              ),
            ],
            // Reserve the floating pill nav + safe area,
            // plus dp(16) clearance — the nav is an overlay,
            // so a fixed 100 let it cover the last card.
            SizedBox(
              height: aePillNavReservedHeight(context) + context.dp(16),
            ),
          ],
        ),
      );
    }

    final scaffold = Scaffold(
      // Mint feed canvas fills the bottom (nav / home-indicator / overscroll).
      // Primary is painted only under the hero so top pull-to-refresh still
      // matches the club header — not a full-screen green flash at the foot.
      backgroundColor: context.dugnadTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + context.dp(240),
            child: ColoredBox(color: heroColor),
          ),
          RefreshIndicator(
            color: hasClub ? context.dugnadTheme.primary : ReenPreClubTokens.coral,
            onRefresh: _loadData,
            child: CustomScrollView(
              controller: _scrollController,
              clipBehavior: Clip.none,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(pagePad),
                      // CSS `.h-feed { margin-top: -18px; border-radius: 24px 24px 0 0 }`
                      // Bottom padding collapses the layout hole Transform leaves
                      // (same as negative margin in document flow).
                      Transform.translate(
                        offset: Offset(0, -overlap),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: overlap),
                          child: _HomeFeedSheet(child: feedChild),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!hasClub) {
      return DugnadClubThemeScope(
        palette: DugnadClubThemePalette.reenPreClub,
        child: scaffold,
      );
    }
    return scaffold;
  }

  // ── Purple hero ──────────────────────────────────────────────────────

  String _heroLocationLabel() {
    try {
      final raw = prefGetString(prefNewDeliveryAddress).trim();
      if (raw.isEmpty) return languages.dugnadSelectAddress;

      final address = raw.startsWith('{')
          ? AddressListItem.fromJson(jsonDecode(raw)).address.trim()
          : raw;
      if (address.isEmpty) return languages.dugnadSelectAddress;

      return _formatHeroAddress(address);
    } catch (_) {
      return languages.dugnadSelectAddress;
    }
  }

  bool _isPlusCodeSegment(String part) {
    return RegExp(
      r'^[2-9CFGHJMPQRVWX]{4,}\+[2-9CFGHJMPQRVWX]{2,}',
      caseSensitive: false,
    ).hasMatch(part.trim());
  }

  String _stripPostcodeFromSegment(String part) {
    final match = RegExp(r'^\d{4}\s+').firstMatch(part.trim());
    if (match != null) return part.substring(match.end).trim();
    return part.trim();
  }

  bool _isCountrySegment(String part) {
    const countries = {
      'india',
      'norway',
      'norge',
      'usa',
      'united states',
      'united kingdom',
      'uk',
    };
    return countries.contains(part.trim().toLowerCase());
  }

  /// Figma-style label: city and state/region only (e.g. "Bergen, Hordaland").
  String _formatHeroAddress(String address) {
    final parts = address
        .split(',')
        .map(_stripPostcodeFromSegment)
        .where((part) => part.isNotEmpty)
        .where((part) => !_isPlusCodeSegment(part))
        .toList();

    var meaningful = List<String>.from(parts);
    if (meaningful.isNotEmpty && _isCountrySegment(meaningful.last)) {
      meaningful = meaningful.sublist(0, meaningful.length - 1);
    }

    if (meaningful.length >= 2) {
      return '${meaningful[meaningful.length - 2]}, ${meaningful.last}';
    }
    if (meaningful.isNotEmpty) return meaningful.last;
    return languages.dugnadSelectAddress;
  }

  Future<void> _pickDeliveryAddress() async {
    HapticFeedback.lightImpact();
    final result = await showDugnadAddressDrawer(
      context,
      parentContext: context,
      onAddressChanged: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted && result == true) {
      setState(() {});
    }
  }

  Widget _buildHero(double pagePad) {
    if (!DugnadState.instance.hasClub) {
      return _buildReenHero(pagePad);
    }
    final locationLabel = _heroLocationLabel();

    // Solid primary like CSS club hero — feed overlaps via translate, so
    // corner cut-outs reveal this colour (not scaffold lavender).
    return Container(
      width: double.infinity,
      color: context.dugnadTheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            pagePad,
            context.dp(AeDugnadSpace.heroPadTop),
            pagePad,
            context.dp(AeDugnadSpace.clubHeroPadBottom),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Balance the bell so the address block stays truly centered.
                  SizedBox(width: context.dp(40)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Cap so the inflated tour hole cannot reach the bell.
                        final textMax = math.max(
                          64.0,
                          constraints.maxWidth -
                              context.dp(24) -
                              context.dp(13) -
                              context.dp(4) -
                              context.dp(14),
                        );
                        return GestureDetector(
                          onTap: _pickDeliveryAddress,
                          behavior: HitTestBehavior.opaque,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: context.dp(40)),
                            child: Center(
                              child: KeyedSubtree(
                                key: DugnadTourKeys.register(
                                    DugnadTourTarget.addr),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.dp(10),
                                    vertical: context.dp(4),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        languages.heroDeliveryTo,
                                        textAlign: TextAlign.center,
                                        style: AeDugnadText.heroDeliveryLabel(
                                          color: Colors.white
                                              .withValues(alpha: 0.72),
                                        ).dp(context),
                                      ),
                                      SizedBox(height: context.dp(4)),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white,
                                            size: context.dp(13),
                                          ),
                                          SizedBox(width: context.dp(4)),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                                maxWidth: textMax),
                                            child: Text(
                                              locationLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: AeDugnadText
                                                  .heroDeliveryPlace(
                                                color: Colors.white,
                                              ).dp(context),
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            size: context.dp(14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ModeChip (dugnad/commercial) hidden for now — mockup is
                  // address + bell only on the hero top row.
                  const DugnadBellButton(onHero: true),
                ],
              ),
              SizedBox(height: context.dp(11)),
              _buildMinKlubbRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReenHero(double pagePad) {
    return Container(
      width: double.infinity,
      color: ReenPreClubTokens.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            pagePad,
            context.dp(AeDugnadSpace.heroPadTop),
            pagePad,
            context.dp(AeDugnadSpace.clubHeroPadBottom),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: context.dp(40)),
              const Expanded(
                child: Center(child: DugnadReenLogo(height: 30)),
              ),
              const DugnadBellButton(onHero: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinKlubbRow() {
    return GestureDetector(
      onTap: _pickClub,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(12),
          vertical: context.dp(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(context.dp(14)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: context.dp(38),
              child: ClubCrest(
                name: DugnadClubBranding.fullName(),
                logoUrl: _clubLogoUrl,
                size: context.dp(30),
                backgroundColor: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            SizedBox(width: context.dp(11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.dugnadMyClub.toUpperCase(),
                    style: AeDugnadText.myKlubbKey(
                      color: Colors.white.withValues(alpha: 0.72),
                    ).dp(context),
                  ),
                  SizedBox(height: context.dp(1)),
                  Text(
                    DugnadClubBranding.fullName(),
                    style: AeDugnadText.myKlubbValue(color: Colors.white).dp(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: context.dp(18),
            ),
          ],
        ),
      ),
    );
  }

  LeaderboardTeamRow? _selectedTeamRow() {
    final board = _leaderboard;
    if (board == null || !DugnadState.instance.hasPointsTeam) return null;
    for (final row in board.teams) {
      if (row.teamId == DugnadState.instance.pointsTeamId) return row;
    }
    return null;
  }

  Future<void> _pickPointsTeam() async {
    if (!DugnadState.instance.hasClub) return;
    HapticFeedback.lightImpact();
    await openPointsTeamPicker(context);
    if (mounted) _loadData();
  }

  Widget _buildAnchorCard() {
    // Avoid flashing wrong metal colors before points summary arrives.
    if (_pointsSummary == null && isLoggedIn()) {
      return const DugnadAnchorCardSkeleton();
    }
    final teamRow = _selectedTeamRow();
    return DugnadHomeAnchorCard(
      summary: _pointsSummary,
      config: _gamificationConfig,
      teamRank: teamRow?.rank,
      teamTotal: _leaderboard?.teams.length,
      isGuest: !isLoggedIn(),
      showSeasonCarryover: _showSeasonFinale,
      onOpenPoints: () => openScreen(context, const DugnadPointsScreen()),
      onOpenStoCard: () => openScreen(context, const SupporterCardScreen()),
      onConnectTeam: _pickPointsTeam,
      onOpenLeaderboard: _openLeaderboard,
    );
  }

  // ── Guided tour: prompt trigger + launch ─────────────────────────────

  /// Home entry sequence: referral golden nudge (if any), then tour invite.
  ///
  /// Celebrations go first. Both prompts render above every route — the tour
  /// invite is a root Overlay entry, the referral nudge a modal sheet — so on
  /// a fresh login they landed on top of the T13/T14 ceremonials, hiding them
  /// and swallowing their close button. Let the queue drain before either.
  Future<void> _presentHomeEntryPrompts() async {
    await DugnadCelebrationOrchestrator.instance.waitUntilIdle();
    if (!mounted) return;
    await _maybeShowReferralPromo();
    if (!mounted) return;
    _maybeShowTourPrompt();
  }

  /// Show the tour prompt when: dugnad mode + club selected, not yet completed,
  /// data loaded (not skeleton), and nothing is on top of DGHome. If it's already
  /// completed but the reward wasn't paid, retry the award once (idempotent).
  ///
  /// "Handled this session" lives on DugnadState so it survives DGHome staying
  /// mounted in the PageView (no re-fire on tab return) yet is cleared on logout.
  void _maybeShowTourPrompt({int routeRetry = 0}) {
    final st = DugnadState.instance;
    if (st.tourPromptHandledThisSession || !mounted) return;
    if (!st.isDugnadMode || !st.hasClub) return;
    if (_pointsSummary == null) return; // still skeleton (or guest) — not ready

    if (prefGetBool(prefDugnadTourCompleted)) {
      st.tourPromptHandledThisSession = true;
      DugnadTourController.retryAwardIfNeeded();
      return;
    }

    // Defer a frame so DGHome is actually visible and topmost (not under a sheet,
    // dialog, or the welcome screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (st.tourPromptHandledThisSession || !mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        // Sheet pop animation can leave us non-current for a frame or two —
        // retry briefly instead of waiting for the next home reload.
        if (routeRetry < 8) {
          _maybeShowTourPrompt(routeRetry: routeRetry + 1);
        }
        return;
      }
      st.tourPromptHandledThisSession = true;
      DugnadTourPrompt.show(
        onStart: _launchTour,
        // "Ikke nå" suppresses the prompt permanently (completed, but NOT
        // finished — so the reward retry stays gated). The profile row is the
        // way back in.
        onLater: () => prefSetBool(prefDugnadTourCompleted, true),
      );
    });
  }

  void _launchTour() {
    final knownAbsent = DugnadTourController.computeKnownAbsent(
      career: _gamificationCareer,
    );
    final controller = DugnadTourController();
    DugnadTourOverlay.show(controller);
    // Let the overlay State mount + subscribe before [start] flips ready —
    // otherwise the fade-in notification is missed and the card stays invisible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isFinished) return;
      controller.start(knownAbsent: knownAbsent);
    });
  }

  /// Season-run-in card (`SeasonCarryoverCard` in club-select.jsx).
  /// Prototype gates sesonginnspurt and overgangsvindu together
  /// (`__dgSeasonFinale` / `transfer_window_enabled`).
  bool get _showSeasonFinale {
    if (!isLoggedIn()) return false;
    final summary = _pointsSummary;
    if (summary == null || summary.lifetimePoints <= 0) return false;
    return _showTransferBanner;
  }

  String? get _seasonFinaleEndRaw {
    final config = _gamificationConfig;
    final activeSeasonEnd = config?.modules?.activeSeason?.endsAt;
    if (activeSeasonEnd != null && activeSeasonEnd.trim().isNotEmpty) {
      return activeSeasonEnd;
    }
    final summaryEnd = _pointsSummary?.seasonEndsAt;
    if (summaryEnd != null && summaryEnd.trim().isNotEmpty) {
      return summaryEnd;
    }
    return _gamificationCareer?.activeSeason?.endsAt;
  }

  Future<void> _dismissSeasonFinale() async {
    await prefSetString(prefDugnadSeasonFinaleDismissed, '1');
    if (mounted) setState(() => _seasonFinaleDismissed = true);
  }

  /// Shows the golden referral nudge when eligible. Completes when the sheet
  /// is dismissed (or immediately when it should not be shown).
  Future<void> _maybeShowReferralPromo() async {
    if (_referralPromoShown || _loading || !mounted) return;
    if (!isLoggedIn()) return;
    if (prefGetString(prefDugnadReferralPromoDismissed) == '1') return;

    final summary = _referralSummary;
    final link = summary?.referralLink?.trim();
    if (summary == null || link == null || link.isEmpty) return;

    _referralPromoShown = true;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    // The celebration queue reports idle the moment its route starts tearing
    // down, so `endOfFrame` alone can land this push inside the navigator's own
    // pop — `showModalBottomSheet` then throws `!_debugLocked` and wedges the
    // navigator, which is what killed the ceremonial's close button. Wait for
    // DGHome to actually be the top route again; the same guard the tour prompt
    // already uses.
    if (!await _waitUntilHomeIsTopRoute()) {
      _referralPromoShown = false; // let a later home load retry
      return;
    }
    // Modal sheet on the root navigator — a ceremonial pushed while it is open
    // would stack over it, and one pushed just before it would be buried.
    final orchestrator = DugnadCelebrationOrchestrator.instance;
    orchestrator.holdCriticalFlow();
    try {
      await showDugnadReferralPromoSheet(context, summary: summary);
    } finally {
      orchestrator.releaseCriticalFlow();
    }
  }

  /// Resolves true once DGHome's route is current, active, and nothing is
  /// mid-transition above it. Polls on a timer so the caller always resumes
  /// outside any Navigator push/pop, never inside one.
  Future<bool> _waitUntilHomeIsTopRoute({int tries = 40}) async {
    for (var i = 0; i < tries; i++) {
      if (!mounted) return false;
      final route = ModalRoute.of(context);
      if (route != null &&
          route.isActive &&
          route.isCurrent &&
          !(route.navigator?.userGestureInProgress ?? false)) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    return false;
  }

  Future<void> _showSeasonFinaleAgain() async {
    await prefSetString(prefDugnadSeasonFinaleDismissed, '');
    if (mounted) setState(() => _seasonFinaleDismissed = false);
  }

  Widget _buildSeasonFinaleSection() {
    final summary = _pointsSummary!;
    final config = _gamificationConfig!;
    return DugnadSeasonFinaleSection(
      summary: summary,
      config: config,
      seasonEndRaw: _seasonFinaleEndRaw,
      seasonBadgeCount: _gamificationCareer?.seasonalBadges.length ?? 0,
      dismissed: _seasonFinaleDismissed,
      onDismiss: _dismissSeasonFinale,
      onShowAgain: _showSeasonFinaleAgain,
      onOpen: _showTransferBanner
          ? () => openScreen(context, const TransferWindowScreen())
          : null,
    );
  }

  Widget _buildHomeModuleEntries({required bool hasClub}) {
    final club = DugnadClubBranding.compactName();
    final teamRow = _selectedTeamRow();
    final hasTeam = DugnadState.instance.hasPointsTeam;
    final teamName = DugnadState.instance.pointsTeamName;
    final gap = context.dp(AeDugnadSpace.quickGap) +
        ((!hasClub || !isLoggedIn()) ? context.dp(6) : 0);

    final leagueTitle = hasTeam && teamRow != null && teamName.trim().isNotEmpty
        ? languages.dugnadLeagueTeamRankTitle(teamName, teamRow.rank)
        : languages.dugnadLeagueCtaTitle;
    final leagueSub = hasTeam && teamRow != null
        ? languages.dugnadLeagueTeamRankSubtitle(DugnadClubBranding.fullName())
        : languages.dugnadLeagueCtaSubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadRiseIn(
          delay: const Duration(milliseconds: 50),
          child: _lockSection(
            languages.dugnadGateCompete,
            languages.dugnadGateChooseClubCompete,
            DugnadFeedEntryBanner(
              key: DugnadTourKeys.register(DugnadTourTarget.comp),
              title: leagueTitle,
              subtitle: leagueSub,
              onTap: () => openScreen(context, const LeaderboardScreen()),
              variant: DugnadFeedEntryVariant.leagueGold,
              trailingIsNorthEast: true,
              // `.lb-entry` has no `.ic` box — just the glyph at 28px, with
              // CSS `drop-shadow(0 3px 5px rgba(160,110,10,.3))`.
              leading: Text(
                '🏆',
                style: TextStyle(
                  fontSize: context.dp(28),
                  height: 1,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFA06E0A).withValues(alpha: 0.3),
                      offset: Offset(0, context.dp(3)),
                      blurRadius: context.dp(5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 100),
          child: _lockSection(
            languages.dugnadGateMissions,
            languages.dugnadGateChooseClubCompete,
            DugnadFeedEntryBanner(
              title: languages.dugnadMissionsEntryTitle,
              subtitle: languages.dugnadMissionsEntrySubtitle,
              onTap: () => openScreen(context, const DugnadMissionsScreen()),
              variant: DugnadFeedEntryVariant.missionsPurple,
            ),
          ),
        ),
        if (hasClub && _showTransferBanner && isLoggedIn()) ...[
          SizedBox(height: gap),
          DugnadRiseIn(
            delay: const Duration(milliseconds: 140),
            child: DugnadTransferFeedBanner(
              title: languages.dugnadTransferBannerTitle,
              subtitle: _transferBannerSubtitle(),
              onTap: () => openScreen(context, const TransferWindowScreen()),
            ),
          ),
        ],
        SizedBox(height: gap),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 180),
          child: _lockSection(
            languages.dugnadGateSupport,
            languages.dugnadGateChooseClubCompete,
            DugnadFeedEntryBanner(
              key: DugnadTourKeys.register(DugnadTourTarget.donate),
              title: languages.dugnadSupportClubFast(club),
              subtitle: languages.dugnadSupportClubFastSub,
              onTap: () => openDonationFlow(context),
              variant: DugnadFeedEntryVariant.supportLight,
              animateLeading: true,
            ),
          ),
        ),
        if (hasClub && isLoggedIn()) ...[
          SizedBox(height: gap),
          DugnadRiseIn(
            delay: const Duration(milliseconds: 220),
            child: DugnadFeedEntryBanner(
              key: DugnadTourKeys.register(DugnadTourTarget.refer),
              title: languages.dugnadReferFriendsToClub(club),
              subtitle: languages.dugnadReferFriendsSubtitle,
              onTap: () => openScreen(context, const ReferralShareScreen()),
              variant: DugnadFeedEntryVariant.referralPurple,
              animateLeading: true,
            ),
          ),
        ],
      ],
    );
  }

  bool get _showTransferBanner {
    final config = _gamificationConfig;
    if (config == null) return false;
    if (!config.isEnabled('transfer_window_enabled')) return false;
    final transfer = config.modules?.transferWindow;
    return transfer != null && transfer.enabled;
  }

  String _transferBannerSubtitle() {
    final closesAt = _gamificationConfig?.modules?.transferWindow?.closesAt;
    if (closesAt == null || closesAt.trim().isEmpty) {
      return languages.dugnadTransferBannerSubtitleSoon;
    }
    final end = DateTime.tryParse(closesAt.trim());
    if (end == null) return languages.dugnadTransferBannerSubtitleSoon;
    final days = end.toLocal().difference(DateTime.now()).inDays;
    if (days <= 0) return languages.dugnadTransferBannerSubtitleSoon;
    return languages.dugnadTransferBannerSubtitle(days);
  }

  // ── Team wheel ───────────────────────────────────────────────────────

  Widget _buildTeamWheel() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(20)),
      child: _ClubWheel(
        clubs: _allClubs,
        selectedClubId: DugnadState.instance.clubId,
        onClubTap: (club) async {
          await DugnadState.instance.selectClub(club);
          if (mounted) _loadData();
        },
      ),
    );
  }

  // ── Medlemstilbud CTA ────────────────────────────────────────────────

  // ignore: unused_element
  Widget _buildMedlemstilbudCta() {
    final hasMembership = DugnadState.instance.hasMembership;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dp(20),
        context.dp(6),
        context.dp(20),
        context.dp(12),
      ),
      child: GestureDetector(
        onTap: () async {
          await showMembershipSheet(context);
          if (mounted) setState(() {});
        },
        child: Container(
          padding: EdgeInsets.all(context.dp(16)),
          decoration: BoxDecoration(
            gradient: context.dugnadTheme.bannerGradient,
            borderRadius: BorderRadius.circular(context.dp(18)),
            boxShadow: context.dugnadTheme.shadowButton,
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(44),
                height: context.dp(44),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(context.dp(14)),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Icon(
                  hasMembership
                      ? Icons.card_membership_rounded
                      : Icons.lock_rounded,
                  color: Colors.white,
                  size: context.dp(22),
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasMembership
                          ? languages.dugnadViewMemberOffers
                          : languages.dugnadMemberDiscountsLocked,
                      style: aeTitle(color: Colors.white).dp(context),
                    ),
                    if (hasMembership)
                      Text(
                        languages.dugnadMemberNumber(
                          DugnadState.instance.membershipNumber,
                        ),
                        style: aeCaption(color: Colors.white70).dp(context),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: context.dp(22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sponsor banner ───────────────────────────────────────────────────

  Widget _buildSponsorBanner() {
    final payoutPct = _clubDetail?.clubPayoutValue ?? 10;
    return Row(
      children: [
        Expanded(
          child: Text(
            languages.dugnadShopAtSponsors,
            style: AeDugnadText.sectionHead().dp(context),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.dp(8),
            vertical: context.dp(3),
          ),
          decoration: BoxDecoration(
            color: ScSaasThemeTokens.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            languages.dugnadPercentToClub(
              payoutPct.toStringAsFixed(
                payoutPct == payoutPct.roundToDouble() ? 0 : 1,
              ),
            ),
            style: aeOverline(color: ScSaasThemeTokens.accent).dp(context),
          ),
        ),
      ],
    );
  }

  // ── Sponsor store cards ──────────────────────────────────────────────

  Widget _buildSponsorStores() {
    return SizedBox(
      height: context.dp(140),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: _sponsors.length,
        separatorBuilder: (_, __) => SizedBox(width: context.dp(12)),
        itemBuilder: (context, index) {
          final store = _sponsors[index];
          return GestureDetector(
            onTap: () => openScreen(
              context,
              StoreDetail(storeId: store.id, storeName: store.name),
            ),
            child: Container(
              width: context.dp(140),
              padding: EdgeInsets.all(context.dp(14)),
              decoration: AeSurface.card(
                borderRadius: BorderRadius.circular(context.dp(14)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClubCrest(
                    name: store.name,
                    logoUrl: store.logo,
                    size: context.dp(48),
                  ),
                  SizedBox(height: context.dp(10)),
                  Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: aeCaption()
                        .copyWith(fontWeight: FontWeight.w700)
                        .dp(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarnPointsEntry() {
    return DugnadEarnPointsEntry(
      clubName: DugnadClubBranding.compactName(),
      onTap: _openEarnSheet,
    );
  }

  void _openClubShop() {
    final homeState = context.findAncestorStateOfType<HomeMainV1State>();
    if (homeState != null) {
      homeState.switchToTab(HomeMainV1State.dugnadShopTabIndex);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ClubShopScreen.routeName),
        builder: (_) => const ClubShopScreen(),
      ),
    );
  }

  void _openLeaderboard() {
    final homeState = context.findAncestorStateOfType<HomeMainV1State>();
    if (homeState != null) {
      homeState.switchToTab(HomeMainV1State.dugnadLeaderboardTabIndex);
      return;
    }
    openScreen(context, const LeaderboardScreen());
  }

  void _openEarnSheet() {
    final membership = _gamificationConfig?.membershipPoints;
    final donationPts = membership != null && membership.enabled
        ? membership.pointsPerMonthAt100Kr()
        : 10;
    showDugnadEarnSheet(
      context,
      clubName: DugnadClubBranding.compactName(),
      points: DugnadEarnSheetPoints(
        campaign: _pointsSummary?.campaignPurchasePoints ?? 50,
        // Real referral rate from config (referral_points) via ReferralSummary.
        referral: _referralSummary?.referralPoints ?? 100,
        donationPerMonth: donationPts,
      ),
    );
  }

  Widget _buildCampaignCarousel() {
    final campaigns = DugnadState.instance.hasClub
        ? (_clubDetail?.campaigns ?? [])
        : dugnadDummyCampaigns();
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return DugnadCampaignCarousel(
      key: DugnadTourKeys.register(DugnadTourTarget.camps),
      campaigns: campaigns,
      clubLabel: DugnadState.instance.hasClub
          ? DugnadClubBranding.compactName()
          : languages.dugnadChooseClub,
      campaignPoints: _pointsSummary?.campaignPurchasePoints ?? 50,
      onSeeAll: () {
        final homeState = context.findAncestorStateOfType<HomeMainV1State>();
        homeState?.switchToTab(1);
      },
    );
  }

  Widget _lockSection(
    String guestLabel,
    String clubLabel,
    Widget child, {
    double? vBleed,
  }) {
    final hasClub = DugnadState.instance.hasClub;
    final locked = !hasClub || !isLoggedIn();
    if (!locked) return child;
    final bleed = vBleed ?? (hasClub ? 16 : DugnadLockedModule.browseVBleed);
    final module = DugnadLockedModule(
      locked: true,
      label: hasClub ? guestLabel : clubLabel,
      onUnlock: hasClub ? _openCreateAccount : _pickClub,
      hBleed: _pagePadding(context),
      vBleed: bleed,
      child: child,
    );
    if (hasClub || bleed <= 0) return module;
    // Vertical inset only — horizontal blur must reach screen edges.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dp(bleed)),
      child: module,
    );
  }

  Future<void> _openCreateAccount() async {
    HapticFeedback.lightImpact();
    if (isGuestUser()) {
      await showGuestLoginSheet(context);
    } else {
      await openScreenWithResult(context, const SignUp(returnOnSuccess: true));
    }
    if (mounted) setState(() {});
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Club wheel — adapted from _ServiceWheel (home_v1.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _ClubWheel extends StatefulWidget {
  final List<ClubListItem> clubs;
  final int selectedClubId;
  final void Function(ClubListItem club) onClubTap;

  const _ClubWheel({
    required this.clubs,
    required this.selectedClubId,
    required this.onClubTap,
  });

  @override
  State<_ClubWheel> createState() => _ClubWheelState();
}

class _ClubWheelState extends State<_ClubWheel>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0;
  double? _lastPanAngle;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  /// Started in initState and merely hidden in build, this kept
  /// running under reduced motion with a frame permanently scheduled.
  /// Gating in build is not gating (rule 16).
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_breatheController.isAnimating) _breatheController.stop();
      _breatheController.value = 0;
      _motionStarted = false;
      return;
    }
    if (_motionStarted) return;
    _motionStarted = true;
    _breatheController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.clubs.length;
    if (count == 0) return const SizedBox.shrink();

    const double outerRadius = 116;
    const double chipSize = 72;
    const double chipLabelWidth = 90;
    const double chipHeight = chipSize + 24;
    const double widgetSize = (outerRadius + chipHeight / 2) * 2 + 22;
    const Offset wheelCenter = Offset(widgetSize / 2, widgetSize / 2);

    return SizedBox(
      width: double.infinity,
      height: widgetSize,
      child: Center(
        child: SizedBox(
          width: widgetSize,
          height: widgetSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _lastPanAngle = _angleForLocalPosition(
                details.localPosition,
                wheelCenter,
              );
            },
            onPanUpdate: (details) {
              final nextAngle = _angleForLocalPosition(
                details.localPosition,
                wheelCenter,
              );
              final lastAngle = _lastPanAngle;
              if (lastAngle == null) {
                _lastPanAngle = nextAngle;
                return;
              }

              setState(() {
                _rotationAngle += _normalizeAngle(nextAngle - lastAngle);
              });
              _lastPanAngle = nextAngle;
            },
            onPanEnd: (_) => _lastPanAngle = null,
            onPanCancel: () => _lastPanAngle = null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    width: outerRadius * 2,
                    height: outerRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.16),
                        width: context.dp(1.2),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: outerRadius * 1.45,
                    height: outerRadius * 1.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                        width: context.dp(1),
                      ),
                    ),
                  ),
                ),
                // Center orb
                AnimatedBuilder(
                  animation: _breatheController,
                  builder: (_, __) {
                    final scale = 1.0 + _breatheController.value * 0.04;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: context.dp(74),
                        height: context.dp(74),
                        padding: EdgeInsets.all(context.dp(8)),
                        decoration: AeSurface.shinyPurple(
                          borderRadius: BorderRadius.circular(context.dp(22)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(context.dp(16)),
                          child: Image.asset(
                            'assets/Logo/reen/mark-coral-navy.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Club chips in a circle
                ...List.generate(count, (i) {
                  final angle =
                      (2 * math.pi * i / count) + _rotationAngle - math.pi / 2;
                  final dx = math.cos(angle) * outerRadius;
                  final dy = math.sin(angle) * outerRadius;
                  final club = widget.clubs[i];
                  final bool isSelected = club.id == widget.selectedClubId;

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: GestureDetector(
                      onTap: () => widget.onClubTap(club),
                      child: SizedBox(
                        width: chipLabelWidth,
                        height: chipHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: chipSize,
                              height: chipSize,
                              decoration: isSelected
                                  ? AeSurface.shinyPurple(isCircle: true)
                                  : AeSurface.shiny(isCircle: true),
                              child: Center(
                                child: ClubCrest(
                                  name: club.name,
                                  logoUrl: club.logo,
                                  size: chipSize - 16,
                                  backgroundColor: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(height: context.dp(3)),
                            Text(
                              club.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style:
                                  aeCaption(
                                        color: isSelected
                                            ? context.dugnadTheme.primary
                                            : context.dugnadTheme.text,
                                      )
                                      .copyWith(
                                        fontSize: 10,
                                        height: 1.0,
                                        fontWeight: FontWeight.w700,
                                      )
                                      .dp(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _angleForLocalPosition(Offset position, Offset center) {
    final vector = position - center;
    return math.atan2(vector.dy, vector.dx);
  }

  double _normalizeAngle(double angle) {
    var normalized = angle;
    while (normalized > math.pi) {
      normalized -= math.pi * 2;
    }
    while (normalized < -math.pi) {
      normalized += math.pi * 2;
    }
    return normalized;
  }
}

/// Home `.h-feed` — rounded lavender sheet over the purple hero.
class _HomeFeedSheet extends StatelessWidget {
  const _HomeFeedSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DugnadRoundedFeedSheet(
      radius: AeDugnadSpace.homeFeedRadius,
      child: child,
    );
  }
}
