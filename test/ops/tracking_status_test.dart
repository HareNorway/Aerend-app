import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/tracking/ops_tracking_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 acceptance (Aerend-app): tracking renders window text for every
/// status enum value, with no unmapped state.
Widget wrap(Widget child, {Locale locale = const Locale('no')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

final DateTime kStart = DateTime.parse('2026-09-22T18:40:00');
final DateTime kEnd = DateTime.parse('2026-09-22T18:55:00');

void main() {
  const List<String> allStates = <String>[
    OpsTrackingStatus.placed,
    OpsTrackingStatus.accepted,
    OpsTrackingStatus.seen,
    OpsTrackingStatus.ready,
    OpsTrackingStatus.pickedUp,
    OpsTrackingStatus.arrivedCustomer,
    OpsTrackingStatus.delivered,
    OpsTrackingStatus.cancelled,
  ];

  testWidgets('every state renders a real label — none fall through to unknown',
      (WidgetTester tester) async {
    for (final String state in allStates) {
      await tester.pumpWidget(wrap(OpsTrackingCard(
        status: OpsTrackingStatus(
          state: state,
          promisedStart: kStart,
          promisedEnd: kEnd,
        ),
      )));
      await tester.pumpAndSettle();

      final Text label = tester.widget<Text>(find.byKey(const Key('ops-tracking-status')));

      expect(label.data, isNotNull, reason: 'state $state produced no label');
      expect(label.data, isNotEmpty);
      expect(
        label.data,
        isNot('Ukjent'),
        reason: 'state $state fell through to the unknown label',
      );
    }
  });

  testWidgets('an unrecognised state falls back to the unknown label rather than crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const OpsTrackingCard(
      status: OpsTrackingStatus(state: 'teleported'),
    )));
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(find.byKey(const Key('ops-tracking-status')));
    expect(label.data, 'Ukjent');
  });

  testWidgets('shows a window, never a single time', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OpsTrackingCard(
      status: OpsTrackingStatus(
        state: OpsTrackingStatus.seen,
        promisedStart: kStart,
        promisedEnd: kEnd,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ops-tracking-window')), findsOneWidget);
    expect(find.text('18:40–18:55'), findsOneWidget);
    expect(find.byKey(const Key('ops-tracking-window-note')), findsOneWidget);
  });

  testWidgets('no window yet means no window box, not a fake time', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const OpsTrackingCard(
      status: OpsTrackingStatus(state: OpsTrackingStatus.placed),
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ops-tracking-window')), findsNothing);
  });

  testWidgets('added time is stated in words', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(OpsTrackingCard(
      status: OpsTrackingStatus(
        state: OpsTrackingStatus.seen,
        promisedStart: kStart,
        promisedEnd: kEnd,
        adjustedByMinutes: 10,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ops-tracking-extra-time')), findsOneWidget);
    expect(find.text('Butikken trenger 10 min ekstra'), findsOneWidget);
  });

  testWidgets('labels are localised — English shows English', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      OpsTrackingCard(
        status: OpsTrackingStatus(
          state: OpsTrackingStatus.ready,
          promisedStart: kStart,
          promisedEnd: kEnd,
        ),
      ),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(find.byKey(const Key('ops-tracking-status')));
    expect(label.data, 'Ready for pickup');
  });

  testWidgets('Norwegian shows the shared vocabulary', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      OpsTrackingCard(
        status: OpsTrackingStatus(
          state: OpsTrackingStatus.pickedUp,
          promisedStart: kStart,
          promisedEnd: kEnd,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final Text label = tester.widget<Text>(find.byKey(const Key('ops-tracking-status')));
    expect(label.data, 'På vei');
  });
}
