import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/ae_typography.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../club_crest.dart';
import 'dugnad_choose_club_widgets.dart';
import '../dugnad_club_theme.dart';
import 'dugnad_rounded_feed_sheet.dart';

/// Locks typography to design-system px (375px frame) — ignores OS text scaling.
class DugnadFixedTypography extends StatelessWidget {
  const DugnadFixedTypography({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: child,
    );
  }
}

/// Shared purple hero + overlapping feed shell for dugnad sub-pages
/// (referral, donation setup — prototype: `.lb-hero`, `.dn-feed`).
///
/// Unified back control — design:
/// ```css
/// .ae-back, .lb-back, .dg-onb-back {
///   background: var(--ae-shiny) !important;
///   box-shadow: var(--ae-shiny-shadow) !important;
///   color: var(--ae-midnight) !important;
/// }
/// .tk-head .ae-back {
///   background: color-mix(in srgb, var(--ae-purple-600) 13%, #fff);
/// }
/// ```
/// Club accent remaps `--ae-purple-600`, so the shiny fill is club-tinted
/// (not the hardcoded purple [AeSurface.shiny]).
class DugnadLbBackButton extends StatefulWidget {
  const DugnadLbBackButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.forceDarkSurface = false,
    this.solidWhite = false,
  });

  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final bool forceDarkSurface;
  final bool solidWhite;

  @override
  State<DugnadLbBackButton> createState() => _DugnadLbBackButtonState();
}

class _DugnadLbBackButtonState extends State<DugnadLbBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final size = context.dp(38);
    final isDarkSurface =
        widget.forceDarkSurface || theme.background.computeLuminance() < 0.45;
    const whiteButtonInk = Color(0xFF16304F);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: widget.solidWhite
                ? const LinearGradient(
                    begin: Alignment(-0.6, -0.8),
                    end: Alignment(0.6, 0.8),
                    colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FA)],
                  )
                : isDarkSurface
                ? const LinearGradient(
                    begin: Alignment(-0.6, -0.8),
                    end: Alignment(0.6, 0.8),
                    colors: [Color(0x29FFFFFF), Color(0x17FFFFFF)],
                  )
                : LinearGradient(
                    begin: const Alignment(-0.6, -0.8),
                    end: const Alignment(0.6, 0.8),
                    colors: [
                      Colors.white,
                      theme.primaryTint,
                      Color.alphaBlend(
                        theme.primary.withValues(alpha: 0.13),
                        Colors.white,
                      ),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
            shape: BoxShape.circle,
            border: widget.solidWhite
                ? Border.all(color: const Color(0x14081626))
                : isDarkSurface
                ? Border.all(color: const Color(0x38FFFFFF))
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.solidWhite
                    ? const Color(0x1A081626)
                    : isDarkSurface
                    ? const Color(0x80000000)
                    : theme.text.withValues(alpha: 0.42),
                blurRadius: context.dp(widget.solidWhite ? 8 : 20),
                offset: Offset(0, context.dp(widget.solidWhite ? 3 : 10)),
                spreadRadius: context.dp(widget.solidWhite ? -2 : -6),
              ),
            ],
          ),
          child: Center(
            child: widget.iconWidget ??
                Icon(
                  widget.icon ?? Icons.arrow_back_ios_new_rounded,
                  size: context.dp(18),
                  color: widget.solidWhite
                      ? whiteButtonInk
                      : isDarkSurface
                      ? Colors.white
                      : theme.text,
                ),
          ),
        ),
      ),
    );
  }
}

/// Compact purple header — back + centred title only (prototype: player-card screen).
class DugnadLbSimpleHero extends StatelessWidget {
  const DugnadLbSimpleHero({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: context.dugnadTheme.heroGradient,
      ),
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        MediaQuery.paddingOf(context).top + context.dp(6),
        context.dp(22),
        context.dp(20),
      ),
      child: Row(
        children: [
          DugnadLbBackButton(onPressed: onBack),
          Expanded(
            child: Text(
              title,
              style: AeDugnadText.pageHeroOrg(color: Colors.white).dp(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.dp(38)),
        ],
      ),
    );
  }
}

