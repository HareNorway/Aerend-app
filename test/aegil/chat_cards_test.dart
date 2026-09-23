import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/chat_card_models.dart';
import 'package:aerend_customer/screens/aegil/widgets/chat_cards.dart';

/// AGIL-2-PLAN Phase 9 — the chat cards.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  group('shopping list card', () {
    const items = [
      ShoppingListItem(id: 1, text: 'melk', qty: 2),
      ShoppingListItem(id: 2, text: 'kaffe', done: true),
      ShoppingListItem(id: 3, text: 'skrei', addedByAgent: true, source: 'agent'),
    ];

    testWidgets('shows quantities and what is done', (tester) async {
      await pump(tester, const ShoppingListCard(items: items));

      expect(find.text('melk × 2'), findsOneWidget);
      expect(find.text('kaffe'), findsOneWidget);
    });

    testWidgets('marks what Ægil added', (tester) async {
      await pump(tester, const ShoppingListCard(items: items));

      // So the customer can tell what they typed from what Ægil put there.
      expect(find.text('Ægil'), findsOneWidget);
    });

    testWidgets('items can be ticked off', (tester) async {
      ShoppingListItem? toggled;

      await pump(
        tester,
        ShoppingListCard(items: items, onToggle: (i) => toggled = i),
      );

      await tester.tap(find.byKey(const Key('chat-shopping-toggle-1')));
      expect(toggled?.id, 1);
    });

    testWidgets('an empty list says so', (tester) async {
      await pump(tester, const ShoppingListCard(items: []));

      expect(find.byKey(const Key('chat-shopping-list-empty')), findsOneWidget);
    });
  });

  group('comparison card', () {
    testWidgets('always shows the size', (tester) async {
      await pump(
        tester,
        const ComparisonCard(
          comparison: Comparison(
            products: [
              ComparisonProduct(
                productIdentityId: 1,
                name: 'Kaffe 500 g',
                unitAmount: 500,
                unit: 'g',
                priceOre: 9900,
                pricePerUnitOre: 1980,
              ),
            ],
          ),
        ),
      );

      // "Cheaper" without "per what?" is how you mislead someone.
      expect(find.text('500 g'), findsOneWidget);
      expect(find.text('99 kr'), findsOneWidget);
    });

    testWidgets('repeats the size warning when packs differ', (tester) async {
      await pump(
        tester,
        const ComparisonCard(
          comparison: Comparison(
            products: [
              ComparisonProduct(productIdentityId: 1, name: 'A', unitAmount: 500, unit: 'g'),
              ComparisonProduct(productIdentityId: 2, name: 'B', unitAmount: 300, unit: 'g'),
            ],
            cheapestId: 1,
            note: 'Varene har ulik størrelse — prisen er regnet om per enhet.',
          ),
        ),
      );

      expect(find.byKey(const Key('chat-comparison-note')), findsOneWidget);
    });

    testWidgets('marks the best value', (tester) async {
      await pump(
        tester,
        const ComparisonCard(
          comparison: Comparison(
            products: [
              ComparisonProduct(productIdentityId: 1, name: 'A'),
              ComparisonProduct(productIdentityId: 2, name: 'B'),
            ],
            cheapestId: 2,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('news card', () {
    testWidgets('shows the headline and who posted it', (tester) async {
      await pump(
        tester,
        const NewsCard(
          headline: 'Fersk skrei fra Torget',
          storeName: 'Nordnes Fisk',
          body: 'Dagens fangst.',
        ),
      );

      expect(find.text('Fersk skrei fra Torget'), findsOneWidget);
      expect(find.text('NORDNES FISK'), findsOneWidget);
    });

    testWidgets('opens the post when tapped', (tester) async {
      var opened = false;

      await pump(
        tester,
        NewsCard(headline: 'Fersk skrei', onOpen: () => opened = true),
      );

      await tester.tap(find.byKey(const Key('chat-news-card')));
      expect(opened, isTrue);
    });
  });

  group('points explainer', () {
    testWidgets('lists the rules and the level promise', (tester) async {
      await pump(
        tester,
        const PointsExplainerCard(
          explainer: PointsExplainer(
            rules: [
              PointsExplainerRule(key: 'kjop', title: 'Handle', body: '1 poeng per 10 kr.'),
              PointsExplainerRule(key: 'verving', title: 'Verving', body: '200 poeng.'),
            ],
            expiry: 'Poeng varer i 12 måneder.',
            tierNote: 'Å bruke poeng senker aldri nivået.',
          ),
        ),
      );

      expect(find.byKey(const Key('chat-explainer-kjop')), findsOneWidget);
      expect(find.text('Poeng varer i 12 måneder.'), findsOneWidget);
      expect(find.byKey(const Key('chat-explainer-tier-note')), findsOneWidget);
    });
  });

  group('level refusal', () {
    testWidgets('names the level and offers to change it', (tester) async {
      var opened = false;

      await pump(
        tester,
        LevelRefusalCard(
          refusal: const ToolRefusal(
            reason: 'LEVEL_TOO_LOW',
            copy: 'Å legge ting i kurven krever nivå 3 — «Fyll kurven min».',
            requiredLevel: 3,
          ),
          onOpenSettings: () => opened = true,
        ),
      );

      // "I can't do that" teaches nothing; this says what to change.
      expect(find.textContaining('nivå 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-level-refusal-settings')));
      expect(opened, isTrue);
    });

    testWidgets('a refusal that no level fixes offers no settings link',
        (tester) async {
      await pump(
        tester,
        LevelRefusalCard(
          refusal: const ToolRefusal(
            reason: 'TOOL_NOT_EXPOSED',
            copy: 'Det kan ikke Ægil gjøre.',
          ),
          onOpenSettings: () {},
        ),
      );

      expect(find.byKey(const Key('chat-level-refusal-settings')), findsNothing);
    });
  });

  group('parsing', () {
    test('a comparison keeps only the allowlisted fields it was given', () {
      final parsed = Comparison.fromJson({
        'products': [
          {
            'product_identity_id': 1,
            'name': 'Kaffe',
            'unit_amount': 500,
            'unit': 'g',
            'price_ore': 9900,
            'price_per_unit_ore': 1980,
          },
        ],
        'cheapest_id': 1,
        'note': null,
      });

      expect(parsed.products.single.sizeLabel, '500 g');
      expect(parsed.cheapestId, 1);
      expect(parsed.note, isNull);
    });

    test('a refusal knows whether a level would fix it', () {
      expect(
        ToolRefusal.fromJson({'reason': 'LEVEL_TOO_LOW', 'copy': 'x', 'required_level': 3})
            .isLevelIssue,
        isTrue,
      );
      expect(
        ToolRefusal.fromJson({'reason': 'TOOL_NOT_EXPOSED', 'copy': 'x'}).isLevelIssue,
        isFalse,
      );
    });
  });
}
