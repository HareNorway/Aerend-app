import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/ops/kasse_models.dart';
import 'package:aerend_customer/data/points/points_rules.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/networking/ops/ops_kasse_api.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_guide.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_launch_copy.dart';
import 'package:aerend_customer/screens/bergen/aegil/aegil_screen.dart';
import 'package:aerend_customer/screens/bergen/hurtig/hurtig_data.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';

import '../a3/a3_fakes.dart';

/// Assistant cost plan Step 6: the app's chips carry their intent id, every
/// turn sends the screen and the session the server gave, and a server reply
/// takes a thumb (only when the server says thumbs are on).

class _Kasse extends OpsKasseApi {
  @override
  Future<KurvState> cart() async => const KurvState();
}

class _Kunde extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<PointsRules?> rules() async => null;
}

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(FakeAegilApi api, {Map<String, String> args = const {}}) => MaterialApp(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    settings: RouteSettings(name: '/', arguments: args),
    builder: (_) => AegilScreen(api: api, repo: FakeAegilRepo(), steg: 'start', kasseApi: _Kasse(), customerApi: _Kunde()),
  ),
);

Future<void> _skriv(WidgetTester tester, String t) async {
  await tester.enterText(find.byKey(const Key('a1_aegil_felt')), t);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 1500));
}

const _svar = AegilTurn(state: 'agSvar', reply: 'Jeg kan finne varer og svare om bestillinger.', sessionId: 7, turnId: 42, tier: 0, feedback: true);

void main() {
  setUpAll(() async {
    await a3Bootstrap(prefs: {'flutter.${AegilScreen.prefTillatelse}': true, AegilScreen.prefTillatelse: true});
    OpsCustomerApi.networkEnabled = false;
  });

  setUp(() {
    A3Services.points = () => FakePointsApi();
    HurtigKilde.memory = () async => const <MemoryEntry>[];
    AegilGuide.reset();
  });

  tearDown(() {
    A3Services.reset();
    HurtigKilde.reset();
  });

  test('the app chips map to intent ids; other words have none', () {
    expect(aegilChipId(AeCopy.chipHjelp), 'what_can_you_do');
    expect(aegilChipId(AeCopy.chipGave), 'gift');
    expect(aegilChipId(AeCopy.chipBillig), 'cheapest_near');
    expect(aegilChipId(AeCopy.chipSulten), 'hungry');
    expect(aegilChipId(AeCopy.chipTaco), 'taco_night');
    expect(aegilChipId('Vis meg andre fiskeretter'), isNull);
  });

  testWidgets('the turn sends chip id and screen, keeps the session, and the reply takes one thumb', (tester) async {
    _frame(tester);
    final api = FakeAegilApi(turn: _svar);
    await tester.pumpWidget(_app(api));
    await tester.pump(const Duration(milliseconds: 800));

    await _skriv(tester, AeCopy.chipSulten);
    expect(api.meta.single, {'chip_id': 'hungry', 'screen': 'aegil', 'session_id': null});

    await _skriv(tester, 'Har dere reker?');
    expect(api.meta.last, {'chip_id': null, 'screen': 'aegil', 'session_id': 7}, reason: 'the server\'s session goes back');

    final opp = find.byKey(const Key('ae-tommel-opp'));
    expect(opp, findsWidgets);
    await tester.ensureVisible(opp.last);
    await tester.tap(opp.last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.thumbs, ['42:up']);
    expect(find.text('Takk'), findsOneWidget);
    expect(find.byKey(const Key('ae-tommel-ned')), findsWidgets, reason: 'the first reply still has its own two');
  });

  testWidgets('no thumbs when the server has them off; a tracking view sends its screen', (tester) async {
    _frame(tester);
    final api = FakeAegilApi(turn: const AegilTurn(state: 'agSvar', reply: 'Den er på vei.', turnId: 9));
    await tester.pumpWidget(_app(api, args: {'order_id': '55', 'order': 'Æ-5T5'}));
    await tester.pump(const Duration(milliseconds: 800));

    await _skriv(tester, 'Når kommer den?');
    expect(api.meta.single['screen'], 'sporing');
    expect(find.byKey(const Key('ae-tommel-opp')), findsNothing);
  });
}
