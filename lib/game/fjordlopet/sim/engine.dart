/// Fjordløpet's simulation core (game spec §4.1–4.2, §9; points plan Step 5).
///
/// A pure function of (course, engine version, perk, inputs): 60 ticks per second, integer arithmetic only, no clock,
/// no random numbers. The same core runs on the server (`App\Game\Sim\Engine` in Hare-AdminPanel); 200 golden runs
/// must give identical results in both (`test/game/golden_runs_test.dart`), and [FjordEngine.version] changes whenever
/// the core changes. The app never generates a course: it plays the one the server sends, with that course's
/// parameters.
///
/// Units: the boat's distance `u` is in 1/60 mm, so a tick adds the speed in mm/s exactly. Lanes 0, 1, 2; the boat
/// starts in lane 1. Lane centres across the fjord are 500, 1500, 2500 width units (the beffen's axis).
///
/// Per tick t: (1) the inputs at t — against a pending wake an input in the opposite direction counters it, otherwise
/// it starts a lane change when none is in progress; (2) a pending wake that was not countered pushes; (3) the boat
/// advances by speed(t); (4) kajakks within `kajakk_ahead_mm` are put out; (5) every row the boat has now passed is
/// checked in the boat's effective lane (a change counts from its midpoint); (6) a kajakk the boat has caught is
/// checked. A hit ends the run unless a redningsvest absorbs it (then `vest_grace_ticks` of no hits).
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
    required this.ticks,
    required this.vestUsed,
    required this.ended,
    required this.gates,
    required this.hitRow,
  });

  /// Metres sailed plus `crate_m` per crate — the score.
  final int distanceM;
  final int sailedMm;
  final int crates;
  final int ticks;
  final bool vestUsed;

  /// `collision` or `limit`.
  final String ended;

  /// The milestones (metres sailed) passed: Bøye 1, Bøye 2, Bryggen.
  final List<int> gates;
  final int? hitRow;

  Map<String, dynamic> toJson() => {
        'distance_m': distanceM,
        'sailed_mm': sailedMm,
        'crates': crates,
        'ticks': ticks,
        'vest_used': vestUsed,
        'ended': ended,
        'gates': gates,
        'hit_row': hitRow,
      };
}

/// A kajakk on the water: put out at `u0` (1/60 mm) at tick `st`, moving `v` mm/s along `lane`.
class FjordKajakk {
  FjordKajakk(this.n, this.lane, this.v, this.u0, this.st);

  final int n;
  final int lane;
  final int v;
  final int u0;
  final int st;

  /// Where it is at tick [t], in 1/60 mm.
  int uAt(int t) => u0 + v * (t - st);
}

/// The simulation stepped one tick at a time — what the play screen drives and draws, and what [FjordEngine.run]
/// replays. Its state is public for drawing only; nothing outside may change it.
class FjordSim {
  FjordSim(Map<String, dynamic> course, this.perk)
      : params = (course['params'] as Map).cast<String, dynamic>(),
        rows = (course['rows'] as List).cast<Map>() {
    final p = params;
    nRows = rows.length;
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
    crateM = FjordEngine._i(p['crate_m']);
    vestAvail = perk == 'vest';
  }

  final Map<String, dynamic> params;
  final List<Map> rows;
  final String perk;
  late final int nRows, lengthMm, start, step, max, lc, mid, wakeFrom, wakeTicks, grace, kAhead, crateM;

  /// The next tick to simulate.
  int tick = 0;

  /// The boat's distance, 1/60 mm.
  int u = 0;
  final List<int> hist = [];
  int chFrom = 1, chTo = 1, chStart = -1000000;
  int crates = 0;
  late bool vestAvail;
  bool vestUsed = false;
  int graceUntil = -1;
  int nextRow = 0, kNext = 0;
  List<FjordKajakk> kajakks = [];

  /// A pending wake: [direction, the tick it pushes].
  List<int>? wake;
  String? ended;
  int endTick = 0;
  int? hitRow;

  /// The tick the redningsvest took a hit (drawing: «Redningsvesten tok støyten»).
  int? vestHitTick;

  bool get done => ended != null || tick >= FjordEngine.maxTicks;

  int get sailedM => u ~/ 60000;

  (Map, int) rowAt(int n) {
    final r = rows[n % nRows];
    return (r, FjordEngine._i(r['d']) + (n ~/ nRows) * lengthMm);
  }

