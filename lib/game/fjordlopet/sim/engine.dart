/// Fjordløpet's simulation core, engine version 2 (game spec v1.3 §4.1, §4.4, §9; Fjordløpet v1.3 plan Step 1).
///
/// A pure function of (course, engine version, perk, inputs): 60 ticks per second, integer arithmetic only, no clock,
/// no random numbers. The same core runs on the server (`App\Game\Sim\Engine` in Hare-AdminPanel); the golden runs
/// must give identical results in both (`test/game/golden_runs_test.dart`), and [FjordEngine.version] changes whenever
/// the core changes. The app never generates a course: it plays the one the server sends, with that course's
/// parameters.
///
/// Units: the boat's distance `u` is in 1/60 mm, so a tick adds the speed in mm/s exactly. Course distances are mm.
/// Lanes 0, 1, 2; the boat starts in lane 1. Lane centres across the fjord are 500, 1500, 2500 width units (the
/// beffen's axis). The course: `params`, `rows` [{d, t, l, p}], `crates` [{d, l}], `landmarks` [{d, k, s}], each sorted
/// by d and repeated every `length_m`.
///
/// Lane change: `lane_change_ticks` (7); the boat counts in the old lane for the first `lane_change_ticks ~/ 2` ticks
/// and in the new lane from the next. An input during a change is held (one; a newer replaces it) and carried out on
/// the first tick a new change may start. An input against a pending kjølvann counters it at once.
///
/// The redningsvest: a meter 0–`vest_crates`; a crate or a near miss adds one; full = a vest. A hit with a vest empties
/// the meter and gives `vest_grace_ticks` without hits; a hit without one ends the run. Perk `full_meter` starts full.
///
/// Near miss, once per obstacle when the boat reaches it unhurt: (a) it left that obstacle's lane fewer than
/// `near_miss_ticks` ticks earlier, or (b) a beffen was in the boat's lane during the last `near_miss_ticks` ticks.
///
/// Per tick t: (1) a held input, if a change may start; (2) the inputs at t; (3) an uncountered wake pushes (lost
/// during a change); (4) advance; (5) kajakks put out; (6) crates passed; (7) rows passed; (8) kajakks caught.
/// The score is distance sailed in metres, and nothing else.
library;

/// One input: at [tick], one lane in [dir] (−1 left, +1 right).
class FjordInput {
  const FjordInput(this.tick, this.dir);

  final int tick;
  final int dir;

  List<int> toJson() => [tick, dir];
}

/// What a run came to. Compared field by field with the server's replay.
class FjordResult {
  const FjordResult({
    required this.distanceM,
    required this.sailedMm,
    required this.crates,
    required this.nearMisses,
    required this.vestUses,
    required this.ticks,
    required this.ended,
    required this.gates,
    required this.hitRow,
    required this.endCause,
  });

  /// Metres sailed — the score.
  final int distanceM;
  final int sailedMm;
  final int crates;
  final int nearMisses;
  final int vestUses;
  final int ticks;

  /// `collision` or `limit`.
  final String ended;

  /// The milestones (metres sailed) passed: Bøye 1, Bøye 2, Bryggen.
  final List<int> gates;
  final int? hitRow;

  /// What ended the run: `{obstacle, row, landmark}` (landmark may be null); null when nothing did.
  final Map<String, dynamic>? endCause;

  Map<String, dynamic> toJson() => {
        'distance_m': distanceM,
        'sailed_mm': sailedMm,
        'crates': crates,
        'near_misses': nearMisses,
        'vest_uses': vestUses,
        'ticks': ticks,
        'ended': ended,
        'gates': gates,
        'hit_row': hitRow,
        'end_cause': endCause,
      };
}

/// A kajakk on the water: put out at `u0` (1/60 mm) at tick `st`, moving `v` mm/s along `lane`.
class FjordKajakk {
  FjordKajakk(this.n, this.lane, this.v, this.u0, this.st, this.d);

  final int n;
  final int lane;
  final int v;
  final int u0;
  final int st;
  final int d;

