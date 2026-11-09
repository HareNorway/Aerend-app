import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bergen_perf.dart';

// ── Heat plan Step 11: one clock, no per-frame widget rebuilds ──────────────
//
// Two switches, both off until device-verified:
//
// * [BergenPerf.klokkePaa] (harness `klokke1`): every `LfLoop` /
//   `OnbLoopClock` ticker ([LfTikker]) is driven by one shared frame callback
//   ([LfKlokke]) instead of registering its own transient callback every
//   frame. Same frames, same timestamps, the same elapsed time per ticker —
//   no cadence, every subscriber gets every vsync while it ticks.
// * [BergenPerf.rammeLoopPaa] (harness `rammeLoop`): a loop marked `ramme`
//   ([LfRammeBygger]) applies its builder's output straight to the render
//   objects it already has when the output has the same shape as last frame
//   (a chain of single-child render-object widgets — Transform, Opacity, … —
//   around the same child): exactly the `updateChild` a rebuild would do,
//   without marking, sorting and rebuilding the builder element in the build
//   phase.

/// The shared clock behind [LfTikker] (Heat plan Step 11, `klokkePaa`).
///
/// While at least one subscriber ticks it holds one transient frame callback
/// and asks for a frame per vsync, exactly as a running `Ticker` does; inside
/// that callback it calls its subscribers in the order they subscribed, each
/// with the frame's timestamp. A subscriber that subscribes during the
/// transient-callback phase of a frame is first called on the next frame —
/// where a `Ticker` started there would have ticked first (its callback goes
/// into the next frame's map) — whether or not the clock's own callback had
/// already run in this frame.
class LfKlokke {
  LfKlokke._();

  static final LfKlokke instance = LfKlokke._();

  /// Tests: picks a ticker's mode at `start` / [byttAlle] instead of
  /// [BergenPerf.klokkePaa] (null = the switch), so a test can run a
  /// ticker-driven loop and a clock-driven one side by side.
  @visibleForTesting
  static bool Function(LfTikker t)? debugModus;

  final List<LfTikker> _aktive = [];
  final Set<LfTikker> _alle = <LfTikker>{};
  int? _planlagt;

  // Frames whose persistent phase has run (a persistent callback counts
  // them): during frame N's transient phase this is N - 1 throughout.
  int _ramme = 0;
  SchedulerBinding? _bundet;

  /// Heartbeat: frames this clock ticked, render-object updates without a
  /// rebuild ([LfRammeBygger]), and the rebuilds the `ramme` loops still did.
  int rammer = 0, direkte = 0, bygg = 0;
  bool _puls = false;

  /// Subscribers ticking now.
  int get aktive => _aktive.length;

  /// Tests: every live [LfTikker], in creation order.
  @visibleForTesting
  Iterable<LfTikker> get debugAlle => _alle;

  bool _modus(LfTikker t) => debugModus?.call(t) ?? BergenPerf.klokkePaa;

  /// After [BergenPerf.klokkePaa] changed (the harness): every live ticker
  /// moves to the clock or back to its own frame callback, keeping its
  /// elapsed time — the next tick lands on the same frame with the same
  /// value it would have had without the move.
  void byttAlle() {
    for (final t in _alle.toList()) {
      t._bytt(_modus(t));
    }
  }

  void _tell() {
    final b = SchedulerBinding.instance;
    if (identical(b, _bundet)) return;
    _bundet = b;
    b.addPersistentFrameCallback((_) => _ramme++);
    _pulsInn();
  }

  void _pulsInn() {
    if (kReleaseMode || _puls) return;
    _puls = true;
    BergenPerf.pulsTillegg.add(() {
      final s = 'klokke=$rammer/${_aktive.length} ramme=$direkte/$bygg';
      rammer = direkte = bygg = 0;
      return s;
    });
  }

  void _inn(LfTikker t) {
    _tell();
    final b = SchedulerBinding.instance;
    t._hopp = b.schedulerPhase == SchedulerPhase.transientCallbacks ? _ramme : null;
    _aktive.add(t);
    _planlagt ??= b.scheduleFrameCallback(_tikk);
  }

  void _ut(LfTikker t) {
    _aktive.remove(t);
    final id = _planlagt;
    if (_aktive.isEmpty && id != null) {
      // As a Ticker unschedules its tick: no frame asked for by nobody.
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      _planlagt = null;
    }
  }

  void _tikk(Duration ts) {
    _planlagt = null;
    rammer++;
    final nr = _ramme;
    for (final t in List<LfTikker>.of(_aktive)) {
      // Unsubscribed by an earlier subscriber's tick, or subscribed in this
      // frame's transient phase: not on this frame.
      if (!t._abonnert || t._hopp == nr) continue;
      try {
        t._ramme(ts);
      } catch (e, s) {
        // Each Ticker's callback was isolated by the scheduler; keep it so.
        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'scheduler library', context: ErrorDescription('during an LfKlokke tick')));
      }
    }
    if (_aktive.isNotEmpty && _planlagt == null) {
      _planlagt = SchedulerBinding.instance.scheduleFrameCallback(_tikk, rescheduling: true);
    }
  }
}

