import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/onboarding/onb_lag.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_maal.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_runde.dart';
import 'package:aerend_customer/screens/bergen/onboarding/onb_steg.dart';

import '../layout/reduced_motion_harness.dart';

/// Ægil-runden, Onboarding Step 1: the step table, the hole geometry
/// (`rtVals`), «Tilbake» over missions, and the layer's intro card.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  group('the step table', () {
    test('has the design\'s 17 steps in five sections, the Min Bio step only with the flag', () {
      final med = onbStegListe(bio: true, posisjonGitt: false);
      final uten = onbStegListe(bio: false, posisjonGitt: false);
      expect(med.length, 17);
      expect(uten.length, 16);
      expect(med.first.intro, isTrue);
      expect(med.map((s) => s.sek).toSet(), {'hjem', 'utforsk', 'butikk', 'kurv', 'meg'});
      expect(med.where((s) => s.harOppdrag).map((s) => s.id), ['utforsk', 'legg', 'tilkurv']);
      expect(med[1].handling, 'Bruk posisjonen min');
      expect(onbStegListe(bio: true, posisjonGitt: true)[1].handling, isNull);
      expect(kOnbSeksjoner.length, 5);
    });

    test('«Tilbake» skips the missions and never lands on the intro', () {
      final s = onbStegListe(bio: true, posisjonGitt: false);
      final feed = s.indexWhere((x) => x.id == 'feed');
      expect(s[OnbRunde.tilbakeTil(s, feed)].id, 'hurtig'); // over «utforsk» (a mission)
      expect(OnbRunde.tilbakeTil(s, 1), -1);
      expect(s[OnbRunde.tilbakeTil(s, 2)].id, 'adresse');
    });
  });

  group('the hole', () {
    test('keeps 12 px inside the screen, with tight air for small targets', () {
      // A tab at the bottom edge, 60×52 at (0, 800): small → 2 px air, clamped at 12.
      final h = onbHull(const OnbMaalRekt(Rect.fromLTWH(0, 800, 60, 52), 18), 390, 844, 1);
      expect(h.x, 12);
      expect(h.y, 798);
      expect(h.x + h.w, 62);
      expect(h.y + h.h, 832);
      // In the bottom-left corner: concentric with the phone corner, radius 36 − 12.
      expect(h.hjorne, {'BL'});
      expect(h.r, 17); // h/2 wins over 36 − 12
      // A wide card at (16, 300) 358×90: 7 px air, radius = 26 + 7.
      final k = onbHull(const OnbMaalRekt(Rect.fromLTWH(16, 300, 358, 90), 26), 390, 844, 1);
      expect(k.x, 12);
      expect(k.w, 366);
      expect(k.r, 26); // at the screen edge: no extra air on the radius
      expect(k.hjorne, isEmpty);
      // No target: a point in the middle, nothing cut out.
      final n = onbHull(null, 390, 844, 1);
      expect(n.w, 0);
    });
  });

  group('missions', () {
    test('«legg» is done when the cart grows, «utforsk» / «tilkurv» when the screen is right', () {
      final r = OnbRunde.instance;
      addTearDown(r.reset);
      final s = onbStegListe(bio: true, posisjonGitt: false);
      var antall = 2;
      r.kurvAntall = () => antall;
      final legg = s.firstWhere((x) => x.id == 'legg');
      // No shell in the test: the screen is «annet», so the navigation missions stay open.
      expect(r.oppdragFerdig(s.firstWhere((x) => x.id == 'utforsk')), isFalse);
      expect(r.oppdragFerdig(legg), isTrue); // 2 > the 0 noted at the step's start
      r.kurvAntall = () => 0;
      expect(r.oppdragFerdig(legg), isFalse);
    });
  });

  testWidgets('after the last step, «Fullfør» stamps the section and shows the done card; «Start å handle» ends the run (reduced motion)', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(OnbRunde.instance.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Stack(children: [OnbLag()]))));
    final r = OnbRunde.instance;
    r.start(fra: 99, rolig: true); // clamps to the last step («ai»)
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(r.naa?.id, 'ai');
    expect(find.text('Fullfør'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb-neste')));
    // Reduced motion: the stamp is 200 + 40 + 40 ms, then the done card.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(r.fase, OnbFase.ferdig);
    expect(r.ferdigeSek.length, 5);
    expect(find.byKey(const Key('onb-ferdig')), findsOneWidget);
    expect(find.text('Runden er fullført!'), findsOneWidget);
    expect(find.text('Hjem'), findsOneWidget); // the five small stamps carry the section names
    expect(find.text('Meg'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onb-start')));
    await tester.pump(const Duration(milliseconds: 50));
    // Reduced motion: no kai-hopp, the layer fades out.
    expect(r.fase, OnbFase.ut);
    await tester.pump(const Duration(milliseconds: 300));
    expect(r.aktiv, isFalse);
    expect(r.ferdig, isTrue);
    expect(r.hoppet, isFalse);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the layer is empty until the run starts, then shows the intro card with «Bli med»', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(OnbRunde.instance.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Stack(children: [OnbLag()]))));
    expect(find.byKey(const Key('onb-lag')), findsNothing);

    OnbRunde.instance.start();
    // No shell in the test: the engine waits up to 3 s for Hjem, then talks anyway.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('onb-lag')), findsOneWidget);
    expect(find.text('Bli med'), findsOneWidget);
    expect(find.text('Senere'), findsOneWidget);
    expect(find.byKey(const Key('onb-hopp')), findsNothing); // not on the intro
    expect(OnbRunde.instance.fase, OnbFase.her);

    // «Senere» = hopp over: the layer fades and the run ends.
    await tester.tap(find.byKey(const Key('onb-senere')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(OnbRunde.instance.fase, OnbFase.ut);
    await tester.pump(const Duration(milliseconds: 600));
    expect(OnbRunde.instance.aktiv, isFalse);
    expect(OnbRunde.instance.hoppet, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });
}
