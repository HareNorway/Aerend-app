import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/butikk/butikk_copy.dart';
import 'package:aerend_customer/screens/bergen/butikk/klede_sheet.dart';
import 'package:aerend_customer/screens/bergen/butikk/produkt_sheet.dart';
import 'package:aerend_customer/screens/deliveryService/storeDetail/store_detail_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// Scraper plan Chunk 8B: the product sheet over the catalogue fields. The
/// fixtures under `test/fixtures/scraper/` are real responses from a local
/// backend (`ops.customer.product` and `get-topping-option`): Holzweiler
/// product 782 (web stock, eight images, XXL sold out) and a Pita kebab 785
/// (three required one-choice groups, +30 / +20 kr).
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/scraper/$name.json').readAsStringSync()) as Map<String, dynamic>;

/// Options from a fixture; the first read can fail to test the retry.
class _Api extends OpsButikkApi {
  _Api({this.opts, this.det, this.failFirst = 0});

  final BergenProductOptions? opts;
  final BergenProductDetail? det;
  int failFirst;
  int calls = 0;

  @override
  Future<ButikkResult<BergenProductOptions>> optionsResult(int productId) async {
    calls++;
    if (failFirst > 0) {
      failFirst--;
      return const ButikkResult.failed();
    }
    return ButikkResult.ok(opts ?? const BergenProductOptions());
  }

  @override
  Future<ButikkResult<BergenProductDetail>> productDetailResult(int productId) async =>
      ButikkResult.ok(det);
}

class _Customer extends OpsCustomerApi {}

