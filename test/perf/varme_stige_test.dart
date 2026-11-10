import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// The gentle heat ladder + idle slow-down (approved 2026-11-10): only really
/// hot (Android moderate / severe, iOS serious) lowers the decorative cadence
/// to 30 fps; critical alone stops the motion; the level falls back only after
/// the cooler reading held for a while; 30 s untouched does the same as hot
/// until the next touch; essential loops keep every vsync.
void main() {
  tearDown(() {
    BergenPerf.termiskTvang(null);
    BergenPerf.debugNullstillStige();
    BergenPerf.debugTilstand(thermal: 0, lowPower: false);
    BergenPerf.debugStatus(-1, android: true);
    BergenPerf.tier.value = BergenTier.full;
  });

  Widget host(Widget child) => MaterialApp(home: BergenPerfScope(child: child));

  // The idle count on the test's fake clock.
  setUp(() {
    final b = TestWidgetsFlutterBinding.ensureInitialized();
    final ekte = Stopwatch()..start();
    BergenPerf.debugTidUs = () => b.inTest ? b.clock.now().microsecondsSinceEpoch : ekte.elapsedMicroseconds;
    BergenPerf.debugNullstillStige();
  });

  test('the heat level for each platform status', () {
    // Android PowerManager: none, light, moderate, severe, critical, emergency, shutdown.
    expect([for (var s = 0; s <= 6; s++) BergenPerf.varmeFor(s, android: true)], [0, 0, 1, 1, 2, 2, 2]);
    // iOS ProcessInfo: nominal, fair, serious, critical.
    expect([for (var s = 0; s <= 3; s++) BergenPerf.varmeFor(s, android: false)], [0, 0, 1, 2]);
  });

  test('an older native side (no raw status): fair is never hot, serious is', () {
    BergenPerf.debugStatus(-1, android: true);
    BergenPerf.debugTilstand(thermal: 1);
    expect(BergenPerf.varme.value, 0, reason: 'Android fair = light or moderate: not hot');
    BergenPerf.debugTilstand(thermal: 2);
    expect(BergenPerf.varme.value, 1);
  });

  testWidgets('up at once, down one level at a time after the hold', (tester) async {
    BergenPerf.debugStatus(1, android: true);
    expect(BergenPerf.varme.value, 0, reason: 'light');
    expect(PerfTakt.paa, isFalse);

    BergenPerf.debugStatus(2);
    expect(BergenPerf.varme.value, 1, reason: 'moderate: at once');
    expect(PerfTakt.grunn, 'varme');
    expect(BergenPerf.tier.value, BergenTier.full, reason: 'no tier change below critical');

    // Cooler for less than the hold, then hot again: no change (no flapping).
    BergenPerf.debugStatus(1);
    expect(BergenPerf.debugVarmeVenter, isTrue);
    await tester.pump(const Duration(seconds: 40));
    expect(BergenPerf.varme.value, 1);
    BergenPerf.debugStatus(3);
    expect(BergenPerf.debugVarmeVenter, isFalse, reason: 'hot again cancels the step down');
    BergenPerf.debugStatus(1);
    await tester.pump(const Duration(seconds: 59));
    expect(BergenPerf.varme.value, 1, reason: 'the hold starts again');
    await tester.pump(const Duration(seconds: 2));
    expect(BergenPerf.varme.value, 0);
    expect(PerfTakt.paa, isFalse);

    // Critical: motion off at once; back through hot, a hold per level.
    BergenPerf.debugStatus(4);
    expect(BergenPerf.varme.value, 2);
    expect(BergenPerf.tier.value, BergenTier.still);
    expect(BergenPerf.reason, 'thermal critical');
    BergenPerf.debugStatus(0);
    await tester.pump(const Duration(seconds: 61));
    expect(BergenPerf.varme.value, 1);
    expect(BergenPerf.tier.value, BergenTier.full);
    expect(PerfTakt.grunn, 'varme');
    await tester.pump(const Duration(seconds: 61));
    expect(BergenPerf.varme.value, 0);
    expect(PerfTakt.paa, isFalse);
  });

  testWidgets('iOS: serious is hot, fair is not, critical stops', (tester) async {
    BergenPerf.debugStatus(1, android: false);
    expect(BergenPerf.varme.value, 0);
    BergenPerf.debugStatus(2);
    expect(BergenPerf.varme.value, 1);
    BergenPerf.debugStatus(3);
    expect(BergenPerf.tier.value, BergenTier.still);
  });

  testWidgets('termisk / termiskStatus force a level; varmeStige off goes back at once', (tester) async {
    BergenPerf.debugStatus(0, android: true);
    BergenPerf.termiskTvang(1);
    expect(BergenPerf.varme.value, 0, reason: 'termisk 1 = light on Android');
    BergenPerf.termiskTvang(null, status: 2);
    expect(BergenPerf.varme.value, 1, reason: 'moderate');
    BergenPerf.termiskTvang(2);
    expect(BergenPerf.varme.value, 1, reason: 'termisk 2 = severe');
    BergenPerf.settStige(stige: false, nedSek: 60, ledigSek: 30, takt: false);
    expect(BergenPerf.varme.value, 0);
    expect(PerfTakt.paa, isFalse);
  });

  testWidgets('idle: 30 s untouched → takt, a touch ends it at once', (tester) async {
    BergenPerf.debugStartLedig();
    await tester.pump(const Duration(seconds: 29));
    expect(BergenPerf.ledig.value, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(BergenPerf.ledig.value, isTrue);
    expect(PerfTakt.grunn, 'ledig');
    BergenPerf.beroering();
    expect(BergenPerf.ledig.value, isFalse);
    expect(PerfTakt.paa, isFalse);
    await tester.pump(const Duration(seconds: 20));
    BergenPerf.beroering();
    await tester.pump(const Duration(seconds: 20));
    expect(BergenPerf.ledig.value, isFalse, reason: 'the count restarts on every touch');
    await tester.pump(const Duration(seconds: 11));
    expect(BergenPerf.ledig.value, isTrue);
    // Hot outranks idle as the reason; the takt stays on.
    BergenPerf.debugStatus(2, android: true);
    expect(PerfTakt.grunn, 'varme');
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 0, takt: false);
    expect(BergenPerf.ledig.value, isFalse, reason: 'ledigSek 0 = off');
  });

  /// Ticks of a loop over [n] vsyncs of 16.7 ms.
  Future<int> ticks(WidgetTester tester, List<int> teller, int n) async {
    final f = teller[0];
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    return teller[0] - f;
  }

  Widget loop(List<int> teller, {bool essential = false}) => LfLoop(
    essential: essential,
    builder: (context, t, _) {
      teller[0]++;
      return const SizedBox();
    },
  );

  testWidgets('takt: a decorative loop ticks every other vsync and asks for no frame in between; off = every vsync', (tester) async {
    final teller = [0];
    await tester.pumpWidget(host(loop(teller)));
    expect(await ticks(tester, teller, 60), inInclusiveRange(59, 61), reason: 'normal: every vsync');

    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: true);
    await ticks(tester, teller, 2);
    expect(await ticks(tester, teller, 60), inInclusiveRange(29, 31), reason: 'takt: 30 fps');
    // Right after a takt frame nothing waits on the next vsync.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(microseconds: 16667));
      if (!SchedulerBinding.instance.hasScheduledFrame) break;
    }
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse, reason: 'no frame between takt frames');
    expect(PerfTakt.debugVenter, 1);

    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: false);
    expect(PerfTakt.debugVenter, 0, reason: 'off: released at once');
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue, reason: 'ticks on the very next vsync');
    expect(await ticks(tester, teller, 60), inInclusiveRange(59, 61));
  });

  testWidgets('taktViktig off: essential loops keep every vsync; two decorative loops share the frames', (tester) async {
    final a = [0], b = [0], v = [0];
    await tester.pumpWidget(host(Column(children: [loop(a), loop(b), loop(v, essential: true)])));
    BergenPerf.taktViktigPaa = false; // the A/B setting: essential loops at every vsync
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: true);
    await ticks(tester, a, 3);
    final a0 = a[0], b0 = b[0], v0 = v[0];
    var rammerMedDekor = 0;
    for (var i = 0; i < 60; i++) {
      final fa = a[0], fb = b[0];
      await tester.pump(const Duration(microseconds: 16667));
      expect(a[0] - fa, b[0] - fb, reason: 'both decorative loops tick on the same frames');
      if (a[0] != fa) rammerMedDekor++;
    }
    expect(a[0] - a0, inInclusiveRange(29, 31));
    expect(b[0] - b0, inInclusiveRange(29, 31));
    expect(rammerMedDekor, inInclusiveRange(29, 31));
    expect(v[0] - v0, inInclusiveRange(59, 61), reason: 'essential: every vsync');
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: false);
  });

  testWidgets('taktViktig: essential loops follow the takt too, a game keeps every vsync', (tester) async {
    final v = [0], s = [0];
    await tester.pumpWidget(host(Column(children: [
      loop(v, essential: true),
      BergenEssential(spill: true, child: loop(s)),
    ])));
    expect(BergenPerf.taktViktigPaa, isTrue, reason: 'the default (user decision 2026-11-10)');
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: true);
    await ticks(tester, v, 3);
    final v0 = v[0], s0 = s[0];
    await ticks(tester, v, 60);
    expect(v[0] - v0, inInclusiveRange(29, 31), reason: 'essential: on the takt');
    expect(s[0] - s0, inInclusiveRange(59, 61), reason: 'a game: every vsync');
    BergenPerf.taktViktigPaa = false;
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: false);
  });

  testWidgets('takt: a hidden loop stays muted when the takt releases', (tester) async {
    final teller = [0];
    final vis = ValueNotifier<bool>(true);
    await tester.pumpWidget(host(ValueListenableBuilder<bool>(
      valueListenable: vis,
      builder: (context, v, _) => TickerMode(enabled: v, child: loop(teller)),
    )));
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: true);
    await ticks(tester, teller, 4);
    vis.value = false;
    await tester.pump();
    expect(await ticks(tester, teller, 30), 0, reason: 'hidden: no ticks across takt releases');
    vis.value = true;
    await tester.pump();
    expect(await ticks(tester, teller, 60), inInclusiveRange(28, 32));
    BergenPerf.settStige(stige: true, nedSek: 60, ledigSek: 30, takt: false);
  });

  test('a scene on the takt: 30 fps at most, a slower one keeps its own pace on average', () {
    int renders(int stepUs) {
      var sist = Duration.zero;
      var n = 0;
      // 3 s of takt frames (33.3 ms, ±1 ms jitter).
      for (var k = 1; k <= 90; k++) {
        final e = Duration(microseconds: k * 33333 + (k.isEven ? 900 : -900));
        final s = PerfTakt.steg(e, sist, Duration(microseconds: stepUs));
        if (s != null) {
          sist = s;
          n++;
        }
      }
      return n;
    }

    expect(renders(16667), 90, reason: 'the 60 fps water: every takt frame');
    expect(renders(33000), 90, reason: 'a 30 fps scene: unchanged');
    expect(renders(50000), inInclusiveRange(59, 61), reason: 'a 20 fps scene: still 20 a second');
    expect(renders(66667), inInclusiveRange(44, 46), reason: 'a 15 fps scene: still 15 a second');
  });
}
