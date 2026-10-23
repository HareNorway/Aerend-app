import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_agenter.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_chat.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_verktoy.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_kvittering.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 9 in the app: the chat's cards for the gift agent
/// (the brief chips, the brief read back, three cards, the card text, the
/// honest empty card), reorder by photo (the camera prompt, one hit, «Var
/// det denne?», nothing), the Kasse's gift line, and the models.

const _giftJson = {
  'id': 7, 'state': 'open', 'round': 1, 'readback': 'Gave til mamma, bursdag, under 600 kr, til lørdag, liker hage.', 'title': 'Tre som rekker fram lørdag',
  'parsed': {'to': 'mamma', 'occasion': 'bursdag', 'budget_min_ore': 0, 'budget_max_ore': 60000, 'deliver_by': '2026-10-24', 'interests': ['hage']},
  'cards': [
    {'store_product_id': 11, 'name': 'Hortensia i potte', 'store': 'Hagen i Sandviken', 'store_id': 43, 'price': {'display': '449 kr'}, 'price_ore': 44900, 'deliver': 'lørdag', 'reason': 'hagebutikk på Nordnes · innenfor budsjettet · levert innen lørdag'},
    {'store_product_id': 12, 'name': 'Hagesaks «Fjære»', 'store': 'Fana trevare', 'store_id': 44, 'price': {'display': '389 kr'}, 'price_ore': 38900, 'deliver': 'lørdag', 'reason': 'hun liker hage · innenfor budsjettet'},
    {'store_product_id': 13, 'name': 'Bok: «Hagen året rundt»', 'store': 'Bergen bokhandel', 'store_id': 45, 'price': {'display': '329 kr'}, 'price_ore': 32900, 'deliver': 'lørdag', 'reason': 'matcher «liker hage» · rekker fram lørdag med god margin'},
  ],
  'card_text': 'Gratulerer med dagen, mamma.\nEn hortensia til hagen, så den blomstrer lenge etter i dag.\nKlem fra Didrik.',
  'card_source': 'fallback', 'source': 'fallback', 'more': true, 'brief': 'gave til mamma',
};

const _emptyJson = {
  'id': 8, 'state': 'cancelled', 'readback': 'Gave til pappa, under 300 kr, til i dag.', 'cards': [], 'empty': true,
  'text': 'Ingenting rekker fram til i dag.', 'sub': 'Vil du ha til mandag? Da har jeg fem forslag under 300 kr.', 'next_day': '2026-10-26', 'next_label': 'Mandag', 'next_count': 5,
  'parsed': {'to': 'pappa', 'occasion': null, 'budget_min_ore': 0, 'budget_max_ore': 30000, 'deliver_by': '2026-10-22', 'interests': []},
};

const _scanOne = {
  'id': 3, 'hit': 'one', 'took_ms': 1200, 'ocr_text': 'Tine Lettmelk', 'ean': '7038010009457',
  'candidates': [{'store_product_id': 21, 'name': 'Tine Lettmelk, 1 l', 'store': 'Torgboden', 'store_id': 43, 'price': {'display': '24 kr'}, 'confidence': 0.95, 'reason': 'strekkoden traff én vare, og Torgboden er butikken du pleier å bruke', 'usual_store': true}],
};

const _scanAsk = {
  'id': 4, 'hit': 'ask', 'ocr_text': 'Kaffe 500 g',
  'candidates': [
    {'store_product_id': 31, 'name': 'Kaffe, mørkbrent 500 g', 'store': 'Torgboden', 'store_id': 43, 'price': {'display': '89 kr'}, 'confidence': 0.55},
    {'store_product_id': 32, 'name': 'Kaffe, filtermalt 500 g', 'store': 'Torgboden', 'store_id': 43, 'price': {'display': '84 kr'}, 'confidence': 0.55},
  ],
};

const _scanNone = {'id': 5, 'hit': 'none', 'ocr_text': 'Kvikk Lunsj', 'candidates': []};

class _H implements AeHandling {
  final List<String> calls = [];
  final Map<String, AeVerktoy> naa = {};

  @override
  AeVerktoy verktoy(AeVerktoy v) => naa[v.id ?? ''] ?? v;

  @override
  Future<void> giftBrief(Map<String, dynamic> fields, String text) async => calls.add('brief:${fields['to']}:${fields['occasion']}:${fields['budget']}:${fields['deliver_by']}:${(fields['interests'] as List?)?.join(',') ?? '-'}');
  @override
  Future<void> giftConfirm(GiftResult r) async => calls.add('confirm:${r.id}');
  @override
  void giftEdit(GiftResult r) => calls.add('edit:${r.id}');
  @override
  Future<void> giftMore(GiftResult r) async => calls.add('more:${r.id}');
  @override
  Future<void> giftCard(GiftResult r, String action, String? text) async => calls.add('card:$action:${text ?? '-'}');
  @override
  Future<void> giftChoose(GiftResult r, GiftCard c) async => calls.add('choose:${c.storeProductId}');
  @override
  void giftSave(AeVerktoy v, GiftCard c) => calls.add('save:${c.storeProductId}');
  @override
  Future<void> giftRetry(GiftResult r, String day) async => calls.add('retry:$day');
  @override
  Future<void> reorderShoot() async => calls.add('shoot');
  @override
  Future<void> reorderChoose(AeVerktoy v, ReorderResult r, ReorderCandidate? c) async => calls.add('reorder:${r.id}:${c?.storeProductId ?? '-'}');
  @override
  void reorderSearch(String text) => calls.add('search:$text');

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(12), child: child))));

