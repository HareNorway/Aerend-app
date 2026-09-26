import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/butikk/butikk_screen.dart';

import '../test/layout/reduced_motion_harness.dart';

/// Device pass for the Butikk page over the local backend (Holy Cow). The
/// test build has no push token, which the legacy add-to-cart requires, so
/// the basket is a stand-in line here.
class _Kasse extends OpsKasseApi {
  @override
  Future<KurvState> cart() async => const KurvState(
    lines: [
      KurvLine(
        cartId: 1,
        productId: 56,
        name: 'Classic Fries',
        quantity: 2,
        unitPrice: 59,
        storeId: 6,
        imageUrl:
            'http://10.224.247.180:8000/assets/images/store-images/product-images/5071714202427115.jpeg',
      ),
    ],
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

  testWidgets('Butikk for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = true;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ButikkScreen(
          storeId: 6,
          name: 'Holy Cow',
          productId: 56,
          kasseApi: _Kasse(),
        ),
      ),
    );
    // The sheet rises over the store page (Søk → a product).
    await _wait(tester, 4500);
    await _hold(tester, 'butikk_sheet');
    await tester.tap(find.byKey(const Key('a1_butikk_produkt_lukk')));
    await _wait(tester, 2500);
    await _hold(tester, 'butikk_top');
    for (var i = 1; i <= 3; i++) {
      await tester.dragFrom(const Offset(200, 650), const Offset(0, -520));
      await _wait(tester, 1400);
      await _hold(tester, 'butikk_s$i');
    }
    if (find
        .byKey(const Key('a1_butikk_kurvbar_toggle'))
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.byKey(const Key('a1_butikk_kurvbar_toggle')));
      await _wait(tester, 900);
      await _hold(tester, 'butikk_mini');
    }
    await _hold(tester, 'butikk_done', 500);
  });
}
