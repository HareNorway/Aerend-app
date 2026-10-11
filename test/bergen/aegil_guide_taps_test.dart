import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/aegil/aegil_guide.dart';

import '../layout/reduced_motion_harness.dart';

/// The Ægil-guide's bubble takes its own taps: «Neste» and ✕ never reach the
/// screen under it (checked 2026-10-08 after a report that they did — the
/// bubble had already left on its 13 s timer when the tap landed).
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Future<int Function()> pumpGuide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 2856);
    tester.view.devicePixelRatio = 3.11;
    addTearDown(tester.view.reset);
    AegilGuide.reset();
    var under = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => under++, child: const ColoredBox(color: Colors.white)),
          ),
          Positioned.fill(child: AegilGuide(skjerm: 'utforsk', tips: aegilGuideTips('utforsk'))),
        ]),
      ),
    ));
    // 1.5 s wait, 1.2 s walk in, then the bubble.
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return () => under;
  }

  testWidgets('✕ closes the guide and nothing under it is tapped', (tester) async {
    final under = await pumpGuide(tester);
    expect(find.byKey(const Key('a1_guide_lukk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('a1_guide_lukk')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(under(), 0);
    expect(find.byKey(const Key('a1_guide_boble')), findsNothing);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('«Neste» moves to the next tip and nothing under it is tapped', (tester) async {
    final under = await pumpGuide(tester);

    await tester.tap(find.byKey(const Key('a1_guide_neste')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(under(), 0);
    expect(find.text('2/3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });
}
