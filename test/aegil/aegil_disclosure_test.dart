import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/aegil/widgets/aegil_disclosure.dart';

/// AGIL-2-PLAN Phase 2 — "disclosure copy component (Flutter + Blade)" and
/// "AI disclosure on first use in every surface".
void main() {
  setUp(AegilDisclosureTracker.reset);

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('the full variant states that Ægil is not a person', (tester) async {
    await pump(tester, const AegilDisclosure());

    expect(find.textContaining('ikke et menneske'), findsOneWidget);
    expect(find.textContaining('angres i 7 dager'), findsOneWidget);
  });

  testWidgets('the short variant fits one line and still discloses AI', (tester) async {
    await pump(
      tester,
      const AegilDisclosure(variant: AegilDisclosureVariant.short),
    );

    expect(find.textContaining('Laget med AI-hjelp'), findsOneWidget);
    expect(find.textContaining('angres i 7 dager'), findsNothing);
  });

  testWidgets('the agent that produced the output can be named', (tester) async {
    await pump(
      tester,
      const AegilDisclosure(
        variant: AegilDisclosureVariant.short,
        agentName: 'aegil_customer',
      ),
    );

    expect(find.textContaining('aegil_customer'), findsOneWidget);
  });

  testWidgets('the terms link only appears on the full variant', (tester) async {
    await pump(tester, AegilDisclosure(onTerms: () {}));
    expect(find.text('Vilkår'), findsOneWidget);

    await pump(
      tester,
      AegilDisclosure(
        variant: AegilDisclosureVariant.short,
        onTerms: () {},
      ),
    );
    expect(find.text('Vilkår'), findsNothing);
  });

  testWidgets('dismissing is only offered when a handler is given', (tester) async {
    await pump(tester, const AegilDisclosure());
    expect(find.byIcon(Icons.close), findsNothing);

    var dismissed = false;
    await pump(tester, AegilDisclosure(onDismiss: () => dismissed = true));

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  test('each surface is told to disclose exactly once', () {
    expect(AegilDisclosureTracker.shouldShow('chat'), isTrue);
    expect(AegilDisclosureTracker.shouldShow('chat'), isFalse);

    // A different surface discloses on its own first use, not on the chat's.
    expect(AegilDisclosureTracker.shouldShow('suggestion_tray'), isTrue);
    expect(AegilDisclosureTracker.hasShown('chat'), isTrue);
  });
}
