/// Bergen-ligaen data shapes (AGIL-2 Phase 5).
library;

class LeagueStanding {
  const LeagueStanding({
    required this.rank,
    required this.userId,
    required this.points,
    this.bydel,
    this.name,
    this.orders = 0,
    this.employee = false,
  });

  /// Points plan Step 11: employees earn points and are never ranked.
  final bool employee;

  /// 0 when not ranked yet (points plan Step 11: fewer than the minimum orders this month).
  final int rank;

  /// Delivered orders this month (ranked from [League.minOrders]).
  final int orders;
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
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        employee: json['employee'] == true,
      );
}

/// A row of the month's prizes (points plan Step 11, `league.prizes`): places [from]–[to], a premie by name or points.
class LeaguePrize {
  const LeaguePrize({required this.from, required this.to, required this.kind, this.points = 0, this.premie, this.uses = 1});

  final int from;
  final int to;
  final String kind;
  final int points;
  final String? premie;
  final int uses;

  factory LeaguePrize.fromJson(Map<String, dynamic> j) => LeaguePrize(
        from: (j['from'] as num?)?.toInt() ?? 0,
        to: (j['to'] as num?)?.toInt() ?? 0,
        kind: (j['kind'] as String?) ?? 'points',
        points: (j['points'] as num?)?.toInt() ?? 0,
        premie: j['premie'] as String?,
        uses: (j['uses'] as num?)?.toInt() ?? 1,
      );
}

/// The closed month for «Nordlys over Fløyen» (`league.last_month`).
class LeagueLastMonth {
  const LeagueLastMonth({required this.month, this.top = const [], this.ownRank});

  final String month;
  final List<LeagueStanding> top;
  final int? ownRank;

  factory LeagueLastMonth.fromJson(Map<String, dynamic> j) => LeagueLastMonth(
        month: (j['month'] as String?) ?? '',
        top: ((j['top'] as List?) ?? const []).whereType<Map>().map((e) => LeagueStanding.fromJson(e.cast<String, dynamic>())).toList(),
        ownRank: (j['own_rank'] as num?)?.toInt(),
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
    this.capPerOrder = 100,
    this.displayName,
    this.visibility = 'alle',
    this.minOrders = 3,
    this.holdHours = 48,
    this.top3CooldownMonths = 3,
    this.prizes = const [],
    this.feed = const [],
    this.lastMonth,
    this.boat,
  });

  /// Points plan Step 11 (points spec §10): ranked from this many delivered orders in the month.
  final int minOrders;

  /// Awards are held this long after month end; a top-three prize once per this many months.
  final int holdHours;
  final int top3CooldownMonths;

  /// The month's prizes as the server sets them (Regler › Bergen-ligaen).
  final List<LeaguePrize> prizes;

  /// The activity feed («Kari klatret 2 plasser»), display names only.
  final List<String> feed;

  /// The closed month, for «Nordlys over Fløyen».
  final LeagueLastMonth? lastMonth;

  /// Last month's winner on Ægil's boat.
  final String? boat;

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
      capPerOrder: (json['cap_per_order'] as num?)?.toInt() ?? 100,
      minOrders: (league['min_orders'] as num?)?.toInt() ?? 3,
      holdHours: (league['hold_h'] as num?)?.toInt() ?? 48,
      top3CooldownMonths: (league['top3_cooldown_months'] as num?)?.toInt() ?? 3,
      prizes: ((league['prizes'] as List?) ?? const []).whereType<Map>().map((e) => LeaguePrize.fromJson(e.cast<String, dynamic>())).toList(),
      feed: ((league['feed'] as List?) ?? const []).whereType<Map>().map((e) => '${e['text'] ?? ''}').where((t) => t.isNotEmpty).toList(),
      lastMonth: league['last_month'] is Map ? LeagueLastMonth.fromJson((league['last_month'] as Map).cast<String, dynamic>()) : null,
      boat: league['boat'] as String?,
      displayName: (league['profile'] as Map?)?['display_name'] as String?,
      visibility: ((league['profile'] as Map?)?['visibility'] as String?) ?? 'alle',
    );
  }
}
