import '../../../utils/shared_pref_utill.dart';

/// Delivery checkout needs an address before order-preview can return totals.
bool checkoutSummaryAwaitingAddress({int orderType = 0}) {
  return orderType == 0 && prefGetInt(prefNewDeliveryAddressId) <= 0;
}

/// Helpers for order-preview totals used on checkout.
double checkoutPreviewSubtotal(dynamic data) {
  if (data is! Map) return 0.0;

  final double fromApi = (data['sub_total'] as num?)?.toDouble() ?? 0.0;
  if (fromApi > 0) return fromApi;

  final List<dynamic> orderList =
      (data['order_list'] as List?) ?? const <dynamic>[];
  double sum = 0.0;
  for (final dynamic item in orderList) {
    if (item is! Map) continue;
    final double amount = (item['product_amount'] as num?)?.toDouble() ?? 0.0;
    final double discount = (item['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final double addon = (item['addon_total'] as num?)?.toDouble() ?? 0.0;
    sum += (amount - discount + addon) * qty;
  }
  return sum;
}

double checkoutPreviewGrossTotal(
  dynamic data, {
  int orderType = 0,
  double tip = 0,
}) {
  if (data is! Map) return tip;

  final double subtotal = checkoutPreviewSubtotal(data);
  final double deliveryFee = orderType == 0
      ? ((data['delivery_fee'] as num?)?.toDouble() ?? 0.0)
      : 0.0;
  final double orderFee = (data['order_fee'] as num?)?.toDouble() ?? 0.0;
  return subtotal + deliveryFee + orderFee + tip;
}
