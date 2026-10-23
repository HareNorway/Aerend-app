import 'package:dio/dio.dart' show MultipartFile;

import '../api_base_helper.dart';
import 'ops_customer_api.dart';

/// One line of the order's chat with the courier
/// (`GET api/customer/orders/{id}/messages`).
class CusMelding {
  const CusMelding({required this.fraMeg, required this.tekst, required this.at});

  /// The customer's own line (`from: customer`); otherwise the courier's.
  final bool fraMeg;
  final String tekst;
  final DateTime? at;

  factory CusMelding.fromJson(Map<String, dynamic> j) => CusMelding(
    fraMeg: j['from'] == 'customer',
    tekst: '${j['text'] ?? ''}',
    at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal(),
  );
}

/// One Varsler item (`GET api/customer/notifications`, Customer Step 3).
class CusVarsel {
  const CusVarsel({
    required this.key,
    required this.type,
    required this.muteKey,
    required this.kind,
    required this.sender,
    required this.title,
    required this.body,
    required this.at,
    this.action,
    this.deepLink,
    this.orderId,
    this.storeId,
    this.photos = const [],
    this.rich = false,
    this.read = false,
    this.actionId,
    this.conversationId,
    this.issueId,
  });

  /// Customer Step 7: the Ægil receipt behind an «Angre» card.
  final int? actionId;

  /// Customer Step 10: the Hjelp thread «Svar {navn}» continues, and the case behind an issue card.
  final int? conversationId;
  final int? issueId;

  /// `n:<id>` / `b:<id>`.
  final String key;

  /// The design's card kind (`ordre`, `valg`, `tilbud`, `nybyen`, `ai`, …).
  final String type;

  /// What «Ikke slike varsler» mutes.
  final String muteKey;
  final String kind;
  final String sender;
  final String title;
  final String body;
  final DateTime at;

  /// A button on the card («Velg»).
  final String? action;
  final String? deepLink;
  final int? orderId;
  final int? storeId;
  final List<String> photos;

  /// «Ny på Ærend»: photos + «Følg» / «Se meny».
  final bool rich;
  final bool read;

  factory CusVarsel.fromJson(Map<String, dynamic> j) => CusVarsel(
    key: '${j['key'] ?? ''}',
    type: '${j['type'] ?? 'aerend'}',
    muteKey: '${j['mute_key'] ?? j['type'] ?? ''}',
    kind: '${j['kind'] ?? ''}',
    sender: '${j['sender'] ?? ''}',
    title: '${j['title'] ?? ''}',
    body: '${j['body'] ?? ''}',
    at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal() ?? DateTime.now(),
    action: j['action'] as String?,
    deepLink: j['deep_link'] as String?,
    orderId: (j['order_id'] as num?)?.toInt(),
    storeId: (j['store_id'] as num?)?.toInt(),
    photos: [for (final p in (j['photos'] as List? ?? const [])) '$p'],
    rich: j['rich'] == true,
    read: j['read'] == true,
    actionId: (j['action_id'] as num?)?.toInt(),
    conversationId: (j['conversation_id'] as num?)?.toInt(),
    issueId: (j['issue_id'] as num?)?.toInt(),
  );
}

// ── Customer Step 10: «Noe galt med bestillingen?» (C2) ─────────────────────

/// The courier's proof at delivery (design C2.7: «Budets bilde · 18:19 · ved døren»).
class CusProof {
  const CusProof({this.type, this.photoUrl, this.time, this.label = '', this.recipientName, this.pinVerified = false, this.courier = ''});

  final String? type;
  final String? photoUrl;

  /// «18:19» (Oslo).
  final String? time;

  /// «Levert ved døren», «Levert til Kari», «Levert med kode».
  final String label;
  final String? recipientName;
  final bool pinVerified;

  /// The courier's first name at the time the issue was filed.
  final String courier;

  factory CusProof.fromJson(Map<String, dynamic> j) => CusProof(
    type: j['type'] as String?,
    photoUrl: j['photo_url'] as String?,
    time: j['time'] as String?,
    label: '${j['label'] ?? ''}',
    recipientName: j['recipient_name'] as String?,
    pinVerified: j['pin_verified'] == true,
    courier: '${j['courier'] ?? ''}',
  );
}

/// A person's answer on an issue («— Mari, Ærend»).
class CusIssueReply {
  const CusIssueReply({required this.text, required this.by, this.at});

  final String text;
  final String by;
  final DateTime? at;
}

/// An issue on a delivered order — `POST|GET customer/orders/{id}/issue`.
class CusIssue {
  const CusIssue({
    required this.id,
    required this.orderId,
    required this.orderCode,
    required this.caseRef,
    required this.type,
    required this.typeLabel,
    required this.state,
    required this.outcome,
    required this.title,
    required this.sub,
    required this.statusText,
    this.items = const [],
    this.text,
    this.photoUrl,
    this.resolution,
    this.reason,
    this.amountOre,
    this.amountDisplay,
    this.slaMinutes = 30,
    this.answerBy,
    this.proof,
    this.reply,
    this.canReopen = false,
    this.reopenCount = 0,
    this.conversationId,
    this.createdAt,
    this.resolvedAt,
    this.already = false,
  });

  final int id;
  final int orderId;
  final String orderCode;

  /// «Æ-42K-1».
  final String caseRef;
  final String type;
  final String typeLabel;

  /// `open` · `escalated` · `reopened` · `resolved`.
  final String state;

  /// `resolved` (auto credit, C2.5) · `reviewing` (C2.6) · `not_delivered` (C2.7) · `reopened` · `approved` (C2.9) · `denied` (C2.10).
  final String outcome;
  final String title;
  final String sub;

