import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_host.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_nivaa_card.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_screen.dart';

import '../a3/a3_fakes.dart';

/// agil-4 — the Meg tab to the 21des design: hero bubble, header, Gullbilletten,
/// the Poeng card with the four-rung ladder, the Meg-rader (Nivå, Fløyen-ligaen,
/// Ukens oppdrag with Godta, Gullbilletten) and the settings rows.
void main() {
  setUpAll(() => a3Bootstrap());
  setUp(() {
    A3Services.addressLine = () async => 'Nygårdsgaten 5';
    A3Services.paymentLine = () async => 'Visa •• 4471';
  });
  tearDown(() {
    A3Services.reset();
    setMensDuVarBorteForTest(const []);
  });

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(600, 3400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  const balance = PointsBalance(
    available: 1340,
    pending: 30,
    earned12m: 3600,
    lifetime: 3600,
    tier: 2,
    tierName: 'Gull',
    nextTierName: 'Platina',
    pointsToNextTier: 2400,
    tiers: [
      TierStep(index: 0, name: 'Bronse', threshold: 0),
      TierStep(index: 1, name: 'Sølv', threshold: 1000),
      TierStep(index: 2, name: 'Gull', threshold: 3000),
      TierStep(index: 3, name: 'Platina', threshold: 6000),
    ],
  );

  FakePointsApi api() => FakePointsApi(
        balanceValue: balance,
        shelfValue: const Premiehylla(prizes: [kPrize], goal: PointGoal(kind: 'prize', label: 'Gratis pizza fra Casa Maria', current: 1340, target: 1360, remaining: 20, percent: 99, prizeId: 7)),
        missionValue: const Mission(id: 1, title: 'Prøv Nordnes Fisk', body: 'Én bestilling', points: 50),
        leagueValue: const League(month: '2026-09', optedIn: false, participants: 120),
      );

  Widget app(FakePointsApi p, {FakeAegilApi? a}) => a3App(MegScreenBody(api: p, aegil: a ?? FakeAegilApi(), aegilRepo: FakeAegilRepo()));

  testWidgets('hero, header, Gullbilletten and the Poeng card render from the API', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    expect(find.byKey(const Key('meg-hero')), findsOneWidget);
    expect(find.text('20 poeng til gratis pizza fra casa maria.'), findsOneWidget);
    expect(find.text('Kari fra Møhlenpris'), findsOneWidget);
    expect(find.byKey(const Key('meg-gullbillett')), findsOneWidget);
    expect(find.text('Gi 200 · få 200 poeng'), findsOneWidget);

    expect(find.byKey(const Key('meg-nivaa-card')), findsOneWidget);
    expect(find.text('GULL'), findsOneWidget);
    expect(find.textContaining('2 400 poeng til Platina'), findsOneWidget);
    expect(find.byKey(const Key('meg-ladder')), findsOneWidget);
    for (final n in ['Bronse', 'Sølv', 'Gull', 'Platina']) {
      expect(find.text(n), findsWidgets, reason: n);
    }
    expect(find.text('1 340'), findsOneWidget);
    expect(find.text('Opptjent i alt: 3 600 poeng'), findsOneWidget);
    expect(find.text('+30 kommer når ordren er levert'), findsOneWidget);
    expect(find.textContaining('Mål: gratis pizza fra casa maria · 20 poeng igjen'), findsOneWidget);
    expect(find.text('99%'), findsOneWidget);
    expect(find.byKey(const Key('meg-open-premiehylla')), findsOneWidget);
  });

  testWidgets('Meg-rader: Nivå, Fløyen-ligaen (Bli med), Ukens oppdrag Godta, Gullbilletten code', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    expect(find.byKey(const Key('meg-rad-nivaa')), findsOneWidget);
    expect(find.text('2 400 til Platina'), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-liga')), findsOneWidget);
    expect(find.text('Bli med'), findsOneWidget);
    expect(find.text('UKENS OPPDRAG'), findsOneWidget);
    expect(find.text('Prøv Nordnes Fisk'), findsOneWidget);
    expect(find.text('+50 poeng'), findsOneWidget);
    expect(find.textContaining('KARI200'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('meg-godta')));
    await tester.tap(find.byKey(const Key('meg-godta')));
    await settle(tester);
    expect(p.calls, contains('accept'));
    expect(find.byKey(const Key('meg-oppdrag-status')), findsOneWidget);
    expect(find.text('0 av 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Ikke dette declines through the API', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('meg-ikke-dette')));
    await tester.tap(find.byKey(const Key('meg-ikke-dette')));
    await settle(tester);
    expect(p.calls, contains('decline'));
    expect(find.byKey(const Key('meg-rad-oppdrag')), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('settings rows: occasions, Ægil level, code toggle, address, payment, counts, name, language', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    expect(find.textContaining('Mamma · 14. mars · én påminnelse sju dager før'), findsOneWidget);
    expect(find.text('Handleliste · Middag denne uken · Ukens kurv'), findsOneWidget);
    expect(find.text('Nivå 2 · Varsle og foreslå'), findsOneWidget);
    expect(find.text('Nivå 4 →'), findsOneWidget);
    expect(find.text('Av · kreves over 300 kr'), findsOneWidget);
    expect(find.text('Nygårdsgaten 5 · bare for deg'), findsOneWidget);
    expect(find.text('Vipps · Visa •• 4471'), findsOneWidget);
    expect(find.text('Oppdrag, premier og verving'), findsOneWidget);
    expect(find.text('Ikke med i Fløyen-ligaen'), findsOneWidget);
    expect(find.text('Velg navn'), findsOneWidget);
    expect(find.text('Norsk bokmål'), findsOneWidget);
    expect(find.text('Nytt fra butikkene'), findsOneWidget);
    expect(find.text('Hjelp og kontakt'), findsOneWidget);
    // Varsler · 2 and Favoritter · 2 from prefs counts.
    expect(find.text('2'), findsNWidgets(2));

    // Krev alltid kode: Ark → Slå på → prefs.
    await tester.ensureVisible(find.byKey(const Key('meg-rad-kode')));
    await tester.tap(find.byKey(const Key('meg-rad-kode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Slå på'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(p.calls, contains('prefs:true:false'));
    expect(find.text('På · budet leverer bare til deg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Navn i ligaen: pick a name and visibility, opt in and save', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.tap(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-liga-navn-sheet')), findsOneWidget);
    expect(find.text('Kari'), findsOneWidget);
    expect(find.text('Kari K.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('liga-navn-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('liga-syn-bydel')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('liga-navn-lagre')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(p.calls, contains('optin:true'));
    expect(p.calls, contains('leaguename:Kari K.:bydel'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Anledninger: the sheet lists and removes', (tester) async {
    tall(tester);
    final p = api();
    final a = FakeAegilApi();
    await tester.pumpWidget(app(p, a: a));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('meg-rad-anledninger')));
    await tester.tap(find.byKey(const Key('meg-rad-anledninger')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-anledninger-sheet')), findsOneWidget);
    expect(find.byKey(const Key('anledning-1')), findsOneWidget);
    await tester.tap(find.text('Fjern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(a.calls, contains('occasion-remove:1'));
    expect(find.byKey(const Key('anledning-1')), findsNothing);
    expect(find.byKey(const Key('anledning-legg')), findsOneWidget);
  });

  testWidgets('MegScreen seam renders the rebuilt body; medals map tier names', (tester) async {
    tall(tester);
    A3Services.points = api;
    A3Services.aegil = () => FakeAegilApi();
    A3Services.aegilRepo = () => FakeAegilRepo();
    await tester.pumpWidget(a3App(const MegScreen()));
    await settle(tester);
    expect(find.byKey(const Key('meg-nivaa-card')), findsOneWidget);
    expect(medalFor('Platina').ink, medalFor('Ulriken').ink);
    expect(medalFor('Bronse').accent, isNot(medalFor('Gull').accent));
  });

  testWidgets('the borte card still mounts under the header', (tester) async {
    tall(tester);
    setMensDuVarBorteForTest(const [AwayItem(id: 1, text: 'La reker i kurven', action: 'basket.add')]);
    await tester.pumpWidget(app(api()));
    await settle(tester);
    expect(find.byKey(const Key('borte-card')), findsOneWidget);
  });

  testWidgets('renders at phone width without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setMensDuVarBorteForTest(const [AwayItem(id: 1, text: 'La reker i kurven', action: 'basket.add', undoable: true)]);
    await tester.pumpWidget(app(api()));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('meg-innstillinger-rader')), findsOneWidget);
  });

  testWidgets('Gullbilletten sheet: code, board, ladder step, friend tickets, Vilkår', (tester) async {
    tall(tester);
    final p = api();
    p.referralValue = const Referral(
      code: 'DIDRIK-BGO',
      link: 'https://aerend.no/verv/DIDRIK-BGO',
      qualifiedTotal: 3,
      pointsEarned: 700,
      ladder: [VervStep(at: 3, name: 'Bronsebillett', bonus: 100), VervStep(at: 10, name: 'Sølvbillett', bonus: 500)],
      friends: [VervFriend(name: 'Kari', status: 'delivered'), VervFriend(name: 'Ola', status: 'downloaded')],
    );
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.tap(find.byKey(const Key('meg-gullbillett')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('meg-billett-sheet')), findsOneWidget);
    expect(find.text('Gullbilletten din'), findsOneWidget);
    expect(find.text('DIN DELINGSKODE'), findsOneWidget);
    expect(find.text('DIDRIK-BGO'), findsOneWidget);
    expect(find.text('BILLETTENE DINE'), findsOneWidget);
    expect(find.byKey(const Key('meg-billett-antall')), findsOneWidget);
    expect(find.text('700 poeng hentet inn · 200 for hver ny'), findsOneWidget);
    expect(find.text('BRONSEBILLETT NÅDD'), findsOneWidget);
    expect(find.text('Sølvbillett ved 10 vervede · +500 bonus'), findsOneWidget);
    expect(find.text('7 igjen'), findsOneWidget);
    expect(find.text('Neste venn'), findsOneWidget);
    expect(find.text('Kari'), findsWidgets);
    expect(find.text('Ola'), findsOneWidget);
    expect(find.text('Lastet ned'), findsOneWidget);
    expect(find.text('Del gullbilletten'), findsOneWidget);

    await tester.tap(find.byKey(const Key('meg-billett-vilkaar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-vilkaar-sheet')), findsOneWidget);
    expect(find.text('Vilkår for poeng'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Nivå sheet: medal ladder with thresholds and NÅ, the detail card and the prizes that open', (tester) async {
    tall(tester);
    final p = api();
    p.shelfValue = const Premiehylla(
      prizes: [kPrize],
      previews: [
        PrizePreview(id: 1, name: 'Din egen båt i Vågen', pointPrice: 2500, tierName: 'Platina', pointsToUnlock: 2400),
        PrizePreview(id: 2, name: 'Middag for to på Bryggen', pointPrice: 2200, tierName: 'Platina', pointsToUnlock: 2400),
        PrizePreview(id: 3, name: 'Fløybanen for to', pointPrice: 2000, tierName: 'Platina', pointsToUnlock: 2400),
      ],
    );
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.tap(find.byKey(const Key('meg-nivaa-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('meg-nivaa-sheet')), findsOneWidget);
    expect(find.text('Du er på Gull.'), findsOneWidget);
    expect(find.byKey(const Key('meg-medal-ladder')), findsOneWidget);
    expect(find.text('1 000'), findsOneWidget);
    expect(find.text('3 000'), findsOneWidget);
    expect(find.text('6 000'), findsOneWidget);
    expect(find.text('NÅ'), findsOneWidget);
    expect(find.text('poeng til Platina'), findsOneWidget);
    expect(find.text('Opptjent siste 12 måneder: 3 600'), findsOneWidget);
    expect(find.text('Da åpner disse på hylla di:'), findsOneWidget);
    expect(find.text('Din egen båt i Vågen'), findsOneWidget);
    expect(find.text('Middag for to på Bryggen'), findsOneWidget);
    expect(find.text('Fløybanen for to'), findsOneWidget);
    expect(find.text('Nivået påvirkes aldri av at du bruker poeng.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Adresser, Betaling and Språk open as sheets', (tester) async {
    tall(tester);
    A3Services.addresses = () async => ['Nygårdsgaten 5', 'Strandkaien 2'];
    A3Services.cards = () async => ['Visa •• 4471'];
    await tester.pumpWidget(app(api()));
    await settle(tester);

    Future<void> open(String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> close() async {
      await tester.tap(find.byKey(const Key('meg-ark-lukk')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await open('meg-rad-adresser');
    expect(find.byKey(const Key('meg-adresser-sheet')), findsOneWidget);
    expect(find.text('Strandkaien 2'), findsOneWidget);
    expect(find.byKey(const Key('adresser-legg')), findsOneWidget);
    await close();

    await open('meg-rad-betaling');
    expect(find.byKey(const Key('meg-betaling-sheet')), findsOneWidget);
    expect(find.text('Reserve'), findsOneWidget);
    await close();

    await open('meg-rad-spraak');
    expect(find.byKey(const Key('meg-spraak-sheet')), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await close();
  });
}
