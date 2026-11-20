import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';

/// Fjordløpet v1.3 plan Step 1 (spec v1.3 §4.1, §4.4, §9): engine version 2 — the same scenarios as Hare-AdminPanel
/// `tests/Feature/Game/V13EngineTest.php`, so both cores are held to the same rules (the golden runs hold them to the
/// same numbers).
void main() {
  const params = {
    'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
    'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
    'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'landmark_near_mm': 150000,
    'kajakk_ahead_mm': 60000,
  };

  Map<String, dynamic> course(List<Map> rows, {List<Map> crates = const [], List<Map> landmarks = const []}) =>
      {'params': params, 'rows': rows, 'crates': crates, 'landmarks': landmarks};

  Map wall(int d) => {'d': d, 't': 'boye', 'l': [0, 1, 2]};
  List<Map> crates(int n, int lane) => [for (var i = 0; i < n; i++) {'d': 60000 + i * 5000, 'l': lane}];

  /// The tick the boat reaches [d] mm.
  int tickAt(int d) {
    var u = 0;
    for (var t = 0;; t++) {
      final s = 9000 + (120 * t) ~/ 60;
      u += s < 24000 ? s : 24000;
      if (u >= d * 60) return t;
    }
  }

  FjordResult run(Map<String, dynamic> c, List<List<int>> inputs, {String perk = 'none', int? stopAt}) =>
      FjordEngine.run(c, perk, [for (final i in inputs) FjordInput(i[0], i[1])], stopAt: stopAt);

  test('engine version 2', () => expect(FjordEngine.version, 2));

  test('T19: the same path with five crates and with none gives the same distance', () {
    final w = run(course([wall(300000)], crates: crates(5, 1)), []);
    final wo = run(course([wall(300000)]), []);
    expect(w.crates, 5);
    expect(wo.crates, 0);
    expect(w.distanceM, wo.distanceM);
    expect(w.ticks, wo.ticks);
    expect(w.vestUses, 0);
  });

  test('T20: eight crates, a hit, then a second hit', () {
    final rows = [
      {'d': 150000, 't': 'boye', 'l': [1]},
      {'d': 300000, 't': 'boye', 'l': [1]},
    ];
    final r = run(course(rows, crates: crates(8, 1)), []);
    expect(r.crates, 8);
    expect(r.vestUses, 1);
    expect(r.ended, 'collision');
    expect(r.hitRow, 1);
    expect(run(course(rows, crates: crates(7, 1)), []).hitRow, 0);
  });

  test('a hit with the vest gives one second without hits', () {
    final r = run(
        course([
          {'d': 150000, 't': 'boye', 'l': [1]},
          {'d': 160000, 't': 'boye', 'l': [1]},
          wall(300000),
        ]),
        [],
        perk: 'full_meter');
    expect(r.vestUses, 1);
    expect(r.hitRow, 2);
  });

  test('full_meter starts with a vest; the v1 name vest is no perk', () {
    final c = course([
      {'d': 150000, 't': 'boye', 'l': [1]},
      wall(300000),
    ]);
    expect(run(c, []).hitRow, 0);
    expect(run(c, [], perk: 'full_meter').hitRow, 1);
    expect(run(c, [], perk: 'vest').toJson(), run(c, []).toJson());
  });

  test('T21: a change 0.2 s before an obstacle is a near miss, 0.8 s is not', () {
    final c = course([
      {'d': 150000, 't': 'boye', 'l': [1]},
      wall(300000),
    ], crates: crates(7, 1));
    final tc = tickAt(150000);
    final close = run(c, [
      [tc - 12, 1]
    ]);
    expect(close.nearMisses, 1);
    expect(close.vestUses, 1);
    final early = run(c, [
      [tc - 48, 1]
    ]);
    expect(early.nearMisses, 0);
    expect(early.vestUses, 0);
    expect(early.hitRow, 1);
  });

  test('a near miss counts once per obstacle', () {
    final c = course([
      {'d': 150000, 't': 'stokk', 'l': [1, 2]},
      wall(300000),
    ]);
    expect(
        run(c, [
          [tickAt(150000) - 12, -1]
        ]).nearMisses,
        1);
  });

  test('a beffen that left the lane just before is a near miss', () {
    final tc = tickAt(150000);
    final st = tickAt(120000);
    Map<String, dynamic> beffen(int x) => course([
          {
            'd': 150000,
            't': 'beffen',
            'l': [],
            'p': {'x0': x - 20 * (tc - st), 'vx': 20, 'a': 30000, 'h': 450},
          },
          wall(300000),
        ]);
    final just = run(beffen(2000), []);
    expect(just.nearMisses, 1);
    expect(just.hitRow, 1);
    expect(run(beffen(2400), []).nearMisses, 0);
    expect(run(beffen(1900), []).hitRow, 0);
  });

  test('T27: an input during a change is held and the newest replaces it', () {
    final c = course([
      {'d': 60000, 't': 'boye', 'l': [0, 2]},
      wall(300000),
    ]);
    expect(tickAt(60000), greaterThan(120));
    expect(
        run(c, [
          [100, -1],
          [103, -1],
          [105, 1]
        ]).hitRow,
        1);
    expect(
        run(c, [
          [100, -1],
          [103, -1]
        ]).hitRow,
        0);
    expect(
        run(c, [
          [100, -1],
          [107, 1]
        ]).hitRow,
        1);
  });

  test('the end cause names the obstacle and the landmark before it', () {
    final near = run(
        course([
          {'d': 150000, 't': 'stokk', 'l': [0, 1]},
          wall(300000),
        ], landmarks: [
          {'d': 120000, 'k': 'fyret', 's': 1}
        ]),
        []);
    expect(near.endCause, {'obstacle': 'stokk', 'row': 0, 'landmark': 'fyret'});
    expect(near.distanceM, 150);
    final far = run(
        course([
          {'d': 250000, 't': 'stokk', 'l': [0, 1]},
          wall(300000),
        ], landmarks: [
          {'d': 60000, 'k': 'naust', 's': -1}
        ]),
        []);
    expect(far.endCause!['obstacle'], 'stokk');
    expect(far.endCause!['landmark'], isNull);
    expect(run(course([wall(300000)]), [], stopAt: 600).endCause, isNull);
  });

  test('T31 (core): stepping the sim tick by tick gives what run() gives, and events mark the feedback', () {
    final c = course([
      {'d': 150000, 't': 'boye', 'l': [1]},
      wall(300000),
    ], crates: crates(8, 1));
    final want = run(c, []);
    final sim = FjordSim(c, 'none');
    var crateEvents = 0, fullEvents = 0, vestEvents = 0, hitEvents = 0;
    while (!sim.done) {
      sim.stepTick(const []);
      if (sim.events & FjordSim.evCrate != 0) crateEvents++;
      if (sim.events & FjordSim.evMeterFull != 0) fullEvents++;
      if (sim.events & FjordSim.evVest != 0) vestEvents++;
      if (sim.events & FjordSim.evHit != 0) hitEvents++;
    }
    expect(sim.result().toJson(), want.toJson());
    expect([crateEvents, fullEvents, vestEvents, hitEvents], [8, 1, 1, 1]);
    expect(sim.crateTaken(7), isTrue);
  });
}
