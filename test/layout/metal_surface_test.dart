import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/metal_hero_tokens.dart';
import 'package:aerend_customer/screens/dugnad/points_metal_theme.dart';
import 'package:aerend_customer/screens/dugnad/widgets/ae_metal_hero_surface.dart';

/// Family A (`.lb-level.metal-*` / `M_BG`) structural guards.
///
/// The premium read comes from layers that are easy to drop silently when
/// porting: the two off-canvas radial overlays, the faked `inset` highlight,
/// and the 48% ramp midpoint. None of these change geometry, so no layout
/// assertion catches them — hence a paint-structure test.
void main() {
  const tones = ['bronse', 'solv', 'gull', 'platina'];

  group('tone tokens', () {
    for (final tone in tones) {
      test('$tone carries the full token set', () {
        final t = AeMetalHeroTokens.forMetal(tone);

        // 3-stop ramp with the 48% midpoint — a 2-stop ramp looks plastic.
        expect(t.ramp, hasLength(3), reason: '$tone ramp must be 3 stops');
        expect(t.background.stops, [0.0, 0.48, 1.0]);
        expect(t.background.begin, Alignment.topLeft);
        expect(t.background.end, Alignment.bottomRight); // 135deg

        // Both radial overlays must be present and visible.
        expect(t.specular.a, greaterThan(0), reason: '$tone specular dropped');
        expect(t.bounce.a, greaterThan(0), reason: '$tone bounce dropped');

        // The faked inset highlight, per surface.
        expect(t.insetHighlightHome.a, greaterThan(0));
        expect(t.insetHighlightHero.a, greaterThan(0));

        // Tone-tinted drop — never the brand purple, never neutral black.
        expect(t.dropTint.a, greaterThan(0));

        // The remaining tone-keyed tokens.
        expect(t.progFill, hasLength(2));
        expect(t.progressFill.begin, Alignment.centerLeft); // 90deg
        for (final c in [
          t.text,
          t.badgeBg,
          t.badgeBorder,
          t.badgeText,
          t.progTrack,
          t.stepOff,
          t.stepOn,
        ]) {
          expect(c, isA<Color>());
        }
      });
    }

    test('gold text is near-black, not white', () {
      // #2a1d08 — getting this wrong makes the card unreadable rather than
      // merely off.
      expect(AeMetalHeroTokens.forMetal('gull').text, const Color(0xFF2A1D08));
    });

    test('platina alone overrides the shine, with a purple pass', () {
      expect(AeMetalHeroTokens.forMetal('platina').shine, isNotNull);
      expect(AeMetalHeroTokens.forMetal('platina').shine!.colors, hasLength(4));
      for (final tone in ['bronse', 'solv', 'gull']) {
        expect(AeMetalHeroTokens.forMetal(tone).shine, isNull, reason: tone);
      }
    });

    test('the season card consumes Family A rather than deriving it', () {
      // `.dg-seasoncard.metal-*` is the sixth surface in this family, and it
      // was synthesising its ramp by lightening and darkening a base colour --
      // landing near the real stops without matching them. The ladder step had
      // the same fault, so this is the second synthesised copy.
      for (final tone in tones) {
        expect(
          PointsMetalTheme.seasonCardForMetal(tone).gradient,
          AeMetalHeroTokens.forMetal(tone).ramp,
          reason: '\$tone season card must use Family A, not a derivation',
        );
      }
    });

    test('ramps are byte-identical to M_BG', () {
      // .lb-level.metal-bronse == M_BG.bronze, which is what makes home and
      // the Dine poeng hero one family rather than two.
      expect(AeMetalHeroTokens.forMetal('bronse').ramp, const [
        Color(0xFFF1CDA1),
        Color(0xFFDCA06B),
        Color(0xFFBD7D44),
      ]);
      expect(AeMetalHeroTokens.forMetal('gull').ramp, const [
        Color(0xFFFFE9A8),
        Color(0xFFF6CF6B),
        Color(0xFFE7B542),
      ]);
    });
  });

  group('surface paints every layer', () {
    for (final tone in tones) {
      testWidgets('$tone renders ramp + 2 radials + inset', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 327,
                  height: 140,
                  child: AeMetalHeroSurface(
                    metal: tone,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gradients = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .toList();

        final radials =
            gradients.where((d) => d.gradient is RadialGradient).length;
        final linears =
            gradients.where((d) => d.gradient is LinearGradient).length;

        expect(radials, greaterThanOrEqualTo(2),
            reason: '$tone: both .lb-level-bg radials must paint');
        expect(linears, greaterThanOrEqualTo(2),
            reason: '$tone: ramp + faked inset highlight must paint');

        // The outer drop must survive, and be tone-tinted.
        final shadowed = gradients.where((d) => d.boxShadow != null).toList();
        expect(shadowed, isNotEmpty, reason: '$tone: drop shadow dropped');
        expect(shadowed.first.boxShadow!.first.color,
            AeMetalHeroTokens.forMetal(tone).dropTint);
        // CSS spread is negative and must not be omitted.
        expect(shadowed.first.boxShadow!.first.spreadRadius, lessThan(0));
      });
    }

    testWidgets('radial centres sit off-canvas', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 327,
                height: 140,
                child: AeMetalHeroSurface(
                  metal: 'gull',
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      final radials = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<RadialGradient>()
          .toList();

      expect(radials, hasLength(2));
      // 88% -25% and 2% 130% both fall outside the 0..1 box; that is what
      // throws the highlight in from the corner rather than centring a blob.
      final centres = radials.map((g) => g.center as Alignment).toList();
      expect(centres.any((c) => c.y < -1), isTrue, reason: 'specular');
      expect(centres.any((c) => c.y > 1), isTrue, reason: 'bounce');
    });
  });

  group('two surface scales, eight cases', () {
    // Family A is one ramp set with two surface scales: the hero is
    // consistently brighter with a larger drop. A single multiplier cannot
    // express it — the delta is +0.05 on bronse but +0.15 on gull — so both
    // are pinned per tone per surface.
    const expected = <String, List<double>>{
      //            home, hero
      'bronse':   [0.55, 0.60],
      'solv':     [0.75, 0.85],
      'gull':     [0.60, 0.75],
      'platina':  [0.75, 0.85],
    };

    expected.forEach((tone, alphas) {
      test('$tone inset alpha differs between home and hero', () {
        final t = AeMetalHeroTokens.forMetal(tone);
        expect(t.insetFor(AeMetalSurfaceScale.home).a,
            closeTo(alphas[0], 0.005),
            reason: '$tone home inset');
        expect(t.insetFor(AeMetalSurfaceScale.hero).a,
            closeTo(alphas[1], 0.005),
            reason: '$tone hero inset');
        // The hero must stay the brighter of the two.
        expect(t.insetFor(AeMetalSurfaceScale.hero).a,
            greaterThan(t.insetFor(AeMetalSurfaceScale.home).a),
            reason: '$tone: the two scales have drifted together');
      });
    });

    for (final tone in tones) {
      testWidgets('$tone drop geometry differs by surface', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        Future<BoxShadow> dropFor(AeMetalSurfaceScale scale) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 327,
                    height: 140,
                    child: AeMetalHeroSurface(
                      metal: tone,
                      scale: scale,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .map((d) => d.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.boxShadow != null)
              .boxShadow!
              .first;
        }

        final home = await dropFor(AeMetalSurfaceScale.home);
        final hero = await dropFor(AeMetalSurfaceScale.hero);

        // home 0 14px 26px -16px, hero 0 18px 36px -16px
        expect(home.offset.dy, closeTo(14, 0.5), reason: '$tone home dy');
        expect(home.blurRadius, closeTo(26, 0.5), reason: '$tone home blur');
        expect(hero.offset.dy, closeTo(18, 0.5), reason: '$tone hero dy');
        expect(hero.blurRadius, closeTo(36, 0.5), reason: '$tone hero blur');
        expect(home.spreadRadius, closeTo(-16, 0.5));
        expect(hero.spreadRadius, closeTo(-16, 0.5));
        // Same tone tint on both — only the geometry and inset scale.
        expect(home.color, hero.color);
      });
    }
  });
}
