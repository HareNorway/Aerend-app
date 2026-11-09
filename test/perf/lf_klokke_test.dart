import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aerend_customer/screens/bergen/hjem/hjem_hero.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kaien.dart';
import 'package:aerend_customer/screens/bergen/hjem/hjem_kort.dart';
import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';
import 'package:aerend_customer/screens/bergen/kit/lf_klokke.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';
import 'package:aerend_customer/screens/common/auth/launch/lf_motion.dart';
import 'package:aerend_customer/screens/common/auth/onboarding_kit.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_floats.dart';
import 'package:aerend_customer/screens/common/home/bergen/bergen_rails.dart';

import '../layout/reduced_motion_harness.dart';

/// Heat plan Step 11: the shared clock (`klokkePaa`) hands every loop the
/// same t on the same frame as its own Ticker did — through off-screen rest
/// (Step 2), keyframe-hold sleep (Step 3), TickerMode muting, reduced motion
/// and the frozen test clock — and `ramme` loops (`rammeLoopPaa`) draw the
/// same pixels and layers without rebuilding their builder.
void main() {
  setUpAll(() => bootstrapGlobals(locale: 'no'));

  tearDown(() {
    BergenPerf.klokkePaa = false;
    BergenPerf.rammeLoopPaa = false;
    BergenPerf.frysMs = null;
    BergenPerf.pauseSovPaa = true;
    BergenPerf.hvilePaa = true;
    BergenPerf.usynligPaa = true;
    LfKlokke.debugModus = null;
    timeDilation = 1.0;
  });

  const f16 = Duration(milliseconds: 16);

  // ── The clock against Ticker, call by call ───────────────────────────────

  testWidgets('LfTikker on the clock: the same frames and elapsed time as a Ticker, started / stopped / muted in every phase, and across a move on and off the clock', (tester) async {
    final avKlokka = <LfTikker>{};
    LfKlokke.debugModus = (t) => !avKlokka.contains(t);
    expect(LfKlokke.instance.debugAlle, isEmpty);
    var f = 0;
    final logg = <String, List<(int, int)>>{};
    TickerCallback rec(String navn) => (e) => (logg[navn] ??= []).add((f, e.inMicroseconds));

    // A ticker that runs from start to end keeps the clock scheduled; [foer]
    // runs before the clock's callback in every frame, [etter] after it.
    var slutt = false;
    late void Function(String) gjor;
    void foer(Duration _) {
      gjor('foer');
      if (!slutt) SchedulerBinding.instance.scheduleFrameCallback(foer, rescheduling: true);
    }

    void etter(Duration _) {
      gjor('etter');
      if (!slutt) SchedulerBinding.instance.scheduleFrameCallback(etter, rescheduling: true);
    }

    SchedulerBinding.instance.scheduleFrameCallback(foer);
    final holder = LfTikker(rec('holder'))..start();
    expect(holder.paaKlokka, isTrue);
    SchedulerBinding.instance.scheduleFrameCallback(etter);

    // Pairs: a Ticker and an LfTikker on the clock, driven alike.
    final t = <Ticker>[], k = <LfTikker>[];
    for (var i = 0; i < 6; i++) {
      if (i == 4) {
        // Stops and restarts itself inside its own tick on frame 35.
        void selv(Ticker Function() hvem, String navn, Duration e) {
          (logg[navn] ??= []).add((f, e.inMicroseconds));
          if (f == 35) {
            hvem().stop();
            hvem().start();
          }
        }

        late Ticker ti;
        late LfTikker ki;
        ti = Ticker((e) => selv(() => ti, 'T4', e));
        ki = LfTikker((e) => selv(() => ki, 'K4', e));
        t.add(ti);
        k.add(ki);
      } else {
        t.add(Ticker(rec('T$i')));
        k.add(LfTikker(rec('K$i')));
      }
    }
    void begge(int i, void Function(Ticker x) g) {
      g(t[i]);
      g(k[i]);
    }

    // Starts and unmutes come from every phase (a loop is woken from a scroll
    // animation's tick, a timer, a post-frame check, the build). Stops and
    // mutes come from the idle / build / post-frame phases or the ticker's own
    // tick, as a loop's do: a stop issued by *another* transient callback
    // would depend, for a Ticker, on whether its own slot came before that
    // callback in the frame (the clock has one slot for all).
    gjor = (hvor) {
      switch ((f, hvor)) {
        case (3, 'foer'): // inside a frame, before the clock's callback
          begge(0, (x) => x.start());
        case (6, 'etter'): // inside a frame, after it
          begge(1, (x) => x.start());
        case (9, 'idle'):
          begge(2, (x) => x.start());
        case (12, 'post'): // a post-frame callback
          begge(3, (x) => x.start());
        case (13, 'idle'):
          begge(4, (x) => x.start());
          begge(5, (x) => x.start());
        case (15, 'post'):
          begge(0, (x) => x
            ..stop()
            ..start());
        case (16, 'persist'): // the build phase
          begge(0, (x) => x
            ..stop()
            ..start());
        case (18, 'idle'):
          begge(1, (x) => x.muted = true);
        case (21, 'foer'):
          begge(1, (x) => x.muted = false);
        case (24, 'persist'): // TickerMode mutes in the build phase
          begge(2, (x) => x.muted = true);
        case (25, 'foer'): // unmuted before the clock's slot: not this frame
          begge(2, (x) => x.muted = false);
        case (30, 'foer'): // stopped before both slots (T3's comes after [foer]): no tick
          begge(3, (x) => x.stop());
        case (31, 'idle'):
          begge(3, (x) => x.start());
        case (40, 'idle'):
          timeDilation = 2.0;
        case (44, 'idle'):
          timeDilation = 1.0;
        case (46, 'idle'): // K5 leaves the clock for its own Ticker callback…
          avKlokka.add(k[5]);
          LfKlokke.instance.byttAlle();
          expect(k[5].paaKlokka, isFalse);
        case (50, 'idle'): // …and comes back
          avKlokka.remove(k[5]);
          LfKlokke.instance.byttAlle();
          expect(k[5].paaKlokka, isTrue);
        case (52, 'idle'):
          begge(5, (x) => x.muted = true);
        case (53, 'idle'): // moved while muted
          avKlokka.add(k[5]);
          LfKlokke.instance.byttAlle();
        case (55, 'idle'):
          begge(5, (x) => x.muted = false);
        case (58, 'idle'):
          avKlokka.remove(k[5]);
          LfKlokke.instance.byttAlle();
      }
    };

    // The build phase (persistent callbacks); registered once, off after.
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (!slutt) gjor('persist');
    });
    var ryddet = false;
    void rydd() {
      if (ryddet) return;
      ryddet = true;
      slutt = true;
      for (final x in [...t, ...k, holder]) {
        x.dispose();
      }
    }

    addTearDown(rydd);
    for (f = 1; f <= 64; f++) {
      gjor('idle');
      SchedulerBinding.instance.addPostFrameCallback((_) => gjor('post'));
      await tester.pump(f16);
    }
    for (var i = 0; i < 6; i++) {
      expect(logg['T$i'], isNotEmpty, reason: 'T$i ticked');
      expect(logg['K$i'], logg['T$i'], reason: 'pair $i: same frames, same elapsed µs');
      expect(k[i].paaKlokka, isTrue);
    }
    // The phases mattered: K0 started before the clock's slot ticks first on
    // the next frame (16 ms), never on the frame it was started in.
    expect(logg['K0']!.first, (4, 16000));
    expect(logg['K1']!.first, (7, 16000));
    expect(logg['K2']!.first, (9, 0));
    expect(logg['K3']!.first, (13, 0));
    expect(logg['K1']!.where((r) => r.$1 > 18 && r.$1 <= 21), isEmpty, reason: 'muted');
    expect(logg['K2']!.where((r) => r.$1 == 25), isEmpty, reason: 'unmuted in the transient phase: next frame');
    expect(logg['K3']!.where((r) => r.$1 == 30), isEmpty, reason: 'stopped before the slot');

    rydd();
    expect(LfKlokke.instance.aktive, 0);
    await tester.pump(f16);
    expect(tester.binding.transientCallbackCount, 0, reason: 'nothing left scheduled');
  });

  // ── LfLoop / OnbLoopClock side by side: own Ticker (A) vs the clock (B) ──

  final kA = GlobalKey(debugLabel: 'A'), kB = GlobalKey(debugLabel: 'B');

  /// A on its own ticker, B on the clock: the first ticker created (A's) is
  /// off the clock, the second (B's) on it.
  void aAvBPaa() {
    expect(LfKlokke.instance.debugAlle, isEmpty);
    LfKlokke.debugModus = (t) => LfKlokke.instance.debugAlle.toList().indexOf(t).isOdd;
  }

  void sjekkModus(WidgetTester tester) {
    expect((tester.state(find.byKey(kA)) as LfTikkerVert).debugTikker!.paaKlokka, isFalse);
    expect((tester.state(find.byKey(kB)) as LfTikkerVert).debugTikker!.paaKlokka, isTrue);
  }

  Widget vert({
    required ValueNotifier<bool> modus,
    required ValueNotifier<bool> rolig,
    required Widget Function(Key key) loop,
    ScrollController? ctl,
  }) =>
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: rolig,
          builder: (context, r, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: r), child: child!),
          child: BergenPerfScope(
            child: ValueListenableBuilder<bool>(
              valueListenable: modus,
              builder: (context, paa, child) => TickerMode(enabled: paa, child: child!),
              child: SingleChildScrollView(
                controller: ctl,
                child: Column(
                  children: [
                    Row(children: [loop(kA), loop(kB)]),
                    const SizedBox(height: 4000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('LfLoop: the same t on the same frames on its own Ticker and on the clock — running, muted, reduced motion, frozen clock, keyframe-hold sleep', (tester) async {
    aAvBPaa();
    var f = 0;
    final logg = <Key, List<(int, double)>>{kA: [], kB: []};
    final modus = ValueNotifier<bool>(true), rolig = ValueNotifier<bool>(false);
    // Holds before 200 ms and over 30–100 % of each 1 s cycle (Step 3).
    final hold = ValueNotifier<LfStille?>(null);
    await tester.pumpWidget(vert(
      modus: modus,
      rolig: rolig,
      loop: (key) => ValueListenableBuilder<LfStille?>(
        valueListenable: hold,
        builder: (context, s, _) => LfLoop(
          key: key,
          stille: s,
          frozenMs: 77,
          builder: (context, t, _) {
            logg[key]!.add((f, t));
            return const SizedBox(width: 40, height: 40);
          },
        ),
      ),
    ));
    sjekkModus(tester);
    final r0 = LfKlokke.instance.rammer;

    Future<void> rammer(int n) async {
      for (var i = 0; i < n; i++) {
        f++;
        await tester.pump(f16);
      }
    }

    await rammer(40);
    expect(LfKlokke.instance.rammer - r0, greaterThanOrEqualTo(39), reason: 'B ticked from the clock');
    modus.value = false; // a covered route / hidden tab
    await rammer(10);
    modus.value = true;
    await rammer(10);
    rolig.value = true; // reduced motion: rests at frozenMs
    await rammer(5);
    rolig.value = false;
    await rammer(10);
    BergenPerf.frysMs = 1234; // the frozen test clock
    await rammer(5);
    BergenPerf.frysMs = null;
    BergenPerf.vekkSovende();
    await rammer(10);
    // Step 3: keyframe holds — both sleep and wake on the same frames.
    hold.value = const LfStille(periodeMs: 1000, forsinkelseMs: 200, fra: .3, til: 1, foer: true);
    await rammer(150);
    modus.value = false; // muted while (perhaps) asleep
    await rammer(20);
    modus.value = true;
    await rammer(60);
    hold.value = const LfStille(periodeMs: 1000, forsinkelseMs: 200, fra: .3, til: .9, foer: true); // a new hold map
    await rammer(120);
    BergenPerf.frysMs = 500; // frozen while asleep: wakes, holds the frozen t
    BergenPerf.vekkSovende();
    await rammer(5);
    BergenPerf.frysMs = null;
    BergenPerf.vekkSovende();
    await rammer(40);

    expect(logg[kA]!.length, greaterThan(200));
    expect(logg[kB], logg[kA], reason: 'same (frame, t) records, exactly');
    // Sanity: the sleep really happened (frames without a build).
    final frames = logg[kA]!.map((r) => r.$1).toSet();
    expect(frames.length, lessThan(f - 50), reason: 'slept through holds');
    sjekkModus(tester);
  });

  testWidgets('LfLoop: off-screen rest and wake (Step 2) on the clock as on its Ticker; muted while resting', (tester) async {
    aAvBPaa();
    var f = 0;
    final logg = <Key, List<(int, double)>>{kA: [], kB: []};
    final modus = ValueNotifier<bool>(true), rolig = ValueNotifier<bool>(false);
    final ctl = ScrollController();
    await tester.pumpWidget(vert(
      modus: modus,
      rolig: rolig,
      ctl: ctl,
      loop: (key) => LfLoop(
        key: key,
        builder: (context, t, _) {
          logg[key]!.add((f, t));
          return const SizedBox(width: 40, height: 40);
        },
      ),
    ));
    sjekkModus(tester);
    Future<void> rammer(int n) async {
      for (var i = 0; i < n; i++) {
        f++;
        await tester.pump(f16);
      }
    }

    await rammer(20);
    ctl.jumpTo(3000); // scrolled away: both rest within 12 ticks
    await rammer(30);
    final hvileFra = logg[kA]!.last.$1;
    expect(hvileFra, lessThan(f - 10), reason: 'resting');
    await tester.binding.delayed(const Duration(milliseconds: 400));
    modus.value = false; // muted while resting (Step 2: no wake timer)
    await rammer(5);
    modus.value = true;
    await rammer(5);
    ctl.jumpTo(0); // back: woken by the scroll position
    await rammer(40);

    final a = logg[kA]!, b = logg[kB]!;
    expect(b.map((r) => r.$1).toList(), a.map((r) => r.$1).toList(), reason: 'the same frames');
    for (var i = 0; i < a.length; i++) {
      // The rest's own clock is a real Stopwatch (wall time) in both; the two
      // start and stop microseconds apart — everything else is frame time.
      expect(b[i].$2, closeTo(a[i].$2, 1.0), reason: 'frame ${a[i].$1}');
    }
    final paa = logg[kA]!.where((r) => r.$1 > hvileFra && r.$1 < f - 40);
    expect(paa, isEmpty, reason: 'no builds while resting');
    ctl.dispose();
  });

  testWidgets('OnbLoopClock (local and shared stopwatch): the same frames on the clock as on its Ticker; frozen clock exact; muted and reduced motion', (tester) async {
    for (final delt in [false, true]) {
      aAvBPaa();
      var f = 0;
      final logg = <Key, List<(int, double)>>{kA: [], kB: []};
      final modus = ValueNotifier<bool>(true), rolig = ValueNotifier<bool>(false);
      await tester.pumpWidget(vert(
        modus: modus,
        rolig: rolig,
        loop: (key) => OnbLoopClock(
          key: key,
          shared: delt,
          builder: (context, t, _) {
            logg[key]!.add((f, t));
            return const SizedBox(width: 40, height: 40);
          },
        ),
      ));
      sjekkModus(tester);
      Future<void> rammer(int n) async {
        for (var i = 0; i < n; i++) {
          f++;
          await tester.pump(f16);
        }
      }

      await rammer(30);
      modus.value = false;
      await rammer(8);
      modus.value = true;
      await rammer(8);
      rolig.value = true;
      await rammer(5);
      rolig.value = false;
      await rammer(8);
      BergenPerf.frysMs = 4321;
      await rammer(5);
      BergenPerf.frysMs = null;
      await rammer(10);

      final a = logg[kA]!, b = logg[kB]!;
      expect(b.map((r) => r.$1).toList(), a.map((r) => r.$1).toList(), reason: 'shared=$delt: the same frames');
      // t is a real Stopwatch read in the tick. Local stopwatches start when
      // each loop is created (A before B, in real time), so B - A is a fixed
      // offset; the shared one has none. Frozen frames compare exactly.
      // The first build reads both clocks in initState (no tick): skipped.
      final d = [for (var i = 0; i < a.length; i++) if (a[i].$1 > 0 && a[i].$2 != 4321) b[i].$2 - a[i].$2]..sort();
      final forskyv = delt ? 0.0 : d[d.length ~/ 2];
      for (var i = 0; i < a.length; i++) {
        if (a[i].$2 == 4321) {
          expect(b[i].$2, 4321, reason: 'shared=$delt frame ${a[i].$1}: frozen');
          continue;
        }
        if (a[i].$1 == 0) continue;
        expect(b[i].$2 - a[i].$2, closeTo(forskyv, 1.5), reason: 'shared=$delt frame ${a[i].$1}');
      }
      expect(a.where((r) => r.$2 == 4321).length, b.where((r) => r.$2 == 4321).length);
      expect(a.where((r) => r.$2 == 4321), isNotEmpty, reason: 'the frozen clock reached both');
      await tester.pumpWidget(const SizedBox());
      LfKlokke.debugModus = null;
    }
  });

  testWidgets('OnbLoopClock on the clock sleeps in a hold (no subscriber, no frame callback) and wakes on its timer', (tester) async {
    BergenPerf.klokkePaa = true;
    var bygg = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: OnbLoopClock(
          stille: const LfStille(periodeMs: 300, fra: .1, til: .9),
          builder: (context, t, _) {
            bygg++;
            return const SizedBox(width: 10, height: 10);
          },
        ),
      ),
    ));
    var sov = false, vaaknet = false;
    for (var i = 0; i < 200 && !(sov && vaaknet); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 4)));
      await tester.pump(f16);
      if (LfKlokke.instance.aktive == 0) {
        sov = true;
        expect(tester.binding.transientCallbackCount, 0, reason: 'asleep: the clock asks for no frame');
      } else if (sov) {
        vaaknet = true;
      }
    }
    expect(sov, isTrue);
    expect(bygg, greaterThan(1));
    await tester.pumpWidget(const SizedBox());
    expect(LfKlokke.instance.aktive, 0);
  });

  testWidgets('a running LfLoop moved onto the clock and back (harness klokke1) keeps its t frame for frame', (tester) async {
    final avKlokka = <LfTikker>{};
    LfKlokke.debugModus = (t) => !avKlokka.contains(t) && LfKlokke.instance.debugAlle.toList().indexOf(t).isOdd;
    var f = 0;
    final logg = <Key, List<(int, double)>>{kA: [], kB: []};
    final modus = ValueNotifier<bool>(true), rolig = ValueNotifier<bool>(false);
    await tester.pumpWidget(vert(
      modus: modus,
      rolig: rolig,
      loop: (key) => LfLoop(
        key: key,
        stille: const LfStille(periodeMs: 1000, fra: .5, til: .8),
        builder: (context, t, _) {
          logg[key]!.add((f, t));
          return const SizedBox(width: 40, height: 40);
        },
      ),
    ));
    final tikB = (tester.state(find.byKey(kB)) as LfTikkerVert).debugTikker!;
    Future<void> rammer(int n) async {
      for (var i = 0; i < n; i++) {
        f++;
        await tester.pump(f16);
      }
    }

    await rammer(10);
    avKlokka.add(tikB);
    LfKlokke.instance.byttAlle();
    expect(tikB.paaKlokka, isFalse);
    await rammer(10);
    avKlokka.remove(tikB);
    LfKlokke.instance.byttAlle();
    expect(tikB.paaKlokka, isTrue);
    await rammer(10);
    modus.value = false;
    await rammer(3);
    avKlokka.add(tikB);
    LfKlokke.instance.byttAlle();
    await rammer(3);
    modus.value = true;
    await rammer(10);
    avKlokka.remove(tikB);
    LfKlokke.instance.byttAlle();
    await rammer(80); // through a hold (sleep) after the move
    expect(logg[kB], logg[kA]);
    expect(logg[kA]!.length, greaterThan(60));
  });

  // ── rammeLoop: no rebuilds, the same render objects, pixels and layers ───

  int lfRammeBygg = 0;
  void tellBygg() {
    lfRammeBygg = 0;
    debugOnRebuildDirtyWidget = (e, _) {
      if (e.widget is LfRammeBygger) lfRammeBygg++;
    };
  }

  testWidgets('rammeLoop: a `ramme` loop stops rebuilding its builder (switch on); off it rebuilds every frame as before', (tester) async {
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    Widget tre() => Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                LfLoop(
                  ramme: true,
                  builder: (context, t, child) => Opacity(opacity: .5 + .4 * ((t / 900) % 1.0), child: Transform.rotate(angle: t / 1000, child: child)),
                  child: const SizedBox(width: 20, height: 20, child: ColoredBox(color: Color(0xFF336699))),
                ),
              OnbLoopClock(
                ramme: true,
                builder: (context, t, child) => Transform.translate(offset: Offset((t / 100) % 7, 0), child: child),
                child: const SizedBox(width: 20, height: 20),
              ),
              // Shrunk before its delay: built the normal way until then.
              LfLoop(
                ramme: true,
                builder: (context, t, child) => t < 200 ? const SizedBox.shrink() : Opacity(opacity: .7, child: Transform.scale(scale: 1 + t / 1e4, child: child)),
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        );
    for (final paa in [false, true]) {
      BergenPerf.rammeLoopPaa = paa;
      await tester.pumpWidget(tre());
      tellBygg();
      final d0 = LfKlokke.instance.direkte;
      for (var i = 0; i < 60; i++) {
        await tester.pump(f16);
      }
      debugOnRebuildDirtyWidget = null;
      if (paa) {
        // Only the delayed one, until it has its shape (≈ 13 frames + 1).
        expect(lfRammeBygg, lessThanOrEqualTo(15), reason: 'on: no per-frame rebuilds');
        expect(LfKlokke.instance.direkte - d0, greaterThanOrEqualTo(4 * 60 + 45));
      } else {
        expect(lfRammeBygg, 5 * 60, reason: 'off: each loop rebuilt every frame, as today');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  Future<Uint8List> bilde(WidgetTester tester, Key k, double dpr) async {
    final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(k));
    final img = ro.toImageSync(pixelRatio: dpr);
    final data = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.rawRgba));
    img.dispose();
    return data!.buffer.asUint8List();
  }

  /// Every layer under the boundary with what it composites with.
  List<String> lag(WidgetTester tester, Key k) {
    final ut = <String>[];
    void gaa(Layer l, int d) {
      final s = switch (l) {
        OpacityLayer o => 'Opacity a=${o.alpha} ${o.offset}',
        TransformLayer t => 'Transform ${t.transform?.storage}',
        ClipRectLayer c => 'ClipRect ${c.clipRect} ${c.clipBehavior}',
        OffsetLayer o => '${o.runtimeType} ${o.offset}',
        PictureLayer p => 'Picture ${p.canvasBounds}',
        _ => '${l.runtimeType}',
      };
      ut.add('${' ' * d}$s');
      if (l is ContainerLayer) {
        for (Layer? c = l.firstChild; c != null; c = c.nextSibling) {
          gaa(c, d + 1);
        }
      }
    }

    // The boundary's own layer carries its place on the screen: children only.
    final rot = tester.renderObject<RenderRepaintBoundary>(find.byKey(k)).debugLayer!;
    for (Layer? c = rot.firstChild; c != null; c = c.nextSibling) {
      gaa(c, 0);
    }
    return ut;
  }

  int forskjell(Uint8List a, Uint8List b) {
    expect(a.length, b.length);
    var n = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) n++;
    }
    return n;
  }

  const tider = <double>[0, 137.5, 611, 1600, 2333.3, 3750, 4402.7, 5021, 6400, 9100, 12345.6, 17999];

  testWidgets('rammeLoop pixels: the converted sites\' shapes (LfLoop and OnbLoopClock) draw the same pixels and layers as the original builders at many t', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    BergenPerf.rammeLoopPaa = true;
    const barn = SizedBox(
      width: 60,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(9)),
          gradient: LinearGradient(colors: [Color(0xFFFFE7A8), Color(0xFF2A6474)]),
          boxShadow: [BoxShadow(color: Color(0x88000000), blurRadius: 4, offset: Offset(1, 2))],
        ),
        child: Center(child: Text('99 kr', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 9, color: Color(0xFF5A3C10)))),
      ),
    );
    // The builders of the converted Hjem sites, verbatim in shape.
    final former = <String, Widget Function(BuildContext, double, Widget?)>{
      // hjem_kaien 139: Opacity over a translated, flipped Transform.
      'kaien fisk': (context, t, child) {
        final p = (t / 18000) % 1.0;
        final x = kf(p, const [0, .45, .5, 1], const [-60, 200, 220, -60]);
        final y = kf(p, const [0, .45, .5, 1], const [0, -8, -6, 4]);
        final o = kf(p, const [0, .08, .45, .5, .92, 1], const [0, .7, .7, .5, .6, 0]);
        final flip = p >= .5 ? -1.0 : 1.0;
        return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform(alignment: Alignment.center, transform: Matrix4.translationValues(x / 4, y, 0)..scaleByDouble(flip, 1, 1, 1), child: child));
      },
      // hjem_kaien 1081: nothing before the delay, then fade + rise + scale.
      'kaien boble': (context, t, child) {
        final e = t - 400;
        if (e < 0) return const SizedBox.shrink();
        final p = cssEaseIn.transform((e / 3000) % 1.0);
        final y = 10 + (-84 - 10) * p;
        final sk = .7 + .3 * p;
        final o = kf(p, const [0, .25, 1], const [0, .6, 0]);
        return Opacity(opacity: o, child: Transform.translate(offset: Offset(0, y / 4), child: Transform.scale(scale: sk, child: child)));
      },
      // hjem_kaien 646: perspective rotateX.
      'kaien funn': (context, t, child) {
        final e = t - 600;
        final p = e < 0 ? 0.0 : (e / 5200) % 1.0;
        final y = kf(p, const [0, .5, 1], const [0, -5, 0], cssEaseInOut);
        final rx = kf(p, const [0, .5, 1], const [6, 3, 6], cssEaseInOut);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, -1 / 600)
            ..translateByDouble(0, y, 0, 1)
            ..rotateX(rad(rx)),
          child: child,
        );
      },
      // hjem_hero 1518: translate over rotate.
      'hero stang': (context, t, child) {
        final p = (t / 5200) % 1.0;
        const st = <double>[0, .2, .4, .62, .68, .74, .8, .88, 1];
        final y = kf(p, st, const [0, 1.5, 0, 0, 6, -1, 3, 0, 0], cssEaseInOut);
        final r = kf(p, st, const [0, -4, 3, 0, -8, 4, -2, 0, 0], cssEaseInOut);
        return Transform.translate(offset: Offset(0, y), child: Transform.rotate(angle: rad(r), child: child));
      },
      // hjem_hero 492: shrunk until its delay, then Opacity over Transform.
      'hero dråpe': (context, t, child) {
        final p = kfLoop(t, 600, 9000) ?? -1;
        if (p < 0) return const SizedBox.shrink();
        final y = kf(p, const [0, .7, 1], const [0, 150, 240]);
        final sy = kf(p, const [0, .7, 1], const [1, 1.6, 1.2]);
        final o = kf(p, const [0, .08, .7, 1], const [0, .9, .8, 0]);
        return Opacity(opacity: o.clamp(0.0, 1.0), child: Transform(transform: Matrix4.translationValues(0, y / 10, 0)..scaleByDouble(1, sy, 1, 1), child: child));
      },
      // hjem_kort 608: translate × skewX.
      'kort glans': (context, t, child) {
        final e = t - 1000;
        if (e < 0) return const SizedBox.shrink();
        final x = kf((e / 5500) % 1.0, const [0, .55, 1], const [-1.2, -1.2, 3.2], cssEaseInOut);
        return Transform(transform: Matrix4.translationValues(x * 60 * .26, 0, 0)..multiply(Matrix4.skewX(rad(-18))), child: child);
      },
      // hjem_kort 654: rotate about the left edge.
      'kort lapp': (context, t, child) => Transform.rotate(alignment: Alignment.centerLeft, angle: rad(kf((t / 4400) % 1.0, const [0, .5, 1], const [-7, -3, -7], cssEaseInOut)), child: child),
      // hjem_kort 217 / 540: aegStaa.
      'kort ægil': (context, t, child) => Transform(alignment: Alignment.bottomCenter, transform: aegStaa(t, 3800), child: child),
      // bergen_rails 1387 (BergenKenBurns, OnbLoopClock): ClipRect over Transform.
      'rails kenburns': (context, t, child) {
        var p = (onbLoop(t, 0, 9000) ?? 0);
        p = p < .5 ? p * 2 : 2 - p * 2;
        final e = Curves.easeInOut.transform(p);
        final sc = 1 + .14 * e;
        return ClipRect(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(-2.5 * e, 1.5 * e, 0, 1)
              ..rotateZ(-2 * e * 3.141592653589793 / 180)
              ..scaleByDouble(sc, sc, 1, 1),
            child: child,
          ),
        );
      },
      // bergen_rails _Pulse (OnbLoopClock): Opacity over scale.
      'rails puls': (context, t, child) {
        final p = (onbLoop(t, 0, 1400) ?? 0);
        final o = onbKf(p, const [0, .5, 1], const [1, .35, 1], Curves.easeInOut);
        final sc = onbKf(p, const [0, .5, 1], const [1, .7, 1], Curves.easeInOut);
        return Opacity(opacity: o, child: Transform.scale(scale: sc, child: child));
      },
    };
    final navn = former.keys.toList();
    Key nokkel(String n, bool ramme) => ValueKey('$n/$ramme');
    Widget loop(String n, bool ramme) {
      final onb = n.startsWith('rails');
      final b = former[n]!;
      return RepaintBoundary(
        key: nokkel(n, ramme),
        child: SizedBox(
          width: 120,
          height: 90,
          child: Center(child: onb ? OnbLoopClock(ramme: ramme, builder: b, child: barn) : LfLoop(ramme: ramme, builder: b, child: barn)),
        ),
      );
    }

    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [for (final n in navn) ...[loop(n, false), loop(n, true)]]),
    ));
    final d0 = LfKlokke.instance.direkte;
    tellBygg();
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    var sjekket = 0;
    for (final t in tider) {
      // The frozen clock steps t: both loops tick to exactly this t.
      BergenPerf.frysMs = t;
      await tester.pump(f16);
      for (final n in navn) {
        final a = await bilde(tester, nokkel(n, false), 3);
        final b = await bilde(tester, nokkel(n, true), 3);
        expect(forskjell(a, b), 0, reason: '$n at t=$t: pixels');
        expect(lag(tester, nokkel(n, true)), lag(tester, nokkel(n, false)), reason: '$n at t=$t: layers');
        sjekket++;
      }
    }
    expect(sjekket, tider.length * navn.length);
    // The converted ones went the direct way on (almost) every step.
    expect(LfKlokke.instance.direkte - d0, greaterThan((tider.length - 3) * navn.length));
    expect(lfRammeBygg, lessThan(tider.length * 3), reason: 'only the shape changes rebuilt');
  });

  /// Runs [innhold] with `rammeLoop` off, on and off again (after a warm-up
  /// run), stepping the frozen clock through [tider]; every image and layer
  /// list with the switch on must equal the one with it off.
  Future<void> sammenlign(WidgetTester tester, String navn, Widget Function() innhold, {required int minDirekte}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    BergenPerf.hvilePaa = false; // nothing rests on wall time
    // google_fonts cannot load its fonts in a test (no network); its load
    // futures fail once real async runs (reading the images). Those failures
    // are expected and identical in every run — the test font draws the text.
    final hent = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = hent);
    final andreFeil = <Object>[];
    Future<T> vakt<T>(Future<T> Function() body) => runZonedGuarded(body, (e, _) {
          // The same in every run: no fonts, and the hero's shader scenes
          // cannot compile in the test renderer (they draw nothing).
          if ('$e'.contains('GoogleFonts.config.allowRuntimeFetching') || '$e'.contains('Invalid SkSL')) return;
          andreFeil.add(e);
        })!;
    const k = ValueKey('hjem');
    Widget host() => MaterialApp(
          builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(size: const Size(390, 1400), textScaler: const TextScaler.linear(.5)), child: app!),
          home: Scaffold(
            body: SingleChildScrollView(child: RepaintBoundary(key: k, child: innhold())),
          ),
        );

    Future<List<(Uint8List, List<String>)>> kjor(bool paa) async {
      BergenPerf.rammeLoopPaa = paa;
      // Frozen from the start: the wall-clock extras (the hero's random
      // ripples, rail turns) hold still, so every run is the same.
      BergenPerf.frysMs = 0;
      await tester.pumpWidget(host());
      // Entrances (frame time) finish the same way in every run; images and
      // SVGs decode (real async), then a few frames draw them.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final ut = <(Uint8List, List<String>)>[];
      for (final t in tider) {
        BergenPerf.frysMs = t;
        await tester.pump(f16);
        ut.add((await bilde(tester, k, 2), lag(tester, k)));
      }
      await tester.pumpWidget(const SizedBox());
      return ut;
    }

    await vakt(() => kjor(false)); // warms the image / raster caches
    final av1 = await vakt(() => kjor(false));
    final d0 = LfKlokke.instance.direkte;
    final paa = await vakt(() => kjor(true));
    final direkte = LfKlokke.instance.direkte - d0;
    final av2 = await vakt(() => kjor(false));
    expect(andreFeil, isEmpty);
    var flytt = 0;
    for (var i = 0; i < tider.length; i++) {
      if (i > 0 && forskjell(av1[i].$1, av1[i - 1].$1) > 0) flytt++;
      // ignore: avoid_print
      print('$navn t=${tider[i]}: off/off ${forskjell(av1[i].$1, av2[i].$1)} · on/off ${forskjell(paa[i].$1, av1[i].$1)} bytes differ of ${av1[i].$1.length}, ${paa[i].$2.length} layers');
    }
    // ignore: avoid_print
    print('$navn: $direkte direct updates with the switch on');
    expect(direkte, greaterThanOrEqualTo(minDirekte), reason: 'the converted sites went the direct way');
    for (var i = 0; i < tider.length; i++) {
      expect(forskjell(av1[i].$1, av2[i].$1), 0, reason: 'off vs off at t=${tider[i]} (the reference is stable)');
      expect(forskjell(paa[i].$1, av1[i].$1), 0, reason: 'on vs off at t=${tider[i]}: pixels');
      expect(paa[i].$2, av1[i].$2, reason: 'on vs off at t=${tider[i]}: layers');
    }
    expect(flytt, greaterThan(tider.length ~/ 2), reason: 'the picture really moved between the steps');
  }

  testWidgets('rammeLoop pixels: the real Hjem cards (Pose card, Gavepapir, Under kaien, Ken Burns) look the same with the switch on and off at many t', (tester) async {
    await sammenlign(
      tester,
      'kort',
      () => lfFlow(
        358,
        Column(
          children: [
            HjemPoseKort(tittel: 'Forundringspose', igjen: '2 igjen i kveld', verdi: 'verdi minst 250 kr', kr: '99', onTap: () {}),
            const SizedBox(height: 140, child: HjemGavepapir()),
            SizedBox(
              height: 300,
              child: HjemUnderKaien(
                vist: true,
                reker: HjemKaienFunn(tittel: 'Reker, 1 kg', under: 'Torgboden · før 349', pris: '299 kr', onTap: () {}),
                pose: HjemKaienFunn(tittel: 'Forundringspose', under: 'Verdi minst 250 kr', pris: '99 kr', merke: '2 igjen', onTap: () {}),
                frakt: HjemKaienFunn(tittel: 'Gratis levering', under: 'Over 300 kr · Testbutikk', pris: '0 kr', onTap: () {}),
              ),
            ),
            const SizedBox(width: 200, height: 120, child: BergenKenBurns(seconds: 9, reverse: false, child: ColoredBox(color: Color(0xFF2A6474), child: Center(child: Text('KB'))))),
          ],
        ),
      ),
      minDirekte: tider.length * 10,
    );
  });

  testWidgets('rammeLoop pixels: the Hjem hero (floats, flags, Ægil, pose) looks the same with the switch on and off at many t', (tester) async {
    const floats = [
      BergenFloatItem(id: 'b1', title: 'Reker på tilbud', store: 'Torgboden', priceText: '149 kr', reason: '-', kind: BergenFloatKind.offer, icon: BergenFloatIcon.shrimp, price: 149, wasPrice: 179, bergensk: true, glow: true, ring: true),
      BergenFloatItem(id: 'b2', title: 'Sei er ny', store: 'Nordnes Fisk', priceText: '129 kr', reason: '-', kind: BergenFloatKind.fresh, icon: BergenFloatIcon.fish, price: 129),
    ];
    await sammenlign(
      tester,
      'hero',
      () => SizedBox(
        width: 390,
        height: kHjemHeroH + 60,
        child: HjemHero(vaer: HjemVaer.sol, floats: floats, onFloatAdd: (_) {}, onFloatSink: (_) {}, onFloatNever: (_) {}, onPose: () {}, onFjordfiske: () {}),
      ),
      minDirekte: tider.length * 6,
    );
  });
}
