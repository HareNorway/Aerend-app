import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/cus_api.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_varsler.dart';
import 'package:aerend_customer/screens/bergen/kit/live_aerend.dart';

import '../layout/reduced_motion_harness.dart';

/// Customer Step 3: Varsler on the per-user inbox — cards from the inbox,
/// read after ~1 s on screen, swipe to «Fjern» / «Ikke slike varsler» with
/// «Angre», «Velg», the rich «Ny på Ærend» card, the bells' count.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  final naa = DateTime(2026, 10, 22, 18, 0);
  final lest = <String>[];
  final fjernet = <(String, bool)>[];
  final dempet = <(String, bool)>[];

  CusVarsel v(String key, String type, String title, {String body = '', String sender = 'Ægil', int min = 10, bool read = false, String? action, int? orderId, bool rich = false, int? storeId}) => CusVarsel(
    key: key,
    type: type,
    muteKey: type,
    kind: '',
    sender: sender,
    title: title,
    body: body,
    at: naa.subtract(Duration(minutes: min)),
    read: read,
    action: action,
    orderId: orderId,
    rich: rich,
    storeId: storeId,
  );

  final items = [
    v('n:1', 'valg', 'Torgboden svarer ikke', body: 'Vent eller avbestill.', sender: 'Ordre', min: 5, action: 'Velg', orderId: 400),
    v('n:2', 'tilbud', 'Torgboden: Reker 500 g', body: 'Tilbud hos en butikk du handler i', min: 6),
    v('n:3', 'nybyen', 'Ny på Ærend: Red Sun (Test)', body: 'Special Deluxe Menu', min: 7, rich: true, storeId: 95),
    v('n:4', 'tilbud', 'Torgboden: Skrei 400 g', min: 8, read: true),
  ];

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

  setUp(() {
    lest.clear();
    fjernet.clear();
    dempet.clear();
    hjemLiveOrdre.value = null;
    HjemVarsler.kilde = HjemVarslerKilde(
      pushes: () async => const [],
      aegil: () async => const [],
      unseen: () async => (antall: 0, sett: null),
      markerSett: () async {},
      ordre: (_) async => null,
      inbox: () async => CusInbox(items: items, unread: 3, mutes: const []),
      antall: () async => 7,
      les: (k) async {
        lest.add(k);
        return true;
      },
      fjern: (k, angre) async {
        fjernet.add((k, angre));
        return true;
      },
      demp: (k, av) async {
        dempet.add((k, av));
        return av ? [k] : <String>[];
      },
    );
  });
  tearDown(HjemVarsler.reset);

  testWidgets('cards from the inbox; read after a second on screen; the bell count is the inbox\'s', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tre ting siden sist.'), findsOneWidget);
    expect(find.text('Torgboden svarer ikke'), findsOneWidget);
    expect(find.byKey(const Key('varsel-handling')), findsOneWidget, reason: '«Velg» on the valg card');
    expect(find.text('Følg'), findsOneWidget);
    expect(find.text('Se meny'), findsOneWidget);
    expect(find.byKey(const Key('varsel-ulest')), findsNWidgets(3));

    // Two 500 ms ticks on screen → read.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(lest, containsAll(['n:1', 'n:2', 'n:3']));
    expect(find.byKey(const Key('varsel-ulest')), findsNothing);
    expect(find.text('Ingenting nytt siden sist.'), findsOneWidget);

    await HjemVarsler.oppdater();
    expect(HjemVarsler.uleste.value, 7);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('swipe to Fjern, Angre puts it back; Ikke slike varsler removes the kind', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();
    await tester.pump();

    await tester.drag(find.text('Torgboden: Reker 500 g'), const Offset(-200, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('varsel-fjern')).hitTestable());
    await tester.pump();
    expect(find.text('Torgboden: Reker 500 g'), findsNothing);
    expect(fjernet, [('n:2', false)]);
    expect(find.text('Fjernet: Torgboden: Reker 500 g'), findsOneWidget);
    await tester.tap(find.byKey(const Key('varsler-angre')));
    await tester.pump();
    expect(find.text('Torgboden: Reker 500 g'), findsOneWidget);
    expect(fjernet.last, ('n:2', true));

    await tester.drag(find.text('Torgboden: Reker 500 g'), const Offset(-200, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('varsel-demp')).hitTestable());
    await tester.pump();
    expect(dempet, [('tilbud', true)]);
    expect(find.text('Torgboden: Reker 500 g'), findsNothing);
    expect(find.text('Torgboden: Skrei 400 g'), findsNothing, reason: 'the whole kind goes');
    expect(find.text('Skrudde av slike varsler'), findsOneWidget);
    await tester.tap(find.byKey(const Key('varsler-angre')));
    await tester.pump();
    expect(dempet.last, ('tilbud', false));
    expect(find.text('Torgboden: Skrei 400 g'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the inbox off: the older sources, no swipe', (tester) async {
    phone(tester);
    HjemVarsler.kilde = HjemVarslerKilde(
      pushes: () async => const [],
      aegil: () async => const [],
      unseen: () async => (antall: 0, sett: null),
      markerSett: () async {},
      ordre: (_) async => null,
    );
    await tester.pumpWidget(host(VarslerPanel(naa: naa)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('varsler-tom')), findsOneWidget);
    expect(find.byKey(const Key('varsel-fjern')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
