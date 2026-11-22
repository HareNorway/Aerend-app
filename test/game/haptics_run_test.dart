import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';

import '../a3/a3_fakes.dart';
import 'haptics_rules_test.dart' show FakeKanal;

/// Fjordløpet haptics plan Step 4 (haptics spec §4.1, §6): the run's haptics — the engine's events per tick through
/// GameHaptics, and the screen's hooks (H14, the gates, H13 and the silence after it, the stop on pause/background).

const _params = {
  'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
  'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
  'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'landmark_near_mm': 150000, 'kajakk_ahead_mm': 60000,
};

Map<String, dynamic> _course() => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 2,
      'params': _params,
      'rows': [
        {'d': 60000, 't': 'open', 'l': []},
        {'d': 230000, 't': 'stokk', 'l': [0, 1]},
        {'d': 231000, 't': 'boye', 'l': [2]},
      ],
      'crates': [for (var i = 0; i < 4; i++) {'d': 40000 + i * 9000, 'l': 1}],
      'landmarks': const [],
      'squalls': const [],
    };

Map<String, dynamic> _stateJson() => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'bonus_granted': false, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(),
      'personal_best_m': null,
      'week_best_m': null,
      'losgrad': {'name': 'Lettmatros', 'lifetime_m': 0},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': false},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
    };

class _FakeApi extends LopetApi {
  _FakeApi(this.json);
  final Map<String, dynamic> json;

  @override
  Future<LopetState?> state(int orderId) async => LopetState.fromJson(json);

  @override
  Future<void> sound(bool on) async {}
}

void main() {
  test('a scripted run: crates in a row, a lane change, the collision last — one pattern per tick', () async {
    var now = 0;
    final k = FakeKanal();
    final h = GameHaptics(kanal: k, klokke: () => now, ios: false);
    await h.prepare();
    final loop = FjordLoop(FjordSim(_course(), 'none'));
    final rows = <int>[];
    loop.onTickEvents = (t, ev) {
      if (ev & FjordSim.evCrate != 0) rows.add(h.rad + 1);
      h.tickEvents(t, ev);
      if (ev & FjordSim.evCrate != 0) rows[rows.length - 1] = h.rad;
    };
    for (var t = 0; t < 4000 && !loop.done; t++) {
      now = (t * 1000 / 60).round();
      if (t == 700) loop.input(1); // a change to lane 2, carried out (H01)…
      if (t == 760) loop.input(-1); // …and back
      loop.step();
    }
    expect(loop.done, isTrue);
    expect(k.played.last, 'h13', reason: 'the collision');
    expect(k.played.where((p) => p.startsWith('h02')).toList(), isNotEmpty);
    expect(rows, [1, 2, 3, 4], reason: 'the crates 9 m apart are one row');
    expect(k.played, contains('h01'));
    expect(h.pulsStoppet, isTrue, reason: 'a collision ends the pulse');
  });

  testWidgets('the screen: H14 at the start, Bøye 1, H13 at the collision; paused and background hold it', (tester) async {
    a3Bootstrap();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final k = FakeKanal();
    final h = GameHaptics(kanal: k, klokke: () => tester.binding.clock.now().millisecondsSinceEpoch, ios: false);
    await tester.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), haptics: h, pollEvery: const Duration(hours: 1))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('lopet-sett-seil')));
    await tester.pump();
    // «Sett seil» plays U01; control starts on the same moment here (no transition in tests), so H14 — lower — is
    // dropped by «one at a time».
    expect(k.played.first, 'u01');
    expect(h.holdt, isFalse);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsOneWidget);
    expect(h.holdt, isTrue, reason: 'nothing plays in the background');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(h.holdt, isTrue, reason: 'still paused');
    await tester.tap(find.byKey(const Key('lopet-fortsett')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(h.holdt, isFalse);
    expect(k.played.where((p) => p == 'h14'), hasLength(1), reason: 'control starts again after 3 · 2 · 1');

    for (var i = 0; i < 300 && find.byKey(const Key('lopet-slutt')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('lopet-slutt')), findsOneWidget);
    expect(k.played, contains('h06'), reason: 'Bøye 1 at 200 m');
    expect(k.played.last, 'h13');
    expect(k.played.where((p) => p.startsWith('h02')), isNotEmpty);
  });
}
