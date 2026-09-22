import 'package:aerend_customer/data/feed/feed_tab_item.dart';
import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/networking/ops/ops_feed_api.dart';
import 'package:aerend_customer/screens/feed/components/feed_publisher_tabs.dart';
import 'package:aerend_customer/screens/feed/components/feed_tab_card.dart';
import 'package:aerend_customer/screens/feed/components/vaagen_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The customer feed's publisher tabs, category chips, cards and Vågen
/// (feed update spec §3).

Widget wrap(Widget child, {Locale locale = const Locale('no')}) {
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

Map<String, dynamic> media() => <String, dynamic>{
      'cloudinary_public_id': 'demo/sample',
      'cloudinary_version': '1',
      'format': 'jpg',
      'width': 1080,
      'height': 1080,
      'resource_type': 'image',
    };

void main() {
  group('tab item parsing', () {
    test('a store post keeps its store', () {
      final FeedTabItem item = FeedTabItem.fromJson(<String, dynamic>{
        'id': '1',
        'publisher': <String, dynamic>{
          'type': 'store',
          'name': 'Torgboden',
          'logo_url': null,
        },
        'store': <String, dynamic>{
          'id': '77',
          'name': 'Torgboden',
          'slug': 'torgboden',
          'logo_url': null,
          'is_following': true,
        },
        'post_type': 'tilbud',
        'headline': 'Fersk skrei fra Torget',
        'caption': 'Kom før 18',
        'media': media(),
      });

      expect(item.store?.id, '77');
      expect(item.isFromAerend, isFalse);
      expect(item.title, 'Fersk skrei fra Torget');
    });

    test('an Ærend post has no store and does not pretend to', () {
      final FeedTabItem item = FeedTabItem.fromJson(<String, dynamic>{
        'id': '2',
        'publisher': <String, dynamic>{'type': 'aerend', 'name': 'Ærend'},
        'store': null,
        'post_type': 'ny_pa_aerend',
        'headline': 'Ny på Ærend: Torgboden',
        'caption': '',
        'media': media(),
      });

      // The older post card assumes a store; this is why tab items are a
      // separate type rather than a FeedPost with a nullable field bolted on.
      expect(item.store, isNull);
      expect(item.isFromAerend, isTrue);
      expect(item.publisherName, 'Ærend');
    });

    test('a post with no headline falls back to its caption', () {
      final FeedTabItem item = FeedTabItem.fromJson(<String, dynamic>{
        'id': '3',
        'publisher': <String, dynamic>{'type': 'store', 'name': 'Torgboden'},
        'caption': 'Dagens rett: fiskesuppe',
        'media': media(),
      });

      expect(item.title, 'Dagens rett: fiskesuppe');
    });

    test('a page carries the tab label the server chose', () {
      final FeedTabPage page = FeedTabPage.fromJson(<String, dynamic>{
        'tab': 'naerheten',
        'label': 'I nærheten',
        'items': <dynamic>[],
        'next_cursor': null,
      });

      // Taken from the server so the two can never disagree about what the tab
      // is called.
      expect(page.label, 'I nærheten');
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('publisher tabs', () {
    testWidgets('both tabs are named in Norwegian', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          FeedPublisherTabs(
            active: FeedPublisherTab.stores,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publisert av butikker'), findsOneWidget);
      expect(find.text('Publisert av Ærend'), findsOneWidget);
    });

    testWidgets('tapping the other tab reports it', (WidgetTester tester) async {
      FeedPublisherTab? picked;

      await tester.pumpWidget(
        wrap(
          FeedPublisherTabs(
            active: FeedPublisherTab.stores,
            onSelected: (FeedPublisherTab t) => picked = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feed_tab_aerend')));
      await tester.pump();

      expect(picked, FeedPublisherTab.aerend);
    });
  });

  group('category chips', () {
    const List<FeedCategory> categories = <FeedCategory>[
      FeedCategory(slug: 'mat_fisk', label: 'Fisk'),
      FeedCategory(slug: 'restaurant', label: 'Restaurant'),
    ];

    testWidgets('Alle is offered alongside the configured categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          FeedCategoryChips(
            categories: categories,
            selected: null,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed_category_all')), findsOneWidget);
      expect(find.text('Fisk'), findsOneWidget);
      expect(find.text('Restaurant'), findsOneWidget);
    });

    testWidgets('picking a category reports its slug, not its label', (
      WidgetTester tester,
    ) async {
      String? picked = 'unset';

      await tester.pumpWidget(
        wrap(
          FeedCategoryChips(
            categories: categories,
            selected: null,
            onSelected: (String? slug) => picked = slug,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feed_category_mat_fisk')));
      await tester.pump();

      // The slug travels, so a label change is not an API change.
      expect(picked, 'mat_fisk');
    });

    testWidgets('an empty config renders no strip at all', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          FeedCategoryChips(
            categories: const <FeedCategory>[],
            selected: null,
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('feed_category_chips')), findsNothing);
    });
  });

  group('tab card', () {
    FeedTabItem item({bool aerend = false, String? bydel}) {
      return FeedTabItem.fromJson(<String, dynamic>{
        'id': '9',
        'publisher': <String, dynamic>{
          'type': aerend ? 'aerend' : 'store',
          'name': aerend ? 'Ærend' : 'Torgboden',
        },
        'store': aerend
            ? null
            : <String, dynamic>{
                'id': '77',
                'name': 'Torgboden',
                'slug': 'torgboden',
                'logo_url': null,
                'is_following': false,
              },
        'headline': 'Fersk skrei fra Torget',
        'caption': 'Kom før 18',
        'bydel': bydel,
        'media': media(),
      });
    }

    /// Cards live in a scrolling list in the app, so they are given unbounded
    /// height here too. Dropped straight into a Scaffold body they overflow on
    /// a short screen, which is a property of the placement rather than the
    /// card. `pump` rather than `pumpAndSettle`: the image placeholder shimmers
    /// forever, so settling never finishes.
    Widget inList(Widget card) => wrap(ListView(children: <Widget>[card]));

    testWidgets('an Ærend card is badged as ours', (WidgetTester tester) async {
      await tester.pumpWidget(inList(FeedTabCard(item: item(aerend: true))));
      await tester.pump();

      // Badged on the card as well as by the tab: a card screenshotted or
      // deep-linked out of its tab must still say who wrote it.
      expect(find.byKey(const Key('feed_tab_aerend_badge_9')), findsOneWidget);
    });

    testWidgets('a store card is not badged', (WidgetTester tester) async {
      await tester.pumpWidget(inList(FeedTabCard(item: item())));
      await tester.pump();

      expect(find.byKey(const Key('feed_tab_aerend_badge_9')), findsNothing);
      expect(find.text('Torgboden'), findsOneWidget);
    });

    testWidgets('no price is shown when the live price is unknown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(inList(FeedTabCard(item: item())));
      await tester.pump();

      // A card that quotes a stale price is worse than a card with no price.
      expect(find.byKey(const Key('feed_tab_price_9')), findsNothing);
    });

    testWidgets('the live price is shown when it is known', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        inList(FeedTabCard(item: item(), livePriceOre: 4950)),
      );
      await tester.pump();

      expect(find.text('49,50 kr'), findsOneWidget);
    });

    test('whole kroner drop the decimals', () {
      expect(FeedTabCard.formatOre(14900), '149');
      expect(FeedTabCard.formatOre(4950), '49,50');
    });
  });

  group('Vågen', () {
    testWidgets('an available pull offers the button', (
      WidgetTester tester,
    ) async {
      bool pulled = false;

      await tester.pumpWidget(
        wrap(VaagenCard(available: true, onReel: () => pulled = true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dagens napp'), findsOneWidget);
      await tester.tap(find.byKey(const Key('vaagen_reel')));
      await tester.pump();

      expect(pulled, isTrue);
    });

    testWidgets('a spent pull stays visible and says so', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const VaagenCard(available: false)));
      await tester.pumpAndSettle();

      // Visible, not hidden: a card that vanishes leaves the customer
      // wondering whether they imagined it or whether it worked.
      expect(find.byKey(const Key('vaagen_card')), findsOneWidget);
      expect(find.text('Dagens napp er trukket opp'), findsOneWidget);
      expect(find.byKey(const Key('vaagen_reel')), findsNothing);
    });

    testWidgets('a pull in flight cannot be double-tapped', (
      WidgetTester tester,
    ) async {
      int pulls = 0;

      await tester.pumpWidget(
        wrap(VaagenCard(available: true, pending: true, onReel: () => pulls++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vaagen_reel')));
      await tester.pump();

      expect(pulls, 0);
    });

    test('either outcome means today is spent', () {
      const VaagenReelResult first =
          VaagenReelResult(reeled: true, already: false, day: '2026-09-22');
      const VaagenReelResult second =
          VaagenReelResult(reeled: false, already: true, day: '2026-09-22');

      expect(first.spent, isTrue);
      // `already` is not a failure: the state the app wanted is the state that
      // exists, so it renders the spent card rather than an error.
      expect(second.spent, isTrue);
    });
  });
}
