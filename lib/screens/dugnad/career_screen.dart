import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'club_crest.dart';
import 'dugnad_badge_sheet.dart';
import 'dugnad_share.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_models.dart';
import 'dugnad_points_widgets.dart';
import 'dugnad_repo.dart';
import 'dugnad_state.dart';
import 'dugnad_sto_utils.dart';
import 'gamification_models.dart';
import 'points_metal_theme.dart';
import 'transfer_window_screen.dart';
import 'widgets/dugnad_subpage_shell.dart';
import 'dugnad_club_theme.dart';
import 'widgets/dugnad_rise_in.dart';

/// Career screen — prototype: `CareerScreen` in gamify-cards.jsx + gamify-plus.css.
class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  final DugnadRepo _repo = DugnadRepo();

  GamificationCareer? _career;
  GamificationConfig? _config;
  PointsSummary? _summary;
  LeaderboardData? _leaderboard;
  DugnadBadgeSections? _badgeSections;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final clubId = DugnadState.instance.clubId;
      final teamId = DugnadState.instance.hasPointsTeam
          ? DugnadState.instance.pointsTeamId
          : null;

      final results = await Future.wait([
        _repo.getGamificationCareer(
          organizationId: clubId > 0 ? clubId : null,
          teamId: teamId,
        ),
        clubId > 0
            ? _repo.getGamificationConfig(organizationId: clubId)
            : Future.value(null),
        _repo.getPointsSummary(),
        clubId > 0 ? _repo.getLeaderboard(clubId) : Future.value(null),
        _repo.getReferralSummary(organizationId: clubId > 0 ? clubId : null),
        _repo.getPointsLedger(page: 1),
      ]);

      final career = results[0] as GamificationCareer?;
      final config = results[1] as GamificationConfig?;
      final summary = results[2] as PointsSummary?;
      final board = results[3] as LeaderboardData?;
      final referral = results[4] as ReferralSummary?;
      final ledger = results[5] as PointsLedgerPage?;

      dugnadApplyMetalColorOverrides(config: config, summary: summary);

      LeaderboardTeamRow? teamRow;
      if (board != null && DugnadState.instance.hasPointsTeam) {
        for (final row in board.teams) {
          if (row.teamId == DugnadState.instance.pointsTeamId) {
            teamRow = row;
            break;
          }
        }
      }

      final hasSub = ledger?.entries.any(
            (e) => e.action == 'subscription_donation' && e.points > 0,
          ) ??
          false;

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

      if (!mounted) return;
      setState(() {
        _career = career;
        _config = config;
        _summary = summary;
        _leaderboard = board;
        _badgeSections = sections;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _share(BuildContext shareContext) async {
    HapticFeedback.lightImpact();
    final points = _formatPoints(_career?.lifetimePoints ?? 0);
    final share = await _repo.getShareSummary(
      organizationId: DugnadState.instance.clubId,
    );
    final link = share?.shareLink?.trim() ?? '';
    final text = link.isNotEmpty
        ? languages.dugnadCareerShareMessage(points, link)
        : languages.dugnadCareerShareMessageLegacy(points);
    if (!shareContext.mounted) return;
    await shareDugnadText(
      shareContext,
      text: text,
      subject: languages.dugnadCareerTitle,
    );
  }

  bool get _showTransferEntry {
    final config = _config;
    if (config == null) return false;
    if (!config.isEnabled('transfer_window_enabled')) return false;
    final tw = config.modules?.transferWindow;
    return tw != null && tw.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final clubName = _leaderboard?.clubName ?? DugnadClubBranding.fullName();
    final clubLogo = _leaderboard?.clubLogo ?? DugnadState.instance.clubLogo;

    // Same shell as Lagkonkurranse / sesong-recap — Stack overlap so the
    // lavender sheet radius composites over club purple cleanly.
    return DugnadFixedTypography(
      child: Scaffold(
        backgroundColor: theme.primary,
        body: DugnadLbScrollBody(
          hero: DugnadLbHero(
            clubName: clubName,
            clubLogo: clubLogo,
            title: languages.dugnadCareerTitle,
            subtitle: languages.dugnadCareerHeroSub,
            subtitleWithClock: true,
            trailing: _CareerShareButton(onPressed: _share),
            onBack: () => Navigator.of(context).pop(),
          ),
          bottomPadding: 40,
          itemGap: 0,
          topPadding: 18,
          feedRadius: 22,
          overlap: 12,
          children: [
            if (_loading)
              const DugnadCareerFeedSkeleton()
            else
              _buildFeed(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(DugnadClubThemePalette theme) {
    final career = _career;
    final badges = _badgeSections?.permanent ?? const <DugnadBadgeItem>[];
    final earnedBadgeCount = badges.where((b) => b.earned).length;

    // Entrance stagger — canonical `au-rise` cadence: first block at 120ms,
    // ~70ms apart, trailing group at 550ms / ~50ms apart. A section label and
    // its body share one delay so they rise together as a single block.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadRiseIn(
          delay: const Duration(milliseconds: 120),
          child: _CareerLifetimeCard(
            points: career?.lifetimePoints ?? _summary?.lifetimePoints ?? 0,
            sinceLabel: _lifetimeSinceLabel(career?.lifetimeSince),
            theme: theme,
          ),
        ),
        SizedBox(height: context.dp(18)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 190),
          child: _CareerSectionLabel(
            languages.dugnadCareerSeasonArchiveLabel,
          ),
        ),
        SizedBox(height: context.dp(10)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 190),
          child: (career?.seasonArchives ?? []).isEmpty
              ? _CareerSeasonArchiveEmpty(theme: theme)
              : _CareerSeasonArchiveGrid(
                  archives: career!.seasonArchives,
                  theme: theme,
                ),
        ),
        SizedBox(height: context.dp(18)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 260),
          child: _CareerMeritHead(
            earned: earnedBadgeCount,
            total: badges.length,
          ),
        ),
        SizedBox(height: context.dp(10)),
        if (badges.isNotEmpty)
          DugnadRiseIn(
            delay: const Duration(milliseconds: 260),
            child: DugnadBadgeGrid(
              badges: badges,
              onBadgeTap: (b) => showDugnadBadgeSheet(context, badge: b),
            ),
          ),
        SizedBox(height: context.dp(18)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 330),
          child: _CareerSectionLabel(
            languages.dugnadCareerAffiliationTimeline,
          ),
        ),
        SizedBox(height: context.dp(12)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 330),
          child: (career?.affiliations ?? []).isEmpty
              ? Text(
                  languages.dugnadCareerSub,
                  style: aeCaption(color: ScSaasThemeTokens.gray500),
                )
              : _CareerAffiliationTimeline(
                  entries: career!.affiliations,
                  fallbackClubLogo:
                      _leaderboard?.clubLogo ?? DugnadState.instance.clubLogo,
                  theme: theme,
                ),
        ),
        if (_showTransferEntry) ...[
          SizedBox(height: context.dp(16)),
          DugnadRiseIn(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 550),
            child: _CareerTransferEntry(
              onTap: () => openScreen(context, const TransferWindowScreen()),
              theme: theme,
            ),
          ),
        ],
        SizedBox(height: context.dp(14)),
        DugnadRiseIn(
          delay: const Duration(milliseconds: 450),
          duration: const Duration(milliseconds: 550),
          child: _CareerInfoFooter(
            text: languages.dugnadCareerInfoFooter,
            theme: theme,
          ),
        ),
      ],
    );
  }

  String _lifetimeSinceLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return languages.dugnadCareerLifetimeSub('—');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return languages.dugnadCareerLifetimeSub(raw);
    final formatted = DateFormat('MMMM yyyy', languages.localeName)
        .format(parsed.toLocal());
    return languages.dugnadCareerLifetimeSub(formatted);
  }

  String _formatPoints(int n) {
    final negative = n < 0;
    final digits = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return negative ? '-${buf.toString()}' : buf.toString();
  }
}

