import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/butikk/automat_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_copy.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_screen.dart';

import '../a3/a3_fakes.dart';
import '../layout/reduced_motion_harness.dart';

/// Launch UI Step 9: the Forundringspose segment (L5632–5708) and
/// Poseautomaten (L5715–5906) against the Launch prototype — the bag cards'
/// price, value and discount, the head count, the goal card, the segment
/// switch, and the machine's claw, pull, landing and fishing states.

final _bags = <Map<String, dynamic>>[
  {'id': '793', 'name': 'Forundringspose', 'description': 'Bakst', 'store_id': 10, 'store_name': 'Sandviken Bakeri', 'price_ore': 9900, 'value_ore': 25000, 'pickup_window': 'til 18:00', 'left': null},
  {'id': '794', 'name': 'Forundringspose', 'description': 'Frukt og grønt', 'store_id': 28, 'store_name': 'Grønt & Godt', 'price_ore': 7900, 'value_ore': 20000, 'left': null},
  {'id': '795', 'name': 'Forundringspose', 'description': 'Fisk', 'store_id': 6, 'store_name': 'Torgboden', 'price_ore': 9900, 'value_ore': 25000, 'left': null},
];

class _Api extends OpsCustomerApi {
  _Api({this.bags = const []});

  final List<Map<String, dynamic>> bags;

  @override
  Future<List<Map<String, dynamic>>> poser() async => bags;

  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];
}

