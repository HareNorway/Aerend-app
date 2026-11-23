import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/api_base_helper.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_copy.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_data.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_laast_rad.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_liste.dart';
import 'package:aerend_customer/screens/bergen/lopet/lopet_screen.dart';
import 'package:aerend_customer/services/lopet_utboks.dart';

import '../a3/a3_fakes.dart';

/// Fjordløpet v1.3 plan Step 7 (spec §3, §7, §8, §12; T6, T7, T12, T16): pauses from the tracking cards, the door
/// handing over to Sporing, the server's answer on the end card, the cached state offline, and the entry rows.

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

Map<String, dynamic> _stateJson({String deliveryState = 'seen', String? needsYou}) => {
      'status': 1,
      'session': {'id': 1, 'order_id': 42, 'state': 'open', 'runs_allowed': 3, 'runs_left': 3, 'bonus_granted': false, 'perk': 'none', 'tokens': ['rt_a', 'rt_b', 'rt_c']},
      'course': _course(),
      'personal_best_m': null,
      'week_best_m': null,
      'losgrad': {'name': 'Lettmatros', 'lifetime_m': 0},
      'level': {'index': 0, 'name': 'Bronse', 'boat': 'robaat'},
      'rewards': {'buoy1': 3, 'buoy2': 6, 'quay': 12, 'personal_best': 3, 'cap': 15, 'milestones_m': [200, 500, 1000]},
      'delivery': {'state': deliveryState, 'stage': 1, 'stage_label': 'Tilberedes', 'promised_end': null, 'courier_eta_minutes': null, 'no_new_run': false, 'needs_you': needsYou},
      'vilkaar': ['Linje 1'],
      'profile': {'sound_on': false},
    };

class _FakeApi extends LopetApi {
  _FakeApi(this.json);

  Map<String, dynamic>? json;

  @override
  Future<LopetState?> state(int orderId) async {
    final j = json;
    return j == null ? null : LopetState.fromJson(j);
  }

  @override
  Future<void> sound(bool on) async {}
}

/// One answer per GET for `/game/state`; 0 = no network.
class _StateHelper extends ApiBaseHelper {
  _StateHelper(this.svar) : super(baseUrl: 'http://test.local/');

  final List<(int, Object?)> svar;

  @override
  Future<ApiClientResult> getAllowClientError(String url) async {
    final (k, body) = svar.removeAt(0);
    if (k == 0) throw Exception('offline');
    return ApiClientResult(k, body);
  }
}

class _ListeApi extends LopetListeApi {
  _ListeApi(this.s);

  final Map<String, dynamic>? s;

  @override
  Future<Map<String, dynamic>?> summary() async => s;
}

void _stor(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

/// Sporing underneath, the game pushed on top (as from the Sporing tile).
Future<void> _fraSporing(WidgetTester t, Widget spill) async {
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: TextButton(key: const Key('sporing-stub'), onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => spill)), child: const Text('Sporing')),
      ),
    ),
  ));
  await t.tap(find.byKey(const Key('sporing-stub')));
  await t.pumpAndSettle();
  await _settle(t);
}

