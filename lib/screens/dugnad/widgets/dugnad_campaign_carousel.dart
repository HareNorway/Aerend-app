import '../../../theme/design_scale.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import '../dugnad_models.dart';
import '../matkasse_campaign_screen.dart';
import 'campaign_countdown.dart';
import 'dugnad_metal_animations.dart';
import 'mk_price_tag.dart';

const _kCardWidthFraction = 0.72;
const _kCardGap = 14.0;
const _kAutoRotateMs = 5400;

double carouselCardWidth(double viewportWidth) =>
    viewportWidth * _kCardWidthFraction;

double carouselViewportFraction(double viewportWidth, double cardWidth) {
  return ((cardWidth + _kCardGap) / viewportWidth).clamp(0.55, 0.92);
}

/// Centered peek campaign carousel (prototype: `DgCampCarousel`).
class DugnadCampaignCarousel extends StatefulWidget {
  const DugnadCampaignCarousel({
    super.key,
    required this.campaigns,
    required this.clubLabel,
    required this.campaignPoints,
    this.onSeeAll,
  });

  final List<ClubCampaignSummary> campaigns;
  final String clubLabel;
  final int campaignPoints;
  final VoidCallback? onSeeAll;

  @override
  State<DugnadCampaignCarousel> createState() => _DugnadCampaignCarouselState();
}

class _DugnadCampaignCarouselState extends State<DugnadCampaignCarousel> {
  PageController? _pageController;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  int _index = 0;
  int _direction = 1;
  double? _lastViewportFraction;

  PageController _controllerFor(double viewportWidth, double cardWidth) {
    final fraction = carouselViewportFraction(viewportWidth, cardWidth);
    if (_pageController == null || _lastViewportFraction != fraction) {
      _pageController?.dispose();
      _pageController = PageController(
        viewportFraction: fraction,
        initialPage: _index,
      );
      _lastViewportFraction = fraction;
    }
    return _pageController!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoRotate());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _startAutoRotate() {
    _autoTimer?.cancel();
    if (widget.campaigns.length <= 1) return;
    if (MediaQuery.disableAnimationsOf(context)) return;

    _autoTimer = Timer.periodic(
      const Duration(milliseconds: _kAutoRotateMs),
      (_) => _stepAuto(),
    );
  }

