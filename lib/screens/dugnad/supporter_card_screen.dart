import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commonView/skeleton_loaders/dugnad_subpage_skeletons.dart';
import '../../services/dugnad_data_cache.dart';
import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_form_utils.dart';
import 'dugnad_models.dart';
import 'dugnad_points_widgets.dart';
import 'dugnad_repo.dart';
import 'dugnad_share.dart';
import 'dugnad_state.dart';
import 'dugnad_sto_source_breakdown.dart';
import 'dugnad_sto_utils.dart';
import 'gamification_models.dart';
import 'tier_level_up_screen.dart';
import 'tour/dugnad_tour_controller.dart';
import 'tour/dugnad_tour_keys.dart';
import 'widgets/dugnad_form_explainer_sheet.dart';
import 'widgets/dugnad_player_card.dart';
import '../../ui/kit/ae_rise_in.dart';
import 'widgets/dugnad_sto_explainer_sheet.dart';
import '../../ui/kit/ae_subpage_shell.dart';
import '../../ui/kit/ae_theme.dart';

/// FIFA-style supporter card (prototype: player-card.jsx).
class SupporterCardScreen extends StatefulWidget {
  const SupporterCardScreen({super.key});

  @override
  State<SupporterCardScreen> createState() => _SupporterCardScreenState();
}

class _SupporterCardScreenState extends State<SupporterCardScreen> {
  final DugnadRepo _repo = DugnadRepo();
  final DugnadDataCache _cache = DugnadDataCache.instance;
  PointsSummary? _summary;
  GamificationConfig? _config;
  StoSourcePoints? _stoBreakdown;
  List<DugnadBadgeItem> _badges = const [];
  GamificationProgress? _progress;
  bool _loading = true;
  bool _levelUpChecked = false;

  /// Owns the feed scroll position so the guided tour can follow it (Chunk 3).
  final ScrollController _tourScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Newest live instance takes player-card key ownership. Ownership is read at
    // build time (isPlayerCardOwner) so a superseded instance stops registering.
    DugnadTourKeys.claimPlayerCard(this);
    // Seed from home cache so the card (and tour keys) paint on the first
    // frame — sequential network in [_load] otherwise exceeds the tour's
    // ~2.5s poll and short-circuits to the done step.
    final cached = _cache.peekPointsSummary();
    if (cached != null) {
      _summary = cached;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _tourScrollController.dispose();
    // Release + drop the player-card tour keys, but only if this instance owns
    // them (no-op for a denied second instance). Owner release re-arms a fresh
    // register on the next push.
    DugnadTourKeys.releasePlayerCard(this);
    // Tell the tour (if running) the player card is gone — it dismisses if the
    // user left via a pop the controller didn't initiate. No-op for the tour's
    // own pop (guarded by _expectedPop inside the controller).
    DugnadTourController.active?.notifyPlayerCardScreenDisposed();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final clubId = DugnadState.instance.clubId;
      final hasClub = DugnadState.instance.hasClub;
      final teamId = DugnadState.instance.hasPointsTeam
          ? DugnadState.instance.pointsTeamId
          : null;

      // Parallel fetch — the old sequential chain routinely took >2.5s and
      // caused the guided tour to give up on sto/form/badges.
      final results = await Future.wait<Object?>([
        _cache.getPointsSummary(),
        hasClub
            ? _cache.getGamificationConfig(organizationId: clubId)
            : Future<GamificationConfig?>.value(null),
        hasClub
            ? _cache.getGamificationCareer(
                organizationId: clubId,
                teamId: teamId,
              )
            : Future<GamificationCareer?>.value(null),
        hasClub
            ? _repo.getGamificationProgress(organizationId: clubId)
            : Future<GamificationProgress?>.value(null),
        _cache.getReferralSummary(organizationId: clubId),
        _repo.getAllPointsLedgerEntries(),
      ]);

      final summary = results[0] as PointsSummary?;
      final config = results[1] as GamificationConfig?;
      final career = results[2] as GamificationCareer?;
      final progress = results[3] as GamificationProgress?;
      final referral = results[4] as ReferralSummary?;
      final entries = (results[5] as List<PointsLedgerEntry>?) ?? const [];

      final hasSub = entries.any(
        (e) => e.action == 'subscription_donation' && e.points > 0,
      );

      final sections = buildDugnadBadgeSections(
        catalog: config?.stoBadges,
        permanentEarned: career?.permanentBadges ?? const [],
        seasonalEarned: career?.seasonalBadges ?? const [],
        seasonLabel: career?.activeSeason?.label ?? progress?.activeSeason?.label,
        progress: DugnadBadgeProgressContext(
          referrals: summary?.actionCounts.referralConversions ??
              referral?.convertedCount ??
              0,
          hasSub: hasSub,
          streakWeeks: progress?.streakWeeks ?? 0,
          metricProgress: dugnadMergedBadgeProgress(
            career: career,
            progress: progress,
          ),
        ),
      );

      final breakdown = computeStoSourceBreakdown(
        entries: entries,
        seasonPoints: summary?.seasonPoints ?? summary?.lifetimePoints ?? 0,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary ?? _summary;
        _config = config;
        _stoBreakdown = breakdown;
        _badges = sections.all;
        _progress = progress;
        _loading = false;
      });

