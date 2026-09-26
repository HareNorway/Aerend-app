import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/kasse/bestilling_sheet.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_copy.dart';
import 'package:aerend_customer/screens/bergen/kasse/kasse_sheets.dart';
import 'package:aerend_customer/screens/bergen/kasse/kjop_sekvens.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_screen.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/deliveryService/checkout/checkout_dl.dart';

import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 5: Kurv's states (empty / filled / pickup / gift), the tip
/// math, the Ægil-added line and Angre, coverage skipped on 404, the 422
/// `PD_OUTSIDE_RADIUS` handling, and Bestillingsdetaljer.
class _FakeKasse extends OpsKasseApi {
  _FakeKasse({
    this.state = const KurvState(),
    this.previewPojo,
    this.addressList = const [],
    this.placeResponse,
  });

  KurvState state;
  final OrderPreviewPojo? previewPojo;
  final List<AddressListItem> addressList;
  final Map<String, dynamic>? placeResponse;
  final List<int> removed = [];
  Map<String, dynamic>? lastPlace;

  @override
  Future<KurvState> cart() async => state;
  @override
  Future<OrderPreviewPojo?> preview() async => previewPojo;
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
  }) async {
    lastPlace = {
      'storeId': storeId,
      'addressId': addressId,
      'pickup': pickup,
      'note': note,
      'tip': tip,
      'cartIds': cartIds,
    };
    return placeResponse;
  }

  @override
  Future<String?> vippsRedirect(int orderId) async => null;
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

KurvLine _line(
  int id,
  String name,
  double price, {
  int qty = 1,
  bool aegil = false,
}) => KurvLine(
  cartId: id,
  productId: id * 10,
  name: name,
  quantity: qty,
  unitPrice: price,
  storeId: 7,
  addedByAegil: aegil,
);

