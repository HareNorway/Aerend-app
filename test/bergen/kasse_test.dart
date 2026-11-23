import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/data/ops/fee_quote.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/kasse/bestilling_sheet.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_copy.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_sheets.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_stripe.dart';
import 'package:aerend_customer/screens/bergen/kasse/kjop_sekvens.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_screen.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/deliveryService/checkout/checkout_dl.dart';
import 'package:aerend_customer/services/customer/client_flags.dart';
import 'package:aerend_customer/utils/utils.dart' show languages, prefSetString, prefUserName, prefContactNumber;

import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 5: Kurv's states (empty / filled / pickup / gift), the tip
/// math, the Ægil-added line and Angre, coverage skipped on 404, the 422
/// `PD_OUTSIDE_RADIUS` handling, and Bestillingsdetaljer.
class _FakeKasse extends OpsKasseApi {
  _FakeKasse({this.state = const KurvState(), this.previewPojo, this.addressList = const [], this.placeResponse, this.placeResponses, this.flexPojo});

  KurvState state;
  final OrderPreviewPojo? previewPojo;
  final List<AddressListItem> addressList;
  final Map<String, dynamic>? placeResponse;
  // Customer v2 Step 1: answers in turn (a re-quote retries), the flex preview, and what was sent.
  final List<Map<String, dynamic>?>? placeResponses;
  final OrderPreviewPojo? flexPojo;
  final List<Map<String, dynamic>> places = [];
  final List<bool> previews = [];
  final List<int> removed = [];
  Map<String, dynamic>? lastPlace;

  @override
  Future<KurvState> cart() async => state;
  @override
  Future<OrderPreviewPojo?> preview({bool flex = false, bool? useFreeDelivery}) async {
    previews.add(flex);
    premieSent.add(useFreeDelivery);
    // Points plan Step 4: a ready «Gratis levering» premie, applied unless unticked.
    final p = premie;
    lastFreeDeliveryPremie = p == null ? null : {...p, 'applied': useFreeDelivery != false};
    final pojo = flex ? (flexPojo ?? previewPojo) : previewPojo;
    if (p != null && pojo != null && useFreeDelivery != false) {
      return _preview(delivery: 0, min: pojo.minOrderAmount.toDouble());
    }
    return pojo;
  }

  /// Points plan Step 4: the premie the fake preview offers, and the `use_free_delivery` values it was asked with.
  Map<String, dynamic>? premie;
  final List<bool?> premieSent = [];
  @override
  Future<List<AddressListItem>> addresses() async => addressList;
  @override
  Future<bool> remove(int cartId) async {
    removed.add(cartId);
    state = KurvState(
      lines: [
        for (final l in state.lines)
          if (l.cartId != cartId) l,
      ],
      storeId: state.storeId,
    );
    return true;
  }

  @override
  Future<Map<String, dynamic>?> placeOrder({
    required int storeId,
    required int addressId,
    required int paymentType,
    required bool pickup,
    required List<int> cartIds,
    String note = '',
    String? scheduleDateTime,
    double tip = 0,
    String? quoteId,
    bool flex = false,
    String? companyName,
    String? companyOrgNr,
    bool? useFreeDelivery,
    int? premieLineClaimId,
  }) async {
    lastPlace = {
      'useFreeDelivery': useFreeDelivery,
      'companyName': companyName,
      'companyOrgNr': companyOrgNr,
      'quoteId': quoteId,
      'flex': flex,
      'storeId': storeId,
      'paymentType': paymentType,
      'addressId': addressId,
      'pickup': pickup,
      'note': note,
      'tip': tip,
      'cartIds': cartIds,
    };
    places.add(lastPlace!);
    final queue = placeResponses;
    if (queue != null && queue.isNotEmpty) return queue.removeAt(0);
    return placeResponse;
  }

  @override
  Future<String?> vippsRedirect(int orderId) async => null;
}

/// A quote that takes its time (the T1 phone: «Velg adresse» until `order-preview` answered).
class _SlowKasse extends _FakeKasse {
  _SlowKasse(this.quote, {super.state, super.addressList});

  final Future<OrderPreviewPojo?> quote;

  @override
  Future<OrderPreviewPojo?> preview({bool flex = false, bool? useFreeDelivery}) => quote;
}

