import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../campaign/campaign_repo.dart';
import '../campaign/models/campaign_order_pojo.dart';
import '../../ui/kit/ae_club_crest.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_points_widgets.dart';
import 'dugnad_repo.dart';
import 'dugnad_share.dart';
import 'dugnad_state.dart';
import 'dugnad_sto_utils.dart';
import 'gamification_models.dart';
import 'points_metal_theme.dart';
import 'supporter_card_screen.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import '../../ui/kit/ae_rise_in.dart';
import 'widgets/dugnad_metal_animations.dart';
import '../../ui/kit/ae_theme.dart';

/// Season recap — prototype: `SeasonRecapScreen` in player-card.jsx + gamify.css `.rc-*`.
class SeasonRecapScreen extends StatefulWidget {
  const SeasonRecapScreen({super.key});

  @override
  State<SeasonRecapScreen> createState() => _SeasonRecapScreenState();
}

class _SeasonRecapScreenState extends State<SeasonRecapScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final CampaignRepo _campaignRepo = CampaignRepo();

  PointsSummary? _summary;
  LeaderboardData? _leaderboard;
  ReferralSummary? _referral;
  List<DonationSubscriptionRecord> _donations = const [];
  List<CampaignMyOrder> _campaignOrders = const [];
  GamificationConfig? _gamificationConfig;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!DugnadState.instance.hasClub) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final clubId = DugnadState.instance.clubId;

    final results = await Future.wait([
      _repo.getPointsSummary(),
      _repo.getLeaderboard(clubId),
      _repo.getReferralSummary(organizationId: clubId),
      _repo.listDonationSubscriptions(),
      _campaignRepo.getMyOrders(),
      _repo.getGamificationConfig(organizationId: clubId),
    ]);

    List<CampaignMyOrder> orders = const [];
    final ordersRaw = results[4];
    if (ordersRaw is Map && ordersRaw['status'] == 1) {
      final parsed = CampaignMyOrdersListPojo.fromJson(
        Map<String, dynamic>.from(ordersRaw),
      );
      orders = parsed.orders;
    }

    if (!mounted) return;
    setState(() {
      _summary = results[0] as PointsSummary?;
      _leaderboard = results[1] as LeaderboardData?;
      _referral = results[2] as ReferralSummary?;
      _donations = results[3] as List<DonationSubscriptionRecord>;
      _campaignOrders = orders;
      _gamificationConfig = results[5] as GamificationConfig?;
      _loading = false;
    });
  }

  String _displayName() {
    final fromSummary = _summary?.publicDisplayName.trim();
    final raw = (fromSummary != null && fromSummary.isNotEmpty)
        ? fromSummary
        : prefGetString(prefUserName);
    final parts = raw.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : raw;
  }

  String _seasonLabel() {
    final endYear = _leaderboard?.season.year ?? DateTime.now().year;
    final startYear = endYear - 1;
    final suffix = (endYear % 100).toString().padLeft(2, '0');
    return '$startYear/$suffix';
  }

  /// Supporter-card entry metal — user's lifetime STØ tier (not season points).
  /// Prototype: `dg-pc-entry metal-{dgMetalForPts(points).id}` on the card the
  /// member actually holds; that maps to [PointsSummary.currentTier].
  String _metalForSupporterEntry() {
    final summary = _summary;
    final fromTier = summary?.currentTier?.metal.trim();
    if (fromTier != null && fromTier.isNotEmpty) return fromTier;

    final tiers = summary?.metalTiers ?? [];
    if (tiers.isEmpty) return 'solv';
    final idx = dugnadTierIndexForPoints(tiers, summary?.lifetimePoints ?? 0);
    return tiers[idx.clamp(0, tiers.length - 1)].metal;
  }

  LeaderboardTeamRow? _teamRow() {
    final board = _leaderboard;
    if (board == null || !DugnadState.instance.hasPointsTeam) return null;
    for (final row in board.teams) {
      if (row.teamId == DugnadState.instance.pointsTeamId) return row;
    }
    return null;
  }

  double _contributedKr() {
    final clubId = DugnadState.instance.clubId;
    var total = 0.0;

    for (final sub in _donations) {
      if (sub.organizationId != clubId) continue;
      if (!sub.isActive && !sub.isPaused) continue;
      total += sub.amountKr * sub.currentStreakMonths;
    }

    final seasonStart = _parseDate(_leaderboard?.season.startsAt);
    final seasonEnd = _parseDate(_leaderboard?.season.endsAt);

    for (final order in _campaignOrders) {
      if (order.paymentStatus != 1) continue;
      final created = _parseDate(order.createdAt);
      if (seasonStart != null &&
          created != null &&
          created.isBefore(seasonStart)) {
        continue;
      }
      if (seasonEnd != null && created != null && created.isAfter(seasonEnd)) {
        continue;
      }
      total += order.clubPayoutAmount;
    }

    return total;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _formatRecapKr(double amount) {
    final n = amount.round();
    final negative = n < 0;
    final digits = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final prefix = negative ? '-' : '';
    return '$prefix${buf.toString()} kr';
  }

  String _medalForRank(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🎽';
    }
  }

  void _share() async {
    HapticFeedback.lightImpact();
    final club = DugnadClubBranding.fullName();
    final share = await _repo.getShareSummary(
      organizationId: DugnadState.instance.clubId,
    );
    final link = share?.shareLink?.trim() ?? '';
    final text = link.isNotEmpty
        ? languages.dugnadSeasonRecapShareMessage(club, link)
        : languages.dugnadSeasonRecapShareMessageLegacy(club);
    if (!mounted) return;
    await shareDugnadText(
      context,
      text: text,
      subject: languages.dugnadSeasonRecapTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    dugnadApplyMetalColorOverrides(
      config: _gamificationConfig,
      summary: _summary,
    );
    final theme = context.aeTheme;
    final clubName = _leaderboard?.clubName ?? DugnadClubBranding.fullName();
    final clubLogo = _leaderboard?.clubLogo ?? DugnadState.instance.clubLogo;

    // Same shell as Lagkonkurranse (`AeScrollBody`) so `.rc-feed` /
    // `.lb-feed` top radius composites over club purple without scroll-clip
    // or lavender-on-lavender corner tips.
    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: theme.primary,
        body: AeScrollBody(
          hero: _SeasonRecapHeader(
            clubName: clubName,
            clubLogo: clubLogo,
            onBack: () => Navigator.of(context).pop(),
          ),
          bottomPadding: 40,
          itemGap: 14,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          children: _loading
              ? const [DugnadSeasonRecapSkeleton()]
              : _buildFeed(theme),
        ),
      ),
    );
  }

  List<Widget> _buildFeed(AeThemePalette theme) {
    final summary = _summary;
    final teamRow = _teamRow();
    final clubName = _leaderboard?.clubName ?? DugnadClubBranding.fullName();
    final referrals = summary?.actionCounts.referralConversions ??
        _referral?.convertedCount ??
        0;
    final campaigns = summary?.actionCounts.campaignPurchases ?? 0;
    final points = summary?.seasonPoints ?? 0;
    final metal = _metalForSupporterEntry();

    final children = <Widget>[
      _riseIn(0,
        _RecapHeroCard(
          seasonLabel: languages.dugnadSeasonRecapSeasonLabel(_seasonLabel()),
          title: languages.dugnadSeasonRecapHeroTitle(_displayName()),
          subtitle: languages.dugnadSeasonRecapHeroSub,
          gradient: theme.shinyGradient,
          shadowColor: theme.primary,
        ),
      ),
      _riseIn(1,
        _RecapStatsGrid(
          stats: [
            _RecapStatData(
              icon: Icons.favorite_rounded,
              value: _formatRecapKr(_contributedKr()),
              label: languages.dugnadSeasonRecapContributed,
              filledIcon: true,
            ),
            _RecapStatData(
              icon: Icons.share_rounded,
              value: '$referrals',
              label: languages.dugnadSeasonRecapReferrals,
            ),
            _RecapStatData(
              icon: Icons.inventory_2_outlined,
              value: '$campaigns',
              label: languages.dugnadSeasonRecapCampaigns,
            ),
            _RecapStatData(
              icon: Icons.star_rounded,
              value: '$points',
              label: languages.dugnadSeasonRecapPoints,
              filledIcon: true,
            ),
          ],
          tintColor: theme.primaryTint,
          iconColor: theme.primaryHover,
        ),
      ),
    ];

    if (teamRow != null && teamRow.rank > 0) {
      children.add(
        _riseIn(2,
          _RecapFinishCard(
            rank: teamRow.rank,
            title: languages.dugnadSeasonRecapTeamFinished(
              teamRow.name,
              teamRow.rank,
            ),
            subtitle: languages.dugnadSeasonRecapTeamOf(
              _leaderboard?.teams.length ?? 0,
              clubName,
            ),
            medal: _medalForRank(teamRow.rank),
          ),
        ),
      );
    }

    final entryIndex = teamRow != null && teamRow.rank > 0 ? 3 : 2;
    children.addAll([
      _riseIn(entryIndex,
        _RecapSupporterCardEntry(
          metal: metal,
          onTap: () {
            HapticFeedback.lightImpact();
            openScreen(context, const SupporterCardScreen());
          },
        ),
      ),
      _riseIn(entryIndex + 1,
        _RecapShareButton(
          onPressed: _share,
          color: theme.primary,
          shadow: theme.shadowButton,
        ),
      ),
    ]);

    return children;
  }
}

