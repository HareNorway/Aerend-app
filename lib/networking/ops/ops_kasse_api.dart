import 'dart:convert';

import '../../data/ops/kasse_models.dart';
import '../../screens/common/manageAddress/manage_address_dl.dart';
import '../../screens/common/manageAddress/manage_address_repo.dart';
import '../../screens/common/orderCart/order_cart_repo.dart';
import '../../screens/deliveryService/checkout/checkout_dl.dart';
import '../../screens/deliveryService/checkout/checkout_repo.dart';
import '../../utils/utils.dart';
import 'ops_customer_api.dart';

/// The cart, preview, address and order calls the Kasse group makes (AGIL-1
/// v2 Phase 5) over the app's existing endpoints, plus the guarded reads that
/// belong to the other branch (`geo.*`). Everything degrades to empty / null.
class OpsKasseApi {
  OpsKasseApi();

  static bool get _off => !OpsCustomerApi.networkEnabled;

  /// The cart lines.
  Future<KurvState> cart() async {
    if (_off) return const KurvState();
    try {
      final json = await OrderCartRepo().callOrderCartApi();
      if (json is! Map<String, dynamic> || json['status'] != 1)
        return const KurvState();
      return KurvState.fromCartJson(json);
    } catch (_) {
      return const KurvState();
    }
  }

  /// The order preview for the selected address: totals and the store.
  Future<OrderPreviewPojo?> preview() async {
    if (_off) return null;
    try {
      final json = await CheckoutRepo().callOrderPreviewApi();
      if (json is! Map<String, dynamic> || json['status'] != 1) return null;
      return previewFromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Today's `order-preview` answers `sub_total`, `delivery_fee` and
  /// `order_fee` (service fee + tax) — not the legacy `total_item_cost`,
  /// `delivery_cost`, `tax_cost` the pojo reads — so the fee the checkout
  /// charges was missing from Kassen's total.
  static OrderPreviewPojo previewFromJson(Map<String, dynamic> json) {
    final pojo = OrderPreviewPojo.fromJson(json);
    double? d(String k) => json[k] is num ? (json[k] as num).toDouble() : double.tryParse('${json[k] ?? ''}');
    if (!json.containsKey('delivery_cost')) pojo.deliveryCost = d('delivery_fee') ?? 0;
    if (!json.containsKey('tax_cost')) pojo.taxCost = d('order_fee') ?? 0;
    if (!json.containsKey('total_item_cost')) pojo.totalItemCost = d('sub_total') ?? 0;
    return pojo;
  }

  Future<bool> changeQuantity(int cartId, int quantity) async {
    if (_off) return false;
    try {
      final json = await OrderCartRepo().callChangeQuantityApi(
        cartId,
        quantity,
      );
      return json is Map && json['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int cartId) async {
    if (_off) return false;
    try {
      final json = await OrderCartRepo().deleteOrderCartApi(cartId);
      return json is Map && json['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /// Saved addresses.
  Future<List<AddressListItem>> addresses() async {
    if (_off) return const [];
    try {
      final json = await ManageAddressRepo().callAddressListApi();
      if (json is! Map<String, dynamic> || json['status'] != 1) return const [];
      final list = json['address_list'];
      return list is List
          ? [for (final a in list) AddressListItem.fromJson(a)]
          : const [];
    } catch (_) {
      return const [];
    }
  }

  /// Place the order through the legacy checkout. Returns the response as
  /// is — the screen reads `order_id`, `total_pay`, `status`, `message`, and
  /// a 422 `error` code such as `PD_OUTSIDE_RADIUS` (spec §8.2).
  Future<Map<String, dynamic>?> placeOrder({
    required int storeId,
    required int addressId,
    required int paymentType,
    required bool pickup,
    required List<int> cartIds,
    String note = '',
    String? scheduleDateTime,
    double tip = 0,
  }) async {
    if (_off) return null;
    try {
      final json = await CheckoutRepo().callStorePlaceOrderApi(
        storeId,
        addressId,
        paymentType,
        pickup ? 2 : 1,
        note,
        jsonEncode(cartIds),
        false,
        '',
        scheduleDateTime,
        tip,
        null,
      );
      return json is Map<String, dynamic> ? json : null;
    } catch (e) {
      return {'status': 0, 'message': e.toString()};
    }
  }

  /// The Vipps redirect for an order; null when initiation failed.
  Future<String?> vippsRedirect(int orderId) async {
    if (_off) return null;
    try {
      final json = await CheckoutRepo().initiateVippsViaBackend(orderId);
      if (json is Map && (json['status'] == 1 || json['status'] == true)) {
        final url = json['redirect_url'] ?? json['redirectUrl'];
        if (url != null && '$url'.isNotEmpty) {
          prefSetInt('vipps_pending_order_id', orderId);
          return '$url';
        }
      }
    } catch (_) {
      // Fall through.
    }
    return null;
  }
}
