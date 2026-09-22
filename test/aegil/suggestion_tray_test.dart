import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/suggestion_models.dart';
import 'package:aerend_customer/screens/aegil/widgets/suggestion_tray.dart';
import 'package:aerend_customer/screens/aegil/widgets/vaagen_moment.dart';

/// AGIL-2-PLAN Phase 7 — the tray, the "Ikke for meg" sheet and the "Vågen" moment.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  const suggestion = Suggestion(
    id: 7,
    reasonCode: 'offer_liked_product',
    reason: 'Tilbud på noe du liker',
    headline: 'Fersk skrei fra Torget',
    productIdentityId: 88,
    storeId: 77,
    storeProductId: 3,
  );

  group('tray', () {
    testWidgets('every card leads with why it is there', (tester) async {
      await pump(tester, const SuggestionTray(suggestions: [suggestion]));

      expect(find.byKey(const Key('suggestion-reason-7')), findsOneWidget);
      expect(find.text('Tilbud på noe du liker'), findsOneWidget);
      expect(find.text('Fersk skrei fra Torget'), findsOneWidget);
    });

    testWidgets('an empty tray says so plainly', (tester) async {
      await pump(tester, const SuggestionTray(suggestions: []));

      expect(find.byKey(const Key('suggestion-tray-empty')), findsOneWidget);
      expect(find.byKey(const Key('suggestion-tray')), findsNothing);
    });

    testWidgets('offers add, not now, and not for me', (tester) async {
      Suggestion? added;
      Suggestion? dismissed;
      Suggestion? refused;

      await pump(
        tester,
        SuggestionTray(
          suggestions: const [suggestion],
          onAdd: (s) => added = s,
          onDismiss: (s) => dismissed = s,
          onNotForMe: (s) => refused = s,
        ),
      );

      await tester.tap(find.byKey(const Key('suggestion-add-7')));
      await tester.tap(find.byKey(const Key('suggestion-dismiss-7')));
      await tester.tap(find.byKey(const Key('suggestion-never-7')));

      expect(added?.id, 7);
      expect(dismissed?.id, 7);
      expect(refused?.id, 7);
    });

    testWidgets('discloses that the suggestions are AI-assisted', (tester) async {
      await pump(tester, const SuggestionTray(suggestions: [suggestion]));

      expect(find.textContaining('Laget med AI-hjelp'), findsOneWidget);
    });
  });

  group('"Ikke for meg" sheet', () {
    testWidgets('asks why, and offers distinct reasons', (tester) async {
      await pump(tester, const NotForMeSheet(suggestion: suggestion));

      expect(find.text('Hvorfor ikke?'), findsOneWidget);

      // The reasons mean different things, which is why they are asked for.
      for (final reason in NotForMeReason.values) {
        expect(find.byKey(Key('not-for-me-${reason.code}')), findsOneWidget);
      }
    });

    testWidgets('reports the chosen reason', (tester) async {
      NotForMeReason? chosen;

      await pump(
        tester,
        NotForMeSheet(suggestion: suggestion, onChosen: (r) => chosen = r),
      );

      await tester.tap(find.byKey(const Key('not-for-me-already_have')));
      expect(chosen, NotForMeReason.alreadyHave);
    });

    test('"already have" is not the same answer as "not for me"', () {
      expect(NotForMeReason.alreadyHave.code, 'already_have');
      expect(NotForMeReason.notForMe.code, 'not_for_me');
      expect(NotForMeReason.values.map((r) => r.code).toSet().length,
          NotForMeReason.values.length);
    });
  });

  group('Vågen', () {
    testWidgets('invites a reel when today\'s catch is still out there',
        (tester) async {
      var reeled = false;

      await pump(
        tester,
        VaagenMoment(
          catchOfTheDay: const DailyCatch(day: '2026-09-22'),
          onReel: () => reeled = true,
        ),
      );

      expect(find.byKey(const Key('vaagen-ready')), findsOneWidget);
      await tester.tap(find.byKey(const Key('vaagen-reel')));
      expect(reeled, isTrue);
    });

    testWidgets('once reeled, it says so warmly rather than greying out',
        (tester) async {
      await pump(
        tester,
        const VaagenMoment(
          catchOfTheDay: DailyCatch(
            day: '2026-09-22',
            points: 5,
            alreadyReeled: true,
          ),
        ),
      );

      expect(find.byKey(const Key('vaagen-done')), findsOneWidget);
      expect(find.text('Dagens napp er i boks — 5 poeng.'), findsOneWidget);
      expect(find.text('Kom tilbake i morgen.'), findsOneWidget);
      // No disabled button sitting there looking broken.
      expect(find.byKey(const Key('vaagen-reel')), findsNothing);
    });

    testWidgets('shows what was caught, reason first', (tester) async {
      await pump(
        tester,
        const VaagenMoment(
          catchOfTheDay: DailyCatch(
            day: '2026-09-22',
            points: 5,
            alreadyReeled: true,
            suggestion: suggestion,
          ),
        ),
      );

      expect(find.byKey(const Key('vaagen-catch')), findsOneWidget);
      expect(find.text('Tilbud på noe du liker'), findsOneWidget);
    });

    testWidgets('the button is disabled while reeling', (tester) async {
      await pump(
        tester,
        VaagenMoment(
          catchOfTheDay: const DailyCatch(day: '2026-09-22'),
          reeling: true,
          onReel: () {},
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byKey(const Key('vaagen-reel')));
      expect(button.onPressed, isNull);
      expect(find.text('Drar inn…'), findsOneWidget);
    });
  });

  group('parsing', () {
    test('a suggestion carries its reason code and its copy', () {
      final parsed = Suggestion.fromJson({
        'id': 7,
        'reason_code': 'price_drop_watched',
        'reason': 'Prisen har gått ned',
        'state': 'open',
        'headline': 'Fersk skrei',
        'product_identity_id': 88,
      });

      expect(parsed.reasonCode, 'price_drop_watched');
      expect(parsed.reason, 'Prisen har gått ned');
      expect(parsed.productIdentityId, 88);
    });

    test('a daily catch knows whether today is done', () {
      final parsed = DailyCatch.fromJson({
        'day': '2026-09-22',
        'points': 5,
        'already_reeled': true,
      });

      expect(parsed.alreadyReeled, isTrue);
      expect(parsed.points, 5);
    });
  });
}
