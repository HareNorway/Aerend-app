import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../utils/utils.dart';
import '../../../ui/kit/ae_theme.dart';
import 'dugnad_bead_badge.dart';
import '../../../ui/kit/ae_confetti.dart';

/// Reusable full-screen ceremonial overlay (`dgseq` in celebrate-pops.jsx).
///
/// Club-gradient backdrop, confetti, hero slot, and kicker / title / subtitle
/// copy block. Used for club welcome (T14), team table (T5), season-end (T9–T15).
class DugnadCeremonialScreen extends StatefulWidget {
  const DugnadCeremonialScreen({
    super.key,
    this.hero,
    this.kicker,
    this.title,
    this.subtitle,
    this.footer,
    this.tapToDismiss = true,
    this.autoDismissAfter,
    this.confettiPieces = 130,
    this.showCloseButton = false,
    this.showSpotlight = false,
  });

  final Widget? hero;
  final String? kicker;
  final String? title;
  final String? subtitle;
  final Widget? footer;
  final bool tapToDismiss;

  /// Safety cap for tap-to-dismiss ceremonials (T13/T14). Stacked modals can
  /// swallow taps and lock the navigator; this always pops.
  static const Duration kTapDismissMax = Duration(seconds: 7);

  /// When set, auto-pops after this delay. Tap-to-dismiss screens default to
  /// [kTapDismissMax] so they cannot trap the user.
  final Duration? autoDismissAfter;
  final int confettiPieces;
  final bool showCloseButton;
  final bool showSpotlight;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDismiss,
    Widget? hero,
    String? kicker,
    String? title,
    String? subtitle,
    Widget? footer,
    bool tapToDismiss = true,
    Duration? autoDismissAfter,
    int confettiPieces = 130,
    bool showCloseButton = false,
    bool showSpotlight = false,
  }) async {
    final route = PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      barrierDismissible: tapToDismiss,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DugnadCeremonialScreen(
          hero: hero,
          kicker: kicker,
          title: title,
          subtitle: subtitle,
          footer: footer,
          tapToDismiss: tapToDismiss,
          autoDismissAfter: autoDismissAfter ??
              (tapToDismiss ? kTapDismissMax : null),
          confettiPieces: confettiPieces,
          showCloseButton: showCloseButton,
          showSpotlight: showSpotlight,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    await Navigator.of(context, rootNavigator: true).push<void>(route);
    // `push` resolves the moment the route is popped — the exit transition is
    // still running and the entry is still in the navigator history. T14/T13
    // queue back to back, so pumping the next ceremonial from here pushed an
    // opaque route over this one, parked it offstage with its ticker muted,
    // and left it stuck in `popping`. `completed` resolves on dispose.
    await route.completed;
    // After the pop animation — never from PopScope/onTap, which run while
    // Navigator is `_debugLocked` and the next celebration would push/insert
    // on top of this transition.
    onDismiss();
  }

  @override
  State<DugnadCeremonialScreen> createState() => _DugnadCeremonialScreenState();
}

