import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/game_haptics.dart';
import 'package:aerend_customer/game/fjordlopet/haptics/haptikk_moenster.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_laast_rad.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_kreditert.dart';

import '../a3/a3_fakes.dart';
import 'haptics_rules_test.dart' show FakeKanal;

/// Fjordløpet haptics plan Step 5 (haptics spec §4.2): the patterns around the run — U01–U05, U07–U09, U11, and
/// «Poeng kreditert» with U06 per row and U11 on a new level (DH5).

Map<String, dynamic> _course() => {
      'id': 9,
      'week': '2026-W47',
      'engine_version': 2,
      'params': {
        'speed_start_mms': 9000, 'speed_step_mms': 120, 'speed_max_mms': 24000, 'lane_change_ticks': 7,
        'milestones_m': [200, 500, 1000], 'length_m': 5000, 'wake_from_m': 700, 'wake_counter_ticks': 30,
        'vest_grace_ticks': 60, 'vest_crates': 8, 'near_miss_ticks': 18, 'kajakk_ahead_mm': 60000,
      },
      'rows': [
        {'d': 60000, 't': 'open', 'l': []},
        {'d': 300000, 't': 'stokk', 'l': [0, 1]},
        {'d': 301000, 't': 'boye', 'l': [2]},
      ],
      'squalls': [],
    };

Map<String, dynamic> _state({bool noNew = false, bool bonus = false, String losgrad = 'Lettmatros'}) => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': noNew ? 'no_new_run' : 'open', 'runs_allowed': 3, 'runs_left': 3, 'bonus_granted': bonus, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(),
      'personal_best_m': null,
      'week_best_m': null,
      'losgrad': {'name': losgrad, 'lifetime_m': 0},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': 'seen', 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': noNew},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
    };

class _Api extends LopetApi {
  _Api(this.json);
  Map<String, dynamic> json;

  @override
  Future<LopetState?> state(int orderId) async => LopetState.fromJson(json);

  @override
  Future<void> sound(bool on) async {}
}

void main() {
  late FakeKanal k;
  late GameHaptics h;

  Future<void> open(WidgetTester t, _Api api) async {
    a3Bootstrap();
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    k = FakeKanal();
    h = GameHaptics(kanal: k, klokke: () => t.binding.clock.now().millisecondsSinceEpoch, ios: false);
    GameHaptics.felles = h;
    addTearDown(() => GameHaptics.felles = null);
    await t.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: api, haptics: h, pollEvery: const Duration(seconds: 6))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('U01 «Sett seil», U03 a pause, U02 each of 3 · 2 · 1, U05 at the door stops what plays', (t) async {
    final api = _Api(_state());
    await open(t, api);
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    await t.pump();
    expect(k.played.first, 'u01');
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.byKey(const Key('lopet-pause-knapp')));
    await t.pump();
    expect(k.played.last, 'u03');
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const Key('lopet-fortsett')));
    await t.pump();
    for (var i = 0; i < 2; i++) {
      await t.pump(const Duration(milliseconds: 800));
    }
    expect(k.played.where((p) => p == 'u02'), hasLength(3));
    await t.pump(const Duration(milliseconds: 800));
    await t.pump();
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    h.play(HaptikkId.h06); // a gate pattern under way…
    LopetSignaler.send(LopetSignal.vedDora);
    await t.pump();
    expect(k.calls.sublist(k.calls.length - 2), ['stop', 'play:u05'], reason: 'TH5: it stops the pattern first');
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('U04: a courier message pauses with the knock; «to minutter unna» knocks when it turns true (DH9)', (t) async {
    final api = _Api(_state());
    await open(t, api);
    expect(k.played, isEmpty, reason: 'nothing on opening');
    api.json = _state(noNew: true);
    await t.pump(const Duration(seconds: 6));
    await t.pump();
    expect(k.played, ['u04'], reason: 'at the quay: at once');
    expect(find.byKey(const Key('lopet-snart')), findsOneWidget);
    // U09 on a tap on «Budet er snart fremme».
    await t.tap(find.text(LopetCopy.snartFremme));
    await t.pump();
    expect(k.played.last, 'u09');
  });

  testWidgets('U04 for «Du har en melding fra budet» during a run', (t) async {
    await open(t, _Api(_state()));
    await t.tap(find.byKey(const Key('lopet-sett-seil')));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    LopetSignaler.send(LopetSignal.trengerDeg);
    await t.pump();
    expect(k.played.last, 'u04');
    expect(h.holdt, isTrue);
  });

  testWidgets('U08 the first time the bonus chip shows; U11 when the losgrad changes', (t) async {
    final api = _Api(_state(bonus: true));
    await open(t, api);
    await t.pump();
    expect(k.played, ['u08']);
    await t.pump(const Duration(seconds: 6));
    await t.pump();
    expect(k.played, ['u08'], reason: 'once');
    api.json = _state(bonus: true, losgrad: 'Matros');
    await t.pump(const Duration(seconds: 6));
    await t.pump();
    expect(k.played.last, 'u11');
  });

  testWidgets('U09 on a tap on the locked row', (t) async {
    k = FakeKanal();
    h = GameHaptics(kanal: k, klokke: () => 0, ios: false);
    await h.prepare();
    GameHaptics.felles = h;
    addTearDown(() => GameHaptics.felles = null);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: LopetLaastRad(summary: {'best_m': 300, 'place': 4, 'losgrad': 'Matros', 'weeks_sailed': 2}))));
    await t.tap(find.byKey(const Key('lopet-laast-rad')));
    expect(k.played, ['u09']);
  });

  group('«Poeng kreditert» (DH5)', () {
    const stige = [TierStep(index: 0, name: 'Bronse', threshold: 0), TierStep(index: 1, name: 'Sølv', threshold: 1000), TierStep(index: 2, name: 'Gull', threshold: 3000), TierStep(index: 3, name: 'Platina', threshold: 6000)];
    PointsBalance b(int earned) => PointsBalance(available: 1249, earned12m: earned, tier: 2, tierName: 'Gull', nextTierName: 'Platina', pointsToNextTier: 6000 - earned, tiers: stige);
    const rader = [KrRad(tittel: 'Bøye 2 nådd', under: '', poeng: 6), KrRad(tittel: 'Ny rekord', under: '', poeng: 3, rekord: true)];

    Future<void> run(WidgetTester t, PointsBalance bal) async {
      a3Bootstrap();
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      k = FakeKanal();
      h = GameHaptics(kanal: k, klokke: () => t.binding.clock.now().millisecondsSinceEpoch, ios: false);
      await h.prepare();
      GameHaptics.felles = h;
      addTearDown(() => GameHaptics.felles = null);
      await t.pumpWidget(MaterialApp(
        builder: (c, app) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(.5)), child: app!),
        home: PoengKreditert(data: KrData.fra(rader, bal)),
      ));
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('a light coin per row, no per-coin ticks, no heavy end pulse', (t) async {
      await run(t, b(3609));
      expect(k.played, ['u06', 'u06']);
    });

    testWidgets('the fanfare on a new level', (t) async {
      await run(t, b(3004));
      expect(k.played, ['u06', 'u06', 'u11']);
    });
  });
}
