import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aerend_customer/data/feed/feed_store.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/feed/components/feed_search_result_tile.dart';
import 'package:aerend_customer/screens/feed/search/feed_search_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

FeedStore _store({required String name}) {
  return FeedStore(
    id: 'store-1',
    name: name,
    slug: 'sky-bangkok',
    logoUrl: null,
    isFollowing: false,
  );
}

void main() {
  testWidgets('FeedSearchScreen shows search hint in field', (tester) async {
    await tester.pumpWidget(_wrap(const FeedSearchScreen()));
    await tester.pump();
    expect(find.text('Search stores'), findsOneWidget);
  });

  testWidgets('FeedSearchResultTile renders name and slug', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: FeedSearchResultTile(
            store: _store(name: 'Sky Bangkok'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Sky Bangkok'), findsOneWidget);
    expect(find.text('@sky-bangkok'), findsOneWidget);
    await tester.tap(find.text('Sky Bangkok'));
    expect(tapped, isTrue);
  });

  testWidgets('FeedSearchResultTile shows following icon when isFollowing',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: FeedSearchResultTile(
            store: FeedStore(
              id: '1',
              name: 'Test',
              slug: 'test',
              isFollowing: true,
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