  /// Where it is at tick [t], in 1/60 mm.
  int uAt(int t) => u0 + v * (t - st);
}

/// The simulation stepped one tick at a time — what the play screen drives and draws, and what [FjordEngine.run]
/// replays. Its state is public for drawing only; nothing outside may change it.
class FjordSim {
  FjordSim(Map<String, dynamic> course, this.perk)
      : params = (course['params'] as Map).cast<String, dynamic>(),
        rows = (course['rows'] as List).cast<Map>(),
        crateList = ((course['crates'] as List?) ?? const []).cast<Map>(),
        landmarks = ((course['landmarks'] as List?) ?? const []).cast<Map>() {
    final p = params;
    nRows = rows.length;
    nCrates = crateList.length;
    lengthMm = FjordEngine._i(p['length_m']) * 1000;
    start = FjordEngine._i(p['speed_start_mms']);
    step = FjordEngine._i(p['speed_step_mms']);
    max = FjordEngine._i(p['speed_max_mms']);
    final l = FjordEngine._i(p['lane_change_ticks']);
    lc = l < 1 ? 1 : l;
    mid = lc ~/ 2;
    wakeFrom = FjordEngine._i(p['wake_from_m']) * 1000;
    wakeTicks = FjordEngine._i(p['wake_counter_ticks']);
    grace = FjordEngine._i(p['vest_grace_ticks']);
    kAhead = FjordEngine._i(p['kajakk_ahead_mm']);
    final f = FjordEngine._i(p['vest_crates']);
    full = f < 1 ? 1 : f;
    nmTicks = FjordEngine._i(p['near_miss_ticks']);
    markNear = FjordEngine._i(p['landmark_near_mm'] ?? 0);
    meter = perk == 'full_meter' ? full : 0;
  }

  final Map<String, dynamic> params;
  final List<Map> rows;
  final List<Map> crateList;
  final List<Map> landmarks;
  final String perk;
  late final int nRows, nCrates, lengthMm, start, step, max, lc, mid, wakeFrom, wakeTicks, grace, kAhead, full, nmTicks,
      markNear;

  /// Events of the last tick, for feedback (haptics, sounds, flashes): a bitmask of the `ev*` constants.
  static const int evCrate = 1, evNearMiss = 2, evMeterFull = 4, evVest = 8, evHit = 16;

  /// The next tick to simulate.
  int tick = 0;

  /// The boat's distance, 1/60 mm.
  int u = 0;
  final List<int> hist = [];
  int chFrom = 1, chTo = 1, chStart = -1000000;

  /// A held input (−1, +1) or 0.
  int held = 0;

  /// Lane switches still inside the near-miss window: [tick the boat counts in the new lane, lane it left, …].
  final List<int> _switches = [];
  int crates = 0;
  int nearMisses = 0;
  int vestUses = 0;

  /// The redningsvest meter, 0–[full]; full means the boat has a vest.
  late int meter;
  int graceUntil = -1;
  int nextRow = 0, nextCrate = 0, kNext = 0;
  List<FjordKajakk> kajakks = [];

  /// The last crates picked up (absolute indices), for drawing: a small ring.
  final List<int> taken = List<int>.filled(16, -1);
  int _takenAt = 0;

  /// A pending wake: [direction, the tick it pushes].
  List<int>? wake;
  String? ended;
  int endTick = 0;
  int? hitRow;
  Map<String, dynamic>? endCause;

  /// The tick the redningsvest last took a hit (drawing: «Redningsvesten tok støyten»).
  int? vestHitTick;

  /// Events of the last tick (`ev*` bits).
  int events = 0;

  bool get done => ended != null || tick >= FjordEngine.maxTicks;

  int get sailedM => u ~/ 60000;

  bool get hasVest => meter >= full;

  (Map, int) rowAt(int n) {
    final r = rows[n % nRows];
    return (r, FjordEngine._i(r['d']) + (n ~/ nRows) * lengthMm);
  }

