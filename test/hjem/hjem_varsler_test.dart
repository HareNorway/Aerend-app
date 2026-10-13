import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_varsler.dart';
import 'package:aerend_customer/screens/bergen/kit/live_aerend.dart';
import 'package:aerend_customer/screens/common/notifications/notifications_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// Gap Step 1: the Varsler panel (new Bergen `vsAapent`, L8524–8627) from
/// real sources: broadcasts («Fra Ærend»), Ægil's unseen actions and the
/// order under way.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final naa = DateTime(2026, 10, 13, 18, 0);
  var sett = 0;

  Widget host(Widget child) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844), textScaler: const TextScaler.linear(.5)),
      child: app!,
    ),
    home: Scaffold(body: child),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  void kilde({List<MassNotificationItem> pushes = const [], List<AwayItem> aegil = const [], DateTime? settTid, VarselOrdre? ordre}) {
    HjemVarsler.kilde = HjemVarslerKilde(
      pushes: () async => pushes,
      aegil: () async => aegil,
      unseen: () async => (antall: pushes.length, sett: settTid),
      markerSett: () async => sett++,
      ordre: (_) async => ordre,
    );
  }

  setUp(() {
    sett = 0;
    hjemLiveOrdre.value = null;
  });
  tearDown(() {
    HjemVarsler.reset();
    hjemLiveOrdre.value = null;
  });

  testWidgets('cards grouped by day, summary counts the unread, opening marks them seen', (tester) async {
    phone(tester);
    kilde(
      pushes: [
        MassNotificationItem(id: 1, title: 'Mye regn i kveld', message: 'Vinduene kan bli 5–10 minutter videre.', datetime: '2026-10-13 17:20:00'),
        MassNotificationItem(id: 2, title: 'Nye butikker', message: 'Tre nye restauranter.', datetime: '2026-10-12 09:00:00'),
      ],
      aegil: [AwayItem(id: 7, text: 'La «ingen skalldyr» til minnet ditt', action: 'memory.add', at: DateTime(2026, 10, 13, 17, 44))],
      settTid: DateTime(2026, 10, 13, 12),
    );
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();

    expect(find.text('Varsler'), findsOneWidget);
    // Two unread: the Ægil action and today's broadcast (yesterday's is before «seen»).
    expect(find.text('To ting siden sist.'), findsOneWidget);
    expect(find.text('I DAG'), findsOneWidget);
    expect(find.text('I GÅR'), findsOneWidget);
    expect(find.text('17:44'), findsOneWidget);
    expect(find.text('Fra Ærend'), findsNWidgets(3)); // two cards + the filter chip
    expect(find.byKey(const Key('varsel-ulest')), findsNWidgets(2));
    expect(find.text('PÅ VEI NÅ'), findsNothing);
    expect(sett, 1);
  });

  testWidgets('filters: Belønninger keeps Ægil, Tilbud is the real empty state', (tester) async {
    phone(tester);
    kilde(
      pushes: [MassNotificationItem(id: 1, title: 'Mye regn i kveld', message: '', datetime: '2026-10-13 17:20:00')],
      aegil: [AwayItem(id: 7, text: 'Fant pad thai på tilbud', action: 'suggestion.add', at: DateTime(2026, 10, 13, 17, 44))],
    );
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('varsler-filter-Belønninger')));
    await tester.tap(find.byKey(const Key('varsler-filter-Belønninger')));
    await tester.pump();
    expect(find.text('Fant pad thai på tilbud'), findsOneWidget);
    expect(find.text('Mye regn i kveld'), findsNothing);

    await tester.tap(find.byKey(const Key('varsler-filter-Tilbud')));
    await tester.pump();
    expect(find.byKey(const Key('varsler-tom')), findsOneWidget);
    expect(find.text('Ingenting nytt siden sist'), findsOneWidget);
  });

  testWidgets('«PÅ VEI NÅ» while an order is under way, under Alle and Bestillinger only', (tester) async {
    phone(tester);
    hjemLiveOrdre.value = (orderId: 276, data: const HjemLiveData(stadie: 2, restSek: 600));
    kilde(
      ordre: const VarselOrdre(orderId: 276, kode: 'Æ-2E8', tittel: 'Kommer 18:12–18:22', linje: 'Aditya er på vei fra Holy Cow'),
    );
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();

    expect(find.text('PÅ VEI NÅ'), findsOneWidget);
    expect(find.text('Kommer 18:12–18:22'), findsOneWidget);
    expect(find.text('Aditya er på vei fra Holy Cow'), findsOneWidget);
    expect(find.text('Ingenting nytt siden sist.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('varsler-filter-Bestillinger')));
    await tester.pump();
    expect(find.text('PÅ VEI NÅ'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('varsler-filter-Fra Ærend')));
    await tester.tap(find.byKey(const Key('varsler-filter-Fra Ærend')));
    await tester.pump();
    expect(find.text('PÅ VEI NÅ'), findsNothing);
  });

  test('copy: summary words, card times, the order line', () {
    expect(VarslerCopy.oppsummering(0), 'Ingenting nytt siden sist.');
    expect(VarslerCopy.oppsummering(1), 'Én ting siden sist.');
    expect(VarslerCopy.oppsummering(12), '12 ting siden sist.');
    expect(VarslerCopy.tid(DateTime(2026, 10, 12, 21, 4), naa), '21:04');
    expect(VarslerCopy.tid(DateTime(2026, 10, 10, 8, 10), naa), 'Lør 08:10');
    expect(VarslerCopy.tid(DateTime(2026, 10, 3, 8, 10), naa), '3. okt.');
    expect(VarslerCopy.gruppe(DateTime(2026, 10, 11), naa), 2);
    expect(VarslerCopy.kommer(DateTime(2026, 10, 13, 18, 12), DateTime(2026, 10, 13, 18, 22), henting: false), 'Kommer 18:12–18:22');
    expect(VarslerCopy.paaVeiLinje(bud: 'Sindre', butikk: 'Torgboden', stadie: 'På vei'), 'Sindre er på vei fra Torgboden');
    expect(VarslerCopy.paaVeiLinje(butikk: 'Holy Cow', stadie: 'Tilberedes'), 'Holy Cow · Tilberedes');
  });
}
