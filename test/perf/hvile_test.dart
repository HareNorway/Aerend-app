import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// Perf plan: a loop scrolled off the screen stops producing frames and
/// comes back, at a later pose, when it is on the screen again.
void main() {
  tearDown(() => BergenPerf.hvilePaa = true);

  double? sist;
  final ctl = ScrollController();

  Widget app() => MaterialApp(
    home: BergenPerfScope(
      child: SingleChildScrollView(
        controller: ctl,
        child: Column(
          children: [
            LfLoop(builder: (context, t, _) {
              sist = t;
              return const SizedBox(height: 50, width: 50);
            }),
            const SizedBox(height: 4000),
          ],
        ),
      ),
    ),
  );

  testWidgets('off the screen: no ticker; back on the screen: ticking, later pose', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    ctl.jumpTo(3000);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.transientCallbackCount, 0, reason: 'the loop rests off the screen');
    final hvilt = sist!;
    await tester.pump(const Duration(seconds: 1));
    expect(sist, hvilt, reason: 'no rebuilds while resting');

    ctl.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 200)); // the 120 ms wake check
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'awake again');
    expect(sist!, greaterThan(hvilt), reason: 'the clock moved on');
  });

  testWidgets('hvile off: the loop keeps ticking off the screen', (tester) async {
    BergenPerf.hvilePaa = false;
    await tester.pumpWidget(app());
    ctl.jumpTo(3000);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });
}
