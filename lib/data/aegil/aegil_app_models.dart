import 'suggestion_models.dart';

/// One chat turn from `POST agent/chat` (agil-3 Phase 7). `state` is the
/// design's `agentGaa` state the screen renders.
class AegilTurn {
  const AegilTurn({
    required this.state,
    required this.reply,
    this.cards = const [],
    this.basket,
    this.comparison,
    this.doorNote,
    this.swap,
    this.ageGate = false,
    this.gift = false,
    this.stored = 0,
  });

  final String state;
  final String reply;
  final List<Suggestion> cards;
  final AegilBasket? basket;
  final Map<String, dynamic>? comparison;
  final String? doorNote;
  final String? swap;
  final bool ageGate;
  final bool gift;
  final int stored;

  factory AegilTurn.fromJson(Map<String, dynamic> json) => AegilTurn(
    state: (json['state'] as String?) ?? 'agIkkeFunnet',
    reply: (json['reply'] as String?) ?? '',
    cards: ((json['cards'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Suggestion.fromJson(e.cast<String, dynamic>()))
        .toList(),
    basket: json['basket'] is Map
        ? AegilBasket.fromJson((json['basket'] as Map).cast<String, dynamic>())
        : null,
    comparison: json['comparison'] is Map
        ? (json['comparison'] as Map).cast<String, dynamic>()
        : null,
    doorNote: json['door_note'] as String?,
    swap: json['swap'] as String?,
    ageGate: json['age_gate'] == true,
    gift: json['gift'] == true,
    stored: (json['stored'] as num?)?.toInt() ?? 0,
  );
}

class AegilBasketLine {
  const AegilBasketLine({
    required this.name,
    required this.qty,
    required this.priceOre,
    this.suggestionId,
    this.storeProductId,
    this.storeId,
    this.storeName,
    this.reason,
  });

  final String name;
  final int qty;
  final int priceOre;
  final int? suggestionId;
  final int? storeProductId;
  final int? storeId;
  final String? storeName;
  final String? reason;

  factory AegilBasketLine.fromJson(Map<String, dynamic> json) => AegilBasketLine(
    name: (json['name'] as String?) ?? 'Vare',
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    priceOre: (json['price_ore'] as num?)?.toInt() ?? 0,
    suggestionId: (json['suggestion_id'] as num?)?.toInt(),
    storeProductId: (json['store_product_id'] as num?)?.toInt(),
    storeId: (json['store_id'] as num?)?.toInt(),
    storeName: json['store_name'] as String?,
    reason: json['reason'] as String?,
  );
}

class AegilBasket {
  const AegilBasket({
    required this.lines,
    this.storeName,
    this.storeId,
    this.subtotalOre = 0,
    this.derfor,
  });

  final List<AegilBasketLine> lines;
  final String? storeName;
  final int? storeId;
  final int subtotalOre;
  final String? derfor;

  int get count => lines.fold(0, (n, l) => n + l.qty);

  factory AegilBasket.fromJson(Map<String, dynamic> json) => AegilBasket(
    lines: ((json['lines'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => AegilBasketLine.fromJson(e.cast<String, dynamic>()))
        .toList(),
    storeName: json['store_name'] as String?,
    storeId: (json['store_id'] as num?)?.toInt(),
    subtotalOre: (json['subtotal_ore'] as num?)?.toInt() ?? 0,
    derfor: json['derfor'] as String?,
  );
}

/// One line of "Mens du var borte" (`GET agent/me/away`).
class AwayItem {
  const AwayItem({
    required this.id,
    required this.text,
    required this.action,
    this.deepLink,
    this.undoable = false,
  });

  final int id;
  final String text;
  final String action;
  final String? deepLink;
  final bool undoable;

  factory AwayItem.fromJson(Map<String, dynamic> json) => AwayItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    text: (json['text'] as String?) ?? '',
    action: (json['action'] as String?) ?? '',
    deepLink: json['deep_link'] as String?,
    undoable: json['undoable'] == true,
  );
}

/// Tillitsregnskap (`GET agent/me/trust-ledger`).
class TrustLedger {
  const TrustLedger({
    required this.month,
    this.savedKr = 0,
    this.findsApplied = 0,
    this.againstInterestShown = 0,
    this.waitRecommended = 0,
    this.cheaperElsewhereTaken = 0,
  });

  final String month;
  final int savedKr;
  final int findsApplied;
  final int againstInterestShown;
  final int waitRecommended;
  final int cheaperElsewhereTaken;

  factory TrustLedger.fromJson(Map<String, dynamic> json) => TrustLedger(
    month: (json['month'] as String?) ?? '',
    savedKr: (json['saved_kr'] as num?)?.toInt() ?? 0,
    findsApplied: (json['finds_applied'] as num?)?.toInt() ?? 0,
    againstInterestShown: (json['against_interest_shown'] as num?)?.toInt() ?? 0,
    waitRecommended: (json['wait_recommended'] as num?)?.toInt() ?? 0,
    cheaperElsewhereTaken: (json['cheaper_elsewhere_taken'] as num?)?.toInt() ?? 0,
  );
}

/// The referral (Gullbilletten) block from `GET points/me/referral`.
class Referral {
  const Referral({
    required this.code,
    this.link,
    this.pointsForMe = 200,
    this.pointsForThem = 200,
    this.qualifiedThisMonth = 0,
    this.monthlyCap = 5,
  });

  final String code;
  final String? link;
  final int pointsForMe;
  final int pointsForThem;
  final int qualifiedThisMonth;
  final int monthlyCap;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    code: (json['code'] as String?) ?? '',
    link: json['link'] as String?,
    pointsForMe: (json['points_for_me'] as num?)?.toInt() ?? 200,
    pointsForThem: (json['points_for_them'] as num?)?.toInt() ?? 200,
    qualifiedThisMonth: (json['qualified_this_month'] as num?)?.toInt() ?? 0,
    monthlyCap: (json['monthly_cap'] as num?)?.toInt() ?? 5,
  );
}

/// What "Ægil velger" picked (`POST points/prizes/pick`).
class AegilPick {
  const AegilPick({this.prize, required this.reason, this.valueHint, this.affordable = false});

  final Map<String, dynamic>? prize;
  final String reason;
  final String? valueHint;
  final bool affordable;

  String? get prizeName => prize?['name'] as String?;
  int? get prizeId => (prize?['id'] as num?)?.toInt();
  int? get pointPrice => (prize?['point_price'] as num?)?.toInt();

  factory AegilPick.fromJson(Map<String, dynamic> json) => AegilPick(
    prize: json['prize'] is Map ? (json['prize'] as Map).cast<String, dynamic>() : null,
    reason: (json['reason'] as String?) ?? '',
    valueHint: json['value_hint'] as String?,
    affordable: json['affordable'] == true,
  );
}

/// The answer of `POST points/me/earn?rule=dagens_napp`.
class EarnResult {
  const EarnResult({required this.earned, required this.today, required this.max, this.capped = false, this.duplicate = false});

  final int earned;
  final int today;
  final int max;
  final bool capped;
  final bool duplicate;

  factory EarnResult.fromJson(Map<String, dynamic> json) => EarnResult(
    earned: (json['earned'] as num?)?.toInt() ?? 0,
    today: (json['today'] as num?)?.toInt() ?? 0,
    max: (json['max'] as num?)?.toInt() ?? 5,
    capped: json['capped'] == true,
    duplicate: json['duplicate'] == true,
  );
}

/// "Anledninger" (agil-4): a person and a date, one reminder `leadDays` before.
class Occasion {
  const Occasion({
    required this.id,
    required this.person,
    required this.date,
    this.label,
    this.next,
    this.remindOn,
    this.leadDays = 7,
    this.yearly = true,
  });

  final int id;
  final String person;
  final String date;
  final String? label;
  final String? next;
  final String? remindOn;
  final int leadDays;
  final bool yearly;

  factory Occasion.fromJson(Map<String, dynamic> json) => Occasion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        person: (json['person'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        label: json['label'] as String?,
        next: json['next'] as String?,
        remindOn: json['remind_on'] as String?,
        leadDays: (json['lead_days'] as num?)?.toInt() ?? 7,
        yearly: json['yearly'] != false,
      );
}
