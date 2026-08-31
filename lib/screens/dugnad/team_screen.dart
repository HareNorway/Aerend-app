import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'donation_manage_screen.dart';
import 'donation_setup_screen.dart';
import 'dugnad_club_branding.dart';
import '../../ui/kit/ae_theme.dart';
import 'dugnad_models.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'dugnad_sto_utils.dart';
import 'matkasse_campaign_screen.dart';
import 'points_metal_theme.dart';
import 'widgets/dugnad_metal_animations.dart';
import '../../ui/kit/ae_rise_in.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import 'widgets/mk_campaign_card.dart';
import 'widgets/supporter_preview_sheet.dart';
import 'widgets/team_support_sheet.dart';
import 'widgets/troppen_sheet.dart';

enum _TeamScorerTab { topScorer, assistKing }

/// Lag-detalj — troppen, standing, lagets toppliste (prototype: TeamDetailScreen).
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.teamId});

  final int teamId;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final DugnadRepo _repo = DugnadRepo();

  TeamDetailData? _data;
  LeaderboardScorersData? _scorers;
  bool _loading = true;
  bool _loadingScorers = false;
  _TeamScorerTab _scorerTab = _TeamScorerTab.topScorer;
  String? _loadedScorerKey;

  @override
  void initState() {
    super.initState();
    DugnadState.instance.revision.addListener(_onStateChanged);
    _load();
  }

  @override
  void dispose() {
    DugnadState.instance.revision.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    if (!DugnadState.instance.hasClub) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _repo.getTeamDetail(
        DugnadState.instance.clubId,
        widget.teamId,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
          _loadedScorerKey = null;
        });
        _loadScorers();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _scorerTabApi(_TeamScorerTab tab) =>
      tab == _TeamScorerTab.assistKing ? 'assistkonge' : 'toppscorer';

  Future<void> _loadScorers() async {
    if (!DugnadState.instance.hasClub || _data == null) return;
    final key = '${_scorerTabApi(_scorerTab)}:${widget.teamId}';
    if (_loadedScorerKey == key && _scorers != null) return;

    setState(() => _loadingScorers = true);
    try {
      final data = await _repo.getLeaderboardScorers(
        DugnadState.instance.clubId,
        tab: _scorerTabApi(_scorerTab),
        teamId: widget.teamId,
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

  void _setScorerTab(_TeamScorerTab tab) {
    if (_scorerTab == tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _scorerTab = tab;
      _loadedScorerKey = null;
    });
    _loadScorers();
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern(languages.localeName).format(value);
  }

  String _rankSubtitle(TeamDetailData data) {
    var sub = languages.dugnadTeamDetailRankOf(
      data.rank,
      data.teamCount,
      data.clubName,
    );
    if (data.rank == 1) {
      sub = '$sub · Gull-plass';
    } else if (data.rank == 2) {
      sub = '$sub · Sølv-plass';
    } else if (data.rank == 3) {
      sub = '$sub · Bronse-plass';
    }
    return sub;
  }

  List<LeaderboardScorerRow> _orderedSquad(TeamDetailData data) {
    final squad = List<LeaderboardScorerRow>.from(data.squad);
    LeaderboardScorerRow? captain;
    final capId = data.captainUserId;
    if (capId != null) {
      final idx = squad.indexWhere((s) => s.userId == capId);
      if (idx >= 0) captain = squad.removeAt(idx);
    }
    squad.sort((a, b) => b.seasonPoints.compareTo(a.seasonPoints));
    if (captain != null) squad.insert(0, captain);
    return squad;
  }

  void _openSupporterPreview(LeaderboardScorerRow scorer) {
    final teamName = _data?.teamName ?? '';
    HapticFeedback.lightImpact();
    showSupporterPreviewSheet(
      context: context,
      scorer: scorer,
      teamName: teamName,
    );
  }

  void _openTroppenSheet(TeamDetailData data) {
    HapticFeedback.lightImpact();
    showTroppenSheet(
      context: context,
      teamName: data.teamName,
      activeFamilies: data.activeFamilies,
      squad: _orderedSquad(data),
      captainUserId: data.captainUserId,
      anonymousCount: data.squadAnonymousCount,
      onOpenScorer: _openSupporterPreview,
    );
  }

  void _openDonationSetup() {
    HapticFeedback.lightImpact();
    openScreen(
      context,
      DonationSetupScreen(initialTeamId: widget.teamId),
    );
  }

  void _openDonationManage() {
    HapticFeedback.lightImpact();
    openScreen(context, const DonationManageScreen());
  }

  void _onFastStotte(TeamDetailData data) {
    // From the choice sheet only — always open setup with this team selected.
    _openDonationSetup();
  }

  void _openCampaign(ClubCampaignSummary campaign) {
    HapticFeedback.lightImpact();
    openScreen(
      context,
      MatkasseCampaignScreen(
        slug: campaign.slug,
        campaignName: campaign.displayTitle,
      ),
    );
  }

  void _openMatkasserTab(String teamName) {
    final home = context.findAncestorStateOfType<HomeMainV1State>();
    DugnadState.instance.setPendingKampanjeTeamFilter(teamName);
    Navigator.of(context).popUntil((route) => route.isFirst);
    home?.switchToTab(1);
  }

  void _showSupportSheet(TeamDetailData data) {
    HapticFeedback.lightImpact();
    final camp = data.activeCampaign;
    final campaignSubtitle = camp != null
        ? '${camp.displayTitle} — en andel går til laget' // TODO(l10n)
        : 'Se matkasser fra klubben'; // TODO(l10n)
    showTeamSupportSheet(
      context: context,
      teamName: data.teamName,
      campaignSubtitle: campaignSubtitle,
      onFastStotte: () {
        if (!mounted) return;
        _onFastStotte(data);
      },
      onBuyCampaign: () {
        if (!mounted) return;
        if (camp != null) {
          _openCampaign(camp);
        } else {
          _openMatkasserTab(data.teamName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubName = _data?.clubName ?? DugnadClubBranding.fullName();
    final clubLogo = _data?.clubLogo ??
        (DugnadState.instance.clubLogo.isEmpty
            ? null
            : DugnadState.instance.clubLogo);
    final heroTitle = _data?.teamName ?? '';

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: context.aeTheme.primary,
        body: _data == null && !_loading
            ? Center(
                child: Text(
                  languages.dugnadLeaderboardEmpty,
                  style: aeBody(color: Colors.white.withValues(alpha: 0.9)),
                ),
              )
            : AeScrollBody(
                hero: AeHero(
                  clubName: clubName,
                  clubLogo: clubLogo,
                  title: heroTitle,
                  onBack: () => Navigator.maybePop(context),
                ),
                bottomPadding: 40,
                itemGap: 14,
                topPadding: 18,
                feedRadius: 22,
                overlap: 12,
                children: _loading
                    ? const [DugnadTeamDetailFeedSkeleton()]
                    : _buildFeed(),
              ),
      ),
    );
  }

  List<Widget> _buildFeed() {
    final data = _data!;
    final orderedSquad = _orderedSquad(data);
    // Design `TeamDetailScreen`: show up to 5 cards + «+N flere».
    final shownSquad = orderedSquad.take(5).toList(growable: false);
    final moreCount = [
      data.activeFamilies - shownSquad.length,
      data.squadAnonymousCount,
      orderedSquad.length - shownSquad.length,
    ].reduce((a, b) => a > b ? a : b).clamp(0, 999999);

    return [
      _riseIn(
        0,
        _TeamStandingCard(
          rank: data.rank,
          teamName: data.teamName,
          subtitle: _rankSubtitle(data),
          avgSto: data.avgSto,
          rankMove: data.rankMove,
        ),
      ),
      if (data.inPrizeZone) _riseIn(1, const _PrizeZoneBadge()),
      _riseIn(
        data.inPrizeZone ? 2 : 1,
        _TeamStatsRow(
          lagpoeng: data.lagpoeng,
          activeFamilies: data.activeFamilies,
          formatCount: _formatCount,
        ),
      ),
      _riseIn(
        data.inPrizeZone ? 3 : 2,
        data.supportsTeam
            ? _SupportedTeamCard(
                clubName: data.clubName,
                supportViaOrg: data.supportViaOrg,
                donationAmountKr: data.donationAmountKr,
                onTap: _openDonationManage,
              )
            : _SupportGradientButton(
                onTap: () => _showSupportSheet(data),
              ),
      ),
      _riseIn(
        data.inPrizeZone ? 4 : 3,
        data.activeCampaign != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AeSectionLabel('Aktiv kampanje'), // TODO(l10n)
                  MkCampaignCard(
                    campaign: data.activeCampaign!,
                    onTap: () => _openCampaign(data.activeCampaign!),
                  ),
                ],
              )
            : _NoCampaignBanner(teamName: data.teamName),
      ),
      _riseIn(
        data.inPrizeZone ? 5 : 4,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AeSectionLabel('Troppen'), // TODO(l10n)
            _SquadAggBar(
              activeFamilies: data.activeFamilies,
              teamName: data.teamName,
            ),
            SizedBox(height: context.dp(12)),
            _SquadRail(
              squad: shownSquad,
              captainUserId: data.captainUserId,
              moreCount: moreCount,
              onOpenScorer: _openSupporterPreview,
              onMore: () => _openTroppenSheet(data),
            ),
            SizedBox(height: context.dp(10)),
            const _PrivacyNote(),
          ],
        ),
      ),
      _riseIn(
        data.inPrizeZone ? 6 : 5,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AeSectionLabel('Lagets toppliste'), // TODO(l10n)
            _TeamScorerTabs(
              selected: _scorerTab,
              onChanged: _setScorerTab,
            ),
            SizedBox(height: context.dp(12)),
            if (_loadingScorers)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.dp(24)),
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_scorerTab),
                  child: _TeamScorerSection(
                    tab: _scorerTab,
                    teamName: data.teamName,
                    scorers: _scorers?.scorers ?? const [],
                    formatCount: _formatCount,
                    onOpenScorer: _openSupporterPreview,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

// ── Standing card (.lb-standing) ─────────────────────────────────────────────

class _TeamStandingCard extends StatefulWidget {
  const _TeamStandingCard({
    required this.rank,
    required this.teamName,
    required this.subtitle,
    required this.avgSto,
    required this.rankMove,
  });

  final int rank;
  final String teamName;
  final String subtitle;
  final int avgSto;
  final int rankMove;

  @override
  State<_TeamStandingCard> createState() => _TeamStandingCardState();
}

class _TeamStandingCardState extends State<_TeamStandingCard> {
  bool _stoTipOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final st = _podiumStandingStyle(widget.rank, theme);
    final r = BorderRadius.circular(context.dp(18));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: st.drop,
                blurRadius: context.dp(32),
                offset: Offset(0, context.dp(16)),
                spreadRadius: context.dp(-16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: r,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: st.gradient),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight.isFinite && c.maxHeight > 0
                            ? c.maxHeight
                            : context.dp(70);
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: st.insetAlpha),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: [
                                0.0,
                                (context.dp(1) / h).clamp(0.004, 0.5),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(16),
                    vertical: context.dp(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: context.dp(44),
                        child: Text(
                          st.rankLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: st.rankFontSize,
                            fontWeight: FontWeight.w900,
                            color: st.text,
                            height: 1,
                            letterSpacing: st.rankFontSize * -0.03,
                          ),
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.teamName,
                              style: TextStyle(
                                fontSize: context.dp(18),
                                fontWeight: FontWeight.w800,
                                letterSpacing: context.dp(18) * -0.02,
                                color: st.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: context.dp(3)),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: context.dp(12),
                                fontWeight: FontWeight.w600,
                                color: st.text.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.dp(8)),
                      _SnittStoChip(
                        rating: widget.avgSto,
                        open: _stoTipOpen,
                        onTap: () =>
                            setState(() => _stoTipOpen = !_stoTipOpen),
                      ),
                      SizedBox(width: context.dp(6)),
                      _RankMoveBadge(move: widget.rankMove),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_stoTipOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _stoTipOpen = false),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            right: context.dp(4),
            top: context.dp(68),
            left: context.dp(8),
            child: Align(
              alignment: Alignment.topRight,
              child: const _StoTipPopover(),
            ),
          ),
        ],
      ],
    );
  }
}

