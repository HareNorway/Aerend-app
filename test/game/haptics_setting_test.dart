import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';
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

  group('Step 7: the policies from /game/state and the perf fields (DH8, TH12)', () {
    Map<String, dynamic> state(Map<String, dynamic>? haptics) => {
          'status': 1,
          'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'bonus_granted': false, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
          'course': {
            'id': 9, 'week': '2026-W47', 'engine_version': 2,
            'params': {
              'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
              'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
              'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'kajakk_ahead_mm': 60000,
            },
            'rows': [{'d': 60000, 't': 'open', 'l': []}, {'d': 90000, 't': 'stokk', 'l': [0, 1, 2]}],
            'squalls': [],
          },
          'personal_best_m': null,
          'week_best_m': null,
          'losgrad': {'name': 'Lettmatros', 'lifetime_m': 0},
          'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
          'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
          'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': false},
          'vilkaar': ['Linje 1'],
          'profile': {'sound_on': false},
          if (haptics != null) 'haptics': haptics,
        };

    test('the state block: an older server keeps haptics on at full strength; the scale is kept in 0.5–1.0', () {
      final old = LopetState.fromJson(state(null))!;
      expect([old.hapticsEnabled, old.hapticsScale], [true, 1.0]);
      final off = LopetState.fromJson(state({'enabled': false, 'scale': 0.7}))!;
      expect([off.hapticsEnabled, off.hapticsScale], [false, 0.7]);
      expect(LopetState.fromJson(state({'enabled': true, 'scale': 0.1}))!.hapticsScale, 0.5);
    });

    testWidgets('scale 0.7 reaches the channel; enabled false silences; every run sends its tier and level', (t) async {
      a3Bootstrap();
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final k = FakeKanal();
      final h = GameHaptics(kanal: k, klokke: () => t.binding.clock.now().millisecondsSinceEpoch, ios: false, appSwitch: () => true);
      final api = _Api(state({'enabled': true, 'scale': 0.7}));
      await t.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: api, haptics: h, pollEvery: const Duration(seconds: 6))));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(k.scales.last, 0.7);

      // A run to the wall: the outbox carries the tier and the level.
      await t.tap(find.byKey(const Key('lopet-sett-seil')));
      await t.pump();
      expect(find.byKey(const Key('lopet-spill')), findsOneWidget, reason: 'sailing');
      for (var i = 0; i < 300 && find.byKey(const Key('lopet-slutt')).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('lopet-slutt')), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      await t.pump();
      final perf = LopetLager.utboks().first['perf'] as Map;
      expect([perf['haptics_tier'], perf['haptics_level']], ['rich', 'full']);

      api.json = state({'enabled': false, 'scale': 0.7});
      await t.pump(const Duration(seconds: 6));
      await t.pump();
      expect(h.virkelig, HaptikkNivaaValg.off);
      expect(h.play(HaptikkId.u05), HaptikkUtfall.silent);
      await t.pump(const Duration(seconds: 2));
    });
  });
}

class _Api extends LopetApi {
  _Api(this.json);
  Map<String, dynamic> json;

  @override
  Future<LopetState?> state(int orderId) async => LopetState.fromJson(json);

  @override
  Future<void> sound(bool on) async {}
}
