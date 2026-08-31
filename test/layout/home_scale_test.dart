import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/commonView/circle_nav_bar.dart';
import 'package:aerend_customer/theme/ae_typography.dart';
import 'package:aerend_customer/theme/design_scale.dart';

/// Hjem scale guards.
///
/// Home was the last screen that never went through `dp()`. These pin the
/// design-px values for the elements that measured short, and — more
/// importantly — pin the *ratio*: every one of them must hold the same
/// fraction of the screen at every width. That ratio assertion is the one
/// that has caught every real bug in this project.
void main() {
  const sizes = <String, Size>{
    'SE 375x667': Size(375, 667),
    'design frame 375x812': Size(375, 812),
    '15 Pro 393x852': Size(393, 852),
    'Pro Max 430x932': Size(430, 932),
  };

  double expectedDs(double w) => w / 375.0;

  Future<T> probe<T>(
    WidgetTester tester,
    Size size,
    T Function(BuildContext c) fn,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late T out;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              out = fn(c);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return out;
  }

  /// Design px for each element that measured short, read from the prototype
  /// CSS rather than from the screenshot.
  const design = <String, double>{
    // `.dg-modechip { height: 36px }`
    'dugnadPillHeight': 36,
    // `.dg-myklubb`: padding 8 top/bottom + a 38px lead column.
    'minKlubbLead': 38,
    'minKlubbRadius': 14,
    'minKlubbPadV': 8,
    // `.dg-myklubb .v`
    'minKlubbValueFont': 14.5,
    // `.h-feed { margin-top: -18px }`
    'feedOverlap': 18,
    // `.h-feed { border-radius: 24px 24px 0 0 }`
    'feedRadius': 24,
    // `.pn-item { height: 46px }` inside `.pn-track { padding: 8px }`
    'navItemHeight': kAePillNavItemHeight,
    'navTrackPad': kAePillNavTrackPad,
    'navPillHeight': kAePillNavPillHeight,
    // `.ae-pillnav` bottom gap
    'navBottomGap': kAePillNavBottomGap,
    // "Slik tjener du flest poeng": sparkle 15, title 15, sub 12.5, circle 28
    'earnSparkle': 15,
    'earnTitle': 15,
    'earnSub': 12.5,
    'earnChevronCircle': 28,
  };

  group('design frame is exact', () {
    testWidgets('every home token is its literal px at 375', (tester) async {
      final got = await probe<Map<String, double>>(
        tester,
        const Size(375, 812),
        (c) => {
          for (final e in design.entries) e.key: c.dp(e.value),
        },
      );
      for (final e in design.entries) {
        expect(got[e.key], e.value, reason: e.key);
      }
    });
  });

  group('ratio is constant across devices', () {
    for (final e in design.entries) {
      testWidgets('${e.key} ÷ screen width', (tester) async {
        final ratios = <double>[];
        for (final size in sizes.values) {
          final v = await probe<double>(tester, size, (c) => c.dp(e.value));
          ratios.add(v / size.width);
        }
        // This is the assertion that matters: the element occupies the same
        // slice of the screen on every device.
        for (final r in ratios) {
          expect(r, closeTo(e.value / 375, 0.0005), reason: e.key);
        }
      });
    }
  });

  group('feed overlaps the hero', () {
    for (final entry in sizes.entries) {
      testWidgets('by dp(18) at ${entry.key}', (tester) async {
        final overlap = await probe<double>(
          tester,
          entry.value,
          (c) => c.dp(AeDugnadSpace.homeFeedOverlap),
        );
        expect(overlap, closeTo(18 * expectedDs(entry.value.width), 0.01));
      });
    }

    test('the overlap token is the CSS value', () {
      expect(AeDugnadSpace.homeFeedOverlap, 18);
      expect(AeDugnadSpace.homeFeedRadius, 24);
    });

    test('club home overrides .h-feed gap to 14', () {
      // `.h-feed` base is `gap: 22`, but DGClubHome sets `gap: 14` inline
      // (club-select.jsx:556). The club home is the denser variant.
      expect(AeDugnadSpace.homeFeedGap, 14);
    });
  });

  group('text styles scale with the frame', () {
    testWidgets('fontSize and letterSpacing both scale, height does not',
        (tester) async {
      const base = TextStyle(fontSize: 20, letterSpacing: -0.4, height: 1.2);

      final at375 =
          await probe<TextStyle>(tester, const Size(375, 812), (c) => base.dp(c));
      expect(at375.fontSize, 20);
      expect(at375.letterSpacing, -0.4);

      final at430 =
          await probe<TextStyle>(tester, const Size(430, 932), (c) => base.dp(c));
      final ds = expectedDs(430);
      expect(at430.fontSize, closeTo(20 * ds, 0.01));
      // letter-spacing is em-relative, so it tracks the scaled size.
      expect(at430.letterSpacing, closeTo(-0.4 * ds, 0.01));
      // line-height is a ratio and must be left alone.
      expect(at430.height, 1.2);
    });
  });

  group('nav bar', () {
    test('pill height is .pn-item 46 inside .pn-track padding 8', () {
      // Four values were wrong independently of scale; this pins them.
      expect(kAePillNavItemHeight, 46);
      expect(kAePillNavTrackPad, 8);
      expect(kAePillNavPillHeight, 62);
      expect(kAePillNavBottomGap, 16);
    });

    testWidgets('bottom inset floors at design 16 when safe-area is 0',
        (tester) async {
      // Matches the HTML `.ae-screen` frame (no env safe-area).
      final inset = await probe<double>(
        tester,
        const Size(375, 812),
        aePillNavBottomInset,
      );
      expect(inset, 16);

      final reserved = await probe<double>(
        tester,
        const Size(375, 812),
        aePillNavReservedHeight,
      );
      expect(reserved, 62 + 16);
    });

    testWidgets('pill height tokens scale with width', (tester) async {
      final ratios = <double>[];
      for (final size in sizes.values) {
        final v = await probe<double>(
          tester,
          size,
          (c) => c.dp(kAePillNavPillHeight),
        );
        ratios.add(v / size.width);
      }
      for (final r in ratios) {
        expect(r, closeTo(62 / 375, 0.0005));
      }
    });
  });
}
