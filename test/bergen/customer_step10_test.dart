import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/tracking_models.dart';
import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/hjelp/noe_galt_sheet.dart';
import 'package:aerend_customer/screens/bergen/hjelp/support.dart';
import 'package:aerend_customer/screens/bergen/sporing/leveringskode_card.dart';
import 'package:aerend_customer/screens/bergen/sporing/sporing_copy.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 10 in the app: the C2 sheet (the chips, «Send» live
/// after a chip, «Tenker», the outcomes — «Løst» with the amount, «Ser på
/// det» with the case, «Beklager» with the courier's proof, «Denne saken er
/// allerede åpen» with «Legg til i saken»), the case row on the order with
/// «Ikke løst», the notice card with the new window, the «Utført av Ærend
/// AI» mapping and the models.

const _reviewing = {
  'id': 12, 'order_id': 404, 'order_code': 'Æ-2E6', 'case_ref': 'Æ-2E6-1', 'type': 'missing_item', 'type_label': 'Manglet noe', 'state': 'escalated', 'outcome': 'reviewing',
  'title': 'Vi ser på det og svarer innen 15 minutter.', 'sub': 'Sak Æ-2E6-1 · svaret kommer under Varsler', 'status_text': 'Vi ser på det · svar innen 15 min',
  'items': ['Rømme, 300 g'], 'amount': {'ore': 8900, 'display': '89 kr'}, 'sla_minutes': 15, 'answer_by': '18:52', 'can_reopen': false, 'reopen_count': 0, 'conversation_id': 7, 'created_at': '2026-10-22T18:37:00+02:00',
};
const _resolved = {
  'id': 13, 'order_id': 404, 'order_code': 'Æ-2E6', 'case_ref': 'Æ-2E6-1', 'type': 'missing_item', 'type_label': 'Manglet noe', 'state': 'resolved', 'outcome': 'resolved', 'resolution': 'auto_credit',
  'title': 'Vi har lagt 89 kr på saldoen din. Beklager.', 'sub': 'Rømme, 300 g · Torgboden · Æ-2E6', 'status_text': 'Løst · 89 kr på saldoen', 'items': ['Rømme, 300 g'], 'amount': {'ore': 8900, 'display': '89 kr'}, 'can_reopen': true,
};
const _notDelivered = {
  'id': 14, 'order_id': 404, 'order_code': 'Æ-2E6', 'case_ref': 'Æ-2E6-1', 'type': 'not_delivered', 'type_label': 'Ikke levert', 'state': 'escalated', 'outcome': 'not_delivered',
  'title': 'Vi ser på det nå.', 'sub': 'Dette er det Sindre registrerte ved levering. Svar innen 15 minutter.', 'status_text': 'Vi ser på det · svar innen 15 min',
  'proof': {'type': 'door_photo', 'photo_url': null, 'time': '18:19', 'label': 'Levert ved døren', 'pin_verified': false, 'courier': 'Sindre'},
};
const _denied = {
  'id': 15, 'order_id': 404, 'order_code': 'Æ-2E6', 'case_ref': 'Æ-2E6-2', 'type': 'damaged', 'type_label': 'Skadet', 'state': 'resolved', 'outcome': 'denied', 'resolution': 'denied',
  'title': 'Ingen refusjon denne gangen.', 'sub': 'Sindres bilde viser posen ved døren 18:19. — Mari, Ærend', 'status_text': 'Avgjort · ingen refusjon',
  'reply': {'text': 'Sindres bilde viser posen ved døren 18:19.', 'by': 'Mari', 'at': '2026-10-22T18:47:00+02:00'}, 'can_reopen': true, 'resolved_at': '2026-10-22T18:47:00+02:00',
};

class _Cus extends CusApi {
  _Cus({this.answer});
  final Map<String, dynamic>? answer;
  final List<String> calls = [];

  @override
  Future<({CusIssue? issue, String? feil})> issueOpen(int orderId, {String? type, String text = '', String? photoPath, bool append = false}) async {
    calls.add('open:$orderId:$type:$text:${photoPath ?? '-'}:$append');
    return (issue: answer == null ? null : CusIssue.fromJson(answer!), feil: answer == null ? 'INVALID' : null);
  }

  @override
  Future<CusIssue?> issueAppend(int id, String text) async {
    calls.add('append:$id:$text');
    return CusIssue.fromJson({..._reviewing, 'text': text});
  }
}

