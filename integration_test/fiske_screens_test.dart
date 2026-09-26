import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/data/ops/fiske_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_game.dart';
import 'package:aerend_customer/screens/bergen/fiske/fjordfiske_screen.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_kit.dart';

import '../test/a3/a3_fakes.dart';
import '../test/layout/reduced_motion_harness.dart';

/// Device pass for Fjordfiske: drives the screen through idle → cast → bite →
/// catch card → prize card on the simulator with the test fakes, holding each
/// state so the host can screenshot it (`xcrun simctl io … screenshot`).
/// Prints `FISKE_STATE <name>` when a state is on screen.
///
///   flutter test integration_test/fiske_screens_test.dart -d <simulator>
class _FakeOps extends OpsCustomerApi {
  @override
  Future<FiskeDay?> fiske() async =>
      const FiskeDay(today: 0, max: 5, left: 5, capped: false);
}

const _s1 = Suggestion(
  id: 11,
  reasonCode: 'offer',
  reason: 'Tilbud hos Nordnes Fisk',
  headline: 'Fiskesuppe, 2 porsjoner',
  storeId: 3,
  storeProductId: 77,
  category: 'Fisk',
);
const _s2 = Suggestion(
  id: 12,
  reasonCode: 'rhythm',
  reason: 'Torsdag er bolledag',
  headline: 'Kanelboller, 6 stk',
  storeId: 4,
  storeProductId: 78,
  category: 'Bakeri',
);

Future<BergenStoreInfo?> _store(int id) async => BergenStoreInfo(
  id: id,
  name: id == 3 ? 'Nordnes Fisk' : 'Sandviken Bakeri',
  kind: BergenStoreKind.other,
  deliveryMinutes: 30,
  menu: const [
    BergenMenuCategory(
      id: 1,
      name: 'Alt',
      items: [
        BergenMenuItem(id: 77, name: 'Fiskesuppe', storeId: 3, storeName: 'Nordnes Fisk', price: 179),
        BergenMenuItem(id: 78, name: 'Kanelboller', storeId: 4, storeName: 'Sandviken Bakeri', price: 89),
      ],
    ),
  ],
);

/// Holds [state] on screen for [ms] and tells the host: stdout is buffered by
/// the tool, so the marker is also a file in the app's Documents folder, which
/// the simulator keeps on the host disk.
Future<void> _hold(WidgetTester tester, String state, [int ms = 5000]) async {
  await tester.pump();
  debugPrint('FISKE_STATE $state');
  await tester.runAsync(() async {
    final dir = await getApplicationDocumentsDirectory();
    File('${dir.path}/fiske_state.txt').writeAsStringSync(state);
    await Future<void>.delayed(Duration(milliseconds: ms));
  });
  await tester.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Fjordfiske states for the device pass', (tester) async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FjordfiskeScreen(
          points: FakePointsApi(),
          aegil: FakeAegilApi(suggestionValue: const [_s1, _s2]),
          customerApi: _FakeOps(),
          storeLookup: _store,
          weather: BergenWeatherLook.regn,
          rules: const FiskePrizeRules(everyN: 2, max: 3, fromCast: 2),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await _hold(tester, 'idle');

    await tester.tap(find.byKey(const Key('a1_fiske_kast')));
    await tester.pump(const Duration(milliseconds: 300));
    await _hold(tester, 'cast', 2500);

    for (var waited = 0; waited < 4000; waited += 100) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('a1_fiske_dra')).evaluate().isNotEmpty) break;
    }
    await _hold(tester, 'bite', 1300);
    await tester.tap(find.byKey(const Key('a1_fiske_dra')));
    await tester.pump(const Duration(milliseconds: 900));
    await _hold(tester, 'catch');

    await tester.tap(find.byKey(const Key('a1_fiske_lagre')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('a1_fiske_kast')));
    for (var waited = 0; waited < 4000; waited += 100) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('a1_fiske_dra')).evaluate().isNotEmpty) break;
    }
    await tester.tap(find.byKey(const Key('a1_fiske_dra')));
    await tester.pump(const Duration(milliseconds: 900));
    await _hold(tester, 'prize');
    await _hold(tester, 'done', 500);
  });
}
