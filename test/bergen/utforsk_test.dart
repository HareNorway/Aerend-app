import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_copy.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_screen.dart';

import '../a3/a3_fakes.dart';
import '../layout/reduced_motion_harness.dart';

/// AGIL-1 v2 Phase 2: the Utforsk screen's three segments, the bag tab's
/// honest empty state, the Fjordfiske segment (a door to the game), and the `/bergen/...` route
/// resolver both branches push through.
class _FakeApi extends OpsCustomerApi {
  _FakeApi({this.bags = const [], this.drift});

  final List<Map<String, dynamic>> bags;
  final Map<String, dynamic>? drift;

  @override
  Future<List<Map<String, dynamic>>> poser() async => bags;

  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => drift;

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];
}

/// An empty feed: these tests are about the shell around the Feed tab.
class _EmptyRepo extends FeedRepo {
  @override
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
  }) async => const FeedTabPage(tab: 'naerheten', label: 'I nærheten', items: []);
}

Widget _app(Widget child) => MaterialApp(home: child);

/// The design frame: the Bergen screens scale from 390 wide.
void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    FeedPostCard.loadImages = false;
  });

  group('BergenRoutes', () {
    test('resolves a query and a trailing parameter to the registered key', () {
      expect(
        BergenRoutes.resolve('/bergen/utforsk?tab=feed'),
        '/bergen/utforsk',
      );
      expect(BergenRoutes.arguments('/bergen/utforsk?tab=feed', null), {
        'tab': 'feed',
      });
      expect(BergenRoutes.resolve('/bergen/nowhere/12'), isNull);
    });

    test('caller arguments win over the query', () {
      final args = BergenRoutes.arguments('/bergen/utforsk?tab=feed', {
        'tab': 'pose',
      });
      expect(args['tab'], 'pose');
    });

    test('generate is null for a name no map knows', () {
      expect(
        BergenRoutes.generate(const RouteSettings(name: '/bergen/finnes-ikke')),
        isNull,
      );
      expect(
        BergenRoutes.generate(const RouteSettings(name: '/elsewhere')),
        isNull,
      );
      expect(
        BergenRoutes.generate(
          const RouteSettings(name: '/bergen/utforsk?tab=pose'),
        ),
        isNotNull,
      );
    });
  });

  group('UtforskScreen', () {
    testWidgets('renders the title and three segments', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          UtforskScreen(api: _FakeApi(), feedRepo: _EmptyRepo()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_utforsk_title')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_tab_feed')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_tab_fiske')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_tab_pose')), findsOneWidget);
      expect(find.byKey(const Key('a1_feed_list')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_filters')), findsOneWidget);
      // No Drift note from the API → the notice is hidden.
      expect(find.byKey(const Key('a1_utforsk_drift')), findsNothing);
    });

    testWidgets('the Drift notice shows only with a note', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          UtforskScreen(
            api: _FakeApi(
              drift: {
                'note': 'Mye regn i kveld — vi legger 5 min på alle tider.',
                'pinned_until': '20:00',
              },
            ),
            feedRepo: _EmptyRepo(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_utforsk_drift')), findsOneWidget);
      expect(find.textContaining('Mye regn'), findsOneWidget);
    });

    testWidgets('the bag tab is honest when there are no bags', (tester) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          UtforskScreen(
            api: _FakeApi(),
            initialTab: UtforskScreen.tabPose,
            feedRepo: _EmptyRepo(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('a1_utforsk_pose_empty')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_automat')), findsOneWidget);
      expect(find.text(UtforskCopy.a1_utforsk_pose_title), findsOneWidget);
    });

    testWidgets('bags render with store, price and pickup window', (
      tester,
    ) async {
      _frame(tester);
      await tester.pumpWidget(
        _app(
          UtforskScreen(
            api: _FakeApi(
              bags: [
                {
                  'id': '7',
                  'name': 'Forundringspose bakst',
                  'price_ore': 9900,
                  'store_id': 3,
                  'store_name': 'Sandviken Bakeri',
                  'pickup_window': 'til 18:00',
                  'left': null,
                },
              ],
            ),
            initialTab: UtforskScreen.tabPose,
            feedRepo: _EmptyRepo(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Sandviken Bakeri'), findsOneWidget);
      expect(find.text('99 kr'), findsOneWidget);
      expect(find.textContaining('Hentes til 18:00'), findsOneWidget);
      expect(find.text(UtforskCopy.a1_utforsk_pose_secure), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_pose_empty')), findsNothing);
    });

    testWidgets('tapping the Fjordfiske segment opens the game over the feed', (
      tester,
    ) async {
      _frame(tester);
      A3Services.points = () => FakePointsApi();
      A3Services.aegil = () => FakeAegilApi();
      addTearDown(A3Services.reset);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: BergenRoutes.generate,
          home: UtforskScreen(api: _FakeApi(), feedRepo: _EmptyRepo()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('a1_utforsk_tab_fiske')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The design's `segFiske`: the game, not a landing card.
      expect(find.byKey(const Key('a1_fiske_screen')), findsOneWidget);
      expect(find.byKey(const Key('a1_utforsk_fiske_landing')), findsNothing);

      // Back: the segment stays lit, the Feed content is beneath.
      await tester.tap(find.byKey(const Key('a1_fiske_tilbake')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('a1_fiske_screen')), findsNothing);
      expect(find.byKey(const Key('a1_feed_list')), findsOneWidget);
    });

    testWidgets('the route carries ?tab= into the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(builder: (_) => const Scaffold());
            }
            return BergenRoutes.generate(settings);
          },
        ),
      );
      // The registered map builds `UtforskScreen(embedded: false)`; pushing
      // with a query lands on the Forundringspose segment.
      final route = BergenRoutes.generate(
        const RouteSettings(name: '/bergen/utforsk?tab=pose'),
      )!;
      expect((route.settings.arguments as Map)['tab'], 'pose');
    });
  });
}
