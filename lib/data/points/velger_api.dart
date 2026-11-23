import '../../networking/api_base_helper.dart';
import '../../networking/api_constant.dart';
import '../../networking/ops/ops_customer_api.dart';

/// Points plan Step 13 (points spec §7.2, §6.2 baat): Ægil velger and the boat in Vågen.
///
///   POST points/velger/start · points/velger/{id}/accept · points/velger/{id}/decline
///   GET|POST points/boat
class VelgerApi {
  VelgerApi({ApiBaseHelper? helper}) : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic> body = const {}]) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null) return {'status': 0, 'message': 'network'};
    try {
      final json = await _helper.post('api/points/$path?${Uri(queryParameters: auth).query}', body: body);
      return json is Map<String, dynamic> ? json : {'status': 0, 'message': 'error'};
    } catch (_) {
      return {'status': 0, 'message': 'network'};
    }
  }

  /// The offer (`{id, premie {id, name, partner, retail_value_kr …}, points}`) or the refusal code.
  Future<({Map<String, dynamic>? offer, String? error})> start() async {
    final r = await _post('velger/start');
    return r['status'] == 1 ? (offer: (r['offer'] as Map?)?.cast<String, dynamic>(), error: null) : (offer: null, error: '${r['message'] ?? 'error'}');
  }

  Future<String?> accept(int id) async {
    final r = await _post('velger/$id/accept');
    return r['status'] == 1 ? null : '${r['message'] ?? 'error'}';
  }

  /// The next offer, or `returned: true` when the points came back.
  Future<({Map<String, dynamic>? offer, bool returned, String? error})> decline(int id) async {
    final r = await _post('velger/$id/decline');
    if (r['status'] != 1) return (offer: null, returned: false, error: '${r['message'] ?? 'error'}');
    return (offer: (r['offer'] as Map?)?.cast<String, dynamic>(), returned: r['returned'] == true, error: null);
  }

  /// `GET points/velger`: what one pick costs and whether it can be used now (null offline).
  Future<({int points, bool available})?> pris() async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final json = await _helper.get('api/points/velger?${Uri(queryParameters: auth).query}');
      if (json is! Map || json['status'] != 1) return null;
      return (points: (json['points'] as num?)?.toInt() ?? 0, available: json['available'] == true);
    } catch (_) {
      return null;
    }
  }

  Future<({String? name, String? state, bool shown})?> boat() async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return null;
    try {
      final json = await _helper.get('api/points/boat?${Uri(queryParameters: auth).query}');
      final b = json is Map ? json['boat'] as Map? : null;
      return b == null ? null : (name: b['name'] as String?, state: b['state'] as String?, shown: b['shown'] == true);
    } catch (_) {
      return null;
    }
  }

  /// Null when saved (waits for review); else the code (BOAT_NAME_INVALID …).
  Future<String?> nameBoat(String name) async {
    final r = await _post('boat', {'name': name});
    return r['status'] == 1 ? null : '${r['message'] ?? 'error'}';
  }
}
