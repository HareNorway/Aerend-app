import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/poeng/premie_ark.dart';

/// Points plan Step 3 (24des `phKrev`): a premie is claimed by holding for 900 ms, never by a tap.
void main() {
  testWidgets('a hold of 900 ms claims once; a tap or an early release claims nothing', (tester) async {
    var n = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 300, child: PremieHoldKnapp(onFull: () async => n++))))));

    await tester.tap(find.byType(PremieHoldKnapp));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(n, 0, reason: 'a tap');

    var g = await tester.startGesture(tester.getCenter(find.byType(PremieHoldKnapp)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(n, 0, reason: 'let go at 500 ms');

    g = await tester.startGesture(tester.getCenter(find.byType(PremieHoldKnapp)));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(n, 1, reason: 'held to full');
  });
}
