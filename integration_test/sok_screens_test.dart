import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/data/ops/sok_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/sok/sok_screen.dart';

import '../test/layout/reduced_motion_harness.dart';

/// Device pass for Søk with the prototype's own content (Nylig, Populært nå,
/// Ukens oppdrag, the «bur» hits) for 1:1 screenshots against the design.
class _ProtoApi extends OpsCustomerApi {
  @override
  Future<List<SokTrend>> trendingItems() async => const [
    SokTrend('fiskesuppe', 38),
    SokTrend('kanelboller', 21),
    SokTrend('pizza', 17),
  ];

  @override
  Future<Map<String, dynamic>?> mission() async => {
    'mission': {
      'title': 'Prøv Nordnes Fisk',
      'body': 'Én bestilling teller. Ett oppdrag per uke.',
      'points': 50,
    },
  };

  @override
  Future<SokTreff> search(String query, {double? lat, double? lng}) async {
    if (!query.startsWith('bur')) return const SokTreff();
    return const SokTreff(
      butikker: [
        SokButikk(
          id: 1,
          name: 'Burger King',
          category: 'Restaurant',
          etaMinutes: 18,
          rating: '4,6 (318)',
          feeText: 'Gratis over 300 kr',
        ),
      ],
      produkter: [
        SokProdukt(id: 1, name: 'Dobbel cheeseburger', storeId: 1, storeName: 'Burger King', price: 149),
        SokProdukt(id: 2, name: 'Crispy chicken', storeId: 1, storeName: 'Burger King', price: 129),
        SokProdukt(id: 3, name: 'Pommes frites, stor', storeId: 1, storeName: 'Burger King', price: 59),
      ],
    );
  }
}

Future<void> _hold(WidgetTester t, String state, [int ms = 5000]) async {
  await t.pump();
  await t.runAsync(() async {
    final dir = await getApplicationDocumentsDirectory();
    File('${dir.path}/fiske_state.txt').writeAsStringSync(state);
    await Future<void>.delayed(Duration(milliseconds: ms));
  });
  await t.pump();
}

Future<void> _type(WidgetTester t, String q) async {
  await t.enterText(find.byKey(const Key('a1_sok_field')), q);
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
  await t.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Søk for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    SokScreen.remember('gavekort');
    SokScreen.remember('laksesashimi');
    SokScreen.remember('sushi');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SokScreen(api: _ProtoApi()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1600)));
    await _hold(tester, 'sok_tom');
    await _type(tester, 'bur');
    await _hold(tester, 'sok_bur');
    await _type(tester, 'tacokveld for fire under 500 kr');
    await _hold(tester, 'sok_onske');
    await _type(tester, 'zzzz');
    await _hold(tester, 'sok_ingen');
    await _hold(tester, 'sok_done', 500);
  });
}
