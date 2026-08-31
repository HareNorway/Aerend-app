import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../../../theme/sc_saas_theme.dart';
import '../dugnad_state.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_hourglass.dart';
import 'dugnad_metal_animations.dart';
import '../../../ui/kit/ae_rise_in.dart';

/// Identifies the faked top-edge `inset` highlight, so a test can tell it apart
/// from the metal glaze overlays — which are also transparent-stop gradients.
const Key kEntryInsetTopKey = ValueKey('ae-entry-inset-top');

/// Identifies `leagueGold`'s bottom-anchored inset tint.
const Key kEntryInsetBottomKey = ValueKey('ae-entry-inset-bottom');

/// Identifies `referralPurple`'s child radial overlay.
const Key kEntryRadialOverlayKey = ValueKey('ae-entry-radial-overlay');

/// Home feed CTA banner — mirrors `lb-entry` / `dg-missions-entry` /
/// `dg-transfer-banner` / `dg-ref-banner` prototype cards.
class DugnadFeedEntryBanner extends StatelessWidget {
  const DugnadFeedEntryBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.variant,
    this.leading,
    this.trailingIsNorthEast = false,
    this.animateLeading = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final DugnadFeedEntryVariant variant;
  final Widget? leading;
  final bool trailingIsNorthEast;
  /// Pulse/pop the leading icon (referral share, etc.).
  final bool animateLeading;

