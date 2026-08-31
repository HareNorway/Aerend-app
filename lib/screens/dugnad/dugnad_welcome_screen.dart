import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_scale.dart';
import '../../theme/sc_saas_theme.dart';
import '../../utils/utils.dart';
import '../common/homeMainV1/home_main_v1.dart';
import 'celebration_models.dart';
import 'dugnad_celebration_orchestrator.dart';
import 'dugnad_club_theme.dart';
import 'dugnad_state.dart';
import 'widgets/dugnad_confetti.dart';
import 'widgets/dugnad_metal_animations.dart';
import 'widgets/dugnad_points_pop.dart';

/// Post-onboarding welcome celebration — matches gamify.jsx `CelebrationOverlay`
/// + `PointsReward` welcome mockup (first login / new user flow only).
///
/// Club-change welcome (T14) uses [DugnadCeremonialScreen] + contract card instead.
class DugnadWelcomeScreen extends StatefulWidget {
  const DugnadWelcomeScreen({
    super.key,
    this.welcomeBonusPoints = 30,
    this.bonusAwarded = false,
    this.referralJoinPoints = 0,
  });

  final int welcomeBonusPoints;
  final bool bonusAwarded;
  final int referralJoinPoints;

  @override
  State<DugnadWelcomeScreen> createState() => _DugnadWelcomeScreenState();
}