OrderPreviewPojo _preview({double delivery = 39, double min = 150}) =>
    OrderPreviewPojo(
      status: 1,
      storeId: 7,
      storeName: 'Burger King',
      deliveryCost: delivery,
      minOrderAmount: min,
    );

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
    expect(
      bergenRoutesAgil1().keys,
      containsAll(['/bergen/kurv', '/bergen/bestilling']),
    );
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
          'product_amount': 25,
          'store_id': 7,
          'snurre_conversation_id': 44,
        },
        {
          'id': 2,
          'product_id': 11,
          'product_name': 'Burger',
          'quantity': 1,
          'product_amount': 149,
          'discount_amount': 129,
          'store_id': 7,
        },
      ],
    });
    expect(state.lines.length, 2);
    expect(state.aegilLines.single.name, 'Melk');
    expect(state.lines[1].unitPrice, 129);
    expect(state.subtotal, 50 + 129);
  });

  test('a slot renders the legacy schedule format', () {
    final slot = KasseSlot(
      id: 's',
      label: '18:30',
      line: '',
      at: DateTime(2026, 9, 25, 18, 30),
    );
    expect(slot.scheduleDateTime, '2026-09-25 18:30:00');
    expect(
      const KasseSlot(id: 'asap', label: 'Nå', line: '').scheduleDateTime,
      isNull,
    );
  });

  testWidgets('empty: the Ægil line and the browse button', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        KurvScreen(
          embedded: false,
          api: _FakeKasse(),
          customerApi: _FakeCustomer(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('a1_kasse_tom')), findsOneWidget);
    expect(find.byKey(const Key('a1_kasse_betal')), findsNothing);
  });

  testWidgets('filled: lines, Endre rows, the summary total with delivery', (
    tester,
  ) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(
        lines: [
          _line(1, 'Dobbel cheeseburger', 149),
          _line(2, 'Pommes frites', 59, qty: 2),
        ],
        storeId: 7,
      ),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(
      _app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())),
    );
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

  testWidgets('pickup drops the delivery line and the address row changes', (
    tester,
  ) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 149)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(
      _app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())),
    );
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

  testWidgets(
    'Flere valg opens the tips card and a tip adds to the total',
    (tester) async {
      _frame(tester);
      final api = _FakeKasse(
        state: KurvState(lines: [_line(1, 'Burger', 100)], storeId: 7),
        previewPojo: _preview(delivery: 0),
        addressList: [_address(5)],
      );
      await tester.pumpWidget(
        _app(
          KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.dragUntilVisible(
        find.byKey(const Key('a1_kasse_flere')),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('a1_kasse_flere')));
      await tester.pump();
      await tester.dragUntilVisible(
        find.byKey(const Key('a1_kasse_tips_25')),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('a1_kasse_tips_25')));
      await tester.pump();
      await tester.dragUntilVisible(
        find.byKey(const Key('a1_kasse_total')),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.byKey(const Key('a1_kasse_tips_rad')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('a1_kasse_total'))).data, '125');

    },
  );

  testWidgets('the Ægil-added line renders and Angre removes those lines', (
    tester,
  ) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(
        lines: [
          _line(1, 'Burger', 149),
          _line(2, 'Melk', 25, aegil: true),
          _line(3, 'Brød', 39, aegil: true),
        ],
        storeId: 7,
      ),
      previewPojo: _preview(),
      addressList: [_address(5)],
    );
    await tester.pumpWidget(
      _app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_aegil_linjer')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(
      find.textContaining('Lagt i kurven av Ægil · Melk, Brød · 64 kr'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('a1_kasse_aegil_angre')));
    await tester.pump();
    await tester.pump();
    expect(api.removed, [2, 3]);
    expect(find.byKey(const Key('a1_kasse_aegil_linjer')), findsNothing);
  });

  testWidgets(
    'coverage is skipped silently when the endpoint answers nothing',
    (tester) async {
      _frame(tester);
      final customer = _FakeCustomer(coverageJson: null);
      expect(await checkCoverage(customer, _address(5)), isTrue);
      expect(customer.coverageCalls, 1);
      final notCovered = _FakeCustomer(coverageJson: {'covered': false});
      expect(await checkCoverage(notCovered, _address(5)), isFalse);
    },
  );

  testWidgets('a 422 PD_OUTSIDE_RADIUS offers pickup', (tester) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {
        'status': 0,
        'error': 'PD_OUTSIDE_RADIUS',
        'message': 'Butikken leverer ikke hit',
      },
    );
    await tester.pumpWidget(
      _app(KurvScreen(embedded: false, api: api, customerApi: _FakeCustomer())),
    );
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

  testWidgets('a placed order asks for the code when the toggle is on', (
    tester,
  ) async {
    _frame(tester);
    final api = _FakeKasse(
      state: KurvState(lines: [_line(1, 'Burger', 200)], storeId: 7),
      previewPojo: _preview(),
      addressList: [_address(5)],
      placeResponse: {'status': 1, 'order_id': 4471, 'total_pay': 239},
    );
    final customer = _FakeCustomer();
    await tester.pumpWidget(
      _app(KurvScreen(embedded: false, api: api, customerApi: customer)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_flere')),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('a1_kasse_flere')));
    await tester.pump();
    await tester.dragUntilVisible(
      find.byKey(const Key('a1_kasse_kode_switch')),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    // Clear the floating slider.
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('a1_kasse_kode_switch')));
    await tester.pump();
    await _dragToPay(tester);
    await tester.pump();
    expect(api.lastPlace?['storeId'], 7);
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
            'store': {
              'id': 7,
              'name': 'Casa Maria',
              'address': 'Bryggen 7, 5003 Bergen',
            },
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

  testWidgets(
    'the referral ticket shows once per order, and not without a code',
    (tester) async {
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
              onPressed: () =>
                  showVervebillett(context, orderId: 10, api: _FakeCustomer()),
              child: const Text('go2'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go2'));
      await tester.pumpAndSettle();
      expect(
        find.text(KasseCopy.a1_kasse_verv),
        findsNothing,
        reason: 'hidden without the referral route',
      );
    },
  );

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
}