/// `.lb-hero` + `.lb-hero-top` — scrolls with `.rc-feed` (player-card.jsx).
class _SeasonRecapHeader extends StatelessWidget {
  const _SeasonRecapHeader({
    required this.clubName,
    required this.clubLogo,
    required this.onBack,
  });

  final String clubName;
  final String? clubLogo;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Match [AeHero] insets so status-bar + `.lb-hero` padding live
    // inside the fixed hero above the overlapped feed sheet.
    return Container(
      width: double.infinity,
      color: context.aeTheme.primary,
      padding: EdgeInsets.fromLTRB(
        context.dp(18),
        MediaQuery.paddingOf(context).top + context.dp(6),
        context.dp(18),
        context.dp(22),
      ),
      child: Row(
        children: [
          AeBackButton(onPressed: onBack),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AeClubCrest(
                  name: clubName,
                  logoUrl: clubLogo?.isEmpty ?? true ? null : clubLogo,
                  size: context.dp(34),
                ),
                SizedBox(width: context.dp(10)),
                Flexible(
                  child: Text(
                    clubName,
                    style: AeDugnadText.pageHeroOrg(color: Colors.white).dp(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.dp(38)),
        ],
      ),
    );
  }
}

/// `.rc-hero`
/// `.rc-hero` — shiny club gradient + inset rim + `.rc-bg` spotlight + soft
/// `lb-sheen` sweep (same family as `.lb-level`, matching the Figma card).
class _RecapHeroCard extends StatelessWidget {
  const _RecapHeroCard({
    required this.seasonLabel,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.shadowColor,
  });

