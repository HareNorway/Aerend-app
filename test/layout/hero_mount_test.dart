import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_points_widgets.dart';
import 'package:aerend_customer/screens/dugnad/metal_hero_tokens.dart';
import 'package:aerend_customer/screens/dugnad/widgets/ae_metal_hero_surface.dart';
import 'package:aerend_customer/screens/dugnad/widgets/ae_metal_progress_bar.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_metal_animations.dart';

import 'reduced_motion_harness.dart';

/// `DugnadLevelHeroCard` painted its own ramp and its own single-layer shadow
/// while `AeMetalHeroSurface` and `AeMetalProgressBar` sat built, tested and
/// unused. This pins the mount so they cannot drift back apart.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Future<void> pumpHero(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DugnadClubThemeScope(
          palette: DugnadClubThemePalette.defaults,
          child: Scaffold(
            // Unbounded height, so the card sizes to its content. Under a
            // Scaffold it otherwise stretches to the full 812 frame, which is
            // the fault that hid the banner's inset stops (rule 22).
            body: SingleChildScrollView(
              child: SizedBox(
                width: 335,
                child: DugnadLevelHeroCard(
                  points: 1240,
                  tier: null,
                  nextTier: null,
                  progressPercent: 60,
                  pointsToNext: 300,
                  tierCount: 4,
                  activeTierIndex: 1,
                  stoRating: 72,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The glaze and the four bar timelines loop forever.
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('the hero mounts AeMetalHeroSurface at the hero scale',
      (tester) async {
    await pumpHero(tester);

    final surface = tester.widget<AeMetalHeroSurface>(
      find.byType(AeMetalHeroSurface),
    );
    // Not `home`. The two scales differ per tone and non-proportionally
    // (+0.05 on bronse, +0.15 on gull), so defaulting to home would quietly
    // dim the hero by an amount no single multiplier could restore.
    expect(surface.scale, AeMetalSurfaceScale.hero);
    expect(surface.radius, 20);
  });

  testWidgets('the hero paints both radials and the inset', (tester) async {
    await pumpHero(tester);

    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .toList();

    expect(
      decorations.where((d) => d.gradient is RadialGradient).length,
      greaterThanOrEqualTo(2),
      reason: 'the two off-canvas .lb-level-bg radials must paint — the ramp '
          'alone reads as coloured plastic',
    );

    final drop = decorations.firstWhere((d) => d.boxShadow != null).boxShadow!;
    // hero geometry: 0 18px 36px -16px
    expect(drop.first.offset.dy, closeTo(18, 0.5));
    expect(drop.first.blurRadius, closeTo(36, 0.5));
    expect(drop.first.spreadRadius, closeTo(-16, 0.5));
  });

  testWidgets('the old bar is gone from the hero', (tester) async {
    await pumpHero(tester);

    expect(find.byType(AeMetalProgressBar), findsOneWidget);
    expect(
      find.byType(DugnadAnimatedMetalProgressBar),
      findsNothing,
      reason: 'the single-tween bar must not come back alongside the '
          'four-timeline one',
    );

    expect(
      tester.widget<AeMetalProgressBar>(find.byType(AeMetalProgressBar)).value,
      closeTo(0.60, 0.001),
      reason: 'progressPercent is 0..100 and the bar takes 0..1',
    );
  });

  testWidgets('the hero does not stretch to the frame', (tester) async {
    await pumpHero(tester);
    final h = tester.getSize(find.byType(DugnadLevelHeroCard)).height;
    expect(h, lessThan(400),
        reason: 'a stretched card silently drives every 1/H inset stop into '
            'the clamp floor');
  });
}
