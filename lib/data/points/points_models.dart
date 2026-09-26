/// Data shapes for Points v2 (AGIL-2).
///
/// Mirrors the backend payloads from `/api/points/*` in Hare-AdminPanel. Every model parses
/// defensively: a missing or unexpected field degrades to a sensible zero rather than
/// throwing, because a points screen failing to render is worse than one showing 0.
library;

class PointsBalance {
  const PointsBalance({
    this.available = 0,
    this.pending = 0,
    this.earned12m = 0,
    this.lifetime = 0,
    this.tier = 0,
    this.tierName = 'Fløyen',
    this.nextTierName,
    this.pointsToNextTier,
    this.expiringAmount = 0,
    this.expiringWindowDays = 30,
    this.expiringFirstAt,
    this.policyVersion = '',
    this.tiers = const [],
  });

  /// Spendable now.
  final int available;

  /// Earned but still inside the order's return window.
  final int pending;

  /// What drives Nivå. Spending and expiry never reduce it.
  final int earned12m;

  final int lifetime;

  final int tier;
  final String tierName;
  final String? nextTierName;
  final int? pointsToNextTier;

  final int expiringAmount;
  final int expiringWindowDays;
  final DateTime? expiringFirstAt;

  final String policyVersion;

  /// The whole ladder (agil-4): Bronse → Sølv → Gull → Platina with thresholds.
  final List<TierStep> tiers;

  bool get hasExpiryNotice => expiringAmount > 0;

  /// 0..1 through the current tier band. 1.0 at the top tier, which has no next band.
  double progressToNextTier() {
    final toNext = pointsToNextTier;
    if (toNext == null || nextTierName == null) return 1;
    if (toNext <= 0) return 1;
    final span = earned12m + toNext;
    if (span <= 0) return 0;
    return (earned12m / span).clamp(0.0, 1.0);
  }

