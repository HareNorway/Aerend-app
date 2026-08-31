import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../club_crest.dart';
import '../dugnad_badge_emblem.dart';
import '../dugnad_badges.dart';
import '../dugnad_form_utils.dart';
import '../dugnad_models.dart';
import '../metal_hero_tokens.dart';
import '../points_metal_theme.dart';
import '../tour/dugnad_tour_keys.dart';
import 'ae_metal_hero_surface.dart';
import 'dugnad_metal_animations.dart';

/// FIFA-style STØ supporter card — shared by STØ-kort and level-up celebration.
class DugnadPlayerCard extends StatelessWidget {
  const DugnadPlayerCard({
    super.key,
    required this.name,
    required this.tier,
    required this.points,
    required this.stoRating,
    required this.isCaptain,
    required this.crestName,
    required this.crestLogo,
    required this.purchases,
    required this.referrals,
    this.badges = const [],
    this.width = 270,
    this.minHeight,
    this.showRisingChevron = false,
    this.animateIn = false,
    this.formStatus,
    this.onFormTap,
    this.onRatingInfoTap,
    this.registerTourKeys = false,
  });

  final String name;
  final MetalTierInfo? tier;
  final int points;
  final int stoRating;
  final bool isCaptain;
  final String crestName;
  final String? crestLogo;
  final int purchases;
  final int referrals;
  final List<DugnadBadgeItem> badges;
  final double width;
  /// When set, the card stretches to a portrait rectangle (supporter card screen).
  final double? minHeight;
  final bool showRisingChevron;

  /// When true the card fades + scales in and the rating/stat numbers count up
  /// on first mount. Left off for the level-up celebration, which drives its
  /// own reveal.
  final bool animateIn;

  /// Cosmetic tempo indicator (prototype `FormArrow` chip). Display ONLY — form
  /// never feeds the STØ rating. Null hides the chip.
  final DugnadFormStatus? formStatus;

  /// Optional tap on the form chip (opens the form explainer sheet).
  final VoidCallback? onFormTap;

  /// Optional tap on the rating info icon (opens the STØ rating sheet).
  final VoidCallback? onRatingInfoTap;

  /// When true, attaches guided-tour registry keys to the form chip and badges
  /// row. Only SupporterCardScreen sets this — the card also renders on the
  /// level-up and preview screens, where a second key would collide.
  final bool registerTourKeys;

  /// Portrait STØ-kort size used on the supporter card screen: ~72% of screen
  /// width, clamped 250–310, with a 1.42 tall aspect.
  static double stoCardWidth(double screenWidth) =>
      (screenWidth * 0.72).clamp(250.0, 310.0);

  static double stoCardMinHeight(double cardWidth) => cardWidth * 1.42;

  /// Attaches a tour registry key to [child] only when [registerTourKeys] is on.
  /// KeyedSubtree renders the child identically, so appearance is unchanged.
  Widget _maybeTourKey(DugnadTourTarget target, Widget child) => registerTourKeys
      ? KeyedSubtree(key: DugnadTourKeys.register(target), child: child)
      : child;