      // Level-up sheet would cover the tour spotlight — skip while touring.
      if (!_levelUpChecked &&
          summary != null &&
          DugnadTourController.active == null) {
        _levelUpChecked = true;
        await _maybeShowLevelUp(summary, config);
      } else if (summary != null) {
        _levelUpChecked = true;
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _maybeShowLevelUp(
    PointsSummary summary,
    GamificationConfig? config,
  ) async {
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
      final stoTiers = config?.stoTierThresholds ?? const [];
      await TierLevelUpScreen.show(
        context,
        fromTier: fromTier,
        toTier: currentTier,
        fromStoRating: dugnadTierStoRatingForMetal(fromTier.metal, stoTiers),
        toStoRating: summary.stoRating,
        points: summary.lifetimePoints,
        displayName: _displayName(),
        purchases: summary.actionCounts.campaignPurchases,
        referrals: summary.actionCounts.referralConversions,
        badges: _badges.where((b) => b.earned).take(3).toList(),
        formStatus: _progress != null
            ? dugnadFormStatusFromProgress(_progress!)
            : null,
        nextTier: summary.nextTier,
      );
    }
    await prefSetString(storageKey, currentTier.key);
  }

  void _openRatingSheet() {
    final summary = _summary;
    if (summary == null) return;
    HapticFeedback.lightImpact();
    DugnadStoExplainerSheet.show(
      context,
      summary: summary,
      breakdown: _stoBreakdown ??
          computeStoSourceBreakdown(
            entries: const [],
            seasonPoints: summary.seasonPoints,
          ),
      earnedBadgeCount: _badges.where((b) => b.earned).length,
      config: _config,
    );
  }

  void _openFormSheet() {
    HapticFeedback.lightImpact();
    final progress = _progress;
    final status = progress != null
        ? dugnadFormStatusFromProgress(progress)
        : DugnadFormStatus.up;
    DugnadFormExplainerSheet.show(
      context,
      status: status,
      history: progress?.formHistory ?? const [],
      formValue: progress?.formValue ?? 70,
      floor: progress?.formFloor ?? 40,
    );
  }

  void _share(BuildContext shareContext) async {
    final club = DugnadClubBranding.fullName();
    final share = await _repo.getShareSummary(
      organizationId: DugnadState.instance.clubId,
    );
    final link = share?.shareLink?.trim() ?? '';
    final text = link.isNotEmpty
        ? languages.dugnadSupporterCardShareMessage(
            languages.dugnadSupporterCardTitle,
            club,
            link,
          )
        : '${languages.dugnadSupporterCardTitle} — $club 💜';
    if (!shareContext.mounted) return;
    await shareDugnadText(
      shareContext,
      text: text,
      subject: prefGetString(prefUserName),
    );
  }

