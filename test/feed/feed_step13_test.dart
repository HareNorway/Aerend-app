import 'dart:convert';
import 'dart:typed_data';

import 'package:aerend_customer/data/feed/feed_comment.dart';
import 'package:aerend_customer/data/feed/feed_config.dart';
import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_page.dart';
import 'package:aerend_customer/data/feed/feed_post.dart';
import 'package:aerend_customer/data/feed/feed_post_detail.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/data/ops/butikk_models.dart';
import 'package:aerend_customer/exceptions/feed/feed_api_exception.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/main.dart' show navigatorKey;
import 'package:aerend_customer/networking/feed/feed_api_helper.dart';
import 'package:aerend_customer/networking/feed/feed_repo.dart';
import 'package:aerend_customer/networking/ops/ops_butikk_api.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_post_card.dart';
import 'package:aerend_customer/screens/bergen/utforsk/feed_tab.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_kebab_sheet.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail_bloc.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail_event.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail_state.dart';
import 'package:aerend_customer/screens/feed/storeProfile/store_profile.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../layout/reduced_motion_harness.dart';

/// Backend plan Step 13 — the feed's half of the admin panel: the
/// «Funksjoner» switches (`GET /v1/feed/config`), reporting a comment, the
/// server's own words when a comment is refused, and Ærend's post without a
/// shop.

/// Answers every feed call from a table and remembers what was asked.
class _FakeFeed implements HttpClientAdapter {
  _FakeFeed(this.answers, {this.status = const {}});

  final Map<String, Object> answers;
  final Map<String, int> status;
  final List<RequestOptions> asked = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add(options);
    final key = '${options.method} ${options.path}';
    final body = answers[key] ?? {'error': {'code': 'not_found', 'message': key}};
    return ResponseBody.fromString(
      jsonEncode(body),
      status[key] ?? (answers.containsKey(key) ? 200 : 404),
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FeedRepo _repo(_FakeFeed fake) {
  final dio = Dio()..httpClientAdapter = fake;
  return FeedRepo(helper: FeedApiHelper.withDio(dio));
}

const _img = FeedMedia(
  cloudinaryPublicId: 'aerend/feed/demo/gambas',
  cloudinaryVersion: '1',
  format: 'jpg',
  width: 1220,
  height: 818,
  resourceType: 'image',
);

final _item = FeedTabItem(
  id: '1',
  publisherType: 'store',
  publisherName: 'Møllaren Café',
  postType: 'dagens_rett',
  caption: 'Reker i hvitløk og chili.',
  media: _img,
  store: const FeedStore(id: '28', name: 'Møllaren Café', slug: 'mollaren', isFollowing: false),
  headline: 'Gambas pil pil',
  likeCount: 214,
  commentCount: 3,
  isLiked: false,
  publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
);

class _TabRepo extends FeedRepo {
  _TabRepo(this.config);

  final FeedConfig config;

  @override
  Future<FeedTabPage> fetchFeedTab({
    required String tab,
    String? cursor,
    int? limit,
    String? bydel,
    double? lat,
    double? lng,
  }) async => FeedTabPage(tab: tab, label: 'I nærheten', items: [_item]);

  @override
  Future<FeedConfig> fetchConfig() async => config;
}

class _Api extends OpsCustomerApi {
  @override
  Future<List<Map<String, dynamic>>> poser() async => const [];

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => const [];

  @override
  Future<Map<String, dynamic>?> driftNotice({int? storeId}) async => null;
}

class _Butikk extends OpsButikkApi {
  @override
  Future<BergenStoreInfo?> store(int storeId, {String? categoryHint}) async => null;
}

/// The storeless Ærend post as `GET /v1/posts/:id` sends it (Step 13).
Map<String, dynamic> _storelessJson() => {
  'id': '501',
  'store': {'id': '', 'name': 'Ærend', 'slug': '', 'logo_url': null, 'is_following': false},
  'publisher': {'type': 'aerend', 'name': 'Ærend'},
  'headline': 'Nytt fra Ærend',
  'caption': 'Vi har åpnet i Bergen.',
  'location_name': null,
  'media': {
    'cloudinary_public_id': 'aerend/feed/x',
    'cloudinary_version': '1',
    'format': 'jpg',
    'width': 1080,
    'height': 1080,
    'resource_type': 'image',
  },
  'like_count': 4,
  'comment_count': 0,
  'is_liked': false,
  'published_at': '2026-10-08T10:00:00.000Z',
  'comments': {'items': [], 'next_cursor': null},
};

class _DetailRepo extends FeedRepo {
  _DetailRepo({this.refusal, this.config = FeedConfig.defaults});

  final FeedApiException? refusal;
  final FeedConfig config;

  @override
  Future<FeedConfig> fetchConfig() async => config;

  @override
  Future<FeedPostDetail> fetchPostDetail(String postId) async => FeedPostDetail.fromJson(_storelessJson());

  @override
  Future<FeedComment> createComment(String postId, String body, {String? displayName, String? avatarUrl}) async {
    throw refusal!;
  }
}

/// Hosts a [PostDetailBloc] the way the screen does.
class _Host extends StatefulWidget {
  const _Host(this.repo, this.onBloc);

  final FeedRepo repo;
  final ValueChanged<PostDetailBloc> onBloc;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  PostDetailBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc != null) return;
    _bloc = PostDetailBloc(context, this, '501', repo: widget.repo);
    widget.onBloc(_bloc!);
  }

