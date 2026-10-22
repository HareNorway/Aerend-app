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
  });

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
}
