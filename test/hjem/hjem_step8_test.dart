import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_snart.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_vindu.dart';

import '../layout/reduced_motion_harness.dart';

/// Backend plan Step 8 — Hjem's data: Vindu «Bestill igjen» from the
/// customer's own shops, «Kommer snart» from the server.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Widget host(Widget child) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  HjemVinduStripe stripe(List<String> butikker, ValueChanged<int> onButikk) => HjemVinduStripe(
    onToggle: () {},
    onDragStart: (_) {},
    onDragUpdate: (_) {},
    onDragEnd: (_) {},
    butikker: butikker,
    onButikk: onButikk,
  );

  testWidgets('Vindu «Bestill igjen» lists the customer\'s own shops and taps the one chosen', (tester) async {
    phone(tester);
    final valgt = <int>[];
    await tester.pumpWidget(host(stripe(['Pokemon Pizza', 'Sushi Bar'], valgt.add)));
    await tester.pump();

    expect(find.text('Bestill igjen'), findsOneWidget);
    expect(find.text('Pokemon Pizza'), findsOneWidget);
    expect(find.text('Casa Maria'), findsNothing);
    await tester.tap(find.byKey(const Key('a1_hjem_vindu_igjen_1')));
    expect(valgt, [1]);
  });

  testWidgets('no earlier orders: no «Bestill igjen» row', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(stripe(const [], (_) {})));
    await tester.pump();

    expect(find.text('Bestill igjen'), findsNothing);
  });

  test('«Kommer snart» rows: coming ones by slot, live ones left out', () {
    final mote = HjemSnartInfo.fraJson({
      'id': 7, 'slot': 2, 'state': 'coming', 'title': 'Mote', 'description': 'Klær', 'aegil_quote': 'Snart!',
      'ready_count': 9, 'target_count': 12, 'notify': true,
    });
    expect(mote!.$1, 2);
    expect(mote.$2.id, 7);
    expect(mote.$2.klar, 9);
    expect(mote.$2.maal, 12);
    expect(mote.$2.varsles, isTrue);

    expect(HjemSnartInfo.fraJson({'slot': 1, 'state': 'live', 'title': 'Mat & fisk'}), isNull);
  });

  testWidgets('the sheet says when every shop is ready', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => visKommerSnart(
          context,
          k: 2,
          info: const HjemSnartInfo(navn: 'Mote', tekst: 'Klær', klar: 12, maal: 12, aeg: 'Snart!'),
          varsles: false,
          onVarsle: (_) {},
          onRestauranter: () {},
        ),
        child: const Text('åpne'),
      ),
    )));
    await tester.tap(find.text('åpne'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Alle butikkene er klare. Vi åpner snart.'), findsOneWidget);
    expect(find.text('12 av 12'), findsOneWidget);
  });
}
