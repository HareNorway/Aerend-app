import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';

/// Swipe-to-pay slider for campaign checkout.
///
/// Mirrors prototype `SwipeButton` / `.dg-swipe`: ~66px track, 56px knob inset
/// 5px, trail while dragging, idle nudge, pulsing chevrons.
///
/// Track fill is fully opaque (solid color under gradient) so scrolled
/// checkout content never shows through the capsule.
///
/// Knob depth uses a **circular radial shade** (not [BoxShadow]) so nothing
/// rectangular can appear behind the white disc — BoxShadow + ClipRRect was
/// squaring the glow on the club-green track.
class CampaignSwipePayBar extends StatefulWidget {
  final String label;
  final String amountText;
  final VoidCallback onConfirmed;
  final bool enabled;
  final Color? accent;
  final Color? accentHover;
  final Color? accentDisabled;
  final List<BoxShadow>? buttonShadow;

  const CampaignSwipePayBar({
    super.key,
    required this.label,
    required this.amountText,
    required this.onConfirmed,
    this.enabled = true,
    this.accent,
    this.accentHover,
    this.accentDisabled,
    this.buttonShadow,
  });

  @override
  State<CampaignSwipePayBar> createState() => _CampaignSwipePayBarState();
}

class _CampaignSwipePayBarState extends State<CampaignSwipePayBar>
    with TickerProviderStateMixin {
  static const double _trackHeight = 66;
  static const double _knob = 56;
  static const double _pad = 5;
  static const Duration _settle = Duration(milliseconds: 280);
  static const Cubic _settleCurve = Cubic(0.2, 0.9, 0.3, 1.2);

  double _x = 0;
  bool _dragging = false;
  bool _done = false;

  late final AnimationController _chev = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _chev.dispose();
    _nudge.dispose();
    super.dispose();
  }

  void _finish() {
    setState(() => _done = true);
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      widget.onConfirmed();
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _done = false;
          _x = 0;
        });
      });
    });
  }

  double _nudgeOffset(double t) {
    if (t < 0.58) return 0;
    if (t < 0.74) {
      return 8 * Curves.easeInOut.transform((t - 0.58) / 0.16);
    }
    if (t < 1) {
      return 8 * (1 - Curves.easeInOut.transform((t - 0.74) / 0.26));
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final accent = widget.accent ?? ScSaasThemeTokens.primary;
    final accentHover = widget.accentHover ?? ScSaasThemeTokens.primaryHover;
    final accentDisabled =
        widget.accentDisabled ?? ScSaasThemeTokens.primaryDisabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX =
            (constraints.maxWidth - _knob - _pad * 2).clamp(0.0, 4000.0);
        final progress = maxX == 0 ? 0.0 : _x / maxX;
        final idle = !_dragging && !_done && _x == 0;

        final trackColor = widget.enabled ? accent : accentDisabled;
        // Avoid [Opacity] on the track — it lets scroll content bleed through.
        return Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              color: trackColor, // opaque base (mockup solid capsule)
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.enabled
                    ? [accent, accentHover]
                    : [accentDisabled, accentDisabled],
              ),
              boxShadow: widget.enabled
                  ? (widget.buttonShadow ??
                      [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: context.dp(22),
                          offset: const Offset(0, 9),
                          spreadRadius: -7,
                        ),
                      ])
                  : null,
            ),
            foregroundDecoration: widget.enabled
                ? null
                : BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  // Trail only while the knob has moved — at rest it was a
                  // full-height light rectangle behind the disc (the "square").
                  if (_x > 0.5)
                    AnimatedPositioned(
                      duration: _dragging ? Duration.zero : _settle,
                      curve: _settleCurve,
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: _x + _knob + _pad * 2,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x26FFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                      ),
                    ),
                  // Label
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity:
                            _done ? 0 : (1 - progress * 1.5).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: _knob),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Chevrons(
                                controller: _chev,
                                animate: !reduceMotion && widget.enabled,
                              ),
                              SizedBox(width: context.dp(9)),
                              Text(widget.label, style: _labelStyle),
                              SizedBox(width: context.dp(5)),
                              Text(
                                '· ${widget.amountText}',
                                style: _labelStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Done
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _done ? 1 : 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: context.dp(18),
                              color: Colors.white,
                            ),
                            SizedBox(width: context.dp(9)),
                            const Text('Betaler…', style: _labelStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Knob + circular shade
                  AnimatedPositioned(
                    duration: _dragging ? Duration.zero : _settle,
                    curve: _settleCurve,
                    left: _pad + _x,
                    top: _pad,
                    width: _knob,
                    height: _knob,
                    child: AnimatedBuilder(
                      animation: _nudge,
                      builder: (context, child) {
                        final dx = (idle && !reduceMotion && widget.enabled)
                            ? _nudgeOffset(_nudge.value)
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: widget.enabled && !_done
                            ? (_) => setState(() => _dragging = true)
                            : null,
                        onHorizontalDragUpdate: widget.enabled && !_done
                            ? (details) => setState(() {
                                  _x =
                                      (_x + details.delta.dx).clamp(0.0, maxX);
                                })
                            : null,
                        onHorizontalDragEnd: widget.enabled && !_done
                            ? (_) {
                                setState(() => _dragging = false);
                                if (_x >= maxX * 0.85) {
                                  setState(() => _x = maxX);
                                  _finish();
                                } else {
                                  setState(() => _x = 0);
                                }
                              }
                            : null,
                        child: _SwipeKnob(
                          done: _done,
                          size: _knob,
                          iconColor: widget.enabled
                              ? accentHover
                              : ScSaasThemeTokens.gray500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 15 * -0.01,
  );
}

/// White disc with a soft **circular** shade drawn as a radial glow — never
/// a [BoxShadow], which ClipRRect turns into a square band on this track.
class _SwipeKnob extends StatelessWidget {
  const _SwipeKnob({
    required this.done,
    required this.iconColor,
    this.size = 56,
  });

  final bool done;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Glow extends a few px past the disc so depth reads on the track.
    final glow = size + context.dp(14);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft circular shade — `0 4px 11px -2px rgba(20,12,40,.32)` feel.
          Positioned(
            left: (size - glow) / 2,
            top: (size - glow) / 2 + context.dp(2),
            width: glow,
            height: glow,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: const [
                      Color(0x66140C28),
                      Color(0x33140C28),
                      Color(0x00140C28),
                    ],
                    stops: const [0.35, 0.62, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Solid white disc — no BoxShadow.
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.chevron_right_rounded,
              size: context.dp(28),
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.dg-swipe-chevs` — three 7px chevrons pulsing 0.25→1 with 160ms offsets.
class _Chevrons extends StatelessWidget {
  const _Chevrons({required this.controller, required this.animate});

  final AnimationController controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Chevron(opacity: 1),
          SizedBox(width: context.dp(3)),
          const _Chevron(opacity: 1),
          SizedBox(width: context.dp(3)),
          const _Chevron(opacity: 1),
        ],
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double opacityAt(double delay) {
          final t = (controller.value + delay) % 1.0;
          final wave = t < 0.5 ? t / 0.5 : (1 - t) / 0.5;
          return 0.25 + 0.75 * Curves.easeInOut.transform(wave);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chevron(opacity: opacityAt(0)),
            SizedBox(width: context.dp(3)),
            _Chevron(opacity: opacityAt(0.16 / 1.4)),
            SizedBox(width: context.dp(3)),
            _Chevron(opacity: opacityAt(0.32 / 1.4)),
          ],
        );
      },
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: -0.7853981633974483,
        child: Container(
          width: context.dp(7),
          height: context.dp(7),
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(
                width: context.dp(2.5),
                color: const Color(0xEBFFFFFF),
              ),
              bottom: BorderSide(
                width: context.dp(2.5),
                color: const Color(0xEBFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
