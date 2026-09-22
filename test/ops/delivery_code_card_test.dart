import 'package:aerend_customer/screens/tracking/delivery_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 5 acceptance (Aerend-app): the code card renders for code orders with
/// its reason, and the courier ID card shows who is coming.
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DeliveryCodeCard', () {
    testWidgets('shows the PIN spaced for reading aloud', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DeliveryCodeCard(
        pin: '4821',
        reasonCopy: 'Varene har aldersgrense, så budet må sjekke kode ved levering.',
      )));

      expect(find.byKey(const Key('ops-delivery-code-card')), findsOneWidget);
      // Spaced so it can be read at a door without stumbling.
      expect(find.text('4 8 2 1'), findsOneWidget);
    });

    testWidgets('says why the code is there', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DeliveryCodeCard(
        pin: '1234',
        reasonCopy: 'Denne leveringen har høy verdi, så vi ber om kode ved døren.',
      )));

      // An unexplained extra step reads as friction; an explained one as care.
      expect(find.byKey(const Key('ops-delivery-code-reason')), findsOneWidget);
      expect(find.textContaining('høy verdi'), findsOneWidget);
    });

    testWidgets('states that leave-at-door is not possible', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DeliveryCodeCard(
        pin: '1234',
        reasonCopy: 'Du har valgt kode ved levering.',
      )));

      expect(find.byKey(const Key('ops-delivery-code-no-leave-at-door')), findsOneWidget);
      expect(find.textContaining('kan ikke settes igjen'), findsOneWidget);
    });

    testWidgets('shows a QR only when one was issued', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const DeliveryCodeCard(
        pin: '1234',
        reasonCopy: 'Du har valgt kode ved levering.',
      )));
      expect(find.byKey(const Key('ops-delivery-code-qr')), findsNothing);

      await tester.pumpWidget(wrap(const DeliveryCodeCard(
        pin: '1234',
        reasonCopy: 'Du har valgt kode ved levering.',
        qrPayload: 'eyJhbGciOiJFUzI1NiJ9.payload.sig',
      )));
      expect(find.byKey(const Key('ops-delivery-code-qr')), findsOneWidget);
    });
  });

  group('CourierIdCard', () {
    testWidgets('shows who is coming, with verification', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(CourierIdCard(
        courierName: 'Ola Nordmann',
        vehicle: 'Sykkel',
        verifiedOn: DateTime.parse('2026-03-01T00:00:00Z'),
      )));

      expect(find.byKey(const Key('ops-courier-name')), findsOneWidget);
      expect(find.text('Ola Nordmann'), findsOneWidget);
      expect(find.byKey(const Key('ops-courier-vehicle')), findsOneWidget);
      expect(find.text('Identitet bekreftet 2026'), findsOneWidget);
    });

    testWidgets('falls back to an icon when there is no photo',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CourierIdCard(courierName: 'Kari')));

      expect(find.byKey(const Key('ops-courier-avatar')), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('omits verification text when the courier is unverified',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CourierIdCard(courierName: 'Kari')));

      // Better to say nothing than to imply a check that did not happen.
      expect(find.byKey(const Key('ops-courier-verified')), findsNothing);
    });
  });
}
