import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';

import '../a3/a3_fakes.dart';

/// Points plan Step 7 (game spec §3, §7, §8, §15; G-T2, T3, T6, T7): Fjordløpet's screens with a fake session.

Map<String, dynamic> _course() => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 1,
      'params': {
        'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
        'milestones_m': [200, 500, 1000], 'crate_m': 20, 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
        'vest_grace_ticks': 50, 'kajakk_ahead_mm': 60000,
      },
      // Open water for 300 m, then a wall: a run of about 300 m without input.
      'rows': [
        {'d': 60000, 't': 'open', 'l': [], 'c': -1},
        {'d': 300000, 't': 'stokk', 'l': [0, 1], 'c': -1},
        {'d': 301000, 't': 'boye', 'l': [2], 'c': -1},
      ],
      'squalls': [],
    };

Map<String, dynamic> _stateJson({String state = 'open', List<String> tokens = const ['rt_a', 'rt_b', 'rt_c'], bool bonus = false, String perk = 'none'}) => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': state, 'runs_allowed': tokens.length, 'runs_left': tokens.length, 'bonus_granted': bonus, 'perk': perk, 'tokens': tokens},
      'course': _course(),
      'personal_best_m': null,
      'week_best_m': null,
      'losgrad': {'name': 'Lettmatros', 'lifetime_m': 0},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': state == 'no_new_run'},
      'vilkaar': ['Linje 1', 'Linje 2', 'Linje 3', 'Linje 4', 'Linje 5', 'Linje 6', 'Linje 7'],
      'profile': {'sound_on': false},
    };

class _FakeApi extends LopetApi {
  _FakeApi(this.json);

  Map<String, dynamic>? json;
  int kall = 0;

  @override
  Future<LopetState?> state(int orderId) async {
    kall++;
    final j = json;
    return j == null ? null : LopetState.fromJson(j);
  }

  @override
  Future<void> sound(bool on) async {}
}

Widget _app(Widget home) => MaterialApp(home: home);

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() async => a3Bootstrap());

  testWidgets('G-T2: an open session shows the quay — three runs, «Sett seil», the rules page', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), pollEvery: const Duration(hours: 1))));
    await _settle(tester);

    expect(find.byKey(const Key('lopet-start')), findsOneWidget);
    expect(find.text(LopetCopy.ukensLed), findsOneWidget);
    expect(find.text(LopetCopy.seilaserIgjen(3)), findsOneWidget);
    expect(find.byKey(const Key('lopet-sett-seil')), findsOneWidget);
    expect(find.byKey(const Key('lopet-sjokort')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lopet-vilkaar-knapp')));
    await tester.pumpAndSettle();
    expect(find.text('Linje 7'), findsOneWidget, reason: 'the seven lines from the panel');
  });

  testWidgets('G-T3: three runs played — no fourth, also after a restart (the tokens are spent on the phone)', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = _FakeApi(_stateJson());
    final s = LopetState.fromJson(_stateJson())!;
    for (final t in ['rt_a', 'rt_b', 'rt_c']) {
      await LopetLager.lagre(token: t, s: s, inputs: const [], result: const {'distance_m': 120, 'ticks': 600, 'crates': 0}, startedMs: 0);
    }
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: api, pollEvery: const Duration(hours: 1))));
    await _settle(tester);
    expect(find.byKey(const Key('lopet-sett-seil')), findsNothing);
    expect(find.text(LopetCopy.nesteSeilas), findsOneWidget);
    expect(LopetLager.utboks(), hasLength(3), reason: 'kept for Step 8 to submit');
  });

  testWidgets('no new run when the courier is two minutes away', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: _FakeApi(_stateJson(state: 'no_new_run')), pollEvery: const Duration(hours: 1))));
    await _settle(tester);
    expect(find.byKey(const Key('lopet-sett-seil')), findsNothing);
    expect(find.text(LopetCopy.snartFremme), findsOneWidget);
  });

  testWidgets('G-T6: the courier at the door ends the run; its distance counts and the run is kept', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), pollEvery: const Duration(hours: 1))));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('lopet-sett-seil')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // three seconds of sailing
    }
    LopetSignaler.send(LopetSignal.vedDora);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('lopet-slutt')), findsOneWidget, reason: 'ended at once');
    expect(find.byKey(const Key('lopet-slutt-dora')), findsOneWidget);
    expect(find.text(LopetCopy.vedDora), findsOneWidget);
    final m = int.parse((tester.widget<Text>(find.byKey(const Key('lopet-slutt-meter'))).data ?? '0 m').split(' ').first);
    expect(m, greaterThan(20), reason: 'the distance reached counts');
    expect(LopetLager.utboks().single['token'], 'rt_a');
  });

  testWidgets('G-T7: the app going to the background pauses; it resumes with 3 · 2 · 1', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), pollEvery: const Duration(hours: 1))));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('lopet-sett-seil')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsOneWidget);
    final meter = tester.widget<Text>(find.byKey(const Key('lopet-meter'))).data;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<Text>(find.byKey(const Key('lopet-meter'))).data, meter, reason: 'nothing moves while paused');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.byKey(const Key('lopet-fortsett')));
    await tester.pump();
    expect(find.text(LopetCopy.fortsettOm(3)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(LopetCopy.fortsettOm(2)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsNothing, reason: 'sailing again');

    // A courier message pauses too.
    LopetSignaler.send(LopetSignal.trengerDeg);
    await tester.pump();
    expect(find.text(LopetCopy.trengerDeg), findsOneWidget);
  });

  testWidgets('the window closed: no game, a way back to Sporing', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(LopetScreen(orderId: 42, api: _FakeApi(null), pollEvery: const Duration(hours: 1))));
    await _settle(tester);
    expect(find.byKey(const Key('lopet-stengt')), findsOneWidget);
  });

  test('the end screen points: the highest threshold, +personal best once, capped', () {
    final s = LopetState.fromJson(_stateJson())!;
    expect(s.pointsFor([200]), 3);
    expect(s.pointsFor([200, 500]), 6, reason: 'not added together');
    expect(s.pointsFor([200, 500, 1000], personalBest: true), 15, reason: '12 + 3, cap 15');
    expect(s.pointsFor(const []), 0);
  });

  test('entry: the order snapshot drives every entry point; a closed one clears it', () {
    LopetPort.fraSporing(42, {'open': true, 'runs_left': 2});
    expect(LopetPort.status.value?.orderId, 42);
    expect(LopetPort.status.value?.runsLeft, 2);
    LopetPort.fraSporing(42, {'open': false, 'runs_left': 0});
    expect(LopetPort.status.value, isNull);
  });

  test('pushes: the courier at the door ends a run; a message or a CRITICAL notification pauses', () async {
    final got = <LopetSignal>[];
    final sub = LopetSignaler.stream.listen(got.add);
    LopetSignaler.fraPush({'type': 'customer.order.at_door'});
    LopetSignaler.fraPush({'type': 'customer.courier_message'});
    LopetSignaler.fraPush({'class': 'critical', 'type': 'x'});
    LopetSignaler.fraPush({'type': 'customer.insight.weekly_summary'});
    await Future<void>.delayed(Duration.zero);
    expect(got, [LopetSignal.vedDora, LopetSignal.trengerDeg, LopetSignal.trengerDeg]);
    await sub.cancel();
  });
}
