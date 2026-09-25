import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/butikk/automat_screen.dart';
import 'package:aerend_customer/screens/bergen/butikk/butikk_copy.dart';
import 'package:aerend_customer/screens/bergen/butikk/butikk_screen.dart';
import 'package:aerend_customer/screens/bergen/butikk/dreieskiven.dart';
import 'package:aerend_customer/screens/bergen/butikk/info_sheet.dart';
import 'package:aerend_customer/screens/bergen/butikk/kategori_screen.dart';
import 'package:aerend_customer/screens/bergen/butikk/klede_sheet.dart';
import 'package:aerend_customer/screens/bergen/butikk/mote_butikk_screen.dart';
import 'package:aerend_customer/screens/bergen/butikk/produkt_sheet.dart';
import 'package:aerend_customer/screens/common/home/home_dl.dart';
import 'package:aerend_customer/screens/deliveryService/home/ds_home_store_list_pojo.dart';
import 'package:aerend_customer/screens/deliveryService/searchStore/search_store_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 4: Kategori, the two store pages, the three sheets, the
/// Dreieskiven and Poseautomaten — rendering from injected data, and the
/// route map carrying all three names.
class _FakeButikk extends OpsButikkApi {
  _FakeButikk({
    this.stores = const [],
    this.products = const [],
    this.storeInfo,
    this.opts = const BergenProductOptions(),
  });

  final List<StoreListItem> stores;
  final List<ProductList> products;
  final BergenStoreInfo? storeInfo;
  final BergenProductOptions opts;

  @override
  Future<List<ServicesItem>> categories() async => const [];
  @override
  Future<List<StoreListItem>> storesInCategory(int categoryId) async => stores;
  @override
  Future<List<ProductList>> productsInCategory(
    int categoryId, {
    String query = '',
  }) async => products;
  @override
  Future<BergenStoreInfo?> store(int storeId, {String? categoryHint}) async =>
      storeInfo;
  @override
  Future<BergenProductOptions> options(int productId) async => opts;
  @override
  Future<bool> subscribeToPrice(int productId) async => true;
}

class _FakeCustomer extends OpsCustomerApi {
  _FakeCustomer({this.pulse, this.presence, this.bags = const []});

  final Map<String, dynamic>? pulse;
  final Map<String, dynamic>? presence;
  final List<Map<String, dynamic>> bags;

  @override
  Future<Map<String, dynamic>?> categoryPulse(String slug) async => pulse;
  @override
  Future<Map<String, dynamic>?> storePresence(int storeId) async => presence;
  @override
  Future<Map<String, dynamic>?> pointsRules() async => null;
  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => null;
  @override
  Future<List<Map<String, dynamic>>> poser() async => bags;
}

StoreListItem _store(String name, {int id = 7, int eta = 25}) =>
    StoreListItem.fromJson({
      'store_id': id,
      'store_name': name,
      'store_banner': '',
      'store_products': 'Burgere · Kylling',
      'average_ratings': 4.6,
      'total_reviews': 12,
      'store_open_time': '10:00',
      'offer': '',
      'order_delivery_time': eta,
      'order_min_amount': 150,
      'store_status': 1,
      'distance': 1.2,
    });

BergenMenuItem _item(
  int id,
  String name,
  double price, {
  double? was,
  String? cat,
}) => BergenMenuItem(
  id: id,
  name: name,
  storeId: 7,
  storeName: 'Burger King',
  price: price,
  wasPrice: was,
  categoryName: cat,
  description: 'Beskrivelse',
);

BergenStoreInfo _restaurant() => BergenStoreInfo(
  id: 7,
  name: 'Burger King',
  kind: BergenStoreKind.restaurant,
  closeTime: '22:30',
  deliveryMinutes: 30,
  deliveryChargeKr: 39,
  minOrderKr: 150,
  offerMinAmountKr: 300,
  rating: '4,6',
  address: 'Strømgaten 8, Bergen',
  distanceKm: 1.2,
  hours: const [
    BergenStoreHours(day: 'Mandag', opens: '10:00', closes: '22:30'),
  ],
  menu: [
    BergenMenuCategory(
      id: 1,
      name: 'Burgere',
      items: [
        _item(1, 'Dobbel cheeseburger', 149, was: 179),
        _item(2, 'Crispy chicken', 129),
      ],
    ),
    BergenMenuCategory(
      id: 2,
      name: 'Tilbehør',
      items: [_item(3, 'Pommes frites, stor', 59)],
    ),
  ],
);

