import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_billett.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_host.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_nivaa_card.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_screen.dart';

import 'package:aerend_customer/utils/shared_pref_utill.dart';
import '../a3/a3_fakes.dart';

/// agil-4 — the Meg tab to the 21des design: hero bubble, header, Gullbilletten,
/// the Poeng card with the four-rung ladder, the Meg-rader (Nivå, Bergen-ligaen,
/// Ukens oppdrag with Godta, Gullbilletten) and the settings rows.
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

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(390, 4200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  /// New Bergen: the Poeng card and the Nivå / Liga / Gullbillett rows sit
  /// inside «Poeng, nivå og konkurranser»; open it.
  Future<void> apnePoeng(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const Key('meg-poeng-knapp')));
    await t.tap(find.byKey(const Key('meg-poeng-knapp')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
  }

  final balance = PointsBalance(
    available: 1340,
    pending: 30,
    earned12m: 3600,
    lifetime: 3600,
    tier: 2,
    tierName: 'Gull',
    nextTierName: 'Platina',
    pointsToNextTier: 2400,
    reviewAt: DateTime(2027, 3, 14),
    keepGap: 400,
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

  testWidgets('Innstillinger for Ægil: the dark Ark lists the levels and saves a choice (Bergen Step 5+7)', (tester) async {
    tall(tester);
    final repo = FakeAegilRepo();
    await tester.pumpWidget(a3App(MegScreenBody(api: api(), aegil: FakeAegilApi(), aegilRepo: repo)));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('meg-rad-aegil')));
    await tester.tap(find.byKey(const Key('meg-rad-aegil')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-ark-aegil-innst')), findsOneWidget);
    expect(find.text('Kommer snart'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ae-innst-nivaa-3')));
    await tester.tap(find.byKey(const Key('ae-innst-nivaa-3')));
    await settle(tester);
    expect(repo.calls.any((c) => c.contains('level: 3')), isTrue);
    await tester.tap(find.byKey(const Key('meg-ark-aegil-ferdig')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('meg-ark-aegil-innst')), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

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
    // New Bergen: «POENG, NIVÅ OG KONKURRANSER» opens to the Poeng card.
    expect(find.text('POENG, NIVÅ OG KONKURRANSER'), findsOneWidget);
    expect(find.byKey(const Key('meg-nivaa-card')), findsNothing);
    await apnePoeng(tester);

    expect(find.byKey(const Key('meg-nivaa-card')), findsOneWidget);
    expect(find.text('GULL'), findsOneWidget);
    expect(find.textContaining('2 400 poeng til Platina'), findsOneWidget);
    expect(find.byKey(const Key('meg-ladder')), findsOneWidget);
    for (final n in ['Bronse', 'Sølv', 'Gull', 'Platina']) {
      expect(find.text(n), findsWidgets, reason: n);
    }
    expect(find.text('1 340'), findsWidgets);
    expect(find.text('Opptjent i alt: 3 600 poeng'), findsOneWidget);
    expect(find.text('+30 kommer når ordren er levert'), findsOneWidget);
    expect(find.textContaining('Mål: gratis pizza fra casa maria · 20 poeng igjen'), findsOneWidget);
    expect(find.text('99%'), findsOneWidget);
    expect(find.byKey(const Key('meg-open-premiehylla')), findsOneWidget);
  });

  testWidgets('Meg-rader: Nivå, Bergen-ligaen (Bli med), Gullbilletten code', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);
    await apnePoeng(tester);

    expect(find.byKey(const Key('meg-rad-nivaa')), findsOneWidget);
    expect(find.text('2 400 til Platina'), findsWidgets);
    expect(find.byKey(const Key('meg-rad-liga')), findsOneWidget);
    expect(find.text('Bli med'), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-gullbillett')), findsOneWidget);
    expect(find.textContaining('KARI200'), findsWidgets);
    // The design's Poeng panel has Nivå, Liga and Gullbilletten only: no Ukens oppdrag row (2026-10-23).
    expect(find.byKey(const Key('cus-meg-rad-oppdrag')), findsNothing);
  });

  testWidgets('settings rows as in the design: Ægil level, address, counts, name, language; Konto kept; Flere innstillinger hidden', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    expect(find.text('Nivå 2 · Varsle og foreslå'), findsOneWidget);
    // New Bergen: «Innstillinger for Ægil · Nivå 2 · Varsle og foreslå · Endre».
    expect(find.text('Innstillinger for Ægil'), findsOneWidget);
    expect(find.text('Nygårdsgaten 5 · bare for deg'), findsOneWidget);
    expect(find.text('Oppdrag, premier og verving'), findsOneWidget);
    expect(find.text('Ikke med i Bergen-ligaen'), findsOneWidget);
    expect(find.text('Velg navn'), findsOneWidget);
    expect(find.text('Norsk bokmål'), findsOneWidget);
    expect(find.text('Nytt fra butikkene'), findsOneWidget);
    expect(find.text('Hjelp og kontakt'), findsOneWidget);
    // Varsler · 2 and Favoritter · 2 from prefs counts.
    expect(find.text('2'), findsNWidgets(2));
    // Konto stays (account deletion); «Ægil sparte deg» is gone (the design's live list has no such row).
    expect(find.byKey(const Key('meg-rad-konto')), findsOneWidget);
    expect(find.byKey(const Key('cus-meg-rad-tillit')), findsNothing);

    // «Flere innstillinger» is hidden (kMegFlereInnstillinger, SAVED-FOR-LATER.md).
    for (final k in ['meg-d2-rader', 'meg-rad-anledninger', 'cus-meg-rad-paaminnelser', 'meg-rad-ukeshandel', 'meg-rad-kode', 'meg-rad-dora', 'meg-rad-betaling']) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
  });

  testWidgets('Husk døra mi: off until the customer says yes, saved on the server (UI-TEMP #25 gone)', skip: !kMegFlereInnstillinger, (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('meg-rad-dora')));
    expect(find.text('Husk døra mi'), findsOneWidget);
    expect(find.text('Av · ingen notater om døra di'), findsOneWidget);

    await tester.tap(find.byKey(const Key('meg-rad-dora')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(p.calls, contains('prefs:door:true'));
    expect(find.text('På · budet ser notatet om døra di'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Navn i ligaen: write a name, pick who sees it, opt in and save', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.tap(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-liga-navn-sheet')), findsOneWidget);
    // New Bergen: no «Bare min bydel» any more.
    expect(find.byKey(const Key('liga-syn-bydel')), findsNothing);
    // Nothing to save before a name is written.
    expect(find.text(A4MegCopy.a4_meg_liga_skriv_forst), findsOneWidget);
    await tester.enterText(find.byKey(const Key('liga-navn-felt')), 'Kari K.');
    await tester.pump();
    expect(find.text('7/20'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('liga-navn-forhaand'))).data, 'Kari K.');
    expect(find.text(A4MegCopy.a4_meg_liga_bli_som('Kari K.')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('liga-syn-skjult')));
    await tester.tap(find.byKey(const Key('liga-syn-skjult')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('liga-navn-lagre')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(p.calls, contains('optin:true'));
    expect(p.calls, contains('leaguename:Kari K.:skjult'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Navn i ligaen: «Vær anonym» joins without a name, hidden', (tester) async {
    tall(tester);
    final p = api();
    await tester.pumpWidget(app(p));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.tap(find.byKey(const Key('meg-rad-navn-liga')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('liga-anonym')));
    await tester.pump();
    expect(find.textContaining('Du er anonym · vises som Klatrer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('liga-navn-lagre')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(p.calls, contains('optin:true'));
    expect(p.calls, contains('leaguename:null:skjult'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Anledninger: the sheet lists and removes', skip: !kMegFlereInnstillinger, (tester) async {
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
    await apnePoeng(tester);
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

  testWidgets('Gullbilletten sheet (dark): code ticket, board with the cap, friend tickets, Vilkår', (tester) async {
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
    // The code is on the Meg ticket and on the sheet's ticket.
    expect(find.text('DIDRIK-BGO'), findsNWidgets(2));
    expect(find.text('BILLETTENE DINE'), findsOneWidget);
    expect(find.byKey(const Key('meg-billett-antall')), findsOneWidget);
    expect(find.text('700 poeng hentet inn · 200 for hver ny'), findsOneWidget);
    // D5: the real monthly cap, not «Ingen grense».
    expect(find.text('0 av 5 denne måneden'), findsOneWidget);
    expect(find.text('Ingen grense'), findsNothing);
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

  group('sharing the gullbillett (new Bergen gbDel)', () {
    final shares = <String>[];
    Rect? anker;
    setUp(() async {
      shares.clear();
      anker = null;
      await prefSetString(GbSendt.prefKey, '');
    });
    DateTime? klipp;
    setUp(() {
      klipp = null;
      GbDeling.klippTid = () async => klipp;
    });
    tearDown(() => GbDeling.share = (text, {subject, origin}) => Share.share(text, subject: subject, sharePositionOrigin: origin));

    void svar(ShareResultStatus s) => GbDeling.share = (text, {subject, origin}) async {
          shares.add(text);
          anker = origin;
          return ShareResult('x', s);
        };

    Future<void> delFraArket(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('meg-gullbillett')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const Key('meg-billett-del')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('Del gullbilletten: the sheet closes, the share goes out anchored, «Gullbillett delt» plays; the board then has «Ny venn · Akkurat nå»', (tester) async {
      tall(tester);
      svar(ShareResultStatus.success);
      final p = api()..referralValue = const Referral(code: 'DIDRIK-BGO', link: 'https://aerend.no/verv/DIDRIK-BGO', friends: [VervFriend(name: 'Kari', status: 'delivered')]);
      await tester.pumpWidget(app(p));
      await settle(tester);
      await delFraArket(tester);

      expect(shares.single, contains('DIDRIK-BGO'));
      expect(anker, isNotNull, reason: 'iOS 26 refuses a share sheet without an anchor');
      expect(find.byKey(const Key('meg-billett-sheet')), findsNothing);
      expect(find.byType(GbDelt), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('LENKEN ER SENDT'), findsOneWidget);
      expect(GbSendt.les(), hasLength(1));

      await tester.tap(find.text('Ferdig'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GbDelt), findsNothing);

      await tester.tap(find.byKey(const Key('meg-gullbillett')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.byKey(const Key('meg-billett-ny')), findsOneWidget);
      expect(find.text('Ny venn'), findsOneWidget);
      expect(find.text('Akkurat nå'), findsOneWidget);
      expect(find.text('Kari'), findsWidgets);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('«Del med flere» shares again and plays again; the earlier ticket reads «Billett sendt»', (tester) async {
      tall(tester);
      svar(ShareResultStatus.success);
      final p = api()..referralValue = const Referral(code: 'KARI200');
      await tester.pumpWidget(app(p));
      await settle(tester);
      // The Meg ticket's stub shares straight away.
      await tester.tap(find.byKey(const Key('meg-del')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GbDelt), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('Del med flere'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(shares, hasLength(2));
      expect(find.byType(GbDelt), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(GbSendt.les(), hasLength(2));
    });

    testWidgets('backing out of the share sheet shows nothing and keeps no ticket', (tester) async {
      tall(tester);
      svar(ShareResultStatus.dismissed);
      await tester.pumpWidget(app(api()..referralValue = const Referral(code: 'KARI200')));
      await settle(tester);
      await delFraArket(tester);
      expect(shares, hasLength(1));
      expect(find.byType(GbDelt), findsNothing);
      expect(GbSendt.les(), isEmpty);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('«Copy» in the share sheet (Android says dismissed, the clipboard was just set): «Gullbillett delt» with «LENKEN ER KOPIERT»', (tester) async {
      tall(tester);
      GbDeling.share = (text, {subject, origin}) async {
        shares.add(text);
        klipp = DateTime.now();
        return const ShareResult('', ShareResultStatus.dismissed);
      };
      await tester.pumpWidget(app(api()..referralValue = const Referral(code: 'KARI200')));
      await settle(tester);
      await delFraArket(tester);
      expect(find.byType(GbDelt), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('LENKEN ER KOPIERT'), findsOneWidget);
      expect(find.text('LENKEN ER SENDT'), findsNothing);
      expect(GbSendt.les(), hasLength(1));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('backing out with an older clipboard (set before the sheet opened) still shows nothing', (tester) async {
      tall(tester);
      klipp = DateTime.now().subtract(const Duration(minutes: 5));
      svar(ShareResultStatus.dismissed);
      await tester.pumpWidget(app(api()..referralValue = const Referral(code: 'KARI200')));
      await settle(tester);
      await delFraArket(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GbDelt), findsNothing);
      expect(GbSendt.les(), isEmpty);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a platform that cannot tell (unavailable) counts as sent', (tester) async {
      tall(tester);
      svar(ShareResultStatus.unavailable);
      await tester.pumpWidget(app(api()..referralValue = const Referral(code: 'KARI200')));
      await settle(tester);
      await delFraArket(tester);
      expect(find.byType(GbDelt), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a share sheet that fails copies the code instead', (tester) async {
      tall(tester);
      GbDeling.share = (text, {subject, origin}) async => throw PlatformException(code: 'no-anchor');
      String? kopi;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') kopi = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(app(api()..referralValue = const Referral(code: 'KARI200', link: 'https://aerend.no/verv/KARI200')));
      await settle(tester);
      await delFraArket(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GbDelt), findsNothing);
      expect(find.text(A4MegCopy.a4_meg_kopiert('KARI200')), findsOneWidget);
      expect(kopi, 'https://aerend.no/verv/KARI200');
      expect(GbSendt.les(), isEmpty);
      await tester.pump(const Duration(seconds: 6));
    });

    test('GbSendt keeps 30 days and ten tickets, newest first; «Akkurat nå» is ten minutes', () async {
      final naa = DateTime(2026, 11, 14, 12);
      await prefSetString(GbSendt.prefKey, '${naa.subtract(const Duration(days: 31)).millisecondsSinceEpoch}');
      expect(GbSendt.les(naa: naa), isEmpty);
      for (var i = 12; i >= 0; i--) {
        await GbSendt.legg(naa: naa.subtract(Duration(minutes: i * 5)));
      }
      final l = GbSendt.les(naa: naa);
      expect(l, hasLength(10));
      expect(l.first, naa);
      expect(GbSendt.erNy(l.first, naa: naa), isTrue);
      expect(GbSendt.erNy(naa.subtract(const Duration(minutes: 11)), naa: naa), isFalse);
    });
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
    await apnePoeng(tester);

    await tester.ensureVisible(find.byKey(const Key('meg-nivaa-open')));
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
    expect(find.text('Neste vurdering 14. mars · du er 400 poeng unna å bli på Gull.'), findsOneWidget);
    expect(find.text('Nivået påvirkes aldri av at du bruker poeng.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the Meg ticket and the Gullbilletten row open the Gullbilletten sheet', (tester) async {
    tall(tester);
    final p = api()..referralValue = const Referral(code: 'KARI200', ladder: [VervStep(at: 3, name: 'Bronsebillett', bonus: 100)]);
    await tester.pumpWidget(app(p));
    await settle(tester);
    await tester.tap(find.byKey(const Key('meg-gullbillett')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-billett-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('meg-ark-lukk')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await apnePoeng(tester);
    await tester.ensureVisible(find.byKey(const Key('meg-del-2')));
    await tester.tap(find.byKey(const Key('meg-del-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('meg-billett-sheet')), findsOneWidget);
    expect(find.byKey(const Key('meg-billett-board')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Logg ut asks first; Avbryt keeps you in (Bergen Step 8)', (tester) async {
    // 03 test pass (CUS-B10 b): «Logg ut» shows only for a logged-in customer.
    await a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefUserName: 'Kari Nordmann', prefUserVerified: 1});
    tall(tester);
    await tester.pumpWidget(app(api()));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('meg-logg-ut')));
    await tester.tap(find.byKey(const Key('meg-logg-ut')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Logge ut?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('meg-logg-ut-avbryt')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Logge ut?'), findsNothing);
    expect(find.byKey(const Key('meg-logg-ut')), findsOneWidget);
    // The D2 group is hidden (SAVED-FOR-LATER.md).
    expect(find.text('FLERE INNSTILLINGER'), findsNothing);
    expect(find.byKey(const Key('meg-d2-rader')), findsNothing);
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets('Adresser and Språk open as sheets (Betaling with Flere innstillinger)', (tester) async {
    tall(tester);
    A3Services.addresses = () async => ['Nygårdsgaten 5', 'Strandkaien 2'];
    A3Services.addressList = () async => [
      AddressListItem.fromJson({'address_id': 1, 'type': 'home', 'address': 'Nygårdsgaten 5, 5015 Bergen', 'flat_no': '3. etasje'}),
      AddressListItem.fromJson({'address_id': 2, 'type': 'work', 'address': 'Strandkaien 2, 5013 Bergen'}),
    ];
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

    if (kMegFlereInnstillinger) {
      await open('meg-rad-betaling');
      expect(find.byKey(const Key('meg-betaling-sheet')), findsOneWidget);
      expect(find.text('Reserve'), findsOneWidget);
      await close();
    }

    await open('meg-rad-spraak');
    expect(find.byKey(const Key('meg-spraak-sheet')), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await close();
  });
}
