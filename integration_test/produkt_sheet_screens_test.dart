import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/butikk/produkt_sheet.dart';
import 'package:aerend_customer/screens/bergen/sok/sok_screen.dart';

import '../test/layout/reduced_motion_harness.dart';

/// Device pass for the product sheet: the live flow (Søk «fries» → tap →
/// the sheet over the local backend), then the prototype's own options
/// (Størrelse, Tillegg with bacon, Styrke) for a 1:1 screenshot.
class _ProtoButikk extends OpsButikkApi {
  @override
  Future<BergenProductOptions> options(int productId) async =>
      const BergenProductOptions(
        sizes: [
          BergenVariant(id: 1, name: 'Liten', priceDelta: -20),
          BergenVariant(id: 2, name: 'Vanlig'),
          BergenVariant(id: 3, name: 'Stor', priceDelta: 29),
        ],
        groups: [
          BergenOptionGroup(
            name: 'Tillegg',
            options: [
              BergenVariant(id: 10, name: 'Ekstra cheddar', priceDelta: 15),
              BergenVariant(id: 11, name: 'Sprøstekt bacon', priceDelta: 25),
              BergenVariant(id: 12, name: 'Uten løk'),
            ],
          ),
          BergenOptionGroup(
            name: 'Styrke',
            single: true,
            options: [
              BergenVariant(id: 20, name: 'Mild'),
              BergenVariant(id: 21, name: 'Medium'),
              BergenVariant(id: 22, name: 'Hot'),
            ],
          ),
        ],
      );

  @override
  Future<BergenProductDetail?> productDetail(int productId) async =>
      const BergenProductDetail(
        allergens: ['gluten', 'melk', 'sennep'],
        readyMinutes: 12,
        mostOrdered: true,
        pointsPer10Kr: 1,
        hasSizes: true,
      );
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

Future<void> _wait(WidgetTester t, int ms) async {
  await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await t.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('product sheet for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = true;

    // 1 · live: Søk «fries» against the local backend, tap the first hit.
    await tester.pumpWidget(
      const MaterialApp(debugShowCheckedModeBanner: false, home: SokScreen()),
    );
    await _wait(tester, 1200);
    await tester.enterText(find.byKey(const Key('a1_sok_field')), 'fries');
    await _wait(tester, 3000);
    await _hold(tester, 'produkt_sok');
    final hit = find.textContaining('Fries');
    if (hit.evaluate().isNotEmpty) {
      await tester.tap(hit.first);
      await _wait(tester, 2500);
      await _hold(tester, 'produkt_live');
      await tester.tap(find.byKey(const Key('a1_butikk_produkt_lukk')));
      await _wait(tester, 600);
    }

    // 2 · the prototype's options on a Burger King product.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFF1E4F5C),
            body: Center(
              child: TextButton(
                onPressed: () => showProduktSheet(
                  context,
                  api: _ProtoButikk(),
                  item: const BergenMenuItem(
                    id: 1,
                    name: 'Dobbel cheeseburger',
                    storeId: 7,
                    storeName: 'Burger King',
                    price: 149,
                    hasSizes: true,
                    description:
                        'To grillede karbonader, cheddar, sylteagurk og dressing.',
                    imageUrl:
                        'http://10.224.247.180:8000/assets/images/store-images/product-images/1151215202426111.jpeg',
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await _wait(tester, 400);
    await tester.tap(find.text('open'));
    await _wait(tester, 1800);
    await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_11')));
    await _wait(tester, 800);
    await _hold(tester, 'produkt_proto_top');
    await tester.drag(
      find.byKey(const Key('a1_butikk_produkt_navn')),
      const Offset(0, -400),
    );
    await _wait(tester, 800);
    await _hold(tester, 'produkt_proto_bunn');
    await _hold(tester, 'produkt_done', 500);
  });
}
