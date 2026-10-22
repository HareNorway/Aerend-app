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
    this.conversationId,
    this.messageId,
    this.source,
    this.aiLabel,
    this.verktoy = const [],
    this.chips = const [],
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

  /// Customer Step 5: the conversation this turn belongs to (`cv_…`) and its
  /// message id — the app keeps the id and resumes the chat after a relaunch.
  final String? conversationId;
  final int? messageId;

  /// Who answered: `model`, `template` (the template lines) or `rules`.
  final String? source;

  /// «Ægil er en AI».
  final String? aiLabel;

  /// The typed cards under the reply (`tool_cards`).
  final List<AeVerktoy> verktoy;

  /// Follow-ups the reply offers (`chips`); empty means the screen's own.
  final List<String> chips;

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
    conversationId: json['conversation_id'] as String?,
    messageId: (json['message_id'] as num?)?.toInt(),
    source: json['source'] as String?,
    aiLabel: json['ai_label'] as String?,
    verktoy: ((json['tool_cards'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => AeVerktoy.fromJson(e.cast<String, dynamic>()))
        .where((v) => v.type.isNotEmpty)
        .toList(),
    chips: ((json['chips'] as List?) ?? const []).whereType<String>().toList(),
  );
}

/// Customer Step 5: a typed card under a chat reply (`tool_cards`) — an
/// order's status, the basket, a cart change Ægil proposes (the tap applies
/// it; then a receipt with Angre), a person (Hjelp), Min bio.
class AeVerktoy {
  const AeVerktoy(this.type, this.data);

  factory AeVerktoy.fromJson(Map<String, dynamic> json) => AeVerktoy((json['type'] as String?) ?? '', json);

  final String type;
  final Map<String, dynamic> data;

  /// A proposal's id (`pa_…`).
  String? get id => data['id'] as String?;
  String get status => (data['status'] as String?) ?? '';

  AeVerktoy med(Map<String, dynamic> nytt) => AeVerktoy(type, {...data, ...nytt});

  Map<String, dynamic> map(String k) => (data[k] is Map) ? (data[k] as Map).cast<String, dynamic>() : const {};
}

/// Customer Step 5: one of the customer's chats (`GET agent/chat/conversations`).
class AegilSamtale {
  const AegilSamtale({required this.id, this.title, this.messageCount = 0, this.lastMessageAt, this.open = true});

  factory AegilSamtale.fromJson(Map<String, dynamic> json) => AegilSamtale(
    id: (json['id'] as String?) ?? '',
    title: json['title'] as String?,
    messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
    lastMessageAt: DateTime.tryParse('${json['last_message_at'] ?? ''}'),
    open: (json['status'] as String?) != 'closed',
  );

  final String id;
  final String? title;
  final int messageCount;
  final DateTime? lastMessageAt;
  final bool open;
}

/// Customer Step 5: a line of a stored chat — the customer's words, or
/// Ægil's turn (read back through [AegilTurn.fromJson]).
class AegilSamtaleLinje {
  const AegilSamtaleLinje({required this.meg, required this.tekst, this.turn});

  factory AegilSamtaleLinje.fromJson(Map<String, dynamic> json) {
    final meg = json['role'] == 'customer';
    final tekst = (json['text'] as String?) ?? '';
    if (meg) return AegilSamtaleLinje(meg: true, tekst: tekst);
    final payload = json['payload'] is Map ? (json['payload'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    return AegilSamtaleLinje(
      meg: false,
      tekst: tekst,
      turn: AegilTurn.fromJson({...payload, 'state': json['state'] ?? 'agSvar', 'reply': tekst, 'tool_cards': json['tool_cards'], 'chips': json['chips'], 'source': json['source']}),
    );
  }

  final bool meg;
  final String tekst;
  final AegilTurn? turn;
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
    this.at,
  });

  final int id;
  final String text;
  final String action;
  final String? deepLink;
  final bool undoable;

