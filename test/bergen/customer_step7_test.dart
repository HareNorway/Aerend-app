import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_minne.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_harness.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/min_bio.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 7 in the app: the basket's lines Ægil merged (marked
/// from `agent/me/cart/agent-lines`), «Angre» on a receipt in «Mens du var
/// borte», the push invitation card, and the learned patterns in Minne with
/// «Stemmer» / ✕.

const _lineA = KurvLine(cartId: 11, productId: 1, name: 'Laksefilet', quantity: 1, unitPrice: 149, storeId: 43);
const _lineB = KurvLine(cartId: 12, productId: 2, name: 'Reker', quantity: 2, unitPrice: 60, storeId: 43);

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  setUpAll(() async {
    await a3Bootstrap();
    OpsCustomerApi.networkEnabled = false;
  });

  tearDown(() {
    A3Services.reset();
    HjemHarness.hjemInvitasjon = false;
    // ignore: invalid_use_of_visible_for_testing_member
    setPushInviteForTest(false);
    // ignore: invalid_use_of_visible_for_testing_member
    setMensDuVarBorteForTest(const []);
  });

  test('the basket marks the lines Ægil merged', () {
    const cart = KurvState(lines: [_lineA, _lineB], storeId: 43);
    expect(cart.aegilLines, isEmpty);
    final marked = cart.medAegilLinjer({12});
    expect(marked.aegilLines.map((l) => l.cartId), [12]);
    expect(marked.lines.first.addedByAegil, isFalse);
    expect(marked.subtotal, cart.subtotal);
    expect(AgentLine.fromJson(const {'line_id': 12, 'name': 'Reker', 'price': {'display': '120 kr'}, 'action_id': 7}).actionId, 7);
    expect(AwayItem.fromJson(const {'id': 1, 'text': 'x', 'action': 'cart.merged', 'undoable': true, 'undone': true}).undone, isTrue);
    expect(const AegilSettings().pushInvited, isTrue, reason: 'no card until the server says the invitation is due');
    expect(AegilSettings.fromJson(const {'push_invited': false, 'patterns_proposed': 2}).patternsProposed, 2);
  });

  testWidgets('«Mens du var borte»: «Angre» on a merge undoes the receipt and says «Angret»', (tester) async {
    final api = FakeAegilApi();
    A3Services.aegil = () => api;
    // ignore: invalid_use_of_visible_for_testing_member
    setMensDuVarBorteForTest(const [
      AwayItem(id: 5, text: 'Ægil la Laksefilet i kurven · 149 kr', action: 'cart.merged', undoable: true),
      AwayItem(id: 6, text: 'Fant reker på tilbud', action: 'suggestion.open'),
      AwayItem(id: 7, text: 'Ægil la Reker i kurven · 120 kr', action: 'cart.merged', undoable: false, undone: true),
    ]);
    await tester.pumpWidget(_app(Builder(builder: (context) => mensDuVarBorteCard(context)!)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('borte-angre-5')), findsOneWidget);
    expect(find.byKey(const Key('borte-angre-6')), findsNothing);
    expect(find.byKey(const Key('borte-angret-7')), findsOneWidget, reason: 'already undone: no key, «Angret»');

    await tester.tap(find.byKey(const Key('borte-angre-5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.undoneActions, [5]);
    expect(find.byKey(const Key('borte-angre-5')), findsNothing);
    expect(find.byKey(const Key('borte-angret-5')), findsOneWidget);
    expect(find.text('Ægil la Laksefilet i kurven · 149 kr'), findsOneWidget, reason: 'the receipt stays readable');
  });

  testWidgets('the push invitation card asks once; «Ja takk» / «Nei takk» answer the server', (tester) async {
    final api = FakeAegilApi();
    A3Services.aegil = () => api;
    await tester.pumpWidget(_app(Builder(builder: (context) => pushInviteCard(context) ?? const Text('ingen'))));
    expect(find.text('ingen'), findsOneWidget, reason: 'not due: nothing');

    // ignore: invalid_use_of_visible_for_testing_member
    setPushInviteForTest(true);
    await tester.pumpWidget(_app(Builder(builder: (context) => pushInviteCard(context) ?? const Text('ingen'))));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('invit-card')), findsOneWidget);
    expect(find.text('Vil du at Ægil sier fra?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invit-nei')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.invited, isFalse);
    expect(find.byKey(const Key('invit-card')), findsNothing);
    expect(pushInviteCard(tester.element(find.byType(Scaffold))), isNull, reason: 'answered: not asked again');

    // The harness shows it regardless (`hjemInvitasjon`); a fresh tree, so the answered card's state is gone.
    HjemHarness.hjemInvitasjon = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(Builder(builder: (context) => pushInviteCard(context) ?? const Text('ingen'))));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('invit-ja')));
    await tester.pump();
    expect(api.invited, isTrue);
  });

  testWidgets('Minne lists what Ægil noticed; «Stemmer» confirms, ✕ rejects', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final valg = <(int, bool)>[];
    const monstre = [
      LearnedPatternItem(id: 1, type: 'recurring_item', text: 'Du pleier å kjøpe Laksefilet omtrent hver uke', support: 'Sett i 5 av 6 bestillinger'),
      LearnedPatternItem(id: 2, type: 'dinner_rhythm', text: 'Du bestiller middag de fleste onsdager rundt 17:40', support: 'Sett 4 av 5 onsdager', confirmed: true),
    ];
    await tester.pumpWidget(_app(AeMinneView(
      data: AeMinneData(const []),
      bio: const MinBio(),
      varsler: 'Daglig',
      nivaaNavn: 'Varsle og foreslå',
      onFjern: (_) {},
      onStemmer: (_) {},
      onLeggTil: () {},
      onNivaa: () {},
      onGlem: () {},
      onBio: () {},
      monstre: monstre,
      onMonster: (p, stemmer) => valg.add((p.id, stemmer)),
    )));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Du pleier å kjøpe Laksefilet omtrent hver uke'), findsOneWidget);
    expect(find.text('Sett i 5 av 6 bestillinger · kun forslag til du bekrefter'), findsOneWidget);
    expect(find.text('Bekreftet — styrer automatikk'), findsOneWidget);
    expect(find.byKey(const Key('a1_aegil_monster_stemmer_1')), findsOneWidget);
    expect(find.byKey(const Key('a1_aegil_monster_stemmer_2')), findsNothing, reason: 'confirmed: no «Stemmer»');

    await tester.ensureVisible(find.byKey(const Key('a1_aegil_monster_stemmer_1')));
    await tester.tap(find.byKey(const Key('a1_aegil_monster_stemmer_1')));
    await tester.pump();
    expect(valg, [(1, true)]);
  });
}
