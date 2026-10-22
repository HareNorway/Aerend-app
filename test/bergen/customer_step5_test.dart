import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_guide.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_screen.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/tillit_ark.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 5: the Ægil chat on the gateway in the app — typed
/// tool cards (an order's status, a cart change proposed, applied with the
/// receipt and undone with «Angre»), the conversation resumed after a
/// relaunch, «Ægil er en AI» and «Snakk med et menneske», «Spør Ægil» from a
/// tracking view, and Meg's Tillitsregnskap.

class _Kasse extends OpsKasseApi {
  int hentet = 0;

  @override
  Future<KurvState> cart() async {
    hentet++;
    return const KurvState();
  }
}

class _Kunde extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<PointsRules?> rules() async => null;
}

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 700));
}

Widget _skjerm(FakeAegilApi api, {Map<String, String> args = const {}, _Kasse? kasse}) => MaterialApp(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    settings: RouteSettings(name: '/', arguments: args),
    builder: (_) => AegilScreen(api: api, repo: FakeAegilRepo(), steg: 'start', kasseApi: kasse ?? _Kasse(), customerApi: _Kunde()),
  ),
);

Future<void> _skriv(WidgetTester tester, String t) async {
  await tester.enterText(find.byKey(const Key('a1_aegil_felt')), t);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 2500));
}

const _forslag = AeVerktoy('cart_proposal', {
  'type': 'cart_proposal',
  'id': 'pa_test1',
  'action': 'add',
  'status': 'proposed',
  'qty': 1,
  'product': {'id': 803, 'name': 'Reker 500 g', 'price_ore': 18900, 'store': 'Torgboden'},
});

