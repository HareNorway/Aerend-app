import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_media.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/data/feed/feed_story.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/storyViewer/story_viewer_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

FeedStoreStories _entry() {
  return FeedStoreStories(
    store: const FeedStore(
      id: '5',
      name: 'Sky Bangkok',
      slug: 'sky-bangkok',
      logoUrl: null,
      isFollowing: true,
    ),
    stories: [
      FeedStory(
        id: 'story-1',
        media: const FeedMedia(
          cloudinaryPublicId: 'sample',
          cloudinaryVersion: '1',
          format: 'jpg',
          width: 1080,
          height: 1080,
          resourceType: 'image',
        ),
        caption: 'Hello story',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
  );
}

void main() {
  testWidgets('StoryViewerScreen shows close button and store name',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        StoryViewerScreen(
          stores: [_entry()],
          initialStoreIndex: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Sky Bangkok'), findsOneWidget);
    expect(find.text('Hello story'), findsOneWidget);
  });

  testWidgets('close button triggers dismiss callback', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StoryViewerScreen(
          stores: [_entry()],
          initialStoreIndex: 0,
        ),
      ),
    );
    await tester.pump();

    final btn = tester.widget<IconButton>(
      find.byKey(const Key('story_viewer_close')),
    );
    expect(btn.onPressed, isNotNull);
    btn.onPressed!.call();
    await tester.pump();
  });
}
