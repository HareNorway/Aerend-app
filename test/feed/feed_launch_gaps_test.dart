import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_empty_followed.dart';
import 'package:aerend_customer/screens/feed/components/feed_empty_no_posts.dart';
import 'package:aerend_customer/screens/feed/feedHome/feed_home_state.dart';
import 'package:aerend_customer/screens/feed/postDetail/post_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Launch-readiness gaps T3, T4 and T8 (FEED_HANDOVER_10DAYS.md).
///
/// These are all "the app says nothing useful when X is missing" bugs, and each
/// one is about telling two situations apart that currently look identical.

Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('T4 · two empty feeds, two answers', () {
    testWidgets('zero follows keeps the Explore call to action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(FeedEmptyFollowed(onExploreTap: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('follows with no posts drops the CTA and says to wait', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const FeedEmptyNoPosts()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed_empty_no_posts')), findsOneWidget);
      expect(
        find.text("The stores you follow haven't posted yet — check back soon!"),
        findsOneWidget,
      );

      // No CTA on purpose: pushing someone to follow more shops when they
      // already follow five reads as the app not listening.
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Explore'), findsNothing);
    });

    testWidgets('the Norwegian copy is the one the handover specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const FeedEmptyNoPosts(), locale: const Locale('no')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('De du følger har ikke postet ennå — sjekk tilbake snart!'),
        findsOneWidget,
      );
    });

    test('hasFollows survives a copyWith that does not mention it', () {
      const FeedHomeLoaded loaded = FeedHomeLoaded(stories: [], hasFollows: true);

      // Losing it here would silently flip the first page back to the wrong
      // empty state.
      expect(loaded.copyWith(storiesLoading: true).hasFollows, isTrue);
    });

    test('hasFollows starts unknown rather than false', () {
      // Unknown falls back to the CTA, which is the safer of the two wrong
      // answers: offering a way forward beats telling someone who follows
      // nobody to wait for posts that can never arrive.
      const FeedHomeLoaded loaded = FeedHomeLoaded(stories: []);

      expect(loaded.hasFollows, isNull);
    });
  });

  group('T8 · a deleted post is not a retryable error', () {
    test('PostDetailNotFound is its own state, not an error message', () {
      const PostDetailState state = PostDetailNotFound();

      expect(state, isA<PostDetailNotFound>());
      // Distinct from PostDetailError so the UI can offer "go back" instead of
      // a retry that would fail identically every time.
      expect(state, isNot(isA<PostDetailError>()));
    });

    test('the unavailable copy exists in both shipped locales', () async {
      final AppLocalizations en =
          await AppLocalizations.delegate.load(const Locale('en'));
      final AppLocalizations no =
          await AppLocalizations.delegate.load(const Locale('no'));

      expect(en.post_detail_unavailable, 'This post is no longer available');
      expect(no.post_detail_unavailable, isNotEmpty);
      expect(en.post_detail_go_back, 'Go back');
      expect(no.post_detail_go_back, 'Tilbake');
    });
  });

  group('T3 · an expired story is named, not shown as a broken image', () {
    test('the copy exists in both shipped locales', () async {
      final AppLocalizations en =
          await AppLocalizations.delegate.load(const Locale('en'));
      final AppLocalizations no =
          await AppLocalizations.delegate.load(const Locale('no'));

      expect(en.story_viewer_unavailable, 'This story is no longer available');
      expect(no.story_viewer_unavailable, isNotEmpty);
    });
  });
}
