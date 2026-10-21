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

/// The Customer plan's own routes (`routes/api_customer_agents.php`, `cus.*`):
/// the thank-you note, the courier chat read, «Husk døra mi» (Step 2) — later
/// the inbox, bio, issues, gifts, scans and assistant links. Same auth as
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