  /// The one line on the order («Vi ser på det · svar innen 30 min», «Løst · 89 kr på saldoen»).
  final String statusText;
  final List<String> items;
  final String? text;
  final String? photoUrl;
  final String? resolution;
  final String? reason;
  final int? amountOre;
  final String? amountDisplay;
  final int slaMinutes;

  /// «18:52» (Oslo) — when a person answers by.
  final String? answerBy;
  final CusProof? proof;
  final CusIssueReply? reply;
  final bool canReopen;
  final int reopenCount;
  final int? conversationId;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  /// C2.8: the case was already open; this is it.
  final bool already;

  bool get open => state == 'open' || state == 'escalated' || state == 'reopened';
  bool get loest => state == 'resolved';

  factory CusIssue.fromJson(Map<String, dynamic> j) => CusIssue(
    id: (j['id'] as num?)?.toInt() ?? 0,
    orderId: (j['order_id'] as num?)?.toInt() ?? 0,
    orderCode: '${j['order_code'] ?? ''}',
    caseRef: '${j['case_ref'] ?? ''}',
    type: '${j['type'] ?? 'other'}',
    typeLabel: '${j['type_label'] ?? ''}',
    state: '${j['state'] ?? 'open'}',
    outcome: '${j['outcome'] ?? 'reviewing'}',
    title: '${j['title'] ?? ''}',
    sub: '${j['sub'] ?? ''}',
    statusText: '${j['status_text'] ?? ''}',
    items: [for (final x in (j['items'] as List? ?? const [])) '$x'],
    text: j['text'] as String?,
    photoUrl: j['photo_url'] as String?,
    resolution: j['resolution'] as String?,
    reason: j['reason'] as String?,
    amountOre: ((j['amount'] as Map?)?['ore'] as num?)?.toInt(),
    amountDisplay: (j['amount'] as Map?)?['display'] as String?,
    slaMinutes: (j['sla_minutes'] as num?)?.toInt() ?? 30,
    answerBy: j['answer_by'] as String?,
    proof: j['proof'] is Map ? CusProof.fromJson(Map<String, dynamic>.from(j['proof'] as Map)) : null,
    reply: j['reply'] is Map ? CusIssueReply(text: '${(j['reply'] as Map)['text'] ?? ''}', by: '${(j['reply'] as Map)['by'] ?? ''}', at: DateTime.tryParse('${(j['reply'] as Map)['at'] ?? ''}')?.toLocal()) : null,
    canReopen: j['can_reopen'] == true,
    reopenCount: (j['reopen_count'] as num?)?.toInt() ?? 0,
    conversationId: (j['conversation_id'] as num?)?.toInt(),
    createdAt: DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal(),
    resolvedAt: DateTime.tryParse('${j['resolved_at'] ?? ''}')?.toLocal(),
    already: j['already'] == true,
  );
}

/// The order's issue window and its newest issue — `GET customer/orders/{id}/issue`.
class CusIssueStatus {
  const CusIssueStatus({required this.delivered, required this.canReport, this.windowEndsAt, this.slaMinutes = 30, this.types = const [], this.issue, this.proof});

  final bool delivered;

  /// Inside `cus.issue.window_hours` after delivery: the entry row shows.
  final bool canReport;
  final DateTime? windowEndsAt;
  final int slaMinutes;

  /// The chips, in the design's order.
  final List<({String key, String label})> types;
  final CusIssue? issue;
  final CusProof? proof;

  factory CusIssueStatus.fromJson(Map<String, dynamic> j) => CusIssueStatus(
    delivered: j['delivered'] == true,
    canReport: j['can_report'] == true,
    windowEndsAt: DateTime.tryParse('${j['window_ends_at'] ?? ''}')?.toLocal(),
    slaMinutes: (j['sla_minutes'] as num?)?.toInt() ?? 30,
    types: [for (final t in (j['types'] as List? ?? const []).whereType<Map>()) (key: '${t['key']}', label: '${t['label']}')],
    issue: j['issue'] is Map ? CusIssue.fromJson(Map<String, dynamic>.from(j['issue'] as Map)) : null,
    proof: j['proof'] is Map ? CusProof.fromJson(Map<String, dynamic>.from(j['proof'] as Map)) : null,
  );
}

/// One page of the inbox.
class CusInbox {
  const CusInbox({required this.items, required this.unread, required this.mutes, this.nextCursor});

  final List<CusVarsel> items;
  final int unread;
  final List<String> mutes;
  final String? nextCursor;
}

/// Min bio as the server keeps it (`GET api/customer/me/bio`, Customer Step 6):
/// the chips as codes, the text, the consent (version, words, when) and the
/// labels and disclaimer the sheet shows.
class CusBio {
  const CusBio({
    this.allergener = const [],
    this.unngaar = const [],
    this.annet = const [],
    this.kost = const [],
    this.annetKost = const [],
    this.streng = const [],
    this.liker = const [],
    this.ikke = const [],
    this.tekst = '',
    this.ingenAllergier = false,
    this.samtykkeVersjon = 'v1',
    this.samtykkeTekst = '',
    this.samtykkeTekstEn = '',
    this.samtykket,
    this.samtykkeGjeldende = false,
    this.oppdatert,
    this.kjent = false,
    this.eldre = false,
    this.ansvar = '',
    this.ansvarEn = '',
  });

  /// Codes (`nuts`, `milk` …).
  final List<String> allergener, unngaar;

  /// «Annet»: the customer's own allergen words.
  final List<String> annet;