  final String seasonLabel;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final radius = context.dp(20);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.55),
            blurRadius: context.dp(36),
            spreadRadius: -16,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Base: `--ae-shiny-purple` / club shinyGradient.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            // `.rc-bg` — soft white spotlight at top-right.
            // Use white@0 (not Colors.transparent) to avoid muddy black fringe.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -1.15),
                      radius: 0.95,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            // Inset rim — `box-shadow: 0 1px 1px rgba(255,255,255,.35) inset`.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: context.dp(2),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.dp(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seasonLabel.toUpperCase(),
                    style: aeCaption(color: Colors.white.withValues(alpha: 0.85))
                        .copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 11 * 0.08,
                    ),
                  ),
                  SizedBox(height: context.dp(6)),
                  Text(
                    title,
                    style: aeH2(color: Colors.white).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 24 * -0.025,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: context.dp(7)),
                  Text(
                    subtitle,
                    style: aeBody(color: Colors.white.withValues(alpha: 0.92))
                        .copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Shared diagonal metal glaze (same sweep as STØ / home metal cards).
            Positioned.fill(
              child: DugnadMetalGlazeOverlay(
                borderRadius: radius,
                overContent: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapStatData {
  const _RecapStatData({
    required this.icon,
    required this.value,
    required this.label,
    this.filledIcon = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool filledIcon;
}

/// `.rc-stats` + `.rc-stat` — compact cards, 10px gap.
class _RecapStatsGrid extends StatelessWidget {
  const _RecapStatsGrid({
    required this.stats,
    required this.tintColor,
    required this.iconColor,
  });

  final List<_RecapStatData> stats;
  final Color tintColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RecapStatTile(stats[0], tintColor, iconColor)),
            SizedBox(width: context.dp(10)),
            Expanded(child: _RecapStatTile(stats[1], tintColor, iconColor)),
          ],
        ),
        SizedBox(height: context.dp(10)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RecapStatTile(stats[2], tintColor, iconColor)),
            SizedBox(width: context.dp(10)),
            Expanded(child: _RecapStatTile(stats[3], tintColor, iconColor)),
          ],
        ),
      ],
    );
  }
}

