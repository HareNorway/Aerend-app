import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../sim/engine.dart';

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.2, §12.3, §12.4): the fixed-step loop between the Ticker and the core.
///
/// The Ticker adds the time since the last frame to an accumulator; the core advances in whole ticks, at most
/// [maxTicksPerFrame] in one frame (anything beyond is dropped, so a stall never fast-forwards the run); the painter
/// draws between the last two ticks ([alpha]). An input is stamped with the next tick the core runs and recorded as
/// `[tick, dir]` — rendering never feeds back into the simulation, so the frame rate cannot change a run (T31).
///
/// It is the painter's [Listenable]: it notifies once per frame that advanced or moved, and the HUD reads separate
/// [ValueNotifier]s that change only when the value shown changes. Nothing is allocated per frame in steady state.
class FjordLoop extends ChangeNotifier {
  FjordLoop(this.sim, {this.ghost, this.ghostTicks = 0, List<FjordInput> ghostInputs = const []})
      : _ghostInputs = ghostInputs,
        uPrev = 0,
        uNow = 0;

  static const int ticksPerSecond = 60;
  static const int maxTicksPerFrame = 5;

  final FjordSim sim;

  /// The customer's best run this week, replayed tick for tick (spec §5.5); stops at [ghostTicks].
  final FjordSim? ghost;
  final int ghostTicks;
  final List<FjordInput> _ghostInputs;
  int _ghostAt = 0;

  /// The boat's distance (1/60 mm) at the previous and the current tick, for interpolation.
  int uPrev, uNow;
  int ghostUPrev = 0, ghostUNow = 0;

  /// 0–1 between the previous and the current tick.
  double alpha = 0;

  double _acc = 0;
  Duration? _last;

  /// Inputs waiting for the next tick (at most a few per frame).
  final List<int> _pending = [];
  final List<int> _dirs = [];

  /// The run's inputs, flat: tick, dir, tick, dir …
  final List<int> recorded = [];

  /// Feedback events (FjordSim.ev* bits) since the screen last took them.
  int events = 0;

  /// Haptics plan Step 1 (spec §6 «on the same tick, only the higher plays»): called once for every tick that had
  /// events, with that tick and its bits — a frame may run several ticks, and the haptics decide per tick.
  void Function(int tick, int events)? onTickEvents;

  // HUD values, each changes only when the number shown changes.
  final ValueNotifier<int> metres = ValueNotifier<int>(0);
  final ValueNotifier<int> meter = ValueNotifier<int>(0);
  final ValueNotifier<bool> vest = ValueNotifier<bool>(false);
  final ValueNotifier<int> nearMisses = ValueNotifier<int>(0);

  bool get done => sim.done;

  /// A lane input (−1 left, +1 right), stamped with the next tick the core runs.
  void input(int dir) {
    if (sim.done) return;
    _pending.add(dir < 0 ? -1 : 1);
  }

  /// Starts timing from now: the next frame's time counts from here (after a pause or a countdown).
  void resetClock() {
    _last = null;
    _acc = 0;
  }

  /// One frame at [elapsed] (the Ticker's time). Returns the number of ticks run.
  int frame(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null || sim.done) return 0;
    _acc += (elapsed - last).inMicroseconds / 1e6;
    var n = (_acc * ticksPerSecond).floor();
    if (n > maxTicksPerFrame) {
      n = maxTicksPerFrame;
      _acc = 0; // dropped: a stall never fast-forwards
    } else {
      _acc -= n / ticksPerSecond;
    }
    for (var i = 0; i < n && !sim.done; i++) {
      _step();
    }
    alpha = sim.done ? 1 : (_acc * ticksPerSecond).clamp(0.0, 1.0);
    _publish();
    notifyListeners();
    return n;
  }

  /// Runs exactly one tick (tests, and the frame loop).
  void step() {
    _step();
    _publish();
  }

  void _step() {
    _dirs.clear();
    for (var i = 0; i < _pending.length; i++) {
      _dirs.add(_pending[i]);
      recorded
        ..add(sim.tick)
        ..add(_pending[i]);
    }
    _pending.clear();
    uPrev = sim.u;
    final t = sim.tick;
    sim.stepTick(_dirs);
    uNow = sim.u;
    events |= sim.events;
    if (sim.events != 0) onTickEvents?.call(t, sim.events);
    final g = ghost;
    if (g != null && !g.done && g.tick < ghostTicks) {
      _dirs.clear();
      while (_ghostAt < _ghostInputs.length && _ghostInputs[_ghostAt].tick < g.tick) {
        _ghostAt++;
      }
      while (_ghostAt < _ghostInputs.length && _ghostInputs[_ghostAt].tick == g.tick) {
        _dirs.add(_ghostInputs[_ghostAt].dir);
        _ghostAt++;
      }
      ghostUPrev = g.u;
      g.stepTick(_dirs);
      ghostUNow = g.u;
    } else if (g != null) {
      ghostUPrev = ghostUNow; // stopped at its flag: it stays where its best run ended
    }
  }

  void _publish() {
    if (metres.value != sim.sailedM) metres.value = sim.sailedM;
    if (meter.value != sim.meter) meter.value = sim.meter;
    if (vest.value != sim.hasVest) vest.value = sim.hasVest;
    if (nearMisses.value != sim.nearMisses) nearMisses.value = sim.nearMisses;
  }

  /// Takes the feedback events since the last call.
  int takeEvents() {
    final e = events;
    events = 0;
    return e;
  }

  /// The boat's distance (mm) between the last two ticks.
  double boatMm() => (uPrev + (uNow - uPrev) * alpha) / 60.0;

  /// The boat's lane position between the last two ticks.
  double lanePos() => sim.lanePosAt(sim.tick - 1) + (sim.lanePosAt(sim.tick) - sim.lanePosAt(sim.tick - 1)) * alpha;

  /// The ghost's distance (mm), or −1 when there is none. It stops at its flag (the end of the best run).
  double ghostMm() {
    if (ghost == null) return -1;
    return (ghostUPrev + (ghostUNow - ghostUPrev) * alpha) / 60.0;
  }

  double ghostLanePos() {
    final g = ghost;
    if (g == null) return 1;
    return g.lanePosAt(g.tick);
  }

  /// The recorded inputs as the server takes them.
  List<List<int>> inputsJson() => [for (var i = 0; i + 1 < recorded.length; i += 2) [recorded[i], recorded[i + 1]]];

  @override
  void dispose() {
    metres.dispose();
    meter.dispose();
    vest.dispose();
    nearMisses.dispose();
    super.dispose();
  }
}

