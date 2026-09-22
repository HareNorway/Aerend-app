import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_post.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/data/feed/feed_story.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_empty_followed.dart';
import 'package:aerend_customer/screens/feed/components/feed_error_state.dart';
import 'package:aerend_customer/screens/feed/components/feed_login_gate.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_card.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_skeleton.dart';
import 'package:aerend_customer/screens/feed/components/feed_stories_row.dart';
import 'package:aerend_customer/screens/feed/components/feed_stories_skeleton.dart';
import 'package:aerend_customer/screens/feed/utils/feed_time_ago.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
}

FeedPost _fakePost({
  bool isLiked = false,
  int likeCount = 42,
  int commentCount = 3,
  DateTime? publishedAt,
}) {
  return FeedPost(
    id: 'post-1',
    store: const FeedStore(
      id: '5',
      name: 'Sky Bangkok',
      slug: 'sky-bangkok',
      logoUrl: null,
      isFollowing: true,
    ),
    caption: 'Fresh matkasse fra Bergen',
    media: const FeedMedia(
      cloudinaryPublicId: 'hare/dev/posts/sample',
      cloudinaryVersion: '1',
      format: 'jpg',
      width: 1080,
      height: 1080,
      resourceType: 'image',
    ),
    likeCount: likeCount,
    commentCount: commentCount,
    isLiked: isLiked,
    publishedAt: publishedAt ?? DateTime.now().subtract(const Duration(hours: 2)),
  );
}

FeedStoreStories _fakeStoreStories(String name) {
  return FeedStoreStories(
    store: FeedStore(
      id: 'store-$name',
      name: name,
      slug: name.toLowerCase(),
      logoUrl: null,
      isFollowing: true,
    ),
    stories: const [],
  );
}

void main() {
  testWidgets('FeedLoginGate renders login prompt and button', (tester) async {
    await _pump(tester, const FeedLoginGate());

    expect(find.text('Please log in to use Ærend Feed'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('FeedEmptyFollowed renders message and explore button',
      (tester) async {
    var tapped = false;
    await _pump(tester, FeedEmptyFollowed(onExploreTap: () => tapped = true));

    expect(find.text('Follow a store to see posts here'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    await tester.tap(find.text('Explore'));
    expect(tapped, isTrue);
  });

  testWidgets('FeedErrorState renders message and retry', (tester) async {
    var retried = false;
    await _pump(
      tester,
      FeedErrorState(
        message: 'Network down',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('FeedPostCard renders post fields and time ago', (tester) async {
    final post = _fakePost();
    await _pump(
      tester,
      FeedPostCard(
        post: post,
        onLikeTap: () {},
        onStoreTap: () {},
        onCommentsTap: () {},
        onVisitStoreTap: () {},
        onKebabTap: () {},
      ),
    );

    expect(find.text('Sky Bangkok'), findsOneWidget);
    expect(find.text('Fresh matkasse fra Bergen'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('View 3 comments'), findsOneWidget);
    expect(find.textContaining('h'), findsWidgets);
  });

  testWidgets('FeedPostCard shows filled heart when liked', (tester) async {
    await _pump(
      tester,
      FeedPostCard(
        post: _fakePost(isLiked: true),
        onLikeTap: () {},
        onStoreTap: () {},
        onCommentsTap: () {},
        onVisitStoreTap: () {},
        onKebabTap: () {},
      ),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  testWidgets('FeedPostCard shows outlined heart when not liked',
      (tester) async {
    await _pump(
      tester,
      FeedPostCard(
        post: _fakePost(isLiked: false),
        onLikeTap: () {},
        onStoreTap: () {},
        onCommentsTap: () {},
        onVisitStoreTap: () {},
        onKebabTap: () {},
      ),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('FeedPostCard disables like while in flight', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      FeedPostCard(
        post: _fakePost(),
        isLikeInFlight: true,
        onLikeTap: () => taps++,
        onStoreTap: () {},
        onCommentsTap: () {},
        onVisitStoreTap: () {},
        onKebabTap: () {},
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('FeedPostCard onLikeTap fires when heart tapped', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      FeedPostCard(
        post: _fakePost(),
        onLikeTap: () => tapped = true,
        onStoreTap: () {},
        onCommentsTap: () {},
        onVisitStoreTap: () {},
        onKebabTap: () {},
      ),
    );

    final heart = find.byIcon(Icons.favorite_border_rounded);
    await tester.ensureVisible(heart);
    await tester.tap(heart);
    expect(tapped, isTrue);
  });

  testWidgets('FeedStoriesRow renders Your story and store bubbles',
      (tester) async {
    await _pump(
      tester,
      FeedStoriesRow(
        storeStories: [
          _fakeStoreStories('Kaibosh'),
          _fakeStoreStories('Folk og Fe'),
        ],
        onStoreStoriesTap: (_) {},
        onYourStoryTap: () {},
      ),
    );

    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('Kaibosh'), findsOneWidget);
    expect(find.text('Folk og Fe'), findsOneWidget);
  });

  testWidgets('FeedStoriesRow empty list renders shrink', (tester) async {
    await _pump(
      tester,
      FeedStoriesRow(
        storeStories: const [],
        onStoreStoriesTap: (_) {},
        onYourStoryTap: () {},
      ),
    );

    expect(find.byType(FeedStoriesRow), findsOneWidget);
    expect(find.text('Your story'), findsNothing);
  });

  testWidgets('FeedStoriesSkeleton renders shimmer row', (tester) async {
    await _pump(tester, const FeedStoriesSkeleton());

    expect(find.byType(FeedStoriesSkeleton), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('FeedPostSkeleton renders placeholder', (tester) async {
    await _pump(tester, const FeedPostSkeleton());

    expect(find.byType(FeedPostSkeleton), findsOneWidget);
    expect(find.byType(AspectRatio), findsOneWidget);
  });
}