  void _pauseAutoRotate() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 9000), _startAutoRotate);
  }

  void _stepAuto() {
    if (!mounted || widget.campaigns.length <= 1) return;
    var next = _index + _direction;
    if (next >= widget.campaigns.length) {
      _direction = -1;
      next = _index - 1;
    } else if (next < 0) {
      _direction = 1;
      next = _index + 1;
    }
    _goTo(next, fromUser: false);
  }

  void _goTo(int index, {required bool fromUser}) {
    final clamped = index.clamp(0, widget.campaigns.length - 1);
    if (fromUser) {
      _direction = clamped >= _index ? 1 : -1;
      _pauseAutoRotate();
    }
    if (clamped == _index) return;
    setState(() => _index = clamped);
    _pageController?.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 1100),
      curve: const Cubic(0.22, 0.61, 0.36, 1),
    );
  }

  void _openCampaign(ClubCampaignSummary campaign) {
    HapticFeedback.lightImpact();
    openScreen(
      context,
      MatkasseCampaignScreen(
        slug: campaign.slug,
        campaignName: campaign.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.campaigns.isEmpty) return const SizedBox.shrink();

    final theme = context.aeTheme;
    final atStart = _index == 0;
    final atEnd = _index == widget.campaigns.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                languages
                    .dugnadCampaignsFromClub(widget.clubLabel)
                    .toUpperCase(),
                style: aeOverline(color: ScSaasThemeTokens.gray500).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10.5 * 0.04,
                ).dp(context),
              ),
            ),
            if (widget.onSeeAll != null)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSeeAll!();
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.primary,
                  padding: EdgeInsets.symmetric(horizontal: context.dp(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  languages.dugnadSeeAll,
                  style: aeCaption(color: theme.primary).copyWith(
                    fontWeight: FontWeight.w800,
                  ).dp(context),
                ),
              ),
            if (widget.campaigns.length > 1) ...[
              _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                enabled: !atStart,
                onTap: () => _goTo(_index - 1, fromUser: true),
              ),
              SizedBox(width: context.dp(4)),
              _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                enabled: !atEnd,
                onTap: () => _goTo(_index + 1, fromUser: true),
              ),
            ],
          ],
        ),
        SizedBox(height: context.dp(12)),
        Builder(
          builder: (context) {
            final viewportWidth = MediaQuery.sizeOf(context).width;
            final cardWidth = carouselCardWidth(viewportWidth);
            final pageController = _controllerFor(viewportWidth, cardWidth);

            return SizedBox(
              height: cardWidth,
              child: OverflowBox(
                maxWidth: viewportWidth,
                minWidth: viewportWidth,
                alignment: Alignment.center,
                child: SizedBox(
                  width: viewportWidth,
                  height: cardWidth,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: widget.campaigns.length,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      _pauseAutoRotate();
                    },
                    itemBuilder: (context, i) {
                      final active = i == _index;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _kCardGap / context.dp(2),
                        ),
                        child: AnimatedScale(
                          scale: active ? 1 : 0.935,
                          duration: const Duration(milliseconds: 1100),
                          curve: const Cubic(0.22, 0.61, 0.36, 1),
                          child: AnimatedOpacity(
                            opacity: active ? 1 : 0.58,
                            duration: const Duration(milliseconds: 1100),
                            child: Center(
                              child: SizedBox(
                                width: cardWidth,
                                height: cardWidth,
                                child: DugnadCampMiniCard(
                                  campaign: widget.campaigns[i],
                                  campaignPoints: widget.campaignPoints,
                                  onTap: () =>
                                      _openCampaign(widget.campaigns[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.campaigns.length > 1) ...[
          SizedBox(height: context.dp(14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.campaigns.length, (i) {
              final active = i == _index;
              return GestureDetector(
                onTap: () => _goTo(i, fromUser: true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: const Cubic(0.22, 0.61, 0.36, 1),
                  margin: EdgeInsets.symmetric(horizontal: context.dp(3.5)),
                  width: active ? 20 : 6,
                  height: context.dp(6),
                  decoration: BoxDecoration(
                    color: active ? theme.primary : ScSaasThemeTokens.gray300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: context.dp(30),
          height: context.dp(30),
          child: Icon(
            icon,
            size: context.dp(16),
            color: enabled
                ? context.aeTheme.primary
                : ScSaasThemeTokens.gray300,
          ),
        ),
      ),
    );
  }
}

/// Compact campaign card for the home carousel (prototype: `DgCampMiniCard`).
class DugnadCampMiniCard extends StatefulWidget {
  const DugnadCampMiniCard({
    super.key,
    required this.campaign,
    required this.campaignPoints,
    required this.onTap,
  });

  final ClubCampaignSummary campaign;
  final int campaignPoints;
  final VoidCallback onTap;

  @override
  State<DugnadCampMiniCard> createState() => _DugnadCampMiniCardState();
}

class _DugnadCampMiniCardState extends State<DugnadCampMiniCard>
    with SingleTickerProviderStateMixin {
  // Assigned eagerly in initState, never by a lazy `late final x = expr`.
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    // `.mk-camp2:active .mk-camp2-shine { animation: dg-offer-shine 1s ease }`.
    // The carousel card has no shine rule of its own, so it takes .mk-camp2's
    // own period rather than one propagated from another element.
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  /// One-shot on tap, not a repeating loop and not hover: the design added
  /// `:active` triggers precisely because `:hover` never fires on touch, so a
  /// hover-wired port ships an animation no user will ever see.
  void _triggerShine() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shine.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final campaignPoints = widget.campaignPoints;
    final onTap = widget.onTap;
    final theme = context.aeTheme;
    final teamName = campaign.teamName?.trim() ?? '';
    final note = campaign.landingIntroText?.trim() ?? '';
    final goalPct = campaign.goalPercent ?? 0;
    final minPrice = campaign.minPrice.round();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.dp(22)),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.dp(22)),
        onTapDown: (_) => _triggerShine(),
        child: Stack(
          children: [
            Container(
          // Same `.mk-camp2` shell as MkCampaignCard. No design class carries
          // a 20-radius single-shadow campaign card: `.mk-camp-card` is the
          // compact 50px-thumbnail row, and `.mk-pcar` is a product image
          // gallery. The two widgets had simply drifted (rule 20b).
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.dp(22)),
            border: Border.all(color: ScSaasThemeTokens.gray100),
            boxShadow: [
              // 0 2px 4px rgba(45,27,91,.05)
              BoxShadow(
                color: theme.text.withValues(alpha: 0.05),
                blurRadius: context.dp(4),
                offset: Offset(0, context.dp(2)),
              ),
              // 0 20px 40px -20px rgba(45,27,91,.36)
              BoxShadow(
                color: theme.text.withValues(alpha: 0.36),
                blurRadius: context.dp(40),
                offset: Offset(0, context.dp(20)),
                spreadRadius: context.dp(-20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 58,
                child: _MiniBanner(
                  campaign: campaign,
                  teamName: teamName,
                ),
              ),
              Expanded(
                flex: 42,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.dp(12), context.dp(8), context.dp(12), context.dp(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            campaign.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aeBody(color: theme.text).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.12,
                              letterSpacing: 15 * -0.015,
                            ).dp(context),
                          ),
                          if (note.isNotEmpty || campaignPoints > 0) ...[
                            SizedBox(height: context.dp(5)),
                            Row(
                              children: [
                                if (note.isNotEmpty) ...[
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: context.dp(12),
                                    color: ScSaasThemeTokens.gray500,
                                  ),
                                  SizedBox(width: context.dp(5)),
                                  Expanded(
                                    child: Text(
                                      note,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: aeCaption().copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                      ).dp(context),
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                if (campaignPoints > 0)
                                  _PointsPill(points: campaignPoints),
                              ],
                            ),
                          ],
                        ],
                      ),
                      // Same animated `.mk-pricetag` the Kampanje tab card
                      // wears -- the plain "fra N kr" line read as an
                      // afterthought next to it.
                      Row(
                        children: [
                          if (minPrice > 0) ...[
                            MkPriceTag(
                              amount: minPrice,
                              gradient: MkPriceTag.gradientFor(context),
                            ),
                            if (goalPct > 0) SizedBox(width: context.dp(8)),
                          ],
                          // Expanded, not Spacer + Text: a Spacer would take
                          // an equal flex share and clip the goal label early.
                          if (goalPct > 0)
                            Expanded(
                              child: Text(
                                languages.dugnadTeamDetailGoalPercent(goalPct),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: aeCaption(color: theme.primary).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ).dp(context),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            // dg-offer-shine: -160% -> 240% with a persistent skewX(-16deg),
            // opacity 1 -> 0 across the single pass. Clipped by the Material.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, _) {
                    if (_shine.value == 0 || _shine.value == 1) {
                      return const SizedBox.shrink();
                    }
                    final t = Curves.ease.transform(_shine.value);
                    return LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth * 0.55;
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
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.dp(7), context.dp(3), context.dp(9), context.dp(3)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7DC82), Color(0xFFE9B844)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD6A228).withValues(alpha: 0.45),
            blurRadius: context.dp(6),
            offset: Offset(context.dp(0), context.dp(2)),
            spreadRadius: context.dp(-3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: context.dp(11),
            color: Color(0xFF7A5E1C),
          ),
          SizedBox(width: context.dp(4)),
          Text(
            '+$points ${languages.dugnadPointsUnit}',
            style: aeCaption(color: const Color(0xFF7A5E1C)).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ).dp(context),
          ),
        ],
      ),
    );
  }
}

class _MiniBanner extends StatelessWidget {
  const _MiniBanner({
    required this.campaign,
    required this.teamName,
  });

  final ClubCampaignSummary campaign;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final heroUrl = campaign.heroImageUrl?.trim();
    final salesEnd = campaign.salesWindowEnd;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(context.dp(22))),
      child: Stack(
        fit: StackFit.expand,
        children: [
            if (heroUrl != null && heroUrl.isNotEmpty)
              Image.network(
                heroUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _bannerGradient(theme),
              )
            else
              _bannerGradient(theme),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // `.mk-camp2-grad`: linear-gradient(to top, rgba(20,12,40,.5) 0%,
                  // rgba(20,12,40,0) 55%). `to top` puts the tint at the
                  // *bottom*, and it clears at 55% -- the top 45% is untouched.
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF140C28).withValues(alpha: 0.5),
                    const Color(0xFF140C28).withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
            // Same speed as feed cards; different start phase so they don't sync.
            const DugnadMetalGlazeOverlay(
              borderRadius: 0,
              phase: 0.0,
            ),
            if (salesEnd != null && salesEnd.isNotEmpty)
              Positioned(
                // Inline-styled at top 12 in the JSX; `.mk-camp2-urg`'s 14 is
                // dead CSS, mounted nowhere.
                top: 12,
                right: 12,
                child: CampaignCountdownChip(salesWindowEnd: salesEnd),
              ),
            if (teamName.isNotEmpty)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dp(11),
                    vertical: context.dp(5),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140C28).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: context.dp(12),
                        color: Colors.white,
                      ),
                      SizedBox(width: context.dp(5)),
                      Text(
                        teamName,
                        style: aeCaption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 13 * 0.01,
                        ).dp(context),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _bannerGradient(AeThemePalette theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.primaryHover, Colors.black, 0.35)!,
            theme.primary,
          ],
        ),
      ),
    );
  }
}
