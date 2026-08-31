import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../celebration_copy.dart';
import '../celebration_models.dart';
import '../dugnad_badge_emblem.dart';
import '../dugnad_badges.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_confetti.dart';
import 'dugnad_shiny_press.dart';
import 'dugnad_t16_sto_rise.dart';
import 'lucide_box_icon.dart';

class DugnadCelebrationOverlay extends StatefulWidget {
  const DugnadCelebrationOverlay({
    super.key,
    required this.item,
    required this.onDismiss,
    this.onCta,
    this.fullscreen = false,
  });

  final PendingCelebration item;
  final VoidCallback onDismiss;
  final VoidCallback? onCta;
  final bool fullscreen;

  @override
  State<DugnadCelebrationOverlay> createState() =>
      _DugnadCelebrationOverlayState();
}

class _DugnadCelebrationOverlayState extends State<DugnadCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _confetti;
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final AnimationController _progressFill;
  late final AnimationController _flashlight;
  late final Animation<double> _progress;
  bool _started = false;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressFill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progress = CurvedAnimation(
      parent: _progressFill,
      curve: const Interval(0.18, 0.82, curve: Curves.easeOutCubic),
    );
    _flashlight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    HapticFeedback.heavyImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != null && reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce == true) {
      _enter.value = 1;
      _confetti.value = 1;
      _progressFill.value = 1;
      _started = true;
      return;
    }
    if (_started) return;
    _started = true;
    _enter.forward();
    final type = widget.item.type;
    if (type == CelebrationType.t4) {
      _confetti.value = 1;
    } else {
      _confetti.forward();
    }
    _pulse.forward(from: 0);
    if (type == CelebrationType.t3) {
      _progressFill.forward(from: 0);
    } else {
      _progressFill.value = 1;
    }
    if (type == CelebrationType.t6 ||
        type == CelebrationType.t7 ||
        type == CelebrationType.t8 ||
        type == CelebrationType.t5a) {
      _flashlight.repeat();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _enter.dispose();
    _pulse.dispose();
    _progressFill.dispose();
    _flashlight.dispose();
    super.dispose();
  }

  Color _formAccent() {
    switch (widget.item.stringPayload('new_state')) {
      case 'up':
        return const Color(0xFF2BD67A);
      case 'down':
        return const Color(0xFFC9A024);
      default:
        return const Color(0xFF8E8B9A);
    }
  }

  IconData _formArrowIcon() {
    switch (widget.item.stringPayload('new_state')) {
      case 'up':
        return Icons.north_east_rounded;
      case 'down':
        return Icons.south_east_rounded;
      default:
        return Icons.east_rounded;
    }
  }

  Widget _formBody(
    BuildContext context,
    AeThemePalette theme,
    String eyebrow,
    String title,
    String body,
    bool reduce,
  ) {
    final accent = _formAccent();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CelebrationPoppingBadge(
          icon: _formArrowIcon(),
          color: accent,
          size: context.dp(78),
          pop: _pulse,
          reduceMotion: reduce,
        ),
        SizedBox(height: context.dp(15)),
        Text(
          eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: aeLabel(color: accent).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: context.dp(7)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: aeTitle(color: theme.ink).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (body.trim().isNotEmpty) ...[
          SizedBox(height: context.dp(8)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: aeBody(color: const Color(0xFF6B6580)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  IconData _throneIcon() {
    switch (widget.item.type) {
      case CelebrationType.t5a:
        return Icons.emoji_events_outlined;
      case CelebrationType.t5b:
      case CelebrationType.t15:
      case CelebrationType.t6:
        return Icons.shield_outlined;
      case CelebrationType.t7:
        // Design `ic: "box"` — drawn via [LucideBoxIcon], not Material.
        return Icons.inventory_2_outlined;
      case CelebrationType.t8:
        return Icons.share_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  /// Design Lucide `box` for T7 toppscorer (isometric cube).
  Widget? _throneIconWidget(double size) {
    if (widget.item.type != CelebrationType.t7) return null;
    return LucideBoxIcon(
      size: size,
      color: Colors.white,
      strokeWidth: 2.1,
    );
  }

  /// Spotlight rays for T5a / T6–T8. T5b and T15 are ring-only (no rays).
  bool _throneShowRays() {
    switch (widget.item.type) {
      case CelebrationType.t5b:
      case CelebrationType.t15:
        return false;
      default:
        return true;
    }
  }

  Widget _throneBody(
    BuildContext context,
    AeThemePalette theme,
    String eyebrow,
    String title,
    String body,
    bool reduce,
  ) {
    // Mock: dark badge ≈ 1/3 of card width (~96), rays larger; headline ~20.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CelebrationFlashlightBadge(
          icon: _throneIcon(),
          iconWidget: _throneIconWidget(context.dp(42)),
          color: theme.primary,
          gradient: theme.shinyGradient,
          size: context.dp(152),
          spin: _flashlight,
          pulse: _pulse,
          reduceMotion: reduce,
          showRays: _throneShowRays(),
        ),
        SizedBox(height: context.dp(6)),
        Text(
          eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: aeLabel(color: theme.ink).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: context.dp(7)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: aeTitle(color: theme.ink).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (body.trim().isNotEmpty) ...[
          SizedBox(height: context.dp(8)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: aeBody(color: const Color(0xFF6B6580)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  String _badgeKey() =>
      (widget.item.stringPayload('badge_key') ?? '').trim().toLowerCase();

  String _badgeIcon() {
    final fromPayload = (widget.item.stringPayload('icon') ?? '').trim();
    return dugnadBadgeIconForKey(_badgeKey(), fromPayload);
  }

  DugnadBadgeTone _badgeTone() {
    final raw = (widget.item.stringPayload('tone') ?? '').trim().toLowerCase();
    switch (raw) {
      case 'gold':
        return DugnadBadgeTone.gold;
      case 'green':
        return DugnadBadgeTone.green;
      case 'silver':
        return DugnadBadgeTone.silver;
      case 'purple':
        return DugnadBadgeTone.purple;
      default:
        return dugnadBadgeToneForKey(_badgeKey());
    }
  }

  String _badgeName(AppLocalizations l10n) {
    final name = widget.item.stringPayload('badge_name')?.trim() ?? '';
    return name.isNotEmpty ? name : l10n.celebrationTitleT2;
  }

  String _badgeSubtitle() {
    final fromPayload = widget.item.stringPayload('badge_sub')?.trim() ??
        widget.item.stringPayload('subtitle')?.trim() ??
        '';
    if (fromPayload.isNotEmpty) return fromPayload;
    final key = _badgeKey();
    if (key.isEmpty) return '';
    return dugnadBadgeUnlockSubtitle(key);
  }

  int _stoBonus() {
    return widget.item.intPayload('sto_bonus') ??
        widget.item.intPayload('points_bonus') ??
        0;
  }

  int _rewardPoints() => widget.item.intPayload('reward_points') ?? 0;

  bool _isSeasonGoal() =>
      (widget.item.stringPayload('kind') ?? '') == 'season_goal';

  String? _linkedBadgeName() {
    final name = widget.item.stringPayload('badge_name')?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return null;
  }

  IconData _challengeIcon() {
    if (_isSeasonGoal()) return Icons.emoji_events_outlined;
    final key = (widget.item.stringPayload('challenge_key') ??
            widget.item.stringPayload('title') ??
            '')
        .toLowerCase();
    if (key.contains('login') || key.contains('logg')) {
      return Icons.flag_outlined;
    }
    if (key.contains('share')) return Icons.share_outlined;
    if (key.contains('refer') || key.contains('verv')) {
      return Icons.person_add_alt_1_rounded;
    }
    if (key.contains('buy') ||
        key.contains('kjop') ||
        key.contains('kampanje')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.flag_outlined;
  }

  Widget _rewardPill({
    required BuildContext context,
    required AeThemePalette theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(10),
        vertical: context.dp(6),
      ),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dp(12), color: theme.ink),
          SizedBox(width: context.dp(5)),
          Text(
            label,
            style: aeLabel(color: theme.ink).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _challengeProgressBar(
    BuildContext context,
    AeThemePalette theme,
    bool reduce,
  ) {
    final track = theme.ink.withValues(alpha: 0.08);
    final fill = theme.primary;
    final h = context.dp(8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: h,
            width: maxW,
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final t = reduce ? 1.0 : _progress.value.clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: track)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: maxW * t,
                      child: ColoredBox(color: fill),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _challengeBody(
    BuildContext context,
    AeThemePalette theme,
    String eyebrow,
    String headline,
    String subtitle,
    bool reduce,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final points = _rewardPoints();
    final badgeName = _linkedBadgeName();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CelebrationPulsingIcon(
          icon: _challengeIcon(),
          color: theme.primary,
          gradient: theme.shinyGradient,
          size: context.dp(96),
          pulse: _pulse,
          reduceMotion: reduce,
        ),
        SizedBox(height: context.dp(15)),
        Text(
          eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: aeLabel(color: theme.ink).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: context.dp(7)),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: aeTitle(color: theme.ink).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: context.dp(8)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: aeBody(color: const Color(0xFF6B6580)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
        SizedBox(height: context.dp(14)),
        _challengeProgressBar(context, theme, reduce),
        if (points > 0 || badgeName != null) ...[
          SizedBox(height: context.dp(13)),
          if (points > 0 && badgeName != null) ...[
            _rewardPill(
              context: context,
              theme: theme,
              icon: Icons.star_rounded,
              label: l10n.dugnadPointsChip(points),
            ),
            SizedBox(height: context.dp(8)),
            _rewardPill(
              context: context,
              theme: theme,
              icon: Icons.shield_rounded,
              label: badgeName,
            ),
          ] else if (points > 0)
            _rewardPill(
              context: context,
              theme: theme,
              icon: Icons.star_rounded,
              label: l10n.dugnadPointsChip(points),
            )
          else if (badgeName != null)
            _rewardPill(
              context: context,
              theme: theme,
              icon: Icons.shield_rounded,
              label: badgeName,
            ),
        ],
      ],
    );
  }

  Widget _badgeBody(BuildContext context, AeThemePalette theme) {
    final l10n = AppLocalizations.of(context)!;
    final name = _badgeName(l10n);
    final sub = _badgeSubtitle();
    final sto = _stoBonus();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DugnadBadgeEmblem(
          iconName: _badgeIcon(),
          tone: _badgeTone(),
          locked: false,
          size: context.dp(78),
        ),
        SizedBox(height: context.dp(15)),
        Text(
          l10n.celebrationTitleT2.toUpperCase(),
          textAlign: TextAlign.center,
          style: aeLabel(color: theme.ink).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: context.dp(7)),
        Text(
          name,
          textAlign: TextAlign.center,
          style: aeTitle(color: theme.ink).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (sub.isNotEmpty) ...[
          SizedBox(height: context.dp(8)),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: aeBody(color: const Color(0xFF6B6580)).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
        if (sto > 0) ...[
          SizedBox(height: context.dp(13)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.dp(10),
              vertical: context.dp(6),
            ),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: context.dp(12),
                  color: theme.ink,
                ),
                SizedBox(width: context.dp(5)),
                Text(
                  l10n.dugnadBadgeStoEarned(sto),
                  style: aeLabel(color: theme.ink).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _genericBody(
    BuildContext context,
    AeThemePalette theme,
    Color accent,
    String title,
    String body,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.dp(72),
          height: context.dp(72),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.14),
          ),
          child: Icon(
            _iconFor(widget.item.type),
            size: context.dp(34),
            color: accent,
          ),
        ),
        SizedBox(height: context.dp(16)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.dp(22),
            fontWeight: FontWeight.w800,
            color: theme.ink,
            height: 1.2,
          ),
        ),
        if (body.trim().isNotEmpty) ...[
          SizedBox(height: context.dp(8)),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.dp(14.5),
              fontWeight: FontWeight.w500,
              color: theme.text.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final l10n = AppLocalizations.of(context)!;
    final copy = CelebrationCopy(l10n);
    final title = copy.title(widget.item);
    final body = copy.body(widget.item);
    final cta = copy.cta(widget.item);
    final eyebrow = copy.eyebrow(widget.item);
    final confettiColors = <Color>[
      theme.primary,
      theme.primaryHover,
      theme.primarySoft,
      Colors.white,
      const Color(0xFFF7CF6B),
    ];
    final isBadge = widget.item.type == CelebrationType.t2;
    final isChallenge = widget.item.type == CelebrationType.t3;
    final formOverlay = widget.item.type == CelebrationType.t4;
    final isStoRise = widget.item.type == CelebrationType.t16;
    final isThrone = widget.item.type == CelebrationType.t6 ||
        widget.item.type == CelebrationType.t7 ||
        widget.item.type == CelebrationType.t8 ||
        widget.item.type == CelebrationType.t5a ||
        widget.item.type == CelebrationType.t5b ||
        widget.item.type == CelebrationType.t15;
    final accent = formOverlay ? _formAccent() : theme.primary;
    final reduce = _reduceMotion == true;

    final card = ScaleTransition(
      scale: reduce
          ? const AlwaysStoppedAnimation(1)
          : CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: reduce
            ? const AlwaysStoppedAnimation(1)
            : CurvedAnimation(parent: _enter, curve: Curves.easeOut),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: widget.fullscreen ? double.infinity : context.dp(288),
            margin: EdgeInsets.symmetric(horizontal: context.dp(28)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.dp(26)),
              boxShadow: [
                BoxShadow(
                  color: theme.ink.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.dp(26)),
              ),
              // Clip so the top accent sits flush under the rounded card edge
              // (Design `.dgcp-card::before` — `top: 0`, not inside padded content).
              clipBehavior: Clip.antiAlias,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!formOverlay && !isStoRise)
                    Positioned(
                      top: 0,
                      left: context.dp(22),
                      right: context.dp(22),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withValues(alpha: 0),
                              theme.primary,
                              theme.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.dp(22),
                      context.dp(isStoRise ? 28 : 22),
                      context.dp(22),
                      context.dp(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBadge)
                          _badgeBody(context, theme)
                        else if (isStoRise)
                          DugnadT16StoRiseBody(
                            item: widget.item,
                            reduceMotion: reduce,
                          )
                        else if (isChallenge)
                          _challengeBody(
                            context,
                            theme,
                            title,
                            widget.item.stringPayload('title')?.trim() ?? '',
                            body,
                            reduce,
                          )
                        else if (formOverlay)
                          _formBody(
                            context,
                            theme,
                            eyebrow,
                            title,
                            body,
                            reduce,
                          )
                        else if (isThrone)
                          _throneBody(
                            context,
                            theme,
                            eyebrow,
                            title,
                            body,
                            reduce,
                          )
                        else
                          _genericBody(context, theme, accent, title, body),
                        SizedBox(height: context.dp(16)),
                        // Same shiny primary CTA as club shop "Lås opp shop".
                        DugnadShinyPress(
                          borderRadius: context.dp(14),
                          onTap: widget.onCta ?? widget.onDismiss,
                          child: Container(
                            width: double.infinity,
                            height: context.dp(48),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: theme.shinyGradient,
                              borderRadius:
                                  BorderRadius.circular(context.dp(14)),
                              boxShadow: theme.shadowButton,
                            ),
                            child: Text(
                              cta,
                              style: aeLabel(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Design `.dgpp-x` — absolute so it overlaps the badge row.
                  Positioned(
                    top: context.dp(14),
                    right: context.dp(14),
                    child: Material(
                      color: theme.ink.withValues(alpha: 0.07),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onDismiss,
                        child: SizedBox(
                          width: context.dp(32),
                          height: context.dp(32),
                          child: Icon(
                            Icons.close_rounded,
                            size: context.dp(18),
                            color: theme.ink,
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
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: widget.onDismiss,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: theme.ink.withValues(
                    alpha: widget.fullscreen ? 0.55 : 0.38,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: reduce || formOverlay
                ? card
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      card,
                      // Design `.dgpp-confetti` — paper bits on the card face.
                      Positioned.fill(
                        child: AeCardPaperConfetti(
                          progress: _confetti,
                          colors: confettiColors,
                        ),
                      ),
                    ],
                  ),
          ),
          // ON TOP of the modal (not behind) so the burst reads as coming
          // from the card and falling top→bottom across it — design image.
          if (!reduce && !formOverlay)
            Positioned.fill(
              child: IgnorePointer(
                child: AeDesignBurstConfetti(
                  colors: confettiColors,
                  count: 110,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(CelebrationType type) {
    switch (type) {
      case CelebrationType.t2:
        return Icons.workspace_premium_outlined;
      case CelebrationType.t3:
        return Icons.flag_outlined;
      case CelebrationType.t4:
        return Icons.trending_up;
      case CelebrationType.t5a:
      case CelebrationType.t9:
        return Icons.emoji_events_outlined;
      case CelebrationType.t5b:
      case CelebrationType.t15:
        return Icons.shield_outlined;
      case CelebrationType.t6:
      case CelebrationType.t12:
        return Icons.star_outline;
      case CelebrationType.t7:
      case CelebrationType.t10:
        return Icons.inventory_2_outlined;
      case CelebrationType.t8:
      case CelebrationType.t11:
        return Icons.share_outlined;
      case CelebrationType.t13:
        return Icons.groups_outlined;
      case CelebrationType.t14:
        return Icons.favorite_outline;
      case CelebrationType.t16:
        return Icons.star_outline;
      default:
        return Icons.celebration_outlined;
    }
  }
}

/// Circular hero icon with a one-shot radial pulse (T3).
class _CelebrationPulsingIcon extends StatelessWidget {
  const _CelebrationPulsingIcon({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.size,
    required this.pulse,
    required this.reduceMotion,
  });

  final IconData icon;
  final Color color;
  /// Same club shiny ramp as the primary CTA (Design `--ae-shiny-purple`).
  final Gradient gradient;
  final double size;
  final AnimationController pulse;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    // Design `.dgcp-orb` 84 / `.disc` 68 ≈ 0.81 of the outer bounce area.
    final core = size * 0.81;

    Widget rings() {
      if (reduceMotion) return const SizedBox.shrink();
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          if (pulse.status == AnimationStatus.completed ||
              pulse.value >= 0.999) {
            return const SizedBox.shrink();
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(
                progress: Interval(0.0, 0.72, curve: Curves.easeOut)
                    .transform(pulse.value.clamp(0.0, 1.0)),
                size: size,
                color: color,
              ),
              _PulseRing(
                progress: Interval(0.18, 0.95, curve: Curves.easeOut)
                    .transform(pulse.value.clamp(0.0, 1.0)),
                size: size,
                color: color,
              ),
            ],
          );
        },
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          rings(),
          Container(
            width: core,
            height: core,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: size * 0.24,
                  offset: Offset(0, size * 0.08),
                  spreadRadius: -size * 0.08,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: core * 0.44,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// T4 arrow badge — scales in once with a short overshoot.
class _CelebrationPoppingBadge extends StatelessWidget {
  const _CelebrationPoppingBadge({
    required this.icon,
    required this.color,
    required this.size,
    required this.pop,
    required this.reduceMotion,
  });

  final IconData icon;
  final Color color;
  final double size;
  final AnimationController pop;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final core = size * 0.72;
    final badge = Container(
      width: core,
      height: core,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: core * 0.42,
        color: Colors.white,
      ),
    );

    if (reduceMotion) {
      return SizedBox(width: size, height: size, child: Center(child: badge));
    }

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(pop);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: ScaleTransition(scale: scale, child: badge),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    final scale = 0.72 + eased * 0.55;
    // Fade fully out by the end of the one-shot (Design `dgcp-ring` → opacity 0).
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.45;
    if (opacity <= 0.01) return const SizedBox.shrink();

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: context.dp(2.5),
          ),
        ),
      ),
    );
  }
}

/// Rotating searchlight rays behind a circular throne badge (T5a / T6–T8).
/// T5b / T15 use the same core badge with one-shot pulse rings only (no rays).
/// Rings vanish when the entry pulse finishes — no static leftover rings.
class _CelebrationFlashlightBadge extends StatelessWidget {
  const _CelebrationFlashlightBadge({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.size,
    required this.spin,
    required this.pulse,
    required this.reduceMotion,
    this.showRays = true,
    this.iconWidget,
  });

  final IconData icon;
  /// When set (e.g. Lucide box for T7), used instead of [icon].
  final Widget? iconWidget;
  final Color color;
  /// Same club shiny ramp as the primary CTA (Design `--ae-shiny-purple`).
  final Gradient gradient;
  final double size;
  final AnimationController spin;
  final AnimationController pulse;
  final bool reduceMotion;
  final bool showRays;

  @override
  Widget build(BuildContext context) {
    // Dark circle ≈ 2/3 of ray canvas → ~100dp when size is 152.
    final core = size * 0.66;

    Widget rays() {
      if (!showRays) return const SizedBox.shrink();
      Widget paintAt(double t) {
        return CustomPaint(
          size: Size.square(size),
          painter: _FlashlightRaysPainter(progress: t, color: color),
        );
      }

      if (reduceMotion) return paintAt(0.12);
      return AnimatedBuilder(
        animation: spin,
        builder: (context, _) => paintAt(spin.value),
      );
    }

    Widget pulseRings() {
      if (reduceMotion) return const SizedBox.shrink();
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          // One-shot only — hide once the controller has completed.
          if (pulse.status == AnimationStatus.completed ||
              pulse.value >= 0.999) {
            return const SizedBox.shrink();
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(
                progress: Interval(0.0, 0.72, curve: Curves.easeOut)
                    .transform(pulse.value.clamp(0.0, 1.0)),
                size: size * 0.88,
                color: color,
              ),
              _PulseRing(
                progress: Interval(0.18, 0.95, curve: Curves.easeOut)
                    .transform(pulse.value.clamp(0.0, 1.0)),
                size: size * 0.88,
                color: color,
              ),
            ],
          );
        },
      );
    }

    final badge = Stack(
      alignment: Alignment.center,
      children: [
        rays(),
        pulseRings(),
        Container(
          width: core,
          height: core,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: size * 0.16,
                offset: Offset(0, size * 0.05),
                spreadRadius: -size * 0.04,
              ),
            ],
          ),
          child: Center(
            child: iconWidget ??
                Icon(
                  icon,
                  size: core * 0.42,
                  color: Colors.white,
                ),
          ),
        ),
      ],
    );

    if (reduceMotion) {
      return SizedBox(width: size, height: size, child: badge);
    }

    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
    ]).animate(pulse);

    return SizedBox(
      width: size,
      height: size,
      child: ScaleTransition(scale: scale, child: badge),
    );
  }
}

class _FlashlightRaysPainter extends CustomPainter {
  _FlashlightRaysPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);

    const beamCount = 4;
    for (var i = 0; i < beamCount; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, -radius),
          [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
        );
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(-radius * 0.16, -radius)
        ..lineTo(radius * 0.16, -radius)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlashlightRaysPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
