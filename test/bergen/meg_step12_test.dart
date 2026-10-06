import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/ops/favourite_stores.dart';
import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/networking/ops/ops_customer_api.dart';
import 'package:aerend_customer/screens/bergen/meg/a3_services.dart';
import 'package:aerend_customer/screens/bergen/meg/bestillinger_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/favoritter_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/konto_screen.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_copy_a4.dart';
import 'package:aerend_customer/screens/bergen/poeng/aegil_velger_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/liga_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/opprykk_screen.dart';
import 'package:aerend_customer/screens/bergen/poeng/premiehylla_screen.dart';
import 'package:aerend_customer/screens/common/manageAddress/manage_address_dl.dart';
import 'package:aerend_customer/utils/shared_pref_utill.dart';

import '../a3/a3_fakes.dart';

/// Launch UI Step 12 — Meg and the points screens: Premiehylla, Ægil velger,
/// Fløyen-ligaen, Opprykk, Ordrehistorikk, Favoritter and Konto render from
/// the API models, and their actions reach the API.
class _FakeOrders extends OpsCustomerApi {
  _FakeOrders({this.rows = const [], this.ledger = const []});

  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> ledger;

  @override
  Future<List<Map<String, dynamic>>> orders({int limit = 50}) async => rows;

  @override
  Future<List<Map<String, dynamic>>> pointsLedger() async => ledger;
}

class _FakeFavs extends OpsCustomerApi {
  final Set<int> server = {5, 6};
  final List<String> calls = [];

  @override
  Future<Map<String, dynamic>?> favourites() async => {
    'status': 1,
    'store_ids': server.toList(),
    'total': server.length,
    'stores': [
      {'store_id': 5, 'name': 'Trattoria Del Napoli', 'address': 'Nøstegaten 51', 'eta_minutes': 15, 'open': true},
      {'store_id': 6, 'name': 'Nordnes Fisk', 'address': 'Nordnes', 'eta_minutes': 25, 'open': false, 'rating': 4.6},
    ].where((s) => server.contains(s['store_id'])).toList(),
  };

  @override
  Future<Map<String, dynamic>?> setFavourite(int storeId, bool favourite) async {
    calls.add('${favourite ? '+' : '-'}$storeId');
    favourite ? server.add(storeId) : server.remove(storeId);
    return {'status': 1, 'store_id': storeId, 'is_favourite': favourite, 'total': server.length};
  }
}

Map<String, dynamic> _ordre(int id, String state, {String butikk = 'Holy Cow', int storeId = 6, num sum = 248, bool paid = true}) => {
  'order_id': id,
  'code': 'Æ-$id',
  'store': {'id': storeId, 'name': butikk},
  'ordered_at': DateTime.now().subtract(Duration(days: id)).toIso8601String(),
  'total_pay': sum,
  'delivery_cost': 39,
  'state': state,
  'paid': paid,
  'items': [
    {'product_id': 1, 'name': 'Classic', 'quantity': 1},
    {'product_id': 2, 'name': 'Classic Fries', 'quantity': 1},
  ],
};

