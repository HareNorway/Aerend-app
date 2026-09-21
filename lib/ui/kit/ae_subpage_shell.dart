import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';
import '../../theme/ae_typography.dart';
import 'ae_theme.dart';

/// Locks typography to design-system px (375px frame) — ignores OS text scaling.
class AeFixedTypography extends StatelessWidget {
  const AeFixedTypography({super.key, required this.child});

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
class AeBackButton extends StatefulWidget {
  const AeBackButton({
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
  State<AeBackButton> createState() => _AeBackButtonState();
}

class _AeBackButtonState extends State<AeBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
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
class AeSimpleHero extends StatelessWidget {
  const AeSimpleHero({
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
        gradient: context.aeTheme.heroGradient,
      ),
      padding: EdgeInsets.fromLTRB(
        context.dp(22),
        MediaQuery.paddingOf(context).top + context.dp(6),
        context.dp(22),
        context.dp(20),
      ),
      child: Row(
        children: [
          AeBackButton(onPressed: onBack),
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
/// Lavender feed content (padding + spaced children).
class AeSubpageFeed extends StatelessWidget {
  const AeSubpageFeed({
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
/// Delegates to [_AeRoundedFeedSheet] (rounded lavender fill).
class AeSubpageFeedShell extends StatelessWidget {
  const AeSubpageFeedShell({
    super.key,
    required this.child,
    this.feedRadius = _AeRoundedFeedSheet.subpageRadius,
  });

  final Widget child;
  /// Design-px radius (`.lb-feed { border-radius: 22px 22px 0 0 }`).
  final double feedRadius;

  @override
  Widget build(BuildContext context) {
    return _AeRoundedFeedSheet(
      radius: feedRadius,
      child: child,
    );
  }
}

/// Pulls the feed sheet up over the purple hero (`.lb-feed { margin-top: -12px }`).
/// Prefer [AePageBody] for fixed-hero pages; use this only inside
/// [CustomScrollView] slivers where negative layout overlap is handled by the scroll stack.
class AeSubpageFeedOverlap extends StatelessWidget {
  const AeSubpageFeedOverlap({
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
class AePageBody extends StatelessWidget {
  const AePageBody({
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
    final theme = context.aeTheme;
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
                          child: AeSubpageFeedShell(
                            feedRadius: feedRadius,
                            child: AeSubpageFeed(
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
                    child: AeSubpageFeedShell(
                      feedRadius: feedRadius,
                      child: ScrollConfiguration(
                        behavior: const _AeFeedScrollBehavior(),
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
                                child: AeSubpageFeed(
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
class _AeFeedScrollBehavior extends ScrollBehavior {
  const _AeFeedScrollBehavior();

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
class AeScrollBody extends StatelessWidget {
  const AeScrollBody({
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

  /// See [AePageBody.scrollEntirePage].
  final bool scrollEntirePage;

  /// See [AePageBody.heroColor].
  final Color? heroColor;

  @override
  Widget build(BuildContext context) {
    return AePageBody(
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
class AeFeedEnter extends StatefulWidget {
  const AeFeedEnter({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<AeFeedEnter> createState() => _AeFeedEnterState();
}

class _AeFeedEnterState extends State<AeFeedEnter>
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
class AeSectionLabel extends StatelessWidget {
  const AeSectionLabel(this.text, {super.key});

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
class AeSectionBlock extends StatelessWidget {
  const AeSectionBlock({
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
        AeSectionLabel(label),
        ...children,
      ],
    );
  }
}

/// Rounded `.lb-feed` sheet over the hero — inlined from the deleted
/// `dugnad_rounded_feed_sheet.dart` so the kit carries no dugnad dependency.
///
/// Paint like CSS: rounded [BoxDecoration] fill, **no** [ClipRRect]. Soft
/// anti-aliased clipping leaves a bright fringe on the corner tips.
class _AeRoundedFeedSheet extends StatelessWidget {
  const _AeRoundedFeedSheet({
    required this.child,
    this.radius,
    this.sheetColor,
  });

  final double? radius;
  final Widget child;
  final Color? sheetColor;

  /// Design-px radius for sub-pages (`.lb-feed`).
  static const double subpageRadius = 22;

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final r = context.dp(radius ?? subpageRadius);
    final sheet = sheetColor ?? theme.background;
    final topRadius = BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheet,
        borderRadius: topRadius,
      ),
      child: child,
    );
  }
}
