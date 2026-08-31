import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/dugnad/widgets/ae_metal_progress_bar.dart';

/// `.lb-level-prog` runs four *independent* CSS animations. Collapsing them
/// into one tween makes the bar pulse in lockstep, which reads as a loading
/// indicator rather than a layered metal surface.
void main() {
  // The MediaQuery must sit INSIDE MaterialApp — MaterialApp inserts its own
  // from the window and would override an outer one.
  Widget host({required bool reduceMotion}) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: const Size(375, 812),
              disableAnimations: reduceMotion,
            ),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: AeMetalProgressBar(metal: 'gull', value: 0.6),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('animates by default', (tester) async {
    await tester.pumpWidget(host(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 50));

    // Frames keep being scheduled: the timelines are live.
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stops every timeline but keeps the fill',
      (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pumpAndSettle();

    // Nothing left running: pumpAndSettle would time out otherwise.
    expect(tester.takeException(), isNull);

    // The bar is still rendered at its value — reduced motion removes the
    // animation, not the information.
    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.widthFactor, closeTo(0.6, 0.001));
  });

  test('CSS durations are transcribed exactly', () {
    final src = File(
      'lib/screens/dugnad/widgets/ae_metal_progress_bar.dart',
    ).readAsStringSync();
    // lb-prog-fill 1.05s / glow 2.4s / stripes .62s / sweep 2.8s
    for (final ms in [1050, 2400, 620, 2800]) {
      expect(src, contains('milliseconds: $ms'), reason: '$ms ms timeline');
    }
    // Delays: fill .1s, glow 1.15s, sweep 1.3s
    for (final ms in [100, 1150, 1300]) {
      expect(src, contains('milliseconds: $ms'), reason: '$ms ms delay');
    }
    // The sheen periods must not be shortened — a 9.6s sweep is an
    // occasional glint; at 2s it reads as a loading shimmer.
    expect(src, isNot(contains('milliseconds: 200,')));
  });

  test('both screens gate their animations on disableAnimationsOf', () {
    for (final path in [
      'lib/screens/dugnad/widgets/ae_metal_progress_bar.dart',
    ]) {
      final src = File(path).readAsStringSync();
      if (src.contains('AnimationController')) {
        expect(
          src,
          contains('disableAnimationsOf'),
          reason: '$path animates without honouring reduced motion',
        );
      }
    }
  });
}