  @override
  Widget build(BuildContext context) {
    dugnadApplyMetalColorOverrides(summary: _summary, config: _config);
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = DugnadPlayerCard.stoCardWidth(screen.width);
    final cardMinHeight = DugnadPlayerCard.stoCardMinHeight(cardWidth);

    return AeFixedTypography(
      child: Scaffold(
        backgroundColor: context.aeTheme.primary,
        body: AeScrollBody(
          scrollController: _tourScrollController,
          hero: AeSimpleHero(
            title: languages.dugnadSupporterCardTitle,
            onBack: () => Navigator.of(context).pop(),
          ),
          bottomPadding: 36,
          topPadding: 28,
          children: [
            if (_loading)
              const DugnadSupporterCardSkeleton()
            else
              Center(
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeyedSubtree(
                        key: DugnadTourKeys.isPlayerCardOwner(this)
                            ? DugnadTourKeys.register(
                                DugnadTourTarget.playerCard)
                            : null,
                        child: DugnadPlayerCard(
                        registerTourKeys: DugnadTourKeys.isPlayerCardOwner(this),
                        name: _displayName(),
                        tier: _summary?.currentTier,
                        points: _summary?.lifetimePoints ?? 0,
                        stoRating: _summary?.stoRating ?? 40,
                        isCaptain: DugnadState.instance.hasPointsTeam,
                        crestName: _crestName(),
                        crestLogo: _crestLogo(),
                        purchases:
                            _summary?.actionCounts.campaignPurchases ?? 0,
                        referrals:
                            _summary?.actionCounts.referralConversions ?? 0,
                        badges:
                            _badges.where((b) => b.earned).take(3).toList(),
                        // Skip flip while the guided tour is measuring — a
                        // mid-rotateY rect spills the hole off the right edge.
                        animateIn: DugnadTourController.active == null,
                        width: cardWidth,
                        minHeight: cardMinHeight,
                        formStatus: _progress != null
                            ? dugnadFormStatusFromProgress(_progress!)
                            : DugnadFormStatus.up,
                        onRatingInfoTap: _openRatingSheet,
                        onFormTap: _openFormSheet,
                        ),
                      ),
                      SizedBox(height: context.dp(16)),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 160),
                        child: _SeeRatingButton(onPressed: _openRatingSheet),
                      ),
                      SizedBox(height: context.dp(10)),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 240),
                        child: _ShareCardButton(onPressed: _share),
                      ),
                      SizedBox(height: context.dp(16)),
                      AeRiseIn(
                        delay: const Duration(milliseconds: 320),
                        child: Text(
                          languages.dugnadCardValueHint,
                          style: aeCaption(color: ScSaasThemeTokens.gray500)
                              .copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            height: context.dp(1.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _displayName() {
    final fromSummary = _summary?.publicDisplayName.trim();
    if (fromSummary != null && fromSummary.isNotEmpty) {
      return fromSummary;
    }
    return prefGetString(prefUserName);
  }

  String _crestName() {
    final ds = DugnadState.instance;
    if (ds.hasPointsTeam && ds.pointsTeamName.isNotEmpty) {
      return ds.pointsTeamName;
    }
    return DugnadClubBranding.fullName();
  }

  String? _crestLogo() {
    final ds = DugnadState.instance;
    if (ds.hasPointsTeam && ds.pointsTeamLogo.isNotEmpty) {
      return ds.pointsTeamLogo;
    }
    final clubLogo = ds.clubLogo;
    return clubLogo.isEmpty ? null : clubLogo;
  }
}

class _ShareCardButton extends StatelessWidget {
  const _ShareCardButton({required this.onPressed});

  final void Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    // Match design `.ae-btn` (`--ae-r-md: 14px`) — Material must use the same
    // radius + clip or ink paints a sharp rectangular frame around the pill.
    final radius = BorderRadius.circular(context.dp(14));
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dp(270)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: context.aeTheme.primary.withValues(alpha: 0.35),
                blurRadius: context.dp(16),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed(context);
              },
              borderRadius: radius,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: context.aeTheme.heroGradient,
                  borderRadius: radius,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.dp(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        size: context.dp(17),
                        color: Colors.white,
                      ),
                      SizedBox(width: context.dp(8)),
                      Text(
                        languages.dugnadShareYourCard,
                        style: aeLabel(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeRatingButton extends StatelessWidget {
  const _SeeRatingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.dp(14));
    final borderColor = context.aeTheme.primary.withValues(alpha: 0.22);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dp(270)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: context.aeTheme.text.withValues(alpha: 0.08),
                blurRadius: context.dp(14),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              borderRadius: radius,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: context.dp(15)),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: context.dp(18),
                      color: context.aeTheme.primary,
                    ),
                    SizedBox(width: context.dp(8)),
                    Text(
                      languages.dugnadSeeWhatMakesRating,
                      style: aeLabel(color: context.aeTheme.primaryHover)
                          .copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 16 * -0.01,
                      ),
                    ),
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
