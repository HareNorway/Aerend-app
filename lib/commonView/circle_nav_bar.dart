library circle_nav_bar;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_scale.dart';

typedef _LetIndexPage = bool Function(int value);

/// Ærend floating-pill bottom navigation bar.
///
/// Visual spec: rend-design-system → Nav.jsx / .ae-pillnav
/// - Frosted glass pill: rgba(255,255,255,0.82), blur 16 (sigma ≈ 8).
/// - Active tab: shiny-purple bg, white icon+label, smooth expand.
/// - Inactive tabs: icon only, gray-500.
///
/// Constructor signature is fully backward-compatible with the old CircleNavBar.
/// Legacy params (circleWidth, circleColor, gradient, etc.) are accepted but
/// ignored — the pill layout does not use a floating circle or notch painter.
class CircleNavBar extends StatefulWidget {
  final List<Widget> activeIcons;
  final List<Widget> inactiveIcons;
  final int activeIndex;
  final Color color;
  final Color? circleColor;
  final ValueChanged<int>? onTap;
  final _LetIndexPage letIndexChange;
  final Curve tabCurve;
  final Duration tabDuration;
  final double height;
  final double circleWidth;
  final double elevation;
  final Color shadowColor;
  final Color? circleShadowColor;
  final Gradient? gradient;
  final Gradient? circleGradient;
  final EdgeInsets padding;
  final BorderRadius cornerRadius;
  final List<String>? levels;
  final TextStyle? activeLevelsStyle;
  final TextStyle? inactiveLevelsStyle;
  final int? fixedFabIndex;
  final double fixedCenterSlotHeight;
  final Gradient? activePillGradient;
  final Color? pillBorderColor;
  final Color? activePillShadowColor;
  final bool compactItems;
  final double compactGap;
  final double compactActiveWidth;
  final double compactInactiveWidth;
  /// Max fraction of screen width the compact dugnad pill may grow to
  /// (active label is fully visible up to this cap — design / mock ≈ 90%).
  final double compactWidthFactor;

  CircleNavBar({
    super.key,
    required this.activeIcons,
    required this.inactiveIcons,
    this.activeIndex = 0,
    required this.color,
    this.circleColor,
    this.onTap,
    _LetIndexPage? letIndexChange,
    this.tabCurve = Curves.easeOutCubic,
    this.tabDuration = const Duration(milliseconds: 280),
    this.height = 75.0,
    this.circleWidth = 60.0,
    this.elevation = 0.0,
    this.shadowColor = Colors.transparent,
    this.circleShadowColor,
    this.gradient,
    this.circleGradient,
    this.padding = EdgeInsets.zero,
    this.cornerRadius = BorderRadius.zero,
    this.levels,
    this.activeLevelsStyle,
    this.inactiveLevelsStyle,
    this.fixedFabIndex,
    this.fixedCenterSlotHeight = 32,
    this.activePillGradient,
    this.pillBorderColor,
    this.activePillShadowColor,
    this.compactItems = false,
    this.compactGap = 4,
    this.compactActiveWidth = 162,
    this.compactInactiveWidth = 56,
    this.compactWidthFactor = 0.90,
  })  : letIndexChange = letIndexChange ?? ((_) => true),
        assert(activeIcons.length == inactiveIcons.length),
        assert(0 <= activeIndex && activeIndex < activeIcons.length),
        assert(compactWidthFactor > 0 && compactWidthFactor <= 1);

  @override
  CircleNavBarState createState() => CircleNavBarState();
}

/// Design px on the 375 frame. `.pn-item { height: 46px }` inside
/// `.pn-track { padding: 8px }`.
const double kAePillNavItemHeight = 46;
const double kAePillNavTrackPad = 8;

/// Height of the floating pill itself.
const double kAePillNavPillHeight =
    kAePillNavItemHeight + kAePillNavTrackPad * 2;

