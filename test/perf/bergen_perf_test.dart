import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// Parity plan Step 2: the motion tiers (full / lite / still) and what each
/// one lets loops, shaders, particles and blur do.
void main() {
  tearDown(() => BergenPerf.tier.value = BergenTier.full);

  /// The app's wiring: the calm `MediaQuery` outside, the tier scope inside.
  Widget host(Widget child, {bool calm = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: calm),
        child: BergenPerfScope(child: child),
      ),
    ),
  );

  /// An LfLoop that shows its clock (rounded to 100 ms) as text.
  Widget clock({bool essential = false, double frozenMs = 0}) => LfLoop(
    essential: essential,
    frozenMs: frozenMs,
    builder: (context, t, _) => Text('${(t / 100).floor()}', textDirection: TextDirection.ltr),
  );

  String shown(WidgetTester tester) => (tester.widget(find.byType(Text)) as Text).data!;

  testWidgets('full: loops run', (tester) async {
    await tester.pumpWidget(host(clock()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(int.parse(shown(tester)), greaterThanOrEqualTo(4));
  });

  testWidgets('lite: a decorative loop rests at frozenMs, an essential one runs', (tester) async {
    BergenPerf.tier.value = BergenTier.lite;
    await tester.pumpWidget(host(clock(frozenMs: 700)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown(tester), '7');

    await tester.pumpWidget(host(clock(essential: true)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(int.parse(shown(tester)), greaterThanOrEqualTo(4));

    await tester.pumpWidget(host(BergenEssential(child: clock())));
    await tester.pump(const Duration(milliseconds: 500));
    expect(int.parse(shown(tester)), greaterThanOrEqualTo(4), reason: 'inside BergenEssential');
  });

  testWidgets('still from heat: even essential loops hold, and it is not «calm»', (tester) async {
    BergenPerf.tier.value = BergenTier.still;
    late BuildContext ctx;
    await tester.pumpWidget(host(Builder(builder: (c) {
      ctx = c;
      return clock(essential: true, frozenMs: 300);
    })));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown(tester), '3');
    expect(BergenPerf.of(ctx), BergenTier.still);
    expect(BergenPerf.calmOf(ctx), isFalse);
    expect(MediaQuery.disableAnimationsOf(ctx), isTrue, reason: 'still reuses the reduced-motion path');
  });

  testWidgets('calm (Roligere bevegelse) is always still, and says so', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(host(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }), calm: true));
    expect(BergenPerf.of(ctx), BergenTier.still);
    expect(BergenPerf.calmOf(ctx), isTrue);
  });

  testWidgets('a tier change reaches a running loop', (tester) async {
    await tester.pumpWidget(host(clock(frozenMs: 200)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(int.parse(shown(tester)), greaterThanOrEqualTo(5));
    BergenPerf.tier.value = BergenTier.lite;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown(tester), '2');
  });

  testWidgets('shader pace, pixels, particles and blur per tier', (tester) async {
    final seen = <BergenTier, List<Object?>>{};
    for (final t in BergenTier.values) {
      BergenPerf.tier.value = t;
      await tester.pumpWidget(host(Builder(builder: (c) {
        seen[t] = [
          BergenPerf.shaderStep(c, fullMs: 50, liteMs: 1000 / 12),
          BergenPerf.shaderBudget(c, 160000),
          BergenPerf.count(c, 18),
          BergenPerf.blurOn(c),
        ];
        return const SizedBox();
      })));
    }
    expect(seen[BergenTier.full], [const Duration(milliseconds: 50), 160000.0, 18, true]);
    expect(seen[BergenTier.lite], [const Duration(microseconds: 83333), 88000.0, 9, true]);
    expect(seen[BergenTier.still], [null, 160000.0, 0, false]);
  });

  test('decode width never goes past the screen', () {
    final w = BergenPerf.decodeWidth;
    expect(w, inInclusiveRange(320, 1600));
  });
}
