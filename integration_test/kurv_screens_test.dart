import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/kasse/kurv_screen.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/screens/deliveryService/checkout/checkout_dl.dart';

import '../test/layout/reduced_motion_harness.dart';

/// Device pass for Kurv: the prototype's cart (Fiskesuppe 1 × 179,
/// Kanelboller 2 × 89) held filled, with Flere valg open, in pickup, and
/// empty, each announced through a marker file for the host screenshot.
class _Kasse extends OpsKasseApi {
  _Kasse(this.state);
  KurvState state;
  @override
  Future<KurvState> cart() async => state;
  @override
  Future<OrderPreviewPojo?> preview() async => OrderPreviewPojo(status: 1, storeId: 7, storeName: 'Burger King', storeAddress: 'Bryggen 7, Bergen', deliveryCost: 0, minOrderAmount: 0);
  @override
  Future<List<AddressListItem>> addresses() async => [
    AddressListItem.fromJson({'address_id': 5, 'type': 'Hjem', 'address': 'Nygårdsgaten 5, Bergen', 'lat': '60.39', 'long': '5.32', 'flat_no': '3. etasje', 'landmark': '«Ring på hos Didrik»'}),
  ];
}

KurvLine _l(int id, String n, double p, int q) => KurvLine(cartId: id, productId: id * 10, name: n, quantity: q, unitPrice: p, storeId: 7);

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

  testWidgets('Kurv states for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    final api = _Kasse(KurvState(lines: [_l(1, 'Fiskesuppe, 2 porsjoner', 179, 1), _l(2, 'Kanelboller, 6 stk', 89, 2)], storeId: 7));
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: KurvScreen(embedded: false, api: api)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1800)));
    await _hold(tester, 'kurv_filled');

    await tester.tap(find.byKey(const Key('a1_kasse_flere')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 500));
    await _hold(tester, 'kurv_flere');

    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('a1_kasse_henting')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 500));
    await _hold(tester, 'kurv_henting');

    api.state = const KurvState();
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, home: KurvScreen(key: const ValueKey('tom'), embedded: false, api: api)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1500)));
    await _hold(tester, 'kurv_tom');
    await _hold(tester, 'kurv_done', 500);
  });
}