/// `.ae-pillnav` bottom inset on the 375 design frame (safe-area is 0 there).
///
/// CSS is `calc(env(safe-area-inset-bottom,0) + 16px)`. In the HTML prototype
/// the frame has no safe-area, so that resolves to 16px above the home
/// indicator. On a real device the system inset already clears the indicator —
/// stacking `inset + 16` floats the bar too high vs Figma. Use
/// [aePillNavBottomInset] (`max(inset, 16)`) instead of summing both.
const double kAePillNavBottomGap = 16;
const double kAePillNavSidePad = 12;

/// Bottom padding under the pill — design 16px, or the device safe-area when
/// that is larger (home-indicator phones).
double aePillNavBottomInset(BuildContext context) => math.max(
      MediaQuery.paddingOf(context).bottom,
      context.dp(kAePillNavBottomGap),
    );

/// Vertical space a scrolling page must reserve so its last card is not
/// covered by the floating nav. The nav is an overlay, so pages do not get
/// this from the layout and have to add it themselves.
double aePillNavReservedHeight(BuildContext context) =>
    context.dp(kAePillNavPillHeight) + aePillNavBottomInset(context);

class CircleNavBarState extends State<CircleNavBar> {
  String? _labelAt(int i) {
    if (widget.levels == null || i >= widget.levels!.length) return null;
    return widget.levels![i];
  }

  void _onItemTap(int i) {
    if (!widget.letIndexChange(i)) return;
    widget.onTap?.call(i);
  }

