import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/bergen/kit/lf_klokke.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';
import 'package:aerend_customer/screens/common/auth/onboarding_kit.dart';

/// Heat plan Steps 9 + 11 together: `loopGrense` puts a loop's animated
/// output in its own RepaintBoundary — outside Step 11's LfRammeBygger, so
/// a `ramme` loop still updates its render objects in place (no rebuild)
/// with the boundary on, and draws the same t as with it off.
void main() {
  tearDown(() {
    BergenPerf.loopGrensePaa = false;
    BergenPerf.rammeLoopPaa = false;
    BergenPerf.klokkePaa = false;
  });

  const f16 = Duration(milliseconds: 16);

  Widget tre() => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        LfLoop(
          ramme: true,
          builder: (context, t, child) => Opacity(opacity: .2 + .6 * ((t / 900) % 1.0), child: child),
          child: const SizedBox(width: 20, height: 20, child: ColoredBox(color: Color(0xFF336699))),
        ),
        OnbLoopClock(
          ramme: true,
          builder: (context, t, child) => Transform.translate(offset: Offset((t / 100) % 7, 0), child: child),
          child: const SizedBox(width: 20, height: 20),
        ),
        LfLoop(
          builder: (context, t, child) => Align(alignment: Alignment((t / 700) % 1.0, 0), child: child),
          child: const SizedBox(width: 20, height: 20),
        ),
      ],
    ),
  );

  // No keys on the builder output: LfRammeBygger only updates unkeyed
  // render-object widgets in place.
  bool iGrense(WidgetTester tester, Type k) {
    final ro = tester.renderObject(find.byType(k));
    // The output's own boundary sits directly above the builder output.
    final p = ro.parent;
    return p is RenderRepaintBoundary;
  }

  for (final klokke in [false, true]) {
    testWidgets('ramme + loopGrense (klokke1 $klokke): boundary outside the builder output, direct updates unchanged, same t', (tester) async {
      BergenPerf.klokkePaa = klokke;
      BergenPerf.rammeLoopPaa = true;
      final opas = <bool, List<double>>{};
      final direkte = <bool, int>{};
      for (final grense in [false, true]) {
        BergenPerf.loopGrensePaa = grense;
        await tester.pumpWidget(tre());
        expect(iGrense(tester, Opacity), grense);
        expect(iGrense(tester, Transform), grense);
        expect(iGrense(tester, Align), grense, reason: 'the ValueListenableBuilder path too');
        final d0 = LfKlokke.instance.direkte;
        final o = <double>[];
        for (var i = 0; i < 60; i++) {
          await tester.pump(f16);
          o.add(tester.renderObject<RenderOpacity>(find.byType(Opacity)).opacity);
        }
        direkte[grense] = LfKlokke.instance.direkte - d0;
        opas[grense] = o;
        await tester.pumpWidget(const SizedBox());
      }
      expect(direkte[true], direkte[false], reason: 'the direct-update chain is the same with the boundary');
      expect(direkte[true], greaterThanOrEqualTo(2 * 59), reason: 'both ramme loops went the direct way');
      expect(opas[true], opas[false], reason: 'the same t on the same frames');
    });
  }
}