class _CareerShareButton extends StatefulWidget {
  const _CareerShareButton({required this.onPressed});

  final void Function(BuildContext context) onPressed;

  @override
  State<_CareerShareButton> createState() => _CareerShareButtonState();
}

class _CareerShareButtonState extends State<_CareerShareButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => widget.onPressed(context),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: context.dp(38),
          height: context.dp(38),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.share_rounded, size: context.dp(18), color: Colors.white),
        ),
      ),
    );
  }
}

/// Lifetime-poeng hero — `.dg-lifetime` (gamify-plus.css).
///
/// Base `var(--ae-shiny-*)` → `.lt-bg` radial → one-shot `.lt-shine` (`lt-sweep`).
/// Fade the radial to white@0, never [Colors.transparent], or purple muddies
/// under the highlight.
class _CareerLifetimeCard extends StatefulWidget {
  const _CareerLifetimeCard({
    required this.points,
    required this.sinceLabel,
    required this.theme,
  });

  final int points;
  final String sinceLabel;
  final DugnadClubThemePalette theme;

  @override
  State<_CareerLifetimeCard> createState() => _CareerLifetimeCardState();
}

class _CareerLifetimeCardState extends State<_CareerLifetimeCard>
    with SingleTickerProviderStateMixin {
  static const _ltSweepCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  late final AnimationController _shine;
  Timer? _shineStart;

  @override
  void initState() {
    super.initState();
    // `lt-sweep`: 1.5s cubic-bezier(.4,0,.2,1), delay 0.5s, fill both (once).
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shineStart?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.value = 1;
      return;
    }
    if (_shine.status == AnimationStatus.dismissed) {
      _shineStart = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _shine.forward();
      });
    }
  }

  @override
  void dispose() {
    _shineStart?.cancel();
    _shine.dispose();
    super.dispose();
  }

  String _formatPoints(int n) {
    final digits = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final radius = BorderRadius.circular(context.dp(20));

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // `0 16px 34px -14px rgba(91,62,166,.6)` — club-tinted.
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.6),
            blurRadius: context.dp(34),
            spreadRadius: -14,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Base: `background: var(--ae-shiny-purple)`.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: theme.shinyGradient),
              ),
            ),
            // `.lt-bg` — radial 150×110 at 88% / -10%, white .28 → white@0.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.76, -1.2),
                      radius: 0.85,
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
            // Inset highlight — `0 1px 1px rgba(255,255,255,.3) inset`.
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
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // `.lt-shine` — one-shot diagonal sweep (`lt-sweep`).
            // Band is taller than the card so skewX(-16deg) still covers
            // edge-to-edge (a same-height strip leaves empty triangles).
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        if (w <= 0 || h <= 0) {
                          return const SizedBox.shrink();
                        }
                        final bandW = w * 0.45;
                        // Extra height covers the parallelogram after skew.
                        final bandH = h + bandW;
                        // Keyframes: -180% → 320% by 55%, hold to 100%.
                        final sweepT =
                            (_shine.value / 0.55).clamp(0.0, 1.0);
                        final eased = _ltSweepCurve.transform(sweepT);
                        final x = (-1.8 + eased * 5.0) * bandW;
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: x,
                              top: (h - bandH) / 2,
                              width: bandW,
                              height: bandH,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.skewX(-16 * math.pi / 180),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    // `linear-gradient(100deg, …)`.
                                    gradient: LinearGradient(
                                      begin: const Alignment(-0.2, -1),
                                      end: const Alignment(0.2, 1),
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                      stops: const [0.18, 0.5, 0.82],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // Content — `.lt-top` / `.lt-num` / `.lt-sub`.
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(18),
                context.dp(17),
                context.dp(18),
                context.dp(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: context.dp(28),
                        height: context.dp(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(context.dp(9)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.star_rounded,
                          size: context.dp(17),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: context.dp(8)),
                      Expanded(
                        child: Text(
                          languages.dugnadCareerLifetimeEyebrow.toUpperCase(),
                          style: aeCaption(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            letterSpacing: 0.06 * 11.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dp(9),
                          vertical: context.dp(3),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          languages.dugnadCareerLifetimePermanent
                              .toUpperCase(),
                          style: aeCaption(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.04 * 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dp(12)),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.points),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => Text(
                      _formatPoints(value),
                      style: aeLabel(color: Colors.white).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 40,
                        letterSpacing: -1.2,
                        height: context.dp(1),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  SizedBox(height: context.dp(8)),
                  Text(
                    widget.sinceLabel,
                    style: aeCaption(
                      color: Colors.white.withValues(alpha: 0.9),
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.4,
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

class _CareerSectionLabel extends StatelessWidget {
  const _CareerSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dp(2), context.dp(0), context.dp(2), context.dp(0)),
      child: Text(
        text.toUpperCase(),
        style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.08 * 11,
        ),
      ),
    );
  }
}

class _CareerSeasonArchiveGrid extends StatelessWidget {
  const _CareerSeasonArchiveGrid({
    required this.archives,
    required this.theme,
  });

  final List<GamificationSeasonArchive> archives;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: archives.map((archive) {
            return SizedBox(
              width: width,
              child: _CareerSeasonCard(archive: archive, theme: theme),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CareerSeasonCard extends StatelessWidget {
  const _CareerSeasonCard({
    required this.archive,
    required this.theme,
  });

  final GamificationSeasonArchive archive;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    final metal = archive.metalKey;
    final style = PointsMetalTheme.seasonCardForMetal(metal);
    final stamp = _seasonStampLabel(archive.seasonLabel);
    final teamLine = archive.teamsNote != null && archive.teamsNote!.isNotEmpty
        ? '${archive.teamName} · ${archive.teamsNote}'
        : archive.teamName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(context.dp(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 128),
          child: Ink(
            padding: EdgeInsets.all(context.dp(13)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(16)),
              // 135deg with the 48% midpoint -- Family A's own stops, which
              // an omitted `stops:` spreads evenly and flattens.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.gradient,
                stops: const [0.0, 0.48, 1.0],
              ),
              boxShadow: [
                // `0 6px 16px -10px rgba(45,27,91,.4)` -- blur, offset and
                // spread were right; the alpha was less than half.
                BoxShadow(
                  color: theme.text.withValues(alpha: 0.4),
                  blurRadius: context.dp(16),
                  offset: const Offset(0, 6),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.dp(7), vertical: context.dp(3)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(context.dp(6)),
                    ),
                    child: Text(
                      languages.dugnadCareerSeasonStamp(stamp).toUpperCase(),
                      style: aeCaption(color: style.textColor).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        letterSpacing: 0.03 * 9.5,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${archive.finalRating}',
                      style: aeLabel(color: style.textColor).copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        letterSpacing: -1,
                        height: context.dp(1),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      languages.dugnadCareerStoTier(archive.tierLabel),
                      style: aeCaption(color: style.textColor).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: context.dp(30),
                          height: context.dp(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(context.dp(9)),
                          ),
                          alignment: Alignment.center,
                          child: ClubCrest(
                            name: archive.clubName,
                            size: context.dp(22),
                          ),
                        ),
                        SizedBox(width: context.dp(9)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                archive.clubName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: aeCaption(color: style.textColor).copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                teamLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: aeCaption(
                                  color: style.textColor.withValues(alpha: 0.85),
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _seasonStampLabel(String label) {
    final match = RegExp(r'(\d{2}/\d{2}|\d{4}/\d{2})').firstMatch(label);
    if (match != null) return match.group(1)!;
    if (label.trim().isNotEmpty) return label.trim();
    return '—';
  }
}

class _CareerSeasonArchiveEmpty extends StatelessWidget {
  const _CareerSeasonArchiveEmpty({required this.theme});

  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.dp(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(16)),
        border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: Column(
        children: [
          Container(
            width: context.dp(48),
            height: context.dp(48),
            decoration: BoxDecoration(
              color: theme.primaryTint.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(context.dp(14)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.shield_outlined, color: theme.primary, size: context.dp(22)),
          ),
          SizedBox(height: context.dp(10)),
          Text(
            languages.dugnadCareerSeasonArchiveEmptyTitle,
            textAlign: TextAlign.center,
            style: aeLabel(color: theme.text).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: context.dp(6)),
          Text(
            languages.dugnadCareerSeasonArchiveEmptyBody,
            textAlign: TextAlign.center,
            style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerMeritHead extends StatelessWidget {
  const _CareerMeritHead({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languages.dugnadCareerPermanentMarksTitle,
                style: aeLabel(color: theme.text).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              SizedBox(height: context.dp(2)),
              Text(
                languages.dugnadCareerPermanentMarksSub,
                style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.dp(10), vertical: context.dp(4)),
          decoration: BoxDecoration(
            color: theme.primaryTint.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$earned / $total',
            style: aeCaption(color: theme.primary).copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _CareerAffiliationTimeline extends StatelessWidget {
  const _CareerAffiliationTimeline({
    required this.entries,
    required this.fallbackClubLogo,
    required this.theme,
  });

  final List<CareerAffiliationEntry> entries;
  final String? fallbackClubLogo;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _CareerAffiliationRow(
            entry: entries[i],
            showLine: i < entries.length - 1,
            fallbackClubLogo: fallbackClubLogo,
            theme: theme,
          ),
      ],
    );
  }
}

class _CareerAffiliationRow extends StatelessWidget {
  const _CareerAffiliationRow({
    required this.entry,
    required this.showLine,
    required this.fallbackClubLogo,
    required this.theme,
  });

  final CareerAffiliationEntry entry;
  final bool showLine;
  final String? fallbackClubLogo;
  final DugnadClubThemePalette theme;

  String? get _logoUrl {
    final fromApi = entry.clubLogoUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;

    if (entry.isCurrent ||
        (entry.organizationId > 0 &&
            entry.organizationId == DugnadState.instance.clubId)) {
      final cached = fallbackClubLogo?.trim();
      if (cached != null && cached.isNotEmpty) return cached;
      final stateLogo = DugnadState.instance.clubLogo.trim();
      if (stateLogo.isNotEmpty) return stateLogo;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final role = entry.isCurrent
        ? languages.dugnadCareerRoleCurrent
        : languages.dugnadCareerRoleTransfer;

    return Padding(
      padding: EdgeInsets.only(bottom: context.dp(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.dp(48),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: context.dp(48),
                  height: context.dp(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.dp(14)),
                    border: Border.all(
                      color: entry.isCurrent ? theme.primary : Colors.white,
                      width: entry.isCurrent ? 2 : 1,
                    ),
                    boxShadow: ScSaasThemeTokens.shadowCard,
                  ),
                  alignment: Alignment.center,
                  child: ClubCrest(
                    name: entry.clubName,
                    logoUrl: _logoUrl,
                    size: context.dp(34),
                  ),
                ),
                if (showLine)
                  Positioned(
                    top: 46,
                    bottom: -20,
                    child: Container(
                      width: 2,
                      color: ScSaasThemeTokens.gray100,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: context.dp(14)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: context.dp(3), bottom: context.dp(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.clubName,
                          style: aeLabel(color: theme.text).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      if (entry.isCurrent) ...[
                        SizedBox(width: context.dp(8)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryTint.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            languages.dugnadCareerNowBadge.toUpperCase(),
                            style: aeCaption(color: theme.primary).copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.04 * 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    role,
                    style: aeCaption(color: theme.primary).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  if (entry.seasonsLabel.isNotEmpty) ...[
                    SizedBox(height: context.dp(2)),
                    Text(
                      entry.seasonsLabel,
                      style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerTransferEntry extends StatelessWidget {
  const _CareerTransferEntry({
    required this.onTap,
    required this.theme,
  });

  final VoidCallback onTap;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(18)),
            border: Border.all(color: ScSaasThemeTokens.gray100, width: 1.5),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          padding: EdgeInsets.symmetric(horizontal: context.dp(16), vertical: context.dp(15)),
          child: Row(
            children: [
              Container(
                width: context.dp(44),
                height: context.dp(44),
                decoration: BoxDecoration(
                  color: const Color(0xFF22A769),
                  borderRadius: BorderRadius.circular(context.dp(13)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.autorenew_rounded, color: Colors.white, size: context.dp(20)),
              ),
              SizedBox(width: context.dp(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languages.dugnadTransitionWindowTitle,
                      style: aeLabel(color: theme.text).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    SizedBox(height: context.dp(2)),
                    Text(
                      languages.dugnadTransitionWindowSub,
                      style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: context.dp(18), color: ScSaasThemeTokens.gray500),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareerInfoFooter extends StatelessWidget {
  const _CareerInfoFooter({required this.text, required this.theme});

  final String text;
  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.dp(14)),
      decoration: BoxDecoration(
        color: theme.primaryTint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(context.dp(14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: context.dp(17), color: theme.primary),
          SizedBox(width: context.dp(10)),
          Expanded(
            child: Text(
              text,
              style: aeCaption(color: theme.primary).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
