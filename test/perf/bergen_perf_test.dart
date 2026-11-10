import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// Parity plan Step 2: the motion tiers (full / lite / still) and what each
/// one lets loops, shaders, particles and blur do.
void main() {
  tearDown(() {
    BergenPerf.varmeTrinnGammel = false;
    BergenPerf.termiskTvang(null);
    BergenPerf.debugNullstillStige();
    BergenPerf.debugTilstand(thermal: 0, lowPower: false);
    BergenPerf.tier.value = BergenTier.full;
  });

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

  testWidgets('the heat ladder keeps the tier below critical: fair / serious stay full', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(host(Builder(builder: (c) {
      ctx = c;
      return clock(frozenMs: 300);
    })));
    // (Serious only lowers the decorative cadence — varme_stige_test.)
    for (final thermal in [1, 2]) {
      BergenPerf.debugTilstand(thermal: thermal);
      expect(BergenPerf.tier.value, BergenTier.full, reason: 'thermal $thermal');
      await tester.pump();
      final f = int.parse(shown(tester));
      await tester.pump(const Duration(milliseconds: 500));
      expect(int.parse(shown(tester)), greaterThanOrEqualTo(f + 4), reason: 'a decorative loop runs at thermal $thermal');
      expect(BergenPerf.of(ctx), BergenTier.full);
      expect(BergenPerf.calmOf(ctx), isFalse);
      expect(MediaQuery.disableAnimationsOf(ctx), isFalse, reason: 'no reduced-motion path from heat');
    }
    // Serious left the 30 fps takt on: off before the test ends (its timer).
    BergenPerf.settStige(stige: false, nedSek: 60, ledigSek: 30, takt: false);
  });

  testWidgets('still from low power: even essential loops hold, and it is not «calm»', (tester) async {
    BergenPerf.debugTilstand(lowPower: true);
    expect(BergenPerf.tier.value, BergenTier.still);
    expect(BergenPerf.reason, 'low power mode');
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

  testWidgets('reduce motion is still and calm at every thermal state', (tester) async {
    late BuildContext ctx;
    for (final thermal in [0, 1, 2, 3]) {
      BergenPerf.debugTilstand(thermal: thermal);
      await tester.pumpWidget(host(Builder(builder: (c) {
        ctx = c;
        return clock(essential: true, frozenMs: 300);
      }), calm: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(shown(tester), '3', reason: 'thermal $thermal');
      expect(BergenPerf.of(ctx), BergenTier.still);
      expect(BergenPerf.calmOf(ctx), isTrue);
    }
  });

  test('the tier policy: thermal × low power (× the old step under varmeTrinn)', () {
    for (final lowPower in [false, true]) {
      for (final thermal in [0, 1, 2, 3]) {
        final (t, _) = BergenPerf.velg(thermal: thermal, lowPower: lowPower);
        expect(t, lowPower ? BergenTier.still : BergenTier.full, reason: 'thermal $thermal lowPower $lowPower');
        final (g, _) = BergenPerf.velg(thermal: thermal, lowPower: lowPower, varmeTrinn: true);
        final gammel = lowPower || thermal >= 2 ? BergenTier.still : (thermal == 1 ? BergenTier.lite : BergenTier.full);
        expect(g, gammel, reason: 'old: thermal $thermal lowPower $lowPower');
      }
    }
    // A lite device stays lite under heat; under the old step it went still
    // at serious and stayed lite at fair.
    for (final thermal in [0, 1, 2, 3]) {
      expect(BergenPerf.velg(device: BergenTier.lite, thermal: thermal).$1, BergenTier.lite);
      expect(BergenPerf.velg(device: BergenTier.lite, thermal: thermal, varmeTrinn: true).$1, thermal >= 2 ? BergenTier.still : BergenTier.lite);
    }
    expect(BergenPerf.velg(thermal: 3, lowPower: true, forced: BergenTier.full).$1, BergenTier.full, reason: 'forced wins');
    expect(BergenPerf.velg(thermal: 2, varmeTrinn: true).$2, 'thermal 2');
    expect(BergenPerf.velg(thermal: 1, varmeTrinn: true).$2, 'thermal fair');
    expect(BergenPerf.velg(thermal: 3).$2, 'device');
  });

  testWidgets('varmeTrinn brings back the old step-down (A/B only)', (tester) async {
    BergenPerf.varmeTrinnGammel = true;
    BergenPerf.debugTilstand(thermal: 1);
    expect(BergenPerf.tier.value, BergenTier.lite);
    expect(BergenPerf.reason, 'thermal fair');
    BergenPerf.debugTilstand(thermal: 2);
    expect(BergenPerf.tier.value, BergenTier.still);
    late BuildContext ctx;
    await tester.pumpWidget(host(Builder(builder: (c) {
      ctx = c;
      return clock(essential: true, frozenMs: 300);
    })));
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown(tester), '3');
    expect(BergenPerf.calmOf(ctx), isFalse);
    BergenPerf.varmeTrinnGammel = false;
    BergenPerf.debugTilstand();
    expect(BergenPerf.tier.value, BergenTier.full);
  });

  test('termisk (harness): an injected thermal state stands in for the platform\'s until cleared', () {
    BergenPerf.debugTilstand(thermal: 0);
    BergenPerf.varmeTrinnGammel = true;
    BergenPerf.termiskTvang(2);
    expect(BergenPerf.termisk, 2);
    expect(BergenPerf.tier.value, BergenTier.still, reason: 'as if the platform said serious (old step on)');
    expect(BergenPerf.reason, 'thermal 2');
    // A real reading underneath does not override the injected one.
    BergenPerf.debugTilstand(thermal: 0);
    expect(BergenPerf.tier.value, BergenTier.still);
    BergenPerf.termiskTvang(1);
    expect(BergenPerf.tier.value, BergenTier.lite);
    BergenPerf.termiskTvang(9);
    expect(BergenPerf.termisk, 3, reason: 'clamped to critical');
    // The heat ladder: with the old step off, an injected critical (and only
    // critical) stops the motion.
    BergenPerf.varmeTrinnGammel = false;
    BergenPerf.termiskTvang(2);
    expect(BergenPerf.tier.value, BergenTier.full);
    BergenPerf.termiskTvang(3);
    expect(BergenPerf.tier.value, BergenTier.still);
    expect(BergenPerf.reason, 'thermal critical');
    // Cleared: the real reading again.
    BergenPerf.varmeTrinnGammel = true;
    BergenPerf.debugTilstand(thermal: 1);
    BergenPerf.termiskTvang(null);
    expect(BergenPerf.termisk, isNull);
    expect(BergenPerf.tier.value, BergenTier.lite, reason: 'the real fair');
    BergenPerf.debugTilstand(thermal: 0);
    expect(BergenPerf.tier.value, BergenTier.full);
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