const _ordre = SupportOrdre(id: 404, kode: 'Æ-2E6', butikk: 'Torgboden', total: 285, status: 'Levert', linjer: ['Laksefilet 300 g', 'Torsketunger 250 g'], levert: true);
final _status = CusIssueStatus.fromJson(const {
  'delivered': true, 'can_report': true, 'sla_minutes': 15,
  'types': [{'key': 'missing_item', 'label': 'Manglet noe'}, {'key': 'wrong_item', 'label': 'Feil vare'}, {'key': 'damaged', 'label': 'Skadet'}, {'key': 'cold_late', 'label': 'Kaldt eller sent'}, {'key': 'not_delivered', 'label': 'Ikke levert'}, {'key': 'other', 'label': 'Annet'}],
});

Widget _host(void Function(BuildContext) onOpen) => MaterialApp(
  home: Scaffold(
    body: Builder(builder: (context) => Center(child: ElevatedButton(key: const Key('open'), onPressed: () => onOpen(context), child: const Text('open')))),
  ),
);

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await a3Bootstrap();
  });

  test('models: the issue, the status, the notice with options and the effects', () {
    final i = CusIssue.fromJson(_reviewing);
    expect([i.caseRef, i.outcome, i.amountDisplay, i.answerBy, i.open, i.loest, i.items.single, i.conversationId], ['Æ-2E6-1', 'reviewing', '89 kr', '18:52', true, false, 'Rømme, 300 g', 7]);
    final d = CusIssue.fromJson(_denied);
    expect([d.loest, d.canReopen, d.reply!.by, d.statusText], [true, true, 'Mari', 'Avgjort · ingen refusjon']);
    expect(_status.types.length, 6);
    expect(_status.canReport, isTrue);
    final t = OpsTracking.fromJson(const {
      'order_id': '402', 'state': 'seen', 'stage': 0, 'stage_label': 'Bekreftet', 'store': {'id': 95, 'name': 'Red Sun (Test)'},
      'notice': {'key': 'n:52', 'kind': 'delay_notice', 'title': 'Bestillingen din er forsinket', 'body': 'Red Sun (Test) har ikke bekreftet ennå.', 'options': [{'key': 'wait', 'label': 'Vent', 'window_start': '2026-10-22T13:07:00+02:00', 'window_end': '2026-10-22T13:31:00+02:00'}, {'key': 'cancel', 'label': 'Avbestill', 'policy': 'full_refund'}]},
      'effects': [{'text_key': 'ai_done_delay_notice', 'text': 'Utført av Ærend AI: kunden fikk ny tid', 'text_en': 'Done by Ærend AI: the customer got a new time', 'at': '2026-10-22T18:19:10+02:00'}],
    });
    expect(t.notice!.wait!.window, matches(RegExp(r'^\d\d:\d\d–\d\d:\d\d$')));
    expect(t.notice!.cancel!.policy, 'full_refund');
    expect(t.effects.single.textKey, 'ai_done_delay_notice');
    expect(SporingCopy.cus_ai_utfort('ai_done_delay_notice', 'x', 'y'), 'Utført av Ærend AI: du fikk ny tid');
    expect(SporingCopy.cus_ai_utfort('ai_done_unknown', 'Utført av Ærend AI: noe', 'Done'), 'Utført av Ærend AI: noe');
  });

  testWidgets('the C2 sheet: six chips, «Send» live after a chip, the chip and the line go to the server, «Ser på det» with the case card', (tester) async {
    phone(tester);
    final cus = _Cus(answer: _reviewing);
    CusIssue? out;
    await tester.pumpWidget(_host((c) async => out = await visNoeGaltC2(c, ordre: _ordre, status: _status, api: cus, velgBilde: () async => null)));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cus-sak-skriv')), findsOneWidget);
    expect(find.text('Hva skjedde?'), findsOneWidget);
    for (final k in ['missing_item', 'wrong_item', 'damaged', 'cold_late', 'not_delivered', 'other']) {
      expect(find.byKey(Key('cus-sak-type-$k')), findsOneWidget);
    }
    expect(find.byKey(const Key('cus-sak-ta-bilde')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sak-type-missing_item')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cus-sak-tekst')), 'Rømmen manglet');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cus-sak-send')));
    await tester.pumpAndSettle();
    expect(cus.calls, ['open:404:missing_item:Rømmen manglet:-:false']);
    expect(find.byKey(const Key('cus-sak-utfall-reviewing')), findsOneWidget);
    expect(find.text('Vi ser på det og svarer innen 15 minutter.'), findsOneWidget);
    expect(find.byKey(const Key('cus-sak-kort')), findsOneWidget);
    expect(find.text('Sak Æ-2E6-1 er åpen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sak-ferdig')));
    await tester.pumpAndSettle();
    expect(out?.caseRef, 'Æ-2E6-1');
  });

  testWidgets('the outcomes: «Løst» with the sticker, «Beklager» with the proof, «allerede åpen» → «Legg til i saken» joins the case', (tester) async {
    phone(tester);
    final cus = _Cus(answer: _reviewing);
    await tester.pumpWidget(_host((c) => visNoeGaltC2(c, ordre: _ordre, status: _status, api: cus, fake: CusIssue.fromJson(_resolved))));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cus-sak-utfall-resolved')), findsOneWidget);
    expect(find.byKey(const Key('cus-sak-sticker')), findsOneWidget);
    expect(find.text('+89 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sak-ferdig')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host((c) => visNoeGaltC2(c, ordre: _ordre, status: _status, api: cus, fake: CusIssue.fromJson(_notDelivered))));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cus-sak-utfall-not_delivered')), findsOneWidget);
    expect(find.byKey(const Key('cus-sak-bevis')), findsOneWidget);
    expect(find.text('Levert ved døren'), findsOneWidget);
    expect(find.text('Vi ser på det nå.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sak-ferdig')));
    await tester.pumpAndSettle();

    // C2.8: the case is open already — the next line joins it.
    final already = CusIssueStatus.fromJson({'delivered': true, 'can_report': true, 'sla_minutes': 15, 'issue': _reviewing});
    await tester.pumpWidget(_host((c) => visNoeGaltC2(c, ordre: _ordre, status: already, api: cus)));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cus-sak-allerede')), findsOneWidget);
    expect(find.text('Denne saken er allerede åpen.'), findsOneWidget);
    expect(find.byKey(const Key('cus-sak-se-saken')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-sak-legg-til')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cus-sak-skriv')), findsOneWidget);
    expect(find.text('Det du skriver nå legges til saken.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cus-sak-tekst')), 'Og brødet var tørt');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cus-sak-send')));
    await tester.pumpAndSettle();
    expect(cus.calls.last, 'append:12:Og brødet var tørt');
  });

  testWidgets('the case row: the status line, the person\'s answer, «Ikke løst»; the notice card with the new window', (tester) async {
    phone(tester);
    var reopened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              IssueSakRad(issue: CusIssue.fromJson(_denied), onIkkeLost: () => reopened++),
              IssueSakRad(key: const Key('rad2'), issue: CusIssue.fromJson(_reviewing)),
              ValgSomVenterCard(storeName: 'Red Sun (Test)', tittel: 'Bestillingen din er forsinket', linje: 'Vent på nytt vindu.', ventLabel: 'Vent · ny tid 13:07–13:31', avbestill: true, onWait: () {}, onCancel: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Avgjort · ingen refusjon'), findsOneWidget);
    expect(find.byKey(const Key('oh-sak-svar')), findsOneWidget);
    expect(find.textContaining('Mari, Ærend'), findsOneWidget);
    expect(find.byKey(const Key('oh-sak-ikke-lost')), findsOneWidget);
    await tester.tap(find.byKey(const Key('oh-sak-ikke-lost')));
    expect(reopened, 1);
    expect(find.text('Vi ser på det · svar innen 15 min'), findsOneWidget);
    expect(find.text('Vent · ny tid 13:07–13:31'), findsOneWidget);
    expect(find.text('Bestillingen din er forsinket'), findsOneWidget);
  });

  test('the support store keeps the order\'s newest issue; the chat labels say AI', () {
    final s = SupportStore.instance;
    s.settSak(CusIssue.fromJson(_reviewing));
    expect(s.issueFor(404)!.caseRef, 'Æ-2E6-1');
    s.settSak(CusIssue.fromJson(_denied));
    expect(s.issueFor(404)!.outcome, 'denied');
    expect(SupportCopy.aiUnder, contains('AI'));
    expect(SupportCopy.merkeAi('18:02', navn: 'Ærend AI'), 'ÆREND AI · 18:02');
    expect(SupportCopy.merkeAi('18:02'), 'ÆREND-ASSISTENT · 18:02');
    expect(SupportCopy.koUnder(2, 15), 'Nummer 2 i køen · svar innen 15 min');
  });
}