/// Fjordløpet v1.3 plan Step 5 (spec v1.3 §12.4): frame times during a run, from
/// `SchedulerBinding.addTimingsCallback` — build and raster time per frame. Kept in fixed buffers (two minutes at 60
/// frames per second; older frames roll off), summarised for the run's `perf` and the developer overlay.
class FramePerf {
  FramePerf({this.capacity = 7200});

  final int capacity;
  late final Float64List _total = Float64List(capacity);
  late final Float64List _build = Float64List(capacity);
  late final Float64List _raster = Float64List(capacity);
  int _n = 0;
  int _at = 0;
  int slowFrames = 0;
  int over20 = 0;
  double worstMs = 0;
  Duration? _start;
  bool _listening = false;

  /// Frames over 33 ms count as slow only after the first two seconds of a run.
  static const Duration warmUp = Duration(seconds: 2);

  void start() {
    reset();
    if (!_listening) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _listening = true;
    }
  }

  /// Collects again after a pause, keeping what the run has so far.
  void resume() {
    if (!_listening) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _listening = true;
    }
  }

  void stop() {
    if (_listening) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _listening = false;
    }
  }

  void reset() {
    _n = 0;
    _at = 0;
    slowFrames = 0;
    over20 = 0;
    worstMs = 0;
    _start = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      add(t.totalSpan.inMicroseconds / 1000.0, t.buildDuration.inMicroseconds / 1000.0, t.rasterDuration.inMicroseconds / 1000.0,
          Duration(microseconds: t.timestampInMicroseconds(FramePhase.vsyncStart)));
    }
  }

  /// One frame's times in ms, at [when] (tests call this directly).
  void add(double totalMs, double buildMs, double rasterMs, Duration when) {
    _start ??= when;
    _total[_at] = totalMs;
    _build[_at] = buildMs;
    _raster[_at] = rasterMs;
    _at = (_at + 1) % capacity;
    if (_n < capacity) _n++;
    if (totalMs > worstMs) worstMs = totalMs;
    if (totalMs > 20) over20++;
    if (totalMs > 33 && when - _start! >= warmUp) slowFrames++;
  }

  int get frames => _n;

  double _avg(Float64List l) {
    if (_n == 0) return 0;
    var s = 0.0;
    for (var i = 0; i < _n; i++) {
      s += l[i];
    }
    return s / _n;
  }

  double get avgMs => _avg(_total);
  double get avgBuildMs => _avg(_build);
  double get avgRasterMs => _avg(_raster);

  /// The 99th percentile of frame time over the frames kept.
  double get p99Ms {
    if (_n == 0) return 0;
    final copy = Float64List.fromList(_total.sublist(0, _n))..sort();
    return copy[((_n - 1) * 99) ~/ 100];
  }

  /// Average over the last [frames] frames (the quality rule's «2 s»).
  double recentAvgMs(int frames) {
    if (_n == 0) return 0;
    final k = frames < _n ? frames : _n;
    var s = 0.0;
    for (var i = 1; i <= k; i++) {
      s += _total[(_at - i + capacity) % capacity];
    }
    return s / k;
  }

  /// For the run's submission (spec §10.2 `perf`).
  Map<String, Object> toJson(String quality) => {
        'quality': quality,
        'avg_ms': double.parse(avgMs.toStringAsFixed(2)),
        'p99_ms': double.parse(p99Ms.toStringAsFixed(2)),
        'slow_frames': slowFrames,
      };
}