class _DugnadWelcomeScreenState extends State<DugnadWelcomeScreen>
    with TickerProviderStateMixin {
  static const _pageTop = Color(0xFFFBF8FF);

  late final AnimationController _confettiController;
  late final AnimationController _enterController;
  late final Animation<double> _popScale;
  late final Animation<double> _popOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _ctaOpacity;

  @override
  void initState() {
    super.initState();
    DugnadCelebrationOrchestrator.instance.holdCriticalFlow();
    unawaited(
      DugnadCelebrationOrchestrator.instance.consumeTypeIfPending(
        CelebrationType.t14,
      ),
    );
    HapticFeedback.heavyImpact();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _popScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Cubic(0.2, 1.3, 0.4, 1.0),
      ),
    );
    _popOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.32, curve: Curves.easeOut),
      ),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.14, 0.58, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.14, 0.58, curve: Curves.easeOutCubic),
      ),
    );
    _ctaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.38, 0.9, curve: Curves.easeOut),
      ),
    );

  }

  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // CelebrationOverlay reduced motion: the pop-in resets and the content
      // lands final. Drive the entrance to its end and drop the confetti
      // particles rather than starting either.
      setState(() => _reduceMotion = true);
      _enterController.value = 1;
      return;
    }

    _confettiController.forward();
    _enterController.forward();
  }

  @override
  void dispose() {
    DugnadCelebrationOrchestrator.instance.releaseCriticalFlow();
    _confettiController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  void _continue() {
    unawaited(_continueToHome());
  }

  Future<void> _continueToHome() async {
    await DugnadState.instance.syncPointsTeamFromServer();
    if (!mounted) return;
    openScreenWithClearPrevious(
      context,
      const HomeMainV1(isShowDialog: true),
    );
  }

  List<Color> _confettiPalette(DugnadClubThemePalette theme) {
    return [
      theme.primary,
      theme.primarySoft,
      const Color(0xFFF7CF6B),
      const Color(0xFFE0A93A),
      ScSaasThemeTokens.success,
      Colors.white,
      theme.ink,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final ink = theme.ink;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.2,
            colors: [
              _pageTop,
              theme.background,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: Stack(
          children: [
            DugnadPointsPopTrigger(
              points: widget.welcomeBonusPoints,
              reason: DugnadPointsPopReasons.welcome(context),
              enabled: widget.bonusAwarded && widget.welcomeBonusPoints > 0,
            ),
            DugnadPointsPopTrigger(
              points: widget.referralJoinPoints,
              reason: DugnadPointsPopReasons.referralJoin(context),
              enabled: widget.referralJoinPoints > 0,
              extraDelay: const Duration(milliseconds: 80),
            ),
            if (!_reduceMotion)
              DugnadConfetti(
                progress: _confettiController,
                colors: _confettiPalette(theme),
                includeStars: false,
                fadeByHeight: true,
              ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.dp(28), context.dp(8), context.dp(28), context.dp(20)),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _continue,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            width: context.dp(38),
                            height: context.dp(38),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.07),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: context.dp(18),
                              color: ink.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FadeTransition(
                                    opacity: _popOpacity,
                                    child: ScaleTransition(
                                      scale: _popScale,
                                      child: _WelcomeBrandMark(theme: theme),
                                    ),
                                  ),
                                  SizedBox(height: context.dp(22)),
                                  SlideTransition(
                                    position: _contentSlide,
                                    child: FadeTransition(
                                      opacity: _contentOpacity,
                                      child: Column(
                                        children: [
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 320,
                                            ),
                                            child: Text(
                                              languages.dugnadWelcomeTitle,
                                              textAlign: TextAlign.center,
                                              style: aeH2(color: ink).copyWith(
                                                fontSize: 23,
                                                fontWeight: FontWeight.w900,
                                                height: 1.12,
                                                letterSpacing: 23 * -0.025,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: context.dp(8)),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 300,
                                            ),
                                            child: Text(
                                              languages.dugnadWelcomeSubtitle,
                                              textAlign: TextAlign.center,
                                              style: aeBody(
                                                color: ScSaasThemeTokens.gray700,
                                              ).copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: context.dp(1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.dp(20)),
                                  FadeTransition(
                                    opacity: _contentOpacity,
                                    child: _WelcomePointsReward(
                                        theme: theme,
                                        points: widget.welcomeBonusPoints,
                                        awarded: widget.bonusAwarded,
                                        label: widget.bonusAwarded
                                            ? languages.dugnadWelcomeBonusLabel
                                            : languages
                                                .dugnadWelcomeBonusPendingLabel,
                                        tip: widget.bonusAwarded
                                            ? languages.dugnadWelcomeTip
                                            : languages
                                                .dugnadWelcomeBonusPendingTip,
                                        popScale: _popScale,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: context.dp(28)),
                    FadeTransition(
                      opacity: _ctaOpacity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _continue,
                          borderRadius: BorderRadius.circular(context.dp(16)),
                          child: Ink(
                            width: double.infinity,
                            height: context.dp(54),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.dp(16)),
                              gradient: theme.shinyGradient,
                              boxShadow: theme.shadowButton,
                            ),
                            child: Center(
                              child: Text(
                                languages.dugnadWelcomeCta,
                                style: aeLabel(color: Colors.white).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
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
          ],
        ),
      ),
    );
  }
}

/// Top brand orb — `.cel-burst` heart burst (mockup header graphic).
class _WelcomeBrandMark extends StatelessWidget {
  const _WelcomeBrandMark({required this.theme});

  final DugnadClubThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(96),
      height: context.dp(96),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: theme.shinyGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.45),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.62),
            blurRadius: context.dp(34),
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: context.dp(42),
      ),
    );
  }
}

/// `.dg-ptsreward` + `.cel-carry-note` block from gamify.css.
class _WelcomePointsReward extends StatefulWidget {
  const _WelcomePointsReward({
    required this.theme,
    required this.points,
    required this.awarded,
    required this.label,
    required this.tip,
    required this.popScale,
  });

  final DugnadClubThemePalette theme;
  final int points;
  final bool awarded;
  final String label;
  final String tip;
  final Animation<double> popScale;

  @override
  State<_WelcomePointsReward> createState() => _WelcomePointsRewardState();
}

class _WelcomePointsRewardState extends State<_WelcomePointsReward>
    with SingleTickerProviderStateMixin {
  static const _goldLight = Color(0xFFF7D979);
  static const _goldMid = Color(0xFFE0A93A);
  static const _goldDark = Color(0xFFC2871C);
  static const _goldText = Color(0xFF9A6B12);
  static const _coinLight = Color(0xFFFFE9A8);
  static const _coinMid = Color(0xFFE7B542);

  static const _coinOffsets = <Offset>[
    Offset(-52, -18),
    Offset(-34, -44),
    Offset(4, -56),
    Offset(40, -40),
    Offset(54, -10),
    Offset(40, 22),
    Offset(-30, 24),
    Offset(-50, 14),
  ];

  static const _coinDelays = <double>[
    0.04,
    0.10,
    0.02,
    0.12,
    0.06,
    0.14,
    0.08,
    0.16,
  ];

  late final AnimationController _coinController;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // `.dg-ptsreward .medal .coin` is display:none under reduced motion. Left
    // at value 0 every coin's AnimatedBuilder returns SizedBox.shrink(), so
    // simply not starting the controller drops the particles while the medal
    // stays.
    if (!MediaQuery.disableAnimationsOf(context)) {
      _coinController.forward();
    }
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const medalSize = 88.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          SizedBox(
            width: context.dp(160),
            height: context.dp(120),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < _coinOffsets.length; i++)
                  AnimatedBuilder(
                    animation: _coinController,
                    builder: (context, _) {
                      final delay = _coinDelays[i];
                      const duration = 0.95;
                      final t = ((_coinController.value - delay) / duration)
                          .clamp(0.0, 1.0);
                      if (t <= 0) return const SizedBox.shrink();

                      final opacity = t < 0.22
                          ? t / 0.22
                          : max(0.0, 1 - ((t - 0.22) / 0.78));
                      final scale = 0.3 + min(0.55, t * 0.85);
                      final offset = Offset(
                        _coinOffsets[i].dx * t,
                        _coinOffsets[i].dy * t,
                      );

                      return Positioned.fill(
                        child: Center(
                          child: Transform.translate(
                            offset: offset,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: context.dp(19),
                                  height: context.dp(19),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_coinLight, _coinMid],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _goldMid.withValues(alpha: 0.7),
                                        blurRadius: context.dp(5),
                                        offset: const Offset(0, 2),
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: context.dp(10),
                                    color: _goldText.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ScaleTransition(
                  scale: widget.popScale,
                  child: Container(
                    width: medalSize,
                    height: medalSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment(-0.5, -1),
                        end: Alignment(0.8, 1),
                        colors: [_goldLight, _goldMid, _goldDark],
                        stops: [0.0, 0.62, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: const Color(0xFFD8A028).withValues(alpha: 0.7),
                          blurRadius: context.dp(28),
                          offset: const Offset(0, 14),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.28, -0.32),
                                radius: 0.95,
                                colors: [
                                  Colors.white.withValues(alpha: 0.38),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: DugnadMetalGlazeOverlay(
                              borderRadius: 999,
                              phase: 0.12,
                              overContent: true,
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.star_rounded,
                              color: Colors.white.withValues(alpha: 0.96),
                              size: context.dp(36),
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
          Text(
            '+${widget.points}',
            textAlign: TextAlign.center,
            style: aeH2(color: _goldText).copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 34 * -0.03,
              height: context.dp(1),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: context.dp(5)),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: aeBody(color: widget.theme.primaryHover).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: 12.5 * 0.01,
            ),
          ),
          SizedBox(height: context.dp(12)),
          _WelcomeTipCard(theme: widget.theme, tip: widget.tip),
        ],
      ),
    );
  }
}

class _WelcomeTipCard extends StatelessWidget {
  const _WelcomeTipCard({
    required this.theme,
    required this.tip,
  });

  final DugnadClubThemePalette theme;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.dp(13), context.dp(11), context.dp(13), context.dp(11)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(14)),
        boxShadow: [
          BoxShadow(
            color: theme.ink.withValues(alpha: 0.06),
            blurRadius: context.dp(6),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.dp(1)),
            child: Icon(
              Icons.shield_outlined,
              size: context.dp(14),
              color: theme.primaryHover,
            ),
          ),
          SizedBox(width: context.dp(8)),
          Expanded(
            child: Text(
              tip,
              style: aeBody(color: ScSaasThemeTokens.gray700).copyWith(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
