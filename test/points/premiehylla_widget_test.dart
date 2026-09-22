import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/points/points_models.dart';
import 'package:aerend_customer/screens/points/widgets/premiehylla_shelf.dart';
import 'package:aerend_customer/screens/points/widgets/prize_card.dart';
import 'package:aerend_customer/screens/points/widgets/prize_preview_card.dart';
import 'package:aerend_customer/screens/points/widgets/voucher_chip.dart';

/// AGIL-2-PLAN Phase 4 acceptance — Aerend-app widget tests:
///   a Fløyen user sees exactly 3 blurred previews with correct "poeng til" gaps;
///   the claim button is disabled when balance < price;
///   a voucher chip appears in checkout after a claim.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  Prize prize({
    int id = 1,
    String name = 'Gratis levering',
    int price = 100,
    bool claimable = true,
    String? blockedReason,
  }) =>
      Prize(
        id: id,
        name: name,
        pointPrice: price,
        tierBand: 0,
        tierName: 'Fløyen',
        affordable: claimable,
        claimable: claimable,
        blockedReason: blockedReason,
      );

  /// A Fløyen customer on 600 earned points: Løvstakken starts at 1000, so every
  /// preview is 400 points of earning away.
  Premiehylla floyenShelf() => Premiehylla(
        prizes: [prize()],
        previews: const [
          PrizePreview(
            id: 11,
            name: 'Kaffepose 250 g',
            pointPrice: 700,
            tierName: 'Løvstakken',
            pointsToUnlock: 400,
          ),
          PrizePreview(
            id: 12,
            name: 'Sjokolade fra Bryggen',
            pointPrice: 450,
            tierName: 'Løvstakken',
            pointsToUnlock: 400,
          ),
          PrizePreview(
            id: 13,
            name: '200 poeng til en klubb',
            pointPrice: 600,
            tierName: 'Løvstakken',
            pointsToUnlock: 400,
          ),
        ],
      );

  group('locked previews', () {
    testWidgets('a Fløyen user sees exactly three blurred previews',
        (tester) async {
      await pump(tester, PremiehyllaShelf(shelf: floyenShelf()));

      expect(find.byType(PrizePreviewCard), findsNWidgets(3));
    });

    testWidgets('each preview shows the right "poeng til" gap', (tester) async {
      await pump(tester, PremiehyllaShelf(shelf: floyenShelf()));

      // "Fra Løvstakken · 400 poeng til"
      expect(find.text('Fra Løvstakken · 400 poeng til'), findsNWidgets(3));
    });

    testWidgets('never more than three, even if the backend sends more',
        (tester) async {
      final shelf = Premiehylla(
        prizes: const [],
        previews: List.generate(
          6,
          (i) => PrizePreview(
            id: i,
            name: 'Premie $i',
            pointPrice: 500 + i,
            tierName: 'Løvstakken',
            pointsToUnlock: 400,
          ),
        ),
      );

      await pump(tester, PremiehyllaShelf(shelf: shelf));

      expect(find.byType(PrizePreviewCard), findsNWidgets(3));
    });

    testWidgets('there is no padlock — "not yet", not "forbidden"',
        (tester) async {
      await pump(tester, PremiehyllaShelf(shelf: floyenShelf()));

      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('a user with nothing above them sees no preview section',
        (tester) async {
      await pump(
        tester,
        PremiehyllaShelf(shelf: Premiehylla(prizes: [prize()])),
      );

      expect(find.byType(PrizePreviewCard), findsNothing);
      expect(find.byKey(const Key('premiehylla-previews-heading')), findsNothing);
    });
  });

  group('claim button', () {
    testWidgets('is disabled when the balance is below the price',
        (tester) async {
      await pump(
        tester,
        PrizeCard(
          prize: prize(
            price: 150,
            claimable: false,
            blockedReason: 'PRIZE_INSUFFICIENT_POINTS',
          ),
          onClaim: () {},
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('prize-claim-button')),
      );
      expect(button.onPressed, isNull, reason: 'disabled, not hidden');

      // And it says why, rather than leaving the customer guessing.
      expect(find.text('Mangler 150 poeng'), findsOneWidget);
    });

    testWidgets('is enabled when the prize is claimable', (tester) async {
      var claimed = false;

      await pump(
        tester,
        PrizeCard(prize: prize(), onClaim: () => claimed = true),
      );

      await tester.tap(find.byKey(const Key('prize-claim-button')));
      expect(claimed, isTrue);
    });

    testWidgets('a sold-out prize says so', (tester) async {
      await pump(
        tester,
        PrizeCard(
          prize: prize(claimable: false, blockedReason: 'PRIZE_SOLD_OUT'),
          onClaim: () {},
        ),
      );

      expect(find.text('Utsolgt'), findsOneWidget);
    });

    testWidgets('an already-claimed prize says so', (tester) async {
      await pump(
        tester,
        PrizeCard(
          prize: prize(claimable: false, blockedReason: 'PRIZE_USER_CAP'),
          onClaim: () {},
        ),
      );

      expect(find.text('Allerede hentet'), findsOneWidget);
    });
  });

  group('voucher at checkout', () {
    testWidgets('the chip appears after a claim', (tester) async {
      const claim = PrizeClaim(
        id: 9,
        prizeId: 1,
        state: 'claimed',
        prizeName: 'Gratis levering',
        pointsSpent: 100,
        voucherCode: 'ÆABC1234',
      );

      await pump(tester, const VoucherChip(claim: claim));

      expect(find.byKey(const Key('checkout-voucher-chip')), findsOneWidget);
      expect(find.text('Gratis levering'), findsOneWidget);
    });

    testWidgets('a welcome gift is marked as a gift', (tester) async {
      const gift = PrizeClaim(
        id: 10,
        prizeId: 2,
        state: 'claimed',
        prizeName: 'Forundringspose',
        pointsSpent: 0,
      );

      await pump(tester, const VoucherChip(claim: gift));

      expect(find.text('· gave'), findsOneWidget);
    });

    testWidgets('it can be removed when a handler is given', (tester) async {
      var removed = false;
      const claim = PrizeClaim(
        id: 9,
        prizeId: 1,
        state: 'claimed',
        prizeName: 'Gratis levering',
        pointsSpent: 100,
      );

      await pump(tester, VoucherChip(claim: claim, onRemove: () => removed = true));

      await tester.tap(find.byKey(const Key('checkout-voucher-remove')));
      expect(removed, isTrue);
    });
  });
}
