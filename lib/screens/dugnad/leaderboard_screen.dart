import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/ae_inset_surface.dart';
import '../../commonView/circle_nav_bar.dart';
import '../../ui/kit/ae_loader.dart';
import '../../theme/ae_typography.dart';
import '../../theme/design_scale.dart';
import '../../theme/reen_pre_club_theme.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/guest_auth_helper.dart';
import '../../utils/utils.dart';
import '../../services/dugnad_data_cache.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../common/signUp/sign_up.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'club_sheet.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_points_screen.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'points_team_picker_screen.dart';
import 'team_detail_screen.dart';
import 'team_screen.dart';
import 'widgets/supporter_preview_sheet.dart';
import 'widgets/dugnad_prize_banner.dart';
import '../../ui/kit/ae_rise_in.dart';
import 'widgets/dugnad_metal_animations.dart';
import '../../ui/kit/ae_subpage_shell.dart';

// Design tokens from Ærend Design System / dugnad/gamify.css (.lb-zone, .lb-trow.inzone)
const _kGoldPoints = Color(0xFFB5851A);
const _kGoldTag = Color(0xFF9A6B12);
const _kGoldZoneBorder = Color(0x6BD8A028);
const _kGoldZoneGradientStart = Color(0x4DF7CF6B);
const _kGoldZoneGradientEnd = Color(0x29EEBB44);
const _kInZoneRowGradientStart = Color(0xFFFFFAF0);
const _kInZoneRowGradientEnd = Color(0xFFFFF7E6);
const _kHeroGoldStart = Color(0xFFFFE9A8);
const _kHeroGoldEnd = Color(0xFFF3C95F);

enum _LbTab { table, topScorer, assistKing, value }

