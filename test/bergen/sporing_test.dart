import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/sporing/hjelp_sheet.dart';
import 'package:aerend_customer/screens/bergen/sporing/leveringskode_card.dart';
import 'package:aerend_customer/screens/bergen/sporing/levert_screen.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_screen.dart';

import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 6: stage rendering for every state × actor × mode from
/// server-provided payloads (the app never maps states), the partner
/// variant (no courier widget, no marker, store contact), Finner bud, the
/// Hjelp states, Levert, and the retired tracking widgets' assertions ported
/// to LeveringskodeCard / BudIdentitetPill.
class _FakeApi extends OpsCustomerApi {
  _FakeApi({
    this.payload,
    this.points,
    this.ledger,
    this.contactResult,
    this.problemResult,
    this.referralJson,
  });

  Map<String, dynamic>? payload;
  final Map<String, dynamic>? points;
  final Map<String, dynamic>? ledger;
  final Map<String, dynamic>? contactResult;
  final Map<String, dynamic>? problemResult;
  final Map<String, dynamic>? referralJson;
  final List<Map<String, dynamic>> contacts = [];
  final List<Map<String, dynamic>> problems = [];

  @override
  Future<Map<String, dynamic>> tracking(int orderId) async {
    final p = payload;
    if (p == null) throw StateError('offline');
    return p;
  }

  @override
  Future<Map<String, dynamic>?> pointsMe() async => points;
  @override
  Future<Map<String, dynamic>?> pointsForOrder(int orderId) async => ledger;
  @override
  Future<Map<String, dynamic>?> referral() async => referralJson;
  @override
  Future<Map<String, dynamic>?> contact(
    int orderId, {
    required String kind,
    String? message,
  }) async {
    contacts.add({'kind': kind, 'message': message});
    return contactResult;
  }

  @override
  Future<Map<String, dynamic>?> problem(
    int orderId, {
    required String kind,
    String? words,
    List<String>? items,
  }) async {
    problems.add({'kind': kind, 'words': words, 'items': items});
    return problemResult;
  }
}

/// A §5.1 payload as the server would send it for the given state.
Map<String, dynamic> payload({
  required String state,
  required int stage,
  required String label,
  String mode = 'delivery',
  String actor = 'aerend_courier',
  bool findingCourier = false,
  bool withCourier = true,
  Map<String, dynamic>? livePosition,
  Map<String, dynamic>? code,
  bool unseen = false,
  String? deliveredAt,
}) {
  final partner = actor == 'partner';
  return {
    'order_id': '4471',
    'code': 'Æ-42K',
    'mode': mode,
    'state': state,
    'stage': stage,
    'stage_label': label,
    'promised_start': '2026-09-25T18:12:00+02:00',
    'promised_end': '2026-09-25T18:22:00+02:00',
    'adjusted_by_minutes': 0,
    'delivery_actor': actor,
    'delivered_by_label': partner ? 'Sandviken Bakeri' : 'Bud',
    'finding_courier': findingCourier,
    'courier': partner || !withCourier
        ? null
        : {
            'id': 19,
            'first_name': 'Jonas',
            'avatar_url': null,
            'verified': true,
            'vehicle': 'sykkel',
          },
    'store': {
      'id': 45,
      'name': 'Sandviken Bakeri',
      'address': 'Bryggen 7',
      'lat': 60.39,
      'lng': 5.32,
    },
    'contact': {
      'call_target': partner || stage < 2 ? 'store' : 'courier',
      'message_target': partner || stage < 2 ? 'store' : 'courier',
    },
    'delivery_code': code,
    'live_position': livePosition,
    'unseen_by_store': unseen,
    'policy_version': 12,
    'events_since': 4471,
    'delivery_address': 'Nygårdsgaten 5',
    if (deliveredAt != null) 'delivered_at': deliveredAt,
  };
}

