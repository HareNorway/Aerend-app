import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/ui/kit/ae_rise_in.dart';
import 'package:aerend_customer/screens/dugnad/widgets/ae_metal_progress_bar.dart';

import 'package:aerend_customer/screens/dugnad/widgets/dugnad_metal_animations.dart';

import 'package:aerend_customer/screens/dugnad/widgets/dugnad_points_earn.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_prize_banner.dart';

import 'package:aerend_customer/screens/dugnad/dugnad_models.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_welcome_screen.dart';
import 'package:aerend_customer/screens/dugnad/tier_level_up_screen.dart';
import 'package:aerend_customer/ui/kit/ae_subpage_shell.dart';

import 'reduced_motion_harness.dart';

const _bronse = MetalTierInfo(
  key: 'bronse',
  metal: 'bronse',
  minPoints: 0,
  labelNo: 'Bronse',
  titleSuffix: 'Bronse',
  colorHex: '#B06F3D',
  achieved: true,
);
const _solv = MetalTierInfo(
  key: 'solv',
  metal: 'solv',
  minPoints: 100,
  labelNo: 'Sølv',
  titleSuffix: 'Sølv',
  colorHex: '#9AA6B2',
  achieved: true,
);

void main() {
  setUpAll(bootstrapGlobals);

  testWidgets('AeRiseIn respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const AeRiseIn(
        delay: Duration(milliseconds: 300),
        child: Text('x'),
      ),
      longestDelay: const Duration(milliseconds: 900),
    );
  });

  testWidgets('AeRiseIn with no delay respects reduced motion',
      (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const AeRiseIn(child: Text('x')),
    );
  });

  testWidgets('AePulseIcon respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const AePulseIcon(child: Icon(Icons.star)),
      longestDelay: const Duration(seconds: 6),
    );
  });

  testWidgets('AeBreathe respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const AeBreathe(child: Text('x')),
      longestDelay: const Duration(seconds: 6),
    );
  });

  testWidgets('AeMetalProgressBar respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(
        width: 300,
        child: AeMetalProgressBar(metal: 'gull', value: 0.6),
      ),
      longestDelay: const Duration(seconds: 4),
    );
  });

  testWidgets('DugnadMetalGlazeOverlay respects reduced motion',
      (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(
        width: 300,
        height: 120,
        child: DugnadMetalGlazeOverlay(),
      ),
      longestDelay: const Duration(seconds: 5),
    );
  });

  testWidgets('DugnadEmblemSheen respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(
        width: 80,
        height: 80,
        child: DugnadEmblemSheen(child: SizedBox.expand()),
      ),
      longestDelay: const Duration(seconds: 5),
    );
  });

  testWidgets('DugnadCarryoverFlyGraphic respects reduced motion',
      (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(
        width: 200,
        height: 120,
        child: DugnadCarryoverFlyGraphic(dotColor: Color(0xFFD8A92E)),
      ),
      longestDelay: const Duration(seconds: 5),
    );
  });

  // Unblocked by bootstrapGlobals — both read `languages` / prefs.
  testWidgets('DugnadPointsEarn respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(
        width: 320,
        child: DugnadPointsEarn(points: 50, title: 'T', subtitle: 'S'),
      ),
      longestDelay: const Duration(seconds: 8),
    );
  });

  testWidgets('DugnadPrizeBanner respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const SizedBox(width: 320, child: DugnadPrizeBanner(label: 'L', title: 'T', subtitle: 'S')),
      longestDelay: const Duration(seconds: 10),
    );
  });

  // Two celebration screens that ran 3 and 2 controllers ungated — under
  // reduced motion they now land at the result and start nothing.
  testWidgets('DugnadWelcomeScreen respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const DugnadWelcomeScreen(),
      longestDelay: const Duration(seconds: 3),
    );
  });

  // Shared feed-item entrance reached every subpage feed ungated.
  testWidgets('AeFeedEnter respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => const AeFeedEnter(index: 3, child: Text('x')),
      longestDelay: const Duration(seconds: 1),
    );
  });

  testWidgets('TierLevelUpScreen respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(
      tester,
      () => TierLevelUpScreen(
        fromTier: _bronse,
        toTier: _solv,
        fromStoRating: 40,
        toStoRating: 62,
        points: 1200,
        displayName: 'Test',
        purchases: 3,
        referrals: 1,
        onDone: () {},
      ),
      longestDelay: const Duration(seconds: 3),
    );
  });
}
