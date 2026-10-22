import 'chat_card_models.dart' show ShoppingListItem;
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
    this.undone = false,
  });

  final int id;
  final String text;
  final String action;
  final String? deepLink;
  final bool undoable;

  /// Customer Step 7: a level-3 merge the customer already undid.
  final bool undone;

  /// When Ægil did it (`at`, ISO 8601); the Varsler panel groups by day.
  final DateTime? at;

  factory AwayItem.fromJson(Map<String, dynamic> json) => AwayItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    text: (json['text'] as String?) ?? '',
    action: (json['action'] as String?) ?? '',
    deepLink: json['deep_link'] as String?,
    undoable: json['undoable'] == true,
    at: DateTime.tryParse((json['at'] as String?) ?? '')?.toLocal(),
    undone: json['undone'] == true,
  );
}

/// Something Ægil noticed (`GET agent/me/patterns`, Customer Step 7): a
/// proposal until «Stemmer»; confirmed, it steers level 3 and the rhythm push.
class LearnedPatternItem {
  const LearnedPatternItem({required this.id, required this.type, required this.text, this.support = '', this.confirmed = false});

  final int id;
  final String type;
  final String text;

  /// «Sett i 5 av 6 bestillinger».
  final String support;
  final bool confirmed;

  factory LearnedPatternItem.fromJson(Map<String, dynamic> j) => LearnedPatternItem(
    id: (j['id'] as num?)?.toInt() ?? 0,
    type: '${j['type'] ?? ''}',
    text: '${j['text'] ?? ''}',
    support: '${j['support'] ?? ''}',
    confirmed: j['confirmed'] == true,
  );
}

/// A basket line Ægil merged at level 3 (`GET agent/me/cart/agent-lines`).
class AgentLine {
  const AgentLine({required this.lineId, required this.name, this.productId = 0, this.quantity = 1, this.price = '', this.actionId});

  final int lineId;
  final int productId;
  final String name;
  final int quantity;
  final String price;
  final int? actionId;