BergenStoreInfo _fashion() => BergenStoreInfo(
  id: 9,
  name: 'Torgboden Mote',
  kind: BergenStoreKind.fashion,
  closeTime: '20:00',
  deliveryMinutes: 50,
  deliveryChargeKr: 0,
  menu: [
    BergenMenuCategory(
      id: 1,
      name: 'Tiger of Sweden',
      items: [
        _item(11, 'Hettejakke «Ives»', 2499, cat: 'Tiger of Sweden'),
        _item(12, 'T-skjorte «Dillan»', 899, was: 999, cat: 'Tiger of Sweden'),
      ],
    ),
    BergenMenuCategory(
      id: 2,
      name: 'Devold',
      items: [_item(13, 'Ullgenser «Vestland»', 1799, cat: 'Devold')],
    ),
  ],
);

Widget _app(Widget child) => MaterialApp(home: child);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  test('the three Phase 4 routes are in the agil-1 map', () {
    final keys = bergenRoutesAgil1().keys;
    expect(
      keys,
      containsAll(['/bergen/kategori', '/bergen/butikk', '/bergen/automat']),
    );
  });

  test('a store kind comes from its category name', () {
    expect(BergenStoreInfo.kindOf('Mote'), BergenStoreKind.fashion);
    expect(BergenStoreInfo.kindOf('Gaver'), BergenStoreKind.gift);
    expect(BergenStoreInfo.kindOf('Restaurant'), BergenStoreKind.restaurant);
    expect(BergenStoreInfo.kindOf(null), BergenStoreKind.other);
  });

  group('Kategori', () {
    testWidgets('title, open count, pulse strip, tabs and store cards', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          KategoriScreen(
            slug: 'restaurant',
            categoryId: 3,
            name: 'Restaurant',
            api: _FakeButikk(
              stores: [_store('Burger King'), _store('Casa Maria', id: 8)],
            ),
            customerApi: _FakeCustomer(
              pulse: {'orders_last_hour': 12, 'stores_open': 9},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_kat_title')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_kat_open(2)), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_kat_pulse')), findsOneWidget);
      expect(
        find.byKey(const Key('a1_butikk_kat_bilde')),
        findsOneWidget,
        reason: 'Mat only: Bestill fra bilde',
      );
      expect(find.text('Burger King'), findsOneWidget);
      expect(find.text('Casa Maria'), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_butikk_kat_tab_produkter')));
      await tester.pump();
      expect(
        find.text(ButikkCopy.a1_butikk_kat_empty_products),
        findsOneWidget,
      );
    });

    testWidgets('the Under 30 min filter narrows the stores', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          KategoriScreen(
            slug: 'restaurant',
            categoryId: 3,
            name: 'Restaurant',
            api: _FakeButikk(
              stores: [_store('Rask', eta: 20), _store('Treg', id: 8, eta: 45)],
            ),
            customerApi: _FakeCustomer(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.drag(
        find.byKey(const Key('a1_butikk_kat_filters')),
        const Offset(-250, 0),
      );
      await tester.pump();
      await tester.tap(find.text(ButikkCopy.a1_butikk_kat_f_fast));
      await tester.pump();
      expect(find.text('Rask'), findsOneWidget);
      expect(find.text('Treg'), findsNothing);
    });

    testWidgets('the Gaver variant shows its blocks and no photo button', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          KategoriScreen(
            slug: 'gaver',
            categoryId: 5,
            name: 'Gaver',
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_gave_aegil')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_gave_anledninger), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_kat_bilde')), findsNothing);
    });
  });

  group('Butikk (restaurant)', () {
    testWidgets('hero, voyage, Kjøkkenluka, menu and info chips', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 7,
            preloaded: _restaurant(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(presence: {'viewers_now': 3}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_navn')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_seilas')), findsOneWidget);
      expect(
        find.text('0 kr / 300 kr'),
        findsOneWidget,
        reason: 'the real free-delivery threshold is the goal',
      );
      expect(
        find.byKey(const Key('a1_butikk_kjokkenluka')),
        findsOneWidget,
        reason: 'one discounted item → a special',
      );
      expect(find.byKey(const Key('a1_butikk_menu_1')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_kikker')), findsOneWidget);
      expect(
        find.byKey(const Key('a1_butikk_kurvbar')),
        findsNothing,
        reason: 'no lines yet',
      );

      await tester.tap(find.byKey(const Key('a1_butikk_info_t')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('a1_butikk_info_sheet')), findsOneWidget);
      expect(find.text('10:00–22:30'), findsOneWidget);
    });

    testWidgets('a missing store says so', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 404,
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_not_found')), findsOneWidget);
    });

    testWidgets('a fashion store routes to the Mote page', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 9,
            preloaded: _fashion(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_mote_label')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_mote_label), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_dreieskiven')), findsOneWidget);
      await tester.dragUntilVisible(
        find.byKey(const Key('a1_butikk_hyller')),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_merker')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_hyller')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_til_denne')), findsOneWidget);
    });
  });

  group('sheets', () {
    testWidgets('the product sheet sums size and quantity', (tester) async {
      _frame(tester);
      const opts = BergenProductOptions(
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
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: ProduktSheet(
                item: _item(1, 'Dobbel cheeseburger', 149),
                api: _FakeButikk(),
                customerApi: _FakeCustomer(),
                options: opts,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(ButikkCopy.a1_butikk_prod_legg('149 kr')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('a1_butikk_prod_size_3')));
      await tester.pump();
      expect(
        find.text(ButikkCopy.a1_butikk_prod_legg('178 kr')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_10')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_butikk_qty_plus')));
      await tester.pump();
      expect(
        find.text(ButikkCopy.a1_butikk_prod_legg('386 kr')),
        findsOneWidget,
      );
    });

    testWidgets(
      'the Klede sheet shows stock per size and the try-at-home line',
      (tester) async {
        _frame(tester);
        const opts = BergenProductOptions(
          colours: [BergenVariant(id: 1, name: 'Marine')],
          sizes: [
            BergenVariant(id: 5, name: 'S'),
            BergenVariant(id: 6, name: 'M', inStock: false),
          ],
        );
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: SingleChildScrollView(
                child: KledeSheet(
                  item: _item(11, 'Hettejakke «Ives»', 2499),
                  api: _FakeButikk(),
                  options: opts,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text('S · ${ButikkCopy.a1_butikk_klede_paa_lager}'),
          findsOneWidget,
        );
        expect(
          find.text('M · ${ButikkCopy.a1_butikk_klede_utsolgt}'),
          findsOneWidget,
        );
        expect(find.text(ButikkCopy.a1_butikk_klede_prov), findsOneWidget);
        expect(
          find.text(ButikkCopy.a1_butikk_klede_legg('2499 kr')),
          findsOneWidget,
        );
      },
    );

    testWidgets('the info sheet switches tabs', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: InfoSheet(store: _restaurant(), initial: InfoTab.mer),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Strømgaten 8'), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_butikk_info_allergener')));
      await tester.pump();
      expect(
        find.text(ButikkCopy.a1_butikk_info_allergen_missing),
        findsOneWidget,
      );
    });
  });

  group('Dreieskiven', () {
    testWidgets('the front item shows its price and add', (tester) async {
      _frame(tester);
      BergenMenuItem? added;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Dreieskiven(
              items: [_item(1, 'A', 100), _item(2, 'B', 200)],
              onAdd: (i) => added = i,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_skive_navn')), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.text(ButikkCopy.a1_butikk_skive_legg));
      expect(added?.id, 1);
    });
  });

  group('Poseautomaten', () {
    testWidgets('a pull lands the chosen bag; empty machine is honest', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          AutomatScreen(
            api: _FakeCustomer(
              bags: [
                {
                  'id': '1',
                  'name': 'Forundringspose bakst',
                  'store_name': 'Sandviken Bakeri',
                  'store_id': 3,
                  'price_ore': 9900,
                  'pickup_window': 'til 18:00',
                },
                {
                  'id': '2',
                  'name': 'Forundringspose grønt',
                  'store_name': 'Grønt & Godt',
                  'store_id': 4,
                  'price_ore': 7900,
                },
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_automat_title')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_butikk_automat_right')));
      await tester.pump();
      expect(find.text('Grønt & Godt'), findsWidgets);
      await tester.tap(find.text(ButikkCopy.a1_butikk_automat_trekk(99)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('a1_butikk_automat_vunnet')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_automat_sikre(79)), findsOneWidget);
    });

    testWidgets('no bags tonight', (tester) async {
      _frame(tester);
      await tester.pumpWidget(_app(AutomatScreen(api: _FakeCustomer())));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_automat_empty')), findsOneWidget);
    });
  });
}