  /// Row [n] and its distance without a record — for drawing, which allocates nothing per frame.
  Map rowMapAt(int n) => rows[n % nRows];
  int rowDAt(int n) => FjordEngine._i(rows[n % nRows]['d']) + (n ~/ nRows) * lengthMm;

  /// Crate [n]'s lane and distance (mm) without a record; [crateDAt] is −1 when the course has no crates.
  int crateLaneAt(int n) => nCrates == 0 ? 1 : FjordEngine._i(crateList[n % nCrates]['l']);
  int crateDAt(int n) => nCrates == 0 ? -1 : FjordEngine._i(crateList[n % nCrates]['d']) + (n ~/ nCrates) * lengthMm;

  /// The beffen of row [r] at distance [d]: its position across the fjord now (width units) — drawing only, and
  /// without a closure (so nothing is allocated per frame).
  int beffenXNow(Map r, int d) {
    final p = r['p'] as Map;
    final a = FjordEngine._i(p['a']);
    if (u < (d - a) * 60) return FjordEngine._i(p['x0']);
    final dt = tick - firstAt((d - a) * 60);
    return FjordEngine._i(p['x0']) + FjordEngine._i(p['vx']) * (dt < 0 ? 0 : dt);
  }

  /// The boat's lane position at tick [t] as a fraction (1.0 = the middle lane), for drawing a change in progress.
  double lanePosAt(int t) {
    final f = (t - chStart) / lc;
    if (f <= 0) return chFrom.toDouble();
    if (f >= 1) return chTo.toDouble();
    return chFrom + (chTo - chFrom) * f;
  }

  /// Crate [n] (absolute index over laps) and its distance in mm; null when the course has none.
  (Map, int)? crateAt(int n) {
    if (nCrates == 0) return null;
    final c = crateList[n % nCrates];
    return (c, FjordEngine._i(c['d']) + (n ~/ nCrates) * lengthMm);
  }

  bool crateTaken(int n) => taken.contains(n);

  int effLane(int t) => (t - chStart) < mid ? chFrom : chTo;

  bool _changing(int t) => t < chStart + lc;

  int speedAt(int t) {
    final s = start + (step * t) ~/ 60;
    return s < max ? s : max;
  }

  /// The first tick the boat's distance reached [target] (1/60 mm), from the history so far.
  int firstAt(int target) {
    var lo = 0;
    var hi = hist.length - 1;
    if (target <= 0 || hi < 0) return 0;
    while (lo < hi) {
      final m = (lo + hi) ~/ 2;
      if (hist[m] >= target) {
        hi = m;
      } else {
        lo = m + 1;
      }
    }
    return lo;
  }

  void _change(int t, int dir) {
    final to = chTo + dir;
    if (to < 0 || to > 2) return;
    chFrom = chTo;
    chTo = to;
    chStart = t;
    _switches
      ..add(t + mid)
      ..add(chFrom);
  }

  void _fill() {
    if (meter < full) {
      meter++;
      if (meter == full) events |= evMeterFull;
    }
  }

  bool _leftRecently(int t, List<int> lanes) {
    for (var i = 0; i < _switches.length; i += 2) {
      final sw = _switches[i];
      if (sw <= t && t - sw < nmTicks && lanes.contains(_switches[i + 1])) return true;
    }
    return false;
  }

  bool _leftLaneRecently(int t, int lane) {
    for (var i = 0; i < _switches.length; i += 2) {
      final sw = _switches[i];
      if (sw <= t && t - sw < nmTicks && _switches[i + 1] == lane) return true;
    }
    return false;
  }

  String? _markFor(int d) {
    if (landmarks.isEmpty) return null;
    final lap = d ~/ lengthMm;
    int? bestD;
    String? bestK;
    for (var l = lap; l >= (lap - 1 < 0 ? 0 : lap - 1) && bestD == null; l--) {
      for (var i = landmarks.length - 1; i >= 0; i--) {
        final md = FjordEngine._i(landmarks[i]['d']) + l * lengthMm;
        if (md <= d) {
          bestD = md;
          bestK = '${landmarks[i]['k']}';
          break;
        }
      }
    }
    if (bestD == null || (markNear > 0 && d - bestD > markNear)) return null;
    return bestK;
  }

