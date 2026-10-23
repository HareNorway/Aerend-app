import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/poeng_feil.dart';
import 'package:aerend_customer/screens/bergen/poeng/premiehylla_screen.dart';

import '../a3/a3_fakes.dart';

/// Customer plan Step 12 in the app: Meg's Ukens oppdrag row calls accept /
/// decline (the design's `oppdragGodta` / `oppdragNei`), the month's summary
/// row and its sheet (hidden without data), a claim's «Angre» inside its
/// window (`DELETE points/claims/{id}`), and the named 422s in words.
void main() {
  setUpAll(() => a3Bootstrap());
  setUp(() {
    A3Services.addressLine = () async => 'Nygårdsgaten 5';
    A3Services.rules = () async => null;
    A3Services.addressList = () async => const [];
    A3Services.paymentLine = () async => 'Visa •• 4471';
  });
  tearDown(() {
    A3Services.reset();
    setMensDuVarBorteForTest(const []);
  });

  void tall(WidgetTester t, {double h = 4200}) {
    t.view.physicalSize = Size(390, h);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  Future<void> apnePoeng(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const Key('meg-poeng-knapp')));
    await t.tap(find.byKey(const Key('meg-poeng-knapp')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
  }

  const balance = PointsBalance(available: 4343, pending: 0, earned12m: 4843, lifetime: 4843, tier: 2, tierName: 'Gull', nextTierName: 'Platina', pointsToNextTier: 1157);
  const mission = Mission(id: 1, title: 'Prøv Nordnes Fisk', body: 'Én bestilling teller.', points: 50);

  FakePointsApi api({Mission? m = mission}) => FakePointsApi(balanceValue: balance, missionValue: m, leagueValue: const League(month: '2026-10', optedIn: false, participants: 9))..missionNone = m == null;

  Widget app(FakePointsApi p, {FakeAegilApi? a}) => a3App(MegScreenBody(api: p, aegil: a ?? FakeAegilApi(), aegilRepo: FakeAegilRepo()));

  test('CusPoengFeil: every named code has a line; unknown codes fall back', () {
    for (final code in CusPoengFeil.koder) {
      expect(CusPoengFeil.tekst(code, ellers: 'x'), isNot('x'), reason: code);
      expect(CusPoengFeil.kjent(code), isTrue);
    }
    expect(CusPoengFeil.tekst('PRIZE_TIER_LOCKED', ellers: 'x'), contains('høyere nivå'));
    expect(CusPoengFeil.tekst('MISSION_DECLINE_LIMIT', ellers: 'x'), contains('Ett nei i uka'));
    expect(CusPoengFeil.tekst('CLAIM_CANCEL_WINDOW_CLOSED', ellers: 'x'), contains('Fristen'));
    expect(CusPoengFeil.tekst('Error occured while Communication with Server with StatusCode : 422', ellers: 'x'), 'x');
    expect(CusPoengFeil.tekst(null, ellers: 'x'), 'x');
    expect(CusPoengFeil.kjent(null), isFalse);
  });

  test('MonthlySummary: parsed from the endpoint, empty months hide', () {
    final s = MonthlySummary.fromJson({'month': '2026-10', 'earned': 4833, 'spent': 500, 'expired': 0, 'trust': {'saved_kr': 12}, 'actions': 3});
    expect(s.earned, 4833);
    expect(s.spent, 500);
    expect(s.savedKr, 12);
    expect(s.actions, 3);
    expect(s.tom, isFalse);
    expect(const MonthlySummary(month: '2026-10').tom, isTrue);
    expect(A4MegCopy.cus_meg_maaned('2026-10'), 'Oktober');
    expect(A4MegCopy.cus_meg_oppsummering_under(4833, 500, 12), '+4 833 opptjent · 500 brukt · Ægil sparte deg 12 kr');
  });

  testWidgets('Meg: a new mission shows Godta / Ikke dette; Godta accepts and the row turns «0 av 1»', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);
    await apnePoeng(tester);

    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsOneWidget);
    expect(find.text('Prøv Nordnes Fisk · +50 poeng'), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-oppdrag-godta-rad')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('cus-meg-oppdrag-godta-rad')));
    await tester.tap(find.byKey(const Key('cus-meg-oppdrag-godta-rad')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(p.calls, contains('accept'));
    expect(find.text(A4MegCopy.a4_meg_oppdrag_ditt('Prøv Nordnes Fisk')), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-oppdrag-godta-rad')), findsNothing);
    expect(find.text('0 av 1'), findsOneWidget);
  });

  testWidgets('Meg: the sheet\'s Ikke dette declines (no replacement → the row goes, «Greit · nytt oppdrag neste uke»); a second decline says MISSION_DECLINE_LIMIT in words', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);
    await apnePoeng(tester);

    await tester.ensureVisible(find.byKey(const Key('cus-meg-rad-oppdrag')));
    await tester.tap(find.text('Prøv Nordnes Fisk · +50 poeng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-meg-oppdrag-ark')), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-oppdrag-godta')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-meg-oppdrag-nei')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(p.calls, contains('decline'));
    expect(find.text(A4MegCopy.a4_meg_oppdrag_nei), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsNothing);

    // The sheet's «Ikke dette» on a fresh screen whose backend refuses.
    final p2 = api()..feilKode = 'MISSION_DECLINE_LIMIT';
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(p2));
    await settle(tester);
    await apnePoeng(tester);
    await tester.ensureVisible(find.byKey(const Key('cus-meg-rad-oppdrag')));
    await tester.tap(find.text('Prøv Nordnes Fisk · +50 poeng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-meg-oppdrag-ark')), findsOneWidget);
    expect(find.text('+50 poeng når ordren er levert'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-meg-oppdrag-nei')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(p2.calls, contains('decline'));
    expect(find.textContaining('Ett nei i uka'), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsOneWidget);
  });

  testWidgets('Meg: no mission → no row; a completed one shows «+50 poeng»', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(api(m: null)));
    await settle(tester);
    await apnePoeng(tester);
    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(api(m: const Mission(id: 1, title: 'Prøv Nordnes Fisk', body: '', points: 50, state: 'completed', progress: 1, accepted: true))));
    await settle(tester);
    await apnePoeng(tester);
    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-oppdrag-godta-rad')), findsNothing);
    expect(find.text('+50 poeng'), findsWidgets);
  });

  testWidgets('Meg: the month summary row is hidden without data, and opens the sheet with the rows that have data', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(api(), a: FakeAegilApi()..summaryValue = const MonthlySummary(month: '2026-10')));
    await settle(tester);
    await apnePoeng(tester);
    expect(find.byKey(const Key('cus-meg-rad-oppsummering')), findsNothing);

    final a = FakeAegilApi()..summaryValue = const MonthlySummary(month: '2026-10', earned: 4833, spent: 500, savedKr: 12, actions: 3);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(api(), a: a));
    await settle(tester);
    await apnePoeng(tester);
    await tester.ensureVisible(find.byKey(const Key('cus-meg-rad-oppsummering')));
    expect(find.text('Oktober i poeng'), findsOneWidget);
    expect(find.text('+4 833 opptjent · 500 brukt · Ægil sparte deg 12 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-meg-rad-oppsummering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-meg-oppsummering-ark')), findsOneWidget);
    expect(find.byKey(const Key('cus-opps-opptjent')), findsOneWidget);
    expect(find.text('4 833 poeng'), findsOneWidget);
    expect(find.byKey(const Key('cus-opps-utlopt')), findsNothing);
    expect(find.byKey(const Key('cus-opps-nivaa')), findsOneWidget);
    expect(find.text('Gull · 1 157 til Platina'), findsOneWidget);
    expect(find.byKey(const Key('cus-opps-liga')), findsOneWidget);
    expect(find.text(A4MegCopy.cus_meg_opps_liga_ute), findsOneWidget);
    expect(find.byKey(const Key('cus-opps-oppdrag')), findsNothing);
    expect(find.text('12 kr · 3 handlinger fra Ægil'), findsOneWidget);
  });

  testWidgets('Premiehylla: a cancellable claim offers «Angre premien»; it calls DELETE and the points come back; a closed window says so', (tester) async {
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deadline = DateTime.now().add(const Duration(hours: 20));
    final p = FakePointsApi(balanceValue: balance)
      ..claimsValue = [
        PrizeClaim(id: 2, prizeId: 4, prizeName: 'Kaffe hos Kaffemisjonen', state: 'claimed', pointsSpent: 500, cancellable: true, cancelDeadlineAt: deadline),
        const PrizeClaim(id: 1, prizeId: 3, prizeName: 'Gratis levering', state: 'claimed', pointsSpent: 0),
      ];
    await tester.pumpWidget(a3App(PremiehyllaScreen(api: p)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 2));

    await tester.ensureVisible(find.byKey(const Key('cus-hylla-claim-2')));
    await tester.tap(find.byKey(const Key('cus-hylla-claim-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-hylla-angre-rad')), findsOneWidget);
    expect(find.textContaining('Poengene kommer tilbake · til kl'), findsOneWidget);
    expect(find.byKey(const Key('cus-hylla-angre-cta')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cus-hylla-angre-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(p.calls, contains('cancel:2'));
    expect(find.text(A4MegCopy.cus_hylla_angret(500)), findsOneWidget);
    expect(find.byKey(const Key('cus-hylla-angre-cta')), findsNothing);

    // The claim without a window has no Angre.
    await tester.pump(const Duration(seconds: 3));
    await tester.ensureVisible(find.byKey(const Key('cus-hylla-claim-1')));
    await tester.tap(find.byKey(const Key('cus-hylla-claim-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('cus-hylla-angre-cta')), findsNothing);
    await tester.tapAt(const Offset(195, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // The backend refuses: the code in words, the sheet stays.
    p.feilKode = 'CLAIM_CANCEL_WINDOW_CLOSED';
    await tester.ensureVisible(find.byKey(const Key('cus-hylla-claim-2')));
    await tester.tap(find.byKey(const Key('cus-hylla-claim-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('cus-hylla-angre-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('Fristen for å angre har gått ut'), findsOneWidget);
    expect(find.byKey(const Key('cus-hylla-angre-cta')), findsOneWidget);
  });
}
