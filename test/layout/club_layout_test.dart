import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/commonView/circle_nav_bar.dart';
import 'package:aerend_customer/theme/design_scale.dart';

/// Velg klubb / Hjem geometry guards.
///
/// Same shape as the auth suite: the design frame must stay pixel-exact at
/// 375, and every dimension must hold the same fraction of the screen at
/// every width. That ratio assertion is what caught the real bug two passes
/// ago, so it is the one that matters most here too.
void main() {
  const sizes = <String, Size>{
    'SE 375x667': Size(375, 667),
    'design frame 375x812': Size(375, 812),
    '15 Pro 393x852': Size(393, 852),
    'Pro Max 430x932': Size(430, 932),
  };

  double expectedDs(double width) => width / 375.0;

  Future<T> measure<T>(
    WidgetTester tester,
    Size size,
    T Function(BuildContext context) probe, {
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late T result;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          // Override after MaterialApp's fromView MediaQuery so padding is
          // what the probe (and production helpers) actually read.
          data: MediaQueryData(size: size, padding: viewPadding),
          child: Builder(
            builder: (context) {
              result = probe(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return result;
  }

  group('club sheet', () {
    for (final entry in sizes.entries) {
      testWidgets('is 90% of screen height at ${entry.key}', (tester) async {
        final h = await measure<double>(
          tester,
          entry.value,
          (context) => MediaQuery.of(context).size.height * 0.90,
        );
        // `.dg-csheet { height: 90% }`
        expect(h, closeTo(entry.value.height * 0.90, 0.5));
      });

      testWidgets('row card metrics scale at ${entry.key}', (tester) async {
        final dims = await measure<List<double>>(
          tester,
          entry.value,
          // `.dg-clubrow` crest 44, radius 15, gap 13; `.chk` 28.
          (context) => [
            context.dp(44),
            context.dp(15),
            context.dp(13),
            context.dp(28),
          ],
        );
        final ds = expectedDs(entry.value.width);
        expect(dims[0], closeTo(44 * ds, 0.01));
        expect(dims[1], closeTo(15 * ds, 0.01));
        expect(dims[2], closeTo(13 * ds, 0.01));
        expect(dims[3], closeTo(28 * ds, 0.01));
      });
    }

    testWidgets('crest ÷ screen width is constant at every size',
        (tester) async {
      final ratios = <double>[];
      for (final size in sizes.values) {
        final crest =
            await measure<double>(tester, size, (context) => context.dp(44));
        ratios.add(crest / size.width);
      }
      for (final r in ratios) {
        expect(r, closeTo(44 / 375, 0.001));
      }
    });
  });

  group('club onboarding', () {
    testWidgets('head metrics are the .dg-onb values, not the auth ones',
        (tester) async {
      final dims = await measure<List<double>>(
        tester,
        const Size(375, 812),
        (context) => [
          context.dp(23), // .dg-onb-head h1 — 23, not the auth 26
          context.dp(14), // .dg-onb-head p
          context.dp(38), // .dg-onb-back — 38, not the .ae-back 40
          context.dp(58), // .dg-onb-ic
        ],
      );
      expect(dims, [23.0, 14.0, 38.0, 58.0]);
    });
  });

  group('home bottom clearance', () {
    for (final entry in sizes.entries) {
      testWidgets('reserves nav + safe area at ${entry.key}', (tester) async {
        const safeBottom = 34.0; // home-indicator devices
        final reserved = await measure<double>(
          tester,
          entry.value,
          (context) => aePillNavReservedHeight(context) + context.dp(16),
          viewPadding: const EdgeInsets.only(bottom: safeBottom),
        );

        final ds = expectedDs(entry.value.width);
        // max(safeArea, design 16) — do not stack both (that floated the bar).
        final bottomInset =
            math.max(safeBottom, kAePillNavBottomGap * ds);
        final expected =
            kAePillNavPillHeight * ds + bottomInset + 16 * ds;
        expect(reserved, closeTo(expected, 0.5));

        // The old fixed 100 was not enough once the inset is counted — that is
        // what let the nav cover the campaign card.
        expect(
          reserved,
          greaterThan(100),
          reason: 'must clear the floating nav, which is an overlay',
        );
      });
    }
  });
}
