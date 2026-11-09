import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';

/// Heat plan Steps 2 + 3 together: a loop with a keyframe hold
/// ([LfLoop.stille]) that is scrolled off the screen while asleep in a hold
/// and while resting, and muted by TickerMode while asleep. A hold's
/// one-shot timer (Step 3) and the rest's 120 ms wake timer (Step 2) are
/// never armed together; a wake from a hold keeps frame-time continuity (t
/// is what a ticker that never stopped would show), a wake from a rest keeps
/// the rest's wall-clock stopwatch; nothing is left waiting after dispose.
void main() {
  tearDown(() {
    BergenPerf.pauseSovPaa = true;
    BergenPerf.usynligPaa = true;
    BergenPerf.hvilePaa = true;
    BergenPerf.frysMs = null;
  });

  // 1 s cycle after a 200 ms delay; still before the delay and over 30–100 %
  // of each cycle: holds at t < 200, 500–1200, 1500–2200, 2500–3200, …
  const stille = LfStille(periodeMs: 1000, forsinkelseMs: 200, fra: .3, til: 1, foer: true);
  const annen = LfStille(periodeMs: 1000, forsinkelseMs: 200, fra: .3, til: .99, foer: true);
  const f16 = Duration(milliseconds: 16);

  /// Runs [body] in a zone that sees every timer the loop creates: one-shot
  /// (a hold's sleep) and periodic (the rest's wake check).
  Future<void> medTimere(Future<void> Function(int Function() sov, int Function() vekk, int Function() alle) body) {
    final timere = <({Timer t, bool periodisk})>[];
    int sov() => timere.where((r) => !r.periodisk && r.t.isActive).length;
    int vekk() => timere.where((r) => r.periodisk && r.t.isActive).length;
    int alle() => timere.where((r) => r.t.isActive).length;
    return runZoned(
      () => body(sov, vekk, alle),
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, d, f) {
          final t = parent.createTimer(zone, d, f);
          timere.add((t: t, periodisk: false));
          return t;
        },
        createPeriodicTimer: (self, parent, zone, d, f) {
          final t = parent.createPeriodicTimer(zone, d, f);
          timere.add((t: t, periodisk: true));
          return t;
        },
      ),
    );
  }

  testWidgets('asleep and scrolled away, resting through a hold, muted while resting, back: one timer at a time, t continuous', (tester) async {
    await medTimere((sov, vekk, alle) async {
      double? sist;
      var bygg = 0;
      final ctl = ScrollController();
      final modus = ValueNotifier<bool>(true);
      int aktiv() => tester.binding.transientCallbackCount;
      double ms() => tester.binding.clock.now().microsecondsSinceEpoch / 1000.0;

      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: ValueListenableBuilder<bool>(
              valueListenable: modus,
              builder: (context, paa, child) => TickerMode(enabled: paa, child: child!),
              child: SingleChildScrollView(
                controller: ctl,
                child: Column(
                  children: [
                    LfLoop(
                      stille: stille,
                      builder: (context, t, _) {
                        sist = t;
                        bygg++;
                        return const SizedBox(width: 50, height: 50);
                      },
                    ),
                    const SizedBox(height: 4000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Into the first cycle's hold (t > 500): asleep, only the hold's timer.
      for (var i = 0; i < 200 && (sist ?? 0) <= 500; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0, reason: 'asleep in the hold');
      expect((sov(), vekk()), (1, 0), reason: 'the hold timer only');
      final tS = sist!, cS = ms(), bS = bygg;

      // (1) Scrolled away while asleep: no tick, so no rest — the hold's
      // timer alone still owns the wake.
      ctl.jumpTo(3000);
      await tester.pump(f16);
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0), reason: 'asleep off the screen: still only the hold timer');
      expect(bygg, bS);

      // The hold's timer wakes it (off the screen) on the frame-time clock.
      for (var i = 0; i < 100 && bygg == bS; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), greaterThan(0), reason: 'woken by the hold timer');
      expect((sov(), vekk()), (0, 0));
      expect(sist!, closeTo(tS + ms() - cS, 1e-6), reason: 'frame-time continuity after the sleep');
      expect(sist!, inExclusiveRange(1200 - PerfSov.vekkFoerMs, 1200), reason: 'woken just before the hold ends');

      // (2) It ticks on off the screen, one frame apart, and goes to rest
      // (Step 2) within 12 ticks — before the next hold (t = 1500).
      // [rw] starts before the frame that rests, so it bounds the rest's
      // own stopwatch from above.
      var forrige = sist!;
      var rw = Stopwatch();
      for (var i = 0; i < 20 && aktiv() > 0; i++) {
        rw = Stopwatch()..start();
        await tester.pump(f16);
        expect(sist! - forrige, closeTo(16, 1e-6), reason: 'one frame apart while ticking');
        forrige = sist!;
      }
      expect(aktiv(), 0, reason: 'resting off the screen');
      expect((sov(), vekk()), (0, 1), reason: 'the rest timer only');
      final tR = sist!, bR = bygg;
      expect(tR, lessThan(1500));

      // (3) Resting through a hold window: no sleep timer, no rebuild.
      await tester.binding.delayed(const Duration(milliseconds: 1000));
      expect(aktiv(), 0);
      expect((sov(), vekk()), (0, 1));
      expect(bygg, bR);
      // Muted while resting (Step 2): no timer at all; unmuted: the rest's
      // timer is back, and still no hold timer.
      modus.value = false;
      await tester.pump(f16);
      expect((sov(), vekk()), (0, 0), reason: 'muted rest: nothing waits');
      await tester.binding.delayed(const Duration(milliseconds: 500));
      expect(bygg, bR);
      modus.value = true;
      await tester.pump(f16);
      expect(aktiv(), 0, reason: 'unmuted but still off the screen');
      expect((sov(), vekk()), (0, 1));
      expect(bygg, bR);

      // (4) Back on the screen: woken from the rest on its wall-clock
      // stopwatch (real time in a test), not on the frame clock.
      ctl.jumpTo(0);
      for (var i = 0; i < 30 && bygg == bR; i++) {
        await tester.pump(f16);
      }
      rw.stop();
      expect(aktiv(), greaterThan(0), reason: 'awake again');
      expect((sov(), vekk()), (0, 0));
      expect(sist! - tR, inInclusiveRange(0, rw.elapsedMicroseconds / 1000.0), reason: 'the rest carries its stopwatch time, nothing else');

      // (5) Ticking on, one frame apart, into the next hold: asleep, only the
      // hold's timer (no rest timer).
      forrige = sist!;
      for (var i = 0; i < 100 && aktiv() > 0; i++) {
        await tester.pump(f16);
        expect(sist! - forrige, closeTo(16, 1e-6));
        forrige = sist!;
      }
      expect(aktiv(), 0, reason: 'asleep in the next hold');
      expect((sov(), vekk()), (1, 0));
      expect(stille.igjen(sist!), isNotNull);

      // (6) Disposed while asleep: nothing left waiting.
      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0, reason: 'no pending timer after dispose');
      ctl.dispose();
      modus.dispose();
    });
  });

  testWidgets('muted during a sleep: the hold timer fires into a muted ticker; unmuted, t is the never-stopped ticker\'s', (tester) async {
    await medTimere((sov, vekk, alle) async {
      double? sist;
      var bygg = 0;
      final modus = ValueNotifier<bool>(true);
      final hold = ValueNotifier<LfStille>(stille);
      int aktiv() => tester.binding.transientCallbackCount;
      double ms() => tester.binding.clock.now().microsecondsSinceEpoch / 1000.0;

      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: ValueListenableBuilder<bool>(
              valueListenable: modus,
              builder: (context, paa, child) => TickerMode(enabled: paa, child: child!),
              child: Center(
                child: ValueListenableBuilder<LfStille>(
                  valueListenable: hold,
                  builder: (context, s, _) => LfLoop(
                    stille: s,
                    builder: (context, t, _) {
                      sist = t;
                      bygg++;
                      return const SizedBox(width: 20, height: 20);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 200 && (sist ?? 0) <= 500; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0));
      final tS = sist!, cS = ms(), bS = bygg;

      // Muted while asleep: the ticker is stopped (nothing to mute), the
      // hold's timer still owns the wake; no rest timer (on the screen).
      modus.value = false;
      await tester.pump(f16);
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0));

      // Past the wake time, still muted: the timer has fired and started the
      // ticker, which is muted — no frame, no rebuild, nothing waiting.
      while (tS + ms() - cS < 1300) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0, reason: 'started but muted');
      expect((sov(), vekk()), (0, 0), reason: 'the one-shot fired; nothing else armed');
      expect(bygg, bS);
      // Muted on through motion (1200–1500) and a hold, into the motion of
      // the third cycle (2200–2500).
      while (tS + ms() - cS < 2300) {
        await tester.pump(f16);
      }
      expect(bygg, bS);

      // Unmuted (in a build: the tick is scheduled for the next frame): the
      // first frame has the t a ticker that never stopped would have handed
      // the builder.
      modus.value = true;
      await tester.pump(f16);
      expect(aktiv(), greaterThan(0), reason: 'unmuted: ticking');
      expect(bygg, bS);
      await tester.pump(f16);
      expect(bygg, bS + 1);
      expect(sist!, closeTo(tS + ms() - cS, 1e-6), reason: 'frame-time continuity across the sleep and the mute');
      var forrige = sist!;
      await tester.pump(f16);
      expect(sist! - forrige, closeTo(16, 1e-6));

      // On into the next hold (2500–3200): asleep again.
      for (var i = 0; i < 100 && aktiv() > 0; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0));
      final tS2 = sist!, cS2 = ms();

      // Muted and unmuted inside the sleep: still asleep, still only the
      // hold's timer; it wakes on time, with frame-time continuity.
      modus.value = false;
      await tester.pump(f16);
      modus.value = true;
      await tester.pump(f16);
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0));
      final b2 = bygg;
      for (var i = 0; i < 100 && bygg == b2; i++) {
        await tester.pump(f16);
      }
      expect(sist!, closeTo(tS2 + ms() - cS2, 1e-6));
      expect(sist!, inExclusiveRange(3200 - PerfSov.vekkFoerMs, 3200), reason: 'woken on time, inside the hold');

      // Into the next hold, then a new hold map while asleep
      // (didUpdateWidget): woken in a build, the next frame still has the
      // never-stopped ticker's t.
      for (var i = 0; i < 100 && aktiv() > 0; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0);
      final tS3 = sist!, cS3 = ms();
      hold.value = annen;
      await tester.pump(f16);
      expect(aktiv(), greaterThan(0), reason: 'woken by the new hold map');
      expect(sist, tS3, reason: 'rebuilt by its parent at the same t: started during the build, its first tick is the next frame');
      await tester.pump(f16);
      expect(sist!, closeTo(tS3 + ms() - cS3, 1e-6), reason: 'frame-time continuity after a wake in a build');

      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0, reason: 'no pending timer after dispose');
      modus.dispose();
      hold.dispose();
    });
  });

  testWidgets('disposed while resting (mounted off the screen): nothing left waiting', (tester) async {
    await medTimere((sov, vekk, alle) async {
      final ctl = ScrollController(initialScrollOffset: 3000);
      int aktiv() => tester.binding.transientCallbackCount;
      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: SingleChildScrollView(
              controller: ctl,
              child: Column(
                children: [
                  LfLoop(stille: stille, builder: (context, t, _) => const SizedBox(width: 50, height: 50)),
                  const SizedBox(height: 4000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(f16);
      // Asleep before the delay (t < 200), then woken, then resting.
      expect(aktiv(), 0);
      expect((sov(), vekk()), (1, 0));
      for (var i = 0; i < 40 && vekk() == 0; i++) {
        await tester.pump(f16);
      }
      expect(aktiv(), 0, reason: 'resting');
      expect((sov(), vekk()), (0, 1));
      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0, reason: 'no pending timer after dispose');
      ctl.dispose();
    });
  });
}
