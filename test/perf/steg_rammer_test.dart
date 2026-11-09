import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kit/bergen_perf.dart';

/// Heat plan Step 4: a shader host asks for frames only around its own
/// steps ([PerfStegRammer]) and still renders on exactly the same vsyncs,
/// with the same timestamps and the same scene clock, as a host whose
/// ticker never sleeps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => BergenPerf.stegRammerPaa = true);

  group('simulated vsyncs (lag, timer slop, jitter, 60/90/120 Hz)', () {
    // The hosts' own checks: SpGl (no slack: Sporing 60 fps scenes, Bryggen,
    // SceneGl, lite and calm steps), MegStadion, AegilFloyen; and a SjoWater
    // like check with its 2 ms slack and .05 clamp.
    final verter = <String, (int, int, double)>{
      'SpGl 1000/60': (16667, 0, .1),
      'SpGl Bryggen 31': (31000, 0, .1),
      'SpGl SceneGl 30': (30000, 0, .1),
      'SpGl calm 33333': (33333, 0, .1),
      'SpGl lite 62': (62000, 0, .1),
      'MegStadion 50': (50000, 0, .1),
      'MegStadion lite 1000/12': (83333, 0, .1),
      'AegilFloyen 33': (33000, 0, .1),
      'AegilFloyen lite 66': (66000, 0, .1),
      'Sjo-like 1000/60 - 2': (16667, 2000, .05),
    };
    final paneler = <String, double>{'60.000 Hz': 1e6 / 60, '59.94 Hz': 1e6 / 59.94, '90 Hz': 1e6 / 90, '120 Hz': 1e6 / 120};

    for (final v in verter.entries) {
      for (final pa in paneler.entries) {
        for (final jitter in [0, 300]) {
          for (final andre in [false, true]) {
            for (final maal in [false, true]) {
              final navn = '${v.key} · ${pa.key} · jitter ±$jitter µs · ${andre ? 'other loops run' : 'only animator'}${maal ? ' · target stamps' : ''}';
              test(navn, () {
                final (step, slakk, maks) = v.value;
                final o = _Oppsett(p: pa.value, jitter: jitter, andre: andre, maal: maal, step: step, slakk: slakk, maks: maks);
                final idag = _kjor(o, null);
                final av = _kjor(o, false);
                final paa = _kjor(o, true);
                expect(idag.rE.length, greaterThan(50));
                // Switch off: exactly today, bit for bit.
                expect(av.rE, idag.rE);
                expect(av.rT, idag.rT);
                expect(av.tikk, idag.tikk);
                // Switch on: the same renders at the same timestamps, the same
                // scene clock (to the float the shader gets).
                expect(paa.rE, idag.rE);
                for (var i = 0; i < idag.rT.length; i++) {
                  expect(paa.rT[i], closeTo(idag.rT[i], 1e-9));
                }
                expect(_f32(paa.rT), _f32(idag.rT));
                // Asleep between renders: a tick that renders nothing comes only
                // right before the next possible render (or is one of the first 8).
                for (final e in paa.tomme) {
                  expect(e.$2 - e.$1, greaterThanOrEqualTo(step - slakk - 10000 - pa.value.ceil() - 2000), reason: 'tick at ${e.$2} after render ${e.$1}');
                }
                if (!andre && step - slakk - 10000 >= pa.value + 1500) {
                  expect(paa.tikk, lessThan(idag.tikk), reason: 'frames saved');
                }
              });
            }
          }
        }
      }
    }

    test('hidden (TickerMode) and shown again while asleep: same clock as before', () {
      for (final andre in [false, true]) {
        final o = _Oppsett(p: 1e6 / 60, jitter: 300, andre: andre, maal: false, step: 31000, slakk: 0, maks: .1, skjul: (61, 92));
        final idag = _kjor(o, null);
        final paa = _kjor(o, true);
        expect(paa.rE, idag.rE);
        expect(_f32(paa.rT), _f32(idag.rT));
        // and a short hide (under the .1 s clamp)
        final o2 = _Oppsett(p: 1e6 / 60, jitter: 300, andre: andre, maal: false, step: 50000, slakk: 0, maks: .1, skjul: (40, 43));
        expect(_kjor(o2, true).rE, _kjor(o2, null).rE);
        expect(_f32(_kjor(o2, true).rT), _f32(_kjor(o2, null).rT));
      }
    });

    test('report: frames per second today and with the switch on (only animator)', () {
      final linjer = <String>[];
      for (final v in verter.entries) {
        for (final pa in paneler.entries) {
          final (step, slakk, maks) = v.value;
          final o = _Oppsett(p: pa.value, jitter: 0, andre: false, maal: false, step: step, slakk: slakk, maks: maks);
          final idag = _kjor(o, null), paa = _kjor(o, true);
          linjer.add('${v.key.padRight(26)} ${pa.key.padRight(9)} renders ${(idag.rE.length / 5).toStringAsFixed(1)}/s · frames today ${(idag.tikk / 5).toStringAsFixed(1)}/s → ${(paa.tikk / 5).toStringAsFixed(1)}/s');
        }
      }
      debugPrint('STEG_RAMMER\n${linjer.join('\n')}');
    });
  });

  group('a real Ticker (fake async, 60 Hz with jitter)', () {
    Future<_Logg> kjor(WidgetTester tester, bool paa, int step) async {
      BergenPerf.stegRammerPaa = paa;
      final logg = _Logg();
      final rnd = math.Random(7);
      await tester.pumpWidget(_Vert(step: Duration(microseconds: step), logg: logg, naa: () => tester.binding.clock.now().microsecondsSinceEpoch));
      var sist = 0;
      for (var n = 1; n <= 300; n++) {
        final v = (n * 1e6 / 60).floor() + rnd.nextInt(601) - 300;
        await tester.pump(Duration(microseconds: v - sist));
        sist = v;
        // Asleep right after a render: no ticker callback, no frame asked for.
        if (paa && step > 16667 && n > 20 && logg.rendretNaa) {
          expect(tester.binding.transientCallbackCount, 0);
          expect(tester.binding.hasScheduledFrame, isFalse);
        }
        logg.rendretNaa = false;
      }
      await tester.pumpWidget(const SizedBox());
      return logg;
    }

    for (final step in [31000, 50000, 33000, 16667]) {
      testWidgets('step $step µs: same renders, fewer frames', (tester) async {
        final av = await kjor(tester, false, step);
        final paa = await kjor(tester, true, step);
        expect(av.rE.length, greaterThan(50));
        expect(paa.rE, av.rE);
        expect(_f32(paa.rT), _f32(av.rT));
        if (step > 16667) {
          expect(paa.tikk, lessThan(av.tikk * .7), reason: 'frames saved');
        } else {
          expect(paa.tikk, av.tikk, reason: 'nothing to skip at 60 Hz');
        }
      });
    }
  });
}