  @override
  Widget build(BuildContext context) {
    final metal = tier?.metal ?? 'bronse';
    // Metal ink — every label/icon on the card inherits this (prototype uses
    // `currentColor`), NOT gray/midnight.
    final fg = PointsMetalTheme.levelHeroForegroundColor(metal);
    final positionLabel =
        isCaptain ? languages.dugnadKapPosition : languages.dugnadStoPosition;
    final inset = PointsMetalTheme.playerCardInset(metal);
    final divider = PointsMetalTheme.playerCardDivider(metal);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final counting = animateIn && !reduceMotion;
    // Bronse is a darker surface than gull/sølv/platina, so the reduced-opacity
    // secondary ink goes muddy where it crosses the darker bottom of the
    // gradient. Bump the two lowest-opacity elements on Bronse ONLY; the light
    // metals keep the prototype opacities (.72 / .82).
    final bool bronse = metal == 'bronse';
    final double suffixOpacity = bronse ? 0.90 : 0.82;
    final double statLabelOpacity = bronse ? 0.85 : 0.72;
    final bool tall = minHeight != null;
    final double avatarSize = tall ? 96.0 : 86.0;
    final double avatarIconSize = tall ? 46.0 : 42.0;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        tall ? 22 : 20,
        20,
        tall ? 18 : 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.pc-head-left` — rating + form with ~22 gap. Info controls live
              // in reserved gutters (in-layout) so they stay hittable and glued
              // to their targets without stealing Row width.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: onRatingInfoTap != null ? context.dp(8) : 0,
                          // Full 20px for `.pc-rating-i` so it never covers digits.
                          right: onRatingInfoTap != null ? context.dp(20) : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CountUpNumber(
                                  value: stoRating,
                                  animate: counting,
                                  duration: const Duration(milliseconds: 1000),
                                  style: aeH2().copyWith(
                                    fontSize: 40,
                                    height: 0.95,
                                    letterSpacing: -0.04 * 40,
                                    fontWeight: FontWeight.w900,
                                    color: fg,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                if (showRisingChevron) ...[
                                  SizedBox(width: context.dp(6)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: ScSaasThemeTokens.success,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      size: context.dp(12),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: context.dp(2)),
                            Text(
                              positionLabel,
                              style:
                                  aeCaption(color: fg.withValues(alpha: 0.8))
                                      .copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.04 * 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onRatingInfoTap != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _PcInfoButton(
                            color: fg,
                            size: 20,
                            iconSize: 12,
                            bordered: true,
                            opacity: 0.6,
                            onTap: onRatingInfoTap!,
                          ),
                        ),
                    ],
                  ),
                  if (formStatus != null) ...[
                    // Rating gutter already holds the info; keep remaining gap small
                    // so total number→form ≈ mockup 22.
                    SizedBox(width: context.dp(onRatingInfoTap != null ? 4 : 22)),
                    Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: onFormTap != null ? context.dp(8) : 3,
                            right: onFormTap != null ? context.dp(10) : 0,
                          ),
                          child: GestureDetector(
                            onTap: onFormTap,
                            behavior: HitTestBehavior.opaque,
                            // formButton target: the visible form chip. Keyed
                            // here (not the tiny _PcInfoButton at the Stack's
                            // top-right, which is a conditional 12px affordance).
                            child: _maybeTourKey(
                              DugnadTourTarget.formButton,
                              DugnadFormArrow(
                                status: formStatus!,
                                size: context.dp(15),
                                chip: true,
                                showLabel: false,
                              ),
                            ),
                          ),
                        ),
                        if (onFormTap != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _PcInfoButton(
                              color: fg,
                              iconSize: 12,
                              opacity: 0.7,
                              onTap: onFormTap!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Container(
                width: context.dp(52),
                height: context.dp(52),
                decoration: BoxDecoration(
                  color: inset,
                  borderRadius: BorderRadius.circular(context.dp(14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: ClubCrest(
                  name: crestName,
                  logoUrl: crestLogo,
                  size: context.dp(42),
                ),
              ),
            ],
          ),
          SizedBox(height: tall ? 16 : 8),
          Column(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: inset,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: avatarIconSize,
                  color: fg,
                ),
              ),
              SizedBox(height: tall ? 10 : 6),
              Text(
                name,
                style: aeTitle().copyWith(
                  fontSize: tall ? 22 : 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.02 * 20,
                  color: fg,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.dp(2)),
              Text(
                (tier?.titleSuffix ?? '').toUpperCase(),
                style: aeCaption(
                  color: fg.withValues(alpha: suffixOpacity),
                ).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.05 * 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(height: tall ? 16 : 14),
          Column(
            children: [
              Divider(color: divider, height: 1),
              SizedBox(height: tall ? 14 : 13),
              Row(
                children: [
                  _DugnadPlayerStat(
                    value: points,
                    label: languages.dugnadPointsStat,
                    ink: fg,
                    labelOpacity: statLabelOpacity,
                    animate: counting,
                  ),
                  _DugnadPlayerStat(
                    value: purchases,
                    label: languages.dugnadGoalsPurchases,
                    ink: fg,
                    labelOpacity: statLabelOpacity,
                    animate: counting,
                  ),
                  _DugnadPlayerStat(
                    value: referrals,
                    label: languages.dugnadAssistsReferrals,
                    ink: fg,
                    labelOpacity: statLabelOpacity,
                    animate: counting,
                  ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                SizedBox(height: tall ? 14 : 13),
                // badges target keyed on the Row, which only exists when there
                // are badges — so isResolvable is false when the user has none.
                _maybeTourKey(
                  DugnadTourTarget.badges,
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < badges.length; i++) ...[
                      if (i > 0) SizedBox(width: context.dp(8)),
                      Container(
                        width: context.dp(30),
                        height: context.dp(30),
                        decoration: BoxDecoration(
                          color: inset,
                          borderRadius: BorderRadius.circular(context.dp(9)),
                        ),
                        child: Icon(
                          dugnadBadgeIconData(badges[i].icon),
                          size: context.dp(16),
                          color: fg,
                        ),
                      ),
                    ],
                  ],
                ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Family A (specular + bounce on the 3-stop metal ramp) — the same lit
    // surface as Dine poeng. A ramp-only BoxDecoration reads as flat grey.
    final radius = context.dp(24);
    Widget face = Stack(
      children: [
        Positioned.fill(
          child: DugnadMetalGlazeOverlay(
            borderRadius: radius,
            overContent: true,
          ),
        ),
        content,
      ],
    );
    if (minHeight != null) {
      face = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight!),
        child: face,
      );
    }
    final card = SizedBox(
      width: width,
      child: AeMetalHeroSurface(
        metal: metal,
        radius: 24,
        scale: AeMetalSurfaceScale.hero,
        child: face,
      ),
    );

    if (!counting) return card;

    // Entrance: Y-axis flip from back → front (perspective).
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      child: card,
      builder: (_, t, child) {
        final angle = (1 - t) * math.pi; // π → 0
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.00115)
            ..rotateY(angle),
          child: Opacity(
            opacity: (0.4 + 0.6 * t).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}

class _PcInfoButton extends StatelessWidget {
  const _PcInfoButton({
    required this.color,
    required this.onTap,
    this.size,
    this.iconSize = 16,
    this.opacity = 0.65,
    this.bordered = false,
  });

  final Color color;
  final VoidCallback onTap;
  final double? size;
  final double iconSize;
  final double opacity;
  /// Rating (`.pc-rating-i`): outer CSS ring + info glyph. Form stays bare.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ink = color.withValues(alpha: opacity);
    final glyph = Icon(
      Icons.info_outline_rounded,
      size: context.dp(iconSize),
      color: ink,
    );

    // Hit size == visual size so Positioned(top/right) stays glued to the
    // form chip / rating gutter (a larger box + Align shifted the glyph away).
    final Widget child = bordered
        ? SizedBox(
            width: context.dp(size ?? 20),
            height: context.dp(size ?? 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ink),
              ),
              child: Center(child: glyph),
            ),
          )
        : SizedBox(
            width: context.dp(iconSize + 4),
            height: context.dp(iconSize + 4),
            child: Center(child: glyph),
          );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _DugnadPlayerStat extends StatelessWidget {
  const _DugnadPlayerStat({
    required this.value,
    required this.label,
    required this.ink,
    required this.labelOpacity,
    this.animate = false,
  });

  final int value;
  final String label;
  final Color ink;
  final double labelOpacity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _CountUpNumber(
            value: value,
            animate: animate,
            duration: const Duration(milliseconds: 900),
            style: aeH2().copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.02 * 17,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: context.dp(2)),
          Text(
            label,
            style: aeCaption(color: ink.withValues(alpha: labelOpacity))
                .copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 8.5,
              letterSpacing: 0.04 * 8.5,
              height: context.dp(1.25),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Number that counts up from 0 on first mount, or renders statically when
/// [animate] is false (level-up card, reduced-motion). Mirrors the prototype's
/// animated rating/points counters.
class _CountUpNumber extends StatelessWidget {
  const _CountUpNumber({
    required this.value,
    required this.style,
    required this.animate,
    required this.duration,
  });

  final int value;
  final TextStyle style;
  final bool animate;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (!animate) return Text('$value', style: style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$v', style: style),
    );
  }
}