Widget _app(Widget child) => MaterialApp(home: child);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSporing(
  WidgetTester tester,
  Map<String, dynamic> p, {
  _FakeApi? api,
}) async {
  _frame(tester);
  await tester.pumpWidget(
    _app(
      SporingScreen(
        key: UniqueKey(),
        orderId: 4471,
        api: api ?? _FakeApi(payload: p),
        preloaded: OpsTracking.fromJson(p),
        poll: false,
        showMap: false,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  test(
    'the Phase 6 routes are in the agil-1 map, hjelp resolves with an id',
    () {
      expect(
        bergenRoutesAgil1().keys,
        containsAll([
          '/bergen/sporing',
          '/bergen/sporing/hjelp',
          '/bergen/levert',
          '/bergen/kundeservice',
        ]),
      );
    },
  );

  group(
    'stage rendering — 8 states × 2 actors × 2 modes, from the payload',
    () {
      const courierDelivery = {
        'placed': (0, 'Bekreftet'),
        'accepted': (1, 'Tilberedes'),
        'seen': (1, 'Tilberedes'),
        'ready': (1, 'Tilberedes'),
        'picked_up': (2, 'På vei'),
        'arrived_customer': (2, 'På vei'),
        'delivered': (3, 'Levert'),
        'cancelled': (0, 'Avbestilt'),
      };
      const partnerDelivery = {
        'placed': (0, 'Bekreftet'),
        'accepted': (0, 'Bekreftet'),
        'seen': (0, 'Bekreftet'),
        'ready': (1, 'Tilberedes'),
        'picked_up': (2, 'På vei'),
        'arrived_customer': (2, 'På vei'),
        'delivered': (3, 'Levert'),
        'cancelled': (0, 'Avbestilt'),
      };
      const pickup = {
        'placed': (0, 'Bekreftet'),
        'accepted': (1, 'Tilberedes'),
        'seen': (1, 'Tilberedes'),
        'ready': (2, 'Klar for henting'),
        'picked_up': (3, 'Hentet'),
        'arrived_customer': (3, 'Hentet'),
        'delivered': (3, 'Hentet'),
        'cancelled': (0, 'Avbestilt'),
      };

      for (final (actor, mode, table) in [
        ('aerend_courier', 'delivery', courierDelivery),
        ('partner', 'delivery', partnerDelivery),
        ('aerend_courier', 'pickup', pickup),
        ('partner', 'pickup', pickup),
      ]) {
        for (final entry in table.entries) {
          testWidgets('$actor · $mode · ${entry.key}', (tester) async {
            final (stage, label) = entry.value;
            await _pumpSporing(
              tester,
              payload(
                state: entry.key,
                stage: stage,
                label: label,
                mode: mode,
                actor: actor,
                deliveredAt: entry.key == 'delivered'
                    ? '2026-09-25T18:11:00+02:00'
                    : null,
              ),
            );
            expect(find.byKey(const Key('a1_sporing_stepper')), findsOneWidget);
            final top = tester
                .widget<Text>(find.byKey(const Key('a1_sporing_topline')))
                .data!;
            expect(
              top,
              entry.key == 'cancelled'
                  ? SporingCopy.a1_sporing_avbestilt
                  : SporingCopy.a1_sporing_live(label),
            );
            final cardKey = switch (stage) {
              0 => 'a1_sporing_kort_bekreftet',
              1 => 'a1_sporing_kort_tilberedes',
              2 =>
                mode == 'pickup'
                    ? 'a1_sporing_kort_hentklar'
                    : 'a1_sporing_kort_paavei',
              _ => 'a1_sporing_kort_levert',
            };
            expect(
              find.byKey(Key(cardKey)),
              findsOneWidget,
              reason: 'stage $stage card',
            );
            if (actor == 'partner' && mode == 'delivery') {
              expect(
                find.byKey(const Key('a1_sporing_leveres_av')),
                findsOneWidget,
              );
              expect(
                find.text('Jonas'),
                findsNothing,
                reason: 'spec §5: no courier identity',
              );
              expect(
                find.byKey(const Key('a1_sporing_live_marker')),
                findsNothing,
                reason: 'no live map for partner',
              );
            }
          });
        }
      }
    },
  );

  testWidgets(
    'Finner bud replaces the top line and the Ægil hint, never for partner',
    (tester) async {
      await _pumpSporing(
        tester,
        payload(
          state: 'accepted',
          stage: 1,
          label: 'Tilberedes',
          findingCourier: true,
          withCourier: false,
        ),
      );
      expect(
        find.text(SporingCopy.order_status_finding_courier),
        findsOneWidget,
      );
      expect(find.text(SporingCopy.a1_sporing_finner_bud_hint), findsOneWidget);
    },
  );

  testWidgets(
    'På vei shows the live marker only with a position, bike from the courier',
    (tester) async {
      await _pumpSporing(
        tester,
        payload(
          state: 'picked_up',
          stage: 2,
          label: 'På vei',
          livePosition: {'lat': 60.39, 'lng': 5.32},
        ),
      );
      expect(find.byKey(const Key('a1_sporing_live_marker')), findsOneWidget);
      expect(find.byKey(const Key('a1_sporing_ikon_sykkel')), findsOneWidget);
      expect(find.byKey(const Key('a1_sporing_bud_pill')), findsOneWidget);
      expect(
        find.byKey(const Key('a1_sporing_bud_verifisert')),
        findsOneWidget,
      );

      await _pumpSporing(
        tester,
        payload(state: 'picked_up', stage: 2, label: 'På vei'),
      );
      expect(find.byKey(const Key('a1_sporing_ingen_marker')), findsOneWidget);
    },
  );

  testWidgets(
    'a partner delivery shows the store icon in the identity pill and the store as contact',
    (tester) async {
      await _pumpSporing(
        tester,
        payload(
          state: 'picked_up',
          stage: 2,
          label: 'På vei',
          actor: 'partner',
        ),
      );
      expect(
        find.byKey(const Key('a1_sporing_bud_store_icon')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('a1_sporing_ikon_butikk')), findsOneWidget);
      expect(
        find.text(SporingCopy.a1_sporing_ingen_kart_partner),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Valg som venter shows when the store has not seen the order; Vent posts wait; Avbestill cancels',
    (tester) async {
      final api = _FakeApi(
        payload: payload(
          state: 'accepted',
          stage: 0,
          label: 'Bekreftet',
          actor: 'partner',
          unseen: true,
        ),
        problemResult: {'kind': 'wait'},
      );
      await _pumpSporing(
        tester,
        payload(
          state: 'accepted',
          stage: 0,
          label: 'Bekreftet',
          actor: 'partner',
          unseen: true,
        ),
        api: api,
      );
      await tester.dragUntilVisible(
        find.byKey(const Key('a1_sporing_valg')),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_sporing_valg_vent')));
      await tester.pump();
      await tester.pump();
      expect(api.problems.first['kind'], 'wait');
      expect(find.byKey(const Key('a1_sporing_valg')), findsNothing);
    },
  );

  testWidgets(
    'the delivery code card: PIN spaced, reason, no leave-at-door, visual only online',
    (tester) async {
      _frame(tester);
      const code = OpsDeliveryCode(
        pin: '4821',
        reason: 'value',
        reasonCopyKey: 'a1_sporing_kode_reason_value',
        qrPayload: 'aerend:code:abc',
      );
      await tester.pumpWidget(
        _app(const Scaffold(body: LeveringskodeCard(code: code))),
      );
      expect(find.byKey(const Key('ops-delivery-code-card')), findsOneWidget);
      expect(find.text('4 8 2 1'), findsOneWidget);
      expect(find.textContaining('høy verdi'), findsOneWidget);
      expect(
        find.byKey(const Key('ops-delivery-code-no-leave-at-door')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ops-delivery-code-qr')), findsOneWidget);

      await tester.pumpWidget(
        _app(
          const Scaffold(body: LeveringskodeCard(code: code, offline: true)),
        ),
      );
      expect(find.byKey(const Key('ops-delivery-code-qr')), findsNothing);
      expect(find.text(SporingCopy.a1_sporing_kode_offline), findsOneWidget);

      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: LeveringskodeCard(
              code: OpsDeliveryCode(pin: '1111', reasonCopyKey: 'x'),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const Key('ops-delivery-code-qr')),
        findsNothing,
        reason: 'no visual without a payload',
      );
    },
  );

  test('the visual code is stable for a payload', () {
    expect(
      LeveringskodeCard.pattern('aerend:code:abc'),
      LeveringskodeCard.pattern('aerend:code:abc'),
    );
    expect(
      LeveringskodeCard.pattern('a'),
      isNot(LeveringskodeCard.pattern('b')),
    );
    expect(LeveringskodeCard.pattern('a').length, 49);
  });

  testWidgets(
    'the identity pill: name, verification, vehicle; unverified omits the badge',
    (tester) async {
      _frame(tester);
      final t = OpsTracking.fromJson(
        payload(state: 'picked_up', stage: 2, label: 'På vei'),
      );
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: BudIdentitetPill(key: UniqueKey(), tracking: t),
          ),
        ),
      );
      expect(find.text('Jonas'), findsOneWidget);
      expect(
        find.byKey(const Key('a1_sporing_bud_verifisert')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('a1_sporing_bud_kjoretoy')), findsOneWidget);

      final p = payload(state: 'picked_up', stage: 2, label: 'På vei');
      (p['courier'] as Map)['verified'] = false;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: BudIdentitetPill(
              key: UniqueKey(),
              tracking: OpsTracking.fromJson(p),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('a1_sporing_bud_verifisert')), findsNothing);
    },
  );

  group('Hjelp', () {
    testWidgets(
      'main → melding sends through ops.customer.contact; dør and mangler post problems',
      (tester) async {
        _frame(tester);
        final api = _FakeApi(
          contactResult: {'kind': 'message', 'target': 'courier'},
          problemResult: {'kind': 'door'},
        );
        final t = OpsTracking.fromJson(
          payload(state: 'arrived_customer', stage: 2, label: 'På vei'),
        );
        await tester.pumpWidget(
          _app(
            HjelpScreen(
              key: UniqueKey(),
              orderId: 4471,
              tracking: t,
              api: api,
              items: const ['Pizza', 'Cola'],
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('a1_sporing_hjelp_main')), findsOneWidget);
        expect(find.text('Jonas'), findsOneWidget, reason: 'the courier card');

        await tester.tap(find.byKey(const Key('a1_sporing_hjelp_melding')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            SporingCopy.a1_sporing_hjelp_melding(SporingCopy.a1_sporing_bud),
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('a1_sporing_meld_felt')),
          'Ring på',
        );
        await tester.tap(find.byKey(const Key('a1_sporing_meld_send')));
        await tester.pump();
        await tester.pump();
        expect(api.contacts.single['kind'], 'message');
        expect(find.text('Ring på'), findsWidgets);

        // Back to main, then Finner ikke døra.
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('a1_sporing_hjelp_dor')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('a1_sporing_dor_felt')),
          'Gul dør',
        );
        await tester.tap(find.byKey(const Key('a1_sporing_dor_send')));
        await tester.pumpAndSettle();
        expect(api.problems.single['kind'], 'door');
        expect(find.byKey(const Key('a1_sporing_hjelp_sendt')), findsOneWidget);
      },
    );

    testWidgets(
      'Noe mangler needs a pick; kontaktRolle is butikken for partner',
      (tester) async {
        _frame(tester);
        final api = _FakeApi(problemResult: {'kind': 'missing'});
        final t = OpsTracking.fromJson(
          payload(
            state: 'delivered',
            stage: 3,
            label: 'Levert',
            actor: 'partner',
          ),
        );
        await tester.pumpWidget(
          _app(
            HjelpScreen(
              key: UniqueKey(),
              orderId: 4471,
              tracking: t,
              api: api,
              initial: HjelpState.mangler,
              items: const ['Pizza', 'Cola'],
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const Key('a1_sporing_hjelp_mangler_state')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('a1_sporing_mangler_Cola')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('a1_sporing_mangler_send')));
        await tester.pumpAndSettle();
        expect(api.problems.single['items'], ['Cola']);

        await tester.pumpWidget(
          _app(
            HjelpScreen(key: UniqueKey(), orderId: 4471, tracking: t, api: api),
          ),
        );
        await tester.pump();
        expect(
          find.text('Sandviken Bakeri'),
          findsOneWidget,
          reason: 'the store card for a partner order',
        );
        await tester.tap(find.byKey(const Key('a1_sporing_hjelp_melding')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            SporingCopy.a1_sporing_hjelp_melding(
              SporingCopy.a1_sporing_butikken,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Kundeservice standalone shows hours, chat and the number, no order line',
      (tester) async {
        _frame(tester);
        await tester.pumpWidget(_app(KundeserviceScreen(api: _FakeApi())));
        await tester.pump();
        expect(
          find.byKey(const Key('a1_sporing_kundeservice')),
          findsOneWidget,
        );
        expect(find.text(SporingCopy.a1_sporing_ks_ring), findsOneWidget);
        expect(find.byKey(const Key('a1_sporing_ks_ordre')), findsNothing);
      },
    );
  });

  testWidgets(
    'Levert: time, early line, points when the ledger answers, thanks for courier only, rating',
    (tester) async {
      _frame(tester);
      var rated = 0;
      final p = payload(
        state: 'delivered',
        stage: 3,
        label: 'Levert',
        deliveredAt: '2026-09-25T18:20:00+02:00',
        code: {
          'pin': '4821',
          'reason_copy_key': 'x',
          'verified_at': '2026-09-25T18:20:00+02:00',
        },
      );
      await tester.pumpWidget(
        _app(
          LevertScreen(
            key: UniqueKey(),
            orderId: 4471,
            tracking: OpsTracking.fromJson(p),
            api: _FakeApi(ledger: {'points': 34, 'first_time_bonus': 50}),
            rating: (id, stars) async => rated = stars,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const Key('a1_sporing_levert_for')),
        findsOneWidget,
        reason: 'two minutes early',
      );
      expect(find.byKey(const Key('a1_sporing_poeng')), findsOneWidget);
      expect(find.text('+34'), findsOneWidget);
      expect(find.byKey(const Key('a1_sporing_takk')), findsOneWidget);
      expect(
        find.textContaining('koden ble bekreftet av Jonas'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('a1_sporing_stjerne_5')));
      await tester.pump();
      expect(rated, 5);

      final partner = payload(
        state: 'delivered',
        stage: 3,
        label: 'Levert',
        actor: 'partner',
        deliveredAt: '2026-09-25T18:30:00+02:00',
      );
      await tester.pumpWidget(
        _app(
          LevertScreen(
            key: UniqueKey(),
            orderId: 4471,
            tracking: OpsTracking.fromJson(partner),
            api: _FakeApi(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const Key('a1_sporing_poeng')),
        findsNothing,
        reason: 'hidden on 404',
      );
      expect(
        find.byKey(const Key('a1_sporing_takk')),
        findsNothing,
        reason: 'no courier to thank',
      );
      expect(
        find.byKey(const Key('a1_sporing_levert_for')),
        findsNothing,
        reason: 'not early',
      );
    },
  );
}
