import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_app_models.dart';
import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/data/ops/fiske_models.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_copy.dart';
import 'package:aerend_customer/screens/bergen/fiske/fiske_game.dart';
import 'package:aerend_customer/screens/bergen/fiske/fjordfiske_screen.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_screen.dart';

import '../a3/a3_fakes.dart';
import '../layout/reduced_motion_harness.dart';

/// Fjordfiske (agil-1): the cast → bite → reel → card machine, the prize
/// cadence (every N-th from cast X, at most M), the daily cap, the three card
/// actions, the Utforsk landing chip, and reduced motion.
class _FakeOps extends OpsCustomerApi {
  _FakeOps({this.day});

  FiskeDay? day;

  @override
  Future<FiskeDay?> fiske() async => day;

  @override
  Future<List<Map<String, dynamic>>> poser() async => const [];

  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => null;
}

class _EmptyRepo extends FeedRepo {
  @override
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
  }) async => const FeedTabPage(tab: 'naerheten', label: 'I nærheten', items: []);
}

const _s1 = Suggestion(
  id: 11,
  reasonCode: 'offer',
  reason: 'Tilbud hos Torgboden',
  headline: 'Reker fra Torgboden',
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
const _s3 = Suggestion(
  id: 13,
  reasonCode: 'fresh',
  reason: 'Nytt i hyllene',
  headline: 'Ullgenser «Vestland»',
  storeId: 5,
  category: 'Mote',
);

Future<BergenStoreInfo?> _store(int id) async => BergenStoreInfo(
  id: id,
  name: 'Butikk $id',
  kind: BergenStoreKind.other,
  deliveryMinutes: 30,
  menu: [
    BergenMenuCategory(
      id: 1,
      name: 'Alt',
      items: [
        BergenMenuItem(id: 77, name: 'Reker', storeId: 3, storeName: 'Butikk 3', price: 149),
        BergenMenuItem(id: 78, name: 'Kanelboller', storeId: 4, storeName: 'Butikk 4', price: 89),
      ],
    ),
  ],
);

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester t, [int frames = 4]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Kast ut → the line is out → (≤ 3.1 s) NAPP! → DRA INN! → the card.
Future<void> _castAndReel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('a1_fiske_kast')));
  await _settle(tester);
  expect(find.byKey(const Key('a1_fiske_ute')), findsOneWidget);
  // The bite comes after 1.5–3.1 s and stays 1.7 s: poll for it.
  for (var waited = 0; waited < 3200; waited += 100) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(const Key('a1_fiske_dra')).evaluate().isNotEmpty) break;
  }
  expect(find.byKey(const Key('a1_fiske_dra')), findsOneWidget);
  await tester.tap(find.byKey(const Key('a1_fiske_dra')));
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    FeedPostCard.loadImages = false;
  });

  group('FiskePrizeRules (design fiskePremieVelg)', () {
    test('every 8th from cast 3, at most 3', () {
      const r = FiskePrizeRules();
      expect(r.eligible(1, taken: 0, lastAt: 0), isFalse);
      expect(r.eligible(2, taken: 0, lastAt: 0), isFalse);
      expect(r.eligible(3, taken: 0, lastAt: 0), isTrue);
      expect(r.eligible(4, taken: 1, lastAt: 3), isFalse);
      expect(r.eligible(10, taken: 1, lastAt: 3), isFalse);
      expect(r.eligible(11, taken: 1, lastAt: 3), isTrue);
      expect(r.eligible(19, taken: 2, lastAt: 11), isTrue);
      expect(r.eligible(27, taken: 3, lastAt: 19), isFalse, reason: 'max 3');
    });

    test('off turns prizes off; the server cadence overrides N and X', () {
      expect(const FiskePrizeRules(off: true).eligible(3, taken: 0, lastAt: 0), isFalse);
      final r = const FiskePrizeRules().copyWith(everyN: 4, fromCast: 2);
      expect(r.eligible(2, taken: 0, lastAt: 0), isTrue);
      expect(r.eligible(5, taken: 1, lastAt: 2), isFalse);
      expect(r.eligible(6, taken: 1, lastAt: 2), isTrue);
      expect(r.max, 3);
    });

    test('the deck filters by bait and counts per bucket', () {
      const deck = FiskeDeck([_s1, _s2, _s3]);
      expect(deck.count(FiskeAgn.alle), 3);
      expect(deck.count(FiskeAgn.fisk), 1);
      expect(deck.count(FiskeAgn.mat), 1);
      expect(deck.count(FiskeAgn.mote), 1);
      expect(deck.count(FiskeAgn.gaver), 0);
      expect(deck.withAgn(FiskeAgn.mat).cards.single.id, 12);
      expect(fiskeNfp(1360), '1 360');
      expect(fiskeNfp(420), '420');
    });
  });

  group('FjordfiskeScreen', () {
    testWidgets('cast → bite → reel → catch card, then Lagre advances the deck', (tester) async {
      _frame(tester);
      final points = FakePointsApi();
      final aegil = FakeAegilApi(suggestionValue: const [_s1, _s2]);
      final saved = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: points,
            aegil: aegil,
            customerApi: _FakeOps(day: const FiskeDay(today: 0, max: 5, left: 5, capped: false)),
            storeLookup: _store,
            saveFavourite: (id) async {
              saved.add(id);
              return true;
            },
          ),
        ),
      );
      await _settle(tester);
      expect(aegil.calls, contains('suggestions:fiske'));
      expect(find.byKey(const Key('a1_fiske_title')), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_status(1, 2, 0)), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_snakk_klar), findsOneWidget);
      expect(find.byKey(const Key('a1_fiske_agn')), findsOneWidget);

      await _castAndReel(tester);
      expect(points.calls, contains('earn:1'));
      expect(find.byKey(const Key('a1_fiske_fangst')), findsOneWidget);
      expect(find.text('Reker fra Torgboden'), findsOneWidget);
      expect(find.text('Butikk 3'), findsOneWidget);
      expect(find.text('149 kr'), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_plus(5)), findsOneWidget);
      expect(find.byKey(const Key('a1_fiske_napp_badge')), findsOneWidget, reason: 'first catch of the day is Dagens napp');
      expect(find.text(FiskeCopy.a1_fiske_hint_fangst), findsOneWidget);

      await tester.tap(find.byKey(const Key('a1_fiske_lagre')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(aegil.calls, contains('add:11'));
      expect(saved, [3]);
      expect(find.byKey(const Key('a1_fiske_fangst')), findsNothing);
      expect(find.text(FiskeCopy.a1_fiske_status(2, 2, 1)), findsOneWidget);
      expect(find.byKey(const Key('a1_fiske_kast')), findsOneWidget);
    });

    testWidgets('Slipp dismisses, Legg i kurven adds to the basket, the deck ends in Ferdig', (tester) async {
      _frame(tester);
      final points = FakePointsApi();
      final aegil = FakeAegilApi(suggestionValue: const [_s1, _s2]);
      final cart = <(int, int)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: points,
            aegil: aegil,
            customerApi: _FakeOps(),
            storeLookup: _store,
            addToCart: (context, {required storeId, required productId}) async {
              cart.add((storeId, productId));
              return true;
            },
          ),
        ),
      );
      await _settle(tester);

      await _castAndReel(tester);
      await tester.tap(find.byKey(const Key('a1_fiske_slipp')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(aegil.calls, contains('dismiss:11'));
      expect(find.byKey(const Key('a1_fiske_fangst')), findsNothing);

      await _castAndReel(tester);
      expect(find.text('Kanelboller, 6 stk'), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_legg')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(aegil.calls, contains('add:12'));
      expect(cart, [(4, 78)]);

      // The deck is empty: the end card, no controls.
      expect(find.byKey(const Key('a1_fiske_ferdig')), findsOneWidget);
      expect(find.byKey(const Key('a1_fiske_kontroller')), findsNothing);
      expect(find.text(FiskeCopy.a1_fiske_ferdig_line(0, 1)), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_igjen')));
      await _settle(tester);
      expect(find.byKey(const Key('a1_fiske_kast')), findsOneWidget);
    });

    testWidgets('a missed bite falls back to Kast ut igjen', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: FakePointsApi(),
            aegil: FakeAegilApi(suggestionValue: const [_s1]),
            customerApi: _FakeOps(),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key('a1_fiske_kast')));
      for (var waited = 0; waited < 3200; waited += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('a1_fiske_dra')).evaluate().isNotEmpty) break;
      }
      expect(find.byKey(const Key('a1_fiske_dra')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1800));
      expect(find.text(FiskeCopy.a1_fiske_snakk_mistet), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_kast_igjen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2300));
      expect(find.text(FiskeCopy.a1_fiske_kast), findsOneWidget);
    });

    testWidgets('the prize cadence: every 2nd from cast 2 is a Premiefangst; Hent claims, Slipp lets it go', (tester) async {
      _frame(tester);
      final points = FakePointsApi();
      final aegil = FakeAegilApi(suggestionValue: const [_s1, _s2, _s3, _s1, _s2]);
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: points,
            aegil: aegil,
            customerApi: _FakeOps(),
            rules: const FiskePrizeRules(everyN: 2, max: 3, fromCast: 2),
          ),
        ),
      );
      await _settle(tester);

      await _castAndReel(tester);
      expect(points.calls, isNot(contains('pick')));
      expect(find.byKey(const Key('a1_fiske_fangst')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_slipp')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);

      // Cast 2: the prize.
      await _castAndReel(tester);
      expect(points.calls, contains('pick'));
      expect(find.byKey(const Key('a1_fiske_premiefangst')), findsOneWidget);
      expect(find.text('Kaffe hos Kaffemisjonen'), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_hint_premie), findsOneWidget);
      expect(find.text(FiskeCopy.a1_fiske_poeng_har('300', '420')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_sett_maal')));
      await _settle(tester);
      expect(points.calls, contains('goal:7'));
      await tester.tap(find.byKey(const Key('a1_fiske_hent')));
      await _settle(tester);
      expect(points.calls, contains('claim:7'));
      expect(find.byKey(const Key('a1_fiske_premiefangst')), findsNothing);
      expect(find.text(FiskeCopy.a1_fiske_snakk_din), findsOneWidget);
      // The prize did not consume a deck card.
      expect(find.text(FiskeCopy.a1_fiske_status(3, 6, 0)), findsOneWidget);

      // Cast 3: too soon (every 2nd) → a normal catch.
      final picksBefore = points.calls.where((c) => c == 'pick').length;
      await _castAndReel(tester);
      expect(points.calls.where((c) => c == 'pick').length, picksBefore);
      expect(find.byKey(const Key('a1_fiske_fangst')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_slipp')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);

      // Cast 4: prize again; Slipp lets it go without claiming.
      await _castAndReel(tester);
      expect(points.calls.where((c) => c == 'pick').length, picksBefore + 1);
      expect(find.byKey(const Key('a1_fiske_premiefangst')), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_premie_slipp')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.byKey(const Key('a1_fiske_premiefangst')), findsNothing);
      expect(points.calls.where((c) => c.startsWith('claim')).length, 1);
    });

    testWidgets('the daily cap is shown honestly: before the first cast and when earn says capped', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: FakePointsApi(earnValues: const [EarnResult(earned: 0, today: 5, max: 5, capped: true)]),
            aegil: FakeAegilApi(suggestionValue: const [_s1, _s2]),
            customerApi: _FakeOps(day: const FiskeDay(today: 5, max: 5, left: 0, capped: true)),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text(FiskeCopy.a1_fiske_hint_capped(5)), findsOneWidget);

      await _castAndReel(tester);
      expect(find.byKey(const Key('a1_fiske_fangst')), findsOneWidget);
      expect(find.byKey(const Key('a1_fiske_plus')), findsNothing, reason: 'no points, no coin');
      expect(find.byKey(const Key('a1_fiske_napp_badge')), findsNothing);
      await tester.tap(find.byKey(const Key('a1_fiske_slipp')));
      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(find.text(FiskeCopy.a1_fiske_hint_capped(5)), findsOneWidget);
    });

    testWidgets('the server cadence overrides the prize rules', (tester) async {
      _frame(tester);
      final points = FakePointsApi();
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: points,
            aegil: FakeAegilApi(suggestionValue: const [_s1, _s2]),
            customerApi: _FakeOps(
              day: const FiskeDay(today: 0, max: 5, left: 5, capped: false, prizeEveryN: 4, prizeFromCast: 1),
            ),
          ),
        ),
      );
      await _settle(tester);
      await _castAndReel(tester);
      expect(points.calls, contains('pick'));
      expect(find.byKey(const Key('a1_fiske_premiefangst')), findsOneWidget);
    });

    testWidgets('the bait rail filters the deck', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: FjordfiskeScreen(
            points: FakePointsApi(),
            aegil: FakeAegilApi(suggestionValue: const [_s1, _s2, _s3]),
            customerApi: _FakeOps(),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text(FiskeCopy.a1_fiske_status(1, 3, 0)), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_fiske_agn_mat')));
      await _settle(tester);
      expect(find.text(FiskeCopy.a1_fiske_status(1, 1, 0)), findsOneWidget);
      await _castAndReel(tester);
      expect(find.text('Kanelboller, 6 stk'), findsOneWidget);
    });

    testWidgets('respects reduced motion', (tester) async {
      _frame(tester);
      await expectRespectsReducedMotion(
        tester,
        () => FjordfiskeScreen(
          points: FakePointsApi(),
          aegil: FakeAegilApi(suggestionValue: const [_s1]),
          customerApi: _FakeOps(),
        ),
        longestDelay: const Duration(seconds: 2),
      );
    });
  });

  group('Utforsk · Fjordfiske segment', () {
    testWidgets('?tab=fiske opens the game over Utforsk, like the design\'s tilFjordfiske', (tester) async {
      _frame(tester);
      A3Services.points = () => FakePointsApi();
      A3Services.aegil = () => FakeAegilApi(suggestionValue: const [_s1]);
      addTearDown(A3Services.reset);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: BergenRoutes.generate,
          home: UtforskScreen(
            api: _FakeOps(),
            feedRepo: _EmptyRepo(),
            initialTab: UtforskScreen.tabFiske,
          ),
        ),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('a1_fiske_screen')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_fiske_napp')), findsNothing);
    });
  });
}
