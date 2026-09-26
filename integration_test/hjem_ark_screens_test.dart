import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_category_rad.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_hjem_ark.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';

import '../test/layout/reduced_motion_harness.dart';

/// Device pass for the Hjem Ark with the prototype's own Restaurant content
/// (KAT[0] + MER[0]), on Hjem's teal background, for a 1:1 screenshot.
const _cats = [
  BergenCategory(id: 5, name: 'Restaurant', liveText: '24 åpne nå', look: BergenCategoryLook.restaurant),
  BergenCategory(id: 6, name: 'Mat & fisk', liveText: '9 åpne nå', look: BergenCategoryLook.fish),
  BergenCategory(id: 7, name: 'Mote', liveText: 'Åpner 10:00', look: BergenCategoryLook.fashion),
  BergenCategory(id: 8, name: 'Interiør', liveText: '6 åpne nå', look: BergenCategoryLook.interior),
  BergenCategory(id: 9, name: 'Gaver', liveText: '4 åpne nå', look: BergenCategoryLook.gifts),
];

const _stores = [
  BergenStoreCard(id: 1, name: 'Casa Maria', subtitle: '', open: true, eta: '25–35 min', fee: '39 kr', rating: '4,7 (212)'),
  BergenStoreCard(id: 2, name: 'Fyllingsdalen Wok', subtitle: '', open: true, eta: '20–30 min', fee: 'Gratis', rating: '4,5 (89)'),
  BergenStoreCard(id: 3, name: 'Pizza Forno', subtitle: '', open: true, eta: '30–40 min', fee: '45 kr', rating: '4,6 (140)'),
  BergenStoreCard(id: 4, name: 'Sushi Nordnes', subtitle: '', open: true, eta: '30–40 min', fee: '45 kr', rating: '4,8 (167)'),
  BergenStoreCard(id: 5, name: 'Bien Bar', subtitle: '', open: true, eta: '30–50 min', fee: '55 kr', rating: '4,6 (204)'),
  BergenStoreCard(id: 6, name: 'Pizza Nostra', subtitle: '', open: true, eta: '25–40 min', fee: '39 kr', rating: '4,5 (98)'),
];

HjemArkProduct _p(int id, String n, String st, int kr) => HjemArkProduct(id: id, name: n, storeId: id, storeName: st, priceOre: kr * 100);

Future<void> _hold(WidgetTester t, String state, [int ms = 5000]) async {
  await t.pump();
  await t.runAsync(() async {
    final dir = await getApplicationDocumentsDirectory();
    File('${dir.path}/fiske_state.txt').writeAsStringSync(state);
    await Future<void>.delayed(Duration(milliseconds: ms));
  });
  await t.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Hjem Ark for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            final safeTop = MediaQuery.paddingOf(context).top;
            return Scaffold(
              body: DecoratedBox(
                decoration: const BoxDecoration(gradient: kBergenScreenGradient),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: safeTop + 96 * context.bs,
                      bottom: 0,
                      child: HjemArk(
                        categories: _cats,
                        index: 0,
                        stores: _stores,
                        openCount: 0,
                        loadProducts: (_) async => [
                          _p(1, 'Pizza margherita', 'Casa Maria', 189),
                          _p(2, 'Pad thai', 'Fyllingsdalen Wok', 165),
                          _p(3, 'Nudelsuppe', 'Fyllingsdalen Wok', 139),
                          _p(4, 'Sushi 8 stk', 'Sushi Nordnes', 229),
                          _p(5, 'Burger «Vågen»', 'Bien Bar', 219),
                          _p(6, 'Calzone', 'Pizza Nostra', 195),
                        ],
                        onIndexChanged: (_) {},
                        onClose: () {},
                        onMore: () {},
                        onOpenStore: (_) {},
                        onOpenProduct: (_) {},
                        onAdd: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1200)));
    await _hold(tester, 'ark_top');
    await tester.drag(find.byKey(const Key('a1_hjem_ark_list')), const Offset(0, -560));
    await tester.pump(const Duration(milliseconds: 600));
    await _hold(tester, 'ark_produkter');
    await _hold(tester, 'ark_done', 500);
  });
}
