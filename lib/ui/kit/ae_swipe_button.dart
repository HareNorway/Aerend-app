import 'package:flutter/material.dart';

import '../../theme/design_scale.dart';

import '../../theme/sc_saas_theme.dart';

/// Swipe-to-confirm slider — mirrors `SwipeButton` (dugnad/swipe.jsx) and the
/// `.dg-swipe` rules: ~66px track, 56px knob inset 5px, settle transition
/// 280ms cubic-bezier(.2,.9,.3,1.2), completion at 85% of travel.
/// Track fill stays fully opaque so content never shows through the capsule.
enum AeSwipeVariant { green, purple }

class AeSwipeButton extends StatefulWidget {
  const AeSwipeButton({
    super.key,
    required this.label,
    required this.onComplete,
    this.amount,
    this.doneLabel,
    this.variant = AeSwipeVariant.purple,
    this.enabled = true,
  });

  final String label;
  final String? amount;
  final String? doneLabel;
  final VoidCallback onComplete;
  final AeSwipeVariant variant;
  final bool enabled;

  @override
  State<AeSwipeButton> createState() => _AeSwipeButtonState();
}

class _AeSwipeButtonState extends State<AeSwipeButton>
    with TickerProviderStateMixin {
  static const double _trackHeight = 66;
  static const double _knob = 56;
  static const double _pad = 5;
  static const Duration _settle = Duration(milliseconds: 280);
  static const Cubic _settleCurve = Cubic(0.2, 0.9, 0.3, 1.2);

  double _x = 0;
  bool _dragging = false;
  bool _done = false;

  // dg-chev (1.4s) + dg-nudge (1.9s) idle motion.
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
    Future<void>.delayed(const Duration(milliseconds: 380), () {
      if (mounted) widget.onComplete();
    });
  }

  double _nudgeOffset(double t) {
    // 0%,58%,100% → 0 ; 74% → 8px
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
    final purple = widget.variant == AeSwipeVariant.purple;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX = (constraints.maxWidth - _knob - _pad * 2).clamp(0.0, 4000.0);
        final progress = maxX == 0 ? 0.0 : _x / maxX;
        final idle = !_dragging && !_done && _x == 0;

        final base = purple
            ? const Color(0xFF7F5FC4)
            : const Color(0xFF1C8351);
        // Avoid wrapping in [Opacity] — that composites the track and lets
        // scrolled content show through the capsule.
        return Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: purple
                    ? const [
                        Color(0xFFA98FE0),
                        Color(0xFF7F5FC4),
                        Color(0xFF6B4FA8),
                      ]
                    : const [Color(0xFF29A96A), Color(0xFF1C8351)],
                stops: purple ? const [0, 0.55, 1] : null,
              ),
              boxShadow: [
                BoxShadow(
                  color: purple
                      ? const Color(0x8C7F5FC4)
                      : const Color(0x8C22A769),
                  blurRadius: context.dp(22),
                  offset: const Offset(0, 9),
                  spreadRadius: -7,
                ),
              ],
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
                  // .dg-swipe-trail — only after the knob moves. At rest the
                  // full-height band reads as a square behind the white disc.
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
                  // .dg-swipe-label
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _done
                            ? 0
                            : (1 - progress * 1.5).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: _knob),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Chevrons(
                                controller: _chev,
                                animate: !reduceMotion,
                              ),
                              SizedBox(width: context.dp(9)),
                              Text(widget.label, style: _labelStyle),
                              if (widget.amount != null) ...[
                                SizedBox(width: context.dp(5)),
                                Text('· ${widget.amount}', style: _labelStyle),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // .dg-swipe-done
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _done ? 1 : 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: context.dp(18), color: Colors.white),
                            SizedBox(width: context.dp(9)),
                            Text(
                              widget.doneLabel ?? widget.label,
                              style: _labelStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // .dg-swipe-knob
                  AnimatedPositioned(
                    duration: _dragging ? Duration.zero : _settle,
                    curve: _settleCurve,
                    left: _pad + _x,
                    top: _pad,
                    child: AnimatedBuilder(
                      animation: _nudge,
                      builder: (context, child) {
                        final dx = (idle && !reduceMotion)
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
                                  _x = (_x + details.delta.dx)
                                      .clamp(0.0, maxX);
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
                        child: _SwipeKnobDisc(
                          done: _done,
                          size: _knob,
                          iconColor: purple
                              ? ScSaasThemeTokens.primaryHover
                              : const Color(0xFF1C8351),
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

/// Soft circular shade via radial gradient — [BoxShadow] clips to a square
/// inside the track's [ClipRRect].
class _SwipeKnobDisc extends StatelessWidget {
  const _SwipeKnobDisc({
    required this.done,
    required this.iconColor,
    this.size = 56,
  });

  final bool done;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glow = size + context.dp(14);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: (size - glow) / 2,
            top: (size - glow) / 2 + context.dp(2),
            width: glow,
            height: glow,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x66140C28),
                      Color(0x33140C28),
                      Color(0x00140C28),
                    ],
                    stops: [0.35, 0.62, 1.0],
                  ),
                ),
              ),
            ),
          ),
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
          _Chevron(opacity: 1),
          SizedBox(width: context.dp(3)),
          _Chevron(opacity: 1),
          SizedBox(width: context.dp(3)),
          _Chevron(opacity: 1),
        ],
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double opacityAt(double delay) {
          final t = (controller.value + delay) % 1.0;
          // 0%,100% → .25 ; 50% → 1
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
        angle: -0.7853981633974483, // -45°
        child: Container(
          width: context.dp(7),
          height: context.dp(7),
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(width: context.dp(2.5), color: Color(0xEBFFFFFF)),
              bottom: BorderSide(width: context.dp(2.5), color: Color(0xEBFFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}
