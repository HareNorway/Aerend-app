import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_category_rad.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_hjem_ark.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';

import '../layout/reduced_motion_harness.dart';

/// The Hjem Ark (design L7146): what both «Se alle» on Hjem open — the
/// category's store grid and «Populært i {kategori}» from
/// `ops/products?kind=populaert`.
const _cats = [
  BergenCategory(id: 5, name: 'Restaurant', liveText: '24 åpne nå', look: BergenCategoryLook.restaurant),
  BergenCategory(id: 6, name: 'Mote', liveText: '4 åpne nå', look: BergenCategoryLook.fashion),
];

const _stores = [
  BergenStoreCard(id: 9, name: 'Red Sun', subtitle: '', open: true, eta: '15 min', rating: '4.6'),
  BergenStoreCard(id: 42, name: 'Gyros House', subtitle: '', open: false, eta: '10 min'),
];

HjemArkProduct _p(int id, String name, int ore) => HjemArkProduct(id: id, name: name, storeId: 9, storeName: 'Red Sun', priceOre: ore);

void _frame(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });

  test('a product reads price and image from the populaert payload', () {
    final p = HjemArkProduct.fromJson({'id': '779', 'name': 'Pad thai', 'store_id': 42, 'store_name': 'Red Sun', 'price_ore': 139930, 'image': ''});
    expect(p.id, 779);
    expect(p.priceText, '1 399,30 kr');
    expect(p.imageUrl, isNull);
    expect(_p(1, 'x', 18900).priceText, '189 kr');
  });

  testWidgets('stores, products, chips, add, open and close', (tester) async {
    _frame(tester);
    final loaded = <int>[];
    var index = 0;
    final events = <String>[];
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return HjemArk(
                categories: _cats,
                index: index,
                stores: _stores,
                openCount: 1,
                loadProducts: (id) async {
                  loaded.add(id);
                  return id == 5 ? [_p(1, 'Pad thai', 16500), _p(2, 'Nudelsuppe', 13900)] : const [];
                },
                onIndexChanged: (i) => set(() => index = i),
                onClose: () => events.add('close'),
                onMore: () => events.add('more'),
                onOpenStore: (s) => events.add('store:${s.id}'),
                onOpenProduct: (p) => events.add('product:${p.id}'),
                onAdd: (p) => events.add('add:${p.id}'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Butikker på Bryggen'), findsOneWidget);
    expect(find.text('Red Sun'), findsWidgets);
    expect(find.text('Stengt'), findsOneWidget, reason: 'a closed store says so');
    expect(find.text('Populært i Restaurant'), findsOneWidget);
    expect(find.text('Pad thai'), findsOneWidget);
    expect(find.text('165 kr'), findsOneWidget);
    expect(loaded, [5]);

    await tester.tap(find.byKey(const Key('a1_hjem_ark_legg_1')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('a1_hjem_ark_butikk_9')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(events, ['add:1', 'store:9']);

    // Another chip: the Ark follows the category and loads its products.
    await tester.tap(find.byKey(const Key('a1_hjem_ark_chip_1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('a1_hjem_ark_title')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('a1_hjem_ark_title'))).data, 'Mote');
    expect(find.text('Butikker på Torgallmenningen'), findsOneWidget);
    expect(loaded, [5, 6]);
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_hjem_ark_ingen_varer')),
      find.byKey(const Key('a1_hjem_ark_list')),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('a1_hjem_ark_ingen_varer')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const Key('a1_hjem_ark_mer')),
      find.byKey(const Key('a1_hjem_ark_chips')),
      const Offset(-120, 0),
    );
    await tester.tap(find.byKey(const Key('a1_hjem_ark_mer')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('a1_hjem_ark_lukk')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('a1_hjem_ark_handle')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(events.sublist(2), ['more', 'close', 'close']);
  });

  testWidgets('the Ark respects reduced motion', (tester) async {
    _frame(tester);
    await expectRespectsReducedMotion(
      tester,
      () => HjemArk(
        categories: _cats,
        index: 0,
        stores: _stores,
        openCount: 1,
        loadProducts: (_) async => [_p(1, 'Pad thai', 16500)],
        onIndexChanged: (_) {},
        onClose: () {},
        onMore: () {},
        onOpenStore: (_) {},
        onOpenProduct: (_) {},
        onAdd: (_) {},
      ),
    );
  });
}
