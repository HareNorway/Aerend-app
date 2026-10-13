import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_varsler.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_videre.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_screen.dart';

import '../a3/a3_fakes.dart';

/// Gap Step 4: «Nytt fra butikkene» carries the followed stores' unread
/// count; the old pages' route names only send the user on.
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
    HjemVarsler.reset();
    MegFeed.nye = () async => 0;
  });

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(390, 4200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  FakePointsApi api() => FakePointsApi(
    balanceValue: const PointsBalance(available: 420, pending: 0, earned12m: 420, lifetime: 420, tier: 0, tierName: 'Bronse'),
    shelfValue: const Premiehylla(prizes: [kPrize]),
  );

  Finder merke(String tekst) => find.descendant(of: find.byKey(const Key('meg-rad-nytt')), matching: find.text(tekst));

  testWidgets('«Nytt fra butikkene» shows the unread count from the feed, none at 0', (tester) async {
    tall(tester);
    MegFeed.nye = () async => 2;
    await tester.pumpWidget(a3App(MegScreenBody(api: api(), aegil: FakeAegilApi(), aegilRepo: FakeAegilRepo())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.byKey(const Key('meg-rad-nytt')));
    expect(merke('2'), findsOneWidget);

    MegFeed.nye = () async => 0;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(a3App(MegScreenBody(api: api(), aegil: FakeAegilApi(), aegilRepo: FakeAegilRepo())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.byKey(const Key('meg-rad-nytt')));
    expect(merke('0'), findsNothing);
    await tester.pump(const Duration(seconds: 9));
  });

  Widget ruter(Map<String, WidgetBuilder> extra) => MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(390, 844)),
      child: app!,
    ),
    routes: {
      '/': (_) => const Scaffold(body: Text('start')),
      ...extra,
    },
  );

  testWidgets('/bergen/premie lands on Premiehylla', (tester) async {
    await tester.pumpWidget(
      ruter({
        '/bergen/premie': (_) => BergenVidere((nav) => nav.pushNamed('/bergen/premiehylla')),
        '/bergen/premiehylla': (_) => const Scaffold(body: Text('hylla')),
      }),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/bergen/premie');
    await tester.pumpAndSettle();
    expect(find.text('hylla'), findsOneWidget);
    expect(find.byType(BergenVidere), findsNothing);
  });

  testWidgets('/bergen/meg/varsler opens the Varsler panel', (tester) async {
    HjemVarsler.kilde = HjemVarslerKilde(
      pushes: () async => const [],
      aegil: () async => const [],
      unseen: () async => (antall: 0, sett: null),
      markerSett: () async {},
      ordre: (_) async => null,
    );
    await tester.pumpWidget(ruter({'/bergen/meg/varsler': (_) => BergenVidere((nav) => HjemVarsler.apne(nav.context))}));
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/bergen/meg/varsler');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('varsler-panel')), findsOneWidget);
    expect(find.text('Ingenting nytt siden sist'), findsOneWidget);
  });
}