class _RecapStatTile extends StatelessWidget {
  const _RecapStatTile(this.data, this.tintColor, this.iconColor);

  final _RecapStatData data;
  final Color tintColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.dp(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        boxShadow: [
          BoxShadow(
            color: ScSaasThemeTokens.ink.withValues(alpha: 0.05),
            blurRadius: context.dp(4),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(36),
            height: context.dp(36),
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius: BorderRadius.circular(context.dp(10)),
            ),
            child: Icon(data.icon, size: context.dp(18), color: iconColor),
          ),
          SizedBox(height: context.dp(10)),
          Text(
            data.value,
            style: aeH2().copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ScSaasThemeTokens.ink,
              letterSpacing: 22 * -0.03,
              height: context.dp(1),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: context.dp(4)),
          Text(
            data.label,
            style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.rc-finish`
class _RecapFinishCard extends StatelessWidget {
  const _RecapFinishCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.medal,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String medal;

  @override
  Widget build(BuildContext context) {
    final radius = context.dp(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.55),
            blurRadius: context.dp(30),
            spreadRadius: -16,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            ColoredBox(
              color: const Color(0xFFFFE9A8),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE9A8), Color(0xFFF3C95F)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.dp(16)),
                  child: Row(
                    children: [
                      Text(
                        '#$rank',
                        style: aeH2(color: const Color(0xFF2A1D08)).copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 34 * -0.03,
                        ),
                      ),
                      SizedBox(width: context.dp(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: aeBody(color: const Color(0xFF2A1D08))
                                  .copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 15 * -0.01,
                              ),
                            ),
                            SizedBox(height: context.dp(2)),
                            Text(
                              subtitle,
                              style: aeCaption(color: const Color(0xFF2A1D08))
                                  .copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.2,
                                color: const Color(0xFF2A1D08)
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(medal, style: const TextStyle(fontSize: 30)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DugnadMetalGlazeOverlay(
                borderRadius: radius,
                overContent: true,
                phase: 0.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.dg-pc-entry` — metal strip + shared diagonal metal glaze.
class _RecapSupporterCardEntry extends StatelessWidget {
  const _RecapSupporterCardEntry({
    required this.metal,
    required this.onTap,
  });

  final String metal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    final iconColor = PointsMetalTheme.levelHeroBadgeIconColor(metal);
    final shadowMetal = PointsMetalTheme.pcEntryShadowColor(metal);
    final radius = context.dp(16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: shadowMetal.withValues(alpha: 0.6),
              blurRadius: context.dp(26),
              spreadRadius: -16,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              ColoredBox(
                color: PointsMetalTheme.pcEntryMetalGradient(metal).first,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: PointsMetalTheme.pcEntryMetalGradient(metal),
                      stops: PointsMetalTheme.pcEntryMetalGradientStops,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(14),
                      context.dp(13),
                      context.dp(14),
                      context.dp(13),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.dp(40),
                          height: context.dp(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius:
                                BorderRadius.circular(context.dp(11)),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: context.dp(20),
                            color: iconColor,
                          ),
                        ),
                        SizedBox(width: context.dp(13)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languages.dugnadSeasonRecapViewCard,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 14 * -0.01,
                                  color: fg,
                                ),
                              ),
                              SizedBox(height: context.dp(2)),
                              Text(
                                languages.dugnadSeasonRecapCardSub,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: fg.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: context.dp(18),
                          color: fg.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DugnadMetalGlazeOverlay(
                  borderRadius: radius,
                  overContent: true,
                  phase: 0.32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.ae-btn.ae-btn--primary`
class _RecapShareButton extends StatelessWidget {
  const _RecapShareButton({
    required this.onPressed,
    required this.color,
    required this.shadow,
  });

  final VoidCallback onPressed;
  final Color color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.dp(14)),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.dp(16)),
            boxShadow: shadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_outlined, size: context.dp(17), color: Colors.white),
              SizedBox(width: context.dp(8)),
              Text(
                languages.dugnadSeasonRecapShare,
                style: aeLabel(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
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
  return AeRiseIn(
    delay: Duration(
      milliseconds: index < 4 ? 120 + index * 70 : 400 + (index - 4) * 50,
    ),
    duration: Duration(milliseconds: index < 4 ? 600 : 550),
    child: child,
  );
}
