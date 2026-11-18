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

class _Kajakk {
  _Kajakk(this.n, this.lane, this.v, this.u0, this.st);

  final int n;
  final int lane;
  final int v;
  final int u0;
  final int st;
}

abstract final class FjordEngine {
  static const int version = 1;

  /// 15 minutes.
  static const int maxTicks = 54000;

  static const List<int> _centres = [500, 1500, 2500];

  static int _i(Object? v) => v is int ? v : (v is num ? v.toInt() : int.parse('$v'));

  /// Plays [course] (as the server sends it: `params`, `rows`) with [perk] (`none` | `vest`) and [inputs] (ascending).
  static FjordResult run(Map<String, dynamic> course, String perk, List<FjordInput> inputs) {
    final p = (course['params'] as Map).cast<String, dynamic>();
    final rows = (course['rows'] as List).cast<Map>();
    final nRows = rows.length;
    final lengthMm = _i(p['length_m']) * 1000;
    final start = _i(p['speed_start_mms']);
    final step = _i(p['speed_step_mms']);
    final max = _i(p['speed_max_mms']);
    final lc = _i(p['lane_change_ticks']) < 1 ? 1 : _i(p['lane_change_ticks']);
    final mid = lc ~/ 2;
    final wakeFrom = _i(p['wake_from_m']) * 1000;
    final wakeTicks = _i(p['wake_counter_ticks']);
    final grace = _i(p['vest_grace_ticks']);
    final kAhead = _i(p['kajakk_ahead_mm']);
    final crateM = _i(p['crate_m']);

    var u = 0;
    final hist = <int>[];
    var chFrom = 1;
    var chTo = 1;
    var chStart = -1000000;
    var crates = 0;
    var vestAvail = perk == 'vest';
    var vestUsed = false;
    var graceUntil = -1;
    var nextRow = 0;
    var kNext = 0;
    var kajakks = <_Kajakk>[];
    List<int>? wake; // [w, until]
    var ii = 0;
    final nIn = inputs.length;
    String? ended;
    var endTick = 0;
    int? hitRow;

    (Map, int) rowAt(int n) {
      final r = rows[n % nRows];
      return (r, _i(r['d']) + (n ~/ nRows) * lengthMm);
    }

    int eff(int t) => (t - chStart) < mid ? chFrom : chTo;

    void change(int t, int dir) {
      if (t < chStart + lc) return;
      final to = chTo + dir;
      if (to < 0 || to > 2) return;
      chFrom = chTo;
      chTo = to;
      chStart = t;
    }

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

    void hit(int t, int n) {
      if (t < graceUntil) return;
      if (vestAvail) {
        vestAvail = false;
        vestUsed = true;
        graceUntil = t + grace;
      } else {
        ended = 'collision';
        endTick = t;
        hitRow = n;
      }
    }

    for (var t = 0; t < maxTicks && ended == null; t++) {
      // (1) inputs
      while (ii < nIn && inputs[ii].tick < t) {
        ii++;
      }
      while (ii < nIn && inputs[ii].tick == t) {
        final dir = inputs[ii].dir < 0 ? -1 : 1;
        ii++;
        if (wake != null && dir == -wake[0]) {
          wake = null;
          continue;
        }
        change(t, dir);
      }
      // (2) the wake pushes if nobody steered against it
      if (wake != null && t >= wake[1]) {
        change(t, wake[0]);
        wake = null;
      }
      // (3) advance
      final s = start + (step * t) ~/ 60;
      u += s < max ? s : max;
      hist.add(u);
      // (4) kajakks put out
      while (true) {
        final (r, d) = rowAt(kNext);
        if (u < (d - kAhead) * 60) break;
        if (r['t'] == 'kajakk') {
          final kp = (r['p'] as Map);
          kajakks.add(_Kajakk(kNext, _i(kp['lane']), _i(kp['v']), d * 60, t));
        }
        kNext++;
      }
      // (5) rows passed
      while (ended == null) {
        final (r, d) = rowAt(nextRow);
        if (u < d * 60) break;
        final n = nextRow;
        nextRow++;
        final lane = eff(t);
        if (_i(r['c'] ?? -1) == lane) crates++;
        final b = blocked(r, d, t, firstAt);
        if (r['t'] == 'wake' && d >= wakeFrom) {
          wake = [_i((r['p'] as Map)['w']) < 0 ? -1 : 1, t + wakeTicks];
        }
        if (b.contains(lane)) hit(t, n);
      }
      // (6) kajakks caught
      if (ended == null && kajakks.isNotEmpty) {
        final keep = <_Kajakk>[];
        for (final k in kajakks) {
          if (ended != null) {
            keep.add(k);
            continue;
          }
          final ku = k.u0 + k.v * (t - k.st);
          if (u < ku) {
            keep.add(k);
            continue;
          }
          if (eff(t) == k.lane) hit(t, k.n);
        }
        kajakks = keep;
      }
    }

    final ticks = ended == 'collision' ? endTick + 1 : hist.length;
    final sailedM = u ~/ 60000;
    return FjordResult(
      distanceM: sailedM + crates * crateM,
      sailedMm: u ~/ 60,
      crates: crates,
      ticks: ticks,
      vestUsed: vestUsed,
      ended: ended ?? 'limit',
      gates: [
        for (final m in (p['milestones_m'] as List))
          if (sailedM >= _i(m)) _i(m),
      ],
      hitRow: hitRow,
    );
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
