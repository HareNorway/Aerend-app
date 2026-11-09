import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';

/// Heat plan Steps 2 + 4 together: a shader host asleep between its renders
/// ([PerfStegRammer]) that is scrolled off the screen goes to rest
/// ([PerfHvile], woken by [PerfVekker]) and comes back; a host muted by
/// TickerMode while asleep stays muted. A host never holds the rammer's
/// timer while it rests, the scene clock follows the ticker's clock (the
/// rest adds its own seconds), renders stay on the same vsyncs, and nothing
/// is left waiting after dispose.
void main() {
  tearDown(() {
    BergenPerf.stegRammerPaa = true;
    BergenPerf.usynligPaa = true;
    BergenPerf.hvilePaa = true;
  });

  const vsync = Duration(microseconds: 16667);
  const step = Duration(milliseconds: 50);

  /// Runs [body] in a zone that sees every timer: one-shot (the rammer's
  /// wake) and periodic (the rest's 120 ms check).
  Future<void> medTimere(Future<void> Function(int Function() engang, int Function() periodisk, int Function() alle) body) {
    final timere = <({Timer t, bool periodisk})>[];
    return runZoned(
      () => body(
        () => timere.where((r) => !r.periodisk && r.t.isActive).length,
        () => timere.where((r) => r.periodisk && r.t.isActive).length,
        () => timere.where((r) => r.t.isActive).length,
      ),
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

  /// The host's scene clock moves with the ticker's clock between two ticks
  /// that have no rest between them, and its renders are exactly the first
  /// vsync at or after `sist + step` (3 vsyncs at 60 Hz).
  void sammenhengende(_Logg l, {int fra = 0}) {
    for (var i = fra + 1; i < l.tikk.length; i++) {
      final a = l.tikk[i - 1], b = l.tikk[i];
      if (b.etterHvile) continue;
      expect(b.t - a.t, closeTo((b.e - a.e) / 1e6, 1e-9), reason: 'tick $i: scene clock = ticker clock');
    }
    for (var i = 1; i < l.render.length; i++) {
      if (l.render[i].etterHvile) continue;
      expect(l.render[i].e - l.render[i - 1].e, 3 * vsync.inMicroseconds, reason: 'render $i on the same vsync as a ticker that never slept');
    }
  }

  testWidgets('asleep between renders → scrolled away → rest (no rammer timer) → muted/unmuted at rest → back → asleep again', (tester) async {
    await medTimere((engang, periodisk, alle) async {
      final logg = _Logg();
      final nokkel = GlobalKey<_VertState>();
      final ctl = ScrollController();
      final modus = ValueNotifier<bool>(true);
      _VertState v() => nokkel.currentState!;
      int aktiv() => tester.binding.transientCallbackCount;

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
                    _Vert(key: nokkel, step: step, logg: logg, naa: () => tester.binding.clock.now().microsecondsSinceEpoch),
                    const SizedBox(height: 4000),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Warm-up (8 ticks every vsync), then asleep right after a render.
      for (var i = 0; i < 60 && !(v().sover && logg.render.length > 4); i++) {
        await tester.pump(vsync);
      }
      expect(v().sover, isTrue, reason: 'asleep between renders');
      expect(v().muted, isTrue);
      expect(aktiv(), 0, reason: 'no frame asked for while asleep');
      expect((engang(), periodisk()), (1, 0), reason: 'only the rammer timer');

      // (1) Scrolled away while asleep: nothing ticks, so no rest yet.
      ctl.jumpTo(3000);
      expect(v().hviler, isFalse);
      expect((engang(), periodisk()), (1, 0));

      // The rammer timer wakes it; the vsync count (PerfHvile.tikk(n:)) puts
      // it to rest off the screen within 12 vsyncs.
      for (var i = 0; i < 40 && !v().hviler; i++) {
        await tester.pump(vsync);
      }
      expect(v().hviler, isTrue, reason: 'resting off the screen');
      expect(v().sover, isFalse, reason: 'a resting host never holds the rammer timer');
      expect(v().aktiv, isFalse);
      expect(v().muted, isFalse, reason: 'not left muted by the rammer, so PerfVekker can wake it');
      expect(aktiv(), 0);
      expect((engang(), periodisk()), (0, 1), reason: 'only the rest timer');
      final nTikk = logg.tikk.length;

      // (2) Resting: no ticks, no rammer timer.
      await tester.binding.delayed(const Duration(milliseconds: 600));
      expect(logg.tikk.length, nTikk);
      expect((engang(), periodisk()), (0, 1));
      // Muted at rest (Step 2): no timer at all; unmuted: the rest timer.
      modus.value = false;
      await tester.pump(vsync);
      expect((engang(), periodisk()), (0, 0));
      modus.value = true;
      await tester.pump(vsync);
      expect(v().hviler, isTrue, reason: 'still off the screen');
      expect((engang(), periodisk()), (0, 1));
      expect(logg.tikk.length, nTikk);

      // (3) Back on the screen: PerfVekker wakes it; the scene clock gains the
      // rest's seconds and the new ticker's first elapsed time.
      ctl.jumpTo(0);
      for (var i = 0; i < 20 && logg.tikk.length == nTikk; i++) {
        await tester.pump(vsync);
      }
      expect(v().hviler, isFalse);
      expect(logg.hvilt, hasLength(1));
      final forst = logg.tikk[nTikk];
      expect(forst.etterHvile, isTrue);
      expect(forst.t, closeTo(logg.tikk[nTikk - 1].t + logg.hvilt.single + forst.e / 1e6, 1e-9), reason: 'rest continuity');

      // (4) Ticking on: warm-up again, then asleep between renders; the same
      // vsyncs as a ticker that never slept.
      for (var i = 0; i < 60 && !(v().sover && logg.render.where((r) => r.etterHvile || r.e > forst.e).length > 4); i++) {
        await tester.pump(vsync);
      }
      expect(v().sover, isTrue);
      expect((engang(), periodisk()), (1, 0));
      sammenhengende(logg);

      // (5) Disposed while asleep: nothing left waiting.
      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0);
      ctl.dispose();
      modus.dispose();
    });
  });

  testWidgets('muted by TickerMode while asleep: stays muted when the timer fires; unmuted, the same renders and scene clock as without the rammer', (tester) async {
    /// 240 vsyncs; hidden in the build of frame [skjul] (with the rammer:
    /// the first frame from 61 on that finds the host asleep), shown 60
    /// frames later.
    Future<({_Logg logg, int skjul})> kjor(bool paa, {int? skjul, void Function(_VertState v)? skjult, void Function(int tikkVedSkjul)? vist}) async {
      BergenPerf.stegRammerPaa = paa;
      final logg = _Logg();
      final nokkel = GlobalKey<_VertState>();
      final modus = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: ValueListenableBuilder<bool>(
              valueListenable: modus,
              builder: (context, paa, child) => TickerMode(enabled: paa, child: child!),
              child: Center(child: _Vert(key: nokkel, step: step, logg: logg, naa: () => tester.binding.clock.now().microsecondsSinceEpoch)),
            ),
          ),
        ),
      );
      var sk = skjul;
      var tikkVedSkjul = 0;
      for (var n = 1; n <= 240; n++) {
        if (sk == null && n >= 61 && nokkel.currentState!.sover) sk = n;
        if (n == sk) modus.value = false;
        if (sk != null && n == sk + 60) modus.value = true;
        await tester.pump(vsync);
        if (n == sk) tikkVedSkjul = logg.tikk.length;
        if (sk != null && n == sk + 20) {
          expect(logg.tikk.length, tikkVedSkjul, reason: 'nothing ticks while hidden');
          skjult?.call(nokkel.currentState!);
        }
      }
      await tester.pumpWidget(const SizedBox());
      modus.dispose();
      return (logg: logg, skjul: sk!);
    }

    await medTimere((engang, periodisk, alle) async {
      final paa = await kjor(true, skjult: (v) {
        // Past the rammer's wake, still hidden: the timer fired into a muted
        // ticker — started, muted, no frame asked for, nothing waiting (it
        // is on the screen, so no rest either).
        expect(v.sover, isFalse);
        expect(v.aktiv, isTrue);
        expect(v.muted, isTrue);
        expect(v.hviler, isFalse);
        expect(tester.binding.transientCallbackCount, 0);
        expect((engang(), periodisk()), (0, 0));
      });
      expect(alle(), 0, reason: 'no pending timer after dispose');
      final av = await kjor(false, skjul: paa.skjul);
      // The same renders, at the same ticker times, with the same scene clock
      // (across the hide: the .1 s clamp cut kept), as without the rammer.
      expect([for (final r in paa.logg.render) r.e], [for (final r in av.logg.render) r.e]);
      for (var i = 0; i < av.logg.render.length; i++) {
        expect(paa.logg.render[i].t, closeTo(av.logg.render[i].t, 1e-9), reason: 'render $i');
      }
      expect(paa.logg.tikk.length, lessThan(av.logg.tikk.length * .7), reason: 'frames saved');
      expect(alle(), 0);
    });
  });

  testWidgets('disposed while resting, and while asleep and muted: nothing left waiting', (tester) async {
    await medTimere((engang, periodisk, alle) async {
      final logg = _Logg();
      final nokkel = GlobalKey<_VertState>();
      final ctl = ScrollController(initialScrollOffset: 3000);
      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: SingleChildScrollView(
              controller: ctl,
              child: Column(
                children: [
                  _Vert(key: nokkel, step: step, logg: logg, naa: () => tester.binding.clock.now().microsecondsSinceEpoch),
                  const SizedBox(height: 4000),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 30 && !nokkel.currentState!.hviler; i++) {
        await tester.pump(vsync);
      }
      expect(nokkel.currentState!.hviler, isTrue);
      expect((engang(), periodisk()), (0, 1));
      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0, reason: 'disposed while resting');
      ctl.dispose();

      final modus = ValueNotifier<bool>(true);
      final n2 = GlobalKey<_VertState>();
      await tester.pumpWidget(
        MaterialApp(
          home: BergenPerfScope(
            child: ValueListenableBuilder<bool>(
              valueListenable: modus,
              builder: (context, paa, child) => TickerMode(enabled: paa, child: child!),
              child: Center(child: _Vert(key: n2, step: step, logg: _Logg(), naa: () => tester.binding.clock.now().microsecondsSinceEpoch)),
            ),
          ),
        ),
      );
      for (var i = 0; i < 60 && !n2.currentState!.sover; i++) {
        await tester.pump(vsync);
      }
      expect(n2.currentState!.sover, isTrue);
      modus.value = false;
      await tester.pump(vsync);
      expect(engang(), 1);
      await tester.pumpWidget(const SizedBox());
      expect(alle(), 0, reason: 'disposed while asleep and muted');
      modus.dispose();
    });
  });
}

