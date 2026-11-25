import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/kn_trykk.dart';

/// TestFlight 6 feedback: «Legg til» had no press animation — the design's `knTrykk`: squash down 7 px to
/// .97 × .94 (20 %), spring to −1.5 px 1.01 × 1.02 (60 %), back at 640 ms; rings spread under it for ~1.8 s.

Widget _kn({bool rolig = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: const Size(390, 844), disableAnimations: rolig),
    child: const Scaffold(
      body: Center(
        child: SizedBox(
          width: 260,
          height: 52,
          // As in the sheet: the key ignores pointers (the pressable around it takes the tap).
          child: KnTrykk(hoyde: 52, lys: false, child: IgnorePointer(child: ColoredBox(key: Key('knapp'), color: Color(0xFFE65A28)))),
        ),
      ),
    ),
  ),
);

Matrix4? _klem(WidgetTester tester) {
  final t = find.ancestor(of: find.byKey(const Key('knapp')), matching: find.byType(Transform));
  return t.evaluate().isEmpty ? null : tester.widget<Transform>(t.first).transform;
}

void main() {
  testWidgets('a press squashes the key down and springs it back; rings spread under it, then all is still', (tester) async {
    await tester.pumpWidget(_kn());
    expect(_klem(tester)!.isIdentity(), isTrue, reason: 'at rest: the identity (the tree never changes)');
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('knapp'))));
    // ~20 % of the eased 640 ms: low and squashed.
    var lavest = 0.0, minstY = 1.0;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final m = _klem(tester);
      if (m == null) continue;
      lavest = m.getTranslation().y > lavest ? m.getTranslation().y : lavest;
      minstY = m.entry(1, 1) < minstY ? m.entry(1, 1) : minstY;
    }
    expect(lavest, closeTo(7, 1.2), reason: 'down 7 px');
    expect(minstY, closeTo(.94, .02), reason: 'squashed to .94 tall');
    await g.up();
    expect(find.byType(CustomPaint), findsWidgets, reason: 'the rings are drawing');
    await tester.pump(const Duration(milliseconds: 700));
    expect(_klem(tester)!.isIdentity(), isTrue, reason: 'back at rest after 640 ms');
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  });

  testWidgets('reduced motion: no squash', (tester) async {
    await tester.pumpWidget(_kn(rolig: true));
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('knapp'))));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_klem(tester)!.isIdentity(), isTrue);
    await g.up();
  });
}