  Widget _buildPillShell({required double? width, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          padding: EdgeInsets.all(context.dp(kAePillNavTrackPad)),
          decoration: BoxDecoration(
            color: const Color(0xD1FFFFFF), // rgba(255,255,255,0.82)
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.pillBorderColor ?? const Color(0x1F7F5FC4),
              width: context.dp(1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x4D2D1B5B),
                blurRadius: context.dp(34),
                offset: Offset(0, context.dp(14)),
                spreadRadius: context.dp(-12),
              ),
              BoxShadow(
                color: const Color(0x1A2D1B5B),
                blurRadius: context.dp(6),
                offset: Offset(0, context.dp(2)),
                spreadRadius: context.dp(-2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Compact dugnad bar: hug icon+label content, grow/shrink with the active
  /// tab, never exceed [compactWidthFactor] of the screen (mock ≈ 90%).
  Widget _buildCompactBar(BuildContext context, int tabCount) {
    final maxW =
        MediaQuery.sizeOf(context).width * widget.compactWidthFactor;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: AnimatedSize(
        duration: widget.tabDuration,
        curve: widget.tabCurve,
        alignment: Alignment.center,
        child: _buildPillShell(
          width: null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < tabCount; i++) ...[
                  if (i > 0) SizedBox(width: context.dp(widget.compactGap)),
                  _PillNavItem(
                    activeIcon: widget.activeIcons[i],
                    inactiveIcon: widget.inactiveIcons[i],
                    label: _labelAt(i),
                    isActive: widget.activeIndex == i,
                    duration: widget.tabDuration,
                    curve: widget.tabCurve,
                    activePillGradient: widget.activePillGradient,
                    activePillShadowColor: widget.activePillShadowColor,
                    expand: false,
                    fillActiveSlot: false,
                    onTap: () => _onItemTap(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthBar(BuildContext context, int tabCount) {
    return _buildPillShell(
      width: double.infinity,
      child: Row(
        children: [
          for (var i = 0; i < tabCount; i++)
            Expanded(
              flex: widget.activeIndex == i ? 2 : 1,
              child: _PillNavItem(
                activeIcon: widget.activeIcons[i],
                inactiveIcon: widget.inactiveIcons[i],
                label: _labelAt(i),
                isActive: widget.activeIndex == i,
                duration: widget.tabDuration,
                curve: widget.tabCurve,
                activePillGradient: widget.activePillGradient,
                activePillShadowColor: widget.activePillShadowColor,
                expand: true,
                fillActiveSlot: false,
                onTap: () => _onItemTap(i),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int tabCount = widget.inactiveIcons.length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: aePillNavBottomInset(context),
      ),
      child: Align(
        alignment: Alignment.center,
        heightFactor: 1.0,
        child: widget.compactItems
            ? _buildCompactBar(context, tabCount)
            : _buildFullWidthBar(context, tabCount),
      ),
    );
  }
}

/// Single tab item in the pill nav.
///
/// Active label width animates 0 → full so the colored capsule is pushed open
/// to the right as the text appears (mock: expanding active chip).
class _PillNavItem extends StatefulWidget {
  final Widget activeIcon;
  final Widget inactiveIcon;
  final String? label;
  final bool isActive;
  final Duration duration;
  final Curve curve;
  final Gradient? activePillGradient;
  final Color? activePillShadowColor;
  final VoidCallback onTap;

  /// When true the item fills its slot (full-width nav). When false it sizes
  /// to its content so items can be packed tightly (compact nav).
  final bool expand;

  /// Stretch the active capsule to fill its [Expanded] slot (dugnad track).
  final bool fillActiveSlot;

  const _PillNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isActive,
    required this.duration,
    required this.curve,
    this.activePillGradient,
    this.activePillShadowColor,
    required this.onTap,
    this.expand = true,
    this.fillActiveSlot = false,
  });

  @override
  State<_PillNavItem> createState() => _PillNavItemState();
}

class _PillNavItemState extends State<_PillNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isActive ? 1.0 : 0.0,
    );
    _reveal = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(covariant _PillNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) => SizedBox(
          height: context.dp(kAePillNavItemHeight),
          width: widget.expand ? double.infinity : null,
          child: _buildBody(context),
        ),
      ),
    );
  }

  /// `.pn-item .pn-ico { width: 46px; height: 46px }`
  Widget _iconSlot(BuildContext context) {
    final showActiveChrome = widget.isActive || _reveal.value > 0.001;
    return SizedBox(
      width: context.dp(kAePillNavItemHeight),
      height: context.dp(kAePillNavItemHeight),
      child: Center(
        child: showActiveChrome ? widget.activeIcon : widget.inactiveIcon,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = _reveal.value;
    final showPill = widget.isActive || t > 0.001;

    if (!showPill) {
      final slot = _iconSlot(context);
      return widget.expand ? Center(child: slot) : slot;
    }

    return _buildActivePill(context, t);
  }

  /// `.pn-item.on` — icon stays put; label widthFactor reveals L→R and pushes
  /// the gradient capsule open to the right.
  Widget _buildActivePill(BuildContext context, double t) {
    final labelStyle = TextStyle(
      fontSize: context.dp(13.5),
      fontWeight: FontWeight.w800,
      letterSpacing: context.dp(13.5) * -0.01,
      color: Colors.white,
      height: 1.0,
    );

    final label = widget.label;
    final Widget? labelReveal = label == null
        ? null
        : ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: t.clamp(0.0, 1.0),
              child: Opacity(
                opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: context.dp(2),
                    right: context.dp(16) * t,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: labelStyle,
                  ),
                ),
              ),
            ),
          );

    final pill = Container(
      height: context.dp(kAePillNavItemHeight),
      width: widget.fillActiveSlot ? double.infinity : null,
      padding: EdgeInsets.only(left: context.dp(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: widget.activePillGradient ??
            const LinearGradient(
              begin: Alignment(-0.5, -0.85),
              end: Alignment(0.5, 0.85),
              colors: [
                Color(0xFFA98FE0),
                Color(0xFF7F5FC4),
                Color(0xFF6B4FA8),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
        boxShadow: [
          BoxShadow(
            color: widget.activePillShadowColor ?? const Color(0x8C7F5FC4),
            blurRadius: context.dp(14) * t,
            offset: Offset(0, context.dp(6) * t),
            spreadRadius: context.dp(-4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            widget.fillActiveSlot ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconSlot(context),
          if (labelReveal != null)
            (widget.expand || widget.fillActiveSlot)
                ? Flexible(child: labelReveal)
                : labelReveal,
        ],
      ),
    );

    return widget.expand && !widget.fillActiveSlot
        ? Center(child: pill)
        : pill;
  }
}
