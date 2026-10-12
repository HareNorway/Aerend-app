import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';

/// Bergen Step 12 — the motion tiers: the carousel (Populært i kveld, the
/// Forundringspose) turns on its own in `full`, and stays put in `still`.
void main() {
  tearDown(() => BergenPerf.force(null));

  Future<List<int>> fronter(WidgetTester tester, BergenTier tier) async {
    BergenPerf.force(tier);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final seen = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Scaffold(
            body: BergenRail(
              height: 360,
              cardTop: 40,
              count: 3,
              intervalMs: 1000,
              onOpen: (_) {},
              builder: (context, i, front) {
                if (front) seen.add(i);
                return SizedBox(height: 120, child: Text('$i'));
              },
            ),
          ),
        ),
      ),
    );
    for (var k = 0; k < 4; k++) {
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1300));
    }
    return seen.toSet().toList();
  }

  testWidgets('full: the carousel turns by itself', (tester) async {
    expect((await fronter(tester, BergenTier.full)).length, greaterThan(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('still: the carousel stays on its first card', (tester) async {
    expect(await fronter(tester, BergenTier.still), [0]);
    await tester.pumpWidget(const SizedBox());
  });
}