  void _hit(int t, int n, String type, int d) {
    if (t < graceUntil) return;
    if (meter >= full) {
      meter = 0;
      vestUses++;
      vestHitTick = t;
      graceUntil = t + grace;
      events |= evVest;
      return;
    }
    ended = 'collision';
    endTick = t;
    hitRow = n;
    endCause = {'obstacle': type, 'row': n, 'landmark': _markFor(d)};
    events |= evHit;
  }

  /// One tick, with the lane inputs given at it (−1 left, +1 right), in order.
  void stepTick(List<int> dirs) {
    if (done) return;
    final t = tick;
    events = 0;
    // (1) a held input, once a new change may start
    if (held != 0 && !_changing(t)) {
      _change(t, held);
      held = 0;
    }
    // (2) inputs
    for (final d0 in dirs) {
      final dir = d0 < 0 ? -1 : 1;
      final w = wake;
      if (w != null && dir == -w[0]) {
        wake = null;
        continue;
      }
      if (_changing(t)) {
        held = dir;
      } else {
        _change(t, dir);
      }
    }
    // (3) the wake pushes if nobody steered against it
    final w = wake;
    if (w != null && t >= w[1]) {
      if (!_changing(t)) _change(t, w[0]);
      wake = null;
    }
    while (_switches.isNotEmpty && t - _switches[0] >= nmTicks) {
      _switches.removeRange(0, 2);
    }
    // (4) advance
    u += speedAt(t);
    hist.add(u);
    final lane = effLane(t);
    // (5) kajakks put out
    while (true) {
      final (r, d) = rowAt(kNext);
      if (u < (d - kAhead) * 60) break;
      if (r['t'] == 'kajakk') {
        final kp = (r['p'] as Map);
        kajakks.add(FjordKajakk(kNext, FjordEngine._i(kp['lane']), FjordEngine._i(kp['v']), d * 60, t, d));
      }
      kNext++;
    }
    // (6) crates passed
    while (nCrates > 0) {
      final (c, cd) = crateAt(nextCrate)!;
      if (u < cd * 60) break;
      final n = nextCrate;
      nextCrate++;
      if (FjordEngine._i(c['l']) == lane) {
        crates++;
        taken[_takenAt] = n;
        _takenAt = (_takenAt + 1) % taken.length;
        events |= evCrate;
        _fill();
      }
    }
    // (7) rows passed
    while (ended == null) {
      final (r, d) = rowAt(nextRow);
      if (u < d * 60) break;
      final n = nextRow;
      nextRow++;
      final b = FjordEngine.blocked(r, d, t, firstAt);
      if (r['t'] == 'wake' && d >= wakeFrom) {
        wake = [FjordEngine._i((r['p'] as Map)['w']) < 0 ? -1 : 1, t + wakeTicks];
      }
      if (b.contains(lane)) {
        _hit(t, n, '${r['t']}', d);
      } else if (t >= graceUntil &&
          ((b.isNotEmpty && _leftRecently(t, b)) ||
              (r['t'] == 'beffen' && FjordEngine._beffenWasIn(r, d, t, lane, nmTicks, firstAt)))) {
        nearMisses++;
        events |= evNearMiss;
        _fill();
      }
    }
    // (8) kajakks caught (compacted in place: nothing allocated per tick)
    if (ended == null && kajakks.isNotEmpty) {
      var w = 0;
      for (var i = 0; i < kajakks.length; i++) {
        final k = kajakks[i];
        if (ended != null || u < k.uAt(t)) {
          kajakks[w++] = k;
          continue;
        }
        if (lane == k.lane) {
          _hit(t, k.n, 'kajakk', k.d);
        } else if (t >= graceUntil && _leftLaneRecently(t, k.lane)) {
          nearMisses++;
          events |= evNearMiss;
          _fill();
        }
      }
      kajakks.length = w;
    }
    tick++;
  }

