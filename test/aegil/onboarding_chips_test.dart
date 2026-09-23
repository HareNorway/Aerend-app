import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/screens/aegil/widgets/onboarding_chip_batch.dart';

/// AGIL-2-PLAN Phase 6 acceptance — Aerend-app widget tests:
///   the chip batch posts the expected payload; the re-invite is hidden inside 7 days.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  const chips = [
    OnboardingChip(kind: 'allergen', value: 'nøtter', label: 'Nøtter'),
    OnboardingChip(kind: 'diet', value: 'vegetar', label: 'Vegetar'),
    OnboardingChip(kind: 'like', value: 'fisk', label: 'Fisk'),
  ];

  group('chip batch', () {
    testWidgets('posts only the chips that were chosen', (tester) async {
      List<OnboardingChip>? submitted;

      await pump(
        tester,
        OnboardingChipBatch(
          title: 'Hva bør Ægil vite?',
          chips: chips,
          onSubmit: (selected) => submitted = selected,
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding-chip-allergen-nøtter')));
      await tester.tap(find.byKey(const Key('onboarding-chip-like-fisk')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('onboarding-submit')));

      expect(submitted, isNotNull);
      expect(submitted!.map((c) => c.value), ['nøtter', 'fisk']);
    });

    testWidgets('the payload matches what the batch endpoint expects', (tester) async {
      List<OnboardingChip>? submitted;

      await pump(
        tester,
        OnboardingChipBatch(
          title: 'Hva bør Ægil vite?',
          chips: chips,
          onSubmit: (selected) => submitted = selected,
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding-chip-allergen-nøtter')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('onboarding-submit')));

      expect(submitted!.first.toJson(), {
        'kind': 'allergen',
        'value': 'nøtter',
        'label': 'Nøtter',
      });
    });

    testWidgets('a chip can be unchosen', (tester) async {
      List<OnboardingChip>? submitted;

      await pump(
        tester,
        OnboardingChipBatch(
          title: 'Hva bør Ægil vite?',
          chips: chips,
          onSubmit: (selected) => submitted = selected,
        ),
      );

      final chip = find.byKey(const Key('onboarding-chip-like-fisk'));
      await tester.tap(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();

      await tester.tap(find.byKey(const Key('onboarding-submit')));
      expect(submitted, isEmpty);
    });

    testWidgets('says that allergies and diets are never guessed', (tester) async {
      await pump(
        tester,
        const OnboardingChipBatch(title: 'Hva bør Ægil vite?', chips: chips),
      );

      // The customer should understand that tapping is the only thing that counts.
      expect(
        find.byKey(const Key('onboarding-hard-constraint-note')),
        findsOneWidget,
      );
    });

    testWidgets('omits that note when no chip is a hard constraint', (tester) async {
      await pump(
        tester,
        const OnboardingChipBatch(
          title: 'Hva liker du?',
          chips: [OnboardingChip(kind: 'like', value: 'fisk', label: 'Fisk')],
        ),
      );

      expect(find.byKey(const Key('onboarding-hard-constraint-note')), findsNothing);
    });

    testWidgets('skipping is a first-class option', (tester) async {
      var skipped = false;

      await pump(
        tester,
        OnboardingChipBatch(
          title: 'Hva bør Ægil vite?',
          chips: chips,
          onSkip: () => skipped = true,
        ),
      );

      await tester.tap(find.byKey(const Key('onboarding-skip')));
      expect(skipped, isTrue);
    });

    testWidgets('discloses that Ægil is AI', (tester) async {
      await pump(
        tester,
        const OnboardingChipBatch(title: 'Hva bør Ægil vite?', chips: chips),
      );

      expect(find.textContaining('Laget med AI-hjelp'), findsOneWidget);
    });

    testWidgets('the submit button is disabled while saving', (tester) async {
      await pump(
        tester,
        OnboardingChipBatch(
          title: 'Hva bør Ægil vite?',
          chips: chips,
          submitting: true,
          onSubmit: (_) {},
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('onboarding-submit')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Lagrer…'), findsOneWidget);
    });
  });

  group('re-invite policy', () {
    const policy = OnboardingReinvitePolicy();
    final now = DateTime(2026, 9, 22);

    test('someone who has never skipped is invited', () {
      expect(policy.shouldInvite(now: now), isTrue);
    });

    test('the re-invite is hidden inside 7 days', () {
      expect(
        policy.shouldInvite(skippedAt: now.subtract(const Duration(days: 6)), now: now),
        isFalse,
        reason: 'skipping should mean skipped, not "ask again in a minute"',
      );
    });

    test('and returns after 7 days', () {
      expect(
        policy.shouldInvite(skippedAt: now.subtract(const Duration(days: 7)), now: now),
        isTrue,
      );
    });

    test('someone who completed onboarding is never re-invited', () {
      expect(
        policy.shouldInvite(
          skippedAt: now.subtract(const Duration(days: 30)),
          completed: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('a guest is not asked before their first delivery', () {
      expect(policy.shouldInviteGuest(deliveredOrders: 0, now: now), isFalse);
      expect(policy.shouldInviteGuest(deliveredOrders: 1, now: now), isTrue);
    });

    test('a guest who skipped also waits 7 days', () {
      expect(
        policy.shouldInviteGuest(
          deliveredOrders: 3,
          skippedAt: now.subtract(const Duration(days: 2)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
