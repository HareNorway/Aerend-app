import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/dugnad_data_cache.dart';
import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../dugnad_badges.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_form_utils.dart';
import '../dugnad_models.dart';
import '../dugnad_state.dart';
import '../gamification_models.dart';
import 'dugnad_player_card.dart';

/// Team-selection hero — STØ card + SIGNERT stamp (`dgseq-sign` in celebrate-pops).
class DugnadTeamSignCard extends StatefulWidget {
  const DugnadTeamSignCard({
    super.key,
    required this.teamName,
    this.teamLogoUrl,
  });

  final String teamName;
  final String? teamLogoUrl;

  @override
  State<DugnadTeamSignCard> createState() => _DugnadTeamSignCardState();
}

class _DugnadTeamSignCardState extends State<DugnadTeamSignCard>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _stamp;
  bool? _reduceMotion;
  List<DugnadBadgeItem> _badges = const [];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _stamp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _badges = _badgesFromCache();
    unawaited(_loadBadges());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != null && reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce == true) {
      _enter.value = 1;
      _stamp.value = 1;
    } else if (_enter.status == AnimationStatus.dismissed) {
      _enter.forward();
      Future<void>.delayed(const Duration(milliseconds: 1020), () {
        if (mounted) _stamp.forward();
      });
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _stamp.dispose();
    super.dispose();
  }

  double _stampScale(double t) {
    if (t < 0.7) return 2.6 - (1.66 * (t / 0.7));
    return 0.94 + (0.06 * ((t - 0.7) / 0.3));
  }

  List<DugnadBadgeItem> _cardBadges() =>
      _badges.where((b) => b.earned).take(3).toList();

  List<DugnadBadgeItem> _badgesFromCache() {
    final ds = DugnadState.instance;
    if (!ds.hasClub) return const [];
    final clubId = ds.clubId;
    final teamId = ds.hasPointsTeam ? ds.pointsTeamId : null;
    final cache = DugnadDataCache.instance;
    return _sectionsFor(
      cache.peek<GamificationConfig>(
        DugnadDataCache.gamificationConfigKey(clubId),
      ),
      cache.peek<GamificationCareer>(
        DugnadDataCache.gamificationCareerKey(clubId, teamId),
      ),
      cache.peekPointsSummary(),
    ).all;
  }

  Future<void> _loadBadges() async {
    final ds = DugnadState.instance;
    if (!ds.hasClub) return;
    final clubId = ds.clubId;
    final teamId = ds.hasPointsTeam ? ds.pointsTeamId : null;
    final cache = DugnadDataCache.instance;
    try {
      final results = await Future.wait<Object?>([
        cache.getGamificationConfig(organizationId: clubId, teamId: teamId),
        cache.getGamificationCareer(organizationId: clubId, teamId: teamId),
      ]);
      if (!mounted) return;
      final next = _sectionsFor(
        results[0] as GamificationConfig?,
        results[1] as GamificationCareer?,
        cache.peekPointsSummary(),
      ).all;
      if (next.isEmpty && _badges.isEmpty) return;
      setState(() => _badges = next);
    } catch (_) {}
  }

  DugnadBadgeSections _sectionsFor(
    GamificationConfig? config,
    GamificationCareer? career,
    PointsSummary? summary,
  ) {
    return buildDugnadBadgeSections(
      catalog: config?.stoBadges,
      permanentEarned: career?.permanentBadges ?? const [],
      seasonalEarned: career?.seasonalBadges ?? const [],
      seasonLabel: career?.activeSeason?.label,
      progress: DugnadBadgeProgressContext(
        referrals: summary?.actionCounts.referralConversions ?? 0,
        metricProgress: dugnadMergedBadgeProgress(career: career),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final l10n = AppLocalizations.of(context)!;
    final summary = DugnadDataCache.instance.peekPointsSummary();
    final ds = DugnadState.instance;
    final playerName = () {
      final fromSummary = summary?.publicDisplayName.trim() ?? '';
      if (fromSummary.isNotEmpty) return fromSummary;
      return prefGetString(prefUserName);
    }();
    final crestName = widget.teamName.trim().isNotEmpty
        ? widget.teamName
        : DugnadClubBranding.fullName();
    final crestLogo = widget.teamLogoUrl?.trim().isNotEmpty == true
        ? widget.teamLogoUrl
        : (ds.pointsTeamLogo.isNotEmpty
            ? ds.pointsTeamLogo
            : (ds.clubLogo.isEmpty ? null : ds.clubLogo));
    final stampColor = Color.lerp(theme.primary, Colors.black, 0.12)!;
    final cardWidth = context.dp(300);
    // Same portrait ratio as the supporter-card screen (~1.42).
    final cardMinHeight = cardWidth * 1.42;
    // Design `.dgseq-sign .cardwrap` — `transform: scale(.78)`.
    const cardScale = 0.78;

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _stamp]),
      builder: (context, _) {
        return SizedBox(
          width: cardWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: context.dp(-46),
                child: IgnorePointer(
                  child: Container(
                    width: context.dp(230),
                    height: context.dp(250),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.95),
                        radius: 0.7,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _reduceMotion == true
                    ? const AlwaysStoppedAnimation(1)
                    : CurvedAnimation(parent: _enter, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: _reduceMotion == true
                      ? const AlwaysStoppedAnimation(cardScale)
                      : Tween<double>(begin: 0.6, end: cardScale).animate(
                          CurvedAnimation(
                            parent: _enter,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                  child: Transform.rotate(
                    angle: _reduceMotion == true
                        ? 0
                        : (1 - _enter.value) * -0.07,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DugnadPlayerCard(
                            name: playerName.isNotEmpty
                                ? playerName
                                : 'Spiller',
                            tier: summary?.currentTier,
                            points: summary?.lifetimePoints ?? 0,
                            stoRating: summary?.stoRating ?? 40,
                            isCaptain: true,
                            crestName: crestName,
                            crestLogo: crestLogo,
                            purchases:
                                summary?.actionCounts.campaignPurchases ?? 0,
                            referrals:
                                summary?.actionCounts.referralConversions ?? 0,
                            badges: _cardBadges(),
                            width: cardWidth,
                            minHeight: cardMinHeight,
                            animateIn: false,
                            formStatus: DugnadFormStatus.up,
                          ),
                          // Design `.dgseq-sign .stamp`: right 6px, bottom -2px,
                          // rotate -11deg — on the card, not the unscaled wrap.
                          if (_reduceMotion == true || _stamp.value > 0)
                            Positioned(
                              right: context.dp(6),
                              bottom: context.dp(-2),
                              child: Transform.rotate(
                                angle: -0.19,
                                child: Transform.scale(
                                  // Undo [cardScale] so the stamp stays the
                                  // design 13px size (CSS stamp sits outside
                                  // `.cardwrap`).
                                  scale: (_reduceMotion == true
                                          ? 1
                                          : _stampScale(_stamp.value)) /
                                      cardScale,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.dp(12),
                                      vertical: context.dp(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: stampColor,
                                      borderRadius: BorderRadius.circular(
                                        context.dp(8),
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      l10n.celebrationContractStamp,
                                      style: aeLabel(
                                        color: Colors.white,
                                      ).copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1.4,
                                      ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