/// Lagkonkurranse — 4-tab team leaderboard (prototype: LeaderboardScreen).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    this.openStoTab = false,
    this.openTopScorerTab = false,
    this.openAssistTab = false,
  });

  /// When true, lands on the STØ ranking tab (T6 / T12 CTA).
  final bool openStoTab;

  /// When true, lands on the top scorer tab (T7 / T10 CTA).
  final bool openTopScorerTab;

  /// When true, lands on the assist king tab (T8 / T11 CTA).
  final bool openAssistTab;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final DugnadDataCache _cache = DugnadDataCache.instance;

  _LbTab _tab = _LbTab.table;
  /// +1 = moved right, −1 = moved left — drives tab content slide direction.
  int _tabDir = 1;
  bool _mineOnly = false;
  LeaderboardData? _data;
  LeaderboardScorersData? _scorers;
  PointsSummary? _summary;
  bool _loadingTable = true;
  bool _loadingScorers = false;
  int? _loadedClubId;
  String? _loadedScorerKey;

  void _onBack() {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    if (home != null) {
      home.backOrHome();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  void initState() {
    super.initState();
    if (widget.openStoTab) {
      _tab = _LbTab.value;
    } else if (widget.openTopScorerTab) {
      _tab = _LbTab.topScorer;
    } else if (widget.openAssistTab) {
      _tab = _LbTab.assistKing;
    }
    DugnadState.instance.revision.addListener(_onClubChanged);
    _loadTable();
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onClubChanged);
    super.dispose();
  }

  void _onClubChanged() {
    final clubId = DugnadState.instance.clubId;
    if (!mounted || clubId == _loadedClubId) return;
    _loadedScorerKey = null;
    _scorers = null;
    _loadTable();
  }

  Future<void> _loadTable({bool forceRefresh = false}) async {
    if (!DugnadState.instance.hasClub) {
      _loadedClubId = null;
      if (mounted) setState(() => _loadingTable = false);
      return;
    }
    final clubId = DugnadState.instance.clubId;
    final cachedBoard = _cache.peekLeaderboard(clubId);
    final cachedSummary = _cache.peekPointsSummary();
    if (cachedBoard != null && _data == null) {
      _data = cachedBoard;
      _summary = cachedSummary;
      _loadingTable = false;
      _loadedClubId = clubId;
    }
    if (mounted && _data == null) {
      setState(() => _loadingTable = true);
    }
    try {
      final results = await Future.wait([
        _cache.getLeaderboard(clubId, forceRefresh: forceRefresh),
        _cache.getPointsSummary(forceRefresh: forceRefresh),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as LeaderboardData? ?? _data;
          _summary = results[1] as PointsSummary? ?? _summary;
          _loadingTable = false;
          _loadedClubId = clubId;
        });
        if (_tab != _LbTab.table) _loadScorers();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTable = false);
    }
  }

  String _scorerTabApi(_LbTab tab) {
    switch (tab) {
      case _LbTab.topScorer:
        return 'toppscorer';
      case _LbTab.assistKing:
        return 'assistkonge';
      case _LbTab.value:
        return 'verdi';
      case _LbTab.table:
        return 'toppscorer';
    }
  }

  String _scorerCacheKey() =>
      '${_scorerTabApi(_tab)}:${_mineOnly ? DugnadState.instance.pointsTeamId : 0}';

  Future<void> _loadScorers() async {
    if (!DugnadState.instance.hasClub || _tab == _LbTab.table) return;
    final key = _scorerCacheKey();
    if (_loadedScorerKey == key && _scorers != null) return;

    setState(() => _loadingScorers = true);
    try {
      final teamId = _mineOnly && DugnadState.instance.hasPointsTeam
          ? DugnadState.instance.pointsTeamId
          : null;
      final data = await _repo.getLeaderboardScorers(
        DugnadState.instance.clubId,
        tab: _scorerTabApi(_tab),
        teamId: teamId,
      );
      if (mounted) {
        setState(() {
          _scorers = data;
          _loadingScorers = false;
          _loadedScorerKey = key;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingScorers = false);
    }
  }

  void _setTab(_LbTab tab) {
    if (_tab == tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tabDir = tab.index >= _tab.index ? 1 : -1;
      _tab = tab;
    });
    if (tab != _LbTab.table) _loadScorers();
  }

  /// Re-apply feed `itemGap` inside the tab [AnimatedSwitcher] column.
  List<Widget> _withTabGap(double gap, List<Widget> items) {
    if (items.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  void _setMineOnly(bool value) {
    if (_mineOnly == value) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mineOnly = value;
      _loadedScorerKey = null;
    });
    _loadScorers();
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern(languages.localeName).format(value);
  }

  String _pointsUnitLabel() {
    return languages.dugnadPointsUnit.toUpperCase();
  }

  Future<void> _openPointsTeamPicker() async {
    HapticFeedback.lightImpact();
    final picked = await openPointsTeamPicker(context);
    if (picked == true && mounted) {
      _loadedScorerKey = null;
      await _loadTable();
    }
  }

  void _openTeamDetail(int teamId) {
    HapticFeedback.lightImpact();
    openScreen(context, TeamScreen(teamId: teamId));
  }

  void _openYourTeam() {
    if (DugnadState.instance.hasPointsTeam) {
      HapticFeedback.lightImpact();
      openScreen(
        context,
        TeamDetailScreen(teamId: DugnadState.instance.pointsTeamId),
      );
    } else {
      _openPointsTeamPicker();
    }
  }

  void _openScorerCard(LeaderboardScorerRow scorer) {
    showSupporterPreviewSheet(
      context: context,
      scorer: scorer,
      teamName: scorer.teamName.isNotEmpty
          ? scorer.teamName
          : DugnadClubBranding.fullName(),
    );
  }

  void _openYourPoints() {
    HapticFeedback.lightImpact();
    openScreen(context, const DugnadPointsScreen());
  }

  LeaderboardTeamRow? _userTeamRow() {
    final data = _data;
    if (data == null) return null;
    for (final row in data.teams) {
      if (row.isUserTeam) return row;
    }
    if (DugnadState.instance.hasPointsTeam) {
      for (final row in data.teams) {
        if (row.teamId == DugnadState.instance.pointsTeamId) return row;
      }
    }
    return null;
  }

  int _userLifetimePoints() {
    return _summary?.lifetimePoints ?? DugnadState.instance.pointsTotal;
  }

  String _tierLabel() {
    final tier = _summary?.currentTier;
    if (tier == null || tier.key.isEmpty) {
      return DugnadClubBranding.tierTitle('supporter');
    }
    return DugnadClubBranding.tierTitle(tier.key);
  }

  /// Clearance under the last card: pill nav + extra air, same pattern as home.
  double _feedBottomPadding(BuildContext context) =>
      aePillNavReservedHeight(context) + context.dp(32);

  Future<void> _pickClub() async {
    HapticFeedback.lightImpact();
    final club = await showClubSheet(context);
    if (club != null && mounted) {
      await DugnadState.instance.selectClub(club);
      setState(() {});
      _loadTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DugnadState.instance.hasClub) {
      return AeThemeScope(
        palette: AeThemePalette.reenPreClub,
        child: AeFixedTypography(
          child: Scaffold(
            backgroundColor: ScSaasThemeTokens.background,
            body: AeScrollBody(
              // `useReenLogo` paints the hero navy while this scope's primary
              // is coral -- the strip has to follow the hero, not the palette.
              heroColor: ReenPreClubTokens.navy,
              hero: AeHero(
                clubName: '',
                clubLogo: null,
                title: languages.dugnadLeaderboardTitle,
                subtitle: languages.dugnadLeaderboardNoClubHeroSubtitle,
                subtitleWithClock: true,
                useReenLogo: true,
                onBack: _onBack,
              ),
              bottomPadding: _feedBottomPadding(context),
              itemGap: 0,
              topPadding: 22,
              feedRadius: 22,
              overlap: 12,
              children: [
                _GuestStepsCard(
                  forChooseClub: true,
                  onCta: _pickClub,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final clubName = _data?.clubName ?? DugnadClubBranding.fullName();
    final clubLogo = _data?.clubLogo ?? DugnadState.instance.clubLogo;
    final seasonLabel = _data?.season.endsAtLabel ?? '';

    // Guests see a steps card inside the normal leaderboard chrome.
    if (!isLoggedIn()) {
      return AeFixedTypography(
        child: Scaffold(
          backgroundColor: context.aeTheme.background,
          body: AeScrollBody(
            hero: AeHero(
              clubName: clubName,
              clubLogo: clubLogo,
              title: languages.dugnadLeaderboardTitle,
              subtitle: languages.dugnadLeaderboardGuestHeroSubtitle,
              subtitleWithClock: true,
              onBack: _onBack,
            ),
            bottomPadding: _feedBottomPadding(context),
            itemGap: 0,
            topPadding: 22,
            feedRadius: 22,
            overlap: 12,
            children: [
              _GuestStepsCard(onCta: () async {
                HapticFeedback.lightImpact();
                if (isGuestUser()) {
                  await showGuestLoginSheet(context);
                } else {
                  await openScreenWithResult(
                      context, const SignUp(returnOnSuccess: true));
                }
                if (mounted) setState(() {});
              }),
            ],
          ),
        ),
      );
    }

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: context.aeTheme.background,
        body: _loadingTable
            ? const AeLoaderScreen()
            : AeScrollBody(
                  hero: AeHero(
                  clubName: clubName,
                  clubLogo: clubLogo,
                  title: languages.dugnadLeaderboardTitle,
                  subtitle: seasonLabel.isNotEmpty
                      ? languages.dugnadLeaderboardSeasonEnds(seasonLabel)
                      : null,
                  subtitleWithClock: seasonLabel.isNotEmpty,
                  onBack: _onBack,
                ),
                bottomPadding: _feedBottomPadding(context),
                itemGap: 12,
                topPadding: 8,
                feedRadius: 22,
                overlap: 12,
                children: [
                  _buildFeedHeader(clubName, clubLogo),
                  _LbSegmentedTabs(
                    selected: _tab,
                    onChanged: _setTab,
                  ),
                  // Soft cross-fade + nudge when switching tabs (matches
                  // prototype feel: pill slides, list rises in).
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    reverseDuration: const Duration(milliseconds: 220),
                    switchInCurve: const Cubic(0.22, 1, 0.36, 1),
                    switchOutCurve: const Cubic(0.4, 0, 1, 1),
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: Offset(0.04 * _tabDir, 0.015),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _withTabGap(
                          context.dp(12),
                          _tab == _LbTab.table
                              ? _buildTableTab()
                              : _buildScorerTab(),
                        ),
                      ),
                    ),
                  ),
                  _buildQuickCards(),
                ],
              ),
      ),
    );
  }

  Widget _buildFeedHeader(String clubName, String? clubLogo) {
    final teamCount = _data?.teams.length ?? 0;
    final title = _tab == _LbTab.table
        ? languages.dugnadLeaderboardTableTitle(clubName)
        : _tab == _LbTab.topScorer
        ? languages.dugnadLeaderboardTabTopScorer
        : _tab == _LbTab.assistKing
        ? languages.dugnadLeaderboardTabAssistKing
        // Chunk K: STØ ranking, not market value.
        : languages.dugnadLeaderboardValueTitle;
    final subtitle = _tab == _LbTab.table
        ? languages.dugnadLeaderboardInternalSeries(teamCount)
        : _tab == _LbTab.topScorer
        ? languages.dugnadLeaderboardScorerCapGoals
        : _tab == _LbTab.assistKing
        ? languages.dugnadLeaderboardScorerCapAssists
        : languages.dugnadLeaderboardScorerCapValue;
    final subtitleIcon = _tab == _LbTab.table
        ? Icons.shield_outlined
        : _tab == _LbTab.topScorer
        ? Icons.inventory_2_outlined
        : _tab == _LbTab.assistKing
        ? Icons.share_rounded
        : Icons.shield_outlined;

    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, 8),
          child: SizedBox(
            width: context.dp(64),
            height: context.dp(64),
            // `.crest-wrap` is `0 2px 6px rgba(45,27,91,.12),
            //  0 1px 1px rgba(255,255,255,.9) inset`. The inset was dropped;
            //  AeInsetSurface fakes it as a top edge highlight (rule 5).
            child: AeInsetSurface(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(18)),
              shadows: [
                BoxShadow(
                  color: Color(0x1F2D1B5B),
                  blurRadius: context.dp(6),
                  offset: Offset(0, 2),
                ),
              ],
              insets: [AeSurfaceInset.top(Colors.white.withValues(alpha: 0.9))],
              child: Center(
                child: AeClubCrest(
                  name: clubName,
                  logoUrl: clubLogo?.isEmpty ?? true ? null : clubLogo,
                  // `.lb-tablehead .crest-wrap .dg-crest` forces 50x50.
                  size: context.dp(50),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.dp(18)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.025 * 19,
            color: context.aeTheme.text,
          ),
        ),
        SizedBox(height: context.dp(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subtitleIcon, size: context.dp(13), color: context.aeTheme.primary),
            SizedBox(width: context.dp(6)),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildTableTab() {
    final data = _data;
    if (data == null) return [];

    final zoneSize = data.prizeZoneSize;
    final zoneTeams = data.teams.take(zoneSize).toList(growable: false);
    final restTeams = data.teams.skip(zoneSize).toList(growable: false);
    final cutoff = data.prizeZoneCutoffPoints ??
        (zoneTeams.isNotEmpty ? zoneTeams.last.lagpoeng : 0);

    return [
      _buildPrizeBanner(data.season),
      if (!DugnadState.instance.hasPointsTeam) ...[
        SizedBox(height: context.dp(2)),
        _buildChooseTeamCta(data.clubName),
      ],
      SizedBox(height: context.dp(2)),
      _buildTableColumns(),
      if (data.teams.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(24)),
          child: Text(
            languages.dugnadLeaderboardEmpty,
            textAlign: TextAlign.center,
            style: aeBody(color: ScSaasThemeTokens.gray500),
          ),
        )
      else ...[
        if (zoneTeams.isNotEmpty) _buildPrizeZone(zoneTeams, zoneSize),
        ...restTeams.map(
          (team) => _buildTeamRowWithGap(
            team,
            zoneSize: zoneSize,
            cutoff: cutoff,
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildScorerTab() {
    if (_loadingScorers) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(40)),
          child: const Center(child: AeLoader()),
        ),
      ];
    }

    final scorers = _scorers?.scorers ?? [];
    final teamName = _mineOnly && DugnadState.instance.hasPointsTeam
        ? DugnadState.instance.pointsTeamName
        : _data?.clubName ?? '';
    final season = _data?.season ?? _scorers?.season;

    return [
      if (season != null) _buildPrizeBanner(season),
      _ScorerFilterPills(
        mineOnly: _mineOnly,
        onChanged: _setMineOnly,
        canFilterMyTeam: DugnadState.instance.hasPointsTeam,
      ),
      if (scorers.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.dp(24)),
          child: Text(
            languages.dugnadLeaderboardScorerEmpty(teamName),
            textAlign: TextAlign.center,
            style: aeBody(color: ScSaasThemeTokens.gray500),
          ),
        )
      else
        ...scorers.asMap().entries.map(
          (e) => AeRiseIn(
            delay: Duration(milliseconds: e.key * 30),
            child: _buildScorerRow(e.value, e.key == 0),
          ),
        ),
    ];
  }

  Widget _buildQuickCards() {
    final userRow = _userTeamRow();
    final hasTeam = DugnadState.instance.hasPointsTeam;
    final teamSub = hasTeam && userRow != null
        ? languages.dugnadLeaderboardYourTeamCardSub(
            DugnadState.instance.pointsTeamName,
            userRow.rank,
            _data?.teams.length ?? userRow.rank,
          )
        : languages.dugnadLeaderboardChooseTeamSubtitle;
    final pointsSub = languages.dugnadLeaderboardYourPointsCardSub(
      _formatCount(_userLifetimePoints()),
      _tierLabel(),
    );

    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            variant: _LbCtaVariant.team,
            icon: Icons.shield_outlined,
            title: languages.dugnadYourTeam,
            subtitle: teamSub,
            onTap: _openYourTeam,
          ),
        ),
        SizedBox(width: context.dp(10)),
        Expanded(
          child: _QuickCard(
            variant: _LbCtaVariant.points,
            icon: Icons.star_rounded,
            title: languages.dugnadLeaderboardYourPointsTitle,
            subtitle: pointsSub,
            onTap: _openYourPoints,
          ),
        ),
      ],
    );
  }

  Widget _buildPrizeBanner(LeaderboardSeason season) {
    return DugnadPrizeBanner(
      label: languages.dugnadLeaderboardSeasonPrizeLabel,
      title: languages.dugnadLeaderboardSeasonPrizeAmount(
        _formatCount(season.prizeNok),
      ),
      subtitle: languages.dugnadLeaderboardSeasonPrizeNote,
    );
  }

  Widget _buildChooseTeamCta(String clubName) {
    return Material(
      color: context.aeTheme.primaryTint,
      borderRadius: BorderRadius.circular(context.dp(16)),
      child: InkWell(
        onTap: _openPointsTeamPicker,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Padding(
          padding: EdgeInsets.all(context.dp(14)),
          child: Row(
            children: [
              Container(
                width: context.dp(42),
                height: context.dp(42),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: context.aeTheme.primary,
                  size: context.dp(22),
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadLeaderboardChooseTeamInClub(clubName),
                      style: aeTitle(),
                    ),
                    Text(
                      languages.dugnadLeaderboardChooseTeamSubtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.aeTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableColumns() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dp(6)),
      child: Row(
        children: [
          SizedBox(
            width: context.dp(30),
            child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ScSaasThemeTokens.gray500)),
          ),
          SizedBox(width: context.dp(28)),
          Expanded(
            child: Text(
              languages.dugnadLeaderboardTeamHeader,
              style: aeOverline(color: ScSaasThemeTokens.gray500),
            ),
          ),
          Text(
            _pointsUnitLabel(),
            style: aeOverline(color: ScSaasThemeTokens.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeZone(List<LeaderboardTeamRow> teams, int zoneSize) {
    return Container(
      padding: EdgeInsets.all(context.dp(7)),
      decoration: BoxDecoration(
        // 155deg -- a third gradient axis on this screen, steeper than the
        // 135 of .inzone and the 150 of the shiny token.
        gradient: const LinearGradient(
          begin: Alignment(-0.45, -0.9),
          end: Alignment(0.45, 0.9),
          colors: [_kGoldZoneGradientStart, _kGoldZoneGradientEnd],
        ),
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: _kGoldZoneBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.dp(6), context.dp(3), context.dp(6), context.dp(1)),
            child: Row(
              children: [
                Text(
                  '🏆 ${languages.dugnadLeaderboardPrizeZone}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.5 * 0.04,
                    color: _kGoldTag,
                  ),
                ),
                SizedBox(width: context.dp(7)),
                Expanded(
                  child: Container(
                    height: context.dp(1),
                    color: const Color(0x66D8A028),
                  ),
                ),
                SizedBox(width: context.dp(7)),
                Text(
                  languages.dugnadLeaderboardPrizeZoneTop(zoneSize),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.5 * 0.04,
                    color: _kGoldTag,
                  ),
                ),
              ],
            ),
          ),
          // `.lb-zone { gap: 7px }` — matches spacing between rows.
          SizedBox(height: context.dp(7)),
          ...teams.map(
            (team) => _buildTeamRowWithGap(
              team,
              inPrizeZone: true,
              zoneSize: zoneSize,
              cutoff: _data?.prizeZoneCutoffPoints ?? team.lagpoeng,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRowWithGap(
    LeaderboardTeamRow team, {
    bool inPrizeZone = false,
    required int zoneSize,
    required int cutoff,
  }) {
    final inZone = team.rank <= zoneSize;
    final gap = !inZone && cutoff > 0 ? (cutoff - team.lagpoeng + 1) : 0;
    final showGap =
        !inZone && gap > 0 && (team.rank == zoneSize + 1 || team.isUserTeam);

    return Column(
      children: [
        _buildTeamRow(team, inPrizeZone: inPrizeZone),
        if (showGap) _buildGapDivider(gap),
      ],
    );
  }

  Widget _buildGapDivider(int gap) {
    return Padding(
      // `.scl-divider { margin: 3px 4px }`
      padding: EdgeInsets.symmetric(
        vertical: context.dp(3),
        horizontal: context.dp(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.north_east_rounded,
            size: context.dp(14),
            color: ScSaasThemeTokens.gray500,
          ),
          SizedBox(width: context.dp(9)),
          Text(
            languages.dugnadLeaderboardGapToZone(_formatCount(gap)).toUpperCase(),
            // `.scl-divider` is 10.5 / 800 / +0.04em / uppercase / gray-400.
            style: TextStyle(
              fontSize: context.dp(10.5),
              fontWeight: FontWeight.w800,
              letterSpacing: context.dp(10.5) * 0.04,
              color: ScSaasThemeTokens.gray400,
            ),
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Container(height: context.dp(1), color: ScSaasThemeTokens.gray100),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(LeaderboardTeamRow team, {bool inPrizeZone = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(7)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTeamDetail(team.teamId),
          borderRadius: BorderRadius.circular(context.dp(13)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(13),
              vertical: context.dp(11),
            ),
            decoration: BoxDecoration(
              gradient: inPrizeZone
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _kInZoneRowGradientStart,
                        _kInZoneRowGradientEnd,
                      ],
                    )
                  : null,
              color: inPrizeZone ? null : Colors.white,
              borderRadius: BorderRadius.circular(context.dp(13)),
              // `.lb-trow` declares `1.5px solid transparent` and `.mine` only
              // recolours it. The width must not change with selection, or the
              // row reflows by 1px the moment it becomes yours.
              border: Border.all(
                color: team.isUserTeam
                    ? context.aeTheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                if (team.isUserTeam)
                  // `.mine` gets its own lift: 0 12px 26px -16px
                  // rgba(127,95,196,.5). It is not the base shadow recoloured.
                  BoxShadow(
                    color: context.aeTheme.primary.withValues(alpha: 0.5),
                    blurRadius: context.dp(26),
                    offset: Offset(0, context.dp(12)),
                    spreadRadius: context.dp(-16),
                  )
                else
                  BoxShadow(
                    // base 0 1px 3px rgba(45,27,91,.05);
                    // .inzone 0 1px 3px rgba(160,110,10,.12)
                    color: inPrizeZone
                        ? const Color(0xFFA06E0A).withValues(alpha: 0.12)
                        : context.aeTheme.text.withValues(alpha: 0.05),
                    blurRadius: context.dp(3),
                    offset: Offset(0, context.dp(1)),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildRankBadge(team.rank, inPrizeZone: inPrizeZone),
                SizedBox(width: context.dp(6)),
                _RankMoveBadge(move: team.rankMove),
                SizedBox(width: context.dp(6)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(team.name, style: aeTitle()),
                          if (team.isUserTeam)
                            _YouTag(label: languages.dugnadLeaderboardYourTeamTag),
                        ],
                      ),
                      SizedBox(height: context.dp(3)),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sell_outlined,
                                size: context.dp(11),
                                color: ScSaasThemeTokens.gray500,
                              ),
                              SizedBox(width: context.dp(4)),
                              Text(
                                languages.dugnadLeaderboardKrRaised(
                                  _formatCount(team.krRaised.round()),
                                ),
                                style: aeCaption(
                                  color: ScSaasThemeTokens.gray500,
                                ),
                              ),
                            ],
                          ),
                          Text('·', style: aeCaption()),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: context.dp(11),
                                color: ScSaasThemeTokens.gray500,
                              ),
                              SizedBox(width: context.dp(4)),
                              Text(
                                languages.dugnadLeaderboardActiveFamilies(
                                  team.activeFamilies,
                                ),
                                style: aeCaption(
                                  color: ScSaasThemeTokens.gray500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.dp(8)),
                _buildPointsColumn(team.lagpoeng, inPrizeZone: inPrizeZone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScorerRow(LeaderboardScorerRow scorer, bool isHero) {
    if (isHero) {
      return _ScorerHeroCard(
        scorer: scorer,
        tab: _tab,
        formatCount: _formatCount,
        onTap: () => _openScorerCard(scorer),
      );
    }
    return _ScorerListRow(
      scorer: scorer,
      tab: _tab,
      formatCount: _formatCount,
      onTap: () => _openScorerCard(scorer),
    );
  }

  Widget _buildPointsColumn(int points, {required bool inPrizeZone}) {
    // `--ae-purple-700` is derived per club, so a static alias leaves this
    // numeral default-purple under a navy club.
    final purple = context.aeTheme.primaryHover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatCount(points),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            height: context.dp(1),
            letterSpacing: 16 * -0.02,
            color: inPrizeZone ? _kGoldPoints : purple,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: context.dp(3)),
        Text(
          _pointsUnitLabel(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            height: context.dp(1),
            letterSpacing: 8.5 * 0.04,
            color: ScSaasThemeTokens.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(int rank, {bool inPrizeZone = false}) {
    if (rank == 1) return _medalBadge('🥇', inPrizeZone: inPrizeZone);
    if (rank == 2) return _medalBadge('🥈', inPrizeZone: inPrizeZone);
    if (rank == 3) return _medalBadge('🥉', inPrizeZone: inPrizeZone);
    return SizedBox(
      width: context.dp(30),
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: aeTitle(color: ScSaasThemeTokens.gray500),
      ),
    );
  }

  Widget _medalBadge(String emoji, {bool inPrizeZone = false}) {
    return SizedBox(
      width: context.dp(30),
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 21,
          height: context.dp(1),
          color: inPrizeZone ? _kGoldTag : null,
        ),
      ),
    );
  }
}

class _LbSegmentedTabs extends StatelessWidget {
  const _LbSegmentedTabs({required this.selected, required this.onChanged});

  final _LbTab selected;
  final ValueChanged<_LbTab> onChanged;

  /// Prototype: `.lb-tabs-ind.anim` — `transform .36s cubic-bezier(.34,1.18,.4,1)`.
  /// Equal columns so the pill only translates (no width lerp) — that is what
  /// makes the spring feel smooth instead of wobbly.
  static const _indDuration = Duration(milliseconds: 360);
  static const _indCurve = Cubic(0.34, 1.18, 0.4, 1);

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final items = <(_LbTab, String)>[
      (_LbTab.table, languages.dugnadLeaderboardTabTable),
      (_LbTab.topScorer, languages.dugnadLeaderboardTabTopScorer),
      (_LbTab.assistKing, languages.dugnadLeaderboardTabAssistKing),
      (_LbTab.value, languages.dugnadLeaderboardTabValue),
    ];
    final n = items.length;
    final selectedIndex =
        items.indexWhere((e) => e.$1 == selected).clamp(0, n - 1);
    // Map index → Alignment.x in [-1, 1] for equal-width FractionallySizedBox.
    final alignX = n == 1 ? 0.0 : -1.0 + (selectedIndex * 2.0 / (n - 1));
    // `.lb-tabs.four { padding: 3px }`
    final pad = context.dp(3);

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(13)),
      ),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            // Sliding white pill — same motion as `.lb-tabs-ind` / login email tabs.
            Positioned.fill(
              child: AnimatedAlign(
                duration: _indDuration,
                curve: _indCurve,
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.dp(9)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x382D1B5B),
                          blurRadius: context.dp(6),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(item.$1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.dp(9),
                          horizontal: context.dp(2),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.02 * 11,
                            color: selected == item.$1
                                ? theme.primaryHover
                                : const Color(0xFF8C80A8),
                          ),
                          child: Text(
                            item.$2,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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

class _ScorerFilterPills extends StatelessWidget {
  const _ScorerFilterPills({
    required this.mineOnly,
    required this.onChanged,
    required this.canFilterMyTeam,
  });

  final bool mineOnly;
  final ValueChanged<bool> onChanged;
  final bool canFilterMyTeam;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterPill(
          label: languages.dugnadLeaderboardFilterClub,
          icon: Icons.shield_outlined,
          selected: !mineOnly,
          onTap: () => onChanged(false),
        ),
        SizedBox(width: context.dp(9)),
        _FilterPill(
          label: languages.dugnadLeaderboardFilterMyTeam,
          icon: Icons.person_outline_rounded,
          selected: mineOnly,
          onTap: canFilterMyTeam ? () => onChanged(true) : null,
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected ? theme.shinyGradient : null,
            color: selected ? null : Colors.white,
            border: Border.all(
              color: selected ? Colors.transparent : ScSaasThemeTokens.gray100,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.7),
                      blurRadius: context.dp(20),
                      offset: const Offset(0, 10),
                      spreadRadius: -12,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Color(0x0A2D1B5B),
                      blurRadius: context.dp(2),
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dp(16), vertical: context.dp(9)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: context.dp(14),
                  color: selected ? Colors.white : ScSaasThemeTokens.gray500,
                ),
                SizedBox(width: context.dp(7)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.01 * 12.5,
                    color: selected ? Colors.white : ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankMoveBadge extends StatelessWidget {
  const _RankMoveBadge({required this.move});

  final int move;

  @override
  Widget build(BuildContext context) {
    if (move == 0) {
      return SizedBox(
        width: context.dp(22),
        child: Text(
          '–',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ScSaasThemeTokens.gray300,
          ),
        ),
      );
    }

    final up = move > 0;
    return SizedBox(
      width: context.dp(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: context.dp(16),
            color: up ? ScSaasThemeTokens.success : ScSaasThemeTokens.danger,
          ),
          Text(
            '${move.abs()}',
            style: TextStyle(
              // `.lb-move` is 11px / 900 / line-height 1.
              fontSize: context.dp(11),
              fontWeight: FontWeight.w900,
              height: context.dp(1),
              color: up ? ScSaasThemeTokens.success : ScSaasThemeTokens.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTag extends StatelessWidget {
  const _YouTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(7),
        vertical: context.dp(2),
      ),
      decoration: BoxDecoration(
        // `--ae-shiny-purple`, not a flat primary. The token is club-derived,
        // so consuming it keeps the tag on-brand under an override.
        gradient: context.aeTheme.shinyGradient,
        borderRadius: BorderRadius.circular(context.dp(999)),
      ),
      child: Text(
        label,
        style: TextStyle(
          // `.mine-tag` is 800; its neighbour `.cap-tag` is 900. Adjacent
          // badges, different weights -- checked separately.
          fontSize: context.dp(9),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: context.dp(9) * 0.02,
        ),
      ),
    );
  }
}

/// `.lb-cta .ic.purple` | `.lb-cta .ic.amber`
enum _LbCtaVariant { team, points }

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.variant,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final _LbCtaVariant variant;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `.lb-cta`: column, icon above text, absolute chevron top-right.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.dp(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D1B5B).withValues(alpha: 0.05),
                blurRadius: context.dp(4),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(context.dp(13)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.dp(40),
                      height: context.dp(40),
                      decoration: BoxDecoration(
                        // Team: club shiny (admin accent). Points: amber stays
                        // fixed — star/poeng treatment, not club chrome.
                        gradient: variant == _LbCtaVariant.team
                            ? context.aeTheme.shinyGradient
                            : const LinearGradient(
                                begin: Alignment(-0.5, -0.85),
                                end: Alignment(0.5, 0.85),
                                colors: [
                                  Color(0xFFE0A93A),
                                  Color(0xFFC2871C),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(context.dp(11)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: context.dp(19),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: context.dp(9)),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.dp(14),
                        fontWeight: FontWeight.w800,
                        letterSpacing: context.dp(14) * -0.01,
                        color: ScSaasThemeTokens.text,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.dp(11),
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // `.lb-cta .go` — bare chevron at top-right (not a circle).
              Positioned(
                top: context.dp(14),
                right: context.dp(12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: context.dp(17),
                  color: ScSaasThemeTokens.gray300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorerHeroCard extends StatelessWidget {
  const _ScorerHeroCard({
    required this.scorer,
    required this.tab,
    required this.formatCount,
    required this.onTap,
  });

  final LeaderboardScorerRow scorer;
  final _LbTab tab;
  final String Function(int) formatCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stat = _scorerStat(scorer, tab, formatCount);
    final unit = _scorerUnit(tab);
    final isValue = tab == _LbTab.value;
    // List rows are ~58–64px tall; mock wants ~2× for #1.
    const minHeroHeight = 128.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: EdgeInsets.only(bottom: context.dp(12)),
      constraints: const BoxConstraints(minHeight: minHeroHeight),
      decoration: BoxDecoration(
        // `.scl-hero`: 150deg, #ffe9a8 -> #f3c95f. Two stops -- this hero is
        // not a Family A metal surface and must not gain a midpoint.
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [_kHeroGoldStart, _kHeroGoldEnd],
        ),
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          // 0 16px 30px -16px rgba(216,160,40,.75)
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.75),
            blurRadius: context.dp(30),
            offset: Offset(0, context.dp(16)),
            spreadRadius: context.dp(-16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Stack(
          children: [
            // `0 1px 1px rgba(255,255,255,.6) inset` -- the layer that keeps
            // the gold from reading flat (rule 5).
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final h = c.maxHeight.isFinite && c.maxHeight > 0
                        ? c.maxHeight
                        : context.dp(120);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: [0.0, (context.dp(1) / h).clamp(0.004, 0.5)],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Positioned.fill(
              child: DugnadMetalGlazeOverlay(
                borderRadius: 20,
                phase: 0,
                overContent: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(22), context.dp(18), context.dp(22)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: medal + score stack (mockup layout).
                  SizedBox(
                    width: context.dp(72),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🥇', style: TextStyle(fontSize: 34, height: context.dp(1))),
                        SizedBox(height: context.dp(10)),
                        Text(
                          stat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: context.dp(1),
                            letterSpacing: 36 * -0.04,
                            color: Color(0xFF2A1D08),
                          ),
                        ),
                        SizedBox(height: context.dp(4)),
                        Text(
                          unit,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 12 * 0.08,
                            color: Color(0xFF9A6B12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.dp(14)),
                  _ScorerAvatar(
                    size: context.dp(52),
                    hero: true,
                  ),
                  SizedBox(width: context.dp(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              scorer.displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 19 * -0.02,
                                height: 1.15,
                                color: Color(0xFF2A1D08),
                              ),
                            ),
                            if (isValue)
                              _ScorerTierBadge(
                                metal: scorer.tierMetal,
                                label: scorer.tierLabel,
                                large: true,
                              )
                            else if (scorer.stoRating > 0)
                              _ScorerStoBadge(
                                rating: scorer.stoRating,
                                large: true,
                              ),
                            if (scorer.isViewer)
                              _YouTag(label: languages.dugnadLeaderboardYouTag),
                          ],
                        ),
                        SizedBox(height: context.dp(8)),
                        _ScorerMetaLine(scorer: scorer, tab: tab),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ScorerListRow extends StatelessWidget {
  const _ScorerListRow({
    required this.scorer,
    required this.tab,
    required this.formatCount,
    required this.onTap,
  });

  final LeaderboardScorerRow scorer;
  final _LbTab tab;
  final String Function(int) formatCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stat = _scorerStat(scorer, tab, formatCount);
    final unit = _scorerUnit(tab);
    final isValue = tab == _LbTab.value;
    final theme = context.aeTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: EdgeInsets.only(bottom: context.dp(8)),
      padding: EdgeInsets.symmetric(horizontal: context.dp(13), vertical: context.dp(11)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(15)),
        border: Border.all(
          color: scorer.isViewer ? theme.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scorer.isViewer
                ? theme.primary.withValues(alpha: 0.55)
                : const Color(0x0D2D1B5B),
            blurRadius: scorer.isViewer ? context.dp(24) : context.dp(3),
            // `.me` lifts from 10px; the base row sits at 1px.
            offset: Offset(0, context.dp(scorer.isViewer ? 10 : 1)),
            spreadRadius: scorer.isViewer ? context.dp(-16) : 0,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRank(scorer.rank),
          SizedBox(width: context.dp(11)),
          _ScorerAvatar(),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(scorer.displayName, style: aeTitle()),
                    if (isValue)
                      _ScorerTierBadge(
                        metal: scorer.tierMetal,
                        label: scorer.tierLabel,
                      ),
                    if (!isValue && scorer.stoRating > 0)
                      _ScorerStoBadge(rating: scorer.stoRating),
                    if (scorer.isViewer)
                      _YouTag(label: languages.dugnadLeaderboardYouTag),
                  ],
                ),
                SizedBox(height: context.dp(3)),
                _ScorerMetaLine(scorer: scorer, tab: tab),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // `.scl-stat b` — 17px / 900 / -0.02em / tabular-nums. A rank
              // list's changing numeral is the jitter case tabular figures
              // exist for, and the design marks this one explicitly.
              Text(
                stat,
                style: TextStyle(
                  fontSize: context.dp(17),
                  fontWeight: FontWeight.w900,
                  height: context.dp(1),
                  letterSpacing: context.dp(17) * -0.02,
                  color: isValue ? _kGoldPoints : theme.primaryHover,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: context.dp(4)),
              // `.scl-stat small` — 8.5 / 800 / +0.04em / uppercase /
              // gray-400, not the caption default.
              Text(
                unit.toUpperCase(),
                style: TextStyle(
                  fontSize: context.dp(8.5),
                  fontWeight: FontWeight.w800,
                  height: context.dp(1),
                  letterSpacing: context.dp(8.5) * 0.04,
                  color: isValue
                      ? const Color(0xFF8B6914)
                      : ScSaasThemeTokens.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  // No BuildContext in scope here, so these widths cannot route through
  // context.dp — a deliberate skip, left as literals.
  Widget _buildRank(int rank) {
    if (rank == 2) {
      return SizedBox(
        width: 26,
        child: Text('🥈', textAlign: TextAlign.center, style: TextStyle(fontSize: 19)),
      );
    }
    if (rank == 3) {
      return SizedBox(
        width: 26,
        child: Text('🥉', textAlign: TextAlign.center, style: TextStyle(fontSize: 19)),
      );
    }
    return SizedBox(
      width: 26,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: aeTitle(color: ScSaasThemeTokens.gray500),
      ),
    );
  }
}

class _ScorerTierBadge extends StatelessWidget {
  const _ScorerTierBadge({
    required this.metal,
    required this.label,
    this.large = false,
  });

  final String metal;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = _metalBadgeStyle(metal);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 9 : 7,
        vertical: large ? 2 : 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Color(0x80FFFFFF),
            blurRadius: context.dp(1),
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: large ? 9 : 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.04 * (large ? 9 : 8.5),
          color: style.text,
        ),
      ),
    );
  }
}

class _ScorerStoBadge extends StatelessWidget {
  const _ScorerStoBadge({required this.rating, this.large = false});

  final int rating;

  /// `.scl-hero .scl-sto` overrides the base to 10.5px with padding
  /// `2px 8px 2px 7px`. Its sibling `_ScorerTierBadge` already carries the
  /// equivalent flag; this one did not, so the hero rendered the row's size.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 10.5 : 9.5;
    return Container(
      padding: large
          ? EdgeInsets.fromLTRB(
              context.dp(7), context.dp(2), context.dp(8), context.dp(2))
          : EdgeInsets.fromLTRB(
              context.dp(6), context.dp(2), context.dp(7), context.dp(2)),
      decoration: BoxDecoration(
        color: context.aeTheme.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_rounded,
            size: context.dp(10),
            color: context.aeTheme.primary,
          ),
          SizedBox(width: context.dp(3)),
          // `.scl-sto` is 800; only its `b` -- the rating itself -- is 900.
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: context.dp(size),
                fontWeight: FontWeight.w800,
                letterSpacing: context.dp(size) * 0.01,
                color: context.aeTheme.primaryHover,
              ),
              children: [
                const TextSpan(text: 'STØ '),
                TextSpan(
                  text: '$rating',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

({List<Color> gradient, Color text}) _metalBadgeStyle(String metal) {
  switch (metal) {
    case 'gull':
      return (
        gradient: [const Color(0xFFF7D979), const Color(0xFFE7B542)],
        text: const Color(0xFF7A5410),
      );
    case 'solv':
      return (
        gradient: [const Color(0xFFEDEBF2), const Color(0xFFDCD8E6)],
        text: const Color(0xFF5D5870),
      );
    case 'platina':
      return (
        gradient: [const Color(0xFFE7EDF6), const Color(0xFFC6D3E8)],
        text: const Color(0xFF34466B),
      );
    case 'bronse':
    default:
      return (
        gradient: [const Color(0xFFF4D9BF), const Color(0xFFE3B48B)],
        text: const Color(0xFF7A4420),
      );
  }
}

/// Mini player avatar + club crest badge — mirrors `ScorerAva` / `.scl-ava`.
class _ScorerAvatar extends StatelessWidget {
  const _ScorerAvatar({
    this.size = 42,
    this.hero = false,
  });

  final double size;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final clubName = DugnadClubBranding.fullName();
    final logo = DugnadState.instance.clubLogo.trim();
    final logoUrl = logo.isEmpty ? null : logo;

    // Crest badge: 21px on the 42px base; scale with size (hero 52 → ~26).
    final crestBox = (size * (21 / 42)).clamp(18.0, 26.0);
    final crestInner = crestBox - 4;

    // `.scl-hero .scl-ava .face` vs default `.scl-ava .face`.
    final faceBg = hero
        ? Colors.white.withValues(alpha: 0.55)
        : theme.primaryTint;
    final faceFg = hero ? const Color(0xFF9A6B12) : theme.primaryHover;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: faceBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            // Lucide `user` stroke — outline reads closer than filled Material.
            child: Icon(
              Icons.person_outline_rounded,
              size: size * (20 / 42),
              color: faceFg,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: crestBox,
              height: crestBox,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(crestBox * (7 / 21)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D1B5B).withValues(alpha: 0.28),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: AeClubCrest(
                name: clubName.isNotEmpty ? clubName : '?',
                logoUrl: logoUrl,
                size: crestInner,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorerMetaLine extends StatelessWidget {
  const _ScorerMetaLine({required this.scorer, required this.tab});

  final LeaderboardScorerRow scorer;
  final _LbTab tab;

  @override
  Widget build(BuildContext context) {
    final dotColor = _tierDotColor(scorer.tierKey);
    final tierLabel = scorer.tierTitle.isNotEmpty
        ? scorer.tierTitle
        : DugnadClubBranding.tierTitle(scorer.tierKey);
    final text = tab == _LbTab.value
        ? tierLabel
        : '$tierLabel · ${scorer.teamName}';

    return Row(
      children: [
        Container(
          // `.scl-lvl .dot` is 6x6.
          width: context.dp(6),
          height: context.dp(6),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: context.dp(5)),
        Expanded(
          child: Text(
            text,
            // `.scl-lvl` is 10.5 / 700, not the caption default.
            style: TextStyle(
              fontSize: context.dp(10.5),
              fontWeight: FontWeight.w700,
              color: tab == _LbTab.value
                  ? const Color(0xB85A3C0A)
                  : ScSaasThemeTokens.gray500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Color _tierDotColor(String tierKey) {
  switch (tierKey) {
    case 'helt':
      return const Color(0xFF707C8E);
    case 'legende':
      return const Color(0xFFC8942E);
    case 'ikon':
      return const Color(0xFF8D9CC7);
    case 'supporter':
    default:
      return const Color(0xFFA46321);
  }
}

String _scorerStat(
  LeaderboardScorerRow scorer,
  _LbTab tab,
  String Function(int) formatCount,
) {
  switch (tab) {
    case _LbTab.assistKing:
      return formatCount(scorer.assists);
    case _LbTab.value:
      // Chunk K: display STØ rating only. The deprecated `markedsverdi` field
      // is kept in seed data but must NEVER be shown (money framing under a STØ
      // label). No fallback — show 0 if the rating is unset. Model/ranking/sort
      // untouched.
      return formatCount(scorer.stoRating);
    case _LbTab.topScorer:
    case _LbTab.table:
      return formatCount(scorer.goals);
  }
}

String _scorerUnit(_LbTab tab) {
  switch (tab) {
    case _LbTab.assistKing:
      return languages.dugnadLeaderboardAssistUnit;
    case _LbTab.value:
      return languages.dugnadLeaderboardValueUnit;
    case _LbTab.topScorer:
    case _LbTab.table:
      return languages.dugnadLeaderboardGoalUnit;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest steps card — shown inside the normal leaderboard chrome.
// ─────────────────────────────────────────────────────────────────────────────

class _GuestStepsCard extends StatelessWidget {
  const _GuestStepsCard({
    required this.onCta,
    this.forChooseClub = false,
  });
  final VoidCallback onCta;
  final bool forChooseClub;

  String get _title => forChooseClub
      ? languages.dugnadLeaderboardNoClubTitle
      : languages.dugnadLeaderboardGuestTitle;

  String get _body => forChooseClub
      ? languages.dugnadLeaderboardNoClubBody
      : languages.dugnadLeaderboardGuestBody;

  String get _step1Title => forChooseClub
      ? languages.dugnadLeaderboardNoClubStep1Title
      : languages.dugnadLeaderboardGuestStep1Title;

  String get _step1Body => forChooseClub
      ? languages.dugnadLeaderboardNoClubStep1Body
      : languages.dugnadLeaderboardGuestStep1Body;

  String get _step2Title => forChooseClub
      ? languages.dugnadLeaderboardGuestStep2Title
      : languages.dugnadLeaderboardGuestStep2Title;

  String get _step2Body => forChooseClub
      ? languages.dugnadLeaderboardGuestStep2Body
      : languages.dugnadLeaderboardGuestStep2Body;

  String get _step3Title => forChooseClub
      ? languages.dugnadLeaderboardGuestStep3Title
      : languages.dugnadLeaderboardGuestStep3Title;

  String get _step3Body => forChooseClub
      ? languages.dugnadLeaderboardGuestStep3Body
      : languages.dugnadLeaderboardGuestStep3Body;

  String get _cta => forChooseClub
      ? languages.dugnadChooseClub
      : languages.dugnadLeaderboardGuestCta;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final titleColor =
        forChooseClub ? const Color(0xFF16304F) : theme.text;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dp(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy icon in club color
          Container(
            width: context.dp(60),
            height: context.dp(60),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(context.dp(16)),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.22),
                  blurRadius: context.dp(18),
                  offset: Offset(0, context.dp(8)),
                  spreadRadius: context.dp(-2),
                ),
              ],
            ),
            child: Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: context.dp(28)),
          ),
          SizedBox(height: context.dp(24)),

          // Title
          Text(
            _title,
            textAlign: TextAlign.center,
            style: aeH2(color: titleColor)
                .copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 22 * -0.02,
                  height: 1.2,
                )
                .dp(context),
          ),
          SizedBox(height: context.dp(10)),

          // Body text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.dp(8)),
            child: Text(
              _body,
              textAlign: TextAlign.center,
              style: aeBody(color: ScSaasThemeTokens.gray500)
                  .copyWith(fontSize: 13.5, height: 1.55, fontWeight: FontWeight.w500)
                  .dp(context),
            ),
          ),
          SizedBox(height: context.dp(26)),

          // Steps inside a white rounded card with border
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: context.dp(18), vertical: context.dp(18)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(18)),
              border: Border.all(color: ScSaasThemeTokens.gray100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF140C28).withValues(alpha: 0.08),
                  blurRadius: context.dp(18),
                  offset: Offset(0, context.dp(6)),
                  spreadRadius: context.dp(-4),
                ),
              ],
            ),
            child: Column(
              children: [
                _GuestStep(
                  number: 1,
                  title: _step1Title,
                  body: _step1Body,
                  isLast: false,
                ),
                _GuestStep(
                  number: 2,
                  title: _step2Title,
                  body: _step2Body,
                  isLast: false,
                ),
                _GuestStep(
                  number: 3,
                  title: _step3Title,
                  body: _step3Body,
                  isLast: true,
                ),
              ],
            ),
          ),
          SizedBox(height: context.dp(24)),

          // CTA button — full width in club primary
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onCta,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: context.dp(16)),
                decoration: BoxDecoration(
                  gradient: theme.shinyGradient,
                  borderRadius: BorderRadius.circular(context.dp(16)),
                  boxShadow: theme.shadowButton,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cta,
                      style: aeLabel(color: Colors.white)
                          .copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 15 * -0.01,
                          )
                          .dp(context),
                    ),
                    SizedBox(width: context.dp(6)),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: context.dp(20)),
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

class _GuestStep extends StatelessWidget {
  const _GuestStep({
    required this.number,
    required this.title,
    required this.body,
    required this.isLast,
  });
  final int number;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final stepTitleColor =
        DugnadState.instance.hasClub ? theme.text : const Color(0xFF16304F);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number bubble + connector line
          Column(
            children: [
              Container(
                width: context.dp(28),
                height: context.dp(28),
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.dp(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: context.dp(2),
                    margin: EdgeInsets.symmetric(vertical: context.dp(4)),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: context.dp(14)),

          // Step text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : context.dp(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.dp(4)),
                  Text(
                    title,
                    style: aeLabel(color: stepTitleColor)
                        .copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 14 * -0.01,
                        )
                        .dp(context),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    body,
                    style: aeBody(color: ScSaasThemeTokens.gray500)
                        .copyWith(fontSize: 12.5, fontWeight: FontWeight.w500)
                        .dp(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

