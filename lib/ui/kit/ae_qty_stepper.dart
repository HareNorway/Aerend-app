import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/ae_typography.dart';
import 'ae_theme.dart';

/// Compact qty control — mirrors prototype `.mk-cstep` (cart sheet + checkout).
///
/// White circular +/- on a lavender pill track. [small] matches `.mk-cstep.sm`
/// used on checkout rows; default size matches the cart bottom sheet.
class AeQtyStepper extends StatelessWidget {
  const AeQtyStepper({
    super.key,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    this.theme,
    this.small = false,
  });

  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final AeThemePalette? theme;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final palette = theme ?? context.aeTheme;
    // `.mk-cstep` / `.mk-cstep.sm` — fixed design-px (375 frame).
    final btn = small ? 26.0 : 30.0;
    final iconSize = small ? 13.0 : 15.0;
    final numSize = small ? 13.0 : 14.0;
    final pad = small ? 2.0 : 3.0;
    final numMin = small ? 24.0 : 30.0;
    // Prototype uses solid `--ae-lavender`, not a translucent tint — alpha
    // washed the track out on white cards so only the white circles showed.
    final track = palette.background;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(
            Icons.remove_rounded,
            onDecrement,
            btn: btn,
            iconSize: iconSize,
            color: palette.primaryHover,
          ),
          SizedBox(
            width: numMin,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: aeLabel(color: palette.text).copyWith(
                fontSize: numSize,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
          ),
          _stepBtn(
            Icons.add_rounded,
            onIncrement,
            btn: btn,
            iconSize: iconSize,
            color: palette.primaryHover,
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(
    IconData icon,
    VoidCallback onTap, {
    required double btn,
    required double iconSize,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: btn,
        height: btn,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F2D1B5B),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
