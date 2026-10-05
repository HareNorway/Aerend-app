import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/common/auth/launch/launch_onboarding.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_laster.dart';

import '../layout/reduced_motion_harness.dart';

/// Step 1 (Launch onboarding): the step machine as the prototype's
/// `onbGaa` drives it, without network calls.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  Widget host(Widget child) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        // Reduced motion: every loop is frozen, so pumps settle.
        data: MediaQuery.of(context).copyWith(disableAnimations: true, size: const Size(440, 956)),
        child: child,
      ),
    ),
  );

  testWidgets('landing → vilkår → konto → logg inn', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const LaunchOnboarding()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Alt du trenger, ett ærend'), findsOneWidget);
    expect(find.text('Se deg rundt først'), findsOneWidget);
    expect(find.text('Har du en vervekode?'), findsOneWidget);

    await tester.ensureVisible(find.text('Bruk e-post'));
    await tester.pump();
    await tester.tap(find.text('Bruk e-post'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Vilkår og personvern'), findsOneWidget);
    expect(find.text('STEG 1/4'), findsOneWidget);

    // The CTA does nothing until the box is ticked (it shakes instead).
    await tester.tap(find.text('Godta og fortsett'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Vilkår og personvern'), findsOneWidget);

    await tester.tap(find.textContaining('Jeg har lest og godtar').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Godta og fortsett'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('STEG 2/4'), findsOneWidget);
    expect(find.text('Opprett konto'), findsWidgets);

    await tester.tap(find.text('Logg inn').first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Velkommen tilbake'), findsOneWidget);
    expect(find.text('Glemt passord?'), findsOneWidget);
  });

  testWidgets('referral link opens the code field', (tester) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const LaunchOnboarding()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.text('Har du en vervekode?'));
    await tester.pump();
    await tester.tap(find.text('Har du en vervekode?'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bruk'), findsOneWidget);
  });

  testWidgets('Laster respects reduced motion', (tester) async {
    await expectRespectsReducedMotion(tester, () => const SizedBox(width: 390, height: 844, child: LfLaster()));
  });
}
