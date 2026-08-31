import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_comment.dart';
import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_post.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_comment_input_panel.dart';
import 'package:aerend_customer/screens/feed/components/feed_comment_tile.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_detail_card.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

FeedPost _post() {
  return FeedPost(
    id: 'post-1',
    store: const FeedStore(
      id: '5',
      name: 'Sky Bangkok',
      slug: 'sky-bangkok',
      logoUrl: null,
      isFollowing: true,
    ),
    caption: 'Fresh matkasse',
    media: const FeedMedia(
      cloudinaryPublicId: 'sample',
      cloudinaryVersion: '1',
      format: 'jpg',
      width: 1080,
      height: 1080,
      resourceType: 'image',
    ),
    likeCount: 10,
    commentCount: 2,
    isLiked: false,
    publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
  );
}

FeedComment _comment() {
  return FeedComment(
    id: 'c1',
    postId: 'post-1',
    user: const FeedCommentUser(id: 'u1', name: 'Alex', avatarUrl: null),
    body: 'Looks great',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );
}

void main() {
  testWidgets('PostDetailScreen renders FeedPostDetailCard with given post',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: SingleChildScrollView(
            child: FeedPostDetailCard(
              post: _post(),
              onLikeTap: () {},
              onStoreTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sky Bangkok'), findsOneWidget);
    expect(find.text('Fresh matkasse'), findsOneWidget);
  });

  testWidgets('Comments list renders FeedCommentTile per comment', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ListView(
          children: [
            FeedCommentTile(comment: _comment()),
            FeedCommentTile(comment: _comment()),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FeedCommentTile), findsNWidgets(2));
  });

  testWidgets('Empty comments shows post_detail_no_comments', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(child: Text(l10n.post_detail_no_comments)),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Be the first to comment'), findsOneWidget);
  });

  testWidgets('Comment input shows post_detail_comment_hint', (tester) async {
    await tester.pumpWidget(
      _wrap(PostDetailScreen(
        postId: 'post-1',
        previewPost: _post(),
      )),
    );
    await tester.pump();

    expect(find.text('Add a comment…'), findsOneWidget);
  });

  testWidgets('Send button disabled on empty input', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          bottomNavigationBar: FeedCommentInputPanel(onSubmit: (_) {}),
        ),
      ),
    );
    await tester.pump();

    final send = tester.widget<IconButton>(
      find.byKey(const Key('feed_comment_send_btn')),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('Send button enabled when typing non-empty text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          bottomNavigationBar: FeedCommentInputPanel(onSubmit: (_) {}),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('feed_comment_input')), 'Hi');
    await tester.pump();
    final send = tester.widget<IconButton>(
      find.byKey(const Key('feed_comment_send_btn')),
    );
    expect(send.onPressed, isNotNull);
  });

  testWidgets('Char counter shows when text > 1500 chars', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          bottomNavigationBar: FeedCommentInputPanel(onSubmit: (_) {}),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('feed_comment_input')),
      'a' * 1501,
    );
    await tester.pump();
    expect(find.textContaining('/ 2000'), findsOneWidget);
  });

  testWidgets('onCommentSubmit callback fires when send tapped', (tester) async {
    String? body;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          bottomNavigationBar: FeedCommentInputPanel(
            onSubmit: (t) => body = t,
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('feed_comment_input')), 'Nice!');
    await tester.pump();
    await tester.tap(find.byKey(const Key('feed_comment_send_btn')));
    expect(body, 'Nice!');
  });

  testWidgets('FeedPostDetailCard renders caption', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Material(
          child: SingleChildScrollView(
            child: FeedPostDetailCard(
              post: _post(),
              onLikeTap: () {},
              onStoreTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Fresh matkasse'), findsOneWidget);
  });
}