void main() {
  setUpAll(() => a3Bootstrap(prefs: {prefUserId: 656, prefAccessToken: 'tok', prefContactNumber: '41234567'}));
  tearDown(() {
    A3Services.reset();
    FavouriteStores.instance.reset();
  });

  // A 390-wide surface: LfFrame draws the design at 1:1.
  void phone(WidgetTester t, {double h = 2600}) {
    t.view.physicalSize = Size(390, h);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Premiehylla: points, Nivå, goal, Mine premier, the shelf, velger, locked — and Hent claims', (tester) async {
    phone(tester, h: 3200);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(PremiehyllaScreen(api: api)));
    await settle(tester);

    expect(find.byKey(const Key('hylla-poeng')), findsOneWidget);
    expect(find.text('Premiehylla'), findsOneWidget);
    expect(find.byKey(const Key('hylla-nivaa')), findsOneWidget);
    expect(find.byKey(const Key('hylla-maal')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_hylla_mine), findsOneWidget);
    expect(find.byKey(const Key('hylla-mine')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_hylla_aapent('Fløyen')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_hylla_klare(1)), findsOneWidget);
    for (final id in [7, 8, 9]) {
      expect(find.byKey(Key('hylla-premie-$id')), findsOneWidget, reason: '$id');
    }
    expect(find.byKey(const Key('hylla-velger')), findsOneWidget);
    expect(find.byKey(const Key('hylla-laast-20')), findsOneWidget);
    expect(find.text(A4MegCopy.a4_hylla_laast('Ulriken')), findsOneWidget);

    // The affordable prize: Hent opens the krev sheet; its CTA claims.
    await tester.ensureVisible(find.byKey(const Key('hylla-premie-7')));
    await tester.pump(const Duration(seconds: 2)); // the cards' entrance
    await tester.tap(find.descendant(of: find.byKey(const Key('hylla-premie-7')), matching: find.text(A4MegCopy.a4_hylla_hent)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('hylla-krev-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hylla-krev-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Premiehylla: a prize out of reach is set as the goal', (tester) async {
    phone(tester, h: 3200);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(PremiehyllaScreen(api: api)));
    await settle(tester);

    await tester.ensureVisible(find.byKey(const Key('hylla-premie-8')));
    await tester.pump(const Duration(seconds: 2)); // the cards' entrance
    // Fløibanen (900) is the goal already: its key says so and nothing is sent.
    expect(find.descendant(of: find.byKey(const Key('hylla-premie-8')), matching: find.text(A4MegCopy.a4_hylla_er_maal_kn)), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('hylla-premie-8')), matching: find.text(A4MegCopy.a4_hylla_er_maal_kn)));
    await settle(tester);
    expect(api.calls.where((c) => c.startsWith('goal:')), isEmpty);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Ægil velger: the boat, then the pick with value hint, reason and Hent', (tester) async {
    phone(tester, h: 900);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(AegilVelgerScreen(api: api)));
    await settle(tester);
    expect(api.calls, contains('pick'));
    expect(find.byKey(const Key('velger-premie')), findsNothing);

    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.byKey(const Key('velger-hopp')), findsOneWidget);
    await tester.tap(find.byKey(const Key('velger-hopp')));
    await settle(tester);

    expect(find.byKey(const Key('velger-premie')), findsOneWidget);
    expect(find.text('Kaffe hos Kaffemisjonen'), findsOneWidget);
    expect(find.text('Verdi minst 300 kr'), findsOneWidget);
    expect(find.text('Du har vært der tre torsdager på rad.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('velger-hent')));
    await settle(tester);
    expect(api.calls, contains('claim:7'));
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Fløyen-ligaen: place, table, bydel toggle, prizes; leaving asks first', (tester) async {
    phone(tester, h: 2000);
    final api = FakePointsApi();
    await tester.pumpWidget(a3App(LigaScreen(api: api)));
    await settle(tester);

    expect(find.byKey(const Key('liga-plass')), findsOneWidget);
    expect(find.byKey(const Key('liga-tabell')), findsOneWidget);
    expect(find.byKey(const Key('liga-rad-1')), findsOneWidget);
    expect(find.text('1 000'), findsOneWidget);
    expect(find.byKey(const Key('liga-premier')), findsOneWidget);

    await tester.tap(find.text('Din bydel'));
    await settle(tester);
    expect(find.byKey(const Key('liga-rad-14')), findsOneWidget);
    expect(find.text('320'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('liga-bli-av')));
    await tester.tap(find.byKey(const Key('liga-bli-av')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('liga-av-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('liga-av-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.calls, contains('optin:false'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Opprykk: the medal, the gift and the shelf line', (tester) async {
    phone(tester, h: 900);
    final api = FakePointsApi(balanceValue: const PointsBalance(available: 900, tier: 1, tierName: 'Fløyen'));
    await tester.pumpWidget(a3App(OpprykkScreen(tierName: 'Fløyen', giftName: 'Gratis levering', api: api)));
    await settle(tester);
    await tester.pump(const Duration(seconds: 3));

    expect(find.byKey(const Key('opprykk-tittel')), findsOneWidget);
    expect(find.text('Du er nå Fløyen'), findsOneWidget);
    expect(find.byKey(const Key('opprykk-gave')), findsOneWidget);
    expect(find.text('Gratis levering'), findsOneWidget);
    expect(find.byKey(const Key('opprykk-hylla')), findsOneWidget);
    expect(find.byKey(const Key('opprykk-ferdig')), findsOneWidget);
  });

  testWidgets('Ordrehistorikk: Dine faste, months, status, and an order opens its receipt', (tester) async {
    phone(tester, h: 2400);
    final api = _FakeOrders(
      rows: [
        _ordre(41, 'delivered'),
        _ordre(40, 'cancelled', butikk: 'Torgboden', storeId: 9, sum: 486),
      ],
      ledger: [
        {'ref_type': 'order', 'ref_id': '41', 'amount': 13},
      ],
    );
    await tester.pumpWidget(a3App(BestillingerScreen(api: api)));
    await settle(tester);

    expect(find.text(OhCopy.tittel), findsOneWidget);
    expect(find.text(OhCopy.under(2, 13)), findsOneWidget);
    expect(find.byKey(const Key('oh-faste')), findsOneWidget);
    expect(find.byKey(const Key('oh-ordre-41')), findsOneWidget);
    expect(find.text(OhCopy.kroner(13)), findsOneWidget);
    expect(find.text(OhCopy.levert), findsOneWidget);
    expect(find.text(OhCopy.avbestilt), findsOneWidget);

    await tester.tap(find.byKey(const Key('oh-ordre-41')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('oh-ordre-sheet')), findsOneWidget);
    expect(find.text(OhCopy.kvittering), findsOneWidget);
    expect(find.byKey(const Key('oh-ordre-igjen')), findsOneWidget);
  });

  testWidgets('Favoritter: the count, a card per store, un-heart in place, then the empty state', (tester) async {
    phone(tester, h: 900);
    final api = _FakeFavs();
    FavouriteStores.instance.reset(api: api);
    await tester.pumpWidget(a3App(const FavoritterScreen()));
    await settle(tester);

    expect(find.text('2 steder'), findsOneWidget);
    expect(find.byKey(const Key('fav-store-5')), findsOneWidget);
    expect(find.text('Trattoria Del Napoli'), findsOneWidget);
    expect(find.text('15 min · Åpen nå'), findsOneWidget);
    expect(find.text('25 min · Stengt nå · ★ 4.6'), findsOneWidget);
    expect(find.byKey(const Key('fav-kast')), findsNothing);

    await tester.tap(find.byKey(const Key('fav-heart-5')));
    await settle(tester);
    expect(api.calls, contains('-5'));
    expect(find.byKey(const Key('fav-store-5')), findsNothing);
    expect(find.text('1 sted'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fav-heart-6')));
    await settle(tester);
    expect(find.byKey(const Key('fav-kast')), findsOneWidget);
    expect(find.text('0 steder'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Konto: name chip, addresses as radios, Vipps number, cards, switches and Logg ut', (tester) async {
    phone(tester, h: 1400);
    A3Services.addressList = () async => [
      AddressListItem.fromJson({'address_id': 1, 'type': 'home', 'address': 'Nygårdsgaten 5', 'flat_no': '3. etasje', 'landmark': 'Ring på hos Kari', 'lat': '60.38', 'long': '5.33'}),
      AddressListItem.fromJson({'address_id': 2, 'type': 'work', 'address': 'Solheimsgaten 7, N/A', 'flat_no': 'N/A', 'landmark': 'N/A', 'lat': '60.37', 'long': '5.34'}),
    ];
    A3Services.cards = () async => ['Visa •• 4412'];
    await tester.pumpWidget(a3App(const KontoScreen()));
    await settle(tester);

    expect(find.text('Kari · Vipps-verifisert'), findsOneWidget);
    expect(find.text('Hjem · Nygårdsgaten 5, 3. etasje'), findsOneWidget);
    expect(find.text('Ring på hos Kari'), findsOneWidget);
    expect(find.text('Jobb · Solheimsgaten 7'), findsOneWidget);
    expect(find.text('N/A'), findsNothing);
    expect(find.text('Vipps · 412 34 567'), findsOneWidget);
    expect(find.text('Visa •• 4412'), findsOneWidget);
    expect(find.text('Apple Pay'), findsOneWidget);
    expect(find.byKey(const Key('konto-logg-ut')), findsOneWidget);

    // A radio makes the address the delivery address.
    await tester.tap(find.byKey(const Key('konto-adresse-2')));
    await settle(tester);
    expect(prefGetInt(prefNewDeliveryAddressId), 2);

    expect(A3Services.reducedMotion.value, isFalse);
    await tester.tap(find.byKey(const Key('konto-rolig')));
    await settle(tester);
    expect(A3Services.reducedMotion.value, isTrue);
  });
}
