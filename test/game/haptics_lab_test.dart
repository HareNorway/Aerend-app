import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_lab.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';

import 'haptics_rules_test.dart' show FakeKanal;

/// Fjordløpet haptics plan Step 8: the lab plays every pattern through GameHaptics, with the rules on or off.
void main() {
  testWidgets('the tier, a button per pattern, the crate step, the rules switch', (t) async {
    var now = 0;
    final k = FakeKanal(HaptikkTier.rich);
    final h = GameHaptics(kanal: k, klokke: () => now, ios: false);
    t.view.physicalSize = const Size(1200, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: HaptikkLab(haptics: h)));
    await t.pumpAndSettle();
    expect(find.text('Tier: rich'), findsOneWidget);
    for (final id in HaptikkId.values) {
      expect(find.byKey(Key('haptikk-lab-${id.name}')), findsOneWidget);
    }
    await t.tap(find.byKey(const Key('haptikk-lab-h13')));
    await t.pump();
    expect(k.played, ['h13']);
    expect(find.text('H13 · played'), findsOneWidget);
    // With the rules: a tick inside H13 is dropped.
    await t.tap(find.byKey(const Key('haptikk-lab-h01')));
    await t.pump();
    expect(find.text('H01 · dropped'), findsOneWidget);
    // Without: it plays alone.
    await t.tap(find.byKey(const Key('haptikk-lab-regler')));
    await t.pump();
    await t.tap(find.byKey(const Key('haptikk-lab-h01')));
    await t.pump();
    expect(k.played.last, 'h01');
    // The crate stepper reaches H02's step.
    await t.tap(find.byIcon(Icons.add));
    await t.tap(find.byIcon(Icons.add));
    await t.pump();
    await t.tap(find.byKey(const Key('haptikk-lab-h02')));
    await t.pump();
    expect(k.played.last, 'h02.3');
  });
}
