import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenAssets, bergenSvg;
import '../kit/bergen_kit.dart';

/// The Meg header scene (design `meg` ≈L5912, symbol `#sc-ulr1`): Ulriken,
/// the Fløibanen wires, the varde, the houses and Brann stadion, exported
/// from the design file to `assets/svgs/dashboard/meg_stadium.svg`, with
/// Ægil and the goal bubble ("20 poeng til gratis pizza.").
class MegHero extends StatelessWidget {
  const MegHero({super.key, required this.bubble, this.height = 210});

  final String bubble;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('meg-hero'),
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9FB6C2), Color(0xFF6E8E9C), BergenTokens.tealLight],
                stops: [0, .55, 1],
              ),
            ),
          ),
          Positioned.fill(child: bergenSvg('meg_stadium', fit: BoxFit.cover)),
          Positioned(
            right: 8,
            top: 44,
            width: 190,
            child: AegilSays(
              asset: BergenAssets.aegilPopup,
              text: bubble,
              avatarSize: 56,
              showLabel: false,
              floorShadow: false,
              delayMs: 0,
            ),
          ),
        ],
      ),
    );
  }
}