const _ordre = AeVerktoy('order_status', {
  'type': 'order_status',
  'order': {'id': 405, 'number': 'Æ-23X', 'store': 'Torgboden', 'status': 'På vei', 'window': '18:10–18:25'},
});

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {'flutter.${AegilScreen.prefTillatelse}': true, AegilScreen.prefTillatelse: true});
    OpsCustomerApi.networkEnabled = false;
  });

  setUp(() {
    A3Services.points = () => FakePointsApi();
    HurtigKilde.memory = () async => const <MemoryEntry>[];
    AegilGuide.reset();
  });

  tearDown(() {
    A3Services.reset();
    HurtigKilde.reset();
  });

  testWidgets('a turn with tool cards: the order card, the proposal → the receipt → «Angre»', (tester) async {
    _frame(tester);
    final kasse = _Kasse();
    final api = FakeAegilApi(
      turn: const AegilTurn(state: 'agForslag', reply: 'Skal jeg legge Reker 500 g i kurven?', conversationId: 'cv_a', source: 'model', verktoy: [_ordre, _forslag]),
    )..actionValue = _forslag.med({'status': 'applied', 'receipt': {'text': 'Reker 500 g ligger i kurven.'}});
    await tester.pumpWidget(_skjerm(api, kasse: kasse));
    await _settle(tester);

    await _skriv(tester, 'Legg til reker');
    expect(find.text('Æ-23X · Torgboden'), findsOneWidget);
    expect(find.text('På vei · 18:10–18:25'), findsOneWidget);
    expect(find.byKey(const Key('cus-aegil-forslag-pa_test1')), findsOneWidget);
    // Nothing happened yet: the basket changes only on the tap.
    expect(api.calls.where((c) => c.startsWith('apply')), isEmpty);

    await tester.ensureVisible(find.byKey(const Key('cus-aegil-forslag-bruk-pa_test1')));
    await tester.tap(find.byKey(const Key('cus-aegil-forslag-bruk-pa_test1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.calls, contains('apply:pa_test1'));
    expect(find.byKey(const Key('cus-aegil-kvittering-pa_test1')), findsOneWidget);
    expect(find.text('Kvittering'), findsOneWidget);
    expect(find.text('+ Reker 500 g · 189 kr'), findsOneWidget);
    expect(kasse.hentet, greaterThan(1), reason: 'the basket is read again after the tap');

    await tester.tap(find.byKey(const Key('cus-aegil-angre-pa_test1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.calls, contains('undo:pa_test1'));
    expect(find.text('Angret'), findsOneWidget);

    // The next line continues the same conversation.
    await _skriv(tester, 'Takk');
    expect(api.chats.last['conversation_id'], 'cv_a');
  });

  testWidgets('the chat resumes the latest open conversation after a relaunch', (tester) async {
    _frame(tester);
    final api = FakeAegilApi()
      ..samtalerValue = [AegilSamtale(id: 'cv_b', title: 'Hvor er bestillingen min?', messageCount: 2, lastMessageAt: DateTime.now().subtract(const Duration(minutes: 20)))]
      ..samtaleValue = {
        'cv_b': [
          const AegilSamtaleLinje(meg: true, tekst: 'Hvor er bestillingen min?'),
          AegilSamtaleLinje(meg: false, tekst: 'Her er status nå.', turn: const AegilTurn(state: 'agStatus', reply: 'Her er status nå.', verktoy: [_ordre])),
        ],
      };
    await tester.pumpWidget(_skjerm(api));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 1500));

    expect(api.calls, containsAllInOrder(['conversations', 'conversation:cv_b']));
    expect(find.text('Hvor er bestillingen min?'), findsOneWidget);
    expect(find.text('Æ-23X · Torgboden'), findsOneWidget);

    await _skriv(tester, 'Når er den her?');
    expect(api.chats.last['conversation_id'], 'cv_b');

    // «Ny prat» closes it; the next line starts a new one.
    await tester.ensureVisible(find.byKey(const Key('a1_aegil_ny_prat')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('a1_aegil_ny_prat')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.calls, contains('close:cv_b'));
  });

  testWidgets('an old conversation is not resumed', (tester) async {
    _frame(tester);
    final api = FakeAegilApi()..samtalerValue = [AegilSamtale(id: 'cv_c', messageCount: 4, lastMessageAt: DateTime.now().subtract(const Duration(days: 2)))];
    await tester.pumpWidget(_skjerm(api));
    await _settle(tester);
    expect(api.calls, contains('conversations'));
    expect(api.calls, isNot(contains('conversation:cv_c')));
  });

  testWidgets('«Ægil er en AI» in the header and the chat; «Snakk med et menneske» is there', (tester) async {
    _frame(tester);
    final api = FakeAegilApi(turn: const AegilTurn(state: 'agSvar', reply: 'Hei!'));
    await tester.pumpWidget(_skjerm(api));
    await _settle(tester);
    expect(find.byKey(const Key('cus-aegil-ai-merke')), findsOneWidget);

    await _skriv(tester, 'Hei');
    expect(find.byKey(const Key('cus-aegil-er-ai')), findsOneWidget);
    expect(find.byKey(const Key('cus-aegil-menneske')), findsOneWidget);
    expect(find.text('Snakk med et menneske'), findsOneWidget);
  });

  testWidgets('«Spør Ægil» from a tracking view: the order chip, the order with the chat', (tester) async {
    _frame(tester);
    final api = FakeAegilApi(turn: const AegilTurn(state: 'agStatus', reply: 'Den er på vei.', verktoy: [_ordre]));
    await tester.pumpWidget(_skjerm(api, args: {'order_id': '405', 'order': 'Æ-23X'}));
    await _settle(tester);
    expect(find.text('Om Æ-23X'), findsOneWidget);
    expect(api.calls, isEmpty, reason: 'nothing is asked, and nothing older is resumed');

    await _skriv(tester, 'Hvor er den?');
    expect(api.chats.single['order_id'], 405);
    expect(api.chats.single.containsKey('intent'), isTrue);
    expect(api.chats.single['intent'], isNull, reason: 'an order context sends no intent: the chat answers, not the rules');
  });

  test('Tillitsregnskap: the design\'s line from the month', () {
    const t = TrustLedger(month: '2026-10', savedKr: 30, againstInterestShown: 3, waitRecommended: 1, cheaperElsewhereTaken: 1, lines: [(text: 'Anbefalte å vente på reker', sub: 'Du tok rådet · sparte 30 kr · 21.10')]);
    expect(TillitArk.linje(t), '3 råd mot egen interesse · 1 vent-anbefalinger · 1 billigere andre steder som du tok. Ægil sparte deg 30 kr denne måneden.');
    final j = TrustLedger.fromJson({
      'month': '2026-10',
      'saved_kr': 30,
      'lines': [
        {'text': 'Anbefalte å vente på reker', 'sub': 'Du tok rådet · sparte 30 kr · 21.10'},
      ],
    });
    expect(j.lines.single.text, 'Anbefalte å vente på reker');
  });
}