class _FakeCustomer extends OpsCustomerApi {
  _FakeCustomer({this.coverageJson, this.referralJson});

  final Map<String, dynamic>? coverageJson;
  final Map<String, dynamic>? referralJson;
  int coverageCalls = 0;
  int codeCalls = 0;

  @override
  Future<Map<String, dynamic>?> coverage(double lat, double lng) async {
    coverageCalls++;
    return coverageJson;
  }

  @override
  Future<Map<String, dynamic>?> requestCode(int orderId) async {
    codeCalls++;
    return {'pin': '1234'};
  }

  @override
  Future<Map<String, dynamic>?> referral() async => referralJson;
}

class _FakeButikk extends OpsButikkApi {
  _FakeButikk(this.info);

  final BergenStoreInfo info;

  @override
  Future<BergenStoreInfo?> store(int storeId, {String? categoryHint}) async => info;
}

KurvLine _line(int id, String name, double price, {int qty = 1, bool aegil = false}) => KurvLine(
  cartId: id,
  productId: id * 10,
  name: name,
  quantity: qty,
  unitPrice: price,
  storeId: 7,
  addedByAegil: aegil,
);

OrderPreviewPojo _preview({double delivery = 39, double min = 150}) =>
    OrderPreviewPojo(status: 1, storeId: 7, storeName: 'Burger King', deliveryCost: delivery, minOrderAmount: min);

/// Customer v2 Step 1: a preview priced by the engine (`fq_…` quote with its lines).
OrderPreviewPojo _quoted(String id, int ore, {bool flex = false}) => _preview(delivery: ore / 100)
  ..feeQuote = FeeQuoteView(
    quoteId: id,
    totalOre: ore,
    flex: flex,
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    lines: [
      const FeeLine(key: 'base', label: 'Grunnpris', amountOre: 3500, detail: 'inkl. 2,0 km'),
      FeeLine(key: 'distance', label: 'Avstand', amountOre: ore - 3500 + (flex ? 1000 : 0), detail: '2,8 km'),
      if (flex) const FeeLine(key: 'flex', label: 'Innen 2 timer', amountOre: -1000, detail: 'fleksibelt leveringsvindu'),
    ],
  );

