import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// A paper card (design `.kort`): warm gradient, 20px radius, soft shadow and
/// the 1px inner highlight on top. Tap-able when [onTap] is given.
class BergenCard extends StatelessWidget {
  const BergenCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.onDark = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Glass variant for cards on the teal screen gradient.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(BergenTokens.radiusCard);

    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: onDark ? null : BergenTokens.card,
        color: onDark ? BergenTokens.glassFill : null,
        borderRadius: radius,
        border: Border.all(
          color: onDark ? BergenTokens.glassBorder : BergenTokens.paperWarm,
        ),
        boxShadow: onDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A0F1F2B),
                  offset: Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: .6),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return body;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: body),
    );
  }
}