class DugnadLbHero extends StatelessWidget {
  const DugnadLbHero({
    super.key,
    required this.clubName,
    required this.title,
    this.clubLogo,
    this.subtitle,
    this.subtitleWithHeart = false,
    this.subtitleWithClock = false,
    this.useReenLogo = false,
    this.trailing,
    this.titleTrailing,
    required this.onBack,
  });

  final String clubName;
  final String? clubLogo;
  final String title;
  final String? subtitle;
  final bool subtitleWithHeart;
  final bool subtitleWithClock;
  /// When true, show REEN wordmark instead of club crest + name.
  final bool useReenLogo;
  /// Top-row action (balances the back button), e.g. share.
  final Widget? trailing;
  /// Inline action on the title row (e.g. Min støtte).
  final Widget? titleTrailing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final heroColor =
        useReenLogo ? ReenPreClubTokens.navy : context.dugnadTheme.primary;
    // CSS `.lb-hero { background: var(--ae-purple-600) }` — solid primary so
    // feed-sheet corner cut-outs match the hero (no gradient seam at the curve).
    return Container(
      width: double.infinity,
      color: heroColor,
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        MediaQuery.paddingOf(context).top +
            context.dp(useReenLogo ? 2 : 6),
        context.dp(22),
        context.dp(useReenLogo ? 16 : 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DugnadLbBackButton(
                onPressed: onBack,
                forceDarkSurface: useReenLogo,
                solidWhite: useReenLogo,
              ),
              Expanded(
                child: useReenLogo
                    ? const Center(child: DugnadReenLogo(height: 26))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClubCrest(
                            name: clubName,
                            logoUrl:
                                clubLogo?.isEmpty ?? true ? null : clubLogo,
                            size: context.dp(34),
                          ),
                          SizedBox(width: context.dp(10)),
                          Flexible(
                            child: Text(
                              clubName,
                              style: AeDugnadText.pageHeroOrg(color: Colors.white)
                                  .dp(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              trailing ?? SizedBox(width: context.dp(38)),
            ],
          ),
          SizedBox(height: context.dp(useReenLogo ? 12 : 16)),
          Padding(
            padding: EdgeInsets.only(left: context.dp(2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AeDugnadText.pageHeroTitle(color: Colors.white).dp(context),
                  ),
                ),
                if (titleTrailing != null) ...[
                  SizedBox(width: context.dp(10)),
                  titleTrailing!,
                ],
              ],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: context.dp(7)),
            Row(
              children: [
                if (subtitleWithHeart) ...[
                  Icon(
                    Icons.favorite_rounded,
                    size: context.dp(13),
                    // `.lb-hero-sub { opacity: .9 }` applies to the whole
                    // inline-flex, so the icon and the text share it. The icon
                    // was 2% brighter than the label beside it.
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: context.dp(6)),
                ] else if (subtitleWithClock) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: context.dp(13),
                    // `.lb-hero-sub { opacity: .9 }` applies to the whole
                    // inline-flex, so the icon and the text share it. The icon
                    // was 2% brighter than the label beside it.
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  SizedBox(width: context.dp(6)),
                ],
                Expanded(
                  child: Text(
                    subtitle!,
                    style: AeDugnadText.pageHeroSub(
                      color: Colors.white.withValues(alpha: 0.9),
                    ).dp(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Lavender feed content (padding + spaced children).
class DugnadSubpageFeed extends StatelessWidget {
  const DugnadSubpageFeed({
    super.key,
    required this.children,
    this.bottomPadding = 40,
    this.itemGap,
    this.topPadding,
    this.minHeight,
  });

  final List<Widget> children;
  final double bottomPadding;
  final double? itemGap;
  final double? topPadding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final padTop = topPadding ?? AeDugnadSpace.subFeedPadTop;
    final horizontal = AeDugnadSpace.subFeedPadH;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withGap(children, itemGap ?? AeDugnadSpace.subFeedGap),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          padTop,
          horizontal,
          bottomPadding,
        ),
        child: content,
      ),
    );
  }

  List<Widget> _withGap(List<Widget> items, double gap) {
    if (items.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }
}

/// Rounded lavender sheet (`.lb-feed` background + top radius).
///
/// Delegates to [DugnadRoundedFeedSheet] (`ClipRRect` + lavender fill).
class DugnadSubpageFeedShell extends StatelessWidget {
  const DugnadSubpageFeedShell({
    super.key,
    required this.child,
    this.feedRadius = DugnadRoundedFeedSheet.subpageRadius,
  });

  final Widget child;
  /// Design-px radius (`.lb-feed { border-radius: 22px 22px 0 0 }`).
  final double feedRadius;

  @override
  Widget build(BuildContext context) {
    return DugnadRoundedFeedSheet(
      radius: feedRadius,
      child: child,
    );
  }
}

/// Pulls the feed sheet up over the purple hero (`.lb-feed { margin-top: -12px }`).
/// Prefer [DugnadLbPageBody] for fixed-hero pages; use this only inside
/// [CustomScrollView] slivers where negative layout overlap is handled by the scroll stack.
class DugnadSubpageFeedOverlap extends StatelessWidget {
  const DugnadSubpageFeedOverlap({
    super.key,
    required this.child,
    this.overlap,
  });

  final Widget child;
  final double? overlap;

  @override
  Widget build(BuildContext context) {
    final amount = overlap ?? AeDugnadSpace.subFeedOverlap;
    return Transform.translate(
      offset: Offset(0, -amount),
      child: child,
    );
  }
}

/// Hero + overlapping scroll feed (points, team picker — prototype: `.lb-hero` + `.lb-feed`).
///
/// Default layout: fixed hero, feed sheet overlapped via negative top inset
/// (CSS `margin-top: -12px`). Top overscroll is clamped so the rounded sheet
/// cannot separate from the hero.
///
/// Set [scrollEntirePage] to scroll hero + feed together, same as home
/// ([CustomScrollView] with both in one sliver so the feed curve is not clipped).
class DugnadLbPageBody extends StatelessWidget {
  const DugnadLbPageBody({
    super.key,
    required this.hero,
    required this.children,
    this.bottomPadding = 40,
    this.itemGap,
    this.topPadding,
    this.feedRadius = 22,
    this.overlap,
    this.scrollController,
    this.scrollEntirePage = true,
    this.heroColor,
  });

  final Widget hero;
  final List<Widget> children;
  final double bottomPadding;
  final double? itemGap;
  final double? topPadding;
  final double feedRadius;
  final double? overlap;

  /// Optional controller for the feed scroll view. Defaults to null so existing
  /// callers are unaffected; the guided tour passes one to follow the scroll.
  final ScrollController? scrollController;

  /// Whether the hero scrolls away with the feed.
  ///
  /// Defaults to true because that is what every design screen does: `.lb-hero`
  /// is `position: relative` and sits INSIDE the scrolling `.ae-body`, never
  /// sticky (`dugnad.css` `.lb-hero`; `club-select.jsx`, `gamify-form.jsx`,
  /// `donate.jsx`, `player-card.jsx`, `leaderboard.jsx` all nest it the same
  /// way). Pinning it clips the first feed card behind the header.
  ///
  /// Set false only for a screen that genuinely needs a fixed header -- none
  /// does today.
  final bool scrollEntirePage;

  /// Background the hero actually paints, for the status strip and the
  /// overscroll block behind it. Defaults to the club primary; a `useReenLogo`
  /// hero is navy and has to say so, or the two bleed different colors.
  final Color? heroColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final overlapPx =
        context.dp(overlap ?? AeDugnadSpace.subFeedOverlap);

    final heroBg = heroColor ?? theme.primary;

    if (scrollEntirePage) {
      final statusBarHeight = MediaQuery.paddingOf(context).top;
      return ColoredBox(
        color: theme.background,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBarHeight + context.dp(240),
              child: ColoredBox(color: heroBg),
            ),
            CustomScrollView(
              controller: scrollController,
              clipBehavior: Clip.none,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      hero,
                      Transform.translate(
                        offset: Offset(0, -overlapPx),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: overlapPx),
                          child: DugnadSubpageFeedShell(
                            feedRadius: feedRadius,
                            child: DugnadSubpageFeed(
                              bottomPadding: bottomPadding,
                              itemGap: itemGap,
                              topPadding: topPadding,
                              children: children,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Design keeps the status strip OUTSIDE `.ae-body`: a solid band
            // the hero and feed scroll *under*. Without it the feed rides up
            // over the clock once the hero has gone.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBarHeight,
              child: IgnorePointer(child: ColoredBox(color: heroBg)),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          Expanded(
            child: ColoredBox(
              color: theme.primary,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -overlapPx,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DugnadSubpageFeedShell(
                      feedRadius: feedRadius,
                      child: ScrollConfiguration(
                        behavior: const _DugnadFeedScrollBehavior(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              controller: scrollController,
                              // Clamp top bounce — rubber-banding the feed
                              // sheet away from the hero flashes a color gap.
                              physics: const ClampingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: DugnadSubpageFeed(
                                  bottomPadding: bottomPadding,
                                  itemGap: itemGap,
                                  topPadding: topPadding,
                                  minHeight: constraints.maxHeight,
                                  children: children,
                                ),
                              ),
                            );
                          },
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
    );
  }
}

/// No glow / stretch overscroll — pairs with [ClampingScrollPhysics] on feed.
class _DugnadFeedScrollBehavior extends ScrollBehavior {
  const _DugnadFeedScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Hero + overlapping scroll feed (points, team picker — prototype: `.lb-hero` + `.lb-feed`).
class DugnadLbScrollBody extends StatelessWidget {
  const DugnadLbScrollBody({
    super.key,
    required this.hero,
    required this.children,
    this.bottomPadding = 40,
    this.itemGap,
    this.topPadding,
    this.feedRadius = 22,
    this.overlap,
    this.scrollController,
    this.scrollEntirePage = true,
    this.heroColor,
  });

  final Widget hero;
  final List<Widget> children;
  final double bottomPadding;
  final double? itemGap;
  final double? topPadding;
  final double feedRadius;
  final double? overlap;

  /// Optional controller forwarded to the feed scroll view (defaults to null).
  final ScrollController? scrollController;

  /// See [DugnadLbPageBody.scrollEntirePage].
  final bool scrollEntirePage;

  /// See [DugnadLbPageBody.heroColor].
  final Color? heroColor;

  @override
  Widget build(BuildContext context) {
    return DugnadLbPageBody(
      hero: hero,
      bottomPadding: bottomPadding,
      itemGap: itemGap,
      topPadding: topPadding,
      feedRadius: feedRadius,
      overlap: overlap,
      scrollController: scrollController,
      scrollEntirePage: scrollEntirePage,
      heroColor: heroColor,
      children: children,
    );
  }
}

/// Staggered rise-in entrance (prototype: `dg-rise-in`).
class DugnadFeedEnter extends StatefulWidget {
  const DugnadFeedEnter({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<DugnadFeedEnter> createState() => _DugnadFeedEnterState();
}

class _DugnadFeedEnterState extends State<DugnadFeedEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _started = false;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1, 0.36, 1),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // This shared feed-item entrance reached every subpage feed ungated, and
    // its start was a fire-and-forget Future.delayed. Under reduced motion land
    // the item at its final state; otherwise stage the rise via a cancellable
    // Timer so it cannot fire after disposal.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 60 * widget.index);
    _enterTimer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Section label (`.dg-label`).
class DugnadSectionLabel extends StatelessWidget {
  const DugnadSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `.dg-label { margin: 2px 2px 10px }` — asymmetric on purpose: the
      // label sits tight to the block above it and loose to its own content.
      padding: EdgeInsets.fromLTRB(
        context.dp(2),
        context.dp(2),
        context.dp(2),
        context.dp(10),
      ),
      child: Text(
        text.toUpperCase(),
        style: AeDugnadText.sectionLabel().dp(context),
      ),
    );
  }
}

/// Groups a section label with its content (prototype: `.dg-label` + block).
class DugnadSectionBlock extends StatelessWidget {
  const DugnadSectionBlock({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DugnadSectionLabel(label),
        ...children,
      ],
    );
  }
}
