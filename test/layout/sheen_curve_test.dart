import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/widgets/ae_sheen.dart';

import 'reduced_motion_harness.dart';

/// `lb-sheen` and `pc-sheen` are different shapes, not one animation at two
/// speeds, and **the dwell is the effect**. A linear tween across the full
/// period gives a constant slow crawl that no duration value can fix — which
/// is what the previous implementation did (`-160 + value * 320` over 7.6s).
void main() {
  Widget host({
    required AeSheenCurve curve,
    Duration period = const Duration(seconds: 10),
    Duration? delay,
    bool reduced = false,
  }) =>
      MaterialApp(
        home: Builder(
          // MediaQuery must sit INSIDE MaterialApp — it inserts its own from
          // the window and would override an outer one.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AeSheen(
                          curve: curve,
                          period: period,
                          delay: delay,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  /// The band's left edge, or null when it is not painted at all.
  double? bandLeft(WidgetTester tester) {
    final f = find.byType(Positioned);
    for (final w in tester.widgetList<Positioned>(f)) {
      if (w.width != null && w.left != null) return w.left;
    }
    return null;
  }

  double? bandOpacity(WidgetTester tester) {
    final f = find.byType(Opacity);
    if (f.evaluate().isEmpty) return null;
    return tester.widget<Opacity>(f.first).opacity;
  }

  group('lb-sheen sweeps first, then waits', () {
    testWidgets('parked invisible for the last 76% of the cycle',
        (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.lbSheen));
      await tester.pump();

      // 24% -> 100% is dead time. Sample well inside it.
      await tester.pump(const Duration(milliseconds: 5000)); // t = 0.50
      expect(bandOpacity(tester), anyOf(isNull, 0.0),
          reason: 'the band must be invisible for the 76% dwell — a visible '
              'band here is the constant-crawl bug');

      await tester.pump(const Duration(milliseconds: 3000)); // t = 0.80
      expect(bandOpacity(tester), anyOf(isNull, 0.0));
    });

    testWidgets('fades in by 6% and back out by 24%', (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.lbSheen));
      await tester.pump();

      // t = 0.06 is the opacity peak.
      await tester.pump(const Duration(milliseconds: 600));
      final peak = bandOpacity(tester);
      expect(peak, isNotNull);
      expect(peak!, greaterThan(0.8), reason: 'should be at full opacity');

      // t = 0.20, on the way back out.
      await tester.pump(const Duration(milliseconds: 1400));
      final fading = bandOpacity(tester);
      expect(fading, isNotNull);
      expect(fading!, lessThan(peak),
          reason: 'the envelope must fall away before the sweep ends');
    });

    testWidgets('travels 400% of its own width, not 200%', (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.lbSheen));
      // At exactly t=0 the opacity envelope is 0, so nothing is painted --
      // which is itself correct. Sample just inside the fade-in.
      await tester.pump(const Duration(milliseconds: 100)); // t = 0.01
      final start = bandLeft(tester);
      expect(start, isNotNull);
      // Still essentially at -160% of a 135px band (300 * 0.45); easeInOut
      // barely moves in the first 4% of the interval.
      expect(start!, closeTo(-1.6 * 300 * 0.45, 8.0));

      // And it reaches +240%, not +100% -- a 400% total travel.
      await tester.pump(const Duration(milliseconds: 2200)); // t = 0.23
      final end = bandLeft(tester);
      expect(end, isNotNull);
      expect(end!, greaterThan(2.0 * 300 * 0.45),
          reason: 'travel must be -160% -> 240%, not -100% -> 100%');
    });
  });

  group('pc-sheen waits, then sweeps', () {
    testWidgets('parked left for the first 55%', (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.pcSheen));
      await tester.pump();

      final atStart = bandLeft(tester);
      await tester.pump(const Duration(milliseconds: 4000)); // t = 0.40
      expect(bandLeft(tester), atStart,
          reason: 'pc-sheen must not move for the first 55% — this is the '
              'opposite phase to lb-sheen, which is why two stacked elements '
              'do not fire together');
    });

    testWidgets('has crossed by 72% and stays parked right', (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.pcSheen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 7500)); // t = 0.75
      final parked = bandLeft(tester);
      expect(parked, closeTo(300 * 0.45, 1.0));

      await tester.pump(const Duration(milliseconds: 2000)); // t = 0.95
      expect(bandLeft(tester), parked);
    });

    testWidgets('never fades — its gradient supplies visibility',
        (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.pcSheen));
      await tester.pump();
      for (final ms in [0, 3000, 6000, 6500, 9000]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(bandOpacity(tester), 1.0, reason: 'pc-sheen has no envelope');
      }
    });
  });

  group('reduced motion', () {
    testWidgets('parks off-screen and invisible, never at the end state',
        (tester) async {
      await tester.pumpWidget(host(curve: AeSheenCurve.lbSheen, reduced: true));
      await tester.pump(const Duration(milliseconds: 16));

      // Treatment A: `animation: none` resets to the declared initial state.
      // Landing it at the end state would leave a permanent white band.
      expect(find.byType(Opacity), findsNothing);
      expect(tester.binding.transientCallbackCount, 0,
          reason: 'the controller must be prevented from starting, not merely '
              'hidden — a running controller keeps a frame scheduled');
    });

    for (final curve in AeSheenCurve.values) {
      testWidgets('${curve.name} satisfies the shared contract', (tester) async {
        await expectRespectsReducedMotion(
          tester,
          () => SizedBox(
            width: 300,
            height: 80,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AeSheen(
                    curve: curve,
                    period: const Duration(seconds: 10),
                    delay: const Duration(milliseconds: 1200),
                  ),
                ),
              ],
            ),
          ),
          longestDelay: const Duration(milliseconds: 1200),
        );
      });
    }
  });
}