  factory AgentLine.fromJson(Map<String, dynamic> j) => AgentLine(
    lineId: (j['line_id'] as num?)?.toInt() ?? 0,
    productId: (j['product_id'] as num?)?.toInt() ?? 0,
    name: '${j['name'] ?? ''}',
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    price: j['price'] is Map ? '${(j['price'] as Map)['display'] ?? ''}' : '${j['price'] ?? ''}',
    actionId: (j['action_id'] as num?)?.toInt(),
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

// Customer Step 8: Ukeshandel (`GET agent/me/weekly`, the dinner plan, the
// level-3 checkout). Money comes as the server's `{amount_ore, display}`.

String _display(dynamic v) => v is Map ? '${v['display'] ?? ''}' : (v == null ? '' : '$v');

/// One line in «Ukens kurv».
class WeeklyLine {
  const WeeklyLine({required this.lineId, required this.name, this.store = '', this.storeId = 0, this.qty = 1, this.source = 'list', this.price = '', this.saving, this.substitution, this.needsAccept = false, this.accepted, this.notes = const []});

  final int lineId;
  final String name;
  final String store;
  final int storeId;
  final int qty;

  /// `list` or `dinner`.
  final String source;
  final String price;

  /// «−40» material: the saving against the reference price, or null.
  final String? saving;

  /// «Friele i stedet for Evergood»: the original the store was out of.
  final String? substitution;
  final bool needsAccept;
  final bool? accepted;
  final List<String> notes;

  bool get pendingAccept => needsAccept && accepted == null;

  factory WeeklyLine.fromJson(Map<String, dynamic> j) {
    final sub = j['substitution'];
    return WeeklyLine(
      lineId: (j['line_id'] as num?)?.toInt() ?? 0,
      name: '${j['name'] ?? ''}',
      store: '${j['store'] ?? ''}',
      storeId: (j['store_id'] as num?)?.toInt() ?? 0,
      qty: (j['qty'] as num?)?.toInt() ?? 1,
      source: '${j['source'] ?? 'list'}',
      price: _display(j['price']),
      saving: j['saving'] == null ? null : _display(j['saving']),
      substitution: sub is Map ? '${sub['original'] ?? ''}' : null,
      needsAccept: j['needs_accept'] == true,
      accepted: j['accepted'] is bool ? j['accepted'] as bool : null,
      notes: ((j['notes'] as List?) ?? const []).map((e) => '$e').toList(),
    );
  }
}

/// What the builder left out, with the reason it tells the customer.
class WeeklyDropped {
  const WeeklyDropped({required this.name, required this.reason, this.text = ''});

  final String name;
  final String reason;
  final String text;

  factory WeeklyDropped.fromJson(Map<String, dynamic> j) => WeeklyDropped(name: '${j['name'] ?? ''}', reason: '${j['reason'] ?? ''}', text: '${j['text'] ?? ''}');
}

/// The week's basket as the server presents it.
class WeeklyOrder {
  const WeeklyOrder({required this.id, required this.week, required this.state, this.total = '', this.savings = '', this.savingsOre = 0, this.lines = const [], this.dropped = const [], this.reviewUntil, this.overCap = false, this.pendingAccept = 0, this.orderIds = const [], this.placedAt});

  final int id;
  final String week;

  /// `draft`, `ready`, `reviewed`, `placed`, `paid`, `cancelled`.
  final String state;
  final String total;
  final String savings;
  final int savingsOre;
  final List<WeeklyLine> lines;
  final List<WeeklyDropped> dropped;
  final String? reviewUntil;
  final bool overCap;
  final int pendingAccept;
  final List<int> orderIds;
  final String? placedAt;

  bool get open => state == 'ready' || state == 'reviewed';

  factory WeeklyOrder.fromJson(Map<String, dynamic> j) => WeeklyOrder(
    id: (j['id'] as num?)?.toInt() ?? 0,
    week: '${j['week'] ?? ''}',
    state: '${j['state'] ?? ''}',
    total: _display(j['total']),
    savings: _display(j['savings']),
    savingsOre: j['savings'] is Map ? ((j['savings'] as Map)['amount_ore'] as num?)?.toInt() ?? 0 : 0,
    lines: ((j['lines'] as List?) ?? const []).whereType<Map>().map((e) => WeeklyLine.fromJson(e.cast<String, dynamic>())).toList(),
    dropped: ((j['dropped'] as List?) ?? const []).whereType<Map>().map((e) => WeeklyDropped.fromJson(e.cast<String, dynamic>())).toList(),
    reviewUntil: j['review_until'] as String?,
    overCap: j['over_cap'] == true,
    pendingAccept: (j['pending_accept'] as num?)?.toInt() ?? 0,
    orderIds: ((j['order_ids'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
    placedAt: j['placed_at'] as String?,
  );
}

/// One weekday of the dinner plan (`agent/me/dinner_plans/{week}`).
class DinnerDay {
  const DinnerDay({required this.weekday, required this.name, this.rhythm = false, this.choiceType, this.storeProductId, this.label, this.price});

  final int weekday;
  final String name;
  final bool rhythm;

  /// `restaurant`, `recipe`, `skip` or null (nothing planned).
  final String? choiceType;
  final int? storeProductId;
  final String? label;
  final String? price;

  bool get planned => choiceType == 'restaurant' || choiceType == 'recipe';

  factory DinnerDay.fromJson(Map<String, dynamic> j) => DinnerDay(
    weekday: (j['weekday'] as num?)?.toInt() ?? 0,
    name: '${j['name'] ?? ''}',
    rhythm: j['rhythm'] == true,
    choiceType: j['choice_type'] as String?,
    storeProductId: (j['store_product_id'] as num?)?.toInt(),
    label: j['label'] as String?,
    price: j['price'] == null ? null : _display(j['price']),
  );
}

/// A dish the customer has had delivered before: a dinner candidate.
class DinnerCandidate {
  const DinnerCandidate({required this.storeProductId, required this.name, this.store = '', this.storeId = 0, this.price = ''});

  final int storeProductId;
  final String name;
  final String store;
  final int storeId;
  final String price;

  factory DinnerCandidate.fromJson(Map<String, dynamic> j) => DinnerCandidate(
    storeProductId: (j['store_product_id'] as num?)?.toInt() ?? 0,
    name: '${j['name'] ?? ''}',
    store: '${j['store'] ?? ''}',
    storeId: (j['store_id'] as num?)?.toInt() ?? 0,
    price: _display(j['price']),
  );
}

/// `GET agent/me/weekly`: the week, its basket when built, the list, the plan
/// and the dinner candidates — one read for both steps of the Ark.
class WeeklyView {
  const WeeklyView({this.week = '', this.weekly, this.items = const [], this.plan = const [], this.candidates = const []});

  final String week;
  final WeeklyOrder? weekly;
  final List<ShoppingListItem> items;
  final List<DinnerDay> plan;
  final List<DinnerCandidate> candidates;

  WeeklyView copyWith({WeeklyOrder? weekly, bool clearWeekly = false, List<ShoppingListItem>? items, List<DinnerDay>? plan}) =>
      WeeklyView(week: week, weekly: clearWeekly ? null : weekly ?? this.weekly, items: items ?? this.items, plan: plan ?? this.plan, candidates: candidates);

  factory WeeklyView.fromJson(Map<String, dynamic> j) => WeeklyView(
    week: '${j['week'] ?? ''}',
    weekly: j['weekly'] is Map ? WeeklyOrder.fromJson((j['weekly'] as Map).cast<String, dynamic>()) : null,
    items: ((j['items'] as List?) ?? const []).whereType<Map>().map((e) => ShoppingListItem.fromJson(e.cast<String, dynamic>())).toList(),
    plan: ((j['plan'] as List?) ?? const []).whereType<Map>().map((e) => DinnerDay.fromJson(e.cast<String, dynamic>())).toList(),
    candidates: ((j['candidates'] as List?) ?? const []).whereType<Map>().map((e) => DinnerCandidate.fromJson(e.cast<String, dynamic>())).toList(),
  );
}

/// One store's confirmation on the level-3 checkout (`weekly/{id}/checkout`
/// and each `confirm`): the token the next confirm needs, and where we are.
class WeeklyConfirmation {
  const WeeklyConfirmation({required this.confirmToken, required this.storeId, this.store = '', this.total = '', this.storesTotal = 1, this.storesDone = 0});

  final String confirmToken;
  final int storeId;
  final String store;
  final String total;
  final int storesTotal;
  final int storesDone;

  factory WeeklyConfirmation.fromJson(Map<String, dynamic> j) {
    final c = (j['confirmation'] as Map?)?.cast<String, dynamic>() ?? const {};
    final summary = (c['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WeeklyConfirmation(
      confirmToken: '${c['confirm_token'] ?? ''}',
      storeId: (c['store_id'] as num?)?.toInt() ?? 0,
      store: '${c['store'] ?? ''}',
      total: _display(summary['total']),
      storesTotal: (j['stores_total'] as num?)?.toInt() ?? 1,
      storesDone: (j['stores_done'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `weekly/{id}/confirm`: the order just placed, then the next store's
/// confirmation — or `done` with every order id.
class WeeklyConfirmResult {
  const WeeklyConfirmResult({required this.done, required this.orderId, this.next, this.orders = const [], this.weekly});

  final bool done;
  final int orderId;
  final WeeklyConfirmation? next;
  final List<int> orders;
  final WeeklyOrder? weekly;

  factory WeeklyConfirmResult.fromJson(Map<String, dynamic> j) {
    final placed = (j['placed'] as Map?)?.cast<String, dynamic>() ?? const {};
    final order = (placed['order'] as Map?)?.cast<String, dynamic>() ?? const {};
    final done = j['done'] == true;
    return WeeklyConfirmResult(
      done: done,
      orderId: (order['id'] as num?)?.toInt() ?? 0,
      next: done ? null : WeeklyConfirmation.fromJson(j),
      orders: ((j['orders'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
      weekly: j['weekly'] is Map ? WeeklyOrder.fromJson((j['weekly'] as Map).cast<String, dynamic>()) : null,
    );
  }
}