Map<String, dynamic> _expired(String id, int ore, int before) => {
  'status': 0,
  'error': 'QUOTE_EXPIRED',
  'previous_total_ore': before,
  'quote': {'quote_id': id, 'total_ore': ore, 'components': [{'key': 'base', 'label': 'Grunnpris', 'amount_ore': ore, 'detail': ''}], 'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String()},
};

AddressListItem _address(int id) => AddressListItem.fromJson({
  'address_id': id,
  'type': 'Hjem',
  'address': 'Nygårdsgaten 5, Bergen',
  'lat': '60.39',
  'long': '5.32',
  'flat_no': '3. etasje',
  'landmark': '',
});

Widget _app(Widget child) => MaterialApp(home: child);

/// «Dra for å betale»: drag the knob past 62 % and release.
Future<void> _dragToPay(WidgetTester tester) async {
  final slider = find.byKey(const Key('a1_kasse_betal'));
  final box = tester.getRect(slider);
  await tester.dragFrom(Offset(box.left + 30, box.center.dy), Offset(box.width - 40, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

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

  test('the Phase 5 routes are in the agil-1 map', () {
    expect(bergenRoutesAgil1().keys, containsAll(['/bergen/kurv', '/bergen/bestilling']));
  });

  test('cart json maps lines and the Ægil marker', () {
    final state = KurvState.fromCartJson({
      'status': 1,
      'store_id': 7,
      'count_order': 2,
      'order_list': [
        {
          'id': 1,
          'product_id': 10,
          'product_name': 'Melk',
          'quantity': 2,
          // The API's line total: 2 × 25.
          'product_amount': 50,
          'store_id': 7,
          'snurre_conversation_id': 44,
        },
        {
          'id': 2,
          'product_id': 11,
          'product_name': 'Gyros',
          'quantity': 1,
          // 169 kr with 33.80 kr off: the line total is 135.20 and
          // `discount_amount` is the kroner off, not a price.
          'product_amount': 135.2,
          'discount_amount': 33.8,
          'store_id': 7,
        },
      ],
    });
    expect(state.lines.length, 2);
    expect(state.aegilLines.single.name, 'Melk');
    expect(state.lines[0].unitPrice, 25);
    expect(state.lines[1].unitPrice, 135.2);
    expect(state.subtotal, closeTo(50 + 135.2, 0.001));
  });

  test('the preview fills delivery and the service fee from today\'s keys', () {
    final p = OpsKasseApi.previewFromJson({'status': 1, 'store_id': 7, 'sub_total': 135.2, 'delivery_fee': 39, 'order_fee': 15});
    expect(p.deliveryCost, 39);
    expect(p.taxCost, 15);
    expect(p.totalItemCost, 135.2);
    // A legacy answer keeps its own fields.
    final legacy = OpsKasseApi.previewFromJson({'status': 1, 'store_id': 7, 'delivery_cost': 20, 'tax_cost': 4, 'order_fee': 15});
    expect(legacy.deliveryCost, 20);
    expect(legacy.taxCost, 4);
  });

  test('Betaling ids map to the API payment_type (1 card, 2 Google/Apple Pay, 3 Vipps)', () {
    expect(kasseApiPaymentType(kBetVipps), 3);
    expect(kasseApiPaymentType(kBetKort), 1);
    expect(kasseApiPaymentType(kBetGoogle), 2);
    expect(kasseApiPaymentType(kBetApple), 2);
  });

  test('a slot renders the legacy schedule format', () {
    final slot = KasseSlot(id: 's', label: '18:30', line: '', at: DateTime(2026, 9, 25, 18, 30));
    expect(slot.scheduleDateTime, '2026-09-25 18:30:00');
    expect(const KasseSlot(id: 'asap', label: 'Nå', line: '').scheduleDateTime, isNull);
  });

  testWidgets('empty: the Ægil line and the browse button', (tester) async {
    _frame(tester);
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: _FakeKasse(), customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_tom')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_betal')), findsNothing);
  });

  testWidgets('filled: lines, Endre rows, the summary total with delivery', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(
        lines: [_line(1, 'Dobbel cheeseburger', 149), _line(2, 'Pommes frites', 59, qty: 2)],
        storeId: 7,
      ),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('a1_kasse_linjer')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_rad_adresse')), findsOneWidget);
    expect(find.textContaining('Nygårdsgaten 5'), findsOneWidget);
    // 149 + 118 + 39 delivery = 306
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_total')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '306');
    expect(find.byKey(const Key('a1_kasse_frakt')), findsOneWidget);
  });

  testWidgets('pickup drops the delivery line and the address row changes', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 149)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('a1_kasse_henting')));
    await tester.pump();
    expect(find.text(KasseCopy.a1_kasse_hent_selv), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_total')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_frakt')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '149');
  });


  // ── Design 21 Nov plan Step 2 (A2): the collapsible rows ────────────────────────────────────────────────────────

  Future<void> _tilRad(WidgetTester tester, String key) async {
    await tester.dragUntilVisible(find.byKey(Key(key)), find.byType(ListView).first, const Offset(0, -200));
    await Scrollable.ensureVisible(tester.element(find.byKey(Key(key))), alignment: .1);
    await tester.pump();
  }

  testWidgets('A2: the door row — closed hint, open panel, chips write the note (the exclusive pair), Enter saves', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      // Over the preview's 150 kr minimum, so the slider places the order.
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 1, 'order_id': 4472, 'total_pay': 239},
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await _tilRad(tester, 'a1_kasse_rad_beskjed');
    final chips = KasseCopy.a1_kasse_dor_chips;
    // Closed: the hint line and «Legg til»; the panel takes no height; the receipt has no door card any more.
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_dor_under'))).data, KasseCopy.a1_kasse_dor_under);
    expect(find.text(languages.add), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_dor')).hitTestable(), findsNothing);
    expect(find.byKey(const Key('a1_kasse_dor_kort'), skipOffstage: false), findsNothing);
    expect(find.byKey(const Key('a1_kasse_tips'), skipOffstage: false), findsOneWidget, reason: 'tips always on delivery');

    await tester.tap(find.byKey(const Key('a1_kasse_rad_beskjed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(languages.done), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_dor')).hitTestable(), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('a1_kasse_dor_chip_3'))), alignment: .3);
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_kasse_dor_chip_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_kasse_dor_chip_1')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_dor_under'))).data, '${chips[0]} · ${chips[1]}');
    // «Ikke ring på» pushes «Ring på» out.
    await tester.tap(find.byKey(const Key('a1_kasse_dor_chip_2')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_dor_under'))).data, '${chips[0]} · ${chips[2]}');
    // Tapping a chip that is on removes it.
    await tester.tap(find.byKey(const Key('a1_kasse_dor_chip_0')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_dor_under'))).data, chips[2]);

    // Typing, then Enter: saved, the row closes, «Endre» on the pill, the toast.
    await tester.enterText(find.byKey(const Key('a1_kasse_dor')), '${chips[2]} · 3. etasje ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_dor_under'))).data, '${chips[2]} · 3. etasje');
    expect(find.text(KasseCopy.a1_kasse_dor_lagret), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_dor')).hitTestable(), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('a1_kasse_dor_knapp')), matching: find.text(KasseCopy.a1_kasse_endre)), findsOneWidget);

    // The note rides with the order, plain (no «DØREN» prefix any more). (The toast sits over the pay bar first.)
    await tester.pump(const Duration(seconds: 5));
    await _dragToPay(tester);
    await tester.pump();
    expect(api.lastPlace?['note'], '${chips[2]} · 3. etasje');
  });

  testWidgets('A2: on pickup the store row is «Beskjed og hentetid», opens with Hentetid and the chips, Enter saves; no door row, no tips', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 149)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_kasse_henting')));
    await tester.pump();

    await _tilRad(tester, 'a1_kasse_rad_butikk');
    expect(find.byKey(const Key('a1_kasse_rad_beskjed'), skipOffstage: false), findsNothing);
    expect(find.byKey(const Key('a1_kasse_tips'), skipOffstage: false), findsNothing);
    expect(find.text(KasseCopy.a1_kasse_bk_tittel_hent), findsOneWidget);
    final under = tester.widget<Text>(find.byKey(const Key('a1_kasse_bk_under'))).data!;
    expect(under, startsWith(KasseCopy.a1_kasse_bk_under_tom_hent('').trim().split(' ').first), reason: '«Klar 18:20 · bestikk, poser og annet»');
    expect(find.byKey(const Key('a1_kasse_hentetid_0')).hitTestable(), findsNothing);

    await tester.tap(find.byKey(const Key('a1_kasse_rad_butikk')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('a1_kasse_hentetid_0'))), alignment: .5);
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_hentetid_0')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_kasse_bk_chip_0')));
    await tester.pump();
    final chip0 = KasseCopy.a1_kasse_hent_chips[0];
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_bk_under'))).data, startsWith('$chip0 · '));
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_bk_under'))).data, contains(KasseCopy.a1_kasse_bk_klar('').trim()));

    await tester.enterText(find.byKey(const Key('a1_kasse_bk_felt')), 'Uten løk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(KasseCopy.a1_kasse_bk_lagret('Burger King')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_hentetid_0')).hitTestable(), findsNothing, reason: 'the row closed');
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_bk_under'))).data, contains('«Uten løk»'));
  });

  testWidgets('A2: the address row reads «type · street, flat» over «name · phone»', (tester) async {
    _frame(tester);
    await prefSetString(prefUserName, 'Didrik Hansen');
    await prefSetString(prefContactNumber, '+4741234567');
    addTearDown(() async {
      await prefSetString(prefUserName, '');
      await prefSetString(prefContactNumber, '');
    });
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 149)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Nygårdsgaten 5, 3. etasje'), findsOneWidget);
    expect(find.text('Didrik · 412 34 567'), findsOneWidget);
  });

  testWidgets('the tips card is always there on delivery (Design 21 Nov A2) and a tip adds to the total', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 100)], storeId: 7),
      previewPojo: _preview(delivery: 0),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('a1_kasse_flere'), skipOffstage: false), findsNothing, reason: 'no «Flere valg» since Design 21 Nov');
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_tips_25')),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    // Clear of the pay bar over the list's bottom (the Bedriftskvittering row sits above the tips card).
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('a1_kasse_tips_25'))), alignment: .5);
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_kasse_tips_25')));
    await tester.pump();
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_total')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_tips_rad'), skipOffstage: false), findsOneWidget, reason: 'the receipt has the tip row (above the total; the Bedriftskvittering row moved it out of view)');
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '125');
  });

  testWidgets('the Ægil-added line renders and Angre removes those lines', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(
        lines: [_line(1, 'Burger', 149), _line(2, 'Melk', 25, aegil: true), _line(3, 'Brød', 39, aegil: true)],
        storeId: 7,
      ),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_aegil_linjer')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(find.textContaining('Lagt i kurven av Ægil · Melk, Brød · 64 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_kasse_aegil_angre')));
    await tester.pump();
    await tester.pump();
    expect(api.removed, [2, 3]);
    expect(find.byKey(const Key('a1_kasse_aegil_linjer')), findsNothing);
  });

  testWidgets('coverage is skipped silently when the endpoint answers nothing', (tester) async {
    _frame(tester);
    final customer = _FakeCustomer(coverageJson: null);
    expect(await checkCoverage(customer, _address(5)), isTrue);
    expect(customer.coverageCalls, 1);
    final notCovered = _FakeCustomer(coverageJson: {'covered': false});
    expect(await checkCoverage(notCovered, _address(5)), isFalse);
  });

  testWidgets('a 422 PD_OUTSIDE_RADIUS offers pickup', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 0, 'error': 'PD_OUTSIDE_RADIUS', 'message': 'Butikken leverer ikke hit'},
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(KasseCopy.a1_kasse_utenfor), findsOneWidget);
    await tester.tap(find.text(KasseCopy.a1_kasse_velg_henting));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(KasseCopy.a1_kasse_hent_selv), findsOneWidget);
    expect(api.lastPlace?['pickup'], isFalse);
  });

  testWidgets('a closed store: «Stengt nå · Åpner …» and no order is sent', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Gyros', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 1, 'order_id': 1, 'total_pay': 239},
    );
    final butikk = _FakeButikk(const BergenStoreInfo(
      id: 7, name: 'Gyros House', kind: BergenStoreKind.restaurant, open: false, openTime: '12:30 PM'));
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer(), butikkApi: butikk)));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text(KasseCopy.a1_kasse_stengt_line('12:30')), findsOneWidget);
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.lastPlace, isNull);
    expect(find.text(KasseCopy.a1_kasse_stengt_toast('Gyros House', '12:30')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('T1 ORD-12: a paused store: «Stengt nå · Åpner igjen HH:MM» and no order is sent', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Solbriller', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 1, 'order_id': 1, 'total_pay': 239},
    );
    // Travelmodus: the legacy hours say open all day (00:00–23:59), the pause says closed until 10:19.
    final butikk = _FakeButikk(const BergenStoreInfo(
      id: 7, name: 'Red Sun (Test)', kind: BergenStoreKind.other, open: false, paused: true, reopensAt: '10:19', openTime: '00:00', closeTime: '23:59'));
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer(), butikkApi: butikk)));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text(KasseCopy.a1_kasse_apner_igjen('10:19')), findsOneWidget);
    expect(KasseCopy.a1_kasse_apner_igjen('10:19'), 'Åpner igjen 10:19');
    expect(find.text(KasseCopy.a1_kasse_tid_asap), findsNothing);
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.lastPlace, isNull);
    expect(find.text(KasseCopy.a1_kasse_pause_toast('Red Sun (Test)', '10:19')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the saved address shows before a slow quote is in', (tester) async {
    _frame(tester);
    final quote = Completer<OrderPreviewPojo?>();
    final api = _SlowKasse(
      quote.future,
      state: KurvState(lines: [_line(1, 'Gyros', 200)], storeId: 7),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Nygårdsgaten 5'), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_adr_velg), findsNothing);

    quote.complete(_preview());
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Nygårdsgaten 5'), findsOneWidget);
  });

  testWidgets('back on a pushed Kassen goes back, not to a new store page', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Gyros', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => Text('route ${s.name}')),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer()))),
          child: const Text('butikken'),
        ),
      ),
    ));
    await tester.tap(find.text('butikken'));
    // Kassen animates for ever (the sea), so fixed pumps, not pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.byKey(const Key('a1_kasse_tilbake')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('butikken'), findsOneWidget);
    expect(find.textContaining('route /bergen/butikk'), findsNothing);
  });

  testWidgets('a placed order asks for the code when the toggle is on', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 1, 'order_id': 4471, 'total_pay': 239},
    );
    final customer = _FakeCustomer();
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: customer)));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Design 21 Nov (A2): the code switch lives in the «Beskjed til budet» row's panel.
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_rad_beskjed')),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('a1_kasse_rad_beskjed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_kode_switch')),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    // Clear of the floating slider.
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('a1_kasse_kode_switch'))), alignment: .4);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('a1_kasse_kode_switch')));
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump();
    expect(api.lastPlace?['storeId'], 7);
    expect(api.lastPlace?['paymentType'], 3, reason: 'Vipps is the default method');
    expect(api.lastPlace?['addressId'], 5);
    expect(customer.codeCalls, 1);
  });

  testWidgets('Bestillingsdetaljer shows summary and details', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        BestillingScreen(
          orderId: 4471,
          preloaded: {
            'order_id': '4471',
            'order_no': '4471',
            'code': 'Æ-42K',
            'mode': 'delivery',
            'stage_label': 'Levert',
            'total_pay': 239.0,
            'ordered_at': '2026-09-25T18:11:00+02:00',
            'delivery_address': 'Nygårdsgaten 5',
            'store': {'id': 7, 'name': 'Casa Maria', 'address': 'Bryggen 7, 5003 Bergen'},
            'items': [
              {'name': 'Pizza', 'qty': 2, 'price': 119.5},
            ],
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('a1_kasse_best_sammendrag')), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_best_antall(2)), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_kasse_best_tab_detaljer')));
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_best_ordrenr')), findsOneWidget);
    expect(find.text('Æ-42K'), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_best_kundeservice')), findsOneWidget);
  });

  testWidgets('the referral ticket shows once per order, and not without a code', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showVervebillett(
              context,
              orderId: 9,
              api: _FakeCustomer(
                referralJson: {
                  'referral': {'code': 'DIDRIK-B7', 'points_for_me': 100},
                },
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('DIDRIK-B7'), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_gi_faa(100)), findsOneWidget);
    await tester.tap(find.text(KasseCopy.a1_kasse_lukk));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('DIDRIK-B7'), findsNothing, reason: 'once per order');

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showVervebillett(context, orderId: 10, api: _FakeCustomer()),
            child: const Text('go2'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go2'));
    await tester.pumpAndSettle();
    expect(find.text(KasseCopy.a1_kasse_verv), findsNothing, reason: 'hidden without the referral route');
  });

  testWidgets('Kurv respects reduced motion (filled and empty)', (tester) async {
    _frame(tester);
    await expectRespectsReducedMotion(
      tester,
      () => KurvScreen(
        embedded: false,
        api: _FakeKasse(
          state: KurvState(lines: [_line(1, 'Burger', 149)], storeId: 7),
          previewPojo: _preview(),
          addressList: [_address(5)],
        ),
        customerApi: _FakeCustomer(),
      ),
    );
    await expectRespectsReducedMotion(
      tester,
      () => KurvScreen(embedded: false, api: _FakeKasse(), customerApi: _FakeCustomer()),
    );
  });

  testWidgets('Betalt: the paid sum and «Ægil gjør seg klar» rise in', (tester) async {
    _frame(tester);
    await tester.pumpWidget(_app(KjopBekreftetScreen(orderId: 42, sum: 307, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text(KasseCopy.a1_kasse_betalt_sum('307')), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_gjor_klar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Betaling lists the methods and returns the picked one', (tester) async {
    _frame(tester);
    int? valgt;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => valgt = await showBetalingSheet(context, selected: kBetVipps),
            child: const Text('åpne'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('a1_kasse_betaling_sheet')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_bet_$kBetVipps')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_bet_$kBetKort')), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_kasse_bet_$kBetKort')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(valgt, kBetKort);
  });

  testWidgets('Levering: a time and «Bruk dette» come back', (tester) async {
    _frame(tester);
    KasseSlot? valgt;
    bool? henting;
    const slots = [
      KasseSlot(id: 'asap', label: 'Så fort som mulig', line: 'Innen 18:15 · 25–35 min'),
      KasseSlot(id: 'slot1', label: '18:30', line: 'Budet venter'),
    ];
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => valgt = await showLeveringSheet(
              context,
              slots: slots,
              pickup: false,
              onModeChanged: (m) => henting = m,
            ),
            child: const Text('åpne'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('a1_kasse_slot_slot1')));
    await tester.tap(find.byKey(const Key('a1_kasse_ark_henting')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('a1_kasse_bruk_dette')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(valgt?.id, 'slot1');
    expect(henting, isTrue);
  });

  // Design 21 Nov plan Step 3 (A3).
  testWidgets('A3: the Levering sheet — sub-line per mode, radio cards, the pill names the time, the close key', (tester) async {
    _frame(tester);
    final slots = [
      const KasseSlot(id: 'asap', label: 'Så fort som mulig', line: 'Innen 18:15 · 25–35 min'),
      KasseSlot(id: 'slot1', label: '18:30', line: 'Budet venter', at: DateTime(2026, 11, 22, 18, 30)),
      KasseSlot(id: 'slot2', label: '19:30', line: 'Etter Fløibanen', at: DateTime(2026, 11, 22, 19, 30)),
    ];
    KasseSlot? valgt;
    var lukket = 0;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          valgt = await showLeveringSheet(context, slots: slots, pickup: false, onModeChanged: (_) {});
          lukket++;
        },
        child: const Text('åpne'),
      ),
    )));
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(KasseCopy.a1_kasse_lev_sub_lev), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_bekreft_lev(KasseCopy.a1_kasse_snarest)), findsOneWidget);
    expect(find.text('Innen 18:15 · 25–35 min'), findsOneWidget);
    // Three radio cards in one group, the first checked.
    final d0 = tester.getSemantics(find.byKey(const Key('a1_kasse_slot_asap'))).getSemanticsData();
    expect([d0.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup), d0.hasFlag(SemanticsFlag.isChecked)], [true, true]);
    expect(tester.getSize(find.byKey(const Key('a1_kasse_slot_slot1'))).height, greaterThanOrEqualTo(64));

    await tester.tap(find.byKey(const Key('a1_kasse_slot_slot1')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(KasseCopy.a1_kasse_bekreft_lev('18:30')), findsOneWidget);
    // Henting: the sub-line and the pickup lines change, the pill says henting.
    await tester.tap(find.byKey(const Key('a1_kasse_ark_henting')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(KasseCopy.a1_kasse_lev_sub_hent), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_tid_klar_ca('18:15')), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_hent_middag_line), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_bekreft_hent('18:30')), findsOneWidget);
    // The close key leaves without a choice.
    await tester.tap(find.byKey(const Key('a1_kasse_ark_lukk')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(lukket, 1);
    expect(valgt, isNull);
    expect(find.byKey(const Key('a1_kasse_levering_sheet')), findsNothing);
  });

  testWidgets('A3: the Betaling sheet is dark, with radio cards and the phone under Vipps; a tap picks and closes', (tester) async {
    _frame(tester);
    await prefSetString(prefContactNumber, '41234567');
    addTearDown(() => prefSetString(prefContactNumber, ''));
    int? valgt;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => valgt = await showBetalingSheet(context, selected: kBetKort),
        child: const Text('åpne'),
      ),
    )));
    await tester.tap(find.text('åpne'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(KasseCopy.a1_kasse_bet_sheet_title), findsOneWidget);
    expect(find.text('412 34 567'), findsOneWidget);
    final dk = tester.getSemantics(find.byKey(const Key('a1_kasse_bet_$kBetKort'))).getSemanticsData();
    expect([dk.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup), dk.hasFlag(SemanticsFlag.isChecked)], [true, true]);
    final dv = tester.getSemantics(find.byKey(const Key('a1_kasse_bet_$kBetVipps'))).getSemanticsData();
    expect(dv.hasFlag(SemanticsFlag.isChecked), isFalse);
    // The dark sheet: white title.
    final t = tester.widget<Text>(find.text(KasseCopy.a1_kasse_bet_sheet_title));
    expect(t.style?.color, Colors.white);
    await tester.tap(find.byKey(const Key('a1_kasse_bet_$kBetVipps')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(valgt, kBetVipps);
    expect(find.byKey(const Key('a1_kasse_betaling_sheet')), findsNothing);
  });

  // ── Customer v2 Step 1: the fee quote ─────────────────────────────────

  testWidgets('the fee row opens the engine\'s lines, and the order carries the quote', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _quoted('fq_a', 4100),
      addressList: [_address(5)],
      placeResponse: {'status': 0, 'message': 'stop here'},
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.dragUntilVisible(find.byKey(const Key('a1_kasse_frakt')), find.byType(ListView).first, const Offset(0, -200));
    // Above the pay slider, which covers the bottom of the list.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1_kasse_frakt')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('fee_breakdown_sheet')), findsOneWidget);
    expect(find.text('Grunnpris'), findsOneWidget);
    expect(find.text('Avstand'), findsOneWidget);
    expect(find.text('6 kr'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 600));

    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.lastPlace?['quoteId'], 'fq_a');
    expect(api.lastPlace?['flex'], isFalse);
  });

  testWidgets('a quote that ran out at a lower or equal fee is used at once', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _quoted('fq_old', 4100),
      addressList: [_address(5)],
      placeResponses: [_expired('fq_new', 4100, 4100), {'status': 0, 'message': 'stop here'}],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.places.map((p) => p['quoteId']).toList(), ['fq_old', 'fq_new']);
    expect(find.textContaining('Ny total'), findsNothing);
  });

  testWidgets('a higher fee after the quote ran out is confirmed first («Ny total»)', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _quoted('fq_old', 4100),
      addressList: [_address(5)],
      placeResponses: [_expired('fq_new', 4900, 4100), {'status': 0, 'message': 'stop here'}],
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Ny total'), findsOneWidget);
    expect(api.places, hasLength(1), reason: 'nothing more is sent before the customer confirms');
    await tester.tap(find.textContaining('Betal 249'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.places.map((p) => p['quoteId']).toList(), ['fq_old', 'fq_new']);
  });

  testWidgets('an address the engine does not cover offers pickup and the waitlist', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _quoted('fq_a', 4100),
      addressList: [_address(5)],
      placeResponse: {'status': 0, 'error': 'OUT_OF_COVERAGE', 'message': 'Utenfor'},
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Vi leverer ikke hit ennå'), findsOneWidget);
    expect(find.text('Sett meg på ventelisten'), findsOneWidget);
    await tester.tap(find.text(KasseCopy.a1_kasse_velg_henting));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(KasseCopy.a1_kasse_hent_selv), findsOneWidget);
  });

  testWidgets('«Innen 2 timer» with the flex flag: the engine\'s discount, and the order asks for the flex quote', (tester) async {
    _frame(tester);
    ClientFlags.flags = {'pricing.flex_window': true};
    addTearDown(() => ClientFlags.flags = {});
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _quoted('fq_a', 4100),
      flexPojo: _quoted('fq_flex', 3100, flex: true),
      addressList: [_address(5)],
      placeResponse: {'status': 0, 'message': 'stop here'},
    );
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(api.previews, contains(true), reason: 'the flex price is fetched for the sheet');
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pump();
    await tester.tap(find.descendant(of: find.byKey(const Key('a1_kasse_rad_tid')), matching: find.text(KasseCopy.a1_kasse_endre)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Innen 2 timer'), findsOneWidget);
    expect(find.textContaining('−10 kr'), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_kasse_slot_flex')));
    await tester.tap(find.byKey(const Key('a1_kasse_bruk_dette')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.lastPlace?['quoteId'], 'fq_flex');
    expect(api.lastPlace?['flex'], isTrue);
  });

  testWidgets('points plan Step 4: a ready «Gratis levering» premie makes delivery 0, and the switch keeps it for later', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Dobbel cheeseburger', 149), _line(2, 'Pommes frites', 59, qty: 2)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    )..premie = {'claim_id': 31, 'name': 'Gratis levering', 'covers': 39};
    await tester.pumpWidget(_app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.dragUntilVisible(find.byKey(const Key('a1_kasse_total')), find.byType(ListView).first, const Offset(0, -300));
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_premie')), findsOneWidget);
    expect(find.text(KasseCopy.a1_kasse_premie), findsOneWidget);
    expect(find.text('−39 kr'), findsOneWidget);
    // 149 + 118, delivery 0 with the premie.
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '267');
    expect(api.premieSent.last, isTrue);

    // Keep it for later: the fee is charged and the request says so.
    await tester.tap(find.byKey(const Key('a1_kasse_premie_bryter')));
    await tester.pump();
    await tester.pump();
    expect(api.premieSent.last, isFalse);
    expect(find.text(KasseCopy.a1_kasse_premie_av), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '306');
  });
}