/// The ticker of `LfLoop` / `OnbLoopClock` (Heat plan Step 11).
///
/// A real [Ticker]: off the clock (the default) every call goes to
/// [Ticker]'s own code — its own transient callback per frame, its own
/// elapsed time. On the clock ([BergenPerf.klokkePaa] at [start]) only the
/// scheduling hooks change: [scheduleTick] / [unscheduleTick] subscribe to
/// and leave [LfKlokke], and the elapsed time is counted here the way
/// [Ticker] counts it (from the frame it was started in, or from its first
/// tick). `muted`, `stop`, `isActive`, `dispose` and the [TickerFuture] stay
/// [Ticker]'s, so `PerfSov`, `PerfVekker` and the TickerMode muting work on
/// it unchanged.
class LfTikker extends Ticker {
  factory LfTikker(TickerCallback onTick, {String? debugLabel}) {
    late final LfTikker t;
    t = LfTikker._(onTick, (e) => t._fraTicker(e), debugLabel);
    return t;
  }

  LfTikker._(this._kall, TickerCallback fraTicker, String? debugLabel) : super(fraTicker, debugLabel: debugLabel) {
    LfKlokke.instance._alle.add(this);
  }

  final TickerCallback _kall;

  bool _paaKlokka = false;
  bool _abonnert = false;
  int? _hopp;

  // The frame time this run's elapsed time counts from (null until known);
  // [_byttet]: the run moved between the clock and the Ticker, so a Ticker
  // tick reports from [_start] too.
  Duration? _start;
  bool _byttet = false;

  /// True while this run is driven by [LfKlokke].
  bool get paaKlokka => _paaKlokka;

  @override
  TickerFuture start() {
    _paaKlokka = LfKlokke.instance._modus(this);
    _start = null;
    _byttet = false;
    final f = super.start();
    // Started inside a frame: its elapsed time counts from this frame, as
    // [Ticker.start] does.
    final b = SchedulerBinding.instance;
    if (b.schedulerPhase.index > SchedulerPhase.idle.index && b.schedulerPhase.index < SchedulerPhase.postFrameCallbacks.index) {
      _start = b.currentFrameTimeStamp;
    }
    return f;
  }

  @override
  void stop({bool canceled = false}) {
    super.stop(canceled: canceled);
    _start = null;
    _byttet = false;
  }

  @override
  bool get scheduled => _paaKlokka ? _abonnert : super.scheduled;

  @override
  void scheduleTick({bool rescheduling = false}) {
    if (!_paaKlokka) {
      super.scheduleTick(rescheduling: rescheduling);
      return;
    }
    assert(!scheduled);
    assert(shouldScheduleTick);
    _abonnert = true;
    LfKlokke.instance._inn(this);
  }

  @override
  void unscheduleTick() {
    if (!_paaKlokka) {
      super.unscheduleTick();
      return;
    }
    if (_abonnert) {
      _abonnert = false;
      LfKlokke.instance._ut(this);
    }
    assert(!shouldScheduleTick);
  }

  @override
  void dispose() {
    LfKlokke.instance._alle.remove(this);
    super.dispose();
    if (_abonnert) {
      _abonnert = false;
      LfKlokke.instance._ut(this);
    }
  }

  // [Ticker]'s own tick: [e] is its elapsed time.
  void _fraTicker(Duration e) {
    final ts = SchedulerBinding.instance.currentFrameTimeStamp;
    _start ??= ts - e;
    _kall(_byttet ? ts - _start! : e);
  }

  // The clock's tick.
  void _ramme(Duration ts) {
    _start ??= ts;
    _kall(ts - _start!);
  }

  void _bytt(bool klokke) {
    if (klokke == _paaKlokka) return;
    if (!isActive || muted) {
      // Nothing scheduled either way; the next schedule uses the new mode.
      _paaKlokka = klokke;
      if (isActive) _byttet = true;
      return;
    }
    // Through `muted` so Ticker's own assertions hold: unschedule in the old
    // mode, schedule in the new one.
    muted = true;
    _paaKlokka = klokke;
    _byttet = true;
    muted = false;
  }
}

