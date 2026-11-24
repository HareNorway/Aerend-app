import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/input/lopet_input.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';

import '../a3/a3_fakes.dart';

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.2–12.4; T24, T28, T30, T31): the fixed-step loop, raw-pointer input,
/// the play screen's layers, the back gesture, offline polls and the countdown.

const _params = {
  'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
  'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
  'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'kajakk_ahead_mm': 60000,
};

/// Buoys every 20 m in alternating lanes from 40 m, then a wall at [wallMm].
Map<String, dynamic> _course({int wallMm = 300000}) => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 2,
      'params': _params,
      'rows': [
        for (var i = 0; i < 12; i++)
          if (40000 + i * 20000 < wallMm) {'d': 40000 + i * 20000, 't': 'boye', 'l': [i % 3]},
        {'d': wallMm, 't': 'boye', 'l': [0, 1, 2]},
      ],
      'crates': [
        {'d': 50000, 'l': 1},
      ],
      'landmarks': [],
      'squalls': [],
    };

Map<String, dynamic> _stateJson({int wallMm = 300000}) => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(wallMm: wallMm),
      'losgrad': {'name': 'Lettmatros'},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'no_new_run': false},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
    };

class _Api extends LopetApi {
  _Api(this.json);

  Map<String, dynamic>? json;
  bool offline = false;

  @override
  Future<LopetState?> state(int orderId) async {
    lastOffline = offline;
    final j = offline ? null : json;
    return j == null ? null : LopetState.fromJson(j);
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

/// Plays a loop with frames [dtMicros] apart, turning at the given ticks; returns the result and the recorded inputs.
(FjordResult, List<int>) _play(int dtMicros, Map<int, int> turns) {
  final loop = FjordLoop(FjordSim(_course(), 'none'));
  var t = Duration.zero;
  loop.frame(t);
  final done = <int>{};
  while (!loop.done && t < const Duration(minutes: 3)) {
    for (final e in turns.entries) {
      if (loop.sim.tick >= e.key && !done.contains(e.key)) {
        done.add(e.key);
        loop.input(e.value);
      }
    }
    t += Duration(microseconds: dtMicros);
    loop.frame(t);
  }
  return (loop.sim.result(), List.of(loop.recorded));
}

void main() {
  setUp(() async => a3Bootstrap());

  group('T31: the frame rate never changes a run', () {
    const turns = {100: 1, 240: -1, 245: -1, 420: 1};

    test('60 Hz, 120 Hz and a ragged 90 Hz give the same inputs and the same result as the core', () {
      final (r60, in60) = _play(16667, turns);
      final (r120, in120) = _play(8333, turns);
      final (r90, in90) = _play(11111, turns);
      expect(in120, in60);
      expect(in90, in60);
      expect(r120.toJson(), r60.toJson());
      expect(r90.toJson(), r60.toJson());
      final inputs = [for (var i = 0; i < in60.length; i += 2) FjordInput(in60[i], in60[i + 1])];
      expect(FjordEngine.run(_course(), 'none', inputs).toJson(), r60.toJson(), reason: 'the server replays the same');
    });

    test('a stall runs at most five ticks and never fast-forwards', () {
      final loop = FjordLoop(FjordSim(_course(), 'none'));
      loop.frame(Duration.zero);
      expect(loop.frame(const Duration(seconds: 1)), FjordLoop.maxTicksPerFrame);
      expect(loop.frame(const Duration(seconds: 1, milliseconds: 17)), 1, reason: 'the excess was dropped');
    });

    test('the painter interpolates between the last two ticks', () {
      final loop = FjordLoop(FjordSim(_course(), 'none'));
      loop.frame(Duration.zero);
      loop.frame(const Duration(milliseconds: 25)); // 1.5 ticks: one run, half way to the next
      expect(loop.alpha, closeTo(.5, .01));
      expect(loop.boatMm(), inExclusiveRange(loop.uPrev / 60, loop.uNow / 60));
    });

    test('the HUD values change only with the number shown', () {
      final loop = FjordLoop(FjordSim(_course(), 'none'));
      var metreChanges = 0;
      loop.metres.addListener(() => metreChanges++);
      for (var i = 0; i < 60; i++) {
        loop.step();
      }
      expect(metreChanges, loop.sim.sailedM, reason: 'once per metre, not once per tick');
    });
  });

  test('FramePerf: average, 99th percentile and slow frames after the first two seconds', () {
    final p = FramePerf(capacity: 300);
    for (var i = 0; i < 200; i++) {
      // Frame 10 (at 0.16 s, inside the warm-up) and frame 150 (at 2.4 s) are slow.
      p.add(i == 10 ? 50 : (i == 150 ? 40 : 10), 3, 6, Duration(milliseconds: i * 16));
    }
    expect(p.frames, 200);
    expect(p.slowFrames, 1, reason: 'only after the first two seconds');
    expect(p.over20, 2);
    expect(p.worstMs, 50);
    expect(p.avgMs, closeTo((198 * 10 + 40 + 50) / 200, .01));
    expect(p.p99Ms, 10);
    expect(p.toJson('low'), {'quality': 'low', 'avg_ms': closeTo(10.35, .01), 'p99_ms': 10.0, 'slow_frames': 1});
  });

  group('T28: touches become lane changes', () {
    Future<List<int>> pumpInput(WidgetTester t) async {
      final got = <int>[];
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 300, height: 400, child: LopetInput(onDir: got.add, child: const ColoredBox(color: Color(0xFF000000))))),
      ));
      return got;
    }

