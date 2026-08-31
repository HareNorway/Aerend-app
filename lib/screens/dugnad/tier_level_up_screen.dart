import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import 'dugnad_badges.dart';
import 'dugnad_club_branding.dart';
import 'dugnad_form_utils.dart';
import 'dugnad_models.dart';
import 'dugnad_share.dart';
import 'dugnad_state.dart';
import 'dugnad_sto_utils.dart';
import '../../ui/kit/ae_theme.dart';
import '../../ui/kit/ae_confetti.dart';
import 'widgets/dugnad_player_card.dart';
import '../../ui/kit/ae_rise_in.dart';
import 'widgets/dugnad_shiny_press.dart';
import '../../ui/kit/ae_support_share.dart';

/// Full-screen celebration when the user reaches a new points tier.
/// Shows old metal STØ card → squash-flip → new metal card (CelMetalUp mockup).
class TierLevelUpScreen extends StatefulWidget {
  const TierLevelUpScreen({
    super.key,
    required this.fromTier,
    required this.toTier,
    required this.fromStoRating,
    required this.toStoRating,
    required this.points,
    required this.displayName,
    required this.purchases,
    required this.referrals,
    this.badges = const [],
    this.formStatus,
    this.nextTier,
    required this.onDone,
  });

  final MetalTierInfo fromTier;
  final MetalTierInfo toTier;
  final int fromStoRating;
  final int toStoRating;
  final int points;
  final String displayName;
  final int purchases;
  final int referrals;
  final List<DugnadBadgeItem> badges;
  final DugnadFormStatus? formStatus;
  final MetalTierInfo? nextTier;
  final VoidCallback onDone;