  /// Preference codes (`halal`, `vegetarian` …) and the customer's own diet words.
  final List<String> kost, annetKost;

  /// The preference codes marked strict.
  final List<String> streng;

  /// Likes and dislikes: `value` (as stored) and `label`.
  final List<({String value, String label})> liker, ikke;
  final String tekst;
  final bool ingenAllergier;
  final String samtykkeVersjon, samtykkeTekst, samtykkeTekstEn;

  /// When the customer consented, and whether to the current text.
  final DateTime? samtykket;
  final bool samtykkeGjeldende;
  final DateTime? oppdatert;

  /// The bio holds anything at all.
  final bool kjent;

  /// Chips from before Step 6 that saving moves into the bio.
  final bool eldre;
  final String ansvar, ansvarEn;

  static List<String> _l(Object? v) => [for (final x in (v as List? ?? const [])) '$x'];
  static List<({String value, String label})> _t(Object? v) => [
    for (final m in (v as List? ?? const []).whereType<Map>()) (value: '${m['value'] ?? ''}', label: '${m['label'] ?? m['value'] ?? ''}'),
  ];

  factory CusBio.fromJson(Map<String, dynamic> j) {
    final c = j['consent'] is Map ? (j['consent'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    return CusBio(
      allergener: _l(j['allergens']),
      unngaar: _l(j['avoids']),
      annet: _l(j['other']),
      kost: _l(j['preferences']),
      annetKost: _l(j['other_preferences']),
      streng: _l(j['strict']),
      liker: _t(j['likes']),
      ikke: _t(j['dislikes']),
      tekst: '${j['text'] ?? ''}',
      ingenAllergier: j['no_allergies'] == true,
      samtykkeVersjon: '${c['version'] ?? 'v1'}',
      samtykkeTekst: '${c['text'] ?? ''}',
      samtykkeTekstEn: '${c['text_en'] ?? ''}',
      samtykket: DateTime.tryParse('${c['given_at'] ?? ''}')?.toLocal(),
      samtykkeGjeldende: c['current'] == true,
      oppdatert: DateTime.tryParse('${j['updated_at'] ?? ''}')?.toLocal(),
      kjent: j['known'] == true,
      eldre: j['legacy'] == true,
      ansvar: '${j['disclaimer'] ?? ''}',
      ansvarEn: '${j['disclaimer_en'] ?? ''}',
    );
  }
}

/// A chip `bio/parse` proposes from the text (nothing is stored until tapped).
class CusBioForslag {
  const CusBioForslag({required this.liste, required this.kode, required this.raw});

  /// `allergen`, `avoid` or `preference`.
  final String liste;
  final String kode;

  /// The customer's own words it came from.
  final String raw;
}

/// The Customer plan's own routes (`routes/api_customer_agents.php`, `cus.*`):
/// the thank-you note, the courier chat read, «Husk døra mi» (Step 2), the
/// Varsler inbox (Step 3), Min bio (Step 6) — later issues, gifts, scans and assistant links. Same auth as
/// [OpsCustomerApi] (`user_id` + `access_token`); every call answers null /
/// empty / false on any failure, so a screen falls back to its plain state.
class CusApi {
  CusApi({ApiBaseHelper? helper}) : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  static const String _base = 'api/customer/';

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final res = await _helper.postAllowClientError('$_base$path', body: {...auth, ...body});
      final json = res.data;
      return json is Map<String, dynamic> && res.statusCode < 300 ? json : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _get(String path, [Map<String, String> query = const {}]) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final q = Uri(queryParameters: {...auth, ...query}).query;
      final json = await _helper.get('$_base$path?$q');
      return json is Map<String, dynamic> && json['status'] == 1 ? json : null;
    } catch (_) {
      return null;
    }
  }

  // ── Varsler inbox (Step 3) ───────────────────────────────────────────────

  /// A page of Varsler, newest first; null when the inbox is off or offline
  /// (the panel then shows its older sources).
  Future<CusInbox?> varsler({String? cursor, int limit = 30}) async {
    final j = await _get('notifications', {'limit': '$limit', if (cursor != null) 'cursor': cursor});
    if (j == null) return null;
    return CusInbox(
      items: [for (final m in (j['items'] as List? ?? const []).whereType<Map>()) CusVarsel.fromJson(m.cast<String, dynamic>())],
      unread: (j['unread'] as num?)?.toInt() ?? 0,
      mutes: [for (final m in (j['mutes'] as List? ?? const [])) '$m'],
      nextCursor: j['next_cursor'] as String?,
    );
  }

  /// The bells' number; null when the inbox is off or offline.
  Future<int?> varslerUleste() async => ((await _get('notifications/unread-count'))?['unread'] as num?)?.toInt();

  /// Read (after about a second on screen).
  Future<bool> varselLest(String key) async => (await _post('notifications/$key/read', const {}))?['status'] == 1;

  Future<bool> varslerAlleLest() async => (await _post('notifications/read-all', const {}))?['status'] == 1;

  /// «Fjern»; [angre] puts it back.
  Future<bool> varselFjern(String key, {bool angre = false}) async =>
      (await _post('notifications/$key/dismiss', {if (angre) 'restore': 1}))?['status'] == 1;

  /// «Ikke slike varsler» / a Meg switch: [key] is a card kind or `premier` / `nivaa` / `liga`. The mutes after the change, or null.
  Future<List<String>?> varselDemp(String key, {bool av = true}) async {
    final j = await _post('notifications/mute', {'key': key, 'muted': av});
    return j == null ? null : [for (final m in (j['mutes'] as List? ?? const [])) '$m'];
  }

