import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../commonView/surface_decorations.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'donation_manage_screen.dart';
import 'donation_setup_screen.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_points_screen.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'points_team_picker_screen.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'widgets/dugnad_rise_in.dart';
import 'dugnad_club_theme.dart';

const _kBreakdownCampaigns = 'campaigns';
const _kBreakdownEngagement = 'engagement';
const _kBreakdownParticipation = 'participation';

/// Your Team detail — standing, breakdown, climb tips (prototype: YourTeamScreen).
class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final int teamId;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DugnadRepo _repo = DugnadRepo();
  TeamDetailData? _data;
  bool _loading = true;

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
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern(languages.localeName).format(value);
  }

  int _breakdownPoints(String id) {
    final list = _data?.breakdown ?? const [];
    for (final item in list) {
      if (item.id == id) return item.points;
    }
    return 0;
  }

  Future<void> _changeTeam() async {
    final picked = await openPointsTeamPicker(
      context,
      mode: PointsTeamPickerMode.switchTeam,
    );
    if (picked == true && mounted) await _load();
  }

  void _openDonation() {
    final data = _data;
    if (data == null) return;
    HapticFeedback.lightImpact();
    if (data.hasActiveDonation) {
      openScreen(context, const DonationManageScreen());
    } else {
      openScreen(context, const DonationSetupScreen());
    }
  }

  void _openPoints() {
    HapticFeedback.lightImpact();
    openScreen(context, const DugnadPointsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final clubName = DugnadClubBranding.fullName();
    final clubLogo = DugnadState.instance.clubLogo.isEmpty
        ? null
        : DugnadState.instance.clubLogo;

    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: context.dugnadTheme.primary,
        body: _data == null && !_loading
            ? Center(
                child: Text(
                  languages.dugnadLeaderboardEmpty,
                  style: aeBody(color: Colors.white.withValues(alpha: 0.9)),
                ),
              )
            : DugnadLbScrollBody(
                hero: DugnadLbHero(
                  clubName: clubName,
                  clubLogo: clubLogo,
                  title: languages.dugnadTeamDetailHeroTitle,
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
    final campaigns = _breakdownPoints(_kBreakdownCampaigns);
    final engagement = _breakdownPoints(_kBreakdownEngagement);
    final participation = _breakdownPoints(_kBreakdownParticipation);
    final totalBreakdown = campaigns + engagement + participation;

    return [
      _riseIn(0,
        _RankCard(
          rank: data.rank,
          teamName: data.teamName,
          subtitle: languages.dugnadTeamDetailRankOf(
            data.rank,
            data.teamCount,
            data.clubName,
          ),
          onChange: _changeTeam,
        ),
      ),
      _riseIn(1,
        _SupportEntryCard(
          hasActiveDonation: data.hasActiveDonation,
          onTap: _openDonation,
        ),
      ),
      _riseIn(2,
        _SeasonGoalCard(
          title: languages.dugnadTeamDetailSeasonGoal,
          currentPoints: data.lagpoeng,
          goalPoints: data.goalPoints,
          percent: data.goalPercent,
          seasonEnd: data.season.endsAtLabel,
          formatCount: _formatCount,
        ),
      ),
      _riseIn(3,
        _BreakdownSection(
          heading: languages.dugnadTeamDetailBreakdownHeading,
          campaigns: campaigns,
          engagement: engagement,
          participation: participation,
          total: totalBreakdown > 0 ? totalBreakdown : data.lagpoeng,
          activeFamilies: data.activeFamilies,
          formatCount: _formatCount,
        ),
      ),
      _riseIn(4,
        _ClimbSection(
          title: languages.dugnadTeamDetailClimbTitle,
          tips: [
            _ClimbTip(
              icon: Icons.share_rounded,
              title: languages.dugnadTeamDetailClimbReferrals,
              subtitle: languages.dugnadTeamDetailClimbReferralsSub,
            ),
            _ClimbTip(
              icon: Icons.storefront_outlined,
              title: languages.dugnadTeamDetailClimbSponsors,
              subtitle: languages.dugnadTeamDetailClimbSponsorsSub,
            ),
            _ClimbTip(
              icon: Icons.inventory_2_outlined,
              title: languages.dugnadTeamDetailClimbCampaigns,
              subtitle: languages.dugnadTeamDetailClimbCampaignsSub,
            ),
          ],
        ),
      ),
      _riseIn(5,
        _PointsLinkCard(
          title: languages.dugnadYourPoints,
          subtitle: languages.dugnadTeamDetailYourPointsSub,
          onTap: _openPoints,
        ),
      ),
    ];
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.teamName,
    required this.subtitle,
    required this.onChange,
  });

  final int rank;
  final String teamName;
  final String subtitle;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    // `.lb-standing` is four states, not one. The base is --ae-shiny-purple
    // with the `#rank` number; ranks 1-3 add `.podium .gold|silver|bronze`,
    // each a different metal gradient with its own text colour, inset alpha
    // and drop, and a **medal glyph in place of the number**. The app rendered
    // only the base -- always purple, always numeric -- the largest collapsed
    // dimension in the cluster.
    final st = _standingStyle(rank, theme);
    final r = BorderRadius.circular(context.dp(18));

    return DecoratedBox(
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
              child:
                  DecoratedBox(decoration: BoxDecoration(gradient: st.gradient)),
            ),
            // `0 1px 1px rgba(255,255,255,a) inset` -- faked as a top-edge
            // gradient (rule 5); a card with no top highlight reads flat.
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
                          stops: [0.0, (context.dp(1) / h).clamp(0.004, 0.5)],
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
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: context.dp(30),
                      fontWeight: FontWeight.w900,
                      color: st.text,
                      height: context.dp(1),
                      letterSpacing: context.dp(30) * -0.03,
                    ),
                  ),
                  SizedBox(width: context.dp(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
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
                          subtitle,
                          style: TextStyle(
                            fontSize: context.dp(12),
                            fontWeight: FontWeight.w600,
                            color: st.text.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.dp(12)),
                  // `.bytt` is white on every state -- the CSS never overrides
                  // it per podium, so it stays white on the light metals too.
                  TextButton(
                    onPressed: onChange,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      side:
                          BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.dp(14),
                        vertical: context.dp(8),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.dp(999)),
                      ),
                    ),
                    child: Text(
                      languages.dugnadTeamDetailChangeTeam,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: context.dp(12)),
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

