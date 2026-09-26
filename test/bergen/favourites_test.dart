import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/data/ops/favourite_stores.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_fav_heart.dart';
import 'package:aerend_customer/screens/bergen/meg/favoritter_screen.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

/// ops.customer.favourites as the app sees it: one list, every heart.
class _FakeFavs extends OpsCustomerApi {
  _FakeFavs({this.failWrites = false});

  final bool failWrites;
  final Set<int> server = {12};
  final List<String> calls = [];

  @override
  Future<Map<String, dynamic>?> favourites() async {
    calls.add('list');
    return {
      'status': 1,
      'store_ids': server.toList(),
      'total': server.length,
      'stores': [
        for (final id in server)
          {'store_id': id, 'name': 'Butikk $id', 'eta_minutes': 25, 'open': true},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>?> setFavourite(int storeId, bool favourite) async {
    calls.add('${favourite ? '+' : '-'}$storeId');
    if (failWrites) return null;
    favourite ? server.add(storeId) : server.remove(storeId);
    return {'status': 1, 'store_id': storeId, 'is_favourite': favourite, 'total': server.length};
  }
}

Future<void> _login() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    prefUserId: 651,
    prefAccessToken: 'tok',
  });
  await initSharedPreferences();
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavouriteStores', () {
    test('loads the list once and answers isFavourite', () async {
      final api = _FakeFavs();
      FavouriteStores.instance.reset(api: api);
      await Future.wait([
        FavouriteStores.instance.ensureLoaded(),
        FavouriteStores.instance.ensureLoaded(),
      ]);
      expect(api.calls, ['list']);
      expect(FavouriteStores.instance.isFavourite(12), isTrue);
      expect(FavouriteStores.instance.stores.single.name, 'Butikk 12');
    });

    test('a failed write puts the heart back', () async {
      final api = _FakeFavs(failWrites: true);
      FavouriteStores.instance.reset(api: api);
      final ok = await FavouriteStores.instance.set(40, true);
      expect(ok, isFalse);
      expect(FavouriteStores.instance.isFavourite(40), isFalse);
    });
  });

  group('BergenFavHeart', () {
    testWidgets('tapping hearts the store, fills it and says so', (tester) async {
      await _login();
      final api = _FakeFavs();
      FavouriteStores.instance.reset(api: api);

      await tester.pumpWidget(_host(const BergenFavHeart(storeId: 40)));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('fav-heart-40')));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
      expect(api.calls, contains('+40'));
      // Every frame of the popp, not just its end: the curve overshoots.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text(FavCopy.lagtTil), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byKey(const Key('fav-heart-40')));
      await tester.pump();
      expect(api.calls, contains('-40'));
      expect(FavouriteStores.instance.isFavourite(40), isFalse);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('two hearts for the same store stay in step', (tester) async {
      await _login();
      FavouriteStores.instance.reset(api: _FakeFavs());

      await tester.pumpWidget(_host(const Column(
        children: [
          BergenFavHeart(key: Key('a'), storeId: 7),
          BergenFavHeart(key: Key('b'), storeId: 7, onDark: true),
        ],
      )));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a')));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('fav-heart-7')),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNWidgets(2),
      );
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a guest is asked to log in and nothing is written', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await initSharedPreferences();
      final api = _FakeFavs();
      FavouriteStores.instance.reset(api: api);

      await tester.pumpWidget(_host(const BergenFavHeart(storeId: 9)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('fav-heart-9')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(FavCopy.loggInn), findsOneWidget);
      expect(api.calls.where((c) => c.startsWith('+')), isEmpty);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  testWidgets('Favoritter lists every hearted store and un-hearts in place', (tester) async {
    await _login();
    final api = _FakeFavs()..server.addAll({31, 32});
    FavouriteStores.instance.reset(api: api);

    await tester.pumpWidget(const MaterialApp(home: FavoritterScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('fav-liste')), findsOneWidget);
    expect(find.text('Butikk 31'), findsOneWidget);
    expect(find.text('Butikk 12'), findsOneWidget);
    expect(find.byKey(const Key('fav-kast')), findsNothing);

    await tester.tap(find.byKey(const Key('fav-heart-31')));
    await tester.pump();
    expect(find.text('Butikk 31'), findsNothing);
    expect(api.calls, contains('-31'));
    await tester.pump(const Duration(seconds: 4));
  });

  test('Suggestion reads the Fjordfiske card facts', () {
    final s = Suggestion.fromJson({
      'id': 3,
      'reason_code': 'offer_liked_product',
      'reason': 'Du liker denne',
      'store_id': 5,
      'store_product_id': 88,
      'bydel': 'Bergenhus',
      'store_name': 'Torgboden',
      'eta_minutes': 30,
      'price_ore': 18000,
    });
    expect(s.bydel, 'Bergenhus');
    expect(s.storeName, 'Torgboden');
    expect(s.etaMinutes, 30);
    expect(s.priceOre, 18000);
  });
}