  FjordResult result() {
    final ticks = ended == 'collision' ? endTick + 1 : hist.length;
    return FjordResult(
      distanceM: sailedM,
      sailedMm: u ~/ 60,
      crates: crates,
      nearMisses: nearMisses,
      vestUses: vestUses,
      ticks: ticks,
      ended: ended ?? 'limit',
      gates: [
        for (final m in (params['milestones_m'] as List))
          if (sailedM >= FjordEngine._i(m)) FjordEngine._i(m),
      ],
      hitRow: hitRow,
      endCause: endCause,
    );
  }
}

abstract final class FjordEngine {
  static const int version = 2;

  /// 15 minutes.
  static const int maxTicks = 54000;

  static const List<int> _centres = [500, 1500, 2500];

  static int _i(Object? v) => v is int ? v : (v is num ? v.toInt() : int.parse('$v'));

  /// Plays [course] (as the server sends it) with [perk] (`none` | `full_meter`) and [inputs] (ascending), for at most
  /// [stopAt] ticks.
  static FjordResult run(Map<String, dynamic> course, String perk, List<FjordInput> inputs, {int? stopAt}) {
    final sim = FjordSim(course, perk);
    final limit = stopAt == null ? maxTicks : (stopAt < 0 ? 0 : (stopAt > maxTicks ? maxTicks : stopAt));
    var ii = 0;
    final n = inputs.length;
    final dirs = <int>[];
    while (!sim.done && sim.tick < limit) {
      final t = sim.tick;
      while (ii < n && inputs[ii].tick < t) {
        ii++;
      }
      dirs.clear();
      while (ii < n && inputs[ii].tick == t) {
        dirs.add(inputs[ii].dir);
        ii++;
      }
      sim.stepTick(dirs);
    }
    return sim.result();
  }

  /// The beffen's position across the fjord (width units, lanes centred at 500/1500/2500) at tick [t] — before it is
  /// put out, where it starts. Drawing uses it with the boat's distance [u].
  static int beffenX(Map r, int d, int t, int Function(int target) firstAt, int u) {
    final p = (r['p'] as Map?) ?? const {};
    if (u < (d - _i(p['a'])) * 60) return _i(p['x0']);
    return _beffenXAt(r, d, t, firstAt);
  }

  static int _beffenXAt(Map r, int d, int t, int Function(int target) firstAt) {
    final p = (r['p'] as Map?) ?? const {};
    final st = firstAt((d - _i(p['a'])) * 60);
    final dt = t - st;
    return _i(p['x0']) + _i(p['vx']) * (dt < 0 ? 0 : dt);
  }

  static List<int> _beffenLanes(Map r, int x) {
    final h = _i(((r['p'] as Map?) ?? const {})['h']);
    return [
      for (var lane = 0; lane < 3; lane++)
        if ((_centres[lane] - x).abs() <= h) lane,
    ];
  }

  static bool _beffenWasIn(Map r, int d, int t, int lane, int nm, int Function(int target) firstAt) {
    for (var k = 1; k < nm; k++) {
      if (t - k < 0) break;
      if (_beffenLanes(r, _beffenXAt(r, d, t - k, firstAt)).contains(lane)) return true;
    }
    return false;
  }

  /// The lanes a row blocks when the boat passes it at tick [t] (beffen by where it is then, the gull once it has
  /// dived).
  static List<int> blocked(Map r, int d, int t, int Function(int target) firstAt) {
    final p = (r['p'] as Map?) ?? const {};
    switch (r['t']) {
      case 'boye':
      case 'stokk':
      case 'garn':
        return [for (final l in (r['l'] as List)) _i(l)];
      case 'beffen':
        return _beffenLanes(r, _beffenXAt(r, d, t, firstAt));
      case 'make':
        final st = firstAt((d - _i(p['a'])) * 60);
        return t >= st + _i(p['delay']) ? [_i(p['lane'])] : const [];
      default:
        return const [];
    }
  }
}