void main() {
  setUpAll(() async {
    await a3Bootstrap();
    OpsCustomerApi.networkEnabled = false;
  });

  tearDown(() {
    A3Services.reset();
    GiftPending.current = null;
  });

  test('the agent models read the server shape', () {
    final g = GiftResult.fromJson(_giftJson);
    expect([g.id, g.cards.length, g.cards.first.price, g.cards.first.deliver, g.more, g.title], [7, 3, '449 kr', 'lørdag', true, 'Tre som rekker fram lørdag']);
    final e = GiftResult.fromJson(_emptyJson);
    expect([e.empty, e.nextDay, e.nextLabel, e.cards], [true, '2026-10-26', 'Mandag', <GiftCard>[]]);
    final s = ReorderResult.fromJson(_scanOne);
    expect([s.hit, s.candidates.single.confidence, s.candidates.single.usualStore, s.tookMs], ['one', 0.95, true, 1200]);
    final d = DoorResult.fromJson(const {'id': 2, 'fields': {'floor': 3, 'bell': 'Hansen', 'entrance': 'bakgården', 'code': '1234'}, 'has_code': true, 'code_consent': false, 'needs_floor': false, 'preview': 'Etasje 3 · Ring på Hansen · Inngang bakgården · Kode 1234', 'address': 'Nordnesveien 12'});
    expect(d.fields.line(), 'Etasje 3 · Ring på Hansen · Inngang bakgården · Kode 1234');
    expect(d.fields.line(withCode: false), 'Etasje 3 · Ring på Hansen · Inngang bakgården');
    expect(d.fields.copyWith(floor: 4).line(withCode: false), startsWith('Etasje 4'));
    expect(const DoorFields().isEmpty, isTrue);
  });

  testWidgets('the brief card: chips, «Finn gaver» live after two, prefilled from the line', (tester) async {
    final h = _H();
    await tester.pumpWidget(_app(AeVerktoyKort(v: AeVerktoy('gift_brief', const {'id': 'gift_brief:0', 'prefill': {'to': 'mamma', 'deliver_by': '2026-10-24', 'interests': ['hage']}, 'text': 'gave til mamma'}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_gave_fortell), findsOneWidget);
    expect(find.text('Liker hage'), findsOneWidget, reason: 'prefilled from the line');
    // Mamma and the day are prefilled: two chips, so the key is live; add the occasion and the budget.
    await tester.tap(find.byKey(const Key('gave-ANLEDNING-bursdag')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('gave-BUDSJETT-300_600')));
    await tester.tap(find.byKey(const Key('gave-BUDSJETT-300_600')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('gave-finn')));
    await tester.tap(find.byKey(const Key('gave-finn')));
    await tester.pump();
    expect(h.calls, ['brief:mamma:bursdag:300_600:lørdag:hage'], reason: 'the 24th is a Saturday: the chip, not the date');
  });

  testWidgets('the brief read back: «Stemmer» / «Endre»; three cards with Derfor, Velg, Lagre, «Se tre til»; the card text; the empty card', (tester) async {
    final h = _H();
    final g = GiftResult.fromJson(_giftJson);
    await tester.pumpWidget(_app(Column(children: [
      AeVerktoyKort(v: AeVerktoy('gift_readback', {'id': 'gift_readback:7:1', 'gift': g.raw}), h: h),
      AeVerktoyKort(v: AeVerktoy('gift_set', {'id': 'gift_set:7:1', 'gift': g.raw}), h: h),
    ])));
    await tester.pumpAndSettle();
    expect(find.text(g.readback), findsOneWidget);
    await tester.tap(find.byKey(const Key('gave-stemmer')));
    await tester.tap(find.byKey(const Key('gave-endre')));
    expect(find.text('Hortensia i potte'), findsOneWidget);
    expect(find.text('Rekker fram lørdag'), findsNWidgets(3));
    expect(find.textContaining('hagebutikk på Nordnes', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const Key('gave-lagre-12')));
    await tester.ensureVisible(find.byKey(const Key('gave-velg-11')));
    await tester.tap(find.byKey(const Key('gave-velg-11')));
    await tester.ensureVisible(find.byKey(const Key('gave-tre-til')));
    await tester.tap(find.byKey(const Key('gave-tre-til')));
    expect(h.calls, ['confirm:7', 'edit:7', 'save:12', 'choose:11', 'more:7']);

    // The card text: edited, then «Bruk kortet»; «Skriv om»; «Uten kort».
    await tester.pumpWidget(_app(AeVerktoyKort(v: AeVerktoy('gift_card', {'id': 'gift_card:7:1', 'gift': g.raw, 'til': 'Hortensia i potte'}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_gave_til('Hortensia i potte')), findsOneWidget);
    expect(find.text(g.cardText!), findsOneWidget);
    await tester.enterText(find.byKey(const Key('gave-kort-tekst')), 'Til verdens beste mamma.\nKlem fra oss.');
    await tester.tap(find.byKey(const Key('gave-bruk-kortet')));
    await tester.tap(find.byKey(const Key('gave-skriv-om')));
    await tester.tap(find.byKey(const Key('gave-uten-kort')));
    expect(h.calls.sublist(5), ['card:use:Til verdens beste mamma.\nKlem fra oss.', 'card:rewrite:-', 'card:none:-']);

    // Nothing arrives in time: the next day, or another budget.
    await tester.pumpWidget(_app(AeVerktoyKort(v: AeVerktoy('gift_empty', {'id': 'gift_empty:8:0', 'gift': _emptyJson}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text('Ingenting rekker fram til i dag.'), findsOneWidget);
    expect(find.text('Mandag'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gave-neste-dag')));
    await tester.tap(find.byKey(const Key('gave-endre-budsjett')));
    expect(h.calls.sublist(8), ['retry:2026-10-26', 'edit:8']);
  });

  testWidgets('reorder by photo: the prompt, one hit with «Legg til», «Var det denne?», nothing recognised', (tester) async {
    final h = _H();
    await tester.pumpWidget(_app(AeVerktoyKort(v: const AeVerktoy('reorder_prompt', {'id': 'reorder_prompt:0'}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_bilde_ta), findsOneWidget);
    expect(find.text(AeAgentCopy.cus_bilde_slettes), findsOneWidget);
    await tester.tap(find.byKey(const Key('bilde-ta')));
    expect(h.calls, ['shoot']);

    await tester.pumpWidget(_app(AeVerktoyKort(v: const AeVerktoy('reorder_result', {'id': 'reorder_result:3', 'scan': _scanOne}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text('Tine Lettmelk, 1 l'), findsOneWidget);
    expect(find.textContaining('strekkoden traff én vare', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const Key('bilde-legg-til')));
    expect(h.calls.last, 'reorder:3:21');
    // Added: the key says so and is off.
    h.naa['reorder_result:3'] = const AeVerktoy('reorder_result', {'id': 'reorder_result:3', 'scan': _scanOne, 'gjort': 'lagt'});
    await tester.pumpWidget(_app(AeVerktoyKort(v: h.verktoy(const AeVerktoy('reorder_result', {'id': 'reorder_result:3', 'scan': _scanOne})), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_bilde_lagt), findsOneWidget);

    await tester.pumpWidget(_app(AeVerktoyKort(v: const AeVerktoy('reorder_result', {'id': 'reorder_result:4', 'scan': _scanAsk}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_bilde_var_det), findsOneWidget);
    expect(find.text('Kaffe, filtermalt 500 g'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bilde-velg-32')));
    await tester.tap(find.byKey(const Key('bilde-ingen-av')));
    expect(h.calls.sublist(2), ['reorder:4:32', 'reorder:4:-']);

    await tester.pumpWidget(_app(AeVerktoyKort(v: const AeVerktoy('reorder_result', {'id': 'reorder_result:5', 'scan': _scanNone}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_bilde_kjente_ikke), findsOneWidget);
    expect(find.text('Kvikk Lunsj'), findsOneWidget, reason: 'the search is prefilled from the package');
    await tester.enterText(find.byKey(const Key('bilde-sok')), 'Kvikk Lunsj');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.tap(find.byKey(const Key('bilde-nytt')));
    expect(h.calls.sublist(4), ['search:Kvikk Lunsj', 'shoot']);

    await tester.pumpWidget(_app(AeVerktoyKort(v: const AeVerktoy('reorder_result', {'id': 'reorder_result:6', 'scan': {'id': 6, 'hit': 'none', 'blocked': 'age', 'candidates': []}}), h: h)));
    await tester.pumpAndSettle();
    expect(find.text(AeAgentCopy.cus_bilde_alder), findsOneWidget);
    expect(find.byKey(const Key('bilde-sok')), findsNothing, reason: 'no card for an age-restricted product');
  });

  testWidgets('the Kasse gift line: «GAVE · MED KORT», who it is for, the card text', (tester) async {
    await tester.pumpWidget(_app(const KvGave(navn: 'Hortensia i potte', til: 'mamma', kort: 'Gratulerer med dagen, mamma.\nKlem fra Didrik.')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('a1_kasse_gave_kort')), findsOneWidget);
    expect(find.text('GAVE · MED KORT'), findsOneWidget);
    expect(find.textContaining('mamma'), findsWidgets);
    await tester.pumpWidget(_app(const KvGave(navn: 'Hortensia i potte')));
    await tester.pumpAndSettle();
    expect(find.text('GAVE'), findsOneWidget);
  });
}
