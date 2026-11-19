import '../../networking/api_base_helper.dart';
import '../../networking/api_constant.dart';
import '../../networking/ops/ops_customer_api.dart';

/// A premiekupong from Ukens led (points plan Step 12, points spec §11.2): one premie up to [shelf] for 0 points.
class PremieVoucher {
  const PremieVoucher({required this.id, required this.maxShelf, this.shelf, this.validUntil});

  final int id;
  final int maxShelf;
  final String? shelf;
  final DateTime? validUntil;

  factory PremieVoucher.fromJson(Map<String, dynamic> j) => PremieVoucher(
        id: (j['id'] as num?)?.toInt() ?? 0,
        maxShelf: (j['max_shelf'] as num?)?.toInt() ?? 0,
        shelf: j['shelf'] as String?,
        validUntil: DateTime.tryParse('${j['valid_until'] ?? ''}'),
      );
}

/// `GET /points/premie_vouchers`, `POST /points/premie_vouchers/{id}/claim`.
class VoucherApi {
  VoucherApi({ApiBaseHelper? helper}) : _helper = helper ?? ApiBaseHelper(baseUrl: BaseUrl.domain);

  final ApiBaseHelper _helper;

  Future<List<PremieVoucher>> list() async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null || !OpsCustomerApi.networkEnabled) return const [];
    try {
      final json = await _helper.get('api/points/premie_vouchers?${Uri(queryParameters: auth).query}');
      if (json is! Map || json['status'] != 1) return const [];
      return [for (final v in (json['vouchers'] as List? ?? const [])) if (v is Map) PremieVoucher.fromJson(v.cast<String, dynamic>())];
    } catch (_) {
      return const [];
    }
  }

  /// Null when claimed; else the server's code (SHELF_LOCKED, PREMIE_SOLD_OUT …) or 'network'.
  Future<String?> claim(int voucherId, int premieId) async {
    final auth = OpsCustomerApi.authParams();
    if (auth == null) return 'network';
    try {
      final json = await _helper.post('api/points/premie_vouchers/$voucherId/claim?${Uri(queryParameters: auth).query}', body: {'premie_id': premieId});
      if (json is Map && json['status'] == 1) return null;
      return json is Map ? '${json['message'] ?? 'error'}' : 'error';
    } catch (e) {
      return 'network';
    }
  }
}