class _DugnadCeremonialScreenState extends State<DugnadCeremonialScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bg;
  late final AnimationController _copy;
  late final AnimationController _spotlight;
  bool? _reduceMotion;
  bool _dismissed = false;
  bool _dismissing = false;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _copy = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Design `.dgseq-rays-spin` is 34s linear infinite.
    _spotlight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 34000),
    );
    HapticFeedback.heavyImpact();
    final auto = widget.autoDismissAfter;
    if (auto != null) {
      _autoDismiss = Timer(auto, () {
        if (mounted && !_dismissed) _dismiss();
      });
    }
  }

  void _dismiss() {
    if (_dismissed || _dismissing) return;
    _dismissing = true;
    _autoDismiss?.cancel();
    // Always the next frame — a tap/timer in idle still races HeroController
    // and PopScope, which notify ancestors while pop() holds `_debugLocked`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dismissed || !mounted) {
        _dismissing = false;
        return;
      }
      // Pop THIS route. A bare `nav.pop()` takes whatever sits on top of the
      // root navigator, which is not us the moment anything is stacked over
      // this ceremonial — that closed the wrong screen and still latched
      // `_dismissed`, so close / tap / auto-dismiss all went dead afterwards.
      final route = ModalRoute.of(context);
      final nav = route?.navigator ??
          Navigator.maybeOf(context, rootNavigator: true) ??
          navigatorKey.currentState;
      if (kDebugMode) {
        debugPrint(
          '[ceremonial] dismiss route=${route?.runtimeType} '
          'nav=${nav != null} active=${route?.isActive} '
          'current=${route?.isCurrent} canPop=${nav?.canPop()}',
        );
      }
      if (route == null || nav == null) {
        _dismissing = false;
        return;
      }
      if (!route.isActive) {
        // Already on its way out — a pop raced the auto-dismiss timer. Do NOT
        // latch `_dismissed`: if this ever reports a route that is still on
        // screen, latching here would kill the button for good.
        _dismissing = false;
        return;
      }
      _dismissed = true;
      if (route.isCurrent) {
        nav.pop();
      } else {
        // Buried under another route; pop() would remove the wrong entry.
        nav.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != null && reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce == true) {
      _bg.value = 1;
      _copy.value = 1;
    } else if (_bg.status == AnimationStatus.dismissed) {
      _bg.forward();
      if (widget.showSpotlight) _spotlight.repeat();
      Future<void>.delayed(const Duration(milliseconds: 460), () {
        if (mounted) _copy.forward();
      });
    }
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _bg.dispose();
    _copy.dispose();
    _spotlight.dispose();
    super.dispose();
  }

  LinearGradient _backgroundGradient(AeThemePalette theme) {
    Color mix(Color c, Color b, double weight) => Color.lerp(c, b, weight)!;
    const black = Color(0xFF000000);
    return LinearGradient(
      begin: const Alignment(-0.15, -1),
      end: const Alignment(0.45, 1),
      colors: [
        mix(theme.primary, black, 0.04),
        mix(theme.ink, black, 0.04),
        mix(theme.ink, black, 0.26),
      ],
      stops: const [0, 0.62, 1],
    );
  }

  Widget _animatedCopyLine({
    required String text,
    required TextStyle style,
    required double start,
    required double end,
    TextAlign align = TextAlign.center,
  }) {
    final anim = CurvedAnimation(
      parent: _copy,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: _reduceMotion == true ? const AlwaysStoppedAnimation(1) : anim,
      child: SlideTransition(
        position: _reduceMotion == true
            ? const AlwaysStoppedAnimation(Offset.zero)
            : Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(anim),
        child: Text(text, textAlign: align, style: style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    final confettiColors = <Color>[
      const Color(0xFFF7CF6B),
      Colors.white,
      theme.primarySoft,
      theme.ink,
      const Color(0xFFE0A93A),
      theme.primary,
    ];
    final reduce = _reduceMotion == true;

    return PopScope(
      canPop: true,
      child: Scaffold(
      backgroundColor: theme.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: reduce ? const AlwaysStoppedAnimation(1) : _bg,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _backgroundGradient(theme)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.showSpotlight)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DugnadSpotlightRays(
                          progress: reduce
                              ? const AlwaysStoppedAnimation(0.08)
                              : _spotlight,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Center(child: _buildBody(context)),
                  // Same burst as T3 (rects/dots/squares), faster fall, over content.
                  if (!reduce && widget.confettiPieces > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AeDesignBurstConfetti(
                          colors: confettiColors,
                          count: widget.confettiPieces,
                          duration: const Duration(milliseconds: 4200),
                          fallSpeed: 1.55,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Above the fade/hero so a click always lands, including on the T13 card.
          if (widget.tapToDismiss)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerUp: (_) => _dismiss(),
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          if (widget.showCloseButton)
            Positioned(
              top: MediaQuery.paddingOf(context).top + context.dp(10),
              right: context.dp(16),
              child: Semantics(
                button: true,
                label: 'Close',
                child: Listener(
                  // InkWell loses the tap arena to ancestor GestureDetectors
                  // (MaterialApp wrapper) while still absorbing hits, so the
                  // full-screen dismiss Listener behind this never fires.
                  behavior: HitTestBehavior.opaque,
                  onPointerUp: (_) => _dismiss(),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: SizedBox(
                      width: context.dp(36),
                      height: context.dp(36),
                      child: Icon(
                        Icons.close_rounded,
                        size: context.dp(20),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(34),
          vertical: context.dp(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.hero != null) widget.hero!,
            if (widget.kicker != null && widget.kicker!.trim().isNotEmpty) ...[
              SizedBox(height: context.dp(widget.hero != null ? 14 : 0)),
              _animatedCopyLine(
                text: widget.kicker!.toUpperCase(),
                start: 0,
                end: 0.45,
                style: aeLabel(
                  color: Colors.white.withValues(alpha: 0.66),
                ).copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.8,
                ),
              ),
            ],
            if (widget.title != null && widget.title!.trim().isNotEmpty) ...[
              SizedBox(height: context.dp(8)),
              _animatedCopyLine(
                text: widget.title!,
                start: 0.12,
                end: 0.62,
                style: aeTitle(color: Colors.white).copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.16,
                ),
              ),
            ],
            if (widget.subtitle != null &&
                widget.subtitle!.trim().isNotEmpty) ...[
              SizedBox(height: context.dp(11)),
              _animatedCopyLine(
                text: widget.subtitle!,
                start: 0.28,
                end: 0.82,
                style: aeBody(
                  color: Colors.white.withValues(alpha: 0.72),
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
            if (widget.footer != null) ...[
              SizedBox(height: context.dp(22)),
              widget.footer!,
            ],
          ],
        ),
      ),
    );
  }
}
