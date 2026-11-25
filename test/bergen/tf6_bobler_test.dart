import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_vann.dart';

/// TestFlight 6 feedback: «the bubble water droplets animation is missing in the product detail screen» — the
/// prototype's `boblerFri`: while a big scroll area scrolls, a bubble or two every ~90 px (at most five), rising
/// and fading; never in the top 120 px; not in small areas; not with reduced motion.

Widget _ark({double hoyde = 640, bool rolig = false, int rader = 60}) {
  final rull = ScrollController();
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: const Size(390, 844), disableAnimations: rolig),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 390,
            height: hoyde,
            child: HjemVann(
              controller: rull,
              s: 1,
              bobler: false,
              boblerFri: true,
              bunn: false,
              flate: (st) => st <= 2 ? null : (y: 6 + 10 * (st / 40).clamp(0, 1), a: (st / 40).clamp(0, 1).toDouble()),
              child: ListView(controller: rull, children: [for (var i = 0; i < rader; i++) SizedBox(height: 60, child: Text('rad $i'))]),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _rull(WidgetTester tester, int ganger) async {
  for (var i = 0; i < ganger; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => HjemVann.debugBobler.value = const []);

  testWidgets('scrolling the sheet: bubbles rise, never more than five, all below the top 120 px; they clear', (tester) async {
    await tester.pumpWidget(_ark());
    await _rull(tester, 8);
    final b = HjemVann.debugBobler.value;
    expect(b, isNotEmpty, reason: 'bubbles while it scrolls');
    expect(b.length, lessThanOrEqualTo(5));
    for (final o in b) {
      expect(o.dy, greaterThanOrEqualTo(120 + 40 - .01), reason: 'a bubble rose into the top band: $o');
      expect(o.dx, inInclusiveRange(18, 390 - 18));
    }
    // 2.2–3.6 s each, then gone.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(HjemVann.debugBobler.value, isEmpty);
  });

  testWidgets('a small scroll area (< 420 px) or reduced motion: no bubbles', (tester) async {
    await tester.pumpWidget(_ark(hoyde: 380));
    await _rull(tester, 8);
    expect(HjemVann.debugBobler.value, isEmpty, reason: 'viewport under 420');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_ark(rolig: true));
    await _rull(tester, 8);
    expect(HjemVann.debugBobler.value, isEmpty, reason: 'reduced motion');
  });
}
