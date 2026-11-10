import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';
import 'package:aerend_customer/screens/common/auth/onboarding_kit.dart';

/// Heat plan Step 9: `loopGrense` puts a loop's animated output in its own
/// RepaintBoundary (LfLoop and OnbLoopClock), and the loop draws the same t
/// on the same frames as with it off. (Step 11's LfRammeBygger part was
/// removed with Step 11 on 2026-11-10.)
void main() {
  tearDown(() {
    BergenPerf.loopGrensePaa = false;
  });

  const f16 = Duration(milliseconds: 16);

  Widget tre() => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      children: [
        LfLoop(
          builder: (context, t, child) => Opacity(opacity: .2 + .6 * ((t / 900) % 1.0), child: child),
          child: const SizedBox(width: 20, height: 20, child: ColoredBox(color: Color(0xFF336699))),
        ),
        OnbLoopClock(
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

  bool iGrense(WidgetTester tester, Type k) {
    final ro = tester.renderObject(find.byType(k));
    // The output's own boundary sits directly above the builder output.
    return ro.parent is RenderRepaintBoundary;
  }

  testWidgets('loopGrense: boundary directly above the builder output, same t on the same frames', (tester) async {
    final opas = <bool, List<double>>{};
    for (final grense in [false, true]) {
      BergenPerf.loopGrensePaa = grense;
      await tester.pumpWidget(tre());
      expect(iGrense(tester, Opacity), grense);
      expect(iGrense(tester, Transform), grense);
      expect(iGrense(tester, Align), grense);
      final o = <double>[];
      for (var i = 0; i < 60; i++) {
        await tester.pump(f16);
        o.add(tester.renderObject<RenderOpacity>(find.byType(Opacity)).opacity);
      }
      opas[grense] = o;
      await tester.pumpWidget(const SizedBox());
    }
    expect(opas[true], opas[false], reason: 'the same t on the same frames');
  });
}
