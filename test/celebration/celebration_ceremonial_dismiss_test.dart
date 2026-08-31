import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/l10n/app_localizations.dart';
import 'package:aerend_customer/screens/dugnad/dugnad_club_theme.dart';
import 'package:aerend_customer/screens/dugnad/widgets/dugnad_ceremonial_screen.dart';

import '../layout/reduced_motion_harness.dart';

void main() {
  setUpAll(() => bootstrapGlobals(locale: 'en'));

  Future<void> open(
    WidgetTester tester, {
    required VoidCallback onDismiss,
    Duration? autoDismissAfter,
    bool showCloseButton = true,
    bool wrapWithAncestorTapDetector = false,
  }) async {
    Widget app = MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DugnadClubThemeScope(
          palette: DugnadClubThemePalette.reenPreClub,
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  DugnadCeremonialScreen.show(
                    context,
                    onDismiss: onDismiss,
                    title: 'Fana IL Fotball',
                    kicker: 'Welcome to the club',
                    autoDismissAfter: autoDismissAfter,
                    showCloseButton: showCloseButton,
                    confettiPieces: 0,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    // Production wraps MaterialApp in a GestureDetector (unfocus-on-tap).
    if (wrapWithAncestorTapDetector) {
      app = GestureDetector(onTap: () {}, child: app);
    }
    await tester.pumpWidget(app);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('T13/T14 ceremonial auto-dismisses after the 7s cap', (tester) async {
    var dismissed = 0;
    await open(
      tester,
      onDismiss: () => dismissed++,
      autoDismissAfter: DugnadCeremonialScreen.kTapDismissMax,
    );

    expect(find.text('Fana IL Fotball'), findsOneWidget);
    expect(dismissed, 0);

    await tester.pump(DugnadCeremonialScreen.kTapDismissMax);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(dismissed, 1);
    expect(find.text('Fana IL Fotball'), findsNothing);
  });

  testWidgets('ceremonial close button pops before the cap', (tester) async {
    var dismissed = 0;
    await open(
      tester,
      onDismiss: () => dismissed++,
      autoDismissAfter: DugnadCeremonialScreen.kTapDismissMax,
      showCloseButton: true,
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Fana IL Fotball'), findsNothing);
    expect(dismissed, 1);
  });

  testWidgets('close button pops under an ancestor tap GestureDetector',
      (tester) async {
    var dismissed = 0;
    await open(
      tester,
      onDismiss: () => dismissed++,
      autoDismissAfter: DugnadCeremonialScreen.kTapDismissMax,
      showCloseButton: true,
      wrapWithAncestorTapDetector: true,
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Fana IL Fotball'), findsNothing);
    expect(dismissed, 1);
  });
}
