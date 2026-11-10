import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';
import 'package:aerend_customer/screens/common/auth/onboarding_kit.dart';

/// Heat plan Step 3: a loop sleeps inside its own keyframe hold and wakes
/// on time — the builder sees the same t on the same frames outside the
/// holds, and the pose on screen is the same on every frame.
void main() {
  tearDown(() {
    BergenPerf.pauseSovPaa = true;
    BergenPerf.frysMs = null;
  });

  // 1 s cycle after a 200 ms delay: −1 before the delay, 0 → 1 over 0–30 %,
  // then holds at 1 over 30–100 %.
  const stille = LfStille(periodeMs: 1000, forsinkelseMs: 200, fra: .3, til: 1, foer: true);
  double pose(double t) {
    final e = t - 200;
    if (e < 0) return -1;
    return kf((e / 1000) % 1.0, const [0, .3, 1], const [0, 1, 1], cssEaseInOut);
  }

  /// One run: per 16 ms frame, the t the builder got on that frame (null =
  /// not rebuilt), the pose on screen, and whether a ticker was active.
  Future<({List<double?> t, List<double> vist, List<bool> aktiv})> kjor(WidgetTester tester, {LfStille? s, int frames = 220}) async {
    double? sist;
    double vist = double.nan;
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Center(
            child: LfLoop(
              stille: s,
              builder: (context, t, _) {
                sist = t;
                vist = pose(t);
                return const SizedBox(width: 20, height: 20);
              },
            ),
          ),
        ),
      ),
    );
    final ts = <double?>[], vs = <double>[], ak = <bool>[];
    for (var i = 0; i < frames; i++) {
      sist = null;
      await tester.pump(const Duration(milliseconds: 16));
      ts.add(sist);
      vs.add(vist);
      ak.add(tester.binding.transientCallbackCount > 0);
    }
    await tester.pumpWidget(const SizedBox());
    return (t: ts, vist: vs, aktiv: ak);
  }

  testWidgets('(a) same t outside the holds, same pose on every frame; (b) no ticker inside a hold', (tester) async {
    BergenPerf.pauseSovPaa = false;
    final av = await kjor(tester, s: stille);
    BergenPerf.pauseSovPaa = true;
    final paa = await kjor(tester, s: stille);

    var sovet = 0, vaaknet = 0;
    for (var i = 0; i < av.t.length; i++) {
      final t = av.t[i]!; // switch off: rebuilt on every frame
      final igjen = stille.igjen(t);
      if (igjen == null) {
        // Moving: the switch-on run drew this frame, at the same t.
        expect(paa.t[i], t, reason: 'frame $i (t=$t) is in motion');
      } else if (paa.t[i] != null) {
        expect(paa.t[i], t, reason: 'frame $i (t=$t): any frame drawn has the real t');
      }
      expect(paa.vist[i], av.vist[i], reason: 'frame $i (t=$t): the same pose on screen');
      if (igjen != null && igjen < PerfSov.vekkFoerMs - 20) {
        expect(paa.aktiv[i], isTrue, reason: 'frame $i (t=$t): awake before the hold ends');
      }
      if (igjen != null && !paa.aktiv[i]) sovet++;
      if (igjen == null && paa.aktiv[i]) vaaknet++;
    }
    // (b) The ticker sleeps through the holds and runs through the motion.
    expect(sovet, greaterThan(av.t.length ~/ 2), reason: 'most of the hold frames are slept through');
    expect(vaaknet, av.t.where((t) => stille.igjen(t!) == null).length, reason: 'active on every moving frame');
    expect(paa.t.where((t) => t != null).length, lessThan(av.t.length ~/ 2), reason: 'far fewer rebuilds');
  });

  testWidgets('(b) inactive in the hold, active again just before its end', (tester) async {
    double? sist;
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Center(
            child: LfLoop(
              stille: stille,
              builder: (context, t, _) {
                sist = t;
                return const SizedBox(width: 20, height: 20);
              },
            ),
          ),
        ),
      ),
    );
    // Before the delay it sleeps too; on into the first cycle's hold
    // (t > 200 + 300 ms).
    for (var i = 0; i < 200 && (sist ?? 0) <= 500; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.transientCallbackCount, 0, reason: 'asleep in the hold');
    final ved = sist!;
    expect(ved, inExclusiveRange(500, 516));
    // Hold ends at t = 1200; the wake timer fires 50 ms before.
    final tilVekk = 1200 - PerfSov.vekkFoerMs - ved;
    await tester.binding.delayed(Duration(milliseconds: tilVekk.floor() - 5));
    expect(tester.binding.transientCallbackCount, 0, reason: 'still asleep just before the wake');
    expect(sist, ved, reason: 'no rebuild while asleep');
    await tester.binding.delayed(const Duration(milliseconds: 10));
    expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'awake before the hold ends');
    await tester.pump(const Duration(milliseconds: 16));
    expect(sist!, closeTo(ved + tilVekk.floor() - 5 + 10 + 16, 1e-9), reason: 'the first frame after the wake has the wall-clock t');
    expect(sist!, lessThan(1200), reason: 'woken inside the hold');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('(c) switch off: rebuilt on every frame, as a loop with no holds', (tester) async {
    BergenPerf.pauseSovPaa = false;
    final av = await kjor(tester, s: stille);
    BergenPerf.pauseSovPaa = true;
    final uten = await kjor(tester);
    expect(av.t, uten.t);
    expect(av.t.every((t) => t != null), isTrue);
    expect(av.aktiv.every((a) => a), isTrue);
    for (var i = 1; i < av.t.length; i++) {
      expect(av.t[i]! - av.t[i - 1]!, 16, reason: 'wall-clock t, one frame apart');
    }
  });

  testWidgets('frozen clock: no sleep, the frozen t on every frame', (tester) async {
    BergenPerf.frysMs = 700; // inside the hold
    final r = await kjor(tester, s: stille, frames: 40);
    expect(r.aktiv.every((a) => a), isTrue);
    expect(r.vist.every((v) => v == pose(700)), isTrue);
  });

  testWidgets('a sleeping loop wakes for the harness (klokke / pauseSov)', (tester) async {
    double? sist;
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Center(
            child: LfLoop(
              stille: stille,
              builder: (context, t, _) {
                sist = t;
                return const SizedBox(width: 20, height: 20);
              },
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 200 && (sist ?? 0) <= 500; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.binding.transientCallbackCount, 0);
    BergenPerf.frysMs = 300;
    BergenPerf.vekkSovende();
    await tester.pump(const Duration(milliseconds: 16));
    expect(sist, 300);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('OnbLoopClock: sleeps in the hold (no ticker), wakes on its timer', (tester) async {
    // Its clock is a real stopwatch, so the hold is the (long) delay.
    const lang = LfStille(periodeMs: 1000, forsinkelseMs: 60000, fra: 0, til: 0, foer: true);
    var bygg = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BergenPerfScope(
          child: Center(
            child: OnbLoopClock(
              stille: lang,
              builder: (context, t, _) {
                bygg++;
                return const SizedBox(width: 20, height: 20);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0, reason: 'asleep before the delay');
    final b = bygg;
    await tester.binding.delayed(const Duration(seconds: 30));
    expect(tester.binding.transientCallbackCount, 0);
    expect(bygg, b);
    await tester.binding.delayed(const Duration(seconds: 31));
    expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'the wake timer restarted it');
    await tester.pumpWidget(const SizedBox());
  });

  test('the annotated sites hold exactly still inside their LfStille intervals', () {
    // The builders' time → picture maths (copied from each site), sampled
    // over the delay and three cycles: inside every still stretch the
    // picture equals the one at the stretch's end, so it is one picture.
    void still(String navn, LfStille s, Object? Function(double t) f) {
      final slutt = s.forsinkelseMs + 3 * s.periodeMs;
      final steg = s.periodeMs / 4000;
      var n = 0;
      for (var t = 0.0; t < slutt; t += steg) {
        final igjen = s.igjen(t);
        if (igjen == null) continue;
        n++;
        expect(f(t), f(t + igjen * .5), reason: '$navn t=$t');
        expect(f(t), f(t + igjen - 1e-3), reason: '$navn t=$t');
      }
      expect(n, greaterThan(0), reason: navn);
    }

    String? skjult(bool b) => b ? 'skjult' : null;
    still('liveSveip', const LfStille(periodeMs: 6500, forsinkelseMs: 1600, fra: 0, til: .7, foer: true), (t) {
      final e = t - 1600;
      if (e < 0) return skjult(true);
      return kf((e / 6500) % 1.0, const [0, .7, 1], const [-1.3, -1.3, 2.6], cssEaseInOut);
    });
    still('_GullTall', const LfStille(periodeMs: 6000, forsinkelseMs: 1400, fra: 0, til: .72, foer: true), (t) {
      final p = kfLoop(t, 1400, 6000) ?? 0;
      return kf(p, const [0, .72, 1], const [1, 1, -.6], cssEaseInOut);
    });
    for (final (ms, d) in const [(6000.0, 1000.0), (7000.0, 1400.0), (9000.0, 1000.0), (10200.0, 600.0), (11000.0, 1500.0)]) {
      still('skinnSveip3 $ms $d', LfStille(periodeMs: ms, forsinkelseMs: d, fra: 1 / 3, til: 1, foer: true), (t) {
        final p = kfLoop(t, d, ms);
        if (p == null || p > 1 / 3) return skjult(true);
        return '${kf(p, const [0, 1 / 3], const [-1.4, 2.4], const Cubic(.4, 0, .2, 1))} ${kf(p, const [0, .0667, 1 / 3], const [0, .7, 0])}';
      });
    }
    still('_Glint', const LfStille(periodeMs: 6500, forsinkelseMs: 1400, fra: 0, til: .62, foer: true), (t) {
      final p = onbLoop(t, 1400, 6500);
      if (p == null || p < .62) return skjult(true);
      return const Cubic(.5, 0, .3, 1).transform((p - .62) / .38);
    });
    for (final fase in const [0.0, 1234.0, 7499.0]) {
      still('_Glans $fase', LfStille(periodeMs: 7500, forsinkelseMs: -fase % 7500, fra: 0, til: .62, foer: true), (t) {
        final q = onbLoop(t, -fase % 7500, 7500) ?? 0;
        if (q < .62) return skjult(true);
        return Curves.easeInOut.transform((q - .62) / .38);
      });
    }
    still('_Drypp', const LfStille(periodeMs: 16000, forsinkelseMs: 3000, fra: 0, til: .58, foer: true), (t) {
      final e = t - 3000;
      if (e < 0) return skjult(true);
      final p = (e / 16000) % 1.0;
      if (p < .58) return skjult(true);
      return p;
    });
    still('_SveipLys', const LfStille(periodeMs: 8000, forsinkelseMs: 1200, fra: .45, til: 1, foer: true), (t) {
      final p = onbLoop(t, 1200, 8000);
      if (p == null || p > .45) return skjult(true);
      return p;
    });
    still('_Sweep', const LfStille(periodeMs: 6500, fra: .55, til: 1), (t) {
      final p = (onbLoop(t, 0, 6500) ?? 0);
      return p < .55 ? -1.2 + 2.4 * (p / .55) : 1.2;
    });
    still('_Grain', const LfStille(periodeMs: 200, fra: 0, til: 1), (t) => ((t / 200).floor() % 4));
  });
}