  /// When Ægil did it (`at`, ISO 8601); the Varsler panel groups by day.
  final DateTime? at;

  factory AwayItem.fromJson(Map<String, dynamic> json) => AwayItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    text: (json['text'] as String?) ?? '',
    action: (json['action'] as String?) ?? '',
    deepLink: json['deep_link'] as String?,
    undoable: json['undoable'] == true,
    at: DateTime.tryParse((json['at'] as String?) ?? '')?.toLocal(),
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
    this.lines = const [],
  });

  final String month;
  final int savedKr;
  final int findsApplied;
  final int againstInterestShown;
  final int waitRecommended;
  final int cheaperElsewhereTaken;

  /// Customer Step 5: the month's findings for Meg's sheet (newest first).
  final List<({String text, String sub})> lines;

  factory TrustLedger.fromJson(Map<String, dynamic> json) => TrustLedger(
    month: (json['month'] as String?) ?? '',
    savedKr: (json['saved_kr'] as num?)?.toInt() ?? 0,
    findsApplied: (json['finds_applied'] as num?)?.toInt() ?? 0,
    againstInterestShown: (json['against_interest_shown'] as num?)?.toInt() ?? 0,
    waitRecommended: (json['wait_recommended'] as num?)?.toInt() ?? 0,
    cheaperElsewhereTaken: (json['cheaper_elsewhere_taken'] as num?)?.toInt() ?? 0,
    lines: ((json['lines'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => (text: '${e['text'] ?? ''}', sub: '${e['sub'] ?? ''}'))
        .where((l) => l.text.isNotEmpty)
        .toList(),
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
    this.qualifiedTotal = 0,
    this.pointsEarned = 0,
    this.ladder = const [],
    this.friends = const [],
  });

  final String code;
  final String? link;
  final int pointsForMe;
  final int pointsForThem;
  final int qualifiedThisMonth;
  final int monthlyCap;

  /// agil-4: lifetime qualified referrals, points they brought in, the
  /// Gullbillett ladder and the friends who used the code.
  final int qualifiedTotal;
  final int pointsEarned;
  final List<VervStep> ladder;
  final List<VervFriend> friends;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    code: (json['code'] as String?) ?? '',
    link: json['link'] as String?,
    pointsForMe: (json['points_for_me'] as num?)?.toInt() ?? 200,
    pointsForThem: (json['points_for_them'] as num?)?.toInt() ?? 200,
    qualifiedThisMonth: (json['qualified_this_month'] as num?)?.toInt() ?? 0,
    monthlyCap: (json['monthly_cap'] as num?)?.toInt() ?? 5,
    qualifiedTotal: (json['qualified_total'] as num?)?.toInt() ?? 0,
    pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
    ladder: ((json['ladder'] as List?) ?? const []).whereType<Map>().map((e) => VervStep.fromJson(e.cast<String, dynamic>())).toList(),
    friends: ((json['friends'] as List?) ?? const []).whereType<Map>().map((e) => VervFriend.fromJson(e.cast<String, dynamic>())).toList(),
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

/// One step on the Gullbillett ladder (`points.keys.verving_trapp`).
class VervStep {
  const VervStep({required this.at, required this.name, required this.bonus});

  final int at;
  final String name;
  final int bonus;

  factory VervStep.fromJson(Map<String, dynamic> json) => VervStep(
        at: (json['at'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? '',
        bonus: (json['bonus'] as num?)?.toInt() ?? 0,
      );
}

/// A friend who used the code: `downloaded` (claimed) or `delivered` (qualified).
class VervFriend {
  const VervFriend({required this.name, required this.status, this.at});

  final String name;
  final String status;
  final String? at;

  bool get delivered => status == 'delivered';

  factory VervFriend.fromJson(Map<String, dynamic> json) => VervFriend(
        name: (json['name'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'downloaded',
        at: json['at'] as String?,
      );
}
