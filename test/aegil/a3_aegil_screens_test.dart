import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_entry.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_screen.dart';
import 'package:aerend_customer/screens/bergen/aegil/brett_entry.dart';
import 'package:aerend_customer/screens/bergen/aegil/minne_screen.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — Ægil: every reply state is a card, the basket is
/// added only on tap, the memory screen shows what Ægil knows and forgets it.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() => A3Services.reset());

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Ægil: greeting, evening cards, ask → agForslag basket → Legg i kurven', (tester) async {
    final api = FakeAegilApi();
    final repo = FakeAegilRepo();
    await tester.pumpWidget(a3App(AegilScreen(api: api, repo: repo)));
    await settle(tester);

    expect(find.text('Lytter'), findsOneWidget);
    expect(find.textContaining('Nivå · Varsle og foreslå'), findsOneWidget);
    expect(find.text('Tacokveld for fire'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('aegil-ask')), 'taco for fire');
    await tester.ensureVisible(find.byKey(const Key('aegil-send')));
    await tester.tap(find.byKey(const Key('aegil-send')));
    await settle(tester);

    expect(api.calls, contains('chat:taco for fire'));
    expect(find.byKey(const Key('aegil-turn-agForslag')), findsOneWidget);
    expect(find.textContaining('2 × Tortilla'), findsOneWidget);
    expect(find.textContaining('Derfor: billigst av tre'), findsOneWidget);
    expect(api.calls.where((c) => c.startsWith('add:')), isEmpty);

    await tester.tap(find.byKey(const Key('aegil-legg')));
    await settle(tester);
    expect(api.calls, contains('add:11'));
    expect(find.text('Kvittering'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Ægil: agAldersblokk shows the 18+ card with the BankID door', (tester) async {
    final api = FakeAegilApi(turn: const AegilTurn(state: 'agAldersblokk', reply: 'Det kan jeg ikke hjelpe med ennå.', ageGate: true));
    await tester.pumpWidget(a3App(AegilScreen(api: api, repo: FakeAegilRepo())));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('aegil-ask')), 'rødvin');
    await tester.ensureVisible(find.byKey(const Key('aegil-send')));
    await tester.tap(find.byKey(const Key('aegil-send')));
    await settle(tester);

    expect(find.text('Beklager…'), findsOneWidget);
    expect(find.text('18+ · ikke verifisert'), findsOneWidget);
    expect(find.text('Til Konto · BankID'), findsOneWidget);
  });

  testWidgets('Ægil: agIkkeFunnet explains itself', (tester) async {
    final api = FakeAegilApi(turn: const AegilTurn(state: 'agIkkeFunnet', reply: 'Fant ikke noe i Vågen for det.'));
    await tester.pumpWidget(a3App(AegilScreen(api: api, repo: FakeAegilRepo())));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('aegil-ask')), 'xyz');
    await tester.ensureVisible(find.byKey(const Key('aegil-send')));
    await tester.tap(find.byKey(const Key('aegil-send')));
    await settle(tester);
    expect(find.text('Prøv et annet ord, eller bla selv.'), findsOneWidget);
  });

  testWidgets('Minne: groups, hard constraint, trust ledger, Glem alt', (tester) async {
    final repo = FakeAegilRepo();
    await tester.pumpWidget(a3App(MinneScreen(api: FakeAegilApi(), repo: repo)));
    await settle(tester);

    expect(find.text('DU LIKER'), findsOneWidget);
    expect(find.text('BUTIKKER'), findsOneWidget);
    expect(find.text('KOSTHOLD'), findsOneWidget);
    expect(find.text('Ingen nøtter'), findsOneWidget);
    expect(find.textContaining('Spart 312 kr'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('minne-glem')));
    await tester.tap(find.byKey(const Key('minne-glem')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Glem alt').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.calls, contains('forget'));
    await settle(tester);
    expect(find.byKey(const Key('minne-tom')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Brett: opens with the finds, Legg til adds', (tester) async {
    final api = FakeAegilApi();
    late BuildContext ctx;
    await tester.pumpWidget(a3App(Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    })));
    showAegilBrett(ctx, api: api);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('aegil-brett')), findsOneWidget);
    expect(find.text('Reker fra Torgboden'), findsOneWidget);
    expect(aegilFindCount(), 2);
  });

  testWidgets('aegilGreeting greets by first name and refreshAegilFindCount counts', (tester) async {
    await tester.pumpWidget(a3App(Scaffold(body: Builder(builder: aegilGreeting))));
    expect(find.textContaining('Hei, Kari!'), findsOneWidget);
    final n = await refreshAegilFindCount(api: FakeAegilApi());
    expect(n, 2);
    expect(aegilFindCount(), 2);
  });
}
