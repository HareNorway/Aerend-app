import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:aerend_customer/game/fjordlopet/lopet_lyd.dart';
import 'package:aerend_customer/game/fjordlopet/nearest_goal.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';

import '../a3/a3_fakes.dart';

/// Fjordløpet v1.3 plan Step 6 (spec v1.3 §4.6, §5.2, §5.5–5.7, §12.1; T22, T24, T25): the screens of v1.3.

const _params = {
  'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
  'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
  'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'kajakk_ahead_mm': 60000, 'landmark_near_mm': 150000,
  'generator': {
    'landmark_set': [
      {'k': 'fyr', 'nb': 'fyret', 'en': 'the lighthouse'},
    ],
  },
};

/// A log over lanes 1–2 at 30 m with the lighthouse 10 m before it.
Map<String, dynamic> _course() => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 2,
      'params': _params,
      'rows': [
        {'d': 30000, 't': 'stokk', 'l': [0, 1]},
        {'d': 400000, 't': 'boye', 'l': [0, 1, 2]},
      ],
      'crates': [],
      'landmarks': [
        {'d': 20000, 'k': 'fyr', 's': 1},
      ],
      'squalls': [],
    };

Map<String, dynamic> _stateJson({Map<String, dynamic>? ghost}) => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(),
      'personal_best_m': 100,
      'losgrad': {'name': 'Lettmatros'},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'no_new_run': false},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
      'ghost': ghost,
      'rival': {'place': 30, 'name': 'Seiler 30', 'distance_m': 42},
      'ladder_top': [
        {'place': 1, 'name': 'Kari', 'best_m': 900, 'me': false},
      ],
      'my_runs': [
        {'distance_m': 25, 'end_cause': {'obstacle': 'stokk', 'row': 0, 'landmark': 'fyr'}},
      ],
      'badges': [
        {'key': 'stalnerver', 'name': 'Stålnerver', 'metric': 'near_misses', 'target': 10, 'progress': 3, 'done': false},
        {'key': 'kassejeger', 'name': 'Kassejeger', 'metric': 'crates', 'target': 40, 'progress': 0, 'done': false},
      ],
      'cosmetics': {
        'items': [
          {'item': 'wake_mint', 'kind': 'wake', 'stars': 2, 'nb': 'Kjølvann i mint', 'en': 'Mint wake'},
        ],
        'equipped': {'pennant': null, 'wake': null, 'figurehead': null},
      },
      'weeks_sailed': 4,
    };

class _Api extends LopetApi {
  _Api(this.json);

  final Map<String, dynamic> json;
  Map<String, String?>? equipped;

  @override
  Future<LopetState?> state(int orderId) async => LopetState.fromJson(json);

  @override
  Future<bool> equip(Map<String, String?> e) async {
    equipped = e;
    return true;
  }

  @override
  Future<void> sound(bool on) async {}
}

