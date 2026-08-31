import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../ui/kit/ae_theme.dart';
import 'dugnad_metal_animations.dart';

/// Season prize banner — mirrors `.lb-prize-banner` in `dugnad/gamify.css`.
///
/// Gradient: dark club theme → faint, with a clean diagonal `lb-sheen` sweep
/// (not metal glaze).
class DugnadPrizeBanner extends StatefulWidget {
  const DugnadPrizeBanner({
    super.key,
    required this.label,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String label;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<DugnadPrizeBanner> createState() => _DugnadPrizeBannerState();
}

class _DugnadPrizeBannerState extends State<DugnadPrizeBanner>
    with SingleTickerProviderStateMixin {
  static const _radius = 18.0;
  static const _duration = Duration(milliseconds: 8400);
  static const _delay = Duration(milliseconds: 500);

  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(vsync: this, duration: _duration);
  }

  Timer? _delayTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion must prevent the controller starting, not merely hide
    // its output — see docs/claude-design-to-flutter.md rule 16.
    if (MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      if (_sheen.isAnimating) _sheen.stop();
      _sheen.value = 0;
      return;
    }
    if (_sheen.isAnimating || _delayTimer != null) return;
    // The original 500ms animation-delay, now cancellable.
    _delayTimer = Timer(_delay, () {
      if (!mounted) return;
      _sheen.repeat();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;
    // Figma: linear-gradient(135deg, dark theme → faint club color)
    // Keep faint end on-theme — do not bleach with white (that causes right-side fog).
    final dark = theme.primaryHover;
    final faint = theme.primarySoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [dark, faint],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.text.withValues(alpha: 0.55),
                blurRadius: context.dp(26),
                offset: const Offset(0, 12),
                spreadRadius: -16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                // Soft radial highlight (`.lb-prize-banner-bg`) — subtle only.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.9, -0.7),
                          radius: 0.55,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                // Clean diagonal sheen (`.lb-prize-banner-shine` + `lb-sheen`)
                if (!MediaQuery.disableAnimationsOf(context))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _sheen,
                        builder: (context, _) {
                          final s = dugnadLbSheenAt(_sheen.value);
                          if (s.opacity <= 0.01) {
                            return const SizedBox.shrink();
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final bandW = constraints.maxWidth * 0.42;
                              return OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: constraints.maxWidth * 3.2,
                                child: Transform.translate(
                                  offset: Offset(s.xFactor * bandW, 0),
                                  child: Transform(
                                    transform: Matrix4.skewX(-0.28),
                                    alignment: Alignment.center,
                                    child: Opacity(
                                      opacity: (s.opacity * 0.7).clamp(0.0, 1.0),
                                      child: Container(
                                        width: bandW,
                                        height: constraints.maxHeight,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withValues(
                                                alpha: 0.32,
                                              ),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.22, 0.5, 0.78],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(context.dp(17), context.dp(15), context.dp(17), context.dp(15)),
                  child: Row(
                    children: [
                      Text(
                        '🏆',
                        style: TextStyle(fontSize: 26, height: context.dp(1)),
                      ),
                      SizedBox(width: context.dp(13)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 10.5 * 0.09,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            SizedBox(height: context.dp(1)),
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AeDugnadText.bannerTitle(
                                color: Colors.white,
                              ).copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: context.dp(1)),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AeDugnadText.bannerSubtitle(
                                color: Colors.white.withValues(alpha: 0.85),
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      Container(
                        width: context.dp(30),
                        height: context.dp(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: context.dp(18),
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
