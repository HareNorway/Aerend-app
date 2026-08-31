import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/ui/kit/ae_theme.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_feed_entry_banner.dart';

/// `DugnadFeedEntryBanner` paints five of home's nine feed cards, and every
/// visual property varies per variant. It previously gave all five the *same*
/// `blur 28, offset 14, spread -14` shadow at alpha `.32-.42` — a house default
/// standing in for five different design values (rule 20).
///
/// These pin each variant against its own rule. The two assertions that matter
/// most are structural rather than numeric: that the five shadows stay mutually
/// distinct, and that the two variants with **no** inset never acquire one.
void main() {
  const variants = DugnadFeedEntryVariant.values;

  /// Rendered at the 375 reference frame, where `ds == 1.0` and every value
  /// must equal its literal design px (rule 11).
  Future<void> pumpBanner(
    WidgetTester tester,
    DugnadFeedEntryVariant variant, {
    AeThemePalette? palette,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AeThemeScope(
          palette: palette ?? AeThemePalette.defaults,
          child: Scaffold(
            // Unbounded height so the banner sizes to its content; under a
            // Scaffold it otherwise stretches to the full 812 frame, which
            // would make every 1/H inset stop hit the clamp floor.
            body: SingleChildScrollView(
              child: SizedBox(
                // `.h-feed` padding is 24 20 132, so the column is 375-40.
                width: 335,
                child: DugnadFeedEntryBanner(
                  title: 'Tittel',
                  subtitle: 'Undertekst',
                  onTap: () {},
                  variant: variant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The metal glaze overlays loop forever, so pumpAndSettle would never
    // return. One frame is enough — nothing under test is animated.
    await tester.pump(const Duration(milliseconds: 50));
  }

  BoxDecoration cardDecoration(WidgetTester tester) =>
      tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;

  LinearGradient? insetGradient(WidgetTester tester, Key key) {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) return null;
    return tester.widget<DecoratedBox>(finder).decoration
        is BoxDecoration
        ? (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration)
            .gradient as LinearGradient?
        : null;
  }

  group('drop shadows', () {
    // variant -> (alpha, dy, blur, spread)
    const expected = <DugnadFeedEntryVariant, List<double>>{
      DugnadFeedEntryVariant.leagueGold: [0.82, 16, 30, -16],
      DugnadFeedEntryVariant.missionsPurple: [0.60, 14, 28, -14],
      DugnadFeedEntryVariant.transferDark: [0.60, 16, 30, -14],
      DugnadFeedEntryVariant.referralPurple: [0.70, 16, 30, -16],
      DugnadFeedEntryVariant.supportLight: [0.45, 14, 28, -18],
    };

    expected.forEach((variant, want) {
      testWidgets('${variant.name} carries its own drop', (tester) async {
        await pumpBanner(tester, variant);
        final shadows = cardDecoration(tester).boxShadow!;

        expect(shadows, hasLength(1),
            reason: '${variant.name}: the drop is one layer; the inset layers '
                'are painted inside the clip, not appended here');
        final s = shadows.single;
        expect(s.color.a, closeTo(want[0], 0.005), reason: 'alpha');
        expect(s.offset.dy, closeTo(want[1], 0.01), reason: 'offset-y');
        expect(s.blurRadius, closeTo(want[2], 0.01), reason: 'blur');
        expect(s.spreadRadius, closeTo(want[3], 0.01), reason: 'spread');
        // A negative spread is the 4th CSS length and is easy to drop; without
        // it the shadow is far too wide.
        expect(s.spreadRadius, lessThan(0));
      });
    });

    testWidgets('the five shadows are mutually distinct', (tester) async {
      final seen = <String, String>{};
      for (final variant in variants) {
        await pumpBanner(tester, variant);
        final s = cardDecoration(tester).boxShadow!.single;
        final key = '${s.color.toARGB32()}|${s.offset.dy}|'
            '${s.blurRadius}|${s.spreadRadius}';
        expect(seen.containsKey(key), isFalse,
            reason: '${variant.name} has the same shadow as ${seen[key]} — a '
                'house default has returned');
        seen[key] = variant.name;
      }
      expect(seen, hasLength(5));
    });
  });

  group('inset layers', () {
    testWidgets('leagueGold has a top highlight and a bottom tint',
        (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.leagueGold);

      final top = insetGradient(tester, kEntryInsetTopKey);
      expect(top, isNotNull, reason: 'top inset dropped');
      expect(top!.colors.first.a, closeTo(0.90, 0.005));
      expect(top.colors.last.a, 0, reason: 'must fade to transparent');
      expect(top.begin, Alignment.topCenter);
      // A 1px inset spans 1/H of whatever the card actually lays out to —
      // not of a measured constant, since these cards change height with the
      // copy they are given.
      // Measured on the inset layer itself, not the card: a bordered variant
      // paints its inset inside the border, so the two differ by the border.
      final h = tester.getSize(find.byKey(kEntryInsetTopKey)).height;
      expect(top.stops!.last, closeTo(1 / h, 0.0005));

      final bottom = insetGradient(tester, kEntryInsetBottomKey);
      expect(bottom, isNotNull, reason: 'bottom inset dropped');
      expect(bottom!.colors.first.a, closeTo(0.16, 0.005));
      // The negative y-offset anchors this one to the bottom edge; painting it
      // from the top would put a warm band across the wrong side of the card.
      expect(bottom.begin, Alignment.bottomCenter);
      expect(bottom.end, Alignment.topCenter);
      expect(bottom.stops!.last,
          closeTo(18 / tester.getSize(find.byKey(kEntryInsetBottomKey)).height,
              0.0005));
    });

    testWidgets('referralPurple and supportLight have a top highlight only',
        (tester) async {
      for (final entry in {
        DugnadFeedEntryVariant.referralPurple: 0.35,
        DugnadFeedEntryVariant.supportLight: 0.60,
      }.entries) {
        await pumpBanner(tester, entry.key);
        final top = insetGradient(tester, kEntryInsetTopKey);
        expect(top, isNotNull, reason: '${entry.key.name} top inset dropped');
        expect(top!.colors.first.a, closeTo(entry.value, 0.005),
            reason: entry.key.name);
        final h = tester.getSize(find.byKey(kEntryInsetTopKey)).height;
        expect(top.stops!.last, closeTo(1 / h, 0.0005),
            reason: entry.key.name);
        expect(find.byKey(kEntryInsetBottomKey), findsNothing,
            reason: '${entry.key.name} must not gain a bottom tint');
      }
    });

    testWidgets('missionsPurple and transferDark have NO inset',
        (tester) async {
      // Two of five carry no inset. That is deliberate, and a later pass
      // "helpfully" normalising them would flatten the distinction the design
      // draws between the lit cards and the matte ones.
      for (final variant in [
        DugnadFeedEntryVariant.missionsPurple,
        DugnadFeedEntryVariant.transferDark,
      ]) {
        await pumpBanner(tester, variant);
        expect(find.byKey(kEntryInsetTopKey), findsNothing,
            reason: '${variant.name} gained a top inset');
        expect(find.byKey(kEntryInsetBottomKey), findsNothing,
            reason: '${variant.name} gained a bottom inset');
      }
    });
  });

  group('gradients', () {
    testWidgets('leagueGold keeps #f7cf6b at the 55% midpoint', (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.leagueGold);
      final g = cardDecoration(tester).gradient! as LinearGradient;

      expect(g.colors, const [
        Color(0xFFFFE9A8),
        Color(0xFFF7CF6B), // NOT #f6cf6b — that is the metal family's gold
        Color(0xFFEEBB44),
      ]);
      expect(g.stops, const [0.0, 0.55, 1.0]);
      expect(g.begin, Alignment.topLeft); // 135deg
      expect(g.end, Alignment.bottomRight);
    });

    testWidgets('missionsPurple is two stops, straight from the tokens',
        (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.missionsPurple);
      final g = cardDecoration(tester).gradient! as LinearGradient;
      final theme = AeThemePalette.defaults;

      // `.me-bg` is linear-gradient(135deg, --ae-purple-600, --ae-purple-500).
      // There is no third colour and no gloss layer to justify one.
      expect(g.colors, hasLength(2),
          reason: 'a third interpolated stop has come back');
      expect(g.colors, theme.feedMissionsGradient.colors);
      expect(g.colors.first, theme.primary);
      expect(g.stops, isNull);
      expect(g.begin, Alignment.topLeft);
    });

    testWidgets('transferDark shades the club primary, not a hardcoded hue',
        (tester) async {
      final club = AeThemePalette.resolve(accentColor: '#E86657');
      await pumpBanner(
        tester,
        DugnadFeedEntryVariant.transferDark,
        palette: club,
      );
      final g = cardDecoration(tester).gradient! as LinearGradient;
      final expected = club.feedTransferGradient;

      expect(g.colors, expected.colors);
      expect(g.colors.last, club.primary);
      expect(g.colors.first, isNot(club.text));
      expect(g.colors.first, isNot(const Color(0xFF2D1B5B)));

      final start = HSLColor.fromColor(g.colors.first);
      final accent = HSLColor.fromColor(club.primary);
      final hueDelta = (start.hue - accent.hue).abs();
      expect(hueDelta < 20 || hueDelta > 340, isTrue,
          reason: 'transfer start must stay in the admin hue');
      expect(start.lightness, lessThan(accent.lightness));
    });

    testWidgets('referralPurple carries its child radial overlay',
        (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.referralPurple);

      final box = tester.widget<DecoratedBox>(
        find.byKey(kEntryRadialOverlayKey),
      );
      final g = (box.decoration as BoxDecoration).gradient! as RadialGradient;

      // at 88% -30% — the centre is off-canvas above the top-right corner.
      expect(g.center, const Alignment(0.76, -1.6));
      expect((g.center as Alignment).y, lessThan(-1),
          reason: 'centring this on-canvas turns a corner highlight into a blob');
      expect(g.colors.first.a, closeTo(0.28, 0.005));
      expect(g.colors.last.a, 0);
      expect(g.stops!.last, closeTo(0.70, 0.001));
    });

    testWidgets('only referralPurple has a radial overlay', (tester) async {
      for (final variant in variants) {
        if (variant == DugnadFeedEntryVariant.referralPurple) continue;
        await pumpBanner(tester, variant);
        expect(find.byKey(kEntryRadialOverlayKey), findsNothing,
            reason: '${variant.name} gained a radial overlay');
      }
    });
  });

  group('supportLight colours', () {
    testWidgets('border and hairline width', (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.supportLight);
      final d = cardDecoration(tester);

      expect(d.color, Colors.white);
      expect((d.border! as Border).top.color, const Color(0xFFECECF0));
      // Authored 1.5px. A computed-style read can report 1.25 on a snapped
      // display, so this comes from the CSS source (rule 19).
      expect((d.border! as Border).top.width, 1.5);
    });

    testWidgets('the heart accent is unthemed and survives a club override',
        (tester) async {
      // Flat magenta on every club — mixing it with a club token would drift
      // it per club, which the design does not do.
      final navyClub = AeThemePalette.resolve(accentColor: '#1B3A6B');

      for (final palette in [AeThemePalette.defaults, navyClub]) {
        await pumpBanner(
          tester,
          DugnadFeedEntryVariant.supportLight,
          palette: palette,
        );
        final icon = tester.widget<Icon>(
          find.byIcon(Icons.favorite_rounded),
        );
        expect(icon.color, const Color(0xFFB4509C));
      }
    });
  });

  group('club overrides still propagate', () {
    testWidgets('missionsPurple shadow follows the club, gold does not',
        (tester) async {
      final navyClub = AeThemePalette.resolve(accentColor: '#1B3A6B');

      // rgba(45,27,91,.6) is `--ae-midnight`, which the club theme derives —
      // freezing it as a literal would leave a purple shadow under a navy card.
      await pumpBanner(tester, DugnadFeedEntryVariant.missionsPurple,
          palette: navyClub);
      final themed = cardDecoration(tester).boxShadow!.single.color;
      expect(themed.toARGB32() & 0x00FFFFFF,
          navyClub.text.toARGB32() & 0x00FFFFFF);

      // The gold tint is not a club colour and must not move.
      await pumpBanner(tester, DugnadFeedEntryVariant.leagueGold,
          palette: navyClub);
      expect(cardDecoration(tester).boxShadow!.single.color.toARGB32() &
          0x00FFFFFF,
          const Color(0xFFD8A028).toARGB32() & 0x00FFFFFF);
    });
  });

  group('type is per variant, not a shared compromise', () {
    // The app tracked every title at -0.015em, which is the midpoint of the
    // two values the design actually uses and therefore correct for neither.
    const tracking = <DugnadFeedEntryVariant, double>{
      DugnadFeedEntryVariant.leagueGold: -0.02,
      DugnadFeedEntryVariant.missionsPurple: -0.01,
      DugnadFeedEntryVariant.transferDark: -0.01,
      DugnadFeedEntryVariant.referralPurple: -0.01,
      DugnadFeedEntryVariant.supportLight: -0.01,
    };

    tracking.forEach((variant, em) {
      testWidgets('${variant.name} title tracks ${em}em', (tester) async {
        await pumpBanner(tester, variant);
        final title = tester.widget<Text>(find.text('Tittel'));
        final size = title.style!.fontSize!;
        expect(title.style!.letterSpacing, closeTo(size * em, 0.001),
            reason: '${variant.name}: letterSpacing must derive from the '
                'font size, and the em value is per variant');
        expect(title.style!.letterSpacing, isNot(closeTo(size * -0.015, 0.0001)),
            reason: '${variant.name}: the shared -0.015 compromise is back');
      });
    });

    testWidgets('leagueGold subtitle is 700 where the others are 600',
        (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.leagueGold);
      expect(
        tester.widget<Text>(find.text('Undertekst')).style!.fontWeight,
        FontWeight.w700,
      );

      for (final variant in [
        DugnadFeedEntryVariant.missionsPurple,
        DugnadFeedEntryVariant.transferDark,
      ]) {
        await pumpBanner(tester, variant);
        expect(
          tester.widget<Text>(find.text('Undertekst')).style!.fontWeight,
          FontWeight.w600,
          reason: variant.name,
        );
      }
    });

    testWidgets('supportLight clamps its subtitle to one line', (tester) async {
      // `.s` is nowrap + ellipsis. With rule 8's 1.15 text-scale ceiling a
      // second line would push the card past its measured height.
      await pumpBanner(tester, DugnadFeedEntryVariant.supportLight);
      final s = tester.widget<Text>(find.text('Undertekst'));
      expect(s.maxLines, 1);
      expect(s.overflow, TextOverflow.ellipsis);

      await pumpBanner(tester, DugnadFeedEntryVariant.missionsPurple);
      expect(tester.widget<Text>(find.text('Undertekst')).maxLines, 2,
          reason: 'only supportLight is nowrap');
    });
  });

  group('.ic and .go are per variant', () {
    testWidgets('missionsPurple is 42 with no border, referralPurple 44 with',
        (tester) async {
      await pumpBanner(tester, DugnadFeedEntryVariant.missionsPurple);
      var box = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.bolt_rounded),
          matching: find.byType(Container),
        ).first,
      );
      expect(box.constraints!.maxWidth, 42);
      expect((box.decoration! as BoxDecoration).border, isNull,
          reason: '.dg-missions-entry .ic has no border');

      await pumpBanner(tester, DugnadFeedEntryVariant.referralPurple);
      box = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.share_rounded),
          matching: find.byType(Container),
        ).first,
      );
      expect(box.constraints!.maxWidth, 44);
      expect((box.decoration! as BoxDecoration).border, isNotNull,
          reason: 'referralPurple is the one variant whose .ic has a border');
    });

    testWidgets('the go circle keeps its five sizes', (tester) async {
      const goSizes = <DugnadFeedEntryVariant, double>{
        DugnadFeedEntryVariant.leagueGold: 34,
        DugnadFeedEntryVariant.missionsPurple: 30,
        DugnadFeedEntryVariant.transferDark: 30,
        DugnadFeedEntryVariant.referralPurple: 32,
        DugnadFeedEntryVariant.supportLight: 32,
      };

      for (final entry in goSizes.entries) {
        await pumpBanner(tester, entry.key);
        final go = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.chevron_right_rounded),
            matching: find.byType(Container),
          ).first,
        );
        expect(go.constraints!.maxWidth, entry.value, reason: entry.key.name);
      }
    });
  });

  group('geometry at the 375 reference frame', () {
    testWidgets('radius is 18 and padV is per variant', (tester) async {
      const padV = <DugnadFeedEntryVariant, double>{
        DugnadFeedEntryVariant.leagueGold: 14, // .lb-entry
        DugnadFeedEntryVariant.missionsPurple: 15,
        DugnadFeedEntryVariant.transferDark: 15,
        DugnadFeedEntryVariant.referralPurple: 15,
        DugnadFeedEntryVariant.supportLight: 15,
      };

      for (final variant in variants) {
        await pumpBanner(tester, variant);
        expect(
          cardDecoration(tester).borderRadius,
          BorderRadius.circular(18),
          reason: variant.name,
        );

        final pad = tester
            .widgetList<Padding>(find.byType(Padding))
            .map((p) => p.padding)
            .whereType<EdgeInsets>()
            .firstWhere((e) => e.left == 16);
        expect(pad.top, padV[variant], reason: variant.name);
        expect(pad.bottom, padV[variant], reason: variant.name);
      }
    });
  });
}