Future<void> _open(WidgetTester t, _Api api, {Size size = const Size(1170, 2532), double dpr = 3}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: api, pollEvery: const Duration(hours: 1))));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() async => a3Bootstrap());

  group('the nearest goal (spec §4.6 line 3, T25)', () {
    test('the smallest gap wins: the rival 12 m ahead over the next gate', () {
      final g = FjordGoal.of(distanceM: 500, milestones: [200, 500, 1000], bestM: 480, rival: (30, 'Seiler 30', 512),
          ladder: [(1, 'Kari', 900, false)]);
      expect([g!.type, g.name, g.gapM], ['rival', 'Seiler 30', 12]);
      expect(LopetCopy.maalSeiler(g.name, g.gapM), contains('12 m'));
    });

    test('a badge that lacks a fifth of its target or less takes the line', () {
      final g = FjordGoal.of(distanceM: 500, milestones: [200, 500, 1000], badges: [('Kassejeger', 'crates', 40, 36, false)]);
      expect([g!.type, g.remaining], ['badge', 4]);
      expect(LopetCopy.maalMerke(g.name, g.metric, g.remaining), contains('4'));
      expect(FjordGoal.of(distanceM: 500, milestones: [1000], badges: [('Kassejeger', 'crates', 40, 31, false)])!.type, 'milestone');
    });

    test('nothing ahead: no line', () => expect(FjordGoal.of(distanceM: 2000, milestones: [200, 500, 1000]), isNull));
  });

  test('T22: the ghost repeats the best run tick for tick and stops at its flag', () {
    const inputs = [FjordInput(50, 1), FjordInput(400, -1)];
    final best = FjordEngine.run(_course(), 'none', inputs);
    // The player sails a longer line (the ghost only moves while the run goes on), past the ghost's end.
    final loop = FjordLoop(FjordSim(_course(), 'none'), ghost: FjordSim(_course(), 'none'), ghostTicks: best.ticks - 200, ghostInputs: inputs);
    for (var i = 0; i < best.ticks && !loop.done; i++) {
      if (loop.sim.tick == 50) loop.input(1);
      loop.step();
    }
    expect(loop.ghost!.result().toJson(), FjordEngine.run(_course(), 'none', inputs, stopAt: best.ticks - 200).toJson());
    expect(loop.ghost!.tick, best.ticks - 200, reason: 'it stops at its flag');
    expect(loop.ghostMm(), loop.ghost!.u / 60, reason: 'and stays there');
  });

  testWidgets('T24: on the smallest screen lines 1–5 fit without scrolling — the log after the lighthouse, the goal, the button', (t) async {
    await _open(t, _Api(_stateJson()), size: const Size(750, 1334), dpr: 2);
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    for (var i = 0; i < 260 && find.byKey(const Key('lopet-slutt')).evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    await t.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('lopet-slutt')), findsOneWidget);
    expect(find.text(LopetCopy.aarsak('stokk', 'fyret', int.parse((t.widget<Text>(find.byKey(const Key('lopet-slutt-meter'))).data ?? '0').split(' ').first))),
        findsOneWidget);
    expect(find.byKey(const Key('lopet-slutt-maal')), findsOneWidget);
    final screen = t.view.physicalSize / t.view.devicePixelRatio;
    for (final k in ['lopet-slutt-meter', 'lopet-slutt-aarsak', 'lopet-slutt-maal', 'lopet-seil-igjen']) {
      expect(t.getRect(find.byKey(Key(k))).bottom, lessThan(screen.height), reason: '$k visible without scrolling');
    }
  });

  testWidgets('the start screen: weeks sailed, the rival in the Ukelisten tile, the badges in the Ukeliste sheet; the chart opens full screen', (t) async {
    await _open(t, _Api(_stateJson()));
    expect(find.textContaining(LopetCopy.uker(4)), findsOneWidget);
    // Design 21 Nov plan Step 7: the rival is the Ukelisten tile's line; the badges moved to the Ukeliste sheet.
    expect(find.byKey(const Key('lopet-rival')), findsOneWidget);
    expect(find.textContaining('Seiler 30'), findsOneWidget);
    expect(find.byKey(const Key('lopet-merker')), findsNothing);
    expect(find.byKey(const Key('lopet-neste-maal')), findsOneWidget);
    expect(find.byKey(const Key('lopet-losgrad')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('lopet-ukeliste-knapp')));
    await t.tap(find.byKey(const Key('lopet-ukeliste-knapp')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lopet-merker')), findsOneWidget);
    expect(find.textContaining('3 / 10'), findsOneWidget);
    Navigator.of(t.element(find.byKey(const Key('lopet-merker')))).pop();
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('lopet-sjokort')));
    await t.tap(find.byKey(const Key('lopet-sjokort')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lopet-sjokort-stor')), findsOneWidget);
    expect(find.text(LopetCopy.herGikkDetGalt), findsOneWidget);
  });

  testWidgets('pynt på båten: unlocked items with their stars; the choice goes to the server', (t) async {
    final api = _Api(_stateJson());
    await _open(t, api);
    await t.tap(find.byKey(const Key('lopet-pynt-knapp')));
    await t.pumpAndSettle();
    // Design 21 Nov plan Step 7: the tiles per place; a tap on an unlocked one is the choice, at once.
    expect(find.byKey(const Key('lopet-pynt')), findsOneWidget);
    expect(find.text('Kjølvann i mint'), findsOneWidget);
    expect(find.text('★'), findsOneWidget, reason: 'two stars: one extra');
    await t.ensureVisible(find.byKey(const Key('lopet-pynt-wake_mint')));
    await t.tap(find.byKey(const Key('lopet-pynt-wake_mint')));
    await t.pumpAndSettle();
    expect(api.equipped, {'pennant': null, 'wake': 'wake_mint', 'figurehead': null});
  });

  test('the sounds: rendered WAV files for every event; silent unless turned on, and safe without a player', () {
    for (final n in [...LopetLyd.navn, for (var k = 0; k < 15; k++) 'kasse_$k']) {
      final f = File('assets/game/sounds/$n.wav');
      expect(f.existsSync(), isTrue, reason: n);
      final b = f.readAsBytesSync();
      expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
      expect(b[24] | b[25] << 8, 22050);
    }
    final lyd = LopetLyd();
    expect(() => lyd..spill('treff')..kasse(), returnsNormally);
    lyd.on = true;
    expect(() => lyd..spill('treff')..kasse(), returnsNormally, reason: 'not loaded: simply not heard');
  });

  testWidgets('the HUD shows the vest meter during the run', (t) async {
    await _open(t, _Api(_stateJson()));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('lopet-maaler')), findsOneWidget);
    expect(find.byKey(const Key('lopet-livboye')), findsNothing, reason: 'an empty meter');
  });
}
