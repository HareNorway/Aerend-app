import 'package:flutter/material.dart';
import '../../../utils/utils.dart';
import '../theme/sc_saas_theme.dart';

class DiscountStar extends StatelessWidget {
  final int discount;
  final double scale;

  const DiscountStar({super.key, required this.discount, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image(
          height: 50 * scale,
          width: 50 * scale,
          image: const AssetImage('assets/images/discount_star.png'),
          color: ScSaasThemeTokens.primaryDarkMode,
          colorBlendMode: BlendMode.srcIn,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$discount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
                color: colorWhite,
              ),
            ),
            Baseline(
              baseline: 12 * scale,
              baselineType: TextBaseline.alphabetic,
              child: Text(
                '%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 7 * scale,
                  color: colorWhite,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
