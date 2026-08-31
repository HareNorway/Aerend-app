import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_formen_screen.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'gamification_models.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';

/// Canonical `au-rise` entrance stagger for a flat list of top-level feed
/// blocks: first block at 120ms then ~70ms apart, trailing group at 550ms
/// duration and ~50ms apart. Only the blocks that fit the first screenful
/// animate — anything further down is already off-screen.
List<Widget> _staggerFeed(List<Widget> blocks, {int maxAnimated = 6}) {
  return [
    for (var i = 0; i < blocks.length; i++)
      if (i >= maxAnimated)
        blocks[i]
      else
        DugnadRiseIn(
          delay: Duration(
            milliseconds: i < 4 ? 120 + i * 70 : 400 + (i - 4) * 50,
          ),
          duration: Duration(milliseconds: i < 4 ? 600 : 550),
          child: blocks[i],
        ),
  ];
}

/// Ukens kamper + Sesongmål (Chunk E — gamify-form.jsx).
class DugnadMissionsScreen extends StatefulWidget {
  const DugnadMissionsScreen({super.key});

  @override
  State<DugnadMissionsScreen> createState() => _DugnadMissionsScreenState();
}

class _DugnadMissionsScreenState extends State<DugnadMissionsScreen>
    with TickerProviderStateMixin {
  final DugnadRepo _repo = DugnadRepo();
  GamificationConfig? _config;
  GamificationProgress? _progress;
  bool _loading = true;
  // `.mi-prog` mirrors AeMetalProgressBar / `lb-prog-*`: stripes + sweep on
  // separate timelines. Constructed eagerly; started behind the reduced-motion
  // gate in didChangeDependencies.
  late final AnimationController _stripeController;
  late final AnimationController _sweepController;
  Timer? _sweepDelay;
  bool _motionStarted = false;

  @override
  void initState() {
    super.initState();
    // `.mi-prog span::before` → `lb-prog-stripes .62s linear infinite`
    // `.mi-prog span::after`  → `lb-prog-sweep 2.8s ease-in-out 1.3s infinite`
    _stripeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweepDelay?.cancel();
      _sweepDelay = null;
      if (_stripeController.isAnimating) _stripeController.stop();
      if (_sweepController.isAnimating) _sweepController.stop();
      _stripeController.value = 0;
      _sweepController.value = 0;
      _motionStarted = false;
      return;
    }
    if (_motionStarted) return;
    _motionStarted = true;
    _stripeController.repeat();
    _sweepDelay?.cancel();
    _sweepDelay = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _sweepController.repeat();
    });
  }

  @override
  void dispose() {
    _sweepDelay?.cancel();
    _stripeController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final clubId = DugnadState.instance.clubId;
      final teamId = DugnadState.instance.pointsTeamId;
      final config = await _repo.getGamificationConfig(
        organizationId: clubId > 0 ? clubId : null,
        teamId: teamId > 0 ? teamId : null,
      );
      final progress = await _repo.getGamificationProgress(
        organizationId: clubId > 0 ? clubId : null,
        teamId: teamId > 0 ? teamId : null,
      );
      if (!mounted) return;
      setState(() {
        _config = config;
        _progress = progress;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
        body: DugnadLbScrollBody(
          hero: DugnadLbHero(
            clubName: clubName,
            clubLogo: clubLogo,
            title: 'Ukens kamper & Sesongmal',
            onBack: () => Navigator.of(context).pop(),
          ),
          bottomPadding: 100,
          itemGap: 10,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          children: _loading
              ? const [DugnadMissionsFeedSkeleton()]
              : _buildFeed(),
        ),
      ),
    );
  }

  List<Widget> _buildFeed() {
    final progress = _progress;
    final config = _config;

    if (progress == null && config == null) {
      return _staggerFeed([
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languages.dugnadMissionsLoadError,
                style: aeBody(color: ScSaasThemeTokens.gray700).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.dp(8)),
              Text(
                languages.dugnadMissionsLoadErrorSub,
                style: aeBody(color: ScSaasThemeTokens.gray500),
              ),
              SizedBox(height: context.dp(14)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _load,
                  child: Text(languages.retry),
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    if (progress?.teamRequired == true) {
      return _staggerFeed([
        _card(
          child: Text(
            languages.dugnadMissionsNoTeam,
            style: aeBody(color: ScSaasThemeTokens.gray700),
          ),
        ),
      ]);
    }

    final widgets = <Widget>[];

    if (progress != null && (config?.isEnabled('streaks_enabled') ?? true)) {
      widgets.add(_streakCard(progress));
    }

    if (config?.isEnabled('weekly_challenges_enabled') ?? true) {
      widgets.add(_weeklyHeader(progress));
      final challenges = progress?.weeklyChallenges ?? const [];
      if (challenges.isEmpty) {
        widgets.add(
          _card(
            child: Text(
              languages.dugnadMissionsNoWeekly,
              style: aeBody(color: ScSaasThemeTokens.gray500),
            ),
          ),
        );
      } else {
        for (final c in challenges) {
          widgets.add(_challengeCard(c));
        }
      }
    }

    if (progress != null) {
      widgets.add(_formEntryCard(progress));
    }

    if (config?.isEnabled('season_goals_enabled') ?? true) {
      widgets.add(_sectionTitle(languages.dugnadSeasonGoals));
      final goals = progress?.seasonGoals ?? const [];
      if (goals.isEmpty) {
        widgets.add(
          _card(
            child: Text(
              languages.dugnadMissionsNoSeasonGoals,
              style: aeBody(color: ScSaasThemeTokens.gray500),
            ),
          ),
        );
      } else {
        for (final g in goals) {
          widgets.add(_goalCard(g));
        }
      }
    }

    widgets.add(_infoNote());

    return _staggerFeed(widgets);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(2), context.dp(2), context.dp(10)),
      child: Text(
        text.toUpperCase(),
        style: AeDugnadText.sectionLabel().dp(context),
      ),
    );
  }

  Widget _weeklyHeader(GamificationProgress? progress) {
    final days = progress?.week?.daysRemaining ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(2), context.dp(2), context.dp(10)),
      child: Row(
        children: [
          Text(
            languages.dugnadWeeklyChallengesTitle.toUpperCase(),
            style: AeDugnadText.sectionLabel().dp(context),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: context.dp(12),
                color: ScSaasThemeTokens.gray500,
              ),
              SizedBox(width: context.dp(5)),
              Text(
                languages.dugnadMissionsResetMonday(days),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: ScSaasThemeTokens.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.dp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.dp(12),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _formEntryCard(GamificationProgress progress) {
    final color = progress.formWarning
        ? const Color(0xFFC98A1A)
        : const Color(0xFF22A769);
    final label = progress.formWarning
        ? languages.dugnadFormStatusDown
        : languages.dugnadFormStatusUp;
    final bgColor = progress.formWarning
        ? const Color(0x29E0A93A)
        : const Color(0x2422A769);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(context.dp(16)),
        onTap: () {
          HapticFeedback.lightImpact();
          openScreen(context, const DugnadFormenScreen());
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(12), context.dp(13)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(16)),
            border: Border.all(color: const Color(0xFFE6E6EE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: context.dp(10),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dp(42),
                height: context.dp(42),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(context.dp(12)),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: context.dp(22),
                  color: color,
                ),
              ),
              SizedBox(width: context.dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadFormEntryTitle(label),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: context.dp(1)),
                    Text(
                      languages.dugnadMissionsFormEntrySub,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCC8D6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakCard(GamificationProgress progress) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.dp(16), vertical: context.dp(15)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.dp(20)),
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.8),
          end: Alignment(0.5, 0.8),
          colors: [Color(0xFFFF8A3D), Color(0xFFE0532A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE05332).withValues(alpha: 0.7),
            blurRadius: context.dp(30),
            offset: const Offset(0, 16),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.dp(52),
            height: context.dp(52),
            child: Center(
              child: Text('🔥', style: TextStyle(fontSize: 30, height: context.dp(1))),
            ),
          ),
          SizedBox(width: context.dp(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languages.dugnadStreakTitle(progress.streakWeeks),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.01 * 15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.dp(2)),
                Text(
                  languages.dugnadStreakSubtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _challengeCard(GamificationChallengeProgress c) {
    final clubPrimary = context.dugnadTheme.primary;
    final clubPrimaryTint =
        Color.lerp(clubPrimary, Colors.white, 0.86) ?? const Color(0xFFE8EEF8);
    final clubPrimaryText =
        Color.lerp(clubPrimary, Colors.black, 0.22) ?? clubPrimary;
    final pct = c.progressFraction;
    final isCompleted =
        c.completed || (c.progressCount >= c.goalCount && c.goalCount > 0);
    final isStarted = c.progressCount > 0;
    // `.dg-mission.claimed { background: rgba(34,167,105,.06) }` — must be
    // opaque. A translucent fill lets the previous card's box-shadow bleed
    // through the top edge (see mockup vs in-app).
    final cardBg = isCompleted
        ? (Color.lerp(Colors.white, const Color(0xFF22A769), 0.06) ??
            const Color(0xFFF0F9F4))
        : Colors.white;
    final cardBorder = isCompleted
        ? const Color(0x4D22A769)
        : const Color(0xFFE6E6EE);
    final statusColor = isCompleted
        ? const Color(0xFF12724A)
        : isStarted
            ? const Color(0xFF12724A)
            : const Color(0xFF9890A8);
    final statusText = isCompleted
        ? languages.dugnadMissionsTempoDone
        : (isStarted
            ? languages.dugnadMissionsTempoOnTrack
            : languages.dugnadMissionsTempoNotStarted);
    final statusIcon = isCompleted
        ? Icons.check_rounded
        : isStarted
            ? Icons.north_east_rounded
            : Icons.access_time_rounded;
    final barColor = isCompleted
        ? const Color(0xFF2BB673)
        : context.dugnadTheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: cardBorder, width: 1.5),
        // `.dg-mission { box-shadow: var(--ae-shadow-card) }` -- three layers,
        // the first a hairline ring, and brand-tinted rather than black. A
        // single soft black layer reads floaty where the ring reads crisp.
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(40),
            height: context.dp(40),
            decoration: BoxDecoration(
              color: clubPrimaryTint,
              borderRadius: BorderRadius.circular(context.dp(12)),
            ),
            child: Icon(
              _challengeIcon(c),
              size: context.dp(18),
              color: clubPrimaryText,
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.titleNo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.01 * 14,
                        ),
                      ),
                    ),
                    if (c.rewardPoints > 0) ...[
                      SizedBox(width: context.dp(10)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: clubPrimaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: context.dp(11), color: clubPrimaryText),
                            SizedBox(width: context.dp(3)),
                            Text(
                              '+${c.rewardPoints}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: clubPrimaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.dp(2)),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.descriptionNo.isNotEmpty
                            ? c.descriptionNo
                            : languages.dugnadWeeklyChallengeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ScSaasThemeTokens.gray500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: context.dp(8)),
                    Icon(statusIcon, size: context.dp(11), color: statusColor),
                    SizedBox(width: context.dp(3)),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.dp(9)),
                _animatedStripedProgressBar(
                  fraction: pct,
                  fillColor: barColor,
                  trackColor: const Color(0xFFE8E8EE),
                ),
                SizedBox(height: context.dp(9)),
                Text(
                  '${c.progressCount} / ${c.goalCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(GamificationGoalProgress g) {
    final clubPrimary = context.dugnadTheme.primary;
    final clubPrimaryTint =
        Color.lerp(clubPrimary, Colors.white, 0.86) ?? const Color(0xFFE8EEF8);
    final clubPrimaryText =
        Color.lerp(clubPrimary, Colors.black, 0.22) ?? clubPrimary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.8),
          end: Alignment(0.5, 0.8),
          colors: [Color(0xFFFBFAFF), Color(0xFFF3F0FB)],
        ),
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(
          color: Color.lerp(clubPrimary, Colors.white, 0.82) ??
              const Color(0xFFE0D8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.dp(10),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.dp(40),
            height: context.dp(40),
            decoration: BoxDecoration(
              color: clubPrimary,
              borderRadius: BorderRadius.circular(context.dp(12)),
            ),
            child: Icon(
              _goalIcon(g),
              color: Colors.white,
              size: context.dp(18),
            ),
          ),
          SizedBox(width: context.dp(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        g.titleNo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.01 * 14,
                        ),
                      ),
                    ),
                    if (g.rewardPoints > 0) ...[
                      SizedBox(width: context.dp(10)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: clubPrimaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: context.dp(11), color: clubPrimaryText),
                            SizedBox(width: context.dp(3)),
                            Text(
                              '+${g.rewardPoints}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: clubPrimaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (g.descriptionNo.isNotEmpty) ...[
                  SizedBox(height: context.dp(2)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          g.descriptionNo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ScSaasThemeTokens.gray500,
                          ),
                        ),
                      ),
                      // TODO(backend): fragile heuristic — breaks when an admin
                      // renames the goal. Needs a real `badge` field on the
                      // season-goal model (Hare-AdminPanel) instead of matching
                      // on titleNo. Label 'Sesongkriger' is also NO-only.
                      if (g.titleNo.toLowerCase().contains('aktiv uke')) ...[
                        SizedBox(width: context.dp(8)),
                        Icon(Icons.shield_outlined, size: context.dp(11), color: clubPrimaryText),
                        SizedBox(width: context.dp(3)),
                        Text(
                          'Sesongkriger',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: clubPrimaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                SizedBox(height: context.dp(9)),
                _animatedStripedProgressBar(
                  fraction: g.progressFraction,
                  fillColor: context.dugnadTheme.primary,
                  trackColor: ScSaasThemeTokens.gray100,
                ),
                SizedBox(height: context.dp(9)),
                Text(
                  '${g.progressCount} / ${g.goalCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ScSaasThemeTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _challengeIcon(GamificationChallengeProgress c) {
    final key = c.challengeKey.toLowerCase();
    if (key.contains('login')) return Icons.check_rounded;
    if (key.contains('share')) return Icons.share_outlined;
    if (key.contains('refer')) return Icons.person_add_alt_1_rounded;
    if (key.contains('buy')) return Icons.shopping_bag_outlined;
    return Icons.bolt_rounded;
  }

  IconData _goalIcon(GamificationGoalProgress g) {
    final key = g.goalKey.toLowerCase();
    final title = g.titleNo.toLowerCase();
    if (key.contains('campaign') ||
        key.contains('kjop') ||
        key.contains('buy') ||
        key.contains('matkasse') ||
        title.contains('kampanje') ||
        title.contains('kjøp') ||
        title.contains('matkasse')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.emoji_events_outlined;
  }

  Widget _infoNote() {
    final purple100 =
        Color.lerp(context.dugnadTheme.primary, Colors.white, 0.86) ??
            const Color(0xFFEDE8F8);
    final purple600 = context.dugnadTheme.primary;
    final purple700 =
        Color.lerp(context.dugnadTheme.primary, Colors.black, 0.15) ??
            context.dugnadTheme.primaryHover;
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(14), context.dp(13), context.dp(14), context.dp(13)),
      decoration: BoxDecoration(
        color: purple100,
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(Icons.info_outline_rounded, size: context.dp(17), color: purple600),
          ),
          SizedBox(width: context.dp(11)),
          Expanded(
            child: Text(
              languages.dugnadMissionsInfoBanner,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: purple700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `.mi-prog` — same stripe + sweep glaze as [AeMetalProgressBar] / hero
  /// bars on profil & hjem (`lb-prog-stripes` + `lb-prog-sweep`).
  Widget _animatedStripedProgressBar({
    required double fraction,
    required Color fillColor,
    required Color trackColor,
  }) {
    final clamped = fraction.clamp(0.0, 1.0).toDouble();
    final reduce = MediaQuery.disableAnimationsOf(context);
    final h = context.dp(7);
    final tile = context.dp(14);

    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: ColoredBox(
          color: trackColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(h / 2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: fillColor),
                    if (!reduce && clamped > 0) ...[
                      AnimatedBuilder(
                        animation: _stripeController,
                        builder: (context, _) {
                          return ClipRect(
                            child: Transform.translate(
                              offset: Offset(
                                _stripeController.value * tile,
                                0,
                              ),
                              child: CustomPaint(
                                painter: _MissionStripePainter(
                                  tile: tile,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, _) {
                          final v = _sweepController.value;
                          final progress = v <= 0.55
                              ? Curves.easeInOut.transform(v / 0.55)
                              : 1.0;
                          final dx = -1.2 + progress * 2.4;
                          return FractionalTranslation(
                            translation: Offset(dx, 0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.6),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 45° stripe tile — CSS `.mi-prog span::before` (`background-size: 14px`).
class _MissionStripePainter extends CustomPainter {
  const _MissionStripePainter({required this.tile, required this.color});

  final double tile;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (double x = -size.height - tile; x < size.width + tile; x += tile) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + tile / 2, 0)
        ..lineTo(x + tile / 2, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MissionStripePainter old) =>
      old.tile != tile || old.color != color;
}