List<double> _f32(List<double> t) => Float32List.fromList([for (final x in t) x % 3600]).toList();

class _Oppsett {
  _Oppsett({required this.p, required this.jitter, required this.andre, required this.maal, required this.step, required this.slakk, required this.maks, this.skjul});

  final double p; // vsync period, µs
  final int jitter; // ± µs on each vsync
  final bool andre; // other loops keep a frame going every vsync
  final bool maal; // frame stamps are the target (vsync + period), not the vsync
  final int step, slakk;
  final double maks;
  final (int, int)? skjul; // TickerMode off in frame .$1's build, on in frame .$2's
}

class _Resultat {
  final List<int> rE = [];
  final List<double> rT = [];
  final List<(int, int)> tomme = [];
  int tikk = 0;
}

/// The hosts' tick, as written in SpGl / MegStadion / AegilFloyen.
class _Logikk {
  _Logikk(this.step, this.slakk, this.maks, this.r);

  final Duration step, slakk;
  final double maks;
  final PerfStegRammer? r;
  Duration sist = Duration.zero, prev = Duration.zero;
  double t = 0;

  bool tick(Duration e) {
    final r = this.r;
    r?.tikk(e);
    final dt = r == null ? ((e - prev).inMicroseconds / 1e6).clamp(0.0, maks) : r.dt(e, prev, maks);
    t += dt;
    prev = e;
    if (e - sist < step - slakk) {
      r?.etter(e, sist, step, slakk: slakk);
      return false;
    }
    sist = e;
    r?.etter(e, sist, step, slakk: slakk);
    return true;
  }
}

class _FalskTicker extends Ticker {
  _FalskTicker() : super((_) {});

  bool _m = false;

  @override
  bool get muted => _m;

  @override
  set muted(bool v) => _m = v;

  @override
  bool get isActive => true;
}

class _SimTimer implements Timer {
  _SimTimer(this.av);

  final void Function() av;
  bool _aktiv = true;

