import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/bestillinger_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/favoritter_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/konto_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_host.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/varsler_panel.dart';
import 'package:aerend_customer/screens/common/notifications/notifications_dl.dart';

import '../a3/a3_fakes.dart';

/// AGIL-3-PLAN Phase 7 — Meg: the header, Gullbilletten, the Poeng card, the
/// rows, "Slik får du poeng", Konto's switches, Varsler's filters and swipe.
void main() {
  setUpAll(() => a3Bootstrap());
  tearDown(() {
    A3Services.reset();
    setMensDuVarBorteForTest(const []);
  });

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Meg: header, Gullbilletten, Poeng card, rows, Slik får du poeng, borte card', (tester) async {
    setMensDuVarBorteForTest(const [AwayItem(id: 1, text: 'La reker i kurven', action: 'basket.add', undoable: true), AwayItem(id: 2, text: 'Sa fra om billigere melk', action: 'against_interest')]);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(MegScreenBody(api: api)));
    await settle(tester);

    expect(find.text('Kari fra Bergenhus'), findsOneWidget);
    expect(find.byKey(const Key('meg-gullbillett')), findsOneWidget);
    expect(find.textContaining('KARI200'), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-nivaa')), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-liga')), findsOneWidget);
    expect(find.text('14. plass'), findsOneWidget);
    expect(find.text('UKENS OPPDRAG'), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-favoritter')), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-konto')), findsOneWidget);
    expect(find.byKey(const Key('meg-rad-bestillinger')), findsOneWidget);
    expect(find.text('1 poeng per 10 kr du handler'), findsOneWidget);
    expect(find.text('Nivået påvirkes aldri av at du bruker poeng'), findsWidgets);
    expect(find.byKey(const Key('borte-card')), findsOneWidget);
    expect(find.text('2 ting fra Ægil'), findsOneWidget);
  });

  testWidgets('MegScreen seam renders the Meg body', (tester) async {
    A3Services.points = () => FakePointsApi();
    A3Services.aegil = () => FakeAegilApi();
    await tester.pumpWidget(a3App(const MegScreen()));
    await settle(tester);
    expect(find.byKey(const Key('meg-gullbillett')), findsOneWidget);
  });

  testWidgets('Konto: rows and the reduced-motion switch', (tester) async {
    await tester.pumpWidget(a3App(const KontoScreen()));
    await settle(tester);

    expect(find.text('Kari Nordmann'), findsOneWidget);
    expect(find.byKey(const Key('konto-adresser')), findsOneWidget);
    expect(find.byKey(const Key('konto-betaling')), findsOneWidget);
    expect(find.byKey(const Key('konto-logg-ut')), findsOneWidget);
    expect(A3Services.reducedMotion.value, isFalse);
    await tester.ensureVisible(find.byKey(const Key('konto-rolig-switch')));
    await tester.tap(find.byKey(const Key('konto-rolig-switch')));
    await settle(tester);
    expect(A3Services.reducedMotion.value, isTrue);
  });

  testWidgets('Varsler: filters, rows, swipe-to-remove with Angre, empty state', (tester) async {
    final items = [
      MassNotificationItem(id: 1, title: 'Bestillingen er på vei', message: 'Krysser Vågen nå', datetime: '2026-09-25'),
      MassNotificationItem(id: 2, title: 'Tilbud hos Torgboden', message: '20 % på reker', datetime: '2026-09-25'),
    ];
    await tester.pumpWidget(a3App(Scaffold(body: SingleChildScrollView(child: VarslerBody(loader: () async => items)))));
    await settle(tester);

    expect(find.text('Bestillingen er på vei'), findsOneWidget);
    expect(find.text('Vis sporing'), findsOneWidget);
    await tester.tap(find.byKey(const Key('varsler-filter-2')));
    await settle(tester);
    expect(find.text('Bestillingen er på vei'), findsNothing);
    expect(find.text('Tilbud hos Torgboden'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byKey(const Key('varsel-2')), matching: find.byIcon(Icons.close_rounded)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('varsler-tom')), findsOneWidget);
    expect(find.text('Angre'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Bestillinger and Favoritter render their doors', (tester) async {
    await tester.pumpWidget(a3App(const BestillingerScreen(liveCount: 1)));
    await settle(tester);
    expect(find.byKey(const Key('best-live')), findsOneWidget);
    expect(find.byKey(const Key('best-igjen')), findsOneWidget);

    await tester.pumpWidget(a3App(const FavoritterScreen()));
    await settle(tester);
    expect(find.byKey(const Key('fav-kast')), findsOneWidget);
    expect(find.byKey(const Key('fav-liste')), findsOneWidget);
  });

  test('mensDuVarBorteCard is null with nothing to say', () {
    setMensDuVarBorteForTest(const []);
    expect(mensDuVarBorteCard(_FakeContext()), isNull);
  });
}

class _FakeContext extends Fake implements BuildContext {}
