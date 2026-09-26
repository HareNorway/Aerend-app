/// Fløyen-ligaen data shapes (AGIL-2 Phase 5).
library;

class LeagueStanding {
  const LeagueStanding({
    required this.rank,
    required this.userId,
    required this.points,
    this.bydel,
    this.name,
  });

  final int rank;
  final int userId;
  final int points;
  final String? bydel;

  /// The chosen league name the viewer may see, else "Klatrer N" (agil-4).
  final String? name;

  String get label => name ?? 'Klatrer $rank';

  factory LeagueStanding.fromJson(Map<String, dynamic> json) => LeagueStanding(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        points: (json['points'] as num?)?.toInt() ?? 0,
        bydel: json['bydel'] as String?,
        name: json['name'] as String?,
      );
}

class League {
  const League({
    required this.month,
    this.state = 'open',
    this.top = const [],
    this.own,
    this.participants = 0,
    this.bydel,
    this.bydelStandings = const [],
    this.optedIn = false,
    this.tierBlind = true,
    this.capPerOrder = 200,
    this.displayName,
    this.visibility = 'alle',
  });

  final String month;
  final String state;
  final List<LeagueStanding> top;

  /// Your own place, wherever it falls. A top-ten-only board tells most people nothing.
  final LeagueStanding? own;

  final int participants;

  final String? bydel;
  final List<LeagueStanding> bydelStandings;

  final bool optedIn;

  /// True by design: league points are counted the same whatever Nivå you are on.
  final bool tierBlind;

  /// points.league_cap_per_order — one enormous order cannot buy a month.
  final int capPerOrder;

  /// "Navn i ligaen" (agil-4): the viewer's own chosen name and who may see it
  /// (`alle` | `bydel` | `skjult`).
  final String? displayName;
  final String visibility;

  bool get isClosed => state == 'closed';

  factory League.fromJson(Map<String, dynamic> json) {
    final league = (json['league'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dinBydel = (league['din_bydel'] as Map?)?.cast<String, dynamic>();

    List<LeagueStanding> parse(dynamic list) =>
        ((list as List?) ?? const [])
            .whereType<Map>()
            .map((e) => LeagueStanding.fromJson(e.cast<String, dynamic>()))
            .toList();

    return League(
      month: (league['month'] as String?) ?? '',
      state: (league['state'] as String?) ?? 'open',
      top: parse(league['top']),
      own: league['own'] == null
          ? null
          : LeagueStanding.fromJson((league['own'] as Map).cast<String, dynamic>()),
      participants: (league['participants'] as num?)?.toInt() ?? 0,
      bydel: dinBydel?['bydel'] as String?,
      bydelStandings: parse(dinBydel?['standings']),
      optedIn: json['opted_in'] as bool? ?? false,
      tierBlind: json['tier_blind'] as bool? ?? true,
      capPerOrder: (json['cap_per_order'] as num?)?.toInt() ?? 200,
      displayName: (league['profile'] as Map?)?['display_name'] as String?,
      visibility: ((league['profile'] as Map?)?['visibility'] as String?) ?? 'alle',
    );
  }
}
