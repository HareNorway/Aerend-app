import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/data/ops/sok_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/bergen_routes_agil1.dart';
import 'package:aerend_customer/screens/bergen/sok/sok_screen.dart';

import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 3: Søk's four states, trending falling back to empty on
/// failure, recent searches in local storage, and the wish rule.
class _FakeApi extends OpsCustomerApi {
  _FakeApi({
    this.terms = const [],
    this.missionPayload,
    this.treff = const SokTreff(),
    this.trendingFails = false,
  });

  final List<String> terms;
  final Map<String, dynamic>? missionPayload;
  final SokTreff treff;
  final bool trendingFails;
  final List<String> searched = [];

  @override
  Future<List<String>> trending() async => trendingFails ? const [] : terms;

  @override
  Future<Map<String, dynamic>?> mission() async => missionPayload;

  @override
  Future<SokTreff> search(String query, {double? lat, double? lng}) async {
    searched.add(query);
    return treff;
  }
}

Widget _app(Widget child) => MaterialApp(home: child);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(bootstrapGlobals);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await bootstrapGlobals();
  });

  test('the wish rule: four words, a question, or an errand word', () {
    expect(SokScreen.isWish('sushi'), isFalse);
    expect(SokScreen.isWish('tacokveld for fire under 500 kr'), isTrue);
    expect(SokScreen.isWish('reker under 100 kr'), isTrue);
    expect(SokScreen.isWish('finnes det reker?'), isTrue);
    expect(SokScreen.isWish('kanelboller'), isFalse);
  });

  test('/bergen/sok is in the agil-1 route map', () {
    expect(bergenRoutesAgil1().containsKey('/bergen/sok'), isTrue);
  });

  testWidgets('empty state: Spør Ægil card, categories, trending, mission', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        SokScreen(
          api: _FakeApi(
            terms: ['fiskesuppe', 'kanelboller'],
            missionPayload: {
              'mission': {
                'title': 'Prøv Nordnes Fisk',
                'body': 'Én bestilling teller.',
                'points': 50,
              },
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('a1_sok_title')), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_aegil_card')), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_populaert')), findsOneWidget);
    expect(find.text('fiskesuppe'), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_oppdrag')), findsOneWidget);
    expect(find.text('Prøv Nordnes Fisk'), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_nylig')), findsNothing);
  });

  testWidgets('trending and the mission fall back to hidden', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(SokScreen(api: _FakeApi(trendingFails: true))),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('a1_sok_populaert')), findsNothing);
    expect(find.byKey(const Key('a1_sok_oppdrag')), findsNothing);
  });

  testWidgets('a wish shows the banner and does not search', (tester) async {
    _frame(tester);
    final api = _FakeApi();
    await tester.pumpWidget(_app(SokScreen(api: api)));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('a1_sok_field')),
      'tacokveld for fire under 500 kr',
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('a1_sok_onske')), findsOneWidget);
    expect(api.searched, isEmpty);
    expect(find.byKey(const Key('a1_sok_aegil_card')), findsNothing);
  });

  testWidgets('hits render shops and products with the compare footer', (
    tester,
  ) async {
    _frame(tester);
    final api = _FakeApi(
      treff: const SokTreff(
        butikker: [
          SokButikk(id: 4, name: 'Nordnes Fisk', etaMinutes: 25, rating: '4,8'),
        ],
        produkter: [
          SokProdukt(
            id: 9,
            name: 'Fiskesuppe',
            storeId: 4,
            storeName: 'Nordnes Fisk',
            price: 179,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(SokScreen(api: api)));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('a1_sok_field')), 'fiskesuppe');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(api.searched, ['fiskesuppe']);
    expect(find.byKey(const Key('a1_sok_treff')), findsOneWidget);
    expect(find.text('Nordnes Fisk'), findsWidgets);
    expect(find.text('179 kr'), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_vanlig_footer')), findsOneWidget);
    expect(find.byKey(const Key('a1_sok_ingen')), findsNothing);
  });

  testWidgets('no hits shows the Ægil fallback', (tester) async {
    _frame(tester);
    await tester.pumpWidget(_app(SokScreen(api: _FakeApi())));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('a1_sok_field')), 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byKey(const Key('a1_sok_ingen')), findsOneWidget);
    expect(find.textContaining('«zzzz»'), findsOneWidget);
  });

  testWidgets('a submitted search is remembered locally, last eight', (
    tester,
  ) async {
    _frame(tester);
    for (var i = 0; i < 10; i++) {
      SokScreen.remember('term $i');
    }
    expect(SokScreen.readRecent().length, 8);
    expect(SokScreen.readRecent().first, 'term 9');

    await tester.pumpWidget(_app(SokScreen(api: _FakeApi())));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('a1_sok_nylig')), findsOneWidget);
    expect(find.text('term 9'), findsOneWidget);
  });
}
