import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/screens/aegil/widgets/aegil_settings_panel.dart';

/// AGIL-2-PLAN Phase 6 — the Ægil settings screen.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  /// The panel is a ListView, so anything below the fold has not been built yet.
  Future<void> scrollTo(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  const levels = [
    AegilLevel(level: 0, name: 'Bare når jeg spør', body: 'Svarer i chatten.'),
    AegilLevel(level: 1, name: 'Foreslå', body: 'Husker hva du liker.'),
    AegilLevel(level: 2, name: 'Varsle og foreslå', body: 'Som over, pluss varsler.', isDefault: true),
    AegilLevel(level: 3, name: 'Fyll kurven min', body: 'Legger treff i kurven. Betaler aldri.'),
    AegilLevel(level: 4, name: 'Fast ukeshandel', body: 'Fast ukentlig handel.', requiresRecurring: true),
  ];

  testWidgets('every level is shown with what it actually permits', (tester) async {
    await pump(
      tester,
      const AegilSettingsPanel(settings: AegilSettings(), levels: levels),
    );

    for (final level in levels) {
      expect(find.text('${level.level} · ${level.name}'), findsOneWidget);
      expect(find.text(level.body), findsOneWidget);
    }
  });

  testWidgets('level 4 says it needs a Vipps agreement before it is tapped',
      (tester) async {
    await pump(
      tester,
      const AegilSettingsPanel(
        settings: AegilSettings(recurringAgreement: false),
        levels: levels,
      ),
    );

    // The backend's 422 should be a backstop, not how the customer finds out.
    expect(
      find.byKey(const Key('aegil-level-4-requires-recurring')),
      findsOneWidget,
    );
  });

  testWidgets('that warning disappears once the agreement exists', (tester) async {
    await pump(
      tester,
      const AegilSettingsPanel(
        settings: AegilSettings(recurringAgreement: true),
        levels: levels,
      ),
    );

    expect(find.byKey(const Key('aegil-level-4-requires-recurring')), findsNothing);
  });

  testWidgets('a refused level change is explained in plain words', (tester) async {
    await pump(
      tester,
      const AegilSettingsPanel(
        settings: AegilSettings(),
        levels: levels,
        levelError: 'LEVEL_REQUIRES_RECURRING',
      ),
    );

    expect(
      find.text('Fast ukeshandel krever en Vipps-avtale for gjentakende trekk.'),
      findsOneWidget,
    );
  });

  testWidgets('choosing a level reports it', (tester) async {
    int? chosen;

    await pump(
      tester,
      AegilSettingsPanel(
        settings: const AegilSettings(),
        levels: levels,
        onLevelChanged: (level) => chosen = level,
      ),
    );

    await tester.tap(find.byKey(const Key('aegil-level-1')));
    expect(chosen, 1);
  });

  testWidgets('the against-interest toggle is offered and explained', (tester) async {
    String? toggledField;
    bool? toggledValue;

    await pump(
      tester,
      AegilSettingsPanel(
        settings: const AegilSettings(againstInterestEnabled: true),
        levels: levels,
        onToggle: (field, value) {
          toggledField = field;
          toggledValue = value;
        },
      ),
    );

    await scrollTo(tester, const Key('aegil-against-interest-toggle'));
    expect(find.text('Råd mot Ærends egen interesse'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aegil-against-interest-toggle')));
    expect(toggledField, 'against_interest_enabled');
    expect(toggledValue, isFalse);
  });

  testWidgets('pausing is offered, and resuming when already paused', (tester) async {
    var paused = 0;
    await pump(
      tester,
      AegilSettingsPanel(
        settings: const AegilSettings(),
        levels: levels,
        onPause: (days) => paused = days,
      ),
    );

    await scrollTo(tester, const Key('aegil-pause'));
    await tester.tap(find.byKey(const Key('aegil-pause')));
    expect(paused, 7);

    var resumed = false;
    await pump(
      tester,
      AegilSettingsPanel(
        settings: const AegilSettings(paused: true),
        levels: levels,
        onResume: () => resumed = true,
      ),
    );

    await scrollTo(tester, const Key('aegil-resume'));
    expect(find.byKey(const Key('aegil-paused-notice')), findsOneWidget);
    await tester.tap(find.byKey(const Key('aegil-resume')));
    expect(resumed, isTrue);
  });

  testWidgets('forget-all is always reachable', (tester) async {
    var forgot = false;

    await pump(
      tester,
      AegilSettingsPanel(
        settings: const AegilSettings(),
        levels: levels,
        onForgetAll: () => forgot = true,
      ),
    );

    await scrollTo(tester, const Key('aegil-forget-all'));
    await tester.tap(find.byKey(const Key('aegil-forget-all')));
    expect(forgot, isTrue);
  });

  testWidgets('the panel discloses that Ægil is AI', (tester) async {
    await pump(
      tester,
      const AegilSettingsPanel(settings: AegilSettings(), levels: levels),
    );

    expect(find.textContaining('ikke et menneske'), findsOneWidget);
  });

  group('settings parsing', () {
    test('reads the API payload, including the cart permission', () {
      final parsed = AegilSettings.fromJson({
        'level': 3,
        'level_name': 'Fyll kurven min',
        'push_mode': 'good_only',
        'learning_enabled': true,
        'against_interest_enabled': false,
        'read_aloud': true,
        'recurring_agreement': false,
        'paused': false,
        'may_write_cart': true,
        'quiet_hours': {'from': '22:00', 'to': '07:00'},
      });

      expect(parsed.level, 3);
      expect(parsed.mayWriteCart, isTrue);
      expect(parsed.againstInterestEnabled, isFalse);
      expect(parsed.hasQuietHours, isTrue);
      expect(parsed.quietHoursFrom, '22:00');
    });

    test('defaults to level 2 when the payload is empty', () {
      expect(AegilSettings.fromJson(const {}).level, 2);
    });

    test('a memory entry knows whether it is absolute', () {
      final hard = MemoryEntry.fromJson({
        'id': 1, 'kind': 'allergen', 'value': 'nøtter', 'hard_constraint': true,
      });
      final soft = MemoryEntry.fromJson({
        'id': 2, 'kind': 'like', 'value': 'fisk', 'hard_constraint': false,
      });

      expect(hard.hardConstraint, isTrue);
      expect(soft.hardConstraint, isFalse);
    });
  });
}
