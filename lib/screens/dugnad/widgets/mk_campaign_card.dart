import 'dart:math' as math;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_club_crest.dart';
import '../dugnad_club_branding.dart';
import '../dugnad_state.dart';
import 'ae_sheen.dart';
import 'campaign_countdown.dart';
import 'lucide_box_icon.dart';
import 'mk_price_tag.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_models.dart';

// Aliases the token rather than repeating its hex. A shared constant is
// verified once or not at all: when every site holds the same wrong value
// they stay consistent with each other and diverge only from the source.
const _kSuccessGreen = ScSaasThemeTokens.success;
const _kSuccessGreenLight = Color(0xFF2BBD7A);
const _kBannerDark = Color(0xFF140C28);

/// Rich matkasse campaign card — mirrors prototype `.mk-camp2` + animations.
class MkCampaignCard extends StatefulWidget {
  const MkCampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  final ClubCampaignSummary campaign;
  final VoidCallback onTap;

  @override
  State<MkCampaignCard> createState() => _MkCampaignCardState();
}

class _MkCampaignCardState extends State<MkCampaignCard>
    with TickerProviderStateMixin {
  late final AnimationController _shineController;

  /// `.mk-camp2-foot .cta svg` translates 3px on hover *and* active. Hover is
  /// dead on touch, and the design's own comment says the `:active` rules
  /// exist for exactly that reason, so this rides the tap.
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Raw 0→1 over 1s — `Curves.ease` is applied at paint time to match
    // `dg-offer-shine 1s ease` (same as DugnadCampMiniCard).
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _triggerShine() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shineController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final browseNoClub = !DugnadState.instance.hasClub;
    const browseSlate = Color(0xFF6F87A4);
    const browseSlateDark = Color(0xFF284565);
    final campaign = widget.campaign;
    final clubName = (campaign.clubName?.trim().isNotEmpty ?? false)
        ? campaign.clubName!.trim()
        : DugnadClubBranding.fullName();
    final teamName = campaign.teamName?.trim() ?? '';
    final title = campaign.displayTitle;
    final note = campaign.landingIntroText?.trim() ?? '';
    // `campState(c)`: expired when the deadline has passed, `last` under 24h,
    // otherwise active. Driven by the campaign's own field, not a flag.
    final deadline = DateTime.tryParse(campaign.salesWindowEnd ?? '');
    final expired = deadline != null && deadline.isBefore(DateTime.now());

    final showProgress = (campaign.fundraisingGoalNok ?? 0) > 0;
    final goalPct = math.min(100, campaign.goalPercent ?? 0);
    final raisedLabel = formatNok(campaign.totalRevenueNok).split(' ').first;

    return GestureDetector(
      onTapDown: (_) {
        _triggerShine();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Opacity(
        // `.is-expired { opacity: .96 }`
        opacity: expired ? 0.96 : 1,
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(22)),
          boxShadow: [
            BoxShadow(
              color: theme.text.withValues(alpha: 0.05),
              blurRadius: context.dp(4),
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: theme.text.withValues(alpha: 0.36),
              blurRadius: context.dp(40),
              offset: const Offset(0, 20),
              spreadRadius: context.dp(-20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MkCampBanner(
              expired: expired,
              campaign: campaign,
              supportLabel: languages.dugnadSupportClub(
                DugnadClubBranding.compactName(),
              ),
              teamName: teamName,
              shineProgress: _shineController,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(14), context.dp(16), context.dp(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clubName.toUpperCase(),
                    // `.mk-camp2-body .club` is 11px / 800 / +0.03em. The
                    // tracking was derived from 10.5, so it was short by the
                    // size difference as well as inheriting aeOverline's size.
                    style: TextStyle(
                      fontSize: context.dp(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(11) * 0.03,
                      color: browseNoClub ? browseSlate : theme.primary,
                    ),
                  ),
                  SizedBox(height: context.dp(4)),
                  Text(
                    title,
                    // `.ttl` is 19 / 800 / -0.02em / line-height 1.12.
                    // Prefer club primary-ink over heavily black-mixed midnight.
                    style: TextStyle(
                      fontSize: context.dp(19),
                      fontWeight: FontWeight.w800,
                      letterSpacing: context.dp(19) * -0.02,
                      height: 1.12,
                      color: browseNoClub
                          ? browseSlateDark
                          : Color.lerp(theme.text, theme.primary, 0.18)!,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.isNotEmpty) ...[
                    SizedBox(height: context.dp(6)),
                    Row(
                      children: [
                        // Lucide `box` — `.mk-camp2-body .note` uses Icon name="box".
                        LucideBoxIcon(
                          size: context.dp(12),
                          color: ScSaasThemeTokens.gray500,
                        ),
                        SizedBox(width: context.dp(6)),
                        Expanded(
                          child: Text(
                            note,
                            style: aeCaption(
                              color: ScSaasThemeTokens.gray500,
                            ).copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (showProgress) ...[
                    SizedBox(height: context.dp(13)),
                    _MkCampProgressBar(
                      percent: goalPct,
                      raisedLabel: languages.dugnadCampaignRaised(raisedLabel),
                      goalLabel: languages.dugnadTeamDetailGoalPercent(goalPct),
                    ),
                  ],
                  SizedBox(height: context.dp(14)),
                  Container(
                    padding: EdgeInsets.only(top: context.dp(13)),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: ScSaasThemeTokens.gray100),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (campaign.minPrice > 0)
                          MkPriceTag(
                            amount: campaign.minPrice.round(),
                            gradient: MkPriceTag.gradientFor(context),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: browseNoClub
                                ? const LinearGradient(
                                    begin: Alignment(-0.5, -0.85),
                                    end: Alignment(0.5, 0.85),
                                    colors: [
                                      Color(0xFFF08D80),
                                      Color(0xFFE86657),
                                      Color(0xFFC94F41),
                                    ],
                                    stops: [0.0, 0.55, 1.0],
                                  )
                                : theme.shinyGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: theme.shadowButton,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                languages.dugnadCampaignSeeBoxes,
                                style: aeLabel(
                                  // `.is-expired .mk-camp2-foot .cta`
                                  color: expired
                                      ? ScSaasThemeTokens.gray400
                                      : Colors.white,
                                ).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 13 * -0.01,
                                ),
                              ),
                              SizedBox(width: context.dp(6)),
                              AnimatedSlide(
                                offset: Offset(_pressed ? 3 / 15 : 0, 0),
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOut,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: expired
                                      ? ScSaasThemeTokens.gray400
                                      : Colors.white,
                                  size: context.dp(15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// `.dg-expired-veil` — takes the countdown chip's place once a campaign's
/// deadline has passed.
///
/// `backdrop-filter: saturate(.6) blur(1px)` needs a real BackdropFilter: a
/// flat scrim would darken the image but leave it as saturated and as sharp
/// as before, which is the part you only notice with the two side by side.
class _ExpiredVeil extends StatelessWidget {
  const _ExpiredVeil();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: ColorFiltered(
          // saturate(.6) as a colour matrix.
          colorFilter: const ColorFilter.matrix(<double>[
            0.7126, 0.2848, 0.0426, 0, 0,
            0.1426, 0.8548, 0.0426, 0, 0,
            0.1426, 0.2848, 0.6526, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Container(
            // rgba(45,27,91,.55)
            color: const Color(0xFF2D1B5B).withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.dp(14),
                vertical: context.dp(7),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.dp(999)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: context.dp(14),
                    // strokeWidth 2.6 has no Flutter equivalent on an icon
                    // font; the rounded glyph is the closest weight.
                    color: ScSaasThemeTokens.text,
                  ),
                  SizedBox(width: context.dp(5)),
                  Text(
                    languages.campaignCountdownClosed,
                    style: TextStyle(
                      fontSize: context.dp(14),
                      fontWeight: FontWeight.w900,
                      color: ScSaasThemeTokens.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MkCampBanner extends StatelessWidget {
  const _MkCampBanner({
    required this.campaign,
    required this.supportLabel,
    required this.teamName,
    required this.shineProgress,
    required this.expired,
  });

  final ClubCampaignSummary campaign;
  final String supportLabel;
  final String teamName;
  final Animation<double> shineProgress;

  /// Derived from the campaign's deadline, not a flag — see `campState`.
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final heroUrl = campaign.heroImageUrl?.trim();

    return SizedBox(
      height: context.dp(132),
      width: double.infinity,
      // `.mk-camp2-banner { overflow: hidden }`
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          if (heroUrl != null && heroUrl.isNotEmpty)
            Image.network(
              heroUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _bannerFallback(theme),
            )
          else
            _bannerFallback(theme),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _kBannerDark.withValues(alpha: 0.5),
                  _kBannerDark.withValues(alpha: 0),
                ],
                stops: const [0, 0.55],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _MkCampClubPill(
              label: supportLabel,
              logoUrl: campaign.teamLogoUrl ?? campaign.logoUrl,
              clubName: campaign.clubName ?? DugnadClubBranding.fullName(),
            ),
          ),
          if (!expired &&
              campaign.salesWindowEnd != null &&
              campaign.salesWindowEnd!.isNotEmpty)
            Positioned(
              right: 12,
              // Inline-styled at top 12 / right 12 in the JSX. `.mk-camp2-urg`
              // is top 14 but is mounted nowhere -- dead CSS, like
              // `.mk-camp-card`. This chip is a different element.
              top: 12,
              child: CampaignCountdownChip(
                salesWindowEnd: campaign.salesWindowEnd!,
              ),
            ),
          // `.dg-expired-veil` takes the countdown's place once the deadline
          // has passed. BackdropFilter's first use in this tree.
          if (expired) const Positioned.fill(child: _ExpiredVeil()),
          if (teamName.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 12,
              child: _MkCampTeamPill(teamName: teamName),
            ),
          // Ambient blade — `.dg-campcta-shine` / `lb-sheen` loop so the cover
          // shimmer is visible while browsing (hover never fires on touch).
          const Positioned.fill(
            child: AeSheen(
              period: Duration(milliseconds: 7600),
              delay: Duration(milliseconds: 400),
              bandWidthFactor: 0.55,
              // rgba(255,255,255,.5) on `.dg-campcta-shine`
              highlight: Color(0x80FFFFFF),
            ),
          ),
          // Tap one-shot — `.mk-camp2:active .mk-camp2-shine` / `dg-offer-shine`.
          // Positioned.fill must wrap AnimatedBuilder (not the reverse) so the
          // band lays out against the banner, same as DugnadCampMiniCard.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: shineProgress,
                builder: (context, child) {
                  final raw = shineProgress.value;
                  if (raw <= 0 || raw >= 1) return const SizedBox.shrink();
                  final t = Curves.ease.transform(raw);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Band is 55% of the *banner*, travel -160% → 240% of
                      // that band (not screen pixels — the old Offset(-160…)
                      // made the blade almost invisible).
                      final w = constraints.maxWidth * 0.55;
                      return Stack(
                        children: [
                          Positioned(
                            left: (-1.6 + t * 4.0) * w,
                            top: 0,
                            bottom: 0,
                            width: w,
                            child: Opacity(
                              opacity: 1 - t,
                              child: Transform(
                                transform: Matrix4.skewX(-0.2867),
                                alignment: Alignment.center,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
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
        ],
      ),
    );
  }

  Widget _bannerFallback(AeThemePalette theme) {
    final browseNoClub = !DugnadState.instance.hasClub;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            browseNoClub ? const Color(0xFF8EA3BA) : theme.primaryHover,
            browseNoClub ? const Color(0xFF6F87A4) : theme.primary,
          ],
        ),
      ),
    );
  }
}

class _MkCampClubPill extends StatelessWidget {
  const _MkCampClubPill({
    required this.label,
    required this.logoUrl,
    required this.clubName,
  });

  final String label;
  final String? logoUrl;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(5), context.dp(5), context.dp(12), context.dp(5)),
      decoration: BoxDecoration(
        color: _kBannerDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AeClubCrest(
            name: clubName,
            logoUrl: logoUrl,
            size: context.dp(30),
            backgroundColor: Colors.white.withValues(alpha: 0.15),
          ),
          SizedBox(width: context.dp(8)),
          Text(
            label,
            style: aeOverline(color: Colors.white).copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 11.5 * -0.01,
            ),
          ),
        ],
      ),
    );
  }
}

class _MkCampTeamPill extends StatelessWidget {
  const _MkCampTeamPill({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final browseNoClub = !DugnadState.instance.hasClub;
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(10), context.dp(6), context.dp(13), context.dp(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: context.dp(16),
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: context.dp(13),
            color: browseNoClub ? const Color(0xFF6F87A4) : theme.primary,
          ),
          SizedBox(width: context.dp(6)),
          Text(
            teamName,
            style: aeLabel(
              color: browseNoClub ? const Color(0xFF284565) : theme.text,
            ).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 13 * -0.01,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundraising progress bar with sheen — mirrors `.mk-camp2-prog`.
class _MkCampProgressBar extends StatefulWidget {
  const _MkCampProgressBar({
    required this.percent,
    required this.raisedLabel,
    required this.goalLabel,
  });

  final int percent;
  final String raisedLabel;
  final String goalLabel;

  @override
  State<_MkCampProgressBar> createState() => _MkCampProgressBarState();
}

class _MkCampProgressBarState extends State<_MkCampProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  /// Started in initState and merely hidden in build, this kept
  /// running under reduced motion with a frame permanently scheduled.
  /// Gating in build is not gating (rule 16).
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_sheen.isAnimating) _sheen.stop();
      _sheen.value = 0;
      _motionStarted = false;
      return;
    }
    if (_motionStarted) return;
    _motionStarted = true;
    _sheen.repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fill = (widget.percent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `.mk-camp2-prog .bar` — track clips to pill; fill clips sheen.
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: context.dp(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: ScSaasThemeTokens.gray100),
                if (fill > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    // Sheen must not paint into the gray track — clip to fill.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_kSuccessGreen, _kSuccessGreenLight],
                              ),
                            ),
                          ),
                          // `.bar > span::after` — soft white dg-sheen, fill only.
                          // Narrow band (not a full-bleed wash) so the green
                          // stays bright — a wide translucent overlay read as muddy/dark.
                          if (!reduceMotion)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _sheen,
                                builder: (context, _) {
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final w = constraints.maxWidth;
                                      final band = w * 0.55;
                                      // @keyframes dg-sheen:
                                      // 0% → -130%; 55%,100% → 130%
                                      final t = _sheen.value;
                                      final sweep = t < 0.55 ? t / 0.55 : 1.0;
                                      final eased =
                                          Curves.easeInOut.transform(sweep);
                                      final dx = (-1.3 + eased * 2.6) * w;
                                      return Stack(
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          Positioned(
                                            left: dx,
                                            top: 0,
                                            bottom: 0,
                                            width: band,
                                            child: const DecoratedBox(
                                              decoration: BoxDecoration(
                                                // linear-gradient(110deg, …)
                                                gradient: LinearGradient(
                                                  begin: Alignment(-0.85, -0.4),
                                                  end: Alignment(0.85, 0.4),
                                                  colors: [
                                                    Color(0x00FFFFFF),
                                                    Color(0x8CFFFFFF),
                                                    Color(0x00FFFFFF),
                                                  ],
                                                  stops: [0.3, 0.5, 0.7],
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
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.dp(7)),
        Row(
          children: [
            Icon(Icons.favorite_rounded, size: context.dp(11), color: _kSuccessGreen),
            SizedBox(width: context.dp(5)),
            Expanded(
              child: Text(
                widget.raisedLabel,
                style: aeCaption(color: _kSuccessGreen).copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              widget.goalLabel,
              style: aeCaption(color: ScSaasThemeTokens.gray500).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