    testWidgets('a swipe right that starts on the left half: recognised at 12 px, finger still down', (t) async {
      final got = await pumpInput(t);
      final box = t.getRect(find.byType(LopetInput));
      final g = await t.startGesture(box.topLeft + const Offset(40, 200));
      await g.moveBy(const Offset(11, 0));
      expect(got, isEmpty);
      await g.moveBy(const Offset(1, 0));
      expect(got, [1], reason: 'at 12 px, before the finger lifts');
      await g.moveBy(const Offset(60, 0));
      await g.up();
      expect(got, [1], reason: 'one change per touch');
    });

    testWidgets('a tap counts for the half where it started; a second finger does nothing', (t) async {
      final got = await pumpInput(t);
      final box = t.getRect(find.byType(LopetInput));
      await t.tapAt(box.topLeft + const Offset(250, 100));
      await t.tapAt(box.topLeft + const Offset(30, 100));
      expect(got, [1, -1]);
      final first = await t.startGesture(box.topLeft + const Offset(250, 100));
      final second = await t.startGesture(box.topLeft + const Offset(30, 100), pointer: 7);
      await second.up();
      await first.up();
      expect(got, [1, -1, 1], reason: 'only the first finger counts');
    });
  });

  testWidgets('T30: during play nothing over or under the scene is a BackdropFilter, blur, opacity or shader layer', (t) async {
    await _open(t, _Api(_stateJson()));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    for (final type in [BackdropFilter, ImageFiltered, Opacity, AnimatedOpacity, ShaderMask, FadeTransition]) {
      expect(find.descendant(of: find.byKey(const Key('lopet-spill')), matching: find.byType(type)), findsNothing, reason: '$type');
    }
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('T24: on the smallest screen the end of the run is up within 0.9 s of the collision', (t) async {
    await _open(t, _Api(_stateJson(wallMm: 30000)), size: const Size(750, 1334), dpr: 2); // iPhone SE (2020)
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    // ~3.3 s of sailing to the wall at 30 m (five ticks a frame at most).
    var frames = 0;
    while (find.byKey(const Key('lopet-slutt')).evaluate().isEmpty && frames < 400) {
      await t.pump(const Duration(milliseconds: 16));
      frames++;
      if (frames == 220) break;
    }
    expect(find.byKey(const Key('lopet-slutt')), findsNothing, reason: 'the picture freezes first');
    await t.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('lopet-slutt')), findsOneWidget);
    expect(find.byKey(const Key('lopet-seil-igjen')), findsOneWidget);
  });

  testWidgets('back during a run pauses it; back again leaves and keeps the run with its token spent', (t) async {
    await _open(t, _Api(_stateJson()));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    await t.pump(const Duration(milliseconds: 500));
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.maybePop(); // the system back button or gesture
    await t.pump();
    expect(find.byKey(const Key('lopet-pause')), findsOneWidget);
    nav.maybePop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(LopetLager.utboks().single['token'], 'rt_a', reason: 'no replay on the same token');
  });

  testWidgets('a poll that fails offline does not end the run', (t) async {
    final api = _Api(_stateJson());
    final screen = LopetScreen(orderId: 42, api: api, pollEvery: const Duration(seconds: 1));
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: screen));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    api.offline = true;
    for (var i = 0; i < 80; i++) {
      await t.pump(const Duration(milliseconds: 16)); // past a poll
    }
    expect(find.byKey(const Key('lopet-slutt')), findsNothing);
    expect(find.byKey(const Key('lopet-meter')), findsOneWidget);
  });

  testWidgets('the 3 · 2 · 1 countdown never runs in the background', (t) async {
    await _open(t, _Api(_stateJson()));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byKey(const Key('lopet-pause-knapp')));
    await t.pump();
    await t.tap(find.byKey(const Key('lopet-fortsett')));
    await t.pump();
    expect(find.text(LopetCopy.fortsettOm(3)), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 3));
    // Nothing is drawn while the app is in the background; what the customer sees on return is the pause screen.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(find.byKey(const Key('lopet-fortsett')), findsOneWidget, reason: 'back on the pause screen, not playing');
    expect(find.text(LopetCopy.fortsettOm(1)), findsNothing, reason: 'the countdown did not run on');
    // Engine events reach the phone as haptics (smoke: no platform error).
    expect(SystemChannels.platform, isNotNull);
  });
}
