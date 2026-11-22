import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_vibrasjon.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart' show prefGetString;

import '../a3/a3_fakes.dart';
import 'haptics_rules_test.dart' show FakeKanal;

/// Fjordløpet haptics plan Step 6 (haptics spec §8, DH2, TH6): «Vibrasjon» Full · Dempet · Av.
void main() {
  late FakeKanal k;
  late GameHaptics h;

  Future<void> show(WidgetTester t, {HaptikkTier tier = HaptikkTier.rich, String? why, bool app = true}) async {
    a3Bootstrap();
    k = FakeKanal(tier, why);
    h = GameHaptics(kanal: k, klokke: () => t.binding.clock.now().millisecondsSinceEpoch, ios: false, appSwitch: () => app);
    await h.prepare();
    await t.pumpWidget(MaterialApp(home: Scaffold(backgroundColor: const Color(0xFF0C2A38), body: Center(child: SizedBox(width: 320, child: LopetVibrasjon(haptics: h))))));
  }

  testWidgets('the three choices; Dempet is stored and plays H03 at 0.7; Av silences everything (TH6)', (t) async {
    await show(t);
    expect(find.text(LopetCopy.vibrasjon), findsOneWidget);
    expect(find.text(LopetCopy.vibFull), findsOneWidget);
    await t.tap(find.byKey(const Key('lopet-vib-soft')));
    await t.pump();
    expect(h.nivaa, HaptikkNivaaValg.soft);
    expect(prefGetString(GameHaptics.prefNivaa), 'soft');
    expect(k.scales.last, .7, reason: 'Dempet at 0.7 on Rich');
    expect(k.played, ['h03'], reason: 'the choice is felt');
    expect(GameHaptics.lagretNivaa(), HaptikkNivaaValg.soft);

    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.byKey(const Key('lopet-vib-off')));
    await t.pump();
    expect(k.played, ['h03'], reason: 'Av plays nothing, not even the check');
    for (final id in HaptikkId.values) {
      expect(h.play(id), HaptikkUtfall.silent);
    }
    expect(GameHaptics.lagretNivaa(), HaptikkNivaaValg.off);
  });

  testWidgets('the app-wide «Vibrasjon» off: Av, disabled, with the Konto line (DH2)', (t) async {
    await show(t, app: false);
    expect(find.text(LopetCopy.vibKontoAv), findsOneWidget);
    await t.tap(find.byKey(const Key('lopet-vib-full')));
    await t.pump();
    expect(k.played, isEmpty);
    expect(h.nivaa, HaptikkNivaaValg.full, reason: 'the game\'s own setting is not changed');
    expect(h.virkelig, HaptikkNivaaValg.off);
  });

  testWidgets('the phone\'s vibration off: Av with «Telefonen din har slått av vibrasjon»', (t) async {
    await show(t, tier: HaptikkTier.off, why: 'system_off');
    expect(find.text(LopetCopy.vibTelefonAv), findsOneWidget);
    expect(find.text(LopetCopy.vibKontoAv), findsNothing);
  });

  testWidgets('a working phone shows no line', (t) async {
    await show(t);
    expect(find.byKey(const Key('lopet-vib-linje')), findsNothing);
  });
}