Future<void> _seil(WidgetTester t, {int pumps = 20}) async {
  await t.tap(find.byKey(const Key('lopet-sett-seil')));
  for (var i = 0; i < pumps; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  // Signed out: a finished run stays in the outbox and nothing goes to the network (the T12 test signs in).
  setUp(() async => a3Bootstrap());
  tearDown(() => OpsCustomerApi.networkEnabled = true);

  testWidgets('T6: the courier at the door ends the run, the end card shows the distance, then Sporing is on screen', (tester) async {
    _stor(tester);
    await _fraSporing(tester, LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), pollEvery: const Duration(hours: 1), tilSporingEtter: const Duration(milliseconds: 600)));
    await _seil(tester);
    LopetSignaler.send(LopetSignal.vedDora);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('lopet-slutt-dora')), findsOneWidget, reason: 'ended at once, the distance counts');
    expect(LopetLager.utboks().single['token'], 'rt_a');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lopet-slutt')), findsNothing);
    expect(find.byKey(const Key('sporing-stub')), findsOneWidget, reason: 'Sporing is on screen (T6)');
  });

  testWidgets('T6 by the poll: arrived_customer in /game/state ends the run as the push does', (tester) async {
    _stor(tester);
    final api = _FakeApi(_stateJson());
    await _fraSporing(tester, LopetScreen(orderId: 42, api: api, pollEvery: const Duration(seconds: 1), tilSporingEtter: const Duration(milliseconds: 300)));
    await _seil(tester, pumps: 5);
    api.json = _stateJson(deliveryState: 'arrived_customer');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('lopet-slutt-dora')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sporing-stub')), findsOneWidget);
  });

  testWidgets('T7: a card that needs the customer\'s answer pauses the run once per card', (tester) async {
    _stor(tester);
    final api = _FakeApi(_stateJson());
    await tester.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: api, pollEvery: const Duration(seconds: 1))));
    await _settle(tester);
    await _seil(tester, pumps: 5);
    api.json = _stateJson(needsYou: 'n:5');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsOneWidget);
    // T3 GAM-D03: a card for the customer (a delay or problem notice) — «Ærendet ditt trenger deg», not the courier's message.
    expect(find.text(LopetCopy.pauseTekst('kort').$1), findsOneWidget);

    // Resumed with 3 · 2 · 1 while the same card is still open: the next poll does not pause again.
    await tester.tap(find.byKey(const Key('lopet-fortsett')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsNothing, reason: 'the same card pauses once');

    api.json = _stateJson(needsYou: 'n:6');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('lopet-pause')), findsOneWidget, reason: 'a new card pauses again');
  });

  testWidgets('the server\'s answer to the run replaces the phone\'s points and nearest goal on the end card', (tester) async {
    _stor(tester);
    await tester.pumpWidget(MaterialApp(home: LopetScreen(orderId: 42, api: _FakeApi(_stateJson()), pollEvery: const Duration(hours: 1), tilSporingEtter: const Duration(hours: 1))));
    await _settle(tester);
    await _seil(tester);
    LopetSignaler.send(LopetSignal.vedDora);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(LopetUtboks.onSvar, isNotNull);
    LopetUtboks.onSvar!({'token': 'rt_a'}, {
      'status': 1,
      'state': 'verified',
      'points_pending': 6,
      'nearest_goal': {'type': 'rival', 'name': 'Seiler 30', 'gap_m': 12},
    });
    await tester.pump();
    expect(find.text(LopetCopy.maalSeiler('Seiler 30', 12)), findsOneWidget);
    expect(find.text(LopetCopy.poengVedLevering(6)), findsOneWidget);

    // Another run's answer does not touch this card's goal.
    LopetUtboks.onSvar!({'token': 'rt_x'}, {'status': 1, 'state': 'verified', 'nearest_goal': {'type': 'best', 'gap_m': 40}});
    await tester.pump();
    expect(find.text(LopetCopy.maalSeiler('Seiler 30', 12)), findsOneWidget);
  });

  test('pushes: every notification hushes the game first; the door ends, a message or CRITICAL pauses', () async {
    final got = <LopetSignal>[];
    final sub = LopetSignaler.stream.listen(got.add);
    LopetSignaler.fraPush({'type': 'customer.order.at_door'});
    LopetSignaler.fraPush({'type': 'customer.code.required'});
    LopetSignaler.fraPush({'type': 'customer.insight.weekly_summary'});
    await Future<void>.delayed(Duration.zero);
    expect(got, [LopetSignal.varsel, LopetSignal.vedDora, LopetSignal.varsel, LopetSignal.trengerDeg, LopetSignal.varsel]);
    await sub.cancel();
  });

  test('T12: /game/state is kept per order and answers offline; a closed window forgets it', () async {
    await a3Bootstrap(prefs: {'UserId': 815, 'AccessToken': 'tok'});
    final api = LopetApi(helper: _StateHelper([(200, _stateJson()), (0, null), (404, {'status': 0, 'message': 'GAME_CLOSED'}), (0, null)]));
    expect((await api.state(42))?.tokens, ['rt_a', 'rt_b', 'rt_c']);
    final offline = await api.state(42);
    expect(api.lastOffline, isTrue);
    expect(offline?.tokens, ['rt_a', 'rt_b', 'rt_c'], reason: 'runs start from the session\'s tokens without a network');
    expect(await api.state(42), isNull, reason: 'the window closed');
    expect(await api.state(42), isNull, reason: 'nothing kept once closed');

    // The network switched off in the app (no request at all): the kept state too.
    await LopetStateCache.lagre(42, _stateJson());
    OpsCustomerApi.networkEnabled = false;
    expect((await LopetApi().state(42))?.orderId, 42);
    expect(await LopetApi().state(43), isNull, reason: 'per order');
  });

  test('§8: the Sporing tile says runs left, your best and the week\'s best', () {
    expect(LopetCopy.flisUnder(2, 310, 512), '${LopetCopy.seilaserIgjen(2)} · ${LopetCopy.dinBeste.toLowerCase()} 310 m · ${LopetCopy.ukensBeste.toLowerCase()} 512 m');
    expect(LopetCopy.flisUnder(3, null, null), LopetCopy.seilaserIgjen(3), reason: 'before the first run of the week');
    expect(LopetCopy.maalFra({'type': 'rival', 'name': 'Seiler 30', 'gap_m': 12}), LopetCopy.maalSeiler('Seiler 30', 12));
    expect(LopetCopy.maalFra(null), isNull);
    expect(LopetCopy.maalFra({'type': 'nothing'}), isNull);
  });

  testWidgets('§8: the locked Premiehylla row shows results only and never opens the game', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: LopetLaastRad(summary: const {'best_m': 311, 'place': 31, 'losgrad': 'Lettmatros', 'weeks_sailed': 4, 'nearest_goal': {'type': 'rival', 'name': 'Seiler 30', 'gap_m': 12}}),
      ),
    ));
    expect(find.byKey(const Key('lopet-laast-rad')), findsOneWidget);
    expect(find.text(LopetCopy.nesteSeilas), findsOneWidget);
    expect(find.text(LopetCopy.maalSeiler('Seiler 30', 12)), findsOneWidget);
    expect(find.textContaining(LopetCopy.uker(4)), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('lopet-laast-rad')), matching: find.byType(InkWell)), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('lopet-laast-rad')), matching: find.byType(GestureDetector)), findsNothing);
  });

  testWidgets('T16: no summary (game off, the holdout) — no locked row at all', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LopetLaastRad(api: _ListeApi(null)))));
    await tester.pump();
    expect(find.byKey(const Key('lopet-laast-rad')), findsNothing);
  });
}
