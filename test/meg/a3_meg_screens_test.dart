import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/bestillinger_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
import 'package:aerend_customer/screens/bergen/meg/favoritter_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/konto_screen.dart';
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
    // Logged out / none yet: the empty state with Kast ut, no list.
    expect(find.byKey(const Key('fav-kast')), findsOneWidget);
    expect(find.byKey(const Key('fav-liste')), findsNothing);
  });

  test('mensDuVarBorteCard is null with nothing to say', () {
    setMensDuVarBorteForTest(const []);
    expect(mensDuVarBorteCard(_FakeContext()), isNull);
  });
}

class _FakeContext extends Fake implements BuildContext {}