  int effLane(int t) => (t - chStart) < mid ? chFrom : chTo;

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
    if (t < chStart + lc) return;
    final to = chTo + dir;
    if (to < 0 || to > 2) return;
    chFrom = chTo;
    chTo = to;
    chStart = t;
  }

  void _hit(int t, int n) {
    if (t < graceUntil) return;
    if (vestAvail) {
      vestAvail = false;
      vestUsed = true;
      vestHitTick = t;
      graceUntil = t + grace;
    } else {
      ended = 'collision';
      endTick = t;
      hitRow = n;
    }
  }

  /// One tick, with the lane inputs given at it (−1 left, +1 right), in order.
  void stepTick(List<int> dirs) {
    if (done) return;
    final t = tick;
    // (1) inputs
    for (final d0 in dirs) {
      final dir = d0 < 0 ? -1 : 1;
      final w = wake;
      if (w != null && dir == -w[0]) {
        wake = null;
        continue;
      }
      _change(t, dir);
    }
    // (2) the wake pushes if nobody steered against it
    final w = wake;
    if (w != null && t >= w[1]) {
      _change(t, w[0]);
      wake = null;
    }
    // (3) advance
    u += speedAt(t);
    hist.add(u);
    // (4) kajakks put out
    while (true) {
      final (r, d) = rowAt(kNext);
      if (u < (d - kAhead) * 60) break;
      if (r['t'] == 'kajakk') {
        final kp = (r['p'] as Map);
        kajakks.add(FjordKajakk(kNext, FjordEngine._i(kp['lane']), FjordEngine._i(kp['v']), d * 60, t));
      }
      kNext++;
    }
    // (5) rows passed
    while (ended == null) {
      final (r, d) = rowAt(nextRow);
      if (u < d * 60) break;
      final n = nextRow;
      nextRow++;
      final lane = effLane(t);
      if (FjordEngine._i(r['c'] ?? -1) == lane) crates++;
      final b = FjordEngine.blocked(r, d, t, firstAt);
      if (r['t'] == 'wake' && d >= wakeFrom) {
        wake = [FjordEngine._i((r['p'] as Map)['w']) < 0 ? -1 : 1, t + wakeTicks];
      }
      if (b.contains(lane)) _hit(t, n);
    }
    // (6) kajakks caught
    if (ended == null && kajakks.isNotEmpty) {
      final keep = <FjordKajakk>[];
      for (final k in kajakks) {
        if (ended != null) {
          keep.add(k);
          continue;
        }
        if (u < k.uAt(t)) {
          keep.add(k);
          continue;
        }
        if (effLane(t) == k.lane) _hit(t, k.n);
      }
      kajakks = keep;
    }
    tick++;
  }

  FjordResult result() {
    final ticks = ended == 'collision' ? endTick + 1 : hist.length;
    return FjordResult(
      distanceM: sailedM + crates * crateM,
      sailedMm: u ~/ 60,
      crates: crates,
      ticks: ticks,
      vestUsed: vestUsed,
      ended: ended ?? 'limit',
      gates: [
        for (final m in (params['milestones_m'] as List))
          if (sailedM >= FjordEngine._i(m)) FjordEngine._i(m),
      ],
      hitRow: hitRow,
    );
  }
}

abstract final class FjordEngine {
  static const int version = 1;

  /// 15 minutes.
  static const int maxTicks = 54000;

  static const List<int> _centres = [500, 1500, 2500];

  static int _i(Object? v) => v is int ? v : (v is num ? v.toInt() : int.parse('$v'));

  /// Plays [course] (as the server sends it: `params`, `rows`) with [perk] (`none` | `vest`) and [inputs] (ascending).
  static FjordResult run(Map<String, dynamic> course, String perk, List<FjordInput> inputs) {
    final sim = FjordSim(course, perk);
    var ii = 0;
    final n = inputs.length;
    while (!sim.done) {
      final t = sim.tick;
      while (ii < n && inputs[ii].tick < t) {
        ii++;
      }
      final dirs = <int>[];
      while (ii < n && inputs[ii].tick == t) {
        dirs.add(inputs[ii].dir);
        ii++;
      }
      sim.stepTick(dirs);
    }
    return sim.result();
  }

  /// The beffen's position across the fjord (width units, lanes centred at 500/1500/2500) at tick [t] — before it is
  /// put out, where it starts. Drawing only.
  static int beffenX(Map r, int d, int t, int Function(int target) firstAt, int u) {
    final p = (r['p'] as Map?) ?? const {};
    if (u < (d - _i(p['a'])) * 60) return _i(p['x0']);
    final st = firstAt((d - _i(p['a'])) * 60);
    return _i(p['x0']) + _i(p['vx']) * (t - st);
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
        final st = firstAt((d - _i(p['a'])) * 60);
        final x = _i(p['x0']) + _i(p['vx']) * (t - st);
        final h = _i(p['h']);
        return [
          for (var lane = 0; lane < 3; lane++)
            if ((_centres[lane] - x).abs() <= h) lane,
        ];
      case 'make':
        final st = firstAt((d - _i(p['a'])) * 60);
        return t >= st + _i(p['delay']) ? [_i(p['lane'])] : const [];
      default:
        return const [];
    }
  }
}
