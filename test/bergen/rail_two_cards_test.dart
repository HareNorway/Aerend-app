import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';

/// A rail of two cards (Populært i kveld with two products): the card the
/// rail calls «front» is drawn in front — at full opacity — after every turn,
/// not only the first two. (The ring used to step 120° with only two cards,
/// so from the third turn on both sat behind and the front card looked
/// see-through.)
void main() {
  tearDown(() => BergenPerf.force(null));

  testWidgets('two cards: the front card is opaque after every auto-turn', (tester) async {
    BergenPerf.force(BergenTier.full);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? front;
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Scaffold(
            body: BergenRail(
              height: 360,
              cardTop: 40,
              count: 2,
              intervalMs: 3000,
              onOpen: (_) {},
              builder: (context, i, isFront) {
                if (isFront) front = i;
                return SizedBox(height: 120, child: Text('card$i'));
              },
            ),
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 6; turn++) {
      // A turn every 3 s; measure once its 1250 ms glide has settled.
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 1300));
      final f = front!;
      final op = tester.widget<Opacity>(find.ancestor(of: find.text('card$f'), matching: find.byType(Opacity)).first);
      expect(op.opacity, closeTo(1, .01), reason: 'turn $turn: the front card $f is drawn at opacity ${op.opacity}');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
