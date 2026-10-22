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
}