/// [SingleTickerProviderStateMixin], for an [LfTikker]: the same TickerMode
/// muting (it follows [TickerMode.getNotifier] from `createTicker` and again
/// on `activate`).
mixin LfTikkerVert<T extends StatefulWidget> on State<T> implements TickerProvider {
  LfTikker? _tikker;
  ValueListenable<bool>? _modus;

  /// Tests: the ticker this state created.
  @visibleForTesting
  LfTikker? get debugTikker => _tikker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(_tikker == null, '$runtimeType is an LfTikkerVert but multiple tickers were created.');
    _tikker = LfTikker(onTick, debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null);
    _folgModus();
    _oppdater();
    return _tikker!;
  }

  @override
  void dispose() {
    assert(_tikker == null || !_tikker!.isActive, '$this was disposed with an active Ticker.');
    _modus?.removeListener(_oppdater);
    _modus = null;
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    // We may have a new TickerMode ancestor.
    _folgModus();
    _oppdater();
  }

  void _oppdater() => _tikker?.muted = !_modus!.value;

  void _folgModus() {
    final n = TickerMode.getNotifier(context);
    if (n == _modus) return;
    _modus?.removeListener(_oppdater);
    n.addListener(_oppdater);
    _modus = n;
  }
}

/// The builder host of a loop marked `ramme` (Heat plan Step 11,
/// `rammeLoopPaa`): a [ValueListenableBuilder] for the loop's time [verdi]
/// that, on a tick, first tries to apply [builder]'s new output to the
/// elements it already has.
///
/// That works when the new output and the current one have the same shape:
/// a chain of [SingleChildRenderObjectWidget]s of the same types, no keys,
/// that reaches the very same widget object (normally the loop's `child`) or
/// ends in no child at the same depth. Then `updateChild` runs here, in the
/// tick, instead of in the build phase: each level's
/// `RenderObjectWidget.updateRenderObject` — the same render objects, the
/// same properties, the same layers as the rebuild would leave — and the
/// unchanged child is skipped exactly as a rebuild skips it. Any other
/// output (a different type, a `SizedBox.shrink()` before a delay, a new
/// leaf widget) is built the normal way in the build phase that frame. With
/// the switch off it is a plain [ValueListenableBuilder].
///
/// Only for builders that depend on nothing but t and values fixed when the
/// loop widget was built (a rebuild of the loop widget rebuilds this as
/// usual).
class LfRammeBygger extends StatelessWidget {
  const LfRammeBygger({super.key, required this.verdi, required this.builder, this.child});

  final ValueListenable<double> verdi;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  StatelessElement createElement() => _LfRammeElement(this);

  @override
  Widget build(BuildContext context) => builder(context, verdi.value, child);
}

class _LfRammeElement extends StatelessElement {
  _LfRammeElement(LfRammeBygger super.widget);

  ValueListenable<double>? _lytter;
  bool _aktiv = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    _aktiv = true;
    super.mount(parent, newSlot);
    _folg();
  }

  @override
  void update(LfRammeBygger newWidget) {
    super.update(newWidget);
    _folg();
  }

  @override
  void activate() {
    super.activate();
    _aktiv = true;
  }

  @override
  void deactivate() {
    _aktiv = false;
    super.deactivate();
  }

  @override
  void unmount() {
    _lytter?.removeListener(_endret);
    _lytter = null;
    super.unmount();
  }

  void _folg() {
    final v = (widget as LfRammeBygger).verdi;
    if (identical(v, _lytter)) return;
    _lytter?.removeListener(_endret);
    _lytter = v..addListener(_endret);
  }

  void _endret() {
    if (dirty) return;
    if (BergenPerf.rammeLoopPaa) {
      final k = LfKlokke.instance.._pulsInn();
      if (_aktiv && SchedulerBinding.instance.schedulerPhase == SchedulerPhase.transientCallbacks && _direkte()) {
        k.direkte++;
        return;
      }
      k.bygg++;
    }
    markNeedsBuild();
  }

  bool _direkte() {
    Element? barn;
    visitChildren((e) => barn = e);
    final b = barn;
    if (b == null) return false;
    final w = widget as LfRammeBygger;
    final Widget ny;
    try {
      ny = w.builder(this, w.verdi.value, w.child);
    } catch (_) {
      // Built the normal way, so the error shows as it does today.
      return false;
    }
    if (!_sammeForm(b, ny)) return false;
    final e = updateChild(b, ny, slot);
    assert(identical(e, b));
    return true;
  }

  /// True when updating [el] to [ny] only updates render objects in place
  /// down to an identical widget (or to no child): no element is inflated
  /// or dropped.
  static bool _sammeForm(Element el, Widget ny) {
    var a = el.widget;
    var b = ny;
    Element? e = el;
    for (var i = 0; i < 8; i++) {
      if (identical(a, b)) return true;
      if (a is! SingleChildRenderObjectWidget || b is! SingleChildRenderObjectWidget) return false;
      if (a.runtimeType != b.runtimeType || a.key != null || b.key != null) return false;
      if (e is! SingleChildRenderObjectElement) return false;
      final ab = a.child, bb = b.child;
      if (ab == null || bb == null) return ab == null && bb == null;
      Element? neste;
      e.visitChildren((c) => neste = c);
      if (neste == null || !identical(neste!.widget, ab)) return false;
      e = neste;
      a = ab;
      b = bb;
    }
    return false;
  }
}
