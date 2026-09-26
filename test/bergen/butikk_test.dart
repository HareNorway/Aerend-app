import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
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

/// The cart: lines by cart id; −/+/remove change it like the API would.
class _FakeKasse extends OpsKasseApi {
  _FakeKasse([List<KurvLine> lines = const []]) : lines = [...lines];

  List<KurvLine> lines;
  final List<String> calls = [];

  @override
  Future<KurvState> cart() async => KurvState(lines: [...lines]);

  @override
  Future<bool> changeQuantity(int cartId, int quantity) async {
    calls.add('qty $cartId $quantity');
    lines = [
      for (final l in lines)
        l.cartId == cartId
            ? KurvLine(
                cartId: l.cartId,
                productId: l.productId,
                name: l.name,
                quantity: quantity,
                unitPrice: l.unitPrice,
                storeId: l.storeId,
              )
            : l,
    ];
    return true;
  }

  @override
  Future<bool> remove(int cartId) async {
    calls.add('remove $cartId');
    lines = [
      for (final l in lines)
        if (l.cartId != cartId) l,
    ];
    return true;
  }
}

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
    String plain(WidgetTester t, String key) => t
        .widget<RichText>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(RichText),
          ),
        )
        .text
        .toPlainText();

    testWidgets('hero, voyage, Kjøkkenluka, orbs, menu and info tiles', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 7,
            preloaded: _restaurant(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            kasseApi: _FakeKasse(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('a1_butikk_navn')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_seilas')), findsOneWidget);
      // The real thresholds: MIN 150 first, the free-delivery 300 the goal.
      expect(plain(tester, 'a1_butikk_seilas_sum'), '0 / 300 kr');
      expect(
        plain(tester, 'a1_butikk_neste'),
        '150 kr ${ButikkCopy.a1_butikk_til_navn(ButikkCopy.a1_butikk_minstebestilling)}',
      );
      expect(
        find.byKey(const Key('a1_butikk_kjokkenluka')),
        findsOneWidget,
        reason: 'one discounted item → a special',
      );
      expect(find.byKey(const Key('a1_butikk_kat_0')), findsOneWidget);
      expect(
        find.byKey(const Key('a1_butikk_kurvbar')),
        findsNothing,
        reason: 'an empty cart has no bar',
      );

      await tester.tap(find.byKey(const Key('a1_butikk_info_t')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('a1_butikk_info_sheet')), findsOneWidget);
      expect(find.text('10:00–22:30'), findsOneWidget);
    });

    testWidgets('the menu: the orbs filter, the search pill finds dishes', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 7,
            preloaded: _restaurant(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            kasseApi: _FakeKasse(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.dragUntilVisible(
        find.byKey(const Key('a1_butikk_menu_3')),
        find.byKey(const Key('a1_butikk_scroll')),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('a1_butikk_menu_1')), findsOneWidget);

      // Tilbehør (orb 2) leaves only the fries.
      await tester.ensureVisible(find.byKey(const Key('a1_butikk_kat_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_butikk_kat_2')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('a1_butikk_menu_1')), findsNothing);
      expect(find.byKey(const Key('a1_butikk_menu_3')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('a1_butikk_meny_sok_knapp')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_butikk_meny_sok_knapp')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(
        find.byKey(const Key('a1_butikk_meny_sok')),
        'crispy',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('a1_butikk_menu_2')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_menu_3')), findsNothing);
    });

    testWidgets('the basket: the bar, the steppers, the mini list, the total', (
      tester,
    ) async {
      _frame(tester);
      final kasse = _FakeKasse([
        const KurvLine(
          cartId: 91,
          productId: 1,
          name: 'Dobbel cheeseburger',
          quantity: 1,
          unitPrice: 149,
          storeId: 7,
        ),
        const KurvLine(
          cartId: 92,
          productId: 55,
          name: 'Other store',
          quantity: 1,
          unitPrice: 999,
          storeId: 8,
        ),
      ]);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 7,
            preloaded: _restaurant(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            kasseApi: kasse,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Only this store's line; 149 + 39 delivery (under the 300 threshold).
      expect(find.byKey(const Key('a1_butikk_kurvbar')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_varer_i_kurven(1)), findsOneWidget);
      expect(find.text(ButikkCopy.kr(188)), findsOneWidget);
      expect(plain(tester, 'a1_butikk_seilas_sum'), '149 / 300 kr');

      // The grid shows the stepper for the dish in the cart.
      await tester.dragUntilVisible(
        find.byKey(const Key('a1_butikk_plus_1')),
        find.byKey(const Key('a1_butikk_scroll')),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('a1_butikk_qty_1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_butikk_minus_1')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(kasse.calls, ['remove 91']);
      expect(find.byKey(const Key('a1_butikk_kurvbar')), findsNothing);
    });

    testWidgets('the mini list changes quantities and empties the basket', (
      tester,
    ) async {
      _frame(tester);
      final kasse = _FakeKasse([
        const KurvLine(
          cartId: 91,
          productId: 1,
          name: 'Dobbel cheeseburger',
          quantity: 2,
          unitPrice: 149,
          storeId: 7,
        ),
      ]);
      await tester.pumpWidget(
        _app(
          ButikkScreen(
            storeId: 7,
            preloaded: _restaurant(),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            kasseApi: kasse,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 298 kr: under 300, so still 39 in delivery; the boat nearly there.
      expect(find.text(ButikkCopy.kr(337)), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_butikk_kurvbar_toggle')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('a1_butikk_minikurv')), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_butikk_linje_plus_91')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(kasse.calls, ['qty 91 3']);
      // 447 kr is past the free-delivery threshold: no fee, Ægil says so.
      expect(find.text(ButikkCopy.kr(447)), findsWidgets);
      expect(find.byKey(const Key('a1_butikk_frakt_naadd')), findsOneWidget);
      expect(plain(tester, 'a1_butikk_neste'), ButikkCopy.a1_butikk_havn);

      await tester.tap(find.byKey(const Key('a1_butikk_tom_kurven')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('a1_butikk_kurvbar')), findsNothing);
    });

    testWidgets('the restaurant page respects reduced motion', (tester) async {
      _frame(tester);
      await expectRespectsReducedMotion(
        tester,
        () => ButikkScreen(
          storeId: 7,
          preloaded: _restaurant(),
          api: _FakeButikk(),
          customerApi: _FakeCustomer(),
          kasseApi: _FakeKasse([
            const KurvLine(
              cartId: 91,
              productId: 1,
              name: 'Dobbel cheeseburger',
              quantity: 1,
              unitPrice: 149,
              storeId: 7,
            ),
          ]),
        ),
      );
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
    Widget sheet({
      BergenProductOptions opts = const BergenProductOptions(),
      BergenProductDetail? detail,
    }) => _app(
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ProduktSheet(
            item: _item(56, 'Classic Fries', 59),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            options: opts,
            detail: detail,
          ),
        ),
      ),
    );

    testWidgets('the product sheet shows ops.customer.product', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        sheet(
          detail: const BergenProductDetail(
            description: 'Crispy og litt salt.',
            allergens: ['Hvete', 'Melk'],
            readyMinutes: 15,
            mostOrdered: true,
            pointsPer10Kr: 1,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // The menu row's own description wins over the detail's.
      expect(find.text('Beskrivelse'), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_prod_klar(15)), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_prod_mest_bestilt), findsOneWidget);
      // Kjøp: whole 10 kr × 1 → 59 kr earns 5.
      expect(find.text(ButikkCopy.a1_butikk_prod_poeng(5)), findsOneWidget);
      expect(
        find.text(ButikkCopy.a1_butikk_prod_allergen_linje('Hvete, Melk')),
        findsOneWidget,
      );
    });

    testWidgets('without the detail the sheet hides what it does not know', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(sheet());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(ButikkCopy.a1_butikk_prod_mest_bestilt), findsNothing);
      expect(find.textContaining('poeng'), findsNothing);
      expect(
        find.text(ButikkCopy.a1_butikk_info_allergen_missing),
        findsOneWidget,
      );
    });

    testWidgets('single groups are cards, a strength group is the segment', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        sheet(
          opts: const BergenProductOptions(
            groups: [
              BergenOptionGroup(
                name: 'Velg Kjøtt',
                single: true,
                required: true,
                options: [
                  BergenVariant(id: 20, name: 'Kylling'),
                  BergenVariant(id: 21, name: 'Biff', priceDelta: 16),
                ],
              ),
              BergenOptionGroup(
                name: 'Styrke',
                single: true,
                options: [
                  BergenVariant(id: 30, name: 'Mild'),
                  BergenVariant(id: 31, name: 'Medium'),
                  BergenVariant(id: 32, name: 'Hot'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      String sum() => tester
          .widget<Text>(find.byKey(const Key('a1_butikk_produkt_sum')))
          .data!;

      // Required and strength groups open on their first choice.
      expect(sum(), ButikkCopy.a1_butikk_prod_sum('59 kr'));
      expect(find.text('Mild'), findsNWidgets(2)); // the segment + its label
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_21')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(sum(), ButikkCopy.a1_butikk_prod_sum('75 kr'));
      await tester.ensureVisible(
        find.byKey(const Key('a1_butikk_prod_opt_32')),
      );
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_32')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hot'), findsNWidgets(2));
    });

    testWidgets('the product sheet respects reduced motion', (tester) async {
      _frame(tester);
      await expectRespectsReducedMotion(
        tester,
        () => Align(
          alignment: Alignment.bottomCenter,
          child: ProduktSheet(
            item: _item(56, 'Classic Fries', 59),
            api: _FakeButikk(),
            customerApi: _FakeCustomer(),
            options: const BergenProductOptions(),
            detail: const BergenProductDetail(
              readyMinutes: 15,
              mostOrdered: true,
              pointsPer10Kr: 1,
            ),
          ),
        ),
      );
    });

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
            body: Align(
              alignment: Alignment.bottomCenter,
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
      await tester.pump(const Duration(seconds: 1));

      String sum() => tester
          .widget<Text>(find.byKey(const Key('a1_butikk_produkt_sum')))
          .data!;
      expect(sum(), ButikkCopy.a1_butikk_prod_sum('149 kr'));
      await tester.tap(find.byKey(const Key('a1_butikk_prod_size_3')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(sum(), ButikkCopy.a1_butikk_prod_sum('178 kr'));
      await tester.ensureVisible(
        find.byKey(const Key('a1_butikk_prod_opt_10')),
      );
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_10')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('a1_butikk_qty_plus')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(sum(), ButikkCopy.a1_butikk_prod_sum('386 kr'));
      expect(find.text(ButikkCopy.a1_butikk_prod_valgt(1)), findsOneWidget);
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