class _Repo extends FeedRepo {
  @override
  Future<FeedTabPage> fetchFeedTab({required String tab, String? cursor, int? limit, String? bydel, double? lat, double? lng}) async =>
      const FeedTabPage(tab: 'naerheten', label: 'I nærheten', items: []);
}

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    FeedPostCard.loadImages = false;
  });

  setUp(() {
    A3Services.points = () => FakePointsApi();
    A3Services.aegil = () => FakeAegilApi();
  });
  tearDown(A3Services.reset);

  group('Forundringspose segment', () {
    testWidgets('bags float with price, value, discount and the live count', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: UtforskScreen(api: _Api(bags: _bags), feedRepo: _Repo(), initialTab: UtforskScreen.tabPose)));
      await _settle(tester);

      expect(find.text(UtforskCopy.a1_utforsk_pose_left_today(3)), findsOneWidget);
      expect(find.text('Sandviken Bakeri'), findsOneWidget);
      expect(find.text(UtforskCopy.a1_pose_kort_under('Bakst', 250)), findsOneWidget);
      expect(find.text('−60 %'), findsWidgets);
      expect(find.text('Hentes til 18:00'), findsOneWidget);
      // No stock is tracked: no «N igjen» chip on the cards.
      expect(find.text(UtforskCopy.a1_utforsk_pose_left(2)), findsNothing);
      expect(find.byKey(const Key('a1_utforsk_automat')), findsOneWidget);
      expect(find.byKey(const Key('a1_pose_feed')), findsOneWidget);
    });

    testWidgets('the goal card reads the shelf goal and the balance', (tester) async {
      _frame(tester);
      A3Services.points = () => FakePointsApi(
        balanceValue: const PointsBalance(available: 1240),
        shelfValue: const Premiehylla(
          prizes: [],
          goal: PointGoal(kind: 'prize', label: 'Gratis pizza fra Casa Maria', current: 1240, target: 1360, remaining: 120, percent: 91),
        ),
      );
      await tester.pumpWidget(MaterialApp(home: UtforskScreen(api: _Api(bags: _bags), feedRepo: _Repo(), initialTab: UtforskScreen.tabPose)));
      await _settle(tester);

      expect(find.text(UtforskCopy.a1_maal_igjen('gratis pizza fra casa maria', 120)), findsOneWidget);
      expect(find.text(UtforskCopy.a1_poeng(1240)), findsOneWidget);
      expect(find.byKey(const Key('a1_pose_premiehylla')), findsOneWidget);
    });

    testWidgets('the Ærend-feed card and the Feed segment switch back', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: UtforskScreen(api: _Api(bags: _bags), feedRepo: _Repo(), initialTab: UtforskScreen.tabPose)));
      await _settle(tester);
      expect(find.byKey(const Key('a1_utforsk_filters')), findsNothing);

      await tester.tap(find.byKey(const Key('a1_pose_feed')));
      await _settle(tester);
      expect(find.byKey(const Key('a1_utforsk_filters')), findsOneWidget);
      expect(find.byKey(const Key('a1_pose_feed')), findsNothing);

      await tester.tap(find.byKey(const Key('a1_utforsk_tab_pose')));
      await _settle(tester);
      expect(find.byKey(const Key('a1_pose_feed')), findsOneWidget);
    });
  });

  group('Poseautomaten', () {
    testWidgets('the claw steps over the shops and the display follows', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: AutomatScreen(api: _Api(bags: _bags))));
      await _settle(tester);

      expect(find.text(UtforskCopy.a1_auto_title), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_igjen(3)), findsOneWidget);
      // The prototype's claw starts over the third slot.
      expect(find.text('▸ Torgboden'), findsOneWidget);
      await tester.tap(find.byKey(const Key('a1_automat_venstre')));
      await _settle(tester);
      expect(find.text('▸ Grønt & Godt'), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_verdi(200)), findsOneWidget);
      // A tap on a bag picks it too.
      await tester.tap(find.byKey(const Key('a1_automat_pose_0')));
      await _settle(tester);
      expect(find.text('▸ Sandviken Bakeri'), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_hint_start), findsOneWidget);
    });

    testWidgets('a pull lands the bag in Vågen; Ægil rows out for it', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: AutomatScreen(api: _Api(bags: _bags))));
      await _settle(tester);

      await tester.ensureVisible(find.byKey(const Key('a1_automat_trekk')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_automat_trekk')));
      await tester.pump();
      // While the claw works the arrows are locked.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const Key('a1_automat_vaagen')), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('a1_automat_vaagen')), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_din), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_fisk_inn(99)), findsOneWidget);
      // One bag on the water: one fewer in the count.
      expect(find.text(UtforskCopy.a1_auto_igjen(2)), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('a1_automat_fisk')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_automat_fisk')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text(UtforskCopy.a1_auto_fisker), findsOneWidget);
      expect(find.text(UtforskCopy.a1_auto_linje_ror), findsOneWidget);

      // Leaving before Ægil is back puts nothing in the basket.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('«Prøv igjen» puts the bag back and the machine is ready', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: AutomatScreen(api: _Api(bags: _bags))));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('a1_automat_spak')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('a1_automat_prov')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('a1_automat_prov')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1_automat_prov')));
      await _settle(tester);
      expect(find.byKey(const Key('a1_automat_vaagen')), findsNothing);
      expect(find.byKey(const Key('a1_automat_trekk')), findsOneWidget);
    });

    testWidgets('the fishing frames follow the prototype\'s clock', (tester) async {
      // The boat glides in over 1.3 s; the bag is aboard and dry at 4.3 s.
      final start = PoseFiskFrame.at(0);
      expect(start.bx, closeTo(240, .01));
      final inn = PoseFiskFrame.at(1.3);
      expect(inn.bx, closeTo(0, .01));
      final ombord = PoseFiskFrame.at(4.4);
      expect(ombord.iv, 0);
      expect(ombord.pX, closeTo(196 + ombord.bx, .5));
      // The float shows only while the line is in the water.
      expect(PoseFiskFrame.at(2).dVis, 1);
      expect(PoseFiskFrame.at(3.2).dVis, 0);
    });

    testWidgets('no bags tonight is said plainly', (tester) async {
      _frame(tester);
      await tester.pumpWidget(MaterialApp(home: AutomatScreen(api: _Api())));
      await _settle(tester);
      expect(find.text(UtforskCopy.a1_auto_tom), findsOneWidget);
      expect(find.byKey(const Key('a1_automat_alle')), findsOneWidget);
    });

    testWidgets('reduced motion still pulls and lands', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
            child: AutomatScreen(api: _Api(bags: _bags)),
          ),
        ),
      );
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const Key('a1_automat_trekk')));
      await tester.tap(find.byKey(const Key('a1_automat_trekk')));
      await _settle(tester);
      expect(find.text(UtforskCopy.a1_auto_din), findsOneWidget);
    });
  });
}