class _StandingStyle {
  const _StandingStyle({
    required this.gradient,
    required this.text,
    required this.drop,
    required this.insetAlpha,
    required this.rankLabel,
    this.rankFontSize = 30,
  });

  final Gradient gradient;
  final Color text;
  final Color drop;
  final double insetAlpha;
  final String rankLabel;
  final double rankFontSize;
}

_StandingStyle _podiumStandingStyle(int rank, AeThemePalette theme) {
  switch (rank) {
    case 1:
      return const _StandingStyle(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFFFE9A8), Color(0xFFF0C64F)],
        ),
        text: Color(0xFF5B4410),
        drop: Color(0xBFD8A028),
        insetAlpha: 0.55,
        rankLabel: '🥇',
        rankFontSize: 28,
      );
    case 2:
      return const _StandingStyle(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFF1EFF5), Color(0xFFCCC7DA)],
        ),
        text: Color(0xFF45415C),
        drop: Color(0x8099A0B0),
        insetAlpha: 0.5,
        rankLabel: '🥈',
        rankFontSize: 28,
      );
    case 3:
      return const _StandingStyle(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.85),
          end: Alignment(0.5, 0.85),
          colors: [Color(0xFFF3D4AE), Color(0xFFD2945C)],
        ),
        text: Color(0xFF5A3A18),
        drop: Color(0x80C48450),
        insetAlpha: 0.5,
        rankLabel: '🥉',
        rankFontSize: 28,
      );
    default:
      return _StandingStyle(
        gradient: theme.shinyGradient,
        text: Colors.white,
        drop: theme.primary.withValues(alpha: 0.7),
        insetAlpha: 0.35,
        rankLabel: '#$rank',
      );
  }
}

