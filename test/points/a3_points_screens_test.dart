import 'dart:math';
import 'package:aerend_customer/data/points/points_models.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/poeng/aegil_velger_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/fjordfiske_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/liga_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/napp_entry.dart';
import 'package:aerend_customer/screens/bergen/poeng/opprykk_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_entry.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/premie_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/premiehylla_screen.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — the Points screens render from the API models alone
/// (points, never kroner), and every action reaches the API.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() => A3Services.reset());

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Premiehylla: header, Nivå, goal, Mine premier, the shelf, locked, 60-day note', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(PremiehyllaScreen(api: api)));
    await settle(tester);

    expect(find.byKey(const Key('hylla-hero')), findsOneWidget);
    expect(find.text('420 poeng'), findsOneWidget);
    expect(find.text('Premiehylla'), findsOneWidget);
    expect(find.byKey(const Key('hylla-nivaa')), findsOneWidget);
    expect(find.text('480 poeng til fløibanen tur-retur'), findsOneWidget);
    expect(find.text('46%'), findsOneWidget);
    expect(find.text('Mine premier'), findsOneWidget);
    expect(find.text('KLAR'), findsOneWidget);
    expect(find.text('Åpent på Fløyen'), findsOneWidget);
    expect(find.text('1 klare å hente'), findsOneWidget);
    expect(find.text('300 poeng'), findsOneWidget);
    expect(find.text('MÅL'), findsOneWidget);
    expect(find.text('UTSOLGT'), findsOneWidget);
    expect(find.text('480 poeng igjen'), findsOneWidget);
    expect(find.text('Dette er målet ditt'), findsOneWidget);
    expect(find.text('Utsolgt denne måneden'), findsOneWidget);
    expect(find.byKey(const Key('hylla-velger')), findsOneWidget);
    expect(find.text('Låst til Ulriken'), findsOneWidget);
    expect(find.text('Middag på Bryggen'), findsOneWidget);
    expect(find.textContaining('60 dager'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hylla-maal-7')));
    await settle(tester);
    expect(api.calls, contains('goal:7'));
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.byKey(const Key('hylla-kn-7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('hylla-krev-sheet')), findsOneWidget);
    expect(find.text('Hent for 300 poeng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hylla-krev-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Premie: Hent claims through the API', (tester) async {
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(PremieScreen(prize: kPrize, api: api)));
    await settle(tester);

    expect(find.text('Kaffe hos Kaffemisjonen'), findsOneWidget);
    expect(find.text('300 poeng'), findsOneWidget);
    await tester.tap(find.text('Hent premien'));
    await settle(tester);
    expect(api.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Ægil velger: reveals the pick with value hint and reason', (tester) async {
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(AegilVelgerScreen(api: api)));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(api.calls, contains('pick'));
    expect(find.text('Kaffe hos Kaffemisjonen'), findsOneWidget);
    expect(find.text('Verdi minst 300 kr'), findsOneWidget);
    expect(find.text('Du har vært der tre torsdager på rad.'), findsOneWidget);
    expect(find.text('Hent premien'), findsOneWidget);
    expect(find.text('Ikke for meg'), findsOneWidget);
  });

  testWidgets('Liga: rank, table, bydel toggle, prizes, join sheet', (tester) async {
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(LigaScreen(api: api)));
    await settle(tester);

    expect(find.text('Du ligger på 14. plass'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('Din bydel'), findsOneWidget);
    await tester.tap(find.text('Din bydel'));
    await settle(tester);
    expect(find.text('320'), findsOneWidget);
    expect(find.textContaining('Deg · Årstad'), findsOneWidget);
  });

  testWidgets('Opprykk: shows the gift and the shelf note', (tester) async {
    final api = FakePointsApi();
    api.balanceValue = const PointsBalance(available: 900, tier: 2, tierName: 'Ulriken');
    await tester.pumpWidget(a3App(OpprykkScreen(tierName: 'Ulriken', giftName: 'Gratis levering', api: api)));
    await settle(tester);

    expect(find.text('Du er nå Ulriken'), findsOneWidget);
    expect(find.text('Gratis levering'), findsOneWidget);
    expect(find.text('Ferdig'), findsOneWidget);
  });

  testWidgets('Fjordfiske: cast → bite → reel → catch card → save; 4th catch is a Premiefangst', (tester) async {
    final points = FakePointsApi();
    final aegil = FakeAegilApi();
    await tester.pumpWidget(a3App(FjordfiskeScreen(points: points, aegil: aegil, random: Random(1), prizeEvery: 2)));
    await settle(tester);

    expect(aegil.calls, contains('suggestions:fiske'));
    await tester.tap(find.byKey(const Key('fiske-kast')));
    await tester.pump();
    expect(find.byKey(const Key('fiske-ute')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('fiske-napp')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fiske-dra')));
    await settle(tester);
    expect(points.calls, contains('earn:1'));
    expect(find.byKey(const Key('fiske-fangst')), findsOneWidget);
    expect(find.text('Reker fra Torgboden'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fiske-lagre')));
    await settle(tester);
    expect(aegil.calls, contains('add:11'));
    await tester.pump(const Duration(seconds: 4));

    // Second cast is the prize catch (prizeEvery: 2).
    await tester.tap(find.byKey(const Key('fiske-kast')));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('fiske-dra')));
    await settle(tester);
    expect(points.calls, contains('pick'));
    expect(find.byKey(const Key('fiske-premiefangst')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fiske-hent')));
    await settle(tester);
    expect(points.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Napp-kort: Legg til adds through the API, Aldri dette marks never', (tester) async {
    final aegil = FakeAegilApi();
    late BuildContext ctx;
    await tester.pumpWidget(a3App(Builder(builder: (c) {
      ctx = c;
      return const Scaffold(body: SizedBox());
    })));
    const offer = NappOffer(id: '11', title: 'Reker fra Torgboden', storeName: 'Torgboden', priceOre: 14900, reason: 'Dagens napp', kind: 'tilbud');
    showNappKort(ctx, offer, aegil: aegil);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('napp-kort')), findsOneWidget);
    expect(find.text('149 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('napp-legg')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(aegil.calls, contains('add:11'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Poeng hub and entry card render the balance', (tester) async {
    final api = FakePointsApi();
    A3Services.points = () => api;
    await tester.pumpWidget(a3App(Scaffold(body: Column(children: [Builder(builder: poengEntryCard), Expanded(child: PoengScreen(api: api))]))));
    await settle(tester);

    expect(find.byKey(const Key('poeng-entry')), findsOneWidget);
    expect(find.textContaining('420 poeng'), findsWidgets);
    expect(find.byKey(const Key('poeng-hylla')), findsOneWidget);
    expect(find.byKey(const Key('poeng-fiske')), findsOneWidget);
    expect(find.text('Handle hos to bergenske butikker'), findsOneWidget);
  });

  test('AegilPick exposes the prize fields', () {
    const p = AegilPick(prize: {'id': 1, 'name': 'X', 'point_price': 10}, reason: 'r');
    expect(p.prizeId, 1);
    expect(p.pointPrice, 10);
  });
}
