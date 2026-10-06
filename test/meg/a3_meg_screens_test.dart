import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/borte_entry.dart';
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

  test('mensDuVarBorteCard is null with nothing to say', () {
    setMensDuVarBorteForTest(const []);
    expect(mensDuVarBorteCard(_FakeContext()), isNull);
  });
}

class _FakeContext extends Fake implements BuildContext {}