  /// Same loop speed as campaign glaze; offset so sweeps don't fire together.
  static double _glazePhaseFor(DugnadFeedEntryVariant variant) {
    switch (variant) {
      case DugnadFeedEntryVariant.leagueGold:
        return 0.12;
      case DugnadFeedEntryVariant.missionsPurple:
        return 0.34;
      case DugnadFeedEntryVariant.transferDark:
        return 0.58;
      case DugnadFeedEntryVariant.referralPurple:
        return 0.76;
      case DugnadFeedEntryVariant.supportLight:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final style = _styleFor(context, variant, theme);
    final trailingIcon = trailingIsNorthEast
        ? Icons.north_east_rounded
        : Icons.chevron_right_rounded;

    Widget icon = leading ??
        _IconBox(
          icon: style.fallbackIcon,
          light: style.isLight,
          accent: style.iconAccent,
          background: style.iconBackground,
          size: style.iconSize,
          borderColor: style.iconBorderColor,
        );
    if (animateLeading) {
      icon = AePulseIcon(
        child: AeCampCtaMotion(iconPop: true, child: icon),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(context.dp(18)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: style.gradient,
            color: style.solidColor,
            borderRadius: BorderRadius.circular(context.dp(18)),
            border: style.border,
            boxShadow: style.shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.dp(18)),
            child: Stack(
              children: [
                // Soft metal ambient polish only — no opaque circular spotlight.
                if (style.showAmbientPolish)
                  Positioned.fill(
                    child: DugnadMetalAmbientGlaze(borderRadius: context.dp(18)),
                  ),
                if (style.showGlaze)
                  Positioned.fill(
                    child: DugnadMetalGlazeOverlay(
                      borderRadius: context.dp(18),
                      phase: _glazePhaseFor(variant),
                      overContent: true,
                    ),
                  ),
                // A positioned child paints this, not the card's own
                // background — reading the card's computed style would miss it
                // entirely (rule 17).
                if (style.radialOverlay != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: kEntryRadialOverlayKey,
                        decoration: BoxDecoration(gradient: style.radialOverlay),
                      ),
                    ),
                  ),
                // Faked CSS `inset` layers (rule 5). Inside the clip, under the
                // content; the drop shadows stay on the parent decoration.
                for (final inset in style.insets)
                  Positioned.fill(
                    child: _InsetLayer(inset: inset),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.dp(16),
                    context.dp(style.padV),
                    context.dp(16),
                    context.dp(style.padV),
                  ),
                  child: Row(
                    children: [
                      icon,
                      SizedBox(width: context.dp(13)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AeDugnadText.bannerTitle(
                                color: style.titleColor,
                              ).copyWith(
                                fontSize: context.dp(style.titleSize),
                                fontWeight: FontWeight.w900,
                                // em-relative, and the em value is per variant:
                                // leagueGold tracks -0.02em, the rest -0.01em.
                                // A shared -0.015 was right for neither.
                                letterSpacing:
                                    context.dp(style.titleSize) *
                                        style.titleTracking,
                              ),
                            ),
                            SizedBox(height: context.dp(style.subtitleGap)),
                            Text(
                              subtitle,
                              maxLines: style.subtitleMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: AeDugnadText.bannerSubtitle(
                                color: style.subtitleColor,
                              ).copyWith(
                                fontSize: context.dp(style.subtitleSize),
                                fontWeight: style.subtitleWeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      Container(
                        width: context.dp(style.goSize),
                        height: context.dp(style.goSize),
                        decoration: BoxDecoration(
                          color: style.goBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          trailingIcon,
                          size: context.dp(18),
                          color: style.goIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DugnadFeedEntryVariant {
  leagueGold,
  missionsPurple,
  transferDark,
  supportLight,
  referralPurple,
}

/// A CSS `inset` box-shadow, faked as an edge gradient inside the clip.
///
/// Flutter's [BoxShadow] has no inset mode and dropping these layers is what
/// makes a ported surface read flat (rule 5). The design uses exactly two
/// shapes across the five variants:
///
/// * **top highlight** — `0 1px 1px rgba(255,255,255,α) inset`. A 1px inset on
///   a card of height `H` spans `1/H` of it.
/// * **bottom tint** — only `leagueGold`'s
///   `0 -10px 18px rgba(190,135,30,0.16) inset`. The **negative** y-offset
///   pushes the glow *up* from the bottom edge, so it is anchored to the bottom
///   and spans `18/H`. It is not a second top highlight.
///
/// Two of the five variants have **no** inset at all. That is deliberate — see
/// rule 20 on not normalising across treatments.
class _EntryInset {
  const _EntryInset.top(this.color) : extentPx = 1, fromBottom = false;

  const _EntryInset.bottom(this.color, {required this.extentPx})
      : fromBottom = true;

  final Color color;

  /// How far the highlight reaches from its edge, in design px.
  final double extentPx;

  /// Anchored to the bottom edge rather than the top.
  final bool fromBottom;
}

class _EntryStyle {
  const _EntryStyle({
    required this.isLight,
    required this.showGlaze,
    this.showAmbientPolish = false,
    required this.titleColor,
    required this.subtitleColor,
    required this.goBackground,
    required this.goIconColor,
    this.padV = 15,
    required this.titleSize,
    required this.titleTracking,
    required this.subtitleSize,
    required this.subtitleWeight,
    required this.subtitleGap,
    this.subtitleMaxLines = 2,
    required this.goSize,
    this.iconSize = 44,
    this.iconBorderColor,
    required this.fallbackIcon,
    this.gradient,
    this.radialOverlay,
    this.solidColor,
    this.border,
    this.shadows = const [],
    this.insets = const [],
    this.iconAccent,
    this.iconBackground,
  });

  final bool isLight;
  final bool showGlaze;
  /// Soft linear ambient highlight (same language as metal glaze, not a blob).
  final bool showAmbientPolish;
  final Color titleColor;
  final Color subtitleColor;
  final Color goBackground;
  final Color goIconColor;
  /// `.lb-entry` is `14 16`; every other variant is `15 16`.
  final double padV;
  final double titleSize;

  /// `.t`'s `letter-spacing` in em. `leagueGold` is the outlier at -0.02em.
  final double titleTracking;

  final double subtitleSize;

  /// `.s`'s weight — `leagueGold` is 700 where the others are 600.
  final FontWeight subtitleWeight;

  /// `.s`'s `margin-top` in design px: 2 on `leagueGold`, 1 on the rest.
  final double subtitleGap;

  /// `supportLight`'s `.s` is `nowrap` + `ellipsis`, so it clamps to one line.
  /// Load-bearing under rule 8's 1.15 text-scale ceiling.
  final int subtitleMaxLines;

  final double goSize;

  /// `.ic`'s box size. 42 on `missionsPurple`, 44 on the `.dg-ref-banner` pair.
  final double iconSize;

  /// `.ic`'s border, where it has one. Only `referralPurple` does.
  final Color? iconBorderColor;


  final IconData fallbackIcon;
  final Gradient? gradient;

  /// Painted by a positioned child over the background, not by the card's own
  /// decoration (rule 17).
  final Gradient? radialOverlay;

  final Color? solidColor;
  final Border? border;
  final List<BoxShadow> shadows;

  /// Faked CSS `inset` layers. Empty for the two variants that have none.
  final List<_EntryInset> insets;

  final Color? iconAccent;

  /// Explicit `.ic` fill where the design specifies one, instead of deriving it
  /// from [iconAccent].
  final Color? iconBackground;
}

/// Paints one faked `inset` layer inside the card's clip.
///
/// The stop comes from the card's **actual** laid-out height, not a measured
/// constant. CSS `0 1px 1px inset` is 1px whatever the box turns out to be, and
/// these cards change height with the copy: the design's transfer banner
/// measures 112.2 only because its subtitle wraps to two lines, while its box
/// is the same 72 as the missions card. Deriving the stop from a fixed number
/// would size the highlight for a height the card does not have.
class _InsetLayer extends StatelessWidget {
  const _InsetLayer({required this.inset});

  final _EntryInset inset;

  @override
  Widget build(BuildContext context) {
    final fromBottom = inset.fromBottom;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : context.dp(80);
          final stop = (context.dp(inset.extentPx) / h).clamp(0.004, 0.5);
          return DecoratedBox(
            key: fromBottom ? kEntryInsetBottomKey : kEntryInsetTopKey,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:
                    fromBottom ? Alignment.bottomCenter : Alignment.topCenter,
                end: fromBottom ? Alignment.topCenter : Alignment.bottomCenter,
                colors: [inset.color, inset.color.withValues(alpha: 0)],
                stops: [0.0, stop],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Per-variant design values. **Assume nothing is shared** — the five shadows
/// are five different shadows, and two of the variants deliberately carry no
/// inset layer at all (rule 20).
_EntryStyle _styleFor(
  BuildContext context,
  DugnadFeedEntryVariant variant,
  AeThemePalette theme,
) {
  final browseNoClub = !DugnadState.instance.hasClub;
  switch (variant) {
    case DugnadFeedEntryVariant.leagueGold:
      // `.lb-entry`: 135deg #ffe9a8 0% → #f7cf6b 55% → #eebb44 100%.
      // The middle stop is #f7cf6b, one digit off the #f6cf6b used by the
      // metal family and the season tag. They are different surfaces.
      return _EntryStyle(
        isLight: true,
        showGlaze: true,
        showAmbientPolish: true,
        titleColor: const Color(0xFF3A2A08),
        subtitleColor: const Color(0xFF3A2A08).withValues(alpha: 0.78),
        goBackground: const Color(0xFF3A2A08).withValues(alpha: 0.12),
        goIconColor: const Color(0xFF3A2A08),
        padV: 14, // .lb-entry
        // The outlier on every type axis: larger title, tighter tracking,
        // heavier subtitle, wider gap.
        titleSize: 16,
        titleTracking: -0.02,
        subtitleSize: 12,
        subtitleWeight: FontWeight.w700,
        subtitleGap: 2,
        goSize: 34,
        fallbackIcon: Icons.emoji_events_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9A8), Color(0xFFF7CF6B), Color(0xFFEEBB44)],
          stops: [0.0, 0.55, 1.0],
        ),
        // 0 16px 30px -16px rgba(216,160,40,0.82). The gold tint is not a club
        // colour, so it stays a literal.
        shadows: [
          BoxShadow(
            color: const Color(0xFFD8A028).withValues(alpha: 0.82),
            offset: Offset(0, context.dp(16)),
            blurRadius: context.dp(30),
            spreadRadius: context.dp(-16),
          ),
        ],
        // The only variant with two insets, and the only bottom-anchored one.
        insets: [
          _EntryInset.top(Colors.white.withValues(alpha: 0.90)),
          _EntryInset.bottom(
            const Color(0xFFBE871E).withValues(alpha: 0.16),
            extentPx: 18,
          ),
        ],
      );
    case DugnadFeedEntryVariant.missionsPurple:
      if (browseNoClub) {
        return _EntryStyle(
          isLight: false,
          showGlaze: false,
          showAmbientPolish: false,
          titleColor: Colors.white,
          subtitleColor: Colors.white.withValues(alpha: 0.9),
          goBackground: Colors.white.withValues(alpha: 0.18),
          goIconColor: Colors.white,
          titleSize: 15.5,
          titleTracking: -0.01,
          subtitleSize: 12.5,
          subtitleWeight: FontWeight.w600,
          subtitleGap: 1,
          goSize: 30,
          iconSize: 42,
          fallbackIcon: Icons.bolt_rounded,
          gradient: AeThemePalette.reenBrowse.feedMissionsGradient,
          shadows: [
            BoxShadow(
              color: const Color(0xFF1B3554).withValues(alpha: 0.34),
              offset: Offset(0, context.dp(14)),
              blurRadius: context.dp(28),
              spreadRadius: context.dp(-14),
            ),
          ],
        );
      }
      // `.dg-missions-entry .me-bg`: 135deg 600 → 500. No gloss, sheen, or
      // overlay — the gold `::before` polish was what crushed the bottom
      // of this card into maroon.
      return _EntryStyle(
        isLight: false,
        showGlaze: false,
        showAmbientPolish: false,
        titleColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.9),
        goBackground: Colors.white.withValues(alpha: 0.18),
        goIconColor: Colors.white,
        titleSize: 15.5,
        titleTracking: -0.01,
        subtitleSize: 12.5,
        subtitleWeight: FontWeight.w600,
        subtitleGap: 1,
        goSize: 30,
        // `.dg-missions-entry .ic` is 42 with no border, unlike the 44 + border
        // that `.dg-ref-banner .ic` carries.
        iconSize: 42,
        fallbackIcon: Icons.bolt_rounded,
        gradient: theme.feedMissionsGradient,
        // 0 14px 28px -14px rgba(45,27,91,0.6) — `--ae-midnight`, which the
        // club theme derives, so it follows an override.
        shadows: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.6),
            offset: Offset(0, context.dp(14)),
            blurRadius: context.dp(28),
            spreadRadius: context.dp(-14),
          ),
        ],
        // No inset. Deliberate — do not normalise.
      );
    case DugnadFeedEntryVariant.transferDark:
      if (browseNoClub) {
        return _EntryStyle(
          isLight: false,
          showGlaze: false,
          showAmbientPolish: false,
          titleColor: Colors.white,
          subtitleColor: Colors.white.withValues(alpha: 0.9),
          goBackground: Colors.white.withValues(alpha: 0.18),
          goIconColor: Colors.white,
          titleSize: 15.5,
          titleTracking: -0.01,
          subtitleSize: 12.5,
          subtitleWeight: FontWeight.w600,
          subtitleGap: 1,
          goSize: 30,
          iconSize: 42,
          fallbackIcon: Icons.hourglass_bottom_rounded,
          gradient: AeThemePalette.reenBrowse.feedTransferGradient,
          shadows: [
            BoxShadow(
              color: const Color(0xFF1B3554).withValues(alpha: 0.42),
              offset: Offset(0, context.dp(16)),
              blurRadius: context.dp(30),
              spreadRadius: context.dp(-14),
            ),
          ],
        );
      }
      // Same family as missions, slightly deeper. No gold `::before` polish.
      return _EntryStyle(
        isLight: false,
        showGlaze: false,
        showAmbientPolish: false,
        titleColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.9),
        goBackground: Colors.white.withValues(alpha: 0.18),
        goIconColor: Colors.white,
        titleSize: 15.5,
        titleTracking: -0.01,
        subtitleSize: 12.5,
        subtitleWeight: FontWeight.w600,
        subtitleGap: 1,
        goSize: 30,
        // `.tb-hg` rather than `.ic`: 42, radius 13, white@.16 — a lower alpha
        // than missionsPurple's .2. DugnadTransferFeedBanner already supplies
        // this as a custom `leading`, so _IconBox is only the fallback.
        iconSize: 42,
        fallbackIcon: Icons.hourglass_bottom_rounded,
        gradient: theme.feedTransferGradient,
        // 0 16px 30px -14px rgba(45,27,91,0.6). Same tint as missionsPurple but
        // a different offset and spread — near-identical, not identical.
        shadows: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.6),
            offset: Offset(0, context.dp(16)),
            blurRadius: context.dp(30),
            spreadRadius: context.dp(-14),
          ),
        ],
        // No inset. Deliberate — do not normalise.
      );
    case DugnadFeedEntryVariant.supportLight:
      return _EntryStyle(
        isLight: true,
        showGlaze: false,
        titleColor: theme.text,
        subtitleColor: ScSaasThemeTokens.gray500,
        goBackground: const Color(0xFFEDEDF2),
        goIconColor: ScSaasThemeTokens.gray500,
        titleSize: 15.5,
        titleTracking: -0.01,
        subtitleSize: 11.5,
        subtitleWeight: FontWeight.w600,
        subtitleGap: 2,
        // `.s` is `white-space: nowrap; overflow: hidden; text-overflow:
        // ellipsis` — one line, not two.
        subtitleMaxLines: 1,
        goSize: 32,
        // Inherits `.dg-ref-banner .ic` at 44, but `border-color: transparent`.
        fallbackIcon: Icons.favorite_rounded,
        solidColor: Colors.white,
        border: Border.all(
          color: const Color(0xFFECECF0),
          width: 1.5,
        ),
        // Flat magenta on every club — this accent is deliberately unthemed,
        // so it must not be mixed with a club token.
        iconAccent: const Color(0xFFB4509C),
        // `.ic` is rgba(180,80,150,.12) — #B45096, which is *not* the same
        // magenta as the accent above. One digit apart, two different values.
        iconBackground: const Color(0xFFB45096).withValues(alpha: 0.12),
        // 0 14px 28px -18px rgba(45,27,91,0.45)
        shadows: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.45),
            offset: Offset(0, context.dp(14)),
            blurRadius: context.dp(28),
            spreadRadius: context.dp(-18),
          ),
        ],
        insets: [_EntryInset.top(Colors.white.withValues(alpha: 0.60))],
      );
    case DugnadFeedEntryVariant.referralPurple:
      if (browseNoClub) {
        return _EntryStyle(
          isLight: false,
          showGlaze: false,
          showAmbientPolish: false,
          titleColor: Colors.white,
          subtitleColor: Colors.white.withValues(alpha: 0.92),
          goBackground: Colors.white.withValues(alpha: 0.18),
          goIconColor: Colors.white,
          titleSize: 15.5,
          titleTracking: -0.01,
          subtitleSize: 11.5,
          subtitleWeight: FontWeight.w600,
          subtitleGap: 2,
          goSize: 32,
          iconBorderColor: Colors.white.withValues(alpha: 0.3),
          fallbackIcon: Icons.share_rounded,
          gradient: const LinearGradient(
            begin: Alignment(-0.5, -0.85),
            end: Alignment(0.5, 0.85),
            colors: [Color(0xFF8EA3BA), Color(0xFF748CA8), Color(0xFF5D7694)],
            stops: [0.0, 0.55, 1.0],
          ),
          radialOverlay: const RadialGradient(
            center: Alignment(0.76, -1.6),
            radius: 1.53,
            colors: [Color(0x47FFFFFF), Color(0x00FFFFFF)],
            stops: [0.0, 0.70],
          ),
          shadows: [
            BoxShadow(
              color: const Color(0xFF1B3554).withValues(alpha: 0.34),
              offset: Offset(0, context.dp(16)),
              blurRadius: context.dp(30),
              spreadRadius: context.dp(-16),
            ),
          ],
          insets: [_EntryInset.top(Colors.white.withValues(alpha: 0.35))],
        );
      }
      // Club shiny gradient (no magenta) — matte, no metal glaze. Consumes the
      // token wholesale, so a club override propagates rather than drifting.
      return _EntryStyle(
        isLight: false,
        showGlaze: false,
        showAmbientPolish: false,
        titleColor: Colors.white,
        subtitleColor: Colors.white.withValues(alpha: 0.92),
        goBackground: Colors.white.withValues(alpha: 0.18),
        goIconColor: Colors.white,
        titleSize: 15.5,
        titleTracking: -0.01,
        subtitleSize: 11.5,
        subtitleWeight: FontWeight.w600,
        subtitleGap: 2,
        goSize: 32,
        // The only variant whose `.ic` has a border. The alpha is still
        // unverified — `.dg-ref-banner .ic` sits past the 256 KiB cut.
        iconBorderColor: Colors.white.withValues(alpha: 0.3),
        fallbackIcon: Icons.share_rounded,
        gradient: theme.shinyGradient,
        // radial-gradient(150px 120px at 88% -30%, rgba(255,255,255,.28),
        //                 transparent 70%)
        // The centre is off-canvas above the top-right corner, which is what
        // throws the highlight in from the corner instead of centring a blob.
        // CSS gives an ellipse; Flutter's radius is a single fraction of the
        // short side, so it is approximated by the geometric mean of the two
        // CSS radii over the 87.8px card height — a ratio, hence unscaled.
        radialOverlay: const RadialGradient(
          center: Alignment(0.76, -1.6),
          radius: 1.53,
          colors: [Color(0x47FFFFFF), Color(0x00FFFFFF)],
          stops: [0.0, 0.70],
        ),
        // 0 16px 30px -16px rgba(127,95,196,0.7) — `--ae-purple-600`.
        shadows: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.7),
            offset: Offset(0, context.dp(16)),
            blurRadius: context.dp(30),
            spreadRadius: context.dp(-16),
          ),
        ],
        insets: [_EntryInset.top(Colors.white.withValues(alpha: 0.35))],
      );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.light,
    this.accent,
    this.background,
    this.size = 44,
    this.borderColor,
  });

  final IconData icon;
  final bool light;
  final Color? accent;

  /// Explicit `.ic` fill where the design specifies one.
  final Color? background;

  /// `.ic` box size in design px — per variant, not a house value.
  final double size;

  /// `.ic` border, where the variant has one.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? context.aeTheme.primary;
    return Container(
      width: context.dp(size),
      height: context.dp(size),
      decoration: BoxDecoration(
        color: background ??
            (light
                ? Color.alphaBlend(
                    accentColor.withValues(alpha: 0.14),
                    Colors.white,
                  )
                : Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(context.dp(13)),
        // Only referralPurple's `.ic` has a border; missionsPurple's has none.
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Icon(
        icon,
        size: context.dp(20),
        color: light ? accentColor : Colors.white,
      ),
    );
  }
}

/// Transfer window banner with animated hourglass icon.
class DugnadTransferFeedBanner extends StatelessWidget {
  const DugnadTransferFeedBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DugnadFeedEntryBanner(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      variant: DugnadFeedEntryVariant.transferDark,
      leading: Container(
        width: context.dp(42),
        height: context.dp(42),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(context.dp(13)),
        ),
        alignment: Alignment.center,
        child: AeHourglass(
          size: context.dp(20),
          color: Colors.white,
          fast: true,
        ),
      ),
    );
  }
}
