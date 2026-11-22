import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';
import 'package:aerend_customer/game/fjordlopet/render/lopet_loop.dart';
import 'package:aerend_customer/game/fjordlopet/sim/engine.dart';

/// A recording channel: what was prepared, played and stopped.
class FakeKanal implements HaptikkKanal {
  FakeKanal([this.tier = HaptikkTier.rich, this.why]);

  HaptikkTier tier;
  String? why;
  final List<String> calls = [];
  final List<double> scales = [];
  Map<String, Object>? table;

  List<String> get played => [for (final c in calls) if (c.startsWith('play:')) c.substring(5)];

  @override
  Future<({HaptikkTier tier, String? why})> capabilities() async => (tier: tier, why: why);

  @override
  Future<void> prepare(Map<String, Object> table, double scale) async {
    this.table = table;
    scales.add(scale);
    calls.add('prepare:$scale');
  }

  @override
  void play(String key) => calls.add('play:$key');

  @override
  void stop() => calls.add('stop');

  @override
  Future<void> release() async => calls.add('release');
}

/// Fjordløpet haptics plan Step 1 (haptics spec §5, §6, §4.3): the rules, with a fake clock and channel.
void main() {
  late int now;
  late FakeKanal k;
  late GameHaptics h;
  late List<String> ios;

  Future<GameHaptics> make({HaptikkTier tier = HaptikkTier.rich, bool isIos = false}) async {
    now = 0;
    k = FakeKanal(tier);
    ios = [];
    h = GameHaptics(kanal: k, klokke: () => now, ios: isIos, standardIos: ios.add);
    await h.prepare();
    return h;
  }

  group('the table', () {
    test('every pattern has an iPhone and an Android Rich entry, steps included', () {
      for (final id in HaptikkId.values) {
        if (id == HaptikkId.h02) {
          for (var n = 1; n <= 5; n++) {
            expect(kHaptikkIos['h02.$n'], isNotNull);
            expect(kHaptikkAndroid['h02.$n'], isNotNull);
          }
        } else if (id == HaptikkId.h09) {
          for (var b = 0; b <= 5; b++) {
            expect(kHaptikkIos['h09.$b'], isNotNull);
            expect(kHaptikkAndroid['h09.$b'], isNotNull);
          }
        } else {
          expect(kHaptikkIos[id.name], isNotNull, reason: id.name);
          expect(kHaptikkAndroid[id.name], isNotNull, reason: id.name);
        }
      }
    });

    test('no pattern is longer than 850 ms and nothing loops (spec §6)', () {
      for (final e in kHaptikkIos.entries) {
        for (final ev in e.value) {
          final end = ev[0] == 'T' ? ev[1] as int : ev[2] as int;
          expect(end, lessThanOrEqualTo(kMaksMs), reason: e.key);
        }
      }
      for (final e in kHaptikkAndroid.entries) {
        var t = 0;
        for (final p in e.value) {
          t += p[2] as int;
        }
        expect(t, lessThan(kMaksMs), reason: e.key);
      }
    });

    test('Android uses only the seven primitives, strengths on the 1.4 steps (spec §5.3)', () {
      for (final e in kHaptikkAndroid.entries) {
        for (final p in e.value) {
          expect(kAndroidPrimitiver, contains(p[0]), reason: e.key);
          expect([.35, .5, .7, 1.0], contains(p[1]), reason: e.key);
        }
      }
    });

    test('H02 grows with the row; H09 grows nearer «Din beste»; U11 is H08', () {
      final i = [for (var n = 1; n <= 5; n++) kHaptikkIos['h02.$n']![0][2] as double];
      expect(i, [.30, .36, .43, .52, .62]);
      final p = [for (var b = 0; b <= 5; b++) kHaptikkIos['h09.$b']![0][2] as double];
      for (var b = 1; b <= 5; b++) {
        expect(p[b], greaterThan(p[b - 1]));
      }
      expect(p.first, greaterThanOrEqualTo(.30));
      expect(p.last, lessThanOrEqualTo(.55));
      expect(kHaptikkIos['u11'], kHaptikkIos['h08']);
      expect(kHaptikkAndroid['u11'], kHaptikkAndroid['h08']);
      expect(haptikkSteg(HaptikkId.h09, metresLeft: 59), 0);
      expect(haptikkSteg(HaptikkId.h09, metresLeft: 5), 5);
      expect(haptikkSteg(HaptikkId.h02, step: 9), 5);
    });

    test('the levels and the priority of spec §3.1 and §6', () {
      expect(HaptikkNivaa.av(HaptikkId.h01), 1);
      expect(HaptikkNivaa.av(HaptikkId.h13), 5);
      expect(HaptikkNivaa.av(HaptikkId.h04), 3);
      expect(kHaptikkPrioritet.toSet().length, HaptikkId.values.length);
      const run = [
        HaptikkId.u05, HaptikkId.h13, HaptikkId.h05, HaptikkId.h12, HaptikkId.h10, HaptikkId.h08, HaptikkId.h07,
        HaptikkId.h06, HaptikkId.h04, HaptikkId.h03, HaptikkId.h11, HaptikkId.h02, HaptikkId.h14, HaptikkId.h01,
        HaptikkId.h09,
      ];
      for (var i = 1; i < run.length; i++) {
        expect(GameHaptics.rang(run[i - 1]), greaterThan(GameHaptics.rang(run[i])), reason: '${run[i - 1]} > ${run[i]}');
      }
    });

    test('prepare sends the table once, at the right scale', () async {
      await make();
      expect(k.scales, [1.0]);
      expect((k.table!['ios'] as Map).length, kHaptikkIos.length);
      await h.prepare();
      expect(k.scales, [1.0], reason: 'the same scale is not sent again');
    });
  });

  group('§6 rules', () {
    test('one at a time: a higher event stops a lower one; a lower one is dropped, never queued', () async {
      await make();
      expect(h.play(HaptikkId.h06), HaptikkUtfall.played); // Bøye 1, 120 ms
      now = 30;
      expect(h.play(HaptikkId.h03), HaptikkUtfall.dropped);
      now = 40;
      expect(h.play(HaptikkId.h13), HaptikkUtfall.played);
      expect(k.calls, ['prepare:1.0', 'play:h06', 'stop', 'play:h13']);
      now = 2000;
      expect(k.played.contains('h03'), isFalse, reason: 'never queued');
    });

    test('TH2: a lane change and a collision on one tick give H13 only', () async {
      await make();
      expect(h.playTick([HaptikkId.h01, HaptikkId.h13]), HaptikkUtfall.played);
      expect(k.played, ['h13']);
    });

    test('a crate that fills the meter gives H04', () async {
      await make();
      h.playTick([HaptikkId.h02, HaptikkId.h04], step: 1);
      expect(k.played, ['h04']);
    });

    test('80 ms after a level ≥ 3 pattern, levels 1–2 are dropped; level 3 is not', () async {
      await make();
      h.play(HaptikkId.h03); // 100 ms
      now = 100 + 79;
      expect(h.play(HaptikkId.h02, step: 1), HaptikkUtfall.dropped);
      expect(h.play(HaptikkId.h01), HaptikkUtfall.dropped);
      now = 100 + 80;
      expect(h.play(HaptikkId.h02, step: 2), HaptikkUtfall.played);
      now = 1000;
      h.play(HaptikkId.h03);
      now = 1110;
      expect(h.play(HaptikkId.h11), HaptikkUtfall.played, reason: 'the rest only drops levels 1–2');
    });

    test('TH3: a near miss mid-row plays H03, the pops within 80 ms go, the row continues', () async {
      await make();
      expect(h.crate(100), 1);
      h.play(HaptikkId.h02, step: 1);
      now = 300;
      expect(h.crate(140), 2);
      h.play(HaptikkId.h02, step: 2);
      now = 600;
      h.play(HaptikkId.h03); // the near miss neither advances nor breaks the row
      now = 650;
      final n = h.crate(170);
      expect(n, 3);
      expect(h.play(HaptikkId.h02, step: n), HaptikkUtfall.dropped, reason: 'H03 still playing');
      now = 700 + 79;
      expect(h.play(HaptikkId.h02, step: h.crate(200)), HaptikkUtfall.dropped, reason: 'the 80 ms rest');
      now = 900;
      expect(h.crate(230), 5);
      expect(h.play(HaptikkId.h02, step: 5), HaptikkUtfall.played);
      expect(k.played, ['h02.1', 'h02.2', 'h03', 'h02.5']);
    });

    test('the crate row is counted in ticks: 90 ticks apart breaks it (DH6)', () async {
      await make();
      expect(h.crate(0), 1);
      expect(h.crate(89), 2);
      expect(h.crate(179), 1);
      h.newRun();
      expect(h.crate(200), 1);
    });

    test('after H13 nothing plays until a touch — except U07', () async {
      await make();
      h.play(HaptikkId.h13);
      now = 2000;
      expect(h.play(HaptikkId.u01), HaptikkUtfall.silent);
      expect(h.play(HaptikkId.u07), HaptikkUtfall.played);
      now = 3000;
      h.touch();
      expect(h.play(HaptikkId.u01), HaptikkUtfall.played);
    });

    test('TH9: hold stops a playing H13 and nothing new plays until released', () async {
      await make();
      h.play(HaptikkId.h13);
      now = 100;
      h.hold(true);
      expect(k.calls.last, 'stop');
      h.touch();
      expect(h.play(HaptikkId.u01), HaptikkUtfall.silent);
      h.hold(false);
      expect(h.play(HaptikkId.u01), HaptikkUtfall.played);
    });

    test('TH6: Av plays nothing; Dempet drops its off-list and plays the rest at 0.7 on Rich', () async {
      await make();
      h.setLevel(HaptikkNivaaValg.off);
      for (final id in HaptikkId.values) {
        expect(h.play(id), HaptikkUtfall.silent);
      }
      expect(k.played, isEmpty);
      h.setLevel(HaptikkNivaaValg.soft);
      await Future<void>.delayed(Duration.zero);
      expect(k.scales.last, .7);
      for (final id in kDempetAv) {
        expect(h.play(id, step: 1), HaptikkUtfall.silent, reason: id.name);
      }
      expect(h.play(HaptikkId.h05), HaptikkUtfall.played);
      expect(k.played, ['h05']);
    });

    test('the policies: scale multiplies every Rich strength; enabled false silences', () async {
      await make();
      h.setPolicy(enabled: true, scale: .8);
      await Future<void>.delayed(Duration.zero);
      expect(k.scales.last, .8);
      h.setLevel(HaptikkNivaaValg.soft);
      await Future<void>.delayed(Duration.zero);
      expect(k.scales.last, closeTo(.56, 1e-9));
      h.setPolicy(enabled: false, scale: .8);
      expect(h.play(HaptikkId.h13), HaptikkUtfall.silent);
      expect(h.virkelig, HaptikkNivaaValg.off);
    });

    test('the app-wide «Vibrasjon» off wins (DH2)', () async {
      await make();
      h.setAppSwitch(false);
      expect(h.virkelig, HaptikkNivaaValg.off);
      expect(h.play(HaptikkId.h05), HaptikkUtfall.silent);
      h.setAppSwitch(true);
      expect(h.play(HaptikkId.h05), HaptikkUtfall.played);
    });

    test('tier Off sends nothing, not even the table', () async {
      await make(tier: HaptikkTier.off);
      expect(h.play(HaptikkId.h13), HaptikkUtfall.silent);
      expect(k.calls, isEmpty);
      await h.dispose();
      expect(k.calls, isEmpty);
    });

    test('Standard: the frequent ones are left out on Android; Dempet keeps the off-list only', () async {
      await make(tier: HaptikkTier.standard);
      expect(h.play(HaptikkId.h01), HaptikkUtfall.silent);
      expect(h.play(HaptikkId.h02, step: 1), HaptikkUtfall.silent);
      expect(h.play(HaptikkId.h09, metresLeft: 10), HaptikkUtfall.silent);
      expect(h.play(HaptikkId.h05), HaptikkUtfall.played);
      expect(k.played, ['h05']);
    });

    test('Standard on the iPhone is Flutter\'s HapticFeedback; H10 is heavy twice, 120 ms apart', () async {
      await make(tier: HaptikkTier.standard, isIos: true);
      expect(k.calls, isEmpty, reason: 'no table for the iPhone\'s Standard');
      h.play(HaptikkId.h01);
      expect(ios, ['selection']);
      now = 500;
      h.play(HaptikkId.h10);
      expect(ios, ['selection', 'heavy']);
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(ios, ['selection', 'heavy', 'heavy']);
    });

    test('the lab\'s switch plays a pattern past the rules', () async {
      await make();
      h.play(HaptikkId.h13);
      h.utenRegler = true;
      expect(h.play(HaptikkId.h01), HaptikkUtfall.played);
    });
  });

  group('TH4: the pulse before «Din beste» (§4.3)', () {
    test('beats from 60 m, quickening from 800 to 350 ms', () async {
      await make();
      expect(GameHaptics.slagMs(60), 800);
      expect(GameHaptics.slagMs(0), 350);
      expect(GameHaptics.slagMs(30), 575);
      expect(h.pulse(80), isFalse);
      expect(h.pulse(60), isTrue);
      now = 799;
      expect(h.pulse(52), isFalse);
      now = 800;
      expect(h.pulse(50), isTrue);
      expect(k.played, ['h09.0', 'h09.0']);
      now = 800 + GameHaptics.slagMs(50);
      expect(h.pulse(5), isTrue);
      expect(k.played.last, 'h09.5');
    });

    test('at 24 m/s the beats come closer than at 9 m/s', () async {
      Future<int> beats(double speed) async {
        now = 0;
        final g = GameHaptics(kanal: FakeKanal(), klokke: () => now, ios: false);
        await g.prepare();
        var n = 0;
        for (var ms = 0; ms < 20000; ms += 16) {
          now = ms;
          final left = 70 - speed * ms / 1000;
          if (left <= -1) break;
          if (g.pulse(left > 0 ? left : 0)) n++;
        }
        return n;
      }

      final slow = await beats(9), fast = await beats(24);
      expect(slow, greaterThan(fast), reason: 'more time in the approach at 9 m/s');
      expect(fast, greaterThanOrEqualTo(3));
    });

    test('stops on H10 and does not resume in the same approach; passing ends it', () async {
      await make();
      h.pulse(40);
      now = 100;
      h.play(HaptikkId.h10);
      now = 5000;
      expect(h.pulse(20), isFalse);
      expect(h.pulsStoppet, isTrue);
      h.newRun();
      expect(h.pulse(20), isTrue);
      now = 9000;
      expect(h.pulse(0), isFalse);
      now = 9999;
      expect(h.pulse(10), isFalse);
    });

    test('none without a best (the week\'s first run) or after the best was passed', () async {
      await make();
      expect(h.pulse(null), isFalse);
      expect(k.played, isEmpty);
    });

    test('a pause inside the approach stops it for the approach; a pause before it does not', () async {
      await make();
      h.hold(true);
      h.hold(false);
      expect(h.pulse(50), isTrue);
      now = 2000;
      h.hold(true);
      h.hold(false);
      now = 4000;
      expect(h.pulse(30), isFalse);
    });

    test('a collision ends it', () async {
      await make();
      h.pulse(40);
      now = 100;
      h.play(HaptikkId.h13);
      h.touch();
      now = 3000;
      expect(h.pulse(30), isFalse);
    });
  });

  group('the engine bit evLane (DH1)', () {
    const params = {
      'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
      'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
      'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'landmark_near_mm': 150000,
      'kajakk_ahead_mm': 60000,
    };
    Map<String, dynamic> course() => {
          'params': params,
          'rows': [
            {'d': 900000, 't': 'boye', 'l': [0, 1, 2]},
          ],
          'crates': const [],
          'landmarks': const [],
        };

    test('set on the tick a change starts (an input, and a held one); not at the edge', () {
      final sim = FjordSim(course(), 'none');
      final lanes = <int>[];
      final input = {10: [1], 12: [-1], 40: [1], 60: [1]};
      for (var t = 0; t < 80; t++) {
        sim.stepTick(input[t] ?? const []);
        if (sim.events & FjordSim.evLane != 0) lanes.add(t);
      }
      // 10: right; 12: held (the change runs 7 ticks) and carried out at 17; 40: right; 60: right at the edge — none.
      expect(lanes, [10, 17, 40]);
    });

    test('the loop reports events per tick', () {
      final sim = FjordSim(course(), 'none');
      final loop = FjordLoop(sim);
      final seen = <int, int>{};
      loop.onTickEvents = (t, e) => seen[t] = e;
      loop.step();
      loop.input(1);
      loop.step();
      expect(seen, {1: FjordSim.evLane});
      loop.dispose();
    });

    test('TH10: the golden runs are unchanged with the bit (results never carried events)', () {
      final g = (jsonDecode(File('test/game/fixtures/golden_runs.json').readAsStringSync()) as Map).cast<String, dynamic>();
      final courses = (g['courses'] as Map).cast<String, dynamic>();
      for (final run in (g['runs'] as List).cast<Map>().take(40)) {
        final inputs = [for (final i in (run['inputs'] as List)) FjordInput((i as List)[0] as int, i[1] as int)];
        final got = FjordEngine.run((courses[run['course']] as Map).cast<String, dynamic>(), run['perk'] as String, inputs);
        expect(got.toJson(), run['expect'], reason: 'golden run ${run['id']}');
      }
    });
  });
}