  @override
  void cancel() {
    if (_aktiv) av();
    _aktiv = false;
  }

  @override
  bool get isActive => _aktiv;

  @override
  int get tick => 0;
}

/// 5 s of vsyncs. [paa] null: today's host (no rammer); else the rammer with
/// the switch on or off. The engine: a vsync's frame reaches the host only if
/// its ticker was unmuted before the frame was asked for (1 ms before the
/// vsync), or — with other loops running — before the frame's task ran. Each
/// tick runs 0–3 ms after its vsync; the timer fires 0–1 ms late after the
/// Dart VM's truncation to whole ms.
_Resultat _kjor(_Oppsett o, bool? paa) {
  // Separate streams, so the vsyncs are the same in every run.
  final rndV = math.Random(42), rndL = math.Random(43), rndT = math.Random(44);
  final res = _Resultat();
  var naa = 0;
  int? fyrer;
  void Function()? cb;
  Duration? ramme;
  final modus = ValueNotifier<bool>(true);
  final ticker = _FalskTicker();
  PerfStegRammer? r;
  if (paa != null) {
    BergenPerf.stegRammerPaa = paa;
    r = PerfStegRammer(
      ticker,
      tickerModus: () => modus,
      naaUs: () => naa,
      rammeTid: () => ramme,
      timer: (d, f) {
        fyrer = naa + d.inMilliseconds * 1000 + rndT.nextInt(1001);
        cb = f;
        return _SimTimer(() => fyrer = null);
      },
    );
  }
  final l = _Logikk(Duration(microseconds: o.step), Duration(microseconds: o.slakk), o.maks, r);
  var idagMuted = false;
  int? x0;
  var sistRender = 0;
  var forrigeV = -1;
  final per = o.p.floor();
  for (var n = 0; n * o.p < 5e6; n++) {
    var v = (n * o.p).floor() + (o.jitter == 0 ? 0 : rndV.nextInt(2 * o.jitter + 1) - o.jitter);
    if (v <= forrigeV) v = forrigeV + 1;
    forrigeV = v;
    final x = o.maal ? v + per : v;
    final lag = rndL.nextInt(3001);
    final frist = o.andre ? v + lag : v - 1000;
    final f = fyrer;
    if (f != null && f <= frist) {
      naa = math.max(naa, f);
      fyrer = null;
      cb!();
    }
    final muted = r == null ? idagMuted : ticker.muted;
    if (!muted) {
      naa = math.max(naa, v + lag);
      ramme = Duration(microseconds: x);
      x0 ??= x;
      final e = x - x0;
      res.tikk++;
      if (l.tick(Duration(microseconds: e))) {
        res.rE.add(e);
        res.rT.add(l.t);
        sistRender = e;
      } else if (res.tikk > 8) {
        res.tomme.add((sistRender, e));
      }
      naa += 300; // the tick's own work
    }
    // This frame's build: TickerMode flips (the mixin mutes / unmutes).
    final sk = o.skjul;
    if (sk != null && (n == sk.$1 || n == sk.$2)) {
      ramme = Duration(microseconds: x);
      naa = math.max(naa, v + lag);
      final paaNy = n == sk.$2;
      modus.value = paaNy;
      if (r == null) {
        idagMuted = !paaNy;
      } else {
        ticker.muted = !paaNy;
      }
    }
    ramme = null;
  }
  r?.dispose();
  return res;
}

class _Logg {
  final List<int> rE = [];
  final List<double> rT = [];
  int tikk = 0;
  bool rendretNaa = false;
}

class _Vert extends StatefulWidget {
  const _Vert({required this.step, required this.logg, required this.naa});

  final Duration step;
  final _Logg logg;
  final int Function() naa;

  @override
  State<_Vert> createState() => _VertState();
}

class _VertState extends State<_Vert> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final PerfStegRammer _rammer;
  late final _Logikk _l;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _rammer = PerfStegRammer(_ticker, tickerModus: () => TickerMode.getNotifier(context), naaUs: widget.naa);
    _l = _Logikk(widget.step, Duration.zero, .1, _rammer);
    _ticker.start();
  }

  void _tick(Duration e) {
    widget.logg.tikk++;
    if (_l.tick(e)) {
      widget.logg.rE.add(e.inMicroseconds);
      widget.logg.rT.add(_l.t);
      widget.logg.rendretNaa = true;
    }
  }

  @override
  void dispose() {
    _rammer.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
