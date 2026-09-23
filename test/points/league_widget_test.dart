import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/league_models.dart';
import 'package:aerend_customer/screens/points/widgets/league_card.dart';

/// AGIL-2-PLAN Phase 5 — the league screen: opt-in, tier-blind, top-10 + own rank +
/// "Din bydel".
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  League league({bool optedIn = true, int ownRank = 14}) => League(
        month: '2026-09',
        optedIn: optedIn,
        participants: 120,
        capPerOrder: 200,
        top: List.generate(
          10,
          (i) => LeagueStanding(
            rank: i + 1,
            userId: 100 + i,
            points: 1000 - i * 50,
            bydel: 'Bergenhus',
          ),
        ),
        own: LeagueStanding(rank: ownRank, userId: 999, points: 320, bydel: 'Årstad'),
        bydel: 'Årstad',
        bydelStandings: const [
          LeagueStanding(rank: 14, userId: 999, points: 320, bydel: 'Årstad'),
          LeagueStanding(rank: 19, userId: 888, points: 210, bydel: 'Årstad'),
        ],
      );

  testWidgets('before joining, it explains itself and offers to join', (tester) async {
    await pump(tester, LeagueCard(league: league(optedIn: false), onOptIn: () {}));

    expect(find.byKey(const Key('league-opt-in')), findsOneWidget);
    expect(find.byKey(const Key('league-opt-in-explainer')), findsOneWidget);
    // Nobody is ranked without choosing to be.
    expect(find.byKey(const Key('league-own-rank')), findsNothing);
    expect(find.byKey(const Key('league-top')), findsNothing);
  });

  testWidgets('joining is a real action', (tester) async {
    var joined = false;
    await pump(tester, LeagueCard(league: league(optedIn: false), onOptIn: () => joined = true));

    await tester.tap(find.byKey(const Key('league-opt-in')));
    expect(joined, isTrue);
  });

  testWidgets('shows the top ten', (tester) async {
    await pump(tester, LeagueCard(league: league()));

    expect(find.byKey(const Key('league-top')), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('shows your own rank even when it is outside the top ten', (tester) async {
    await pump(tester, LeagueCard(league: league(ownRank: 47)));

    expect(find.byKey(const Key('league-own-rank')), findsOneWidget);
    expect(find.textContaining('Du er nr. 47 av 120'), findsOneWidget);
  });

  testWidgets('shows "Din bydel"', (tester) async {
    await pump(tester, LeagueCard(league: league()));

    expect(find.byKey(const Key('league-bydel')), findsOneWidget);
    expect(find.text('DIN BYDEL · ÅRSTAD'), findsOneWidget);
  });

  testWidgets('states that the level does not count and the order cap applies',
      (tester) async {
    await pump(tester, LeagueCard(league: league()));

    // Stated on the surface, so the league cannot be read as a second status ladder.
    expect(
      find.text('Nivået ditt teller ikke med. Én bestilling gir maks 200 ligapoeng.'),
      findsOneWidget,
    );
  });

  testWidgets('leaving is always offered', (tester) async {
    var left = false;
    await pump(tester, LeagueCard(league: league(), onOptOut: () => left = true));

    await tester.tap(find.byKey(const Key('league-opt-out')));
    expect(left, isTrue);
  });

  testWidgets('the bydel table can be suppressed', (tester) async {
    await pump(tester, LeagueCard(league: league(), showBydel: false));

    expect(find.byKey(const Key('league-bydel')), findsNothing);
  });

  group('parsing', () {
    test('reads the API envelope', () {
      final parsed = League.fromJson({
        'opted_in': true,
        'tier_blind': true,
        'cap_per_order': 200,
        'league': {
          'month': '2026-09',
          'state': 'open',
          'participants': 3,
          'top': [
            {'rank': 1, 'user_id': 5, 'points': 400, 'bydel': 'Bergenhus'},
          ],
          'own': {'rank': 3, 'user_id': 9, 'points': 120, 'bydel': 'Årstad'},
          'din_bydel': {
            'bydel': 'Årstad',
            'standings': [
              {'rank': 3, 'user_id': 9, 'points': 120, 'bydel': 'Årstad'},
            ],
          },
        },
      });

      expect(parsed.month, '2026-09');
      expect(parsed.optedIn, isTrue);
      expect(parsed.tierBlind, isTrue);
      expect(parsed.top, hasLength(1));
      expect(parsed.own!.rank, 3);
      expect(parsed.bydel, 'Årstad');
      expect(parsed.bydelStandings, hasLength(1));
    });

    test('a customer who has not joined has no rank', () {
      final parsed = League.fromJson({
        'opted_in': false,
        'league': {'month': '2026-09', 'top': [], 'own': null, 'participants': 0},
      });

      expect(parsed.optedIn, isFalse);
      expect(parsed.own, isNull);
    });
  });
}