  /// «Takk til budet»: stores the note (once per delivered order). True when
  /// it is stored now or was already.
  Future<bool> takk(int orderId, String tekst) async => (await _post('orders/$orderId/thanks', {'text': tekst}))?['status'] == 1;

  /// The order's chat with the courier, oldest first; empty when none or offline.
  Future<List<CusMelding>> meldinger(int orderId) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return const [];
    try {
      final q = Uri(queryParameters: auth).query;
      final json = await _helper.get('${_base}orders/$orderId/messages?$q');
      if (json is! Map || json['status'] != 1) return const [];
      return [for (final m in (json['messages'] as List? ?? const []).whereType<Map>()) CusMelding.fromJson(m.cast<String, dynamic>())];
    } catch (_) {
      return const [];
    }
  }

  /// «Husk døra mi» on (door profiles for every saved address, from their door
  /// notes) or off (every profile removed). True on success.
  Future<bool> dorProfil({required bool samtykke, int? adresseId, String? dorLinje}) async =>
      (await _post('me/door-profile', {'consent': samtykke, if (adresseId != null) 'address_id': adresseId, if (dorLinje != null) 'door_line': dorLinje}))?['status'] == 1;

  // ── Min bio (Step 6) ─────────────────────────────────────────────────────

  /// The bio, or null while `cus.bio` is off or offline (the sheet then keeps
  /// to Ægil's memory, the Bergen Step 6 path).
  Future<CusBio?> bio() async {
    final j = await _get('me/bio');
    return j?['bio'] is Map ? CusBio.fromJson((j!['bio'] as Map).cast<String, dynamic>()) : null;
  }

  /// Saves the bio. [samtykke]: the customer ticked the consent box now. The
  /// bio after saving, or the refusal's code (`CONSENT_REQUIRED`,
  /// `CONSENT_VERSION`, `BIO_INVALID`, `offline`).
  Future<({CusBio? bio, String? feil})> bioLagre(Map<String, dynamic> kropp, {bool samtykke = false, String versjon = 'v1'}) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return (bio: null, feil: 'offline');
    try {
      final res = await _helper.postAllowClientError('${_base}me/bio', body: {...auth, ...kropp, if (samtykke) 'consent': true, if (samtykke) 'consent_version': versjon});
      final j = res.data;
      if (j is Map && res.statusCode < 300 && j['bio'] is Map) return (bio: CusBio.fromJson((j['bio'] as Map).cast<String, dynamic>()), feil: null);
      return (bio: null, feil: j is Map ? '${j['error'] ?? 'feil'}' : 'feil');
    } catch (_) {
      return (bio: null, feil: 'offline');
    }
  }

  /// «Slett bioen»: the consent withdrawn, the chips, the text and Ægil's memory of them gone. True on success.
  Future<bool> bioSlett() async => (await _post('me/bio/delete', const {}))?['deleted'] == true;

  /// The chips the text points to ([samtykke]: ticked on the sheet now). `kilde` is `model` when Ærend AI
  /// read it, `rules` when the server used the same reader as the app; null offline / without consent.
  Future<({String kilde, List<CusBioForslag> forslag})?> bioTolk(String tekst, {bool samtykke = false}) async {
    final j = await _post('me/bio/parse', {'text': tekst, if (samtykke) 'consent': true});
    if (j == null) return null;
    return (
      kilde: '${j['source'] ?? 'rules'}',
      forslag: [
        for (final m in (j['proposals'] as List? ?? const []).whereType<Map>())
          CusBioForslag(liste: '${m['list'] ?? ''}', kode: '${m['code'] ?? ''}', raw: '${m['raw'] ?? ''}'),
      ],
    );
  }

  /// «Vis likevel» was tapped (a count, for the rate).
  Future<void> bioVistLikevel() async => await _post('me/bio/shown-anyway', const {});

  // ── «Noe galt med bestillingen?» (Step 10, C2) ───────────────────────────

  /// The window, the newest issue and the courier's proof; null when the
  /// surface is off (`ISSUE_OFF`), the order is not the customer's, or offline
  /// — the caller then shows the plain three-step sheet.
  Future<CusIssueStatus?> issueStatus(int orderId) async {
    final j = await _get('orders/$orderId/issue');
    return j == null ? null : CusIssueStatus.fromJson(j);
  }

  /// Files the issue (the chip, one line, an optional photo). `feil` is the
  /// server's code when it refused (`ISSUE_WINDOW_CLOSED`, `ISSUE_NOT_DELIVERED`,
  /// `INVALID`); both null when offline.
  Future<({CusIssue? issue, String? feil})> issueOpen(int orderId, {String? type, String text = '', String? photoPath, bool append = false}) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return (issue: null, feil: null);
    final body = <String, dynamic>{...auth, if (type != null) 'type': type, if (text.trim().isNotEmpty) 'text': text.trim(), if (append) 'append': 1};
    try {
      if (photoPath != null) {
        final json = await _helper.postFormData('${_base}orders/$orderId/issue', body: {...body, 'photo': await MultipartFile.fromFile(photoPath, filename: 'sak.jpg')});
        return json is Map<String, dynamic> && json['issue'] is Map ? (issue: CusIssue.fromJson(Map<String, dynamic>.from(json['issue'] as Map)), feil: null) : (issue: null, feil: '${json is Map ? json['error'] ?? 'FEIL' : 'FEIL'}');
      }
      final res = await _helper.postAllowClientError('${_base}orders/$orderId/issue', body: body);
      final json = res.data;
      if (json is Map<String, dynamic> && res.statusCode < 300 && json['issue'] is Map) {
        return (issue: CusIssue.fromJson(Map<String, dynamic>.from(json['issue'] as Map)), feil: null);
      }
      return (issue: null, feil: json is Map ? '${json['error'] ?? 'FEIL'}' : 'FEIL');
    } catch (_) {
      return (issue: null, feil: null);
    }
  }

  /// The customer's issues, newest first; empty offline.
  Future<List<CusIssue>> issues() async {
    final j = await _get('issues');
    return [for (final m in (j?['issues'] as List? ?? const []).whereType<Map>()) CusIssue.fromJson(Map<String, dynamic>.from(m))];
  }

  /// C2.8 «Legg til i saken».
  Future<CusIssue?> issueAppend(int id, String text) async {
    final j = await _post('issues/$id/append', {'text': text});
    return j?['issue'] is Map ? CusIssue.fromJson(Map<String, dynamic>.from(j!['issue'] as Map)) : null;
  }

  /// «Ikke løst»: back to a person.
  Future<CusIssue?> issueReopen(int id, {String? text}) async {
    final j = await _post('issues/$id/reopen', {if (text != null && text.trim().isNotEmpty) 'text': text.trim()});
    return j?['issue'] is Map ? CusIssue.fromJson(Map<String, dynamic>.from(j!['issue'] as Map)) : null;
  }
  // ── AI assistants (Customer Step 13 backend, Step 14 screens) ─────────────

  /// The assistants a customer can link (`GET customer/ai/clients`).
  Future<List<CusAiClient>> aiClients() async {
    final j = await _get('ai/clients');
    return [for (final m in (j?['clients'] as List? ?? const []).whereType<Map>()) CusAiClient.fromJson(m.cast<String, dynamic>())];
  }

  /// A new «ÆR-7K2Q» for [clientId] (`POST customer/ai/link-codes`); the
  /// in-app consent's choices ride on the code (D-K15).
  Future<CusAiKode?> aiLinkCode({String? clientId, CusAiPrefs? prefs}) async {
    final j = await _post('ai/link-codes', {
      if (clientId != null) 'client_id': clientId,
      if (prefs != null) ...prefs.toJson(),
    });
    return j == null ? null : CusAiKode.fromJson(j);
  }

  /// `pending` | `linked` | `expired` for the app's «Venter på at {AI} bruker koden …».
  Future<CusAiKode?> aiLinkCodeStatus(String code) async {
    final j = await _get('ai/link-codes/${Uri.encodeComponent(code)}');
    return j == null ? null : CusAiKode.fromJson(j);
  }

  /// «Koblede assistenter» (`GET customer/ai/links`); null when off or offline.
  Future<List<CusAiLink>?> aiLinks() async {
    final j = await _get('ai/links');
    if (j == null) return null;
    return [for (final m in (j['links'] as List? ?? const []).whereType<Map>()) CusAiLink.fromJson(m.cast<String, dynamic>())];
  }

  /// One link with its activity (`GET customer/ai/links/{id}`).
  Future<({CusAiLink link, List<CusAiAktivitet> aktivitet})?> aiLink(int id) async {
    final j = await _get('ai/links/$id');
    if (j == null || j['link'] is! Map) return null;
    return (
      link: CusAiLink.fromJson(Map<String, dynamic>.from(j['link'] as Map)),
      aktivitet: [for (final m in (j['activity'] as List? ?? const []).whereType<Map>()) CusAiAktivitet.fromJson(m.cast<String, dynamic>())],
    );
  }

  /// Scopes / caps / payment / address / Min bio (`PUT customer/ai/links/{id}` — sent as a POST with `_method`).
  Future<CusAiLink?> aiLinkUpdate(int id, {List<String>? scopes, int? capPerOrderKr, int? capPerDayKr, String? paymentPref, String? addressPref, bool? shareBio}) async {
    final j = await _post('ai/links/$id', {
      '_method': 'PUT',
      if (scopes != null) 'scopes': scopes,
      if (capPerOrderKr != null) 'cap_per_order_kr': capPerOrderKr,
      if (capPerDayKr != null) 'cap_per_day_kr': capPerDayKr,
      if (paymentPref != null) 'payment_pref': paymentPref,
      if (addressPref != null) 'address_pref': addressPref,
      if (shareBio != null) 'share_bio': shareBio,
    });
    return j?['link'] is Map ? CusAiLink.fromJson(Map<String, dynamic>.from(j!['link'] as Map)) : null;
  }

  /// «Koble fra» (`DELETE customer/ai/links/{id}`); every token of the link dies.
  Future<bool> aiLinkRevoke(int id) async => (await _post('ai/links/$id', const {'_method': 'DELETE'}))?['status'] == 1;

  /// «Koble fra alle».
  Future<int?> aiLinksRevokeAll() async => ((await _post('ai/links', const {'_method': 'DELETE'}))?['revoked'] as num?)?.toInt();

  /// The newest open request (`GET customer/ai/requests`): the banner after a cold start.
  Future<CusAiRequest?> aiRequestLatest() async {
    final j = await _get('ai/requests');
    return j?['request'] is Map ? CusAiRequest.fromJson(Map<String, dynamic>.from(j!['request'] as Map)) : null;
  }

  /// One request («Handlekurv fra assistent»); null when unknown, off or offline.
  Future<CusAiRequest?> aiRequest(String id) async {
    final j = await _get('ai/requests/${Uri.encodeComponent(id)}');
    return j?['request'] is Map ? CusAiRequest.fromJson(Map<String, dynamic>.from(j!['request'] as Map)) : null;
  }

  /// «Bekreft og betal»: the order and how to pay it; the backend's code on a refusal
  /// (`quote_expired`, `token_used`, `over_limit` …).
  Future<({CusAiOrder? order, String? feil, CusAiRequest? request})> aiRequestConfirm(String id, {String payment = 'vipps'}) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return (order: null, feil: null, request: null);
    try {
      final res = await _helper.postAllowClientError('${_base}ai/requests/${Uri.encodeComponent(id)}/confirm', body: {...auth, 'payment': payment});
      final j = res.data;
      if (j is! Map<String, dynamic>) return (order: null, feil: null, request: null);
      final req = j['request'] is Map ? CusAiRequest.fromJson(Map<String, dynamic>.from(j['request'] as Map)) : null;
      if (res.statusCode >= 300 || j['order'] is! Map) return (order: null, feil: '${j['error'] ?? 'feil'}', request: req);
      return (order: CusAiOrder.fromJson(Map<String, dynamic>.from(j['order'] as Map), Map<String, dynamic>.from((j['payment'] as Map?) ?? const {})), feil: null, request: req);
    } catch (_) {
      return (order: null, feil: null, request: null);
    }
  }

  /// «Avvis» — nothing is ordered; the assistant's token dies.
  Future<CusAiRequest?> aiRequestDecline(String id) async {
    final j = await _post('ai/requests/${Uri.encodeComponent(id)}/decline', const {});
    return j?['request'] is Map ? CusAiRequest.fromJson(Map<String, dynamic>.from(j!['request'] as Map)) : null;
  }

  /// A fresh quote on the same cart (`removeLineId` drops a sold-out line); the old request is replaced.
  Future<CusAiRequest?> aiRequestRequote(String id, {int? removeLineId}) async {
    final j = await _post('ai/requests/${Uri.encodeComponent(id)}/requote', {if (removeLineId != null) 'remove_line_id': removeLineId});
    return j?['request'] is Map ? CusAiRequest.fromJson(Map<String, dynamic>.from(j!['request'] as Map)) : null;
  }

  /// «Sett meg på ventelisten».
  Future<String?> aiRequestWaitlist(String id) async => (await _post('ai/requests/${Uri.encodeComponent(id)}/waitlist', const {}))?['waitlist_id'] as String?;

  /// `order id → assistant` for «Via {AI}» on Ordrer and Kvittering; empty when off or offline.
  Future<Map<int, CusAiVia>> aiOrdersVia() async {
    final j = await _get('ai/orders-via');
    final via = j?['via'];
    if (via is! Map) return const {};
    return {for (final e in via.entries) if (e.value is Map && int.tryParse('${e.key}') != null) int.parse('${e.key}'): CusAiVia.fromJson(Map<String, dynamic>.from(e.value as Map))};
  }
}


