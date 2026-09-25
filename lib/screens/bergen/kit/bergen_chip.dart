import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// A Bergen pill chip (design `.chip`): teal-glass on dark surfaces, paper on
/// light ones; the selected state turns orange. Used for filters, tags and the
/// Points placeholder.
class BergenChip extends StatelessWidget {
  const BergenChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onDark = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  /// True when the chip sits on the teal screen gradient.
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = selected
        ? BergenTokens.orange
        : onDark
        ? BergenTokens.glassFill
        : BergenTokens.paperBright;
    final Color fg = selected || onDark ? Colors.white : BergenTokens.ink;
    final Color border = selected
        ? BergenTokens.orangeDeep
        : onDark
        ? BergenTokens.glassBorder
        : BergenTokens.paperWarm;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BergenTokens.radiusChip),
          child: AnimatedContainer(
            duration: BergenTokens.motion(context, BergenTokens.motionFast),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(BergenTokens.radiusChip),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: BergenTokens.text(
                    BergenTokens.textSmall,
                    weight: FontWeight.w700,
                    color: fg,
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
