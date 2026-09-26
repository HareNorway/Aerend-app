import 'package:flutter/material.dart';

import '../../common/home/bergen/bergen_kit.dart' show kBergenOrangeGradient;
import '../kit/bergen_kit.dart';
import 'a3_scaffold.dart';

/// The orange pill the Meg tab uses for Del / Godta / Premiehylla — the same
/// gradient and drop shadow as the shell's bottom-nav "Meg" pill, so every
/// primary button on the tab reads as one control.
class MegPill extends StatelessWidget {
  const MegPill({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 44,
    this.fontSize = BergenTokens.textBody,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: expand ? 18 : 16),
          decoration: BoxDecoration(
            gradient: enabled ? kBergenOrangeGradient : null,
            color: enabled ? null : BergenTokens.glassFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? .4 : .15)),
            boxShadow: enabled
                ? [
                    const BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 1.5)),
                    const BoxShadow(color: Color.fromRGBO(120, 50, 10, .9), offset: Offset(0, 8), blurRadius: 14, spreadRadius: -8),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: BergenTokens.display(fontSize, weight: FontWeight.w800, color: enabled ? Colors.white : A3Ink.muted)))),
              if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 18, color: enabled ? Colors.white : A3Ink.muted)],
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// The white pill next to it ("Ikke dette").
class MegPillGhost extends StatelessWidget {
  const MegPillGhost({super.key, required this.label, this.onPressed, this.height = 44});

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 4), blurRadius: 10, spreadRadius: -4)],
          ),
          child: Center(child: Text(label, style: BergenTokens.display(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.ink))),
        ),
      ),
    );
  }
}
