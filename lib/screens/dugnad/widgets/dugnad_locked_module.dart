import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/reen_pre_club_theme.dart';
import '../../../theme/sc_saas_theme.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_state.dart';

/// Guest lock overlay — blurs + washes [child] and shows a lock pill.
/// When [locked] is false, returns [child] unchanged.
///
/// The blur is rendered via [ImageFiltered] directly on the child so there
/// is only ONE widget subtree — no GlobalKey conflicts.
///
/// [hBleed] (= column horizontal padding) lets the blur reach the screen edge.
/// The body's own [ClipRRect] (radius 24dp) handles the corner clipping.
class DugnadLockedModule extends StatelessWidget {
  const DugnadLockedModule({
    super.key,
    required this.locked,
    required this.label,
    required this.onUnlock,
    required this.child,
    this.hBleed = 0.0,
    this.vBleed = _defaultVBleed,
  });

  final bool locked;
  final String label;
  final VoidCallback onUnlock;
  final Widget child;

  /// Set to the column's horizontal padding so the blur reaches screen edges.
  final double hBleed;
  final double vBleed;

  /// Vertical bleed so the blur spills past section top/bottom edges,
  /// eliminating the hard border between sections.
  static const double _defaultVBleed = 16.0;

  /// No-club browse — a little vertical softness without the old 16dp overlap.
  static const double browseVBleed = 6.0;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final layoutW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : screenW;
        // Always bleed to the physical screen edges — never leave column gutters.
        final hBleed = math.max(
          context.dp(this.hBleed),
          (screenW - layoutW) / 2,
        );
        final vBleed = context.dp(this.vBleed);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(child: child),
              ),
            ),

            Positioned(
              left: -hBleed,
              right: -hBleed,
              top: -vBleed,
              bottom: -vBleed,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: _LockVeil(label: label, onUnlock: onUnlock),
            ),
          ],
        );
      },
    );
  }
}

class _LockVeil extends StatefulWidget {
  const _LockVeil({required this.label, required this.onUnlock});

  final String label;
  final VoidCallback onUnlock;

  @override
  State<_LockVeil> createState() => _LockVeilState();
}

class _LockVeilState extends State<_LockVeil> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onUnlock,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topPad = math.min(
              context.dp(44),
              constraints.maxHeight * 0.25,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.dp(12),
                topPad,
                context.dp(12),
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedScale(
                  scale: (_pressed && !reduce) ? 0.96 : 1,
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  child: _LockPill(
                    label: widget.label,
                    iconColor: DugnadState.instance.hasClub
                        ? theme.primaryHover
                        : ReenPreClubTokens.navy,
                    pressed: _pressed && !reduce,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LockPill extends StatelessWidget {
  const _LockPill({
    required this.label,
    required this.iconColor,
    required this.pressed,
  });

  final String label;
  final Color iconColor;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final labelColor = DugnadState.instance.hasClub
        ? ScSaasThemeTokens.text
        : ReenPreClubTokens.navy;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.dp(14),
        vertical: context.dp(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF140C28).withValues(alpha: 0.16),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF140C28)
                .withValues(alpha: pressed ? 0.5 : 0.45),
            offset: Offset(0, context.dp(pressed ? 12 : 8)),
            blurRadius: context.dp(pressed ? 26 : 20),
            spreadRadius: context.dp(pressed ? -10 : -8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: context.dp(13),
            color: iconColor,
          ),
          SizedBox(width: context.dp(7)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: aeLabel(color: labelColor)
                .copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12.5 * -0.01,
                  height: 1.2,
                )
                .dp(context),
          ),
        ],
      ),
    );
  }
}
