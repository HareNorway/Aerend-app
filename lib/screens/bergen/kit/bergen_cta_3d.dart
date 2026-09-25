import 'package:flutter/material.dart';

import '../../../theme/bergen_tokens.dart';

/// The orange 3D button (design `.cta3d`): a gradient face standing on a
/// darker edge; pressing sinks the face onto the edge. Full-width by default.
class BergenCta3d extends StatefulWidget {
  const BergenCta3d({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  static const double edge = 4;

  @override
  State<BergenCta3d> createState() => _BergenCta3dState();
}

class _BergenCta3dState extends State<BergenCta3d> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final lift = _down || !enabled ? 0.0 : BergenCta3d.edge;

    final face = AnimatedContainer(
      duration: BergenTokens.motion(context, BergenTokens.motionFast),
      transform: Matrix4.translationValues(0, BergenCta3d.edge - lift, 0),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      decoration: BoxDecoration(
        gradient: enabled ? BergenTokens.cta : null,
        color: enabled ? null : BergenTokens.inkFaint,
        borderRadius: BorderRadius.circular(BergenTokens.radiusButton),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: BergenTokens.display(
              BergenTokens.textBody,
              weight: FontWeight.w800,
              color: Colors.white,
              letterSpacingEm: -0.01,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Container(
          margin: const EdgeInsets.only(bottom: BergenCta3d.edge),
          decoration: BoxDecoration(
            color: enabled ? BergenTokens.orangeDeep : BergenTokens.inkMuted,
            borderRadius: BorderRadius.circular(BergenTokens.radiusButton),
          ),
          child: face,
        ),
      ),
    );
  }
}