  @override
  void dispose() {
    _bloc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

void main() {
  setUp(() async {
    await bootstrapGlobals();
    FeedRepo.resetConfigCache();
  });

  group('feed config', () {
    test('parses the switches; a missing or odd field stays on', () {
      final c = FeedConfig.fromJson({'stories': false, 'comments': false, 'like_counts': 'no', 'sharing': false});
      expect(c.stories, isFalse);
      expect(c.comments, isFalse);
      expect(c.explore, isTrue, reason: 'missing');
      expect(c.likeCounts, isTrue, reason: 'not a bool');
      expect(c.sharing, isFalse);

      final all = FeedConfig.fromJson(const {});
      expect([all.stories, all.comments, all.explore, all.likeCounts, all.sharing], everyElement(isTrue));
    });

    test('fetchConfig reads /feed/config once per session window', () async {
      final fake = _FakeFeed({
        'GET feed/config': {'stories': true, 'comments': false, 'explore': true, 'like_counts': false, 'sharing': false},
      });
      final repo = _repo(fake);

      final c = await repo.fetchConfig();
      expect(c.comments, isFalse);
      expect(c.likeCounts, isFalse);
      expect(c.sharing, isFalse);
      expect(FeedRepo.cachedConfig.sharing, isFalse);

      await repo.fetchConfig();
      expect(fake.asked, hasLength(1), reason: 'cached');
    });

    test('a failed fetch is all on, and not cached', () async {
      final fake = _FakeFeed(const {}, status: const {'GET feed/config': 500});
      final repo = _repo(fake);

      final c = await repo.fetchConfig();
      expect([c.stories, c.comments, c.explore, c.likeCounts, c.sharing], everyElement(isTrue));
      await repo.fetchConfig();
      expect(fake.asked, hasLength(2), reason: 'a later screen asks again');
    });
  });

  group('Utforsk cards follow the switches', () {
    setUpAll(() {
      OpsCustomerApi.networkEnabled = false;
      FeedPostCard.loadImages = false;
    });
    tearDownAll(() => OpsCustomerApi.networkEnabled = true);

    Future<void> pump(WidgetTester tester, FeedConfig config) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UtforskFeedTab(bottomReserve: 0, repo: _TabRepo(config), api: _Api(), butikkApi: _Butikk()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets('all on: like count and share are there', (tester) async {
      await pump(tester, FeedConfig.defaults);
      expect(find.byKey(const Key('a1_feed_like_1')), findsOneWidget);
      expect(find.byKey(const Key('a1_feed_like_count_1')), findsOneWidget);
      expect(find.text('214'), findsOneWidget);
      expect(find.byKey(const Key('a1_feed_share_1')), findsOneWidget);
    });

    testWidgets('like counts and sharing off: the heart stays, the number and share go', (tester) async {
      await pump(tester, const FeedConfig(likeCounts: false, sharing: false));
      expect(find.byKey(const Key('a1_feed_like_1')), findsOneWidget, reason: 'the like action stays');
      expect(find.byKey(const Key('a1_feed_like_count_1')), findsNothing);
      expect(find.text('214'), findsNothing);
      expect(find.byKey(const Key('a1_feed_share_1')), findsNothing);
      expect(find.byKey(const Key('a1_feed_report_1')), findsOneWidget, reason: 'report is not a share');
    });
  });

  group('Ærend post without a shop', () {
    test('the detail parses with an empty store id', () {
      final d = FeedPostDetail.fromJson(_storelessJson());
      expect(d.id, '501');
      expect(d.store.id, isEmpty);
      expect(d.store.name, 'Ærend');
      expect(d.store.logoUrl, isNull);
      expect(d.hasStore, isFalse);
      expect(d.publisherType, 'aerend');
      expect(d.headline, 'Nytt fra Ærend');
      expect(d.comments.items, isEmpty);
    });

    test('a store post still has its shop', () {
      final json = _storelessJson()
        ..['store'] = {'id': '28', 'name': 'Møllaren', 'slug': 'mollaren', 'logo_url': null, 'is_following': true}
        ..remove('publisher')
        ..remove('headline');
      final p = FeedPost.fromJson(json);
      expect(p.hasStore, isTrue);
      expect(p.publisherType, 'store');
      expect(p.store.isFollowing, isTrue);
    });

    testWidgets('the post renders with «Ærend» as the publisher', (tester) async {
      final d = FeedPostDetail.fromJson(_storelessJson());
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('no'),
        home: PostDetailScreen(postId: d.id, previewPost: d, previewComments: const []),
      ));
      await tester.pump();
      expect(find.text('Ærend'), findsWidgets);
    });

    Future<void> pumpDetail(WidgetTester tester, FeedConfig config) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('no'),
        home: PostDetailScreen(postId: '501', repo: _DetailRepo(config: config)),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('post detail: all on has the input, share and the like count', (tester) async {
      await pumpDetail(tester, FeedConfig.defaults);
      expect(find.byKey(const Key('post-detail-comments-off')), findsNothing);
      expect(find.byKey(const Key('post-detail-share')), findsOneWidget);
      expect(find.byKey(const Key('feed-post-detail-like-count')), findsOneWidget);
    });

    testWidgets('post detail: the switches off, and a shopless publisher opens nothing', (tester) async {
      await pumpDetail(tester, const FeedConfig(comments: false, sharing: false, likeCounts: false));
      expect(find.byKey(const Key('post-detail-comments-off')), findsOneWidget);
      expect(find.text('Kommentarer er slått av'), findsOneWidget);
      expect(find.byKey(const Key('post-detail-share')), findsNothing);
      expect(find.byKey(const Key('feed-post-detail-like-count')), findsNothing);
      expect(find.byKey(const Key('post-detail-report')), findsOneWidget);

      // «Ærend» is not a shop: tapping the name pushes no store profile.
      await tester.tap(find.text('Ærend').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(StoreProfileScreen), findsNothing);
      expect(find.byType(PostDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('comments', () {
    test('a comment is reported with its reason', () async {
      final fake = _FakeFeed({
        'POST comments/9/report': {'comment_id': '9', 'report_id': '1', 'reported': true, 'already_reported': false},
      });
      expect(await _repo(fake).reportComment('9', reason: 'spam', note: ' '), isTrue);
      expect(fake.asked.single.data, {'reason': 'spam'});

      final again = _FakeFeed({
        'POST comments/9/report': {'comment_id': '9', 'report_id': '1', 'reported': true, 'already_reported': true},
      });
      expect(await _repo(again).reportComment('9', reason: 'other', note: 'Feil'), isFalse);
      expect(again.asked.single.data, {'reason': 'other', 'note': 'Feil'});
    });

    testWidgets('«Rapporter kommentar» asks why, then reports', (tester) async {
      final fake = _FakeFeed({
        'POST comments/9/report': {'comment_id': '9', 'reported': true, 'already_reported': false},
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => reportFeedComment(context, '9', repo: _repo(fake)),
              child: const Text('rapporter'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('rapporter'));
      await tester.pumpAndSettle();
      expect(find.text('Hvorfor rapporterer du kommentaren?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('feed-report-offensive')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(fake.asked.single.path, 'comments/9/report');
      expect(fake.asked.single.data, {'reason': 'offensive'});
      expect(find.text('Takk! Vi ser på kommentaren.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    test('own comments are told from others by the user id', () async {
      FeedComment c(String userId) => FeedComment(
        id: '1',
        postId: '501',
        user: FeedCommentUser(id: userId, name: 'Kari'),
        body: 'Hei',
        createdAt: DateTime(2026, 10, 8),
      );
      expect(isOwnFeedComment(c('5')), isFalse, reason: 'logged out');
      await prefSetInt(prefUserId, 5);
      expect(isOwnFeedComment(c('5')), isTrue);
      expect(isOwnFeedComment(c('6')), isFalse);
    });

    testWidgets('a refused comment says the server\'s words and turns the input off', (tester) async {
      PostDetailBloc? bloc;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: _Host(
          _DetailRepo(
            refusal: const FeedInternalErrorException('comments_disabled', 'Kommentarer er slått av.', statusCode: 403),
          ),
          (b) => bloc = b,
        ),
      ));
      bloc!.handleEvent(const PostDetailInitRequested());
      await tester.pump();
      await tester.pump();
      expect(bloc!.currentState, isA<PostDetailLoaded>());

      bloc!.handleEvent(const PostDetailCommentSubmitRequested('Hei'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kommentarer er slått av.'), findsOneWidget);
      expect(bloc!.config.value.comments, isFalse);
      expect((bloc!.currentState as PostDetailLoaded).commentSending, isFalse);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a muted customer is told so', (tester) async {
      PostDetailBloc? bloc;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: _Host(
          _DetailRepo(
            refusal: const FeedInternalErrorException('user_muted', 'Du kan ikke kommentere akkurat nå.', statusCode: 403),
          ),
          (b) => bloc = b,
        ),
      ));
      bloc!.handleEvent(const PostDetailInitRequested());
      await tester.pump();
      await tester.pump();
      bloc!.handleEvent(const PostDetailCommentSubmitRequested('Hei'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Du kan ikke kommentere akkurat nå.'), findsOneWidget);
      expect(bloc!.config.value.comments, isTrue, reason: 'muted is not switched off');
      await tester.pump(const Duration(seconds: 5));
    });
  });

  test('FeedPage stays empty-safe', () {
    expect(FeedPage.fromJson(const {}, FeedComment.fromJson).items, isEmpty);
  });
}
