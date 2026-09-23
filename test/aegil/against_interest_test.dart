import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/against_interest_models.dart';
import 'package:aerend_customer/screens/aegil/widgets/action_log_list.dart';
import 'package:aerend_customer/screens/aegil/widgets/against_interest_line.dart';

/// AGIL-2-PLAN Phase 8 — the against-interest line rendered first in the turn, the reminders
/// card, the action log and the trust-ledger card.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  const cheaper = AgainstInterestLine(
    check: 'cheaper_elsewhere',
    lineCode: 'cheaper_elsewhere_same_product',
    line: 'Den samme varen koster 20 kr mindre hos en butikk du bruker.',
    alternativeAction: 'switch_store',
    alternativeLabel: 'Bytt butikk',
    savingOre: 2000,
  );

  group('against-interest line', () {
    testWidgets('states the advice and what it is worth', (tester) async {
      await pump(tester, const AgainstInterestLineCard(line: cheaper));

      expect(find.byKey(const Key('against-interest-text-cheaper_elsewhere')), findsOneWidget);
      expect(find.text('Spar 20 kr'), findsOneWidget);
    });

    testWidgets('always offers the alternative', (tester) async {
      AgainstInterestLine? taken;

      await pump(
        tester,
        AgainstInterestLineCard(
          line: cheaper,
          onTakeAlternative: (l) => taken = l,
        ),
      );

      // Advice with no action is a scolding.
      expect(find.text('Bytt butikk'), findsOneWidget);
      await tester.tap(find.byKey(const Key('against-interest-alternative-cheaper_elsewhere')));
      expect(taken?.check, 'cheaper_elsewhere');
    });

    testWidgets('can be silenced from the line itself', (tester) async {
      AgainstInterestLine? silenced;

      await pump(
        tester,
        AgainstInterestLineCard(line: cheaper, onSilence: (l) => silenced = l),
      );

      await tester.tap(find.byKey(const Key('against-interest-silence-cheaper_elsewhere')));
      expect(silenced?.check, 'cheaper_elsewhere');
    });

    testWidgets('omits the saving chip when there is nothing to save', (tester) async {
      await pump(
        tester,
        const AgainstInterestLineCard(
          line: AgainstInterestLine(
            check: 'store_unreliable',
            lineCode: 'store_unreliable_recent_problems',
            line: 'Du har hatt 2 problemer med denne butikken i det siste.',
            alternativeAction: 'switch_store',
            alternativeLabel: 'Se andre butikker',
          ),
        ),
      );

      expect(find.byKey(const Key('against-interest-saving-store_unreliable')), findsNothing);
    });
  });

  group('turn ordering', () {
    testWidgets('the advice comes before what Ægil was going to say', (tester) async {
      await pump(
        tester,
        const AgainstInterestTurn(
          lines: [cheaper],
          body: Text('Her er forslaget', key: Key('turn-body')),
        ),
      );

      final adviceY = tester
          .getTopLeft(find.byKey(const Key('against-interest-cheaper_elsewhere')))
          .dy;
      final bodyY = tester.getTopLeft(find.byKey(const Key('turn-body'))).dy;

      // Burying it under the suggestion would be technically honest and practically useless.
      expect(adviceY, lessThan(bodyY));
    });

    testWidgets('a turn with no advice is just the body', (tester) async {
      await pump(
        tester,
        const AgainstInterestTurn(
          lines: [],
          body: Text('Her er forslaget', key: Key('turn-body')),
        ),
      );

      expect(find.byKey(const Key('turn-body')), findsOneWidget);
      expect(find.byKey(const Key('against-interest-cheaper_elsewhere')), findsNothing);
    });
  });

  group('trust ledger card', () {
    testWidgets('reports what the advice was worth', (tester) async {
      await pump(
        tester,
        const TrustLedgerCard(
          ledger: TrustLedgerMonth(
            month: '2026-09',
            savedKr: 84,
            findsApplied: 3,
            againstInterestShown: 7,
          ),
        ),
      );

      expect(find.text('Ægil sparte deg 84 kr'), findsOneWidget);
      // Counts what Ægil found, not only what it was allowed to say.
      expect(find.text('7 råd mot egen interesse · 3 tatt i bruk'), findsOneWidget);
    });

    testWidgets('says so plainly when there is nothing yet', (tester) async {
      await pump(
        tester,
        const TrustLedgerCard(ledger: TrustLedgerMonth(month: '2026-09')),
      );

      expect(find.byKey(const Key('trust-ledger-empty')), findsOneWidget);
    });
  });

  group('action log', () {
    const actions = [
      AgentActionItem(
        id: 1,
        action: 'suggestion_added',
        summary: 'La fersk skrei i skuffen',
        deepLink: 'aerend://suggestions/7',
      ),
      AgentActionItem(
        id: 2,
        action: 'reminder_fired',
        summary: 'Kaffen du ventet på er på tilbud',
        seen: true,
      ),
    ];

    testWidgets('lists what happened while they were away', (tester) async {
      await pump(tester, const ActionLogList(actions: actions));

      expect(find.byKey(const Key('action-log-item-1')), findsOneWidget);
      expect(find.text('La fersk skrei i skuffen'), findsOneWidget);
    });

    testWidgets('offers to mark everything read when something is unseen',
        (tester) async {
      var marked = false;

      await pump(
        tester,
        ActionLogList(actions: actions, onMarkAllSeen: () => marked = true),
      );

      await tester.tap(find.byKey(const Key('action-log-mark-seen')));
      expect(marked, isTrue);
    });

    testWidgets('an empty log says so', (tester) async {
      await pump(tester, const ActionLogList(actions: []));

      expect(find.byKey(const Key('action-log-empty')), findsOneWidget);
    });

    testWidgets('only rows with a destination are tappable', (tester) async {
      AgentActionItem? opened;

      await pump(tester, ActionLogList(actions: actions, onOpen: (a) => opened = a));

      await tester.tap(find.byKey(const Key('action-log-item-2')));
      expect(opened, isNull, reason: 'no deep link, nowhere to go');

      await tester.tap(find.byKey(const Key('action-log-item-1')));
      expect(opened?.id, 1);
    });
  });

  group('reminders card', () {
    testWidgets('lists what Ægil is waiting on', (tester) async {
      await pump(
        tester,
        const RemindersCard(
          reminders: [
            AgentReminderItem(
              id: 3,
              kind: 'wait_for_offer',
              productName: 'Kaffepose 500 g',
              targetPriceOre: 7900,
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('reminders-card')), findsOneWidget);
      expect(find.text('Kaffepose 500 g'), findsOneWidget);
      expect(find.text('under 79 kr'), findsOneWidget);
    });

    testWidgets('disappears when nothing is active', (tester) async {
      await pump(
        tester,
        const RemindersCard(
          reminders: [
            AgentReminderItem(id: 3, kind: 'wait_for_offer', state: 'fired'),
          ],
        ),
      );

      expect(find.byKey(const Key('reminders-card')), findsNothing);
    });

    testWidgets('a reminder can be cancelled', (tester) async {
      AgentReminderItem? cancelled;

      await pump(
        tester,
        RemindersCard(
          reminders: const [
            AgentReminderItem(id: 3, kind: 'wait_for_offer', productName: 'Kaffe'),
          ],
          onCancel: (r) => cancelled = r,
        ),
      );

      await tester.tap(find.byKey(const Key('reminder-cancel-3')));
      expect(cancelled?.id, 3);
    });
  });

  group('parsing', () {
    test('an against-interest line carries its alternative', () {
      final parsed = AgainstInterestLine.fromJson({
        'check': 'wait_for_offer',
        'line_code': 'wait_for_offer_seen_cheaper',
        'line': 'Denne har vært 30 kr billigere.',
        'alternative': {'action': 'remind_on_offer', 'label': 'Si fra'},
        'saving_ore': 3000,
      });

      expect(parsed.alternativeAction, 'remind_on_offer');
      expect(parsed.alternativeLabel, 'Si fra');
      expect(parsed.savingKr, 30);
    });
  });
}