// ── AI assistants (Customer Steps 13–14) ─────────────────────────────────────

/// A money amount as the commerce layer sends it.
class CusMoney {
  const CusMoney({this.ore = 0, this.display = ''});
  final int ore;
  final String display;
  static CusMoney? maybe(dynamic m) => m is Map ? CusMoney(ore: (m['amount_ore'] as num?)?.toInt() ?? 0, display: '${m['display'] ?? ''}') : null;
  static CusMoney of(dynamic m) => maybe(m) ?? const CusMoney();
  int get kr => ore ~/ 100;
}

/// A registered assistant vendor (`ai/clients`).
class CusAiClient {
  const CusAiClient({required this.clientId, required this.name, required this.vendor, this.active = true});
  final String clientId;
  final String name;
  final String vendor;
  final bool active;
  factory CusAiClient.fromJson(Map<String, dynamic> j) => CusAiClient(clientId: '${j['client_id'] ?? ''}', name: '${j['name'] ?? ''}', vendor: '${j['vendor'] ?? 'other'}', active: j['active'] != false);
}

/// The in-app consent's choices (design `aiSamtykke`): ride on the link code and win on the consent page.
class CusAiPrefs {
  const CusAiPrefs({this.scopes = const ['catalog:read', 'cart:write', 'orders:read', 'orders:write', 'profile:read'], this.capPerOrderKr = 500, this.capPerDayKr = 1000, this.paymentPref = 'vipps', this.addressPref = 'home', this.shareBio = false});
  final List<String> scopes;
  final int capPerOrderKr;
  final int capPerDayKr;
  final String paymentPref;
  final String addressPref;
  final bool shareBio;
  CusAiPrefs copyWith({List<String>? scopes, int? capPerOrderKr, int? capPerDayKr, String? paymentPref, String? addressPref, bool? shareBio}) => CusAiPrefs(
    scopes: scopes ?? this.scopes, capPerOrderKr: capPerOrderKr ?? this.capPerOrderKr, capPerDayKr: capPerDayKr ?? this.capPerDayKr,
    paymentPref: paymentPref ?? this.paymentPref, addressPref: addressPref ?? this.addressPref, shareBio: shareBio ?? this.shareBio,
  );
  Map<String, dynamic> toJson() => {'scopes': scopes, 'cap_per_order_kr': capPerOrderKr, 'cap_per_day_kr': capPerDayKr, 'payment_pref': paymentPref, 'address_pref': addressPref, 'share_bio': shareBio};
}

