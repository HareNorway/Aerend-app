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

/// The Customer plan's own routes (`routes/api_customer_agents.php`, `cus.*`):
/// the thank-you note, the courier chat read, «Husk døra mi» (Step 2), the
/// Varsler inbox (Step 3) — later bio, issues, gifts, scans and assistant links. Same auth as
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
}
