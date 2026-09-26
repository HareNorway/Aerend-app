import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/data/feed/feed_write_results.dart';
import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_tab.dart';
import 'package:aerend_customer/screens/bergen/utforsk/utforsk_copy.dart';

import '../layout/reduced_motion_harness.dart';

/// The Utforsk Feed tab against the prototype (`utfFeed` ≈L4402–4511): the
/// cards' fields, the orbs as a filter, like and follow, the «Du bestilte …»
/// hint, the shop's open state, the empty states and the bag promo.

const _img = FeedMedia(
  cloudinaryPublicId: 'aerend/feed/demo/gambas',
  cloudinaryVersion: '1',
  format: 'jpg',
  width: 1220,
  height: 818,
  resourceType: 'image',
);
const _video = FeedMedia(
  cloudinaryPublicId: 'aerend/feed/demo/sashimi',
  cloudinaryVersion: '1',
  format: 'mp4',
  width: 1920,
  height: 1080,
  resourceType: 'video',
  durationMs: 24_000,
);

FeedTabItem _post({
  required String id,
  String? storeId,
  String? storeName,
  bool following = false,
  String postType = 'generic',
  String? category,
  String headline = 'Tittel',
  String caption = 'Tekst.',
  int? productId,
  int? priceOre,
  FeedMedia media = _img,
  DateTime? publishedAt,
  int likes = 10,
  bool liked = false,
}) => FeedTabItem(
  id: id,
  publisherType: storeId == null ? 'aerend' : 'store',
  publisherName: storeName ?? 'Ærend',
  postType: postType,
  caption: caption,
  media: media,
  store: storeId == null
      ? null
      : FeedStore(
          id: storeId,
          name: storeName ?? 'Butikk',
          slug: 'butikk',
          isFollowing: following,
        ),
  category: category,
  headline: headline,
  bydel: 'Møhlenpris',
  likeCount: likes,
  commentCount: 3,
  isLiked: liked,
  publishedAt: publishedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
  storeProductId: productId,
  priceOre: priceOre,
);

final _items = <FeedTabItem>[
  _post(
    id: '1',
    storeId: '28',
    storeName: 'Møllaren Café',
    postType: 'dagens_rett',
    category: 'fisk',
    headline: 'Gambas pil pil, rett fra pannen',
    caption: 'Reker i hvitløk og chili.',
    productId: 488,
    priceOre: 17900,
    likes: 214,
  ),
  _post(
    id: '2',
    storeId: '9',
    storeName: 'Red Sun',
    postType: 'ny_i_hyllene',
    category: 'fisk',
    headline: 'Sashimien kom i morges',
    media: _video,
    productId: 176,
    priceOre: 28000,
    likes: 132,
  ),
  _post(
    id: '3',
    postType: 'tilbud_i_naerheten',
    category: 'gront',
    headline: 'Eplene er inne — plukket i går',
    priceOre: 3900,
    publishedAt: DateTime.now().subtract(const Duration(hours: 26)),
    likes: 92,
  ),
];

class _Repo extends FeedRepo {
  _Repo({this.items = const [], this.fail = false});

  final List<FeedTabItem> items;
  final bool fail;
  final List<String> calls = [];

  @override
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
  }) async {
    calls.add('tab:$tab');
    if (fail) throw StateError('offline');
    return FeedTabPage(tab: tab, label: 'I nærheten', items: items);
  }

  @override
  Future<LikeToggleResult> likePost(String postId) async {
    calls.add('like:$postId');
    return LikeToggleResult(postId: postId, isLiked: true, likeCount: 215);
  }

  @override
  Future<LikeToggleResult> unlikePost(String postId) async {
    calls.add('unlike:$postId');
    return LikeToggleResult(postId: postId, isLiked: false, likeCount: 214);
  }

  @override
  Future<FollowToggleResult> followStore(String storeId) async {
    calls.add('follow:$storeId');
    return FollowToggleResult(storeId: storeId, isFollowing: true);
  }

  @override
  Future<FollowToggleResult> unfollowStore(String storeId) async {
    calls.add('unfollow:$storeId');
    return FollowToggleResult(storeId: storeId, isFollowing: false);
  }
}

class _Api extends OpsCustomerApi {
  _Api({this.bags = const [], this.orderRows = const []});

