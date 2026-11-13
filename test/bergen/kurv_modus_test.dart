import 'package:aerend_customer/screens/bergen/kasse/kasse_copy.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../layout/reduced_motion_harness.dart';

/// Bug-11 (TestFlight feedback 2026-11-14, «the toggle here has a bug»): Kassen's Levering / Henting labels flipped
/// white/dark on the tap while the thumb took .5 s to slide, so mid-way both vanished (white on cream, dark on teal).
void main() {
  setUpAll(() async => bootstrapGlobals());

  testWidgets('Levering / Henting: on every frame of the slide the white labels sit exactly on the thumb', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var pickup = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => Center(
              child: SizedBox(width: 358, child: KurvModus(pickup: pickup, onMode: (m) => set(() => pickup = m))),
            ),
          ),
        ),
      ),
    );
    final start = tester.getRect(find.byKey(const Key('a1_kasse_modus_tommel'))).left;
    await tester.tap(find.byKey(const Key('a1_kasse_henting')));
    final lefts = <double>[];
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final tommel = tester.getRect(find.byKey(const Key('a1_kasse_modus_tommel')));
      lefts.add(tommel.left);
      final klipp = tester.renderObjectList<RenderClipRect>(find.descendant(of: find.byType(KurvModus), matching: find.byType(ClipRect))).toList();
      expect(klipp, hasLength(2));
      for (final k in klipp) {
        final r = (k.clipper! as KasseTommelKlipp).getClip(k.size);
        expect(k.localToGlobal(Offset(r.left, 0)).dx, closeTo(tommel.left, .5), reason: 'frame $i: white label clip vs thumb $tommel');
        expect(r.width, closeTo(tommel.width, .5));
      }
    }
    await tester.pumpAndSettle();
    expect(pickup, isTrue);
    final slutt = tester.getRect(find.byKey(const Key('a1_kasse_modus_tommel'))).left;
    // The frames above caught the thumb on its way, between the two labels — where the old labels vanished.
    expect(lefts.any((l) => l > start + 20 && l < slutt - 20), isTrue, reason: 'thumb $start → $slutt, frames $lefts');
    // One label each for the finders / screen reader (the white copies are RichText inside ExcludeSemantics).
    expect(find.text(KasseCopy.a1_kasse_levering), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_henting), findsOneWidget);
  });
}