/// An app link code («ÆR-7K2Q») and its status.
class CusAiKode {
  const CusAiKode({required this.code, required this.raw, required this.status, this.expiresAt, this.minutes = 10, this.linkUrl, this.authorizeUrl, this.link});
  final String code;
  final String raw;
  /// `pending` | `linked` | `expired`
  final String status;
  final DateTime? expiresAt;
  final int minutes;
  final String? linkUrl;
  final String? authorizeUrl;
  final CusAiLink? link;
  factory CusAiKode.fromJson(Map<String, dynamic> j) => CusAiKode(
    code: '${j['code'] ?? ''}', raw: '${j['raw'] ?? ''}', status: '${j['link_status'] ?? 'pending'}', expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}')?.toLocal(),
    minutes: (j['minutes'] as num?)?.toInt() ?? 10, linkUrl: j['link_url'] as String?, authorizeUrl: j['authorize_url'] as String?,
    link: j['link'] is Map ? CusAiLink.fromJson(Map<String, dynamic>.from(j['link'] as Map)) : null,
  );
}

/// One permission row of a link (scope, on, locked, the design's words).
class CusAiRett {
  const CusAiRett({required this.scope, required this.on, required this.locked, required this.title, required this.line, this.lockedLabel});
  final String scope;
  final bool on;
  final bool locked;
  final String title;
  final String line;
  final String? lockedLabel;
  factory CusAiRett.fromJson(Map<String, dynamic> j) => CusAiRett(scope: '${j['scope'] ?? ''}', on: j['on'] == true, locked: j['locked'] == true, title: '${j['title'] ?? ''}', line: '${j['line'] ?? ''}', lockedLabel: j['locked'] == true ? (j['locked_label'] as String? ?? j['lockedLabel'] as String? ?? (j['scope'] == 'catalog:read' ? 'Alltid på' : 'Påkrevd')) : null);
}

