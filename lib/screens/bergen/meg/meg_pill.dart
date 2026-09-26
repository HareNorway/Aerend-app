import 'package:flutter/material.dart';

import '../kit/bergen_kit.dart';
import 'a3_scaffold.dart';

/// The two orange pills the design uses on Meg.
///
/// [MegPillStyle.cta] is `.cta3d` (Del, Godta, Hent premien): the light-to-deep
/// orange face standing on a `#C4491A` ridge. [MegPillStyle.nav] is the shell's
/// bottom-nav / Premiehylla pill: `linear-gradient(160deg,#F2884E,#E0662C)`
/// with the inset top highlight and the darker ridge.
enum MegPillStyle { cta, nav }

class MegPill extends StatelessWidget {
  const MegPill({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 44,
    this.fontSize = BergenTokens.textBody,
    this.style = MegPillStyle.cta,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;
  final double fontSize;
  final MegPillStyle style;

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9A273), Color(0xFFF26D3D), Color(0xFFDD5A25)],
    stops: [0, .56, 1],
  );

  static const LinearGradient navGradient = LinearGradient(
    begin: Alignment(-.34, -.94),
    end: Alignment(.34, .94),
    colors: [Color(0xFFF2884E), Color(0xFFE0662C)],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final cta = style == MegPillStyle.cta;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: expand ? 18 : 13),
          decoration: BoxDecoration(
            gradient: enabled ? (cta ? ctaGradient : navGradient) : null,
            color: enabled ? null : BergenTokens.glassFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: enabled ? (cta ? .5 : .35) : .15)),
            boxShadow: !enabled
                ? null
                : cta
                    ? const [
                        BoxShadow(color: Color(0xFFC4491A), offset: Offset(0, 1.5)),
                        BoxShadow(color: Color.fromRGBO(120, 45, 15, .42), offset: Offset(0, 3)),
                        BoxShadow(color: Color.fromRGBO(200, 70, 25, .8), offset: Offset(0, 8), blurRadius: 12, spreadRadius: -8),
                      ]
                    : const [
                        BoxShadow(color: Color.fromRGBO(150, 60, 15, .8), offset: Offset(0, 3)),
                        BoxShadow(color: Color.fromRGBO(120, 50, 10, .9), offset: Offset(0, 14), blurRadius: 22, spreadRadius: -12),
                      ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: BergenTokens.display(fontSize, weight: FontWeight.w800, color: enabled ? Colors.white : A3Ink.muted, letterSpacingEm: -0.01)))),
              if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: fontSize + 2, color: enabled ? Colors.white : A3Ink.muted)],
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// The white pill next to Godta ("Ikke dette").
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
            boxShadow: const [
              BoxShadow(color: Color(0xFFE7DCC0), offset: Offset(0, 1.5)),
              BoxShadow(color: Color(0x33000000), offset: Offset(0, 6), blurRadius: 10, spreadRadius: -6),
            ],
          ),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: BergenTokens.display(BergenTokens.textSmall, weight: FontWeight.w800, color: BergenTokens.ink)))),
        ),
      ),
    );
  }
}