  factory PointsBalance.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as Map?)?.cast<String, dynamic>() ?? const {};
    final tier = (json['tier'] as Map?)?.cast<String, dynamic>() ?? const {};
    final expiring =
        (json['expiring_soon'] as Map?)?.cast<String, dynamic>() ?? const {};

    return PointsBalance(
      available: _int(points['available']),
      pending: _int(points['pending']),
      earned12m: _int(points['earned_12m']),
      lifetime: _int(points['lifetime']),
      tier: _int(tier['index']),
      tierName: (tier['name'] as String?) ?? 'Fløyen',
      nextTierName: tier['next_name'] as String?,
      pointsToNextTier:
          tier['points_to_next'] == null ? null : _int(tier['points_to_next']),
      expiringAmount: _int(expiring['amount']),
      expiringWindowDays: _int(expiring['window_days'], fallback: 30),
      expiringFirstAt: _date(expiring['first_expires_at']),
      policyVersion: (json['policy_version'] as String?) ?? '',
      tiers: ((json['tiers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TierStep.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// One rung of the Nivå ladder (`points/me` → `tiers[]`).
class TierStep {
  const TierStep({required this.index, required this.name, required this.threshold});

  final int index;
  final String name;
  final int threshold;

  factory TierStep.fromJson(Map<String, dynamic> json) => TierStep(
        index: _int(json['index']),
        name: (json['name'] as String?) ?? '',
        threshold: _int(json['threshold']),
      );
}

/// The Meg tab's preferences and row counts (`points/me/prefs`, agil-4).
class CustomerPrefs {
  const CustomerPrefs({
    this.alwaysCode = false,
    this.notificationsSeenAt,
    this.notificationsUnseen = 0,
    this.favourites = 0,
  });

  final bool alwaysCode;
  final DateTime? notificationsSeenAt;
  final int notificationsUnseen;
  final int favourites;

  factory CustomerPrefs.fromJson(Map<String, dynamic> json) {
    final prefs = (json['prefs'] as Map?)?.cast<String, dynamic>() ?? const {};
    final counts = (json['counts'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CustomerPrefs(
      alwaysCode: prefs['always_code'] == true,
      notificationsSeenAt: _date(prefs['notifications_seen_at']),
      notificationsUnseen: _int(counts['notifications_unseen']),
      favourites: _int(counts['favourites']),
    );
  }
}

/// A prize the customer can claim now.
class Prize {
  const Prize({
    required this.id,
    required this.name,
    required this.pointPrice,
    required this.tierBand,
    required this.tierName,
    this.line,
    this.partnerName,
    this.type = 'voucher',
    this.inStock = true,
    this.affordable = false,
    this.claimable = false,
    this.blockedReason,
  });

  final int id;
  final String name;
  final String? line;
  final String? partnerName;
  final String type;
  final int pointPrice;
  final int tierBand;
  final String tierName;
  final bool inStock;
  final bool affordable;
  final bool claimable;
  final String? blockedReason;

  factory Prize.fromJson(Map<String, dynamic> json) => Prize(
        id: _int(json['id']),
        name: (json['name'] as String?) ?? '',
        line: json['line'] as String?,
        partnerName: json['partner_name'] as String?,
        type: (json['type'] as String?) ?? 'voucher',
        pointPrice: _int(json['point_price']),
        tierBand: _int(json['tier_band']),
        tierName: (json['tier_name'] as String?) ?? '',
        inStock: json['in_stock'] as bool? ?? true,
        affordable: json['affordable'] as bool? ?? false,
        claimable: json['claimable'] as bool? ?? false,
        blockedReason: json['blocked_reason'] as String?,
      );
}

/// A prize from the next band: shown blurred, with the gap still to close.
///
/// The design is explicit that there is no padlock — this reads as "not yet",
/// not "forbidden".
class PrizePreview {
  const PrizePreview({
    required this.id,
    required this.name,
    required this.pointPrice,
    required this.tierName,
    required this.pointsToUnlock,
    this.teaser,
  });

  final int id;
  final String name;
  final String? teaser;
  final int pointPrice;
  final String tierName;

  /// Points of *earning* still needed to reach the band, not to afford the prize.
  final int pointsToUnlock;

  /// "Fra Rundemanen · 2400 poeng til"
  String get unlockLine => 'Fra $tierName · $pointsToUnlock poeng til';

  factory PrizePreview.fromJson(Map<String, dynamic> json) => PrizePreview(
        id: _int(json['id']),
        name: (json['name'] as String?) ?? '',
        teaser: json['teaser'] as String?,
        pointPrice: _int(json['point_price']),
        tierName: (json['tier_name'] as String?) ?? '',
        pointsToUnlock: _int(json['points_to_unlock']),
      );
}

class PrizeClaim {
  const PrizeClaim({
    required this.id,
    required this.prizeId,
    required this.state,
    this.prizeName,
    this.pointsSpent = 0,
    this.voucherCode,
    this.identityName,
    this.nameReview = 'not_required',
    this.cancellable = false,
    this.cancelDeadlineAt,
    this.expiresAt,
    this.createdAt,
  });

  final int id;
  final int prizeId;
  final String? prizeName;
  final String state;
  final int pointsSpent;
  final String? voucherCode;
  final String? identityName;
  final String nameReview;
  final bool cancellable;
  final DateTime? cancelDeadlineAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// A zero-cost claim is a welcome gift, not a purchase.
  bool get isGift => pointsSpent == 0;

  bool get isAwaitingNameReview => nameReview == 'pending';

  factory PrizeClaim.fromJson(Map<String, dynamic> json) => PrizeClaim(
        id: _int(json['id']),
        prizeId: _int(json['prize_id']),
        prizeName: json['prize_name'] as String?,
        state: (json['state'] as String?) ?? 'claimed',
        pointsSpent: _int(json['points_spent']),
        voucherCode: json['voucher_code'] as String?,
        identityName: json['identity_name'] as String?,
        nameReview: (json['name_review'] as String?) ?? 'not_required',
        cancellable: json['cancellable'] as bool? ?? false,
        cancelDeadlineAt: _date(json['cancel_deadline_at']),
        expiresAt: _date(json['expires_at']),
        createdAt: _date(json['created_at']),
      );
}

class PointGoal {
  const PointGoal({
    required this.kind,
    required this.label,
    required this.current,
    required this.target,
    required this.remaining,
    required this.percent,
    this.reached = false,
    this.prizeId,
    this.tier,
    this.source = 'customer',
  });

  final String kind;
  final String label;
  final int current;
  final int target;
  final int remaining;
  final int percent;
  final bool reached;
  final int? prizeId;
  final int? tier;
  final String source;

  factory PointGoal.fromJson(Map<String, dynamic> json) => PointGoal(
        kind: (json['kind'] as String?) ?? 'prize',
        label: (json['label'] as String?) ?? '',
        current: _int(json['current']),
        target: _int(json['target']),
        remaining: _int(json['remaining']),
        percent: _int(json['percent']),
        reached: json['reached'] as bool? ?? false,
        prizeId: json['prize_id'] == null ? null : _int(json['prize_id']),
        tier: json['tier'] == null ? null : _int(json['tier']),
        source: (json['source'] as String?) ?? 'customer',
      );
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.body,
    required this.points,
    this.state = 'active',
    this.progress = 0,
    this.target = 1,
    this.wordingSource = 'template',
    this.accepted = false,
  });

  final int id;
  final String title;
  final String body;
  final int points;
  final String state;
  final int progress;
  final int target;

  /// 'template' or 'agent' — Phase 7 lets Ægil reword a mission.
  final String wordingSource;

  /// "Godta" pressed (agil-4). Assignment already makes a mission active.
  final bool accepted;

  double get fraction => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: _int(json['id']),
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        points: _int(json['points']),
        state: (json['state'] as String?) ?? 'active',
        progress: _int(json['progress']),
        target: _int(json['target'], fallback: 1),
        wordingSource: (json['wording_source'] as String?) ?? 'template',
        accepted: json['accepted'] == true,
      );
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.ruleKey,
    required this.amount,
    this.pending = false,
    this.createdAt,
  });

  final int id;
  final String kind;
  final String ruleKey;
  final int amount;
  final bool pending;
  final DateTime? createdAt;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: _int(json['id']),
        kind: (json['kind'] as String?) ?? 'earn',
        ruleKey: (json['rule_key'] as String?) ?? '',
        amount: _int(json['amount']),
        pending: json['pending'] as bool? ?? false,
        createdAt: _date(json['created_at']),
      );
}

/// The shelf as one payload: what is claimable, what is previewed, and the active goal.
class Premiehylla {
  const Premiehylla({
    this.prizes = const [],
    this.previews = const [],
    this.goal,
  });

  final List<Prize> prizes;
  final List<PrizePreview> previews;
  final PointGoal? goal;

  factory Premiehylla.fromJson(Map<String, dynamic> json) => Premiehylla(
        prizes: ((json['prizes'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Prize.fromJson(e.cast<String, dynamic>()))
            .toList(),
        previews: ((json['previews'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => PrizePreview.fromJson(e.cast<String, dynamic>()))
            .toList(),
        goal: json['goal'] == null
            ? null
            : PointGoal.fromJson((json['goal'] as Map).cast<String, dynamic>()),
      );
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _date(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