class _Logg {
  final List<({int e, double t, bool etterHvile})> tikk = [];
  final List<({int e, double t, bool etterHvile})> render = [];
  final List<double> hvilt = [];
  bool _nyHvile = false;
}

/// A shader host's ticking, line for line as in SpGl / AegilFloyen (no
/// shader): PerfStegRammer first, then PerfHvile with the vsync count, the
/// scene clock from the rammer's dt, the step check, and etter.
class _Vert extends StatefulWidget {
  const _Vert({super.key, required this.step, required this.logg, required this.naa});

  final Duration step;
  final _Logg logg;
  final int Function() naa;

  @override
  State<_Vert> createState() => _VertState();
}

class _VertState extends State<_Vert> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final PerfStegRammer _rammer;
  late final PerfHvile _hvile = PerfHvile(context, _ticker, onVaakn: (s) {
    _t += s;
    _prev = Duration.zero;
    _sist = Duration.zero;
    widget.logg.hvilt.add(s);
    widget.logg._nyHvile = true;
  });
  Duration _sist = Duration.zero, _prev = Duration.zero;
  double _t = 0;
  bool _renderEtterHvile = false;

  bool get sover => _rammer.sover;
  bool get hviler => _hvile.hviler;
  bool get aktiv => _ticker.isActive;
  bool get muted => _ticker.muted;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _rammer = PerfStegRammer(_ticker, tickerModus: () => TickerMode.getNotifier(context), naaUs: widget.naa);
    _ticker.start();
  }

  void _tick(Duration e) {
    _rammer.tikk(e);
    if (_hvile.tikk(n: _rammer.n)) return;
    final dt = _rammer.dt(e, _prev, .1);
    _t += dt;
    _prev = e;
    final ny = widget.logg._nyHvile;
    widget.logg._nyHvile = false;
    if (ny) _renderEtterHvile = true;
    widget.logg.tikk.add((e: e.inMicroseconds, t: _t, etterHvile: ny));
    if (e - _sist < widget.step) {
      _rammer.etter(e, _sist, widget.step);
      return;
    }
    _sist = e;
    _rammer.etter(e, _sist, widget.step);
    widget.logg.render.add((e: e.inMicroseconds, t: _t, etterHvile: _renderEtterHvile));
    _renderEtterHvile = false;
  }

  @override
  void dispose() {
    _hvile.dispose();
    _rammer.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 50, height: 50);
}
