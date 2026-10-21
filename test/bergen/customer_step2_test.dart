import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/sporing/bud_chat_ark.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_panel.dart';
import 'package:aerend_customer/screens/bergen/sporing/takk_ark.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../layout/reduced_motion_harness.dart';

/// Customer Step 2: the dark order sheet's labels, the bud chat (both
/// directions, `contact kind=message`), the thank-you note and its pill.
class _FakeCus extends CusApi {
  _FakeCus(this.server);

  List<CusMelding> server;
  final List<String> takket = [];

  @override
  Future<List<CusMelding>> meldinger(int orderId) async => server;

  @override
  Future<bool> takk(int orderId, String tekst) async {
    takket.add(tekst);
    return true;
  }
}

class _FakeOps extends OpsCustomerApi {
  final List<Map<String, String?>> contacts = [];
  Map<String, dynamic>? svar = {'status': 1};

  @override
  Future<Map<String, dynamic>?> contact(int orderId, {required String kind, String? message}) async {
    contacts.add({'kind': kind, 'message': message});
    return svar;
  }
}

Map<String, dynamic> _payload({required String state, required int stage, String label = 'På vei'}) => {
  'order_id': '4471',
  'code': 'Æ-42K',
  'mode': 'delivery',
  'state': state,
  'stage': stage,
  'stage_label': label,
  'delivery_actor': 'aerend_courier',
  'courier': {'id': 19, 'first_name': 'Jonas', 'verified': true, 'vehicle': 'sykkel'},
  'store': {'id': 45, 'name': 'Sandviken Bakeri', 'address': 'Bryggen 7'},
  'delivery_address': 'Nygårdsgaten 5',
};

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _opner(void Function(BuildContext ctx) apne) => MaterialApp(
  home: Builder(
    builder: (ctx) => Scaffold(
      body: Center(child: TextButton(onPressed: () => apne(ctx), child: const Text('åpne'))),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  testWidgets('the dark order sheet: sentence-case copy shown uppercase, the Vipps logo, «Ring butikken»', (tester) async {
    _frame(tester);
    final t = OpsTracking.fromJson(_payload(state: 'picked_up', stage: 2));
    final ordre = SpOrdre(
      linjer: const [SpLinje(navn: 'Kanelbolle', antall: 2, sum: 78)],
      total: 78,
      adresse: 'Nygårdsgaten 5, 5015 Bergen',
      bestilt: DateTime(2026, 10, 21, 18, 4),
      butikk: 'Sandviken Bakeri',
      butikkAdresse: 'Bryggen 7',
      ordreNr: 'ÆR-1234',
      kode: 'Æ-42K',
    );
    var ring = 0, detaljer = 0;
    Widget ark(SpArk a) => MaterialApp(
      home: Scaffold(
        body: SpDetaljerArk(
          ark: a,
          tracking: t,
          ordre: ordre,
          height: 844,
          onLukk: () {},
          onDetaljer: () => detaljer++,
          onKvittering: () {},
          onKundeservice: () {},
          onRingButikk: () => ring++,
        ),
      ),
    );

    expect(SporingCopy.a1_sporing_leveres_til, 'Leveres til', reason: 'the copy is sentence case; the UI uppercases');
    expect(SporingCopy.a1_sporing_ordrestatus, 'Ordrestatus');

    await tester.pumpWidget(ark(SpArk.sammendrag));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('cus-sporing-ark-mork')), findsOneWidget);
    for (final l in ['LEVERES TIL', 'BESTILLING', 'BETALT MED VIPPS']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.image(const AssetImage('assets/images/vipps_logo_hvit.png')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sporing-ark-bestilling')));
    expect(detaljer, 1);

    await tester.pumpWidget(ark(SpArk.detaljer));
    await tester.pump(const Duration(seconds: 1));
    for (final l in ['ORDRESTATUS', 'DIN BESTILLING', 'BETALING', 'BUTIKKEN', 'ORDRENUMMER', 'ÆREND-ID', 'TIDSSTEMPEL', 'KVITTERING']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    await tester.ensureVisible(find.byKey(const Key('cus-sporing-ring-butikken')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cus-sporing-ring-butikken')));
    expect(ring, 1);
  });

  testWidgets('the bud chat: the courier left, the customer right; a chip sends kind=message; «Ring {navn}»', (tester) async {
    _frame(tester);
    final cus = _FakeCus([CusMelding(fraMeg: false, tekst: 'Hei! Jeg har hentet bestillingen din.', at: DateTime(2026, 10, 21, 18, 6))]);
    final ops = _FakeOps();
    final t = OpsTracking.fromJson(_payload(state: 'picked_up', stage: 2));
    var ringt = 0;
    await tester.pumpWidget(_opner((ctx) => visBudChat(ctx, orderId: 4471, tracking: t, api: ops, cus: cus, onRing: () => ringt++)));
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('cus-budchat')), findsOneWidget);
    expect(find.text(CusBudchatCopy.cus_budchat_ditt_bud('Jonas')), findsOneWidget);
    expect(find.text(CusBudchatCopy.cus_budchat_privat), findsOneWidget);
    expect(find.text(CusBudchatCopy.cus_budchat_paa_vei), findsOneWidget, reason: 'picked up: the courier has the order');
    expect(find.text(CusBudchatCopy.cus_budchat_skriv_til('Jonas')), findsOneWidget);
    expect(find.byKey(const Key('cus-budchat-fra-bud')), findsOneWidget);
    expect(find.byKey(const Key('cus-budchat-fra-meg')), findsNothing);
    expect(tester.widget<Row>(find.byKey(const Key('cus-budchat-fra-bud'))).mainAxisAlignment, MainAxisAlignment.start);

    final chip = CusBudchatCopy.cus_budchat_chips.first;
    cus.server = [...cus.server, CusMelding(fraMeg: true, tekst: chip, at: DateTime(2026, 10, 21, 18, 7))];
    await tester.tap(find.byKey(const Key('cus-budchat-chip-0')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(ops.contacts.single, {'kind': 'message', 'message': chip});
    expect(find.byKey(const Key('cus-budchat-fra-meg')), findsOneWidget, reason: 'the sent line, once — not doubled by the server copy');
    expect(tester.widget<Row>(find.byKey(const Key('cus-budchat-fra-meg'))).mainAxisAlignment, MainAxisAlignment.end);

    // The courier's reply arrives with the next poll.
    cus.server = [...cus.server, CusMelding(fraMeg: false, tekst: 'Supert, to minutter unna', at: DateTime(2026, 10, 21, 18, 8))];
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Supert, to minutter unna'), findsOneWidget);
    expect(find.byKey(const Key('cus-budchat-fra-bud')), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('cus-budchat-ring')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(ringt, 1);
    expect(find.byKey(const Key('cus-budchat')), findsNothing);
  });

  test('a line that does not go is taken back and left in the field', () async {
    final ops = _FakeOps()..svar = null;
    final traad = BudChatTraad(orderId: 4471, api: ops, cus: _FakeCus(const []));
    traad.tekst.text = 'Ring på';
    expect(await traad.send('Ring på'), isFalse);
    expect(traad.meldinger, isEmpty);
    expect(traad.tekst.text, 'Ring på');
    traad.dispose();
  });

  testWidgets('Takk til budet: a suggestion fills the note, «Send takk» stores it, the pill then reads sent', (tester) async {
    _frame(tester);
    final cus = _FakeCus(const []);
    bool? res;
    await tester.pumpWidget(_opner((ctx) async => res = await visTakkArk(ctx, orderId: 4471, navn: 'Jonas', cus: cus)));
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('cus-takk-ark')), findsOneWidget);
    expect(find.text(CusTakkCopy.cus_takk_til('Jonas')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cus-takk-send')));
    await tester.pump();
    expect(cus.takket, isEmpty, reason: 'nothing to send yet');

    final forslag = CusTakkCopy.cus_takk_forslag.first;
    await tester.tap(find.byKey(const Key('cus-takk-forslag-0')));
    await tester.pump();
    expect(find.text('${forslag.length}/$kTakkMaks'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-takk-send')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(cus.takket.single, forslag);
    expect(res, isTrue);
    expect(prefGetString(takkPref(4471)), '1');
    await tester.pump(const Duration(seconds: 5));

    // The pill on the delivered panel.
    var trykk = 0;
    final levert = OpsTracking.fromJson(_payload(state: 'delivered', stage: 3, label: 'Levert'));
    Widget panel(bool sendt) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SpPanel(
            tracking: levert,
            linje: '',
            offline: false,
            slotKode: false,
            slotVerv: false,
            onSammendrag: () {},
            onDetaljer: () {},
            onAvslutt: () {},
            onFjordfiske: () {},
            onVisVeien: () {},
            onChat: () {},
            onRing: () {},
            onLukkVerv: () {},
            onDelBillett: () {},
            onKopierBillett: () {},
            takkNavn: 'Jonas',
            takkSendt: sendt,
            onTakk: () => trykk++,
          ),
        ),
      ),
    );
    await tester.pumpWidget(panel(false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(CusTakkCopy.cus_takk_til('Jonas')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sporing-takk')));
    expect(trykk, 1);
    await tester.pumpWidget(panel(true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(CusTakkCopy.cus_takk_sendt_kort('Jonas')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sporing-takk')));
    expect(trykk, 1, reason: 'sent once; the pill no longer opens the sheet');
  });
}
