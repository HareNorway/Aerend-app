/// Fjordløpet v1.3 plan Step 6 (spec v1.3 §4.6 line 3; plan D6): the nearest goal, and only one — the smallest gap in
/// metres from a run's distance to the next milestone, the customer's best this week, the rival and the top ten. A
/// badge that lacks a fifth of its target or less takes the line instead. Computed on the phone from `/game/state` so
/// the end screen needs no network; the server has the same rule (`App\Game\NearestGoal`) for Levert and Meg.
class FjordGoal {
  const FjordGoal._(this.type, {this.gapM = 0, this.name = '', this.place = 0, this.index = 0, this.metric = '', this.remaining = 0});

  /// badge | milestone | best | rival | top10
  final String type;
  final int gapM;
  final String name;
  final int place;

  /// The milestone's index (Bøye 1, Bøye 2, Bryggen).
  final int index;
  final String metric;
  final int remaining;

  /// [badges]: (name, metric, target, progress after this run, done). [ladder]: (place, name, distance, me).
  static FjordGoal? of({
    required int distanceM,
    required List<int> milestones,
    int? bestM,
    (int place, String name, int distanceM)? rival,
    List<(int place, String name, int distanceM, bool me)> ladder = const [],
    List<(String name, String metric, int target, int progress, bool done)> badges = const [],
    int badgePct = 20,
  }) {
    FjordGoal? badge;
    for (final b in badges) {
      final left = b.$3 - b.$4;
      if (!b.$5 && left > 0 && left * 100 <= b.$3 * badgePct && (badge == null || left < badge.remaining)) {
        badge = FjordGoal._('badge', name: b.$1, metric: b.$2, remaining: left);
      }
    }
    if (badge != null) return badge;

    FjordGoal? best;
    void offer(FjordGoal g) {
      if (best == null || g.gapM < best!.gapM) best = g;
    }

    for (var i = 0; i < milestones.length; i++) {
      if (milestones[i] > distanceM) {
        offer(FjordGoal._('milestone', gapM: milestones[i] - distanceM, index: i));
        break;
      }
    }
    if (bestM != null && bestM > distanceM) offer(FjordGoal._('best', gapM: bestM - distanceM));
    if (rival != null && rival.$3 > distanceM) offer(FjordGoal._('rival', gapM: rival.$3 - distanceM, name: rival.$2, place: rival.$1));
    for (final r in ladder) {
      if (!r.$4 && r.$3 > distanceM) offer(FjordGoal._('top10', gapM: r.$3 - distanceM, name: r.$2, place: r.$1));
    }
    return best;
  }
}