/// `.td-sto` — metal-tinted vertical chip (shield / rating / SNITT-STØ).
class _SnittStoChip extends StatelessWidget {
  const _SnittStoChip({
    required this.rating,
    required this.open,
    required this.onTap,
  });

  final int rating;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = dugnadStoChipColors(rating);
    final ink = chip.fg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(13)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          constraints: BoxConstraints(minWidth: context.dp(52)),
          padding: EdgeInsets.fromLTRB(
            context.dp(10),
            context.dp(5),
            context.dp(10),
            context.dp(6),
          ),
          decoration: BoxDecoration(
            color: chip.bg,
            borderRadius: BorderRadius.circular(context.dp(13)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1F141028),
                blurRadius: open ? context.dp(8) : context.dp(2),
                offset: Offset(0, open ? context.dp(3) : context.dp(1)),
              ),
              if (open)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 0,
                  spreadRadius: context.dp(2),
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: context.dp(13),
                    color: ink,
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    '$rating',
                    style: TextStyle(
                      fontSize: context.dp(19),
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: context.dp(19) * -0.02,
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    'SNITT-STØ', // TODO(l10n)
                    style: TextStyle(
                      fontSize: context.dp(8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.32,
                      height: 1,
                      color: ink.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -2,
                right: -4,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: context.dp(11),
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.td-sto-tip` — STØ explainer popover with arrow + tier pills.
class _StoTipPopover extends StatelessWidget {
  const _StoTipPopover();

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final tiers = <(String metal, String label)>[
      ('bronse', 'Bronse 74+'),
      ('solv', 'Sølv 84+'),
      ('gull', 'Gull 93+'),
      ('platina', 'Platina 99'),
    ];

    return GestureDetector(
      onTap: () {}, // absorb taps so scrim doesn't steal while reading
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dp(300)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // `.td-sto-tip-arw`
            Positioned(
              top: -context.dp(7),
              right: context.dp(20),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: context.dp(14),
                  height: context.dp(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.dp(3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0F1E1446),
                        blurRadius: context.dp(5),
                        offset: Offset(context.dp(-2), context.dp(-2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                context.dp(16),
                context.dp(15),
                context.dp(16),
                context.dp(16),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(16)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x801E1446),
                    blurRadius: context.dp(44),
                    offset: Offset(0, context.dp(20)),
                    spreadRadius: context.dp(-18),
                  ),
                  BoxShadow(
                    color: const Color(0x241E1446),
                    blurRadius: context.dp(8),
                    offset: Offset(0, context.dp(2)),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        size: context.dp(14),
                        color: theme.primaryHover,
                      ),
                      SizedBox(width: context.dp(6)),
                      Text(
                        'STØ-rating', // TODO(l10n)
                        style: TextStyle(
                          fontSize: context.dp(13.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: context.dp(13.5) * -0.01,
                          color: theme.primaryHover,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dp(8)),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: context.dp(12.5),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: ScSaasThemeTokens.gray600,
                      ),
                      children: [
                        TextSpan(
                          text: 'STØ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        const TextSpan(text: ' står for '),
                        TextSpan(
                          text: 'støttespiller-rating',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' — et tall fra 0–99 som viser hvor sterk laget står blant støttespillerne akkurat nå.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.dp(9)),
                  Text(
                    'Lagets STØ er snittet av troppens ratinger. Hver enkelt bygger sin egen rating ved å støtte fast, verve venner og handle gjennom sponsorene.', // TODO(l10n)
                    style: TextStyle(
                      fontSize: context.dp(12.5),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: ScSaasThemeTokens.gray600,
                    ),
                  ),
                  SizedBox(height: context.dp(12)),
                  Wrap(
                    spacing: context.dp(6),
                    runSpacing: context.dp(6),
                    children: [
                      for (final (metal, label) in tiers)
                        Builder(
                          builder: (context) {
                            // Use rating floors so chip colours match mock tiers.
                            final sample = switch (metal) {
                              'platina' => 99,
                              'gull' => 93,
                              'solv' => 84,
                              _ => 74,
                            };
                            final chip = dugnadStoChipColors(sample);
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.dp(9),
                                vertical: context.dp(4),
                              ),
                              decoration: BoxDecoration(
                                color: chip.bg,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x14141028),
                                    blurRadius: context.dp(2),
                                    offset: Offset(0, context.dp(1)),
                                    spreadRadius: context.dp(-1),
                                  ),
                                ],
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: context.dp(10.5),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                  color: chip.fg,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            fontSize: context.dp(12),
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
              fontSize: context.dp(11),
              fontWeight: FontWeight.w900,
              height: 1,
              color: up ? ScSaasThemeTokens.success : ScSaasThemeTokens.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prize zone + stats ───────────────────────────────────────────────────────

class _PrizeZoneBadge extends StatelessWidget {
  const _PrizeZoneBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(12),
          vertical: context.dp(6),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE8A3), Color(0xFFF7D774)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD8A028).withValues(alpha: 0.35),
              blurRadius: context.dp(12),
              offset: Offset(0, context.dp(4)),
            ),
          ],
        ),
        child: Text(
          '🏆 I premie-sonen', // TODO(l10n)
          style: TextStyle(
            fontSize: context.dp(12),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF7A5410),
          ),
        ),
      ),
    );
  }
}

class _TeamStatsRow extends StatelessWidget {
  const _TeamStatsRow({
    required this.lagpoeng,
    required this.activeFamilies,
    required this.formatCount,
  });

  final int lagpoeng;
  final int activeFamilies;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: formatCount(lagpoeng),
            label: 'Lagpoeng', // TODO(l10n)
            icon: Icons.star_rounded,
            iconFilled: true,
            valueColor: theme.primaryHover,
          ),
        ),
        SizedBox(width: context.dp(10)),
        Expanded(
          child: _StatCell(
            value: '$activeFamilies',
            valueSuffix: ' ildsjeler', // TODO(l10n)
            label: 'Aktive støttespillere', // TODO(l10n)
            icon: Icons.person_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    this.iconFilled = false,
    this.valueSuffix = '',
    this.valueColor,
  });

  final String value;
  final String valueSuffix;
  final String label;
  final IconData icon;
  final bool iconFilled;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: AeSurface.card(
        borderRadius: BorderRadius.circular(context.dp(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: context.dp(20),
                    fontWeight: FontWeight.w900,
                    letterSpacing: context.dp(20) * -0.02,
                    color: valueColor ?? theme.text,
                  ),
                ),
                if (valueSuffix.isNotEmpty)
                  TextSpan(
                    text: valueSuffix,
                    style: TextStyle(
                      fontSize: context.dp(13),
                      fontWeight: FontWeight.w700,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.dp(6)),
          Row(
            children: [
              Icon(
                icon,
                size: context.dp(12),
                color: theme.primary,
                fill: iconFilled ? 1.0 : 0.0,
              ),
              SizedBox(width: context.dp(5)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.dp(11),
                    fontWeight: FontWeight.w700,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Support CTAs ─────────────────────────────────────────────────────────────

/// `.td-supported` — confirmation when the viewer already supports this team.
class _SupportedTeamCard extends StatelessWidget {
  const _SupportedTeamCard({
    required this.clubName,
    required this.supportViaOrg,
    required this.donationAmountKr,
    required this.onTap,
  });

  final String clubName;
  final bool supportViaOrg;
  final double? donationAmountKr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final amount = donationAmountKr?.round();
    final subtitle = supportViaOrg
        ? 'Via fast støtte til hele $clubName · administrer' // TODO(l10n)
        : amount != null
            ? '$amount kr/mnd · administrer' // TODO(l10n)
            : 'Administrer fast støtte'; // TODO(l10n)

    final radius = BorderRadius.circular(context.dp(15));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(
              color: const Color(0x6622A769),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 0,
                offset: Offset(0, context.dp(1)),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0x8022A769).withValues(alpha: 0.31),
                blurRadius: context.dp(24),
                offset: Offset(0, context.dp(10)),
                spreadRadius: context.dp(-18),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(15),
              vertical: context.dp(13),
            ),
            child: Row(
              children: [
                Container(
                  width: context.dp(42),
                  height: context.dp(42),
                  decoration: BoxDecoration(
                    color: theme.primaryTint,
                    borderRadius: BorderRadius.circular(context.dp(12)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: context.dp(19),
                    color: theme.primaryHover,
                  ),
                ),
                SizedBox(width: context.dp(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Du støtter dette laget', // TODO(l10n)
                        style: TextStyle(
                          fontSize: context.dp(15),
                          fontWeight: FontWeight.w800,
                          letterSpacing: context.dp(15) * -0.01,
                          color: theme.text,
                        ),
                      ),
                      SizedBox(height: context.dp(2)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: context.dp(11.5),
                          fontWeight: FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: context.dp(28),
                  height: context.dp(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22A769),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: context.dp(15),
                    color: Colors.white,
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

class _SupportGradientButton extends StatelessWidget {
  const _SupportGradientButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // `.td-support` — full-width shiny CTA (mock: heart + «Støtt dette laget»).
    final radius = BorderRadius.circular(context.dp(15));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: theme.shinyGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.55),
                blurRadius: context.dp(28),
                offset: Offset(0, context.dp(14)),
                spreadRadius: context.dp(-14),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(18),
              vertical: context.dp(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded,
                    color: Colors.white, size: context.dp(18)),
                SizedBox(width: context.dp(9)),
                Text(
                  'Støtt dette laget', // TODO(l10n)
                  style: TextStyle(
                    fontSize: context.dp(15.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: context.dp(15.5) * -0.01,
                    color: Colors.white,
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

class _NoCampaignBanner extends StatelessWidget {
  const _NoCampaignBanner({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: theme.primaryTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(10)),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: context.dp(17), color: theme.primaryHover),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Text(
              '$teamName har ingen aktiv matkasse-kampanje akkurat nå. Du kan fortsatt støtte laget fast.', // TODO(l10n)
              style: TextStyle(
                fontSize: context.dp(13),
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: ScSaasThemeTokens.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Troppen ──────────────────────────────────────────────────────────────────

class _SquadAggBar extends StatelessWidget {
  const _SquadAggBar({
    required this.activeFamilies,
    required this.teamName,
  });

  final int activeFamilies;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // `.td-squad-agg` — tinted track + white icon chip (not a solid CTA).
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(12),
      ),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        children: [
          Container(
            width: context.dp(38),
            height: context.dp(38),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.dp(11)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1F2D1B5B),
                  blurRadius: context.dp(3),
                  offset: Offset(0, context.dp(1)),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: theme.primaryHover,
              size: context.dp(18),
            ),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: context.dp(13.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: context.dp(13.5) * -0.01,
                  color: theme.text,
                ),
                children: [
                  TextSpan(
                    text: '$activeFamilies ildsjeler',
                    style: TextStyle(color: theme.primaryHover),
                  ),
                  TextSpan(text: ' støtter $teamName'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadRail extends StatelessWidget {
  const _SquadRail({
    required this.squad,
    required this.captainUserId,
    required this.moreCount,
    required this.onOpenScorer,
    required this.onMore,
  });

  final List<LeaderboardScorerRow> squad;
  final int? captainUserId;
  final int moreCount;
  final void Function(LeaderboardScorerRow scorer) onOpenScorer;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    // Design `.sq-rail`: 3-column grid; up to 5 cards + «+N flere» wrap.
    final showMore = moreCount > 0;
    final gap = context.dp(8);
    final minH = context.dp(136);
    final children = <Widget>[
      for (var i = 0; i < squad.length; i++)
        _SquadCard(
          scorer: squad[i],
          isCaptain:
              captainUserId != null && squad[i].userId == captainUserId,
          onTap: () => onOpenScorer(squad[i]),
        ),
      if (showMore) _SquadMoreButton(count: moreCount, onTap: onMore),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: colW,
                height: minH,
                child: AeRiseIn(
                  delay: Duration(milliseconds: 50 + i * 60),
                  duration: const Duration(milliseconds: 500),
                  child: children[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({
    required this.scorer,
    required this.isCaptain,
    required this.onTap,
  });

  final LeaderboardScorerRow scorer;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final isMe = scorer.isViewer && !isCaptain;
    final metal = scorer.tierMetal.trim().isNotEmpty
        ? scorer.tierMetal
        : dugnadMetalForRating(scorer.stoRating);
    final dot = PointsMetalTheme.colorForMetal(metal);
    final tierLabel = scorer.tierTitle.isNotEmpty
        ? scorer.tierTitle.toLowerCase()
        : DugnadClubBranding.tierTitle(scorer.tierKey).toLowerCase();

    final Gradient? cardGradient;
    final Color borderColor;
    final List<BoxShadow> shadows;
    if (isCaptain) {
      // `.sq-card.cap` — gold metal from admin theme (gull).
      final gull = PointsMetalTheme.seasonCardForMetal('gull');
      cardGradient = LinearGradient(
        begin: const Alignment(-0.4, -1),
        end: const Alignment(0.4, 1),
        colors: gull.gradient.length >= 2
            ? [gull.gradient.first, gull.gradient.last]
            : const [Color(0xFFFFFAF0), Color(0xFFFFEFC4)],
      );
      borderColor = PointsMetalTheme.colorForMetal('gull').withValues(alpha: 0.45);
      shadows = [
        BoxShadow(
          color: PointsMetalTheme.colorForMetal('gull').withValues(alpha: 0.6),
          blurRadius: context.dp(24),
          offset: Offset(0, context.dp(12)),
          spreadRadius: context.dp(-16),
        ),
      ];
    } else if (isMe) {
      // `.sq-card.me`
      cardGradient = LinearGradient(
        begin: const Alignment(-0.4, -1),
        end: const Alignment(0.4, 1),
        colors: [const Color(0xFFFAF8FF), theme.primaryTint],
      );
      borderColor = theme.primary.withValues(alpha: 0.28);
      shadows = [
        BoxShadow(
          color: const Color(0x122D1B5B),
          blurRadius: context.dp(6),
          offset: Offset(0, context.dp(2)),
        ),
      ];
    } else {
      cardGradient = null;
      borderColor = ScSaasThemeTokens.gray100;
      shadows = [
        BoxShadow(
          color: const Color(0x122D1B5B),
          blurRadius: context.dp(6),
          offset: Offset(0, context.dp(2)),
        ),
      ];
    }

    // Fill the rail slot (mock `.sq-card` min-height 136) so every card —
    // captain / member / DEG / +N — shares the same visual size.
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.dp(18)),
          child: Ink(
            decoration: BoxDecoration(
              // Always opaque fill so shadows never show through.
              color: cardGradient == null
                  ? Colors.white
                  : (isCaptain
                      ? PointsMetalTheme.stoChipColors('gull').bg
                      : const Color(0xFFFAF8FF)),
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(context.dp(18)),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: shadows,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(8),
                    context.dp(isCaptain || isMe ? 22 : 16),
                    context.dp(8),
                    context.dp(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SquadAvatar(isCaptain: isCaptain),
                        SizedBox(height: context.dp(10)),
                        Text(
                          scorer.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dp(12.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.dp(12.5) * -0.01,
                            height: 1.15,
                            color: theme.text,
                          ),
                        ),
                        SizedBox(height: context.dp(4)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: context.dp(6),
                              height: context.dp(6),
                              decoration: BoxDecoration(
                                color: dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: context.dp(5)),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: context.dp(88),
                              ),
                              child: Text(
                                tierLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.dp(10.5),
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: ScSaasThemeTokens.gray500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCaptain)
                  Positioned(
                    top: context.dp(8),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(9),
                          vertical: context.dp(2),
                        ),
                        decoration: BoxDecoration(
                          gradient: theme.shinyGradient,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.4),
                              blurRadius: context.dp(6),
                              offset: Offset(0, context.dp(2)),
                            ),
                          ],
                        ),
                        child: Text(
                          '🏅 KAPTEIN',
                          style: TextStyle(
                            fontSize: context.dp(8.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (isMe)
                  Positioned(
                    top: context.dp(8),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(11),
                          vertical: context.dp(2),
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'DEG',
                          style: TextStyle(
                            fontSize: context.dp(8.5),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.34,
                            color: theme.primaryHover,
                          ),
                        ),
                      ),
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

class _SquadAvatar extends StatelessWidget {
  const _SquadAvatar({required this.isCaptain});

  final bool isCaptain;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final logo = DugnadState.instance.clubLogo;
    final faceGradient = isCaptain
        ? const LinearGradient(
            begin: Alignment(-0.4, -1),
            end: Alignment(0.4, 1),
            colors: [Color(0xFFFFF6DD), Color(0xFFFFE2A0)],
          )
        : LinearGradient(
            begin: const Alignment(-0.4, -1),
            end: const Alignment(0.4, 1),
            colors: [const Color(0xFFEFE9FB), theme.primaryTint],
          );
    final faceColor =
        isCaptain ? const Color(0xFF9A6B12) : theme.primaryHover;

    // Keep crest inside the 50×50 box. `right/bottom: -2` with
    // `clipBehavior: Clip.none` painted outside the layout bounds and caused
    // "BOTTOM OVERFLOWED BY 2.1 PIXELS" in the fixed-height troppen rail.
    return SizedBox(
      width: context.dp(50),
      height: context.dp(50),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: context.dp(50),
            height: context.dp(50),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: faceGradient,
            ),
            child: Icon(
              Icons.person_rounded,
              size: context.dp(25),
              color: faceColor,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: context.dp(23),
              height: context.dp(23),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(8)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D2D1B5B),
                    blurRadius: context.dp(5),
                    offset: Offset(0, context.dp(2)),
                  ),
                ],
              ),
              padding: EdgeInsets.all(context.dp(2)),
              child: AeClubCrest(
                name: DugnadClubBranding.compactName(),
                logoUrl: logo.isEmpty ? null : logo,
                size: context.dp(19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadMoreButton extends StatelessWidget {
  const _SquadMoreButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // `.sq-more` — dashed CTA; same slot size as member cards.
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.dp(16)),
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: ScSaasThemeTokens.gray300,
              radius: context.dp(16),
              strokeWidth: 1.5,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+$count',
                    style: TextStyle(
                      fontSize: context.dp(18),
                      fontWeight: FontWeight.w900,
                      letterSpacing: context.dp(18) * -0.02,
                      color: theme.text,
                    ),
                  ),
                  SizedBox(height: context.dp(4)),
                  Text(
                    'flere\nstøttespillere', // TODO(l10n)
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.dp(10.5),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    // `.td-privacy`
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(12),
        vertical: context.dp(11),
      ),
      decoration: BoxDecoration(
        color: ScSaasThemeTokens.gray50,
        borderRadius: BorderRadius.circular(context.dp(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(
              Icons.shield_outlined,
              size: context.dp(15),
              color: ScSaasThemeTokens.gray400,
            ),
          ),
          SizedBox(width: context.dp(9)),
          Expanded(
            child: Text(
              'Vi viser kun støttespillere som har valgt å være synlige. Mindreårige vises med fornavn og initial.', // TODO(l10n)
              style: TextStyle(
                fontSize: context.dp(11),
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: ScSaasThemeTokens.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lagets toppliste ─────────────────────────────────────────────────────────

class _TeamScorerTabs extends StatelessWidget {
  const _TeamScorerTabs({
    required this.selected,
    required this.onChanged,
  });

  final _TeamScorerTab selected;
  final ValueChanged<_TeamScorerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final items = <(_TeamScorerTab, String)>[
      (_TeamScorerTab.topScorer, languages.dugnadLeaderboardTabTopScorer),
      (_TeamScorerTab.assistKing, languages.dugnadLeaderboardTabAssistKing),
    ];
    final selectedLeft = selected == _TeamScorerTab.topScorer;

    // Sliding thumb — same motion as `.lb-tabs-ind` / login email tabs.
    return Container(
      padding: EdgeInsets.all(context.dp(3)),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(13)),
      ),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.34, 1.18, 0.4, 1),
                alignment: selectedLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
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
                      onTap: () {
                        if (selected == item.$1) return;
                        HapticFeedback.selectionClick();
                        onChanged(item.$1);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.dp(9)),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: context.dp(11),
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.dp(11) * -0.02,
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

class _TeamScorerSection extends StatelessWidget {
  const _TeamScorerSection({
    required this.tab,
    required this.teamName,
    required this.scorers,
    required this.formatCount,
    required this.onOpenScorer,
  });

  final _TeamScorerTab tab;
  final String teamName;
  final List<LeaderboardScorerRow> scorers;
  final String Function(int) formatCount;
  final void Function(LeaderboardScorerRow scorer) onOpenScorer;

  @override
  Widget build(BuildContext context) {
    final cap = tab == _TeamScorerTab.assistKing
        ? languages.dugnadLeaderboardScorerCapAssists
        : languages.dugnadLeaderboardScorerCapGoals;

    if (scorers.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.dp(20)),
        child: Text(
          languages.dugnadLeaderboardScorerEmpty(teamName),
          textAlign: TextAlign.center,
          style: aeBody(color: ScSaasThemeTokens.gray500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.dp(10)),
          child: Row(
            children: [
              Icon(
                tab == _TeamScorerTab.assistKing
                    ? Icons.share_rounded
                    : Icons.inventory_2_outlined,
                size: context.dp(13),
                color: context.aeTheme.primary,
              ),
              SizedBox(width: context.dp(6)),
              Expanded(
                child: Text(
                  '$cap · $teamName',
                  style: TextStyle(
                    fontSize: context.dp(11.5),
                    fontWeight: FontWeight.w700,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < scorers.length; i++)
          AeRiseIn(
            delay: Duration(milliseconds: i * 30),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOpenScorer(scorers[i]),
                borderRadius: BorderRadius.circular(context.dp(15)),
                child: i == 0
                    ? _TeamScorerHeroCard(
                        scorer: scorers[i],
                        tab: tab,
                        formatCount: formatCount,
                      )
                    : _TeamScorerListRow(
                        scorer: scorers[i],
                        tab: tab,
                        formatCount: formatCount,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TeamScorerHeroCard extends StatelessWidget {
  const _TeamScorerHeroCard({
    required this.scorer,
    required this.tab,
    required this.formatCount,
  });

  final LeaderboardScorerRow scorer;
  final _TeamScorerTab tab;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    final stat = _teamScorerStat(scorer, tab, formatCount);
    final unit = _teamScorerUnit(tab);
    // Place-1 podium gold — tinted by admin gull metal when configured.
    final gull = PointsMetalTheme.seasonCardForMetal('gull');
    final goldStart = gull.gradient.isNotEmpty
        ? gull.gradient.first
        : const Color(0xFFFFE9A8);
    final goldEnd = gull.gradient.length > 1
        ? gull.gradient.last
        : const Color(0xFFF3C95F);
    final ink = gull.textColor;
    final inkMuted = Color.lerp(ink, goldEnd, 0.35) ?? const Color(0xFF9A6B12);

    return Container(
      margin: EdgeInsets.only(bottom: context.dp(12)),
      constraints: BoxConstraints(minHeight: context.dp(128)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.5, -0.85),
          end: const Alignment(0.5, 0.85),
          colors: [goldStart, goldEnd],
        ),
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: PointsMetalTheme.colorForMetal('gull').withValues(alpha: 0.75),
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
              padding: EdgeInsets.fromLTRB(
                context.dp(16),
                context.dp(22),
                context.dp(18),
                context.dp(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: context.dp(72),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🥇',
                            style: TextStyle(
                                fontSize: context.dp(34), height: 1)),
                        SizedBox(height: context.dp(10)),
                        Text(
                          stat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.dp(36),
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: context.dp(36) * -0.04,
                            color: ink,
                          ),
                        ),
                        SizedBox(height: context.dp(4)),
                        Text(
                          unit,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.dp(12),
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.dp(12) * 0.08,
                            color: inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.dp(14)),
                  _TeamScorerAvatar(size: context.dp(52), hero: true),
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
                              style: TextStyle(
                                fontSize: context.dp(19),
                                fontWeight: FontWeight.w900,
                                letterSpacing: context.dp(19) * -0.02,
                                height: 1.15,
                                color: ink,
                              ),
                            ),
                            if (scorer.stoRating > 0)
                              _TeamScorerStoBadge(
                                rating: scorer.stoRating,
                                large: true,
                              ),
                            if (scorer.isViewer)
                              _TeamYouTag(
                                  label: languages.dugnadLeaderboardYouTag),
                          ],
                        ),
                        SizedBox(height: context.dp(8)),
                        _TeamScorerMetaLine(scorer: scorer),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScorerListRow extends StatelessWidget {
  const _TeamScorerListRow({
    required this.scorer,
    required this.tab,
    required this.formatCount,
  });

  final LeaderboardScorerRow scorer;
  final _TeamScorerTab tab;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    final stat = _teamScorerStat(scorer, tab, formatCount);
    final unit = _teamScorerUnit(tab);
    final theme = context.aeTheme;

    return Container(
      margin: EdgeInsets.only(bottom: context.dp(8)),
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(13),
        vertical: context.dp(11),
      ),
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
            offset: Offset(0, context.dp(scorer.isViewer ? 10 : 1)),
            spreadRadius: scorer.isViewer ? context.dp(-16) : 0,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRank(scorer.rank),
          SizedBox(width: context.dp(11)),
          const _TeamScorerAvatar(),
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
                    if (scorer.stoRating > 0)
                      _TeamScorerStoBadge(rating: scorer.stoRating),
                    if (scorer.isViewer)
                      _TeamYouTag(label: languages.dugnadLeaderboardYouTag),
                  ],
                ),
                SizedBox(height: context.dp(3)),
                _TeamScorerMetaLine(scorer: scorer),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stat,
                style: TextStyle(
                  fontSize: context.dp(17),
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: context.dp(17) * -0.02,
                  color: theme.primaryHover,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: context.dp(4)),
              Text(
                unit.toUpperCase(),
                style: TextStyle(
                  fontSize: context.dp(8.5),
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: context.dp(8.5) * 0.04,
                  color: ScSaasThemeTokens.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRank(int rank) {
    if (rank == 2) {
      return SizedBox(
        width: 26,
        child: Text('🥈',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 19)),
      );
    }
    if (rank == 3) {
      return SizedBox(
        width: 26,
        child: Text('🥉',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 19)),
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

class _TeamScorerAvatar extends StatelessWidget {
  const _TeamScorerAvatar({this.size = 42, this.hero = false});

  final double size;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final clubName = DugnadClubBranding.fullName();
    final logo = DugnadState.instance.clubLogo.trim();
    final logoUrl = logo.isEmpty ? null : logo;

    final crestBox = (size * (21 / 42)).clamp(18.0, 26.0);
    final crestInner = crestBox - 4;

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
            decoration: BoxDecoration(color: faceBg, shape: BoxShape.circle),
            alignment: Alignment.center,
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

class _TeamScorerMetaLine extends StatelessWidget {
  const _TeamScorerMetaLine({required this.scorer});

  final LeaderboardScorerRow scorer;

  @override
  Widget build(BuildContext context) {
    final metal = scorer.tierMetal.trim().isNotEmpty
        ? scorer.tierMetal
        : dugnadMetalForRating(scorer.stoRating);
    final dotColor = PointsMetalTheme.colorForMetal(metal);
    final tierLabel = scorer.tierTitle.isNotEmpty
        ? scorer.tierTitle
        : DugnadClubBranding.tierTitle(scorer.tierKey);

    return Row(
      children: [
        Container(
          width: context.dp(6),
          height: context.dp(6),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: context.dp(5)),
        Expanded(
          child: Text(
            tierLabel,
            style: TextStyle(
              fontSize: context.dp(10.5),
              fontWeight: FontWeight.w700,
              color: ScSaasThemeTokens.gray500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TeamScorerStoBadge extends StatelessWidget {
  const _TeamScorerStoBadge({required this.rating, this.large = false});

  final int rating;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 10.5 : 9.5;
    final chip = dugnadStoChipColors(rating);
    return Container(
      padding: large
          ? EdgeInsets.fromLTRB(
              context.dp(7), context.dp(2), context.dp(8), context.dp(2))
          : EdgeInsets.fromLTRB(
              context.dp(6), context.dp(2), context.dp(7), context.dp(2)),
      decoration: BoxDecoration(
        color: chip.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: context.dp(10), color: chip.fg),
          SizedBox(width: context.dp(3)),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: context.dp(size),
                fontWeight: FontWeight.w800,
                letterSpacing: context.dp(size) * 0.01,
                color: chip.fg,
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

class _TeamYouTag extends StatelessWidget {
  const _TeamYouTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(7),
        vertical: context.dp(2),
      ),
      decoration: BoxDecoration(
        gradient: context.aeTheme.shinyGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.dp(9),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

String _teamScorerStat(
  LeaderboardScorerRow scorer,
  _TeamScorerTab tab,
  String Function(int) formatCount,
) {
  return tab == _TeamScorerTab.assistKing
      ? formatCount(scorer.assists)
      : formatCount(scorer.goals);
}

String _teamScorerUnit(_TeamScorerTab tab) {
  return tab == _TeamScorerTab.assistKing
      ? languages.dugnadLeaderboardAssistUnit
      : languages.dugnadLeaderboardGoalUnit;
}

Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return AeRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
