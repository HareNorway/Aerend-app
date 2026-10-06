import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_cards.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_game.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_ui.dart';
import 'package:aerend_customer/screens/bergen/fiske/fjordfiske_screen.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_nav.dart';

import '../a3/a3_fakes.dart';
import '../layout/reduced_motion_harness.dart';

/// Launch UI Step 10: Fjordfiske's Launch layers — the nav with no tab lit,
/// the bait rail's discs and badges, the teal catch card's facts, the
/// waiting pill and «DRA INN!» with its time line.

class _Ops extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> poser() async => const [];
}

const _fisk = Suggestion(id: 1, reasonCode: 'offer', reason: 'Tilbud', headline: 'Reker', storeId: 3, storeProductId: 77, category: 'Fisk');
const _bakst = Suggestion(id: 2, reasonCode: 'rhythm', reason: 'Bolledag', headline: 'Kanelboller', storeId: 4, category: 'Bakeri');

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
  });

  testWidgets('the screen carries the nav (no tab lit) and the bait rail with counts', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: FjordfiskeScreen(
          points: FakePointsApi(),
          aegil: FakeAegilApi(suggestionValue: const [_fisk, _bakst]),
          customerApi: _Ops(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final nav = tester.widget<BergenBottomNav>(find.byType(BergenBottomNav));
    expect(nav.index, -1);
    expect(find.byKey(const Key('a1_fiske_agn_alle')), findsOneWidget);
    // «Alle» counts both, «Mat & fisk» and «Bakeri» one each.
    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const Key('a1_fiske_kast')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the catch card shows name, shop, price, ETA and the bydel', (tester) async {
    _frame(tester);
    const item = FiskeCatch(suggestion: _fisk, name: 'Reker, 500 g', storeName: 'Torgboden', priceKr: 149, bydel: 'Nordnes', eta: 'Innen 18:15');
    await tester.pumpWidget(_app(const Center(child: FiskeLFangstKort(item: item, earned: 5))));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Reker, 500 g'), findsOneWidget);
    expect(find.text('Torgboden'), findsOneWidget);
    expect(find.text('149 kr'), findsOneWidget);
    expect(find.text('Innen 18:15'), findsOneWidget);
    expect(find.text('Nordnes'), findsOneWidget);
    expect(find.byKey(const Key('a1_fiske_plus')), findsOneWidget);
    expect(find.byKey(const Key('a1_fiske_napp_badge')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('waiting pill and DRA INN! render; the rail lifts the chosen bait', (tester) async {
    _frame(tester);
    var dratt = 0;
    var valgt = FiskeAgn.alle;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FiskeLVenter(),
              const SizedBox(height: 30),
              FiskeLDraInn(onTap: () => dratt++),
              const SizedBox(height: 30),
              SizedBox(
                width: 390,
                height: 80,
                child: FiskeLAgnRail(selected: valgt, count: (a) => a == FiskeAgn.alle ? 3 : 1, onSelect: (a) => set(() => valgt = a)),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('a1_fiske_venter')), findsOneWidget);
    await tester.tap(find.byKey(const Key('a1_fiske_dra')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(dratt, 1);
    await tester.tap(find.byKey(const Key('a1_fiske_agn_mote')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(valgt, FiskeAgn.mote);
    await tester.pumpWidget(const SizedBox());
  });
}
