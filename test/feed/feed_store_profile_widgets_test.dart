import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_store_profile.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_grid.dart';
import 'package:aerend_customer/screens/feed/components/feed_post_thumbnail.dart';
import 'package:aerend_customer/screens/feed/components/feed_store_profile_header.dart';
import 'package:aerend_customer/screens/feed/storeProfile/store_profile.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:aerend_customer/data/feed/feed_post.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

FeedStoreProfile _profile({
  bool isFollowing = false,
  bool hasActiveStories = false,
}) {
  return FeedStoreProfile(
    id: 'store-1',
    name: 'Sky Bangkok',
    slug: 'sky-bangkok',
    logoUrl: null,
    coverUrl: null,
    isActive: true,
    isSportsClub: false,
    isFollowing: isFollowing,
    followerCount: 120,
    postCount: 8,
    bio: 'Fresh food daily',
    description: null,
    hasActiveStories: hasActiveStories,
    deeplinkPath: '/stores/sky-bangkok',
  );
}

void main() {
  testWidgets('StoreProfileScreen renders header with avatar + name + counts',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        FeedStoreProfileHeader(
          profile: _profile(),
          onFollowTap: () {},
          onVisitStoreTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sky Bangkok'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('Fresh food daily'), findsOneWidget);
  });

  testWidgets('Follow button shows Follow when isFollowing=false', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FeedStoreProfileHeader(
          profile: _profile(isFollowing: false),
          onFollowTap: () {},
          onVisitStoreTap: () {},
        ),
      ),
    );
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('Follow button shows Following when isFollowing=true',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        FeedStoreProfileHeader(
          profile: _profile(isFollowing: true),
          onFollowTap: () {},
          onVisitStoreTap: () {},
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Following'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Visit Store button shows Visit store', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FeedStoreProfileHeader(
          profile: _profile(),
          onFollowTap: () {},
          onVisitStoreTap: () {},
        ),
      ),
    );
    expect(find.text('Visit store'), findsOneWidget);
  });

  testWidgets('Tap Follow fires onFollowTap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        FeedStoreProfileHeader(
          profile: _profile(),
          onFollowTap: () => tapped = true,
          onVisitStoreTap: () {},
        ),
      ),
    );
    await tester.tap(find.text('Follow'));
    expect(tapped, isTrue);
  });

  testWidgets('Empty posts grid shows store_profile_no_posts', (tester) async {
    final controller = PagingController<String?, FeedPost>(firstPageKey: null);
    controller.appendLastPage([]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 400,
          child: FeedPostGrid(
            pagingController: controller,
            onPostTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('Store profile uses posts grid divider instead of stories tab',
      (tester) async {
    await tester.pumpWidget(
      _wrap(StoreProfileScreen(
        storeId: 'store-1',
        previewProfile: _profile(hasActiveStories: true),
      )),
    );
    await tester.pump();

    expect(find.text('Stories'), findsNothing);
    expect(find.byIcon(Icons.grid_on_rounded), findsOneWidget);
  });
}
