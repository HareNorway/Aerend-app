import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/points/widgets/meg_points_card.dart';
import 'package:aerend_customer/screens/points/widgets/mission_card.dart';
import 'package:aerend_customer/screens/points/widgets/monthly_summary_card.dart';
import 'package:aerend_customer/screens/points/widgets/welcome_moment.dart';

/// AGIL-2-PLAN Phase 4 — the "Meg" surfaces: balance strip, Nivå with progress, expiry
/// notice, mission card, welcome moment and the monthly summary.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  group('Meg points card', () {
    testWidgets('shows the spendable balance and the level', (tester) async {
      await pump(
        tester,
        const MegPointsCard(
          balance: PointsBalance(
            available: 640,
            earned12m: 1200,
            tier: 1,
            tierName: 'Løvstakken',
            nextTierName: 'Rundemanen',
            pointsToNextTier: 1800,
          ),
        ),
      );

      expect(find.byKey(const Key('meg-available-points')), findsOneWidget);
      expect(find.text('640'), findsOneWidget);
      expect(find.text('Løvstakken'), findsOneWidget);
      expect(find.text('1800 poeng til Rundemanen'), findsOneWidget);
    });

    testWidgets('states that spending never lowers the level', (tester) async {
      await pump(
        tester,
        const MegPointsCard(balance: PointsBalance(available: 100)),
      );

      // The promise the design makes in words and the engine keeps in code.
      expect(
        find.text('Nivået påvirkes aldri av at du bruker poeng'),
        findsOneWidget,
      );
    });

    testWidgets('explains pending points rather than hiding them',
        (tester) async {
      await pump(
        tester,
        const MegPointsCard(
          balance: PointsBalance(available: 50, pending: 14),
        ),
      );

      expect(find.byKey(const Key('meg-pending-line')), findsOneWidget);
      expect(find.textContaining('14 poeng er på vei'), findsOneWidget);
    });

    testWidgets('shows no pending line when nothing is pending',
        (tester) async {
      await pump(
        tester,
        const MegPointsCard(balance: PointsBalance(available: 50)),
      );

      expect(find.byKey(const Key('meg-pending-line')), findsNothing);
    });

    testWidgets('warns about points about to expire', (tester) async {
      await pump(
        tester,
        const MegPointsCard(
          balance: PointsBalance(available: 500, expiringAmount: 120),
        ),
      );

      expect(find.byKey(const Key('meg-expiry-notice')), findsOneWidget);
      expect(find.text('120 poeng utløper snart'), findsOneWidget);
    });

    testWidgets('the top level has no "poeng til" line', (tester) async {
      await pump(
        tester,
        const MegPointsCard(
          balance: PointsBalance(
            available: 900,
            earned12m: 9000,
            tier: 3,
            tierName: 'Ulriken',
          ),
        ),
      );

      expect(find.byKey(const Key('meg-tier-progress-line')), findsNothing);
      expect(find.text('Ulriken'), findsOneWidget);
    });

    testWidgets('shows the active goal with its progress', (tester) async {
      await pump(
        tester,
        const MegPointsCard(
          balance: PointsBalance(available: 200),
          goal: PointGoal(
            kind: 'prize',
            label: 'Kaffepose 250 g',
            current: 200,
            target: 700,
            remaining: 500,
            percent: 28,
          ),
        ),
      );

      expect(find.text('Sparer til Kaffepose 250 g'), findsOneWidget);
      expect(find.text('28 %'), findsOneWidget);
    });
  });

  group('progress maths', () {
    test('progress through the band, not through all of history', () {
      const balance = PointsBalance(
        earned12m: 1200,
        tier: 1,
        tierName: 'Løvstakken',
        nextTierName: 'Rundemanen',
        pointsToNextTier: 1800,
      );

      // 1200 earned, 1800 to go → 40% of the way to the next mountain.
      expect(balance.progressToNextTier(), closeTo(0.4, 0.001));
    });

    test('the top tier is full', () {
      const balance = PointsBalance(earned12m: 9000, tier: 3, tierName: 'Ulriken');

      expect(balance.progressToNextTier(), 1.0);
    });
  });

  group('mission card', () {
    const mission = Mission(
      id: 1,
      title: 'Prøv en ny butikk',
      body: 'Bestill fra en butikk du ikke har handlet hos før denne uken.',
      points: 40,
    );

    testWidgets('shows the mission and what it is worth', (tester) async {
      await pump(tester, const MissionCard(mission: mission));

      expect(find.text('Prøv en ny butikk'), findsOneWidget);
      expect(find.text('40 poeng'), findsOneWidget);
    });

    testWidgets('offers a decline while one is still available',
        (tester) async {
      var declined = false;
      await pump(
        tester,
        MissionCard(mission: mission, onDecline: () => declined = true),
      );

      await tester.tap(find.byKey(const Key('mission-decline')));
      expect(declined, isTrue);
    });

    testWidgets('hides the decline once it has been used this week',
        (tester) async {
      await pump(
        tester,
        MissionCard(mission: mission, canDecline: false, onDecline: () {}),
      );

      // Gone rather than present-but-failing: an unlimited reroll would be a slot machine.
      expect(find.byKey(const Key('mission-decline')), findsNothing);
    });

    testWidgets('discloses AI when Ægil reworded the mission', (tester) async {
      await pump(
        tester,
        const MissionCard(
          mission: Mission(
            id: 2,
            title: 'Handle utenom rushet',
            body: 'Ægils formulering',
            points: 30,
            wordingSource: 'agent',
          ),
        ),
      );

      expect(find.textContaining('Laget med AI-hjelp'), findsOneWidget);
    });

    testWidgets('does not disclose AI for template wording', (tester) async {
      await pump(tester, const MissionCard(mission: mission));

      expect(find.textContaining('Laget med AI-hjelp'), findsNothing);
    });
  });

  group('welcome moment', () {
    testWidgets('says the gift cost nothing', (tester) async {
      await pump(
        tester,
        const WelcomeMoment(
          tierName: 'Løvstakken',
          gift: PrizeClaim(
            id: 1,
            prizeId: 2,
            state: 'claimed',
            prizeName: 'Forundringspose',
            pointsSpent: 0,
          ),
        ),
      );

      expect(find.text('Velkommen til Løvstakken'), findsOneWidget);
      expect(find.textContaining('uten å bruke poeng'), findsOneWidget);
    });
  });

  group('monthly summary', () {
    testWidgets('carries the savings line, not a separate trust card',
        (tester) async {
      await pump(
        tester,
        const MonthlySummaryCard(
          month: 'September',
          earned: 340,
          spent: 100,
          savedKr: 84,
        ),
      );

      expect(find.text('Ægil sparte deg'), findsOneWidget);
      expect(find.text('84 kr'), findsOneWidget);
    });

    testWidgets('shows the migrated balance so the conversion is visible',
        (tester) async {
      await pump(
        tester,
        const MonthlySummaryCard(
          month: 'September',
          earned: 100,
          migratedSavingsKr: 300,
        ),
      );

      expect(
        find.byKey(const Key('monthly-summary-migrated-line')),
        findsOneWidget,
      );
      expect(find.text('300 kr'), findsOneWidget);
    });

    testWidgets('omits the migration line for customers who had no balance',
        (tester) async {
      await pump(
        tester,
        const MonthlySummaryCard(month: 'September', earned: 100),
      );

      expect(
        find.byKey(const Key('monthly-summary-migrated-line')),
        findsNothing,
      );
    });
  });
}