/// One `.lb-standing` state: base (purple, numeric) or a podium tone (metal,
/// medal glyph). Four states where the app modelled one.
class _StandingStyle {
  const _StandingStyle({
    required this.gradient,
    required this.text,
    required this.drop,
    required this.insetAlpha,
  });
  final Gradient gradient;
  final Color text;
  final Color drop;
  final double insetAlpha;
}

_StandingStyle _standingStyle(int rank, DugnadClubThemePalette theme) {
  // Ditt lag mock uses club gradient for the hero strip regardless of rank.
  return _StandingStyle(
    gradient: theme.shinyGradient,
    text: Colors.white,
    drop: theme.primary.withValues(alpha: 0.7),
    insetAlpha: 0.35,
  );
}

class _SupportEntryCard extends StatelessWidget {
  const _SupportEntryCard({
    required this.hasActiveDonation,
    required this.onTap,
  });

  final bool hasActiveDonation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final borderRadius = BorderRadius.circular(context.dp(16));
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: BoxDecoration(
            gradient: theme.shinyGradient,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.55),
                blurRadius: context.dp(26),
                offset: Offset(0, context.dp(14)),
                spreadRadius: context.dp(-14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(42),
                height: context.dp(42),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(context.dp(12)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: context.dp(20),
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadTeamDetailSupportTitle,
                      style: aeTitle().copyWith(color: Colors.white),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      languages.dugnadTeamDetailSupportSub,
                      style:
                          aeCaption(color: Colors.white.withValues(alpha: 0.88)),
                    ),
                  ],
                ),
              ),
              if (hasActiveDonation)
                Container(
                  width: context.dp(30),
                  height: context.dp(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: context.dp(18),
                  ),
                )
              else
                Container(
                  width: context.dp(30),
                  height: context.dp(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: context.dp(18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonGoalCard extends StatelessWidget {
  const _SeasonGoalCard({
    required this.title,
    required this.currentPoints,
    required this.goalPoints,
    required this.percent,
    required this.seasonEnd,
    required this.formatCount,
  });

  final String title;
  final int currentPoints;
  final int goalPoints;
  final int percent;
  final String seasonEnd;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0, 100);

    return Container(
      padding: EdgeInsets.all(context.dp(16)),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(context.dp(16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: aeTitle())),
              Text(
                '${formatCount(currentPoints)} / ${formatCount(goalPoints)}',
                style: aeCaption(color: ScSaasThemeTokens.gray500),
              ),
            ],
          ),
          SizedBox(height: context.dp(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.dp(6)),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: ScSaasThemeTokens.gray100,
              color: context.dugnadTheme.primary,
            ),
          ),
          SizedBox(height: context.dp(10)),
          Row(
            children: [
              Text(
                languages.dugnadTeamDetailGoalPercent(pct),
                style: aeCaption(color: ScSaasThemeTokens.gray500),
              ),
              const Spacer(),
              if (seasonEnd.isNotEmpty)
                Text(
                  languages.dugnadLeaderboardSeasonEnds(seasonEnd),
                  style: aeCaption(color: ScSaasThemeTokens.gray500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.heading,
    required this.campaigns,
    required this.engagement,
    required this.participation,
    required this.total,
    required this.activeFamilies,
    required this.formatCount,
  });

  final String heading;
  final int campaigns;
  final int engagement;
  final int participation;
  final int total;
  final int activeFamilies;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total > 0 ? total : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSectionLabel(heading),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.dp(6)),
          child: Row(
            children: [
              if (campaigns > 0)
                Expanded(
                  flex: campaigns,
                  child: Container(
                    height: context.dp(6),
                    color: context.dugnadTheme.primary,
                  ),
                ),
              if (engagement > 0)
                Expanded(
                  flex: engagement,
                  child: Container(
                    height: context.dp(6),
                    color: ScSaasThemeTokens.success,
                  ),
                ),
              if (participation > 0)
                Expanded(
                  flex: participation,
                  child: Container(
                    height: context.dp(6),
                    color: ScSaasThemeTokens.warning,
                  ),
                ),
              if (campaigns + engagement + participation == 0)
                Expanded(
                  child: Container(
                    height: context.dp(6),
                    color: ScSaasThemeTokens.gray100,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.dp(12)),
        _BreakdownRow(
          color: context.dugnadTheme.primary,
          icon: Icons.inventory_2_outlined,
          title: languages.dugnadTeamDetailBreakdownCampaigns,
          subtitle: languages.dugnadTeamDetailBreakdownCampaignsSub,
          points: campaigns,
          formatCount: formatCount,
          share: campaigns / safeTotal,
        ),
        SizedBox(height: context.dp(8)),
        _BreakdownRow(
          color: ScSaasThemeTokens.success,
          icon: Icons.storefront_outlined,
          title: languages.dugnadTeamDetailBreakdownEngagement,
          subtitle: languages.dugnadTeamDetailBreakdownEngagementSub,
          points: engagement,
          formatCount: formatCount,
          share: engagement / safeTotal,
        ),
        SizedBox(height: context.dp(8)),
        _BreakdownRow(
          color: ScSaasThemeTokens.warning,
          icon: Icons.people_outline_rounded,
          title: languages.dugnadTeamDetailBreakdownParticipation,
          subtitle: languages.dugnadTeamDetailBreakdownParticipationSub(
            activeFamilies,
          ),
          points: participation,
          formatCount: formatCount,
          share: participation / safeTotal,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.formatCount,
    required this.share,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final int points;
  final String Function(int) formatCount;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.dp(12)),
      decoration: AeSurface.card(borderRadius: BorderRadius.circular(context.dp(14))),
      child: Row(
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(context.dp(10)),
            ),
            child: Icon(icon, size: context.dp(18), color: color),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: aeTitle()),
                Text(
                  subtitle,
                  style: aeCaption(color: ScSaasThemeTokens.gray500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCount(points),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A3D96),
                ),
              ),
              Text(
                '${(share * 100).round()}%',
                style: aeCaption(color: ScSaasThemeTokens.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClimbTip {
  const _ClimbTip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ClimbSection extends StatelessWidget {
  const _ClimbSection({required this.title, required this.tips});

  final String title;
  final List<_ClimbTip> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `.lb-climb { background: var(--ae-purple-100); border-radius: 16px;
      //   padding: 14px 15px }` -- and no border around the card. The design
      // draws a border here only as a row separator; the ring the app added
      // is the third undeclared border found in this port.
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(15),
        vertical: context.dp(14),
      ),
      decoration: BoxDecoration(
        color: context.dugnadTheme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(16)),
        // Match white cards (AeSurface.card) so the climb tip panel lifts
        // off the feed instead of reading as a flat tint block.
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: context.dp(16),
                color: context.dugnadTheme.primaryHover,
              ),
              SizedBox(width: context.dp(7)),
              // `.lb-climb-head` is 13 / 800 / -0.01em / purple-700.
              Text(
                title,
                style: TextStyle(
                  fontSize: context.dp(13),
                  fontWeight: FontWeight.w800,
                  letterSpacing: context.dp(13) * -0.01,
                  color: context.dugnadTheme.primaryHover,
                ),
              ),
            ],
          ),
          SizedBox(height: context.dp(10)),
          for (var i = 0; i < tips.length; i++) ...[
            // `.lb-climb .row + .row { border-top: 1px solid
            // rgba(127,95,196,.14) }` -- a separator between adjacent rows,
            // which the app was rendering as a plain 10px gap.
            if (i > 0)
              Container(
                height: context.dp(1),
                color: const Color(0xFF7F5FC4).withValues(alpha: 0.14),
              ),
            Padding(
              // `.row { padding: 7px 0 }`
              padding: EdgeInsets.symmetric(vertical: context.dp(7)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.dp(30),
                    height: context.dp(30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.dp(9)),
                    ),
                    child: Icon(tips[i].icon,
                        size: context.dp(15),
                        color: context.dugnadTheme.primaryHover),
                  ),
                  SizedBox(width: context.dp(11)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // `.t` 13 / 800 / -0.01em / midnight
                        Text(
                          tips[i].title,
                          style: TextStyle(
                            fontSize: context.dp(13),
                            fontWeight: FontWeight.w800,
                            letterSpacing: context.dp(13) * -0.01,
                            color: context.dugnadTheme.text,
                          ),
                        ),
                        SizedBox(height: context.dp(1)),
                        // `.s` 11 / 600 / purple-700 at opacity .8 -- a tinted
                        // purple, not a grey. Kind, not just degree.
                        Text(
                          tips[i].subtitle,
                          style: TextStyle(
                            fontSize: context.dp(11),
                            fontWeight: FontWeight.w600,
                            color: context.dugnadTheme.primaryHover
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsLinkCard extends StatelessWidget {
  const _PointsLinkCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.dp(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Container(
          padding: EdgeInsets.all(context.dp(14)),
          decoration: AeSurface.card(borderRadius: BorderRadius.circular(context.dp(16))),
          child: Row(
            children: [
              Container(
                width: context.dp(42),
                height: context.dp(42),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE8A3), Color(0xFFF7D774)],
                  ),
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFFB8860B),
                  size: context.dp(22),
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: aeTitle()),
                    Text(
                      subtitle,
                      style: aeCaption(color: ScSaasThemeTokens.gray500),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ScSaasThemeTokens.gray500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Canonical `au-rise` entrance cadence (dugnad.css / splash.css): the first
/// block rises at 120ms, then roughly 70ms apart; trailing blocks use the
/// 550ms duration and ~50ms spacing of the `.auth-bottom` group. Blocks past
/// the first screenful render immediately rather than animating out of view.
Widget _riseIn(int index, Widget child) {
  if (index > 6) return child;
  return DugnadRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