  static Future<void> show(
    BuildContext context, {
    required MetalTierInfo fromTier,
    required MetalTierInfo toTier,
    required int fromStoRating,
    required int toStoRating,
    required int points,
    required String displayName,
    int purchases = 0,
    int referrals = 0,
    List<DugnadBadgeItem> badges = const [],
    DugnadFormStatus? formStatus,
    MetalTierInfo? nextTier,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => TierLevelUpScreen(
          fromTier: fromTier,
          toTier: toTier,
          fromStoRating: fromStoRating,
          toStoRating: toStoRating,
          points: points,
          displayName: displayName,
          purchases: purchases,
          referrals: referrals,
          badges: badges,
          formStatus: formStatus,
          nextTier: nextTier,
          onDone: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<TierLevelUpScreen> createState() => _TierLevelUpScreenState();
}

class _TierLevelUpScreenState extends State<TierLevelUpScreen>
    with TickerProviderStateMixin {
  static const _pageTop = Color(0xFFFBF8FF);

  late final AnimationController _confettiController;
  late final AnimationController _flipController;
  late final AnimationController _ratingController;
  late final AnimationController _deltaController;

  late final Animation<double> _squash;
  late final Animation<double> _skew;

  bool _showNewFace = false;
  int _displayRating = 0;

  // Reduced-motion gate: controllers are constructed eagerly in initState but
  // only started in didChangeDependencies, once, behind `_started`. The delayed
  // starts are cancellable Timers so none outlives disposal.
  bool _started = false;
  bool _reduceMotion = false;
  bool _flipBurst = false;
  Timer? _seq1;
  Timer? _seq2;
  Timer? _seq3;
  Timer? _seq4;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _displayRating = widget.fromStoRating;

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _squash = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.03)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 46,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 54,
      ),
    ]).animate(_flipController);

    _skew = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.08),
        weight: 46,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.08, end: 0.0),
        weight: 54,
      ),
    ]).animate(_flipController);

    _ratingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _deltaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipController.addListener(() {
      if (!_showNewFace && _flipController.value >= 0.46) {
        setState(() => _showNewFace = true);
        HapticFeedback.mediumImpact();
      }
    });

    _ratingController.addListener(() {
      final t = Curves.easeOutCubic.transform(_ratingController.value);
      setState(() {
        _displayRating = (widget.fromStoRating +
                (widget.toStoRating - widget.fromStoRating) * t)
            .round();
      });
    });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // `.cel-metalup` under reduced motion: `.cmu-ring`/`.cmu-card` reset (no
      // ring pulse, no card flip), `.cmu-delta.on` lands at its end state
      // (opacity:1, transform:none) and the `.dg-ptsreward .medal .coin`
      // particles are `display:none`. So the level-up shows only its result —
      // the new metal card and the final +N badge, both final, no confetti.
      setState(() {
        _reduceMotion = true;
        _showNewFace = true;
        _displayRating = widget.toStoRating;
      });
      _deltaController.value = 1;
      return;
    }

    _confettiController.forward();
    _runSequence();
  }

  // Cumulative-offset cancellable timers rather than a chained Future.delayed:
  // each is stored and cancelled in dispose, so none can fire after teardown.
  void _runSequence() {
    _seq1 = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _flipController.forward();
    });
    _seq2 = Timer(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => _flipBurst = true);
    });
    _seq3 = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) _ratingController.forward();
    });
    _seq4 = Timer(const Duration(milliseconds: 1450), () {
      if (mounted) _deltaController.forward();
    });
  }

  @override
  void dispose() {
    _seq1?.cancel();
    _seq2?.cancel();
    _seq3?.cancel();
    _seq4?.cancel();
    _confettiController.dispose();
    _flipController.dispose();
    _ratingController.dispose();
    _deltaController.dispose();
    super.dispose();
  }

  Future<void> _share(BuildContext shareContext) async {
    final club = DugnadClubBranding.fullName();
    final link = await fetchAeSupportShareLink();
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

  String get _crestName {
    final ds = DugnadState.instance;
    if (ds.hasPointsTeam && ds.pointsTeamName.isNotEmpty) {
      return ds.pointsTeamName;
    }
    return DugnadClubBranding.fullName();
  }

  String? get _crestLogo {
    final ds = DugnadState.instance;
    if (ds.hasPointsTeam && ds.pointsTeamLogo.isNotEmpty) {
      return ds.pointsTeamLogo;
    }
    return ds.clubLogo.isEmpty ? null : ds.clubLogo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final tierName = widget.toTier.titleSuffix;
    final nextName = widget.nextTier?.titleSuffix;
    final delta = widget.toStoRating - widget.fromStoRating;
    final metalLabel = dugnadMetalDisplayLabel(widget.toTier.metal);
    final cardWidth =
        DugnadPlayerCard.stoCardWidth(MediaQuery.sizeOf(context).width);
    final cardMinHeight = DugnadPlayerCard.stoCardMinHeight(cardWidth);

    final confettiColors = <Color>[
      theme.primary,
      theme.primaryHover,
      theme.primarySoft,
      Colors.white,
      const Color(0xFFF7CF6B),
    ];

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.2,
            colors: [_pageTop, theme.background],
            stops: const [0.0, 0.6],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(26),
                      context.dp(8),
                      context.dp(26),
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onDone,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            width: context.dp(38),
                            height: context.dp(38),
                            decoration: BoxDecoration(
                              color: theme.ink.withValues(alpha: 0.07),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: context.dp(18),
                              color: theme.ink.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        context.dp(26),
                        context.dp(8),
                        context.dp(26),
                        context.dp(18),
                      ),
                      child: AeSuccessCardWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _flipController,
                                _ratingController,
                              ]),
                              builder: (context, _) {
                                final faceTier = _showNewFace
                                    ? widget.toTier
                                    : widget.fromTier;
                                return Center(
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.001)
                                            ..setEntry(0, 0, _squash.value)
                                            ..setEntry(0, 1, _skew.value),
                                          child: DugnadPlayerCard(
                                            name: widget.displayName,
                                            tier: faceTier,
                                            points: widget.points,
                                            stoRating: _displayRating,
                                            isCaptain: DugnadState
                                                .instance.hasPointsTeam,
                                            crestName: _crestName,
                                            crestLogo: _crestLogo,
                                            purchases: widget.purchases,
                                            referrals: widget.referrals,
                                            badges: widget.badges,
                                            formStatus: widget.formStatus,
                                            width: cardWidth,
                                            minHeight: cardMinHeight,
                                            showRisingChevron:
                                                _showNewFace && delta > 0,
                                          ),
                                        ),
                                        if (!_reduceMotion)
                                          Positioned.fill(
                                            child: AeCardPaperConfetti(
                                              progress: _confettiController,
                                              colors: confettiColors,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: context.dp(16)),
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _deltaController,
                                curve: Curves.easeOut,
                              ),
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.5, end: 1)
                                    .animate(
                                  CurvedAnimation(
                                    parent: _deltaController,
                                    curve: const Cubic(0.2, 1.4, 0.4, 1),
                                  ),
                                ),
                                child: delta > 0
                                    ? Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.dp(13),
                                            vertical: context.dp(6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: ScSaasThemeTokens.success,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            boxShadow: [
                                              BoxShadow(
                                                color: ScSaasThemeTokens
                                                    .success
                                                    .withValues(alpha: 0.45),
                                                blurRadius: context.dp(16),
                                                offset: const Offset(0, 8),
                                                spreadRadius: -4,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.north_east_rounded,
                                                size: context.dp(13),
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: context.dp(4)),
                                              Text(
                                                '+$delta STØ · $metalLabel',
                                                style: aeLabel(
                                                        color: Colors.white)
                                                    .copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                  height: 1,
                                                  leadingDistribution:
                                                      TextLeadingDistribution
                                                          .even,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            SizedBox(height: context.dp(22)),
                            AeRiseIn(
                              delay: const Duration(milliseconds: 120),
                              child: Text(
                                languages.dugnadLevelUpTitle(tierName),
                                style: aeH2(color: theme.ink).copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: context.dp(8)),
                            AeRiseIn(
                              delay: const Duration(milliseconds: 190),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: context.dp(12)),
                                child: Text(
                                  nextName != null
                                      ? languages.dugnadLevelUpThanks(nextName)
                                      : languages.dugnadLevelUpThanksMax,
                                  style: aeBody(
                                          color: ScSaasThemeTokens.gray700)
                                      .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(height: context.dp(22)),
                            AeRiseIn(
                              delay: const Duration(milliseconds: 260),
                              child: SizedBox(
                                width: double.infinity,
                                child: AeSupportShareCard(
                                  teamName: DugnadClubBranding.fullName(),
                                  message: languages
                                      .dugnadShareCardMessage(tierName),
                                  logoUrl:
                                      DugnadState.instance.clubLogo.isEmpty
                                          ? null
                                          : DugnadState.instance.clubLogo,
                                  eyebrow: languages.dugnadSupporterLabel,
                                  maxWidth: double.infinity,
                                ),
                              ),
                            ),
                            SizedBox(height: context.dp(16)),
                            AeRiseIn(
                              delay: const Duration(milliseconds: 440),
                              duration: const Duration(milliseconds: 550),
                              child: GestureDetector(
                                onTap: () => _share(context),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        context.dp(16)),
                                    border: Border.all(
                                        color: ScSaasThemeTokens.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_outlined,
                                          size: context.dp(18)),
                                      SizedBox(width: context.dp(8)),
                                      Expanded(
                                        child: Text(
                                          languages.dugnadShareResult,
                                          style: aeBody().copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7CF6B),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          languages.dugnadSharePointsReward(20),
                                          style: aeCaption().copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF7A5A00),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: context.dp(10)),
                            AeRiseIn(
                              delay: const Duration(milliseconds: 490),
                              duration: const Duration(milliseconds: 550),
                              child: DugnadShinyPress(
                                borderRadius: context.dp(14),
                                onTap: widget.onDone,
                                child: Container(
                                  width: double.infinity,
                                  height: context.dp(52),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: theme.shinyGradient,
                                    borderRadius: BorderRadius.circular(
                                        context.dp(14)),
                                    boxShadow: theme.shadowButton,
                                  ),
                                  child: Text(
                                    languages.dugnadCheerButton,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 16 * -0.01,
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
                ],
              ),
            ),
            if (!_reduceMotion)
              Positioned.fill(
                child: IgnorePointer(
                  child: AeDesignBurstConfetti(
                    colors: confettiColors,
                    count: 110,
                  ),
                ),
              ),
            if (!_reduceMotion && _flipBurst)
              Positioned.fill(
                child: IgnorePointer(
                  child: AeDesignBurstConfetti(
                    colors: confettiColors,
                    count: 95,
                    duration: const Duration(milliseconds: 4600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
