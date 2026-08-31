import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/dugnad/celebration_models.dart';
import 'package:aerend_customer/ui/kit/ae_theme.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_celebration_overlay.dart';
import 'package:aerend_customer/ui/kit/ae_confetti.dart';

import '../layout/reduced_motion_harness.dart';

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'en'));

  testWidgets('overlay skips confetti under reduced motion', (tester) async {
    final item = PendingCelebration.fromJson({
      'id': 1,
      'type_key': 'T2',
      'club_id': 1,
      'payload': {
        'badge_key': 'sesongambassador',
        'badge_name': 'Sesongambassadør',
        'sto_bonus': 6,
      },
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AeThemeScope(
            palette: AeThemePalette.reenPreClub,
            child: Scaffold(
              body: DugnadCelebrationOverlay(
                item: item,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NEW BADGE UNLOCKED'), findsOneWidget);
    expect(find.text('Sesongambassadør'), findsOneWidget);
    expect(find.byType(AeConfetti), findsNothing);
  });

  testWidgets('T3 shows challenge headline and reward pill', (tester) async {
    final item = PendingCelebration.fromJson({
      'id': 2,
      'type_key': 'T3',
      'club_id': 1,
      'payload': {
        'kind': 'weekly_challenge',
        'title': 'Logg inn 5 dager',
        'description': 'Du var innom hver dag denne uken',
        'reward_points': 30,
      },
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AeThemeScope(
            palette: AeThemePalette.reenPreClub,
            child: Scaffold(
              body: DugnadCelebrationOverlay(
                item: item,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Logg inn 5 dager'), findsOneWidget);
    expect(find.text('Du var innom hver dag denne uken'), findsOneWidget);
    expect(find.text('+30 poeng'), findsOneWidget);
  });

  testWidgets('T4 has no confetti and shows form copy', (tester) async {
    final item = PendingCelebration.fromJson({
      'id': 3,
      'type_key': 'T4',
      'club_id': 1,
      'payload': {
        'new_state': 'up',
        'previous_state': 'flat',
        'form_value': 72,
      },
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AeThemeScope(
            palette: AeThemePalette.reenPreClub,
            child: Scaffold(
              body: DugnadCelebrationOverlay(
                item: item,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('TEMPOET DITT HAR STEGET'), findsOneWidget);
    expect(find.textContaining('Du er i form!'), findsOneWidget);
    expect(find.text('Se formen din'), findsOneWidget);
    expect(find.byType(AeConfetti), findsNothing);
  });

  testWidgets('T6 throne shows copy with confetti under motion', (tester) async {
    final item = PendingCelebration.fromJson({
      'id': 6,
      'type_key': 'T6',
      'club_id': 1,
      'payload': {
        'metric': 'sto',
        'value': 84,
        'display_name': 'Didrik',
      },
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AeThemeScope(
            palette: AeThemePalette.reenPreClub,
            child: Scaffold(
              body: DugnadCelebrationOverlay(
                item: item,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('NY TRONE'), findsOneWidget);
    expect(find.textContaining('høyeste STØ'), findsOneWidget);
    expect(find.text('Se STØ-rangeringsen'), findsOneWidget);
    // Reduced motion still skips confetti paint.
    expect(find.byType(AeConfetti), findsNothing);
  });

  testWidgets('T16 shows STØ rise copy under reduced motion', (tester) async {
    final item = PendingCelebration.fromJson({
      'id': 16,
      'type_key': 'T16',
      'club_id': 1,
      'payload': {
        'previous_sto': 55,
        'new_sto': 57,
        'delta': 2,
        'metal': 'bronse',
        'next_metal': 'solv',
        'next_metal_label': 'Sølv',
        'remaining_to_next': 27,
        'progress_percent': 35,
        'previous_progress_percent': 28,
        'action': 'campaign_purchase',
      },
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          locale: const Locale('no'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AeThemeScope(
            palette: AeThemePalette.reenPreClub,
            child: Scaffold(
              body: DugnadCelebrationOverlay(
                item: item,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('STØ-RATINGEN DIN STEG'), findsOneWidget);
    expect(find.text('Kjøp i kampanje'), findsOneWidget);
    expect(find.text('Se STØ-kortet'), findsOneWidget);
    expect(
      find.textContaining('igjen til Sølv', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(AeConfetti), findsNothing);
  });
}