  final List<Map<String, dynamic>> bags;
  final List<Map<String, dynamic>> orderRows;

  @override
  Future<List<Map<String, dynamic>>> poser() async => bags;

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async =>
      orderRows;

  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => null;
}

class _Butikk extends OpsButikkApi {
  _Butikk(this.infos);

  final Map<int, BergenStoreInfo> infos;

  @override
  Future<BergenStoreInfo?> store(int storeId, {String? categoryHint}) async =>
      infos[storeId];
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void _frame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The rail is lazy and 500px wide on a 358px viewport: scroll the orb into
/// view before tapping it, the way a thumb would.
Future<void> _tapOrb(WidgetTester tester, String slug) async {
  await tester.drag(
    find.byKey(const Key('a1_utforsk_filters')),
    const Offset(-160, 0),
  );
  await tester.pump();
  await tester.ensureVisible(find.byKey(Key('a1_feed_orb_$slug')));
  await tester.pump();
  await tester.tap(find.byKey(Key('a1_feed_orb_$slug')));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUpAll(() async {
    await bootstrapGlobals();
    OpsCustomerApi.networkEnabled = false;
    FeedPostCard.loadImages = false;
  });

  testWidgets('cards carry title, text, badge, price, follow and the rail', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: _items),
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Gambas pil pil, rett fra pannen'), findsOneWidget);
    expect(find.text('Reker i hvitløk og chili.'), findsOneWidget);
    expect(find.text('Dagens rett'), findsOneWidget);
    expect(find.text('179 kr'), findsOneWidget);
    expect(find.text('214'), findsOneWidget);
    expect(find.text(UtforskCopy.a1_feed_cta_add), findsWidgets);
    // Two shop posts carry «Følg»; the Ærend post has no shop to follow.
    expect(find.text(UtforskCopy.a1_feed_follow), findsNWidgets(2));
    expect(find.byKey(const Key('a1_feed_follow_3')), findsNothing);
    // The video card: duration pill and the play button.
    expect(find.byKey(const Key('a1_feed_play_2')), findsOneWidget);
    expect(find.textContaining('0:24'), findsOneWidget);
  });

  testWidgets('an Ærend post says so and leads to the post', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: [_items[2]]),
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    expect(
      find.textContaining(UtforskCopy.a1_feed_published_by_aerend),
      findsOneWidget,
    );
    expect(find.text(UtforskCopy.a1_feed_cta_post), findsOneWidget);
    expect(find.text('Tilbud i nærheten'), findsOneWidget);
    expect(find.text('39 kr'), findsOneWidget);
  });

  testWidgets('the shop read gives distance, open state and ETA', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: [_items[0]]),
          api: _Api(),
          butikkApi: _Butikk({
            28: const BergenStoreInfo(
              id: 28,
              name: 'Møllaren Café',
              kind: BergenStoreKind.restaurant,
              open: true,
              deliveryMinutes: 25,
              distanceKm: .4,
            ),
          }),
        ),
      ),
    );
    await _settle(tester);

    expect(find.textContaining('400 m'), findsOneWidget);
    expect(find.textContaining('Åpen · 25–35 min'), findsOneWidget);
  });

  testWidgets('a closed shop shows when it opens and no cart CTA', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: [_items[0]]),
          api: _Api(),
          butikkApi: _Butikk({
            28: const BergenStoreInfo(
              id: 28,
              name: 'Møllaren Café',
              kind: BergenStoreKind.restaurant,
              open: false,
              openTime: '10:00',
            ),
          }),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Åpner 10:00'), findsOneWidget);
    expect(find.text(UtforskCopy.a1_feed_cta_add), findsNothing);
    expect(find.text(UtforskCopy.a1_feed_cta_store), findsOneWidget);
  });

  testWidgets('an earlier order gives the hint and «Bestill igjen»', (
    tester,
  ) async {
    _frame(tester);
    final twoWeeks = DateTime.now().subtract(const Duration(days: 14));
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: [_items[0]]),
          api: _Api(
            orderRows: [
              {
                'order_id': 1,
                'store': {'id': 28, 'name': 'Møllaren Café'},
                'ordered_at': twoWeeks.toIso8601String(),
              },
            ],
          ),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    expect(find.byKey(const Key('a1_feed_hint_1')), findsOneWidget);
    expect(find.text('Du bestilte herfra for to uker siden'), findsOneWidget);
    expect(find.text(UtforskCopy.a1_feed_cta_add_again), findsOneWidget);
  });

  testWidgets('the orbs filter by category, show «nytt», and clear', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: _items),
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    // Fisk had a post today; grønt's is from yesterday.
    expect(find.byKey(const Key('a1_feed_orb_new_fisk')), findsOneWidget);
    expect(find.byKey(const Key('a1_feed_orb_new_gront')), findsNothing);

    await _tapOrb(tester, 'gront');
    expect(find.text('Eplene er inne — plukket i går'), findsOneWidget);
    expect(find.text('Gambas pil pil, rett fra pannen'), findsNothing);
    expect(find.byKey(const Key('a1_feed_filter_clear')), findsOneWidget);

    await tester.tap(find.byKey(const Key('a1_feed_filter_clear')));
    await _settle(tester);
    expect(find.text('Gambas pil pil, rett fra pannen'), findsOneWidget);
    expect(find.byKey(const Key('a1_feed_filter_clear')), findsNothing);
  });

  testWidgets('a category with nothing today is an honest empty state', (
    tester,
  ) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: _items),
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    await _tapOrb(tester, 'mote');
    expect(find.byKey(const Key('a1_feed_empty')), findsOneWidget);
    expect(find.text(UtforskCopy.a1_feed_empty_cat_title), findsOneWidget);

    await tester.tap(find.text(UtforskCopy.a1_feed_empty_cat_cta));
    await _settle(tester);
    expect(find.byKey(const Key('a1_feed_empty')), findsNothing);
  });

  testWidgets('a feed that does not answer offers a retry', (tester) async {
    _frame(tester);
    final repo = _Repo(fail: true);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: repo,
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text(UtforskCopy.a1_feed_error_title), findsOneWidget);
    await tester.tap(find.text(UtforskCopy.a1_feed_retry));
    await _settle(tester);
    expect(repo.calls.where((c) => c == 'tab:naerheten').length, 2);
  });

  testWidgets('like is optimistic and lands on the server count', (
    tester,
  ) async {
    _frame(tester);
    final repo = _Repo(items: [_items[0]]);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: repo,
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const Key('a1_feed_like_1')));
    await tester.pump();
    expect(find.text('215'), findsOneWidget);
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.calls, contains('like:1'));

    await tester.tap(find.byKey(const Key('a1_feed_like_1')));
    await _settle(tester);
    expect(find.text('214'), findsOneWidget);
    expect(repo.calls, contains('unlike:1'));
  });

  testWidgets('follow flips the pill and says push is off', (tester) async {
    _frame(tester);
    final repo = _Repo(items: [_items[0]]);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: repo,
          api: _Api(),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const Key('a1_feed_follow_1')));
    await _settle(tester);
    expect(find.text(UtforskCopy.a1_feed_following), findsOneWidget);
    expect(
      find.textContaining(UtforskCopy.a1_feed_follow_toast('Møllaren Café')),
      findsOneWidget,
    );
    expect(repo.calls, contains('follow:28'));
    // Let the toast finish before the test ends.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the first bag becomes the promo card', (tester) async {
    _frame(tester);
    await tester.pumpWidget(
      _app(
        UtforskFeedTab(
          bottomReserve: 0,
          repo: _Repo(items: const []),
          api: _Api(
            bags: [
              {
                'id': '7',
                'name': 'Grønt & godt',
                'store_name': 'Grønt & Godt',
                'price_ore': 9900,
                'value_ore': 25000,
                'pickup_window': '17–19',
                'left': 2,
              },
            ],
          ),
          butikkApi: _Butikk(const {}),
        ),
      ),
    );
    await _settle(tester);

    expect(find.byKey(const Key('a1_feed_promo')), findsOneWidget);
    expect(find.text(UtforskCopy.a1_feed_promo_price(99, 250)), findsOneWidget);
    expect(find.text(UtforskCopy.a1_utforsk_promo_cta), findsOneWidget);
    expect(find.text(UtforskCopy.a1_utforsk_promo_left(2)), findsOneWidget);
    // And with no posts at all, the honest empty state above it.
    expect(find.text(UtforskCopy.a1_feed_empty_title), findsOneWidget);
  });
}
