import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/design_scale.dart';
import '../../utils/utils.dart';
import 'mode_sheet.dart';

/// Compact mode indicator: heart + "Dugnad" + chevron.
/// Taps open [showModeSheet].
///
/// Design spec: dugnad/auth.jsx → ModeChip.
/// Use [light] = true when placed on a dark (purple hero) background.
class ModeChip extends StatelessWidget {
  final bool light;

  const ModeChip({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModeSheet(context);
      },
      // `.dg-modechip { height: 36px; padding: 0 12px; gap: 6px;
      // font-size: 13px; font-weight: 800; letter-spacing: -0.01em }`
      // The old 5px vertical padding gave ~26px — a third short of the design.
      child: Container(
        height: context.dp(36),
        padding: EdgeInsets.symmetric(horizontal: context.dp(12)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: light
              ? Colors.white.withValues(alpha: 0.20)
              : const Color(0xFFE8DEF5), // primaryTint
          borderRadius: BorderRadius.circular(999),
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: 0.28))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svgs/menu/heart.svg',
              width: context.dp(13),
              height: context.dp(13),
              colorFilter: ColorFilter.mode(
                light ? Colors.white : const Color(0xFF7F5FC4),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: context.dp(6)),
            Text(
              languages.dugnadModeDugnad,
              style: TextStyle(
                color: light ? Colors.white : const Color(0xFF7F5FC4),
                fontSize: context.dp(13),
                fontWeight: FontWeight.w800,
                letterSpacing: context.dp(13) * -0.01,
                height: 1,
              ),
            ),
            SizedBox(width: context.dp(6)),
            Icon(
              Icons.expand_more_rounded,
              color: light ? Colors.white70 : const Color(0xFF7F5FC4),
              size: context.dp(14),
            ),
          ],
        ),
      ),
    );
  }
}
