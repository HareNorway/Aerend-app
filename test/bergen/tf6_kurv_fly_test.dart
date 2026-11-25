import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/kurv_fly.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_widgets.dart' show LfPillCta;

import '../a3/a3_fakes.dart';

/// TestFlight 6 feedback: «+» and «Legg til» put the dish in the basket with no sign of it; the design flies it into
/// the basket bar's cart (`flyTilKurv`), and the sheet's «Legg til» floats (`aeKnSvev`).

Widget _scene({bool rolig = false}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(size: Size(402, 874)).copyWith(disableAnimations: rolig),
    child: Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 20,
            top: 300,
            width: 170,
            height: 220,
            child: KurvFlyKort(
              child: Column(
                children: [
                  const KurvFlyKilde(url: null, child: SizedBox(key: Key('bilde'), width: 170, height: 128)),
                  Builder(builder: (c) => TextButton(key: const Key('pluss'), onPressed: () => kurvFly(c), child: const Text('+'))),
                ],
              ),
            ),
          ),
          const Positioned(left: 60, top: 790, width: 40, height: 40, child: KurvFlyMaal(child: SizedBox(key: Key('kurv'), width: 40, height: 40))),
        ],
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('«+»: the dish lifts off its picture, arcs up and lands in the cart, which bounces; «+1» rises; all clears', (tester) async {
    phone(tester);
    await tester.pumpWidget(_scene());
    final bilde = tester.getRect(find.byKey(const Key('bilde')));
    await tester.tap(find.byKey(const Key('pluss')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final kopi = find.byKey(const Key('kurv-fly-kopi'));
    expect(kopi, findsOneWidget, reason: 'the copy is in the root overlay');
    // Centred on the picture, at most 120 frame px wide (×402/390).
    final r0 = tester.getRect(kopi);
    expect(r0.center.dx, closeTo(bilde.center.dx, 2));
    expect(r0.width, lessThanOrEqualTo(120 * 402 / 390 + .5));
    // Halfway: up and over (`top = min(0, dy) − 90`), smaller.
    await tester.pump(const Duration(milliseconds: 300));
    final midt = tester.getRect(kopi);
    expect(midt.center.dy, lessThan(r0.center.dy - 20), reason: 'it arcs up first: $midt from $r0');
    expect(midt.width, lessThan(r0.width));
    // Landed (720 ms): the copy is gone, the cart bounces, «+1» shows.
    await tester.pump(const Duration(milliseconds: 440));
    await tester.pump(const Duration(milliseconds: 16));
    expect(kopi, findsNothing);
    expect(find.byKey(const Key('kurv-fly-pluss1')), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    // The cart's bounce (480 ms, `scale 1 → 1.28 → .94 → 1` on an overshooting curve): its peak over the frames.
    var topp = 1.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final t = tester.widgetList<Transform>(find.ancestor(of: find.byKey(const Key('kurv')), matching: find.byType(Transform)));
      for (final x in t) {
        topp = topp > x.transform.getMaxScaleOnAxis() ? topp : x.transform.getMaxScaleOnAxis();
      }
    }
    // (The 1.28 peak falls between 16 ms frames on this curve.)
    expect(topp, greaterThan(1.15), reason: 'the cart swells as the dish lands');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('kurv-fly-pluss1')), findsNothing);
  });

  testWidgets('«Roligere bevegelse» / the OS setting: no flight', (tester) async {
    phone(tester);
    await tester.pumpWidget(_scene(rolig: true));
    await tester.tap(find.byKey(const Key('pluss')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('kurv-fly-kopi')), findsNothing);
  });

  testWidgets('the floating pill (`aeKnSvev 3.4s`): up 5 px and back, its shadow narrowing', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 260, child: LfPillCta(onTap: () {}, phaseMs: -2300, child: const Text('Legg til'))))),
    ));
    double topp() => tester.getRect(find.text('Legg til')).top;
    final a = topp();
    final ys = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      ys.add(topp());
    }
    final spenn = ys.reduce((x, y) => x > y ? x : y) - ys.reduce((x, y) => x < y ? x : y);
    expect(spenn, closeTo(5, 1), reason: 'from $a: $ys');
  });
}
