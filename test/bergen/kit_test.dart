import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_kit.dart';

Widget _app(Widget child, {bool reducedMotion = false}) => MaterialApp(
  home: Builder(
    builder: (c) => MediaQuery(
      data: MediaQuery.of(c).copyWith(disableAnimations: reducedMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  group('BergenTokens', () {
    test('sea modes map to the design hex', () {
      expect(BergenTokens.seaFor(BergenSea.day), const Color(0xFF9FC3CC));
      expect(BergenTokens.seaFor(BergenSea.evening), const Color(0xFF3D6B7A));
      expect(BergenTokens.seaFor(BergenSea.rain), const Color(0xFF6F8790));
    });

    testWidgets('motion honours reduced motion', (tester) async {
      late Duration d;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) {
              d = BergenTokens.motion(c, BergenTokens.motionBase);
              return const SizedBox();
            },
          ),
          reducedMotion: true,
        ),
      );
      expect(d, Duration.zero);
    });
  });

  group('BergenChip', () {
    testWidgets('renders label and icon, taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          BergenChip(
            label: 'Bakeri',
            icon: Icons.bakery_dining,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Bakeri'), findsOneWidget);
      expect(find.byIcon(Icons.bakery_dining), findsOneWidget);
      await tester.tap(find.text('Bakeri'));
      expect(taps, 1);
    });

    testWidgets('selected chip is orange', (tester) async {
      await tester.pumpWidget(
        _app(const BergenChip(label: 'Valgt', selected: true)),
      );
      await tester.pumpAndSettle();
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((box.decoration as BoxDecoration).color, BergenTokens.orange);
    });
  });

  group('BergenCta3d', () {
    testWidgets('fires onPressed and sinks while pressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _app(BergenCta3d(label: 'Bestill', onPressed: () => pressed++)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Bestill')),
      );
      await tester.pump();
      final down = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(down.transform!.getTranslation().y, BergenCta3d.edge);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_app(const BergenCta3d(label: 'Vent')));
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(of: find.text('Vent'), matching: find.byType(Semantics))
            .first,
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.button, isTrue);
    });
  });

  group('BergenCard', () {
    testWidgets('wraps its child and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(BergenCard(onTap: () => taps++, child: const Text('Kort'))),
      );
      await tester.tap(find.text('Kort'));
      expect(taps, 1);
    });
  });

  group('BergenOfflineBanner', () {
    testWidgets('shows the contract copy when visible', (tester) async {
      await tester.pumpWidget(_app(const BergenOfflineBanner()));
      expect(find.text(BergenOfflineBanner.copy), findsOneWidget);
    });

    testWidgets('renders nothing when hidden', (tester) async {
      await tester.pumpWidget(_app(const BergenOfflineBanner(visible: false)));
      expect(find.text(BergenOfflineBanner.copy), findsNothing);
    });
  });

  group('BergenStepper', () {
    testWidgets('renders four labels and announces the current step', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const BergenStepper(steps: BergenStepper.sporing, current: 2)),
      );
      for (final s in BergenStepper.sporing) {
        expect(find.text(s), findsOneWidget);
      }
      final stepper = tester.widget<Semantics>(
        find
            .ancestor(of: find.text('Klar'), matching: find.byType(Semantics))
            .first,
      );
      expect(stepper.properties.label, 'Steg 3 av 4: På vei');
    });
  });

  group('BergenToast', () {
    testWidgets('shows, holds, then removes itself', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showBergenToast(
                c,
                'Lagt i kurven',
                duration: const Duration(milliseconds: 500),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('Lagt i kurven'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Lagt i kurven'), findsNothing);
    });

    testWidgets('a second toast replaces the first', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () {
                showBergenToast(c, 'Første');
                showBergenToast(c, 'Andre');
              },
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('Første'), findsNothing);
      expect(find.text('Andre'), findsOneWidget);
      hideBergenToast();
      await tester.pump();
      expect(find.text('Andre'), findsNothing);
    });
  });

  group('BergenUndoPill', () {
    testWidgets('Angre runs once and closes the pill', (tester) async {
      var undone = 0;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () =>
                  showBergenUndo(c, message: 'Fjernet', onUndo: () => undone++),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Fjernet'), findsOneWidget);
      await tester.tap(find.text(BergenUndoPill.label));
      await tester.pump();
      expect(undone, 1);
      await tester.pumpAndSettle();
      expect(find.text('Fjernet'), findsNothing);
    });
  });

  group('BergenSheet', () {
    test('handle caption follows the extent', () {
      expect(
        BergenSheet.defaultHandleFor(.28, .28, .92),
        BergenSheetHandle.browse,
      );
      expect(
        BergenSheet.defaultHandleFor(.6, .28, .92),
        BergenSheetHandle.release,
      );
      expect(
        BergenSheet.defaultHandleFor(.92, .28, .92),
        BergenSheetHandle.close,
      );
    });

    testWidgets('renders the handle text and its body', (tester) async {
      await tester.pumpWidget(
        _app(
          const BergenSheet(
            handle: BergenSheetHandle.browse,
            child: Text('Innhold'),
          ),
        ),
      );
      expect(find.text('Alle butikker og varer'), findsOneWidget);
      expect(find.text('Innhold'), findsOneWidget);
    });

    testWidgets('showBergenSheet opens and the handle closes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showBergenSheet<void>(
                c,
                builder: (_) => const Text('Ark-innhold'),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Ark-innhold'), findsOneWidget);
      expect(find.text('Lukk vinduet'), findsOneWidget);
      await tester.tap(find.text('Lukk vinduet'));
      await tester.pumpAndSettle();
      expect(find.text('Ark-innhold'), findsNothing);
    });
  });

  group('BergenArk', () {
    testWidgets('title, subtitle, rows and both CTAs', (tester) async {
      var primary = 0;
      var secondary = 0;
      var row = 0;
      await tester.pumpWidget(
        _app(
          BergenArk(
            title: 'Hentekode',
            subtitle: 'Vis denne i kassen',
            rows: [
              BergenArkRow(label: 'Godt Brød', value: 'Torgallmenningen 2'),
              BergenArkRow(label: 'Ring butikken', onTap: () => row++),
            ],
            primary: BergenArkAction(label: 'Ferdig', onTap: () => primary++),
            secondary: BergenArkAction(
              label: 'Hjelp',
              onTap: () => secondary++,
            ),
          ),
        ),
      );
      expect(find.text('Hentekode'), findsOneWidget);
      expect(find.text('Vis denne i kassen'), findsOneWidget);
      expect(find.text('Torgallmenningen 2'), findsOneWidget);
      await tester.tap(find.text('Ring butikken'));
      await tester.tap(find.text('Ferdig'));
      await tester.tap(find.text('Hjelp'));
      expect([row, primary, secondary], [1, 1, 1]);
    });

    testWidgets('Kopier puts the code on the clipboard and toasts', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        _app(const BergenArk(title: 'Hentekode', copyText: 'A7K-42')),
      );
      await tester.tap(find.text('Kopier'));
      await tester.pump();
      expect(copied, 'A7K-42');
      expect(find.text('Kopiert'), findsOneWidget);
      hideBergenToast();
    });
  });
}
