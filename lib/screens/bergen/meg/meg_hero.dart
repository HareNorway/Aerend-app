import 'package:flutter/material.dart';

import '../../common/auth/onboarding_kit.dart';
import '../../common/home/bergen/bergen_kit.dart' show BergenAssets, bergenSvg;
import '../../common/home/bergen/bergen_painters.dart';
import '../kit/bergen_kit.dart';

/// The Meg header scene (design `meg` ≈L5912): the Bergen sky, the mountains
/// and the Bryggen skyline from the Hjem kit, with Ægil and the goal bubble
/// ("20 poeng til gratis pizza."). The design draws Brann stadion here; the
/// app reuses the Hjem scene until that illustration is exported.
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
          Positioned(
            left: -20,
            right: -20,
            bottom: 52,
            child: Opacity(opacity: .9, child: bergenSvg('scene_mountains', height: 120, fit: BoxFit.fill)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const SizedBox(
              height: 76,
              child: CustomPaint(painter: BergenHousesPainter(dim: .1)),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 22,
            width: 220,
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