/// «Koblede assistenter»: one link as the app's cards and the detail read it.
class CusAiLink {
  const CusAiLink({
    required this.id, required this.clientId, required this.name, required this.vendor, required this.active, this.scopes = const [], this.permissions = const [],
    this.capPerOrder, this.capPerDay, this.usedToday = const CusMoney(), this.orders = 0, this.paymentPref = 'vipps', this.addressPref = 'home', this.addressId, this.shareBio = false,
    this.grantedAt, this.revokedAt, this.lastUsedAt,
  });
  final int id;
  final String clientId;
  final String name;
  final String vendor;
  final bool active;
  final List<String> scopes;
  final List<CusAiRett> permissions;
  final CusMoney? capPerOrder;
  final CusMoney? capPerDay;
  final CusMoney usedToday;
  final int orders;
  final String paymentPref;
  final String addressPref;
  final int? addressId;
  final bool shareBio;
  final DateTime? grantedAt;
  final DateTime? revokedAt;
  final DateTime? lastUsedAt;
  factory CusAiLink.fromJson(Map<String, dynamic> j) => CusAiLink(
    id: (j['id'] as num?)?.toInt() ?? 0, clientId: '${j['client_id'] ?? ''}', name: '${j['name'] ?? ''}', vendor: '${j['vendor'] ?? 'other'}', active: j['active'] == true,
    scopes: [for (final s in (j['scopes'] as List? ?? const [])) '$s'],
    permissions: [for (final m in (j['permissions'] as List? ?? const []).whereType<Map>()) CusAiRett.fromJson(m.cast<String, dynamic>())],
    capPerOrder: CusMoney.maybe(j['cap_per_order']), capPerDay: CusMoney.maybe(j['cap_per_day']), usedToday: CusMoney.of(j['used_today']), orders: (j['orders'] as num?)?.toInt() ?? 0,
    paymentPref: '${j['payment_pref'] ?? 'vipps'}', addressPref: '${j['address_pref'] ?? 'home'}', addressId: (j['address_id'] as num?)?.toInt(), shareBio: j['share_bio'] == true,
    grantedAt: DateTime.tryParse('${j['granted_at'] ?? ''}')?.toLocal(), revokedAt: DateTime.tryParse('${j['revoked_at'] ?? ''}')?.toLocal(), lastUsedAt: DateTime.tryParse('${j['last_used_at'] ?? ''}')?.toLocal(),
  );
  bool has(String scope) => scopes.contains(scope);
}

/// One line of a link's activity (the tool-call log).
class CusAiAktivitet {
  const CusAiAktivitet({required this.tool, required this.outcome, this.at});
  final String tool;
  final String outcome;
  final DateTime? at;
  factory CusAiAktivitet.fromJson(Map<String, dynamic> j) => CusAiAktivitet(tool: '${j['tool'] ?? ''}', outcome: '${j['outcome'] ?? ''}', at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal());
}

/// A quote line as the request shows it, with its availability now.
class CusAiLinje {
  const CusAiLinje({required this.productId, required this.name, required this.quantity, this.lineId, this.options = const [], this.unitPrice = const CusMoney(), this.lineTotal = const CusMoney(), this.available = true});
  final int productId;
  final int? lineId;
  final String name;
  final int quantity;
  final List<String> options;
  final CusMoney unitPrice;
  final CusMoney lineTotal;
  final bool available;
  factory CusAiLinje.fromJson(Map<String, dynamic> j) => CusAiLinje(
    productId: (j['product_id'] as num?)?.toInt() ?? 0, lineId: (j['line_id'] as num?)?.toInt(), name: '${j['name'] ?? ''}', quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    options: [for (final o in (j['options'] as List? ?? const [])) o is Map ? '${o['name'] ?? o['label'] ?? ''}' : '$o'], unitPrice: CusMoney.of(j['unit_price']), lineTotal: CusMoney.of(j['line_total']), available: j['available'] != false,
  );
}