BergenMenuItem _item(int id, String name, double price) =>
    BergenMenuItem(id: id, name: name, storeId: 875014, storeName: 'LOCAL-TEST Scraper Store', price: price);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });
  tearDownAll(() => OpsCustomerApi.networkEnabled = true);

  group('parsing', () {
    test('hasSizes needs size_optoinal == 0; a missing key is no sizes', () {
      BergenMenuItem row(Map<String, dynamic> extra) => BergenMenuItem.fromPojo(
        ProductListItem.fromJson({'product_id': 1, 'product_name': 'X', 'product_amount': 10, ...extra}),
        storeId: 1,
        storeName: 'S',
      );
      expect(row({}).hasSizes, isFalse);
      expect(row({'size_optoinal': 1}).hasSizes, isFalse);
      expect(row({'size_optoinal': 0}).hasSizes, isTrue);
      expect(row({}).hasColours, isFalse);
      expect(row({'color_optional': 0}).hasColours, isTrue);
    });

    test('a variant without stock is unknown, not in stock', () {
      final o = BergenProductOptions.fromJson({
        'status': 1,
        'size_list': [
          {'id': 1, 'name': 'S'},
          {'id': 2, 'name': 'M', 'stock': 0},
          {'id': 3, 'name': 'L', 'stock': 1, 'stock_qty': 2},
        ],
      });
      expect(o.sizes[0].stock, isNull);
      expect(o.sizes[0].stockUnknown, isTrue);
      expect(o.sizes[0].inStock, isTrue, reason: 'unknown stays choosable');
      expect(o.sizes[1].stock, isFalse);
      expect(o.sizes[2].stock, isTrue);
      expect(o.sizes[2].stockQty, 2);
    });

    test('get-topping-option for Holzweiler 782: sizes, colour hex, the grid', () {
      final o = BergenProductOptions.fromJson(_fixture('addon_782'));
      expect(o.sizes.map((v) => v.name), ['XS', 'S', 'M', 'L', 'XL', 'XXL']);
      expect(o.sizes.last.stock, isFalse);
      expect(o.sizes.first.stockQty, 1);
      expect(o.colours.single.hex, '#352C2C');
      expect(o.cells, isNotEmpty);
      expect(o.cell('XXL', 'Dk. Brown')?.inStock, isFalse);
      expect(o.cell('m', 'dk. brown')?.stockQty, 1);
    });

    test('ops.customer.product for 782: øre, web stock, images, grid', () {
      final d = BergenProductDetail.fromJson(_fixture('ops_782'));
      expect(d.priceOre, 580000);
      expect(d.priceKr, 5800);
      expect(ButikkCopy.kr(d.priceKr!), ButikkCopy.kr(5800));
      expect(d.stockMode, 'web');
      expect(d.stockUpdatedAt, isNotNull);
      expect(d.images.length, 8);
      expect(d.colours.single.hex, '#352C2C');
      expect(d.cells.where((c) => c.inStock == false).map((c) => c.size), contains('XXL'));
    });

    test('Pita kebab 785: required one-choice groups with bounds and deltas', () {
      final o = BergenProductOptions.fromJson(_fixture('addon_785'));
      expect(o.groups.length, 3);
      for (final g in o.groups) {
        expect(g.single, isTrue);
        expect(g.required, isTrue);
        expect(g.min, 1);
        expect(g.max, 1);
        expect(g.missing(0), isTrue);
        expect(g.missing(1), isFalse);
      }
      expect(o.groups[1].options.first.priceDelta, 30);

      final d = BergenProductDetail.fromJson(_fixture('ops_785'));
      expect(d.priceOre, 16000);
      expect(d.stockMode, 'none');
      expect(d.modifiers.map((m) => m.name), contains('Styrke'));
      expect(d.modifiers[1].options.first.deltaOre, 3000);
    });

    test('a multi-choice group: min, max and a negative delta', () {
      final o = BergenProductOptions.fromJson({
        'status': 1,
        'options_list': [
          {
            'name': 'Tilbehør',
            'selection_type': 2,
            'optional_type': 1,
            'minimum': 0,
            'maximum': 2,
            'options': [
              {'id': 1, 'name': 'Uten løk', 'amount': -5},
              {'id': 2, 'name': 'Ekstra saus', 'amount': 10},
              {'id': 3, 'name': 'Jalapeño', 'amount': 8},
            ],
          },
        ],
      });
      final g = o.groups.single;
      expect(g.single, isFalse);
      expect(g.required, isFalse);
      expect(g.canAdd(1), isTrue);
      expect(g.canAdd(2), isFalse);
      expect(g.options.first.priceDelta, -5);
    });

    test('EU-14 codes map to the user language; freshness wording', () {
      expect(ButikkCopy.a1_butikk_allergen('melk'), isNotEmpty);
      expect(ButikkCopy.a1_butikk_allergen('ukjent-kode'), 'ukjent-kode');
      final now = DateTime(2026, 10, 14, 12);
      expect(
        ButikkCopy.a1_butikk_scr_oppdatert(now.subtract(const Duration(hours: 2)), now: now),
        ButikkCopy.a1_butikk_scr_oppdatert(now.subtract(const Duration(minutes: 125)), now: now),
      );
      expect(ButikkCopy.a1_butikk_scr_oppdatert(now.subtract(const Duration(hours: 2)), now: now), contains('2'));
    });
  });

  group('Klede sheet', () {
    Widget klede(_Api api, {BergenProductOptions? options, BergenProductDetail? detail}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: KledeSheet(
            item: _item(782, 'Dovre Down Jacket', 5800),
            api: api,
            options: options,
            detail: detail,
          ),
        ),
      ),
    );

    testWidgets('782: swatch, sold-out XXL greyed, «1 igjen», web freshness, gallery', (tester) async {
      _frame(tester);
      final o = BergenProductOptions.fromJson(_fixture('addon_782'));
      final d = BergenProductDetail.fromJson(_fixture('ops_782'));
      await tester.pumpWidget(klede(_Api(), options: o, detail: d));
      await tester.pump();

      expect(find.byKey(const Key('a1_butikk_klede_farge_211')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_klede_galleri')), findsOneWidget);
      expect(find.byKey(const Key('a1_butikk_klede_lager_oppdatert')), findsOneWidget);
      expect(find.text('XXL · ${ButikkCopy.a1_butikk_klede_utsolgt}'), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_klede_legg(ButikkCopy.kr(5800))), findsOneWidget);

      // A sold-out size cannot be chosen.
      await tester.tap(find.byKey(const Key('a1_butikk_klede_str_808')));
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_klede_igjen')), findsNothing);

      await tester.tap(find.byKey(const Key('a1_butikk_klede_str_805')));
      await tester.pump();
      expect(find.text(ButikkCopy.a1_butikk_scr_igjen(1)), findsOneWidget);
    });

    testWidgets('unknown stock reads «Lager ikke bekreftet» and stays choosable', (tester) async {
      _frame(tester);
      const o = BergenProductOptions(sizes: [BergenVariant(id: 5, name: 'S', inStock: null)]);
      await tester.pumpWidget(klede(_Api(), options: o));
      await tester.pump();
      expect(find.text('S · ${ButikkCopy.a1_butikk_scr_lager_ukjent}'), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_butikk_klede_str_5')));
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_klede_lager_ukjent')), findsOneWidget);
    });

    testWidgets('a failed read shows the error; «Prøv igjen» loads', (tester) async {
      _frame(tester);
      final api = _Api(opts: BergenProductOptions.fromJson(_fixture('addon_782')), failFirst: 1);
      await tester.pumpWidget(klede(api));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_klede_feil')), findsOneWidget);
      expect(find.text(ButikkCopy.a1_butikk_scr_feil), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_butikk_klede_prov_igjen')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('a1_butikk_klede_feil')), findsNothing);
      expect(find.byKey(const Key('a1_butikk_klede_sheet')), findsOneWidget);
      expect(api.calls, 2);
    });
  });

  group('Produkt sheet', () {
    Widget produkt(_Api api, {BergenProductOptions? options, BergenProductDetail? detail}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ProduktSheet(
            item: _item(785, 'Pita kebab med lam', 160),
            api: api,
            customerApi: _Customer(),
            options: options,
            detail: detail,
          ),
        ),
      ),
    );

    String sum(WidgetTester tester) =>
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.contains('kr'));

    testWidgets('785: required groups default, the price follows the choices', (tester) async {
      _frame(tester);
      final o = BergenProductOptions.fromJson(_fixture('addon_785'));
      final d = BergenProductDetail.fromJson(_fixture('ops_785'));
      await tester.pumpWidget(produkt(_Api(), options: o, detail: d));
      await tester.pump(const Duration(seconds: 1));

      // Required one-choice groups open on their no-extra-cost choice.
      expect(find.textContaining(ButikkCopy.kr(160)), findsWidgets);
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_1799')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(ButikkCopy.kr(190)), findsWidgets);
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_1801')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(ButikkCopy.kr(210)), findsWidgets);
      expect(sum(tester), isNotEmpty);
    });

    testWidgets('a max-2 group refuses a third; a negative delta lowers the price', (tester) async {
      _frame(tester);
      final o = BergenProductOptions.fromJson({
        'status': 1,
        'options_list': [
          {
            'name': 'Tilbehør',
            'selection_type': 2,
            'optional_type': 1,
            'minimum': 0,
            'maximum': 2,
            'options': [
              {'id': 1, 'name': 'Uten løk', 'amount': -5},
              {'id': 2, 'name': 'Ekstra saus', 'amount': 10},
              {'id': 3, 'name': 'Jalapeño', 'amount': 8},
            ],
          },
        ],
      });
      await tester.pumpWidget(produkt(_Api(), options: o, detail: const BergenProductDetail()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(ButikkCopy.a1_butikk_scr_velg_opptil(2)), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_1')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(ButikkCopy.kr(155)), findsWidgets);
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_2')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(ButikkCopy.kr(165)), findsWidgets);
      await tester.tap(find.byKey(const Key('a1_butikk_prod_opt_3')));
      await tester.pump(const Duration(milliseconds: 600));
      // Refused: still 165, not 173.
      expect(find.textContaining(ButikkCopy.kr(173)), findsNothing);
      expect(find.textContaining(ButikkCopy.kr(165)), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('EU-14 codes show as allergens; øre price wins', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        produkt(
          _Api(),
          options: const BergenProductOptions(),
          detail: const BergenProductDetail(priceOre: 17900, allergenCodes: ['gluten', 'melk']),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining(ButikkCopy.a1_butikk_allergen('melk')),
        findsWidgets,
      );
      expect(find.textContaining(ButikkCopy.kr(179)), findsWidgets);
    });

    testWidgets('a failed read shows the error; «Prøv igjen» loads', (tester) async {
      _frame(tester);
      final api = _Api(opts: BergenProductOptions.fromJson(_fixture('addon_785')), failFirst: 1);
      await tester.pumpWidget(produkt(api, detail: const BergenProductDetail()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('a1_butikk_produkt_feil')), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_butikk_produkt_prov_igjen')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('a1_butikk_produkt_feil')), findsNothing);
      expect(find.byKey(const Key('a1_butikk_prod_opt_1799')), findsOneWidget);
      expect(api.calls, 2);
    });
  });
}
