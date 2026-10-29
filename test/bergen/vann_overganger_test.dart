import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_routes.dart';
import 'package:aerend_customer/screens/bergen/kit/drape_route.dart';
import 'package:aerend_customer/screens/bergen/kit/fane_bytte.dart';
import 'package:aerend_customer/screens/bergen/kit/laster_dra.dart';
import 'package:aerend_customer/screens/bergen/kit/laster_skjerm.dart';
import 'package:aerend_customer/screens/bergen/kit/vann_overganger.dart';
import 'package:aerend_customer/screens/bergen/meg/meg_ark.dart';

// Bergen 29 Oct: the loaders and the water transitions.

Widget _host(Widget child, {bool rolig = false}) => MaterialApp(
  // Above the navigator, as the app's reduced-motion scope is.
  builder: (c, app) => MediaQuery(
    data: MediaQuery.of(c).copyWith(disableAnimations: rolig, size: const Size(390, 844)),
    child: app!,
  ),
  home: Scaffold(body: child),
);

void main() {
  setUp(() {
    BergenSkjermLaster.nullstill();
    BergenOverganger.ark = ArkOvergang.bolge;
    BergenOverganger.skjerm = SkjermOvergang.menisk;
    BergenOverganger.fane = FaneOvergang.bolge;
  });

  group('Menisk', () {
    testWidgets('a push comes in over 440ms and goes back over 400ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(c).push(MeniskRoute<void>(builder: (_) => const Scaffold(body: Center(child: Text('andre'))))),
                  child: const Text('gå'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('gå'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Mid-way: both screens are there, the new one clipped and moving.
      expect(find.text('andre'), findsOneWidget);
      expect(find.text('gå'), findsOneWidget);
      expect(find.byType(MeniskTopp), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('andre'), findsOneWidget);
      // Back.
      Navigator.of(tester.element(find.text('andre'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('gå'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('andre'), findsNothing);
    });

    testWidgets('the Bergen routes are Menisk by default, the store a Dråpe only on request', (tester) async {
      expect(BergenRoutes.generate(const RouteSettings(name: '/bergen/butikk/5')), isA<MeniskRoute<dynamic>>());
      expect(BergenRoutes.generate(const RouteSettings(name: '/bergen/butikkprofil/5')), isA<MeniskRoute<dynamic>>());
      expect(BergenRoutes.generate(const RouteSettings(name: '/bergen/meg/bestillinger')), isA<MeniskRoute<dynamic>>());
      BergenOverganger.skjerm = SkjermOvergang.draape;
      expect(BergenRoutes.generate(const RouteSettings(name: '/bergen/butikk/5')), isA<DrapeRoute<dynamic>>());
      expect(BergenRoutes.generate(const RouteSettings(name: '/bergen/meg/bestillinger')), isA<MaterialPageRoute<dynamic>>());
    });

    testWidgets('reduced motion: the screen is just there', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => Navigator.of(c).push(MeniskRoute<void>(builder: (_) => const Text('andre'))),
              child: const Text('gå'),
            ),
          ),
          rolig: true,
        ),
      );
      await tester.tap(find.text('gå'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(MeniskTopp), findsNothing);
      expect(find.text('andre'), findsOneWidget);
    });

    testWidgets('MeniskBytte: a later step comes in, an earlier one goes back', (tester) async {
      var steg = 0;
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return MeniskBytte(steg: steg, child: KeyedSubtree(key: ValueKey(steg), child: Center(child: Text('steg $steg'))));
            },
          ),
        ),
      );
      expect(find.text('steg 0'), findsOneWidget);
      // The snapshot is real engine work: run it for real.
      await tester.runAsync(() async {
        set(() => steg = 1);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('steg 1'), findsOneWidget);
        expect(find.text('steg 0'), findsNothing);
        set(() => steg = 0);
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('steg 0'), findsOneWidget);
      });
    });
  });

  group('Bølge', () {
    testWidgets('a Meg Ark rises behind the wave (520ms) and sinks (380ms)', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showMegArk<void>(c, title: 'Et ark', body: (ctx, _) => const Text('innhold')),
              child: const Text('åpne'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('åpne'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(BolgeArk), findsOneWidget);
      expect(find.text('innhold'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Et ark'), findsOneWidget);
      Navigator.of(tester.element(find.text('innhold'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('innhold'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('innhold'), findsNothing);
    });

    testWidgets('Glid keeps the design\'s glide: the wave sits out', (tester) async {
      BergenOverganger.ark = ArkOvergang.glid;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showMegArk<void>(c, title: 'Et ark', body: (ctx, _) => const Text('innhold')),
              child: const Text('åpne'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('åpne'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The wrapper is there but draws nothing of its own.
      expect(find.byType(BolgeArk), findsOneWidget);
      expect(find.byType(CustomPaint).evaluate().where((e) => (e.widget as CustomPaint).painter is OvKantPainter), isEmpty);
    });

    testWidgets('the tab switch: Bølge by default, Dykk and Trapp on request, Av cuts', (tester) async {
      for (final stil in FaneOvergang.values) {
        BergenOverganger.fane = stil;
        await tester.pumpWidget(const SizedBox());
        var i = 0;
        late StateSetter set;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, s) {
                set = s;
                return BergenFaneBytte(
                  index: i,
                  background: const LinearGradient(colors: [Colors.teal, Colors.black]),
                  builder: (context, k) => Center(child: Text('fane $k')),
                );
              },
            ),
          ),
        );
        expect(find.text('fane 0'), findsOneWidget);
        // The test engine never delivers the snapshot: the 300ms fallback
        // makes the switch a cut; the end state is what is checked.
        set(() => i = 1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('fane 1'), findsOneWidget, reason: '$stil');
        expect(find.text('fane 0'), findsNothing, reason: '$stil');
      }
    });

    test('the wave edge keeps its rounded corners and the clip closes', () {
      final k = ovKant(330, 28, (x) => 10 + 4 * (x / 330));
      expect(k.first.dx, 0);
      expect(k.last.dx, 330);
      // At the corner the radius wins over the curve.
      expect(k.first.dy, greaterThanOrEqualTo(28 - .001));
      final p = ovPoly(k, 330, 900);
      expect(p.getBounds().bottom, 900);
    });
  });

  group('Dra for å oppdatere', () {
    testWidgets('pull past 66px arms it, the release updates, then it settles back', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        _host(
          BergenDraLaster(
            onRefresh: () async {
              refreshes++;
              await Future<void>.delayed(const Duration(milliseconds: 100));
            },
            child: ListView(
              physics: BergenDraLaster.physics,
              children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('rad $i'))],
            ),
          ),
        ),
      );
      final g = await tester.startGesture(const Offset(200, 300));
      await g.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(find.text('Dra for å oppdatere'), findsOneWidget);
      await g.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(find.text('Slipp for å oppdatere'), findsOneWidget);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Oppdaterer …'), findsOneWidget);
      expect(refreshes, 1);
      await tester.pump(const Duration(milliseconds: 1700));
      expect(find.text('Oppdatert'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('dra_laster_tekst')), findsNothing);
    });

    testWidgets('a short pull just goes back', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        _host(
          BergenDraLaster(
            onRefresh: () async => refreshes++,
            child: ListView(physics: BergenDraLaster.physics, children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('rad $i'))]),
          ),
        ),
      );
      final g = await tester.startGesture(const Offset(200, 300));
      await g.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(find.text('Dra for å oppdatere'), findsOneWidget);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(refreshes, 0);
      expect(find.byKey(const Key('dra_laster_tekst')), findsNothing);
    });

    testWidgets('reduced motion: no pull', (tester) async {
      await tester.pumpWidget(
        _host(
          BergenDraLaster(
            child: ListView(physics: BergenDraLaster.physics, children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('rad $i'))]),
          ),
          rolig: true,
        ),
      );
      final g = await tester.startGesture(const Offset(200, 300));
      await g.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(find.byKey(const Key('dra_laster_tekst')), findsNothing);
      await g.up();
    });
  });

  group('Lasting mellom skjermer', () {
    testWidgets('the veil shows while the screen loads, a full cycle at least, and leaves', (tester) async {
      var laster = true;
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return BergenSkjermLaster(aktiv: laster, navn: 'Butikken', child: const Text('skjerm'));
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(BergenSkjermLaster.erOppe, isTrue);
      expect(find.byKey(const Key('skjerm_laster_navn')), findsOneWidget);
      expect(find.text('Butikken'), findsOneWidget);
      // Still loading after the cycle's hold point: the veil waits.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(BergenSkjermLaster.erOppe, isTrue);
      set(() => laster = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(BergenSkjermLaster.erOppe, isFalse);
    });

    testWidgets('reduced motion: no veil', (tester) async {
      await tester.pumpWidget(_host(const BergenSkjermLaster(aktiv: true, navn: 'Butikken', child: Text('skjerm')), rolig: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(BergenSkjermLaster.erOppe, isFalse);
    });
  });
}