/// One step of what the assistant did before asking.
class CusAiLogg {
  const CusAiLogg({required this.tool, required this.text, this.at});
  final String tool;
  final String text;
  final DateTime? at;
  factory CusAiLogg.fromJson(Map<String, dynamic> j) => CusAiLogg(tool: '${j['tool'] ?? ''}', text: '${j['text'] ?? ''}', at: DateTime.tryParse('${j['at'] ?? ''}')?.toLocal());
}

/// «Via {AI}» on an order.
class CusAiVia {
  const CusAiVia({required this.name, required this.vendor});
  final String name;
  final String vendor;
  factory CusAiVia.fromJson(Map<String, dynamic> j) => CusAiVia(name: '${j['name'] ?? ''}', vendor: '${j['vendor'] ?? 'other'}');
}

/// The order «Bekreft og betal» created, and how it is paid.
class CusAiOrder {
  const CusAiOrder({required this.id, required this.number, this.total = const CusMoney(), this.paymentMethod = 'vipps', this.paymentStatus = 'pending', this.paymentIntent, this.trackingToken});
  final int id;
  final String number;
  final CusMoney total;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentIntent;
  final String? trackingToken;
  factory CusAiOrder.fromJson(Map<String, dynamic> o, Map<String, dynamic> p) => CusAiOrder(
    id: (o['id'] as num?)?.toInt() ?? 0, number: '${o['number'] ?? ''}', total: CusMoney.of(o['total']), paymentMethod: '${p['method'] ?? 'vipps'}', paymentStatus: '${p['status'] ?? 'pending'}',
    paymentIntent: p['payment_intent'] as String?, trackingToken: o['tracking_token'] as String?,
  );
}

/// «Handlekurv fra assistent» / «Bekreft bestilling»: an assistant's request.
class CusAiRequest {
  const CusAiRequest({
    required this.id, required this.state, required this.assistant, required this.vendor, required this.store, this.storeLine = '', this.log = const [], this.lines = const [],
    this.subtotal = const CusMoney(), this.deliveryFee = const CusMoney(), this.serviceFee = const CusMoney(), this.total = const CusMoney(), this.windowDisplay = '', this.address = '',
    this.deliveryMethod = 'delivery', this.expiresAt, this.secondsLeft = 0, this.capPerOrder, this.overCap = false, this.covered = true, this.waitlistId, this.paymentPref = 'vipps', this.linkId, this.orderId, this.orderCode, this.orderPaid = false, this.createdAt,
  });
  final String id;
  /// `normal` | `utsolgt` | `utlopt` | `dekning` | `confirmed` | `declined` | `replaced`
  final String state;
  final String assistant;
  final String vendor;
  final String store;
  final String storeLine;
  final List<CusAiLogg> log;
  final List<CusAiLinje> lines;
  final CusMoney subtotal;
  final CusMoney deliveryFee;
  final CusMoney serviceFee;
  final CusMoney total;
  final String windowDisplay;
  final String address;
  final String deliveryMethod;
  final DateTime? expiresAt;
  final int secondsLeft;
  final CusMoney? capPerOrder;
  final bool overCap;
  final bool covered;
  final String? waitlistId;
  final String paymentPref;
  final int? linkId;
  final int? orderId;
  final String? orderCode;
  final bool orderPaid;
  final DateTime? createdAt;
  bool get harUtsolgt => lines.any((l) => !l.available);
  factory CusAiRequest.fromJson(Map<String, dynamic> j) {
    final a = j['assistant'] is Map ? j['assistant'] as Map : const {};
    final s = j['store'] is Map ? j['store'] as Map : const {};
    final q = j['quote'] is Map ? j['quote'] as Map : const {};
    final w = q['window'] is Map ? q['window'] as Map : const {};
    final adr = q['address'] is Map ? q['address'] as Map : const {};
    final o = j['order'] is Map ? j['order'] as Map : null;
    return CusAiRequest(
      id: '${j['id'] ?? ''}', state: '${j['state'] ?? 'normal'}', assistant: '${a['name'] ?? 'Assistent'}', vendor: '${a['vendor'] ?? 'other'}', store: '${s['name'] ?? ''}', storeLine: '${s['line'] ?? ''}',
      log: [for (final m in (j['log'] as List? ?? const []).whereType<Map>()) CusAiLogg.fromJson(m.cast<String, dynamic>())],
      lines: [for (final m in (j['lines'] as List? ?? const []).whereType<Map>()) CusAiLinje.fromJson(m.cast<String, dynamic>())],
      subtotal: CusMoney.of(q['subtotal']), deliveryFee: CusMoney.of(q['delivery_fee']), serviceFee: CusMoney.of(q['service_fee']), total: CusMoney.of(q['total']),
      windowDisplay: '${w['display'] ?? ''}', address: '${adr['text'] ?? ''}', deliveryMethod: '${(q['delivery_method'] is Map ? (q['delivery_method'] as Map)['key'] : q['delivery_method']) ?? 'delivery'}',
      expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}')?.toLocal(), secondsLeft: (j['seconds_left'] as num?)?.toInt() ?? 0,
      capPerOrder: CusMoney.maybe(j['cap_per_order']), overCap: j['over_cap'] == true, covered: j['covered'] != false, waitlistId: j['waitlist_id'] as String?,
      paymentPref: '${j['payment_pref'] ?? 'vipps'}', linkId: (j['link_id'] as num?)?.toInt(),
      orderId: o == null ? null : (o['id'] as num?)?.toInt(), orderCode: o == null ? null : '${o['code'] ?? ''}', orderPaid: o?['paid'] == true, createdAt: DateTime.tryParse('${j['created_at'] ?? ''}')?.toLocal(),
    );
  }
}
