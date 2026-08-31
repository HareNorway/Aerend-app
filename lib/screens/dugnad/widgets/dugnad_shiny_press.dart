import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dugnad_club_theme.dart';

/// Press + release for shiny club pills (`.ae-btn` / `.sh-entry` in kit-shared.css).
///
/// Down: translateY(3px) scale(.93, .9), brightness .94.
/// Up: rubber pop (ae-btn-pop, 700ms) and an expanding color ring.
class DugnadShinyPress extends StatefulWidget {
  const DugnadShinyPress({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 18,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  State<DugnadShinyPress> createState() => _DugnadShinyPressState();
}

class _DugnadShinyPressState extends State<DugnadShinyPress>
    with TickerProviderStateMixin {
  late final AnimationController _hold;
  late final AnimationController _pop;
  late final AnimationController _ring;

  bool _holding = false;

  static const _pressMs = 90;
  static const _popMs = 700;
  static const _ringMs = 600;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _pressMs),
    );
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _popMs),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _ringMs),
    );
    _pop.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _pop.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    _pop.dispose();
    _ring.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _holding = true);
      return;
    }
    _pop.stop();
    _pop.value = 0;
    _holding = true;
    _hold.forward();
  }

  void _cancel() {
    _holding = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {});
      return;
    }
    _hold.reverse();
  }

  void _up(TapUpDetails _) {
    HapticFeedback.lightImpact();
    _holding = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {});
      widget.onTap();
      return;
    }
    _hold.value = 0;
    _pop.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) _ring.forward(from: 0);
    });
    widget.onTap();
  }

  /// Linear keyframes from `@keyframes ae-btn-pop`.
  ({double ty, double sx, double sy}) _popAt(double t) {
    const keys = <double>[0, 0.13, 0.30, 0.46, 0.60, 0.74, 0.86, 0.94, 1];
    const ty = <double>[0, 3, -4, 1.4, -1.6, 0.6, -0.6, 0.2, 0];
    const sx = <double>[1, 0.93, 1.055, 1.005, 1.022, 0.998, 1.008, 1, 1];
    const sy = <double>[1, 0.90, 1.075, 0.965, 1.03, 0.986, 1.011, 0.997, 1];
    for (var i = 0; i < keys.length - 1; i++) {
      if (t <= keys[i + 1] || i == keys.length - 2) {
        final p = ((t - keys[i]) / (keys[i + 1] - keys[i])).clamp(0.0, 1.0);
        return (
          ty: ty[i] + (ty[i + 1] - ty[i]) * p,
          sx: sx[i] + (sx[i + 1] - sx[i]) * p,
          sy: sy[i] + (sy[i + 1] - sy[i]) * p,
        );
      }
    }
    return (ty: 0, sx: 1, sy: 1);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final accent = context.dugnadTheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_hold, _pop, _ring]),
      builder: (context, child) {
        final holdT = reduced ? 0.0 : _hold.value;
        final pop = _pop.isAnimating ? _popAt(_pop.value) : null;

        final ty = pop?.ty ?? (3 * holdT);
        final sx = pop?.sx ?? (1 - 0.07 * holdT);
        final sy = pop?.sy ?? (1 - 0.10 * holdT);
        final brightness = 1 - 0.06 * holdT;

        Widget body = child!;
        if (reduced && _holding) {
          body = Opacity(opacity: 0.82, child: body);
        } else if (ty != 0 || sx != 1 || sy != 1 || brightness < 0.999) {
          Widget scaled = Transform.translate(
            offset: Offset(0, ty),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: body,
            ),
          );
          if (brightness < 0.999) {
            scaled = ColorFiltered(
              colorFilter: ColorFilter.matrix(_brightnessMatrix(brightness)),
              child: scaled,
            );
          }
          body = scaled;
        }

        final ringT = _ring.value;
        final ringOpacity = ringT == 0
            ? 0.0
            : ringT < 0.55
                ? 0.6 - (ringT / 0.55) * 0.38
                : 0.22 * (1 - (ringT - 0.55) / 0.45);
        final ringSpread = ringT < 0.55
            ? (ringT / 0.55) * 12
            : 12 + ((ringT - 0.55) / 0.45) * 10;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            body,
            if (!reduced && ringT > 0 && ringT < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: ringOpacity * 0.58),
                          blurRadius: 0,
                          spreadRadius: ringSpread,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        child: widget.child,
      ),
    );
  }

  List<double> _brightnessMatrix(double b) {
    return <double>[
      b, 0, 0, 0, 0,
      0, b, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
