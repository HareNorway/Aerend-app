// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPreviewPojo _$OrderPreviewPojoFromJson(Map<String, dynamic> json) =>
    OrderPreviewPojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      storeId: (json['store_id'] as num?)?.toInt() ?? 0,
      requiredPrescription:
          (json['required_prescription'] as num?)?.toInt() ?? 0,
      userTakenStatus: (json['user_taken_status'] as num?)?.toInt() ?? 0,
      promoMessageCode: (json['promo_message_code'] as num?)?.toInt() ?? 0,
      storeStatus: (json['store_status'] as num?)?.toInt() ?? 0,
      storeRating: (json['store_rating'] as num?)?.toDouble() ?? 0,
      totalItemCost: (json['total_item_cost'] as num?)?.toDouble() ?? 0,
      discountCost: (json['discount_cost'] as num?)?.toDouble() ?? 0,
      applyPromocodeAmount:
          (json['apply_promocode_amount'] as num?)?.toDouble() ?? 0,
      packagingCost: (json['packaging_cost'] as num?)?.toDouble() ?? 0,
      deliveryCost: (json['delivery_cost'] as num?)?.toDouble() ?? 0,
      taxCost: (json['tax_cost'] as num?)?.toDouble() ?? 0,
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
      promocodeDiscount: (json['promocode_discount'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      referDiscount: (json['refer_discount'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      promocodeName: json['promocode_name'] as String? ?? "",
      promoCodeMessage: json['promo_code_message'] as String? ?? "",
      message: json['message'] as String? ?? "",
      storeBanner: json['store_banner'] as String? ?? "",
      storeName: json['store_name'] as String? ?? "",
      storeAddress: json['store_address'] as String?,
      unavailableProducts: json['unavailable_products'] as String? ?? "",
      productList: (json['product_list'] as List<dynamic>?)
          ?.map((e) => COProductListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderPreviewPojoToJson(OrderPreviewPojo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'store_id': instance.storeId,
      'required_prescription': instance.requiredPrescription,
      'user_taken_status': instance.userTakenStatus,
      'promo_message_code': instance.promoMessageCode,
      'store_status': instance.storeStatus,
      'store_rating': instance.storeRating,
      'total_item_cost': instance.totalItemCost,
      'discount_cost': instance.discountCost,
      'apply_promocode_amount': instance.applyPromocodeAmount,
      'packaging_cost': instance.packagingCost,
      'delivery_cost': instance.deliveryCost,
      'tax_cost': instance.taxCost,
      'total_pay': instance.totalPay,
      'promocode_discount': instance.promocodeDiscount,
      'tip': instance.tip,
      'refer_discount': instance.referDiscount,
      'min_order_amount': instance.minOrderAmount,
      'message': instance.message,
      'store_name': instance.storeName,
      'store_address': ?instance.storeAddress,
      'store_banner': instance.storeBanner,
      'promocode_name': instance.promocodeName,
      'promo_code_message': instance.promoCodeMessage,
      'unavailable_products': instance.unavailableProducts,
      'product_list': instance.productList.map((e) => e.toJson()).toList(),
    };

COProductListItem _$COProductListItemFromJson(
  Map<String, dynamic> json,
) => COProductListItem(
  productId: (json['product_id'] as num?)?.toInt() ?? 0,
  productTotalQuantity: (json['product_total_quantity'] as num?)?.toInt() ?? 0,
  productTotalAmount: (json['product_total_amount'] as num?)?.toDouble() ?? 0,
  productDiscount: (json['product_discount'] as num?)?.toDouble() ?? 0,
  productName: json['product_name'] as String? ?? "",
  productQuantityList: (json['product_quantity_list'] as List<dynamic>?)
      ?.map((e) => ProductQuantityListItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$COProductListItemToJson(COProductListItem instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_total_quantity': instance.productTotalQuantity,
      'product_total_amount': instance.productTotalAmount,
      'product_discount': instance.productDiscount,
      'product_name': instance.productName,
      'product_quantity_list': instance.productQuantityList
          .map((e) => e.toJson())
          .toList(),
    };

ProductQuantityListItem _$ProductQuantityListItemFromJson(
  Map<String, dynamic> json,
) => ProductQuantityListItem(
  productQuantity: (json['product_quantity'] as num?)?.toInt() ?? 0,
  productAmount: (json['product_amount'] as num?)?.toDouble() ?? 0,
  priceForOne: (json['price_for_one'] as num?)?.toDouble() ?? 0,
  productDiscount: (json['product_discount'] as num?)?.toDouble() ?? 0,
  productSize: (json['product_size'] as num?)?.toInt() ?? 0,
  productAddOns: json['product_add_ons'] as String? ?? "",
  productOptions: (json['product_options'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  productToppings: (json['product_toppings'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ProductQuantityListItemToJson(
  ProductQuantityListItem instance,
) => <String, dynamic>{
  'product_quantity': instance.productQuantity,
  'product_amount': instance.productAmount,
  'price_for_one': instance.priceForOne,
  'product_discount': instance.productDiscount,
  'product_add_ons': instance.productAddOns,
  'product_size': instance.productSize,
  'product_options': instance.productOptions,
  'product_toppings': instance.productToppings,
};

PromoCodePojo _$PromoCodePojoFromJson(Map<String, dynamic> json) =>
    PromoCodePojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? "",
      promocodeList: (json['promocode_list'] as List<dynamic>?)
          ?.map((e) => PromoCodeListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PromoCodePojoToJson(PromoCodePojo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'message': instance.message,
      'promocode_list': instance.promocodeList.map((e) => e.toJson()).toList(),
    };

PromoCodeListItem _$PromoCodeListItemFromJson(Map<String, dynamic> json) =>
    PromoCodeListItem(
      promocodeId: (json['promocode_id'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      discountType: (json['discount_type'] as num?)?.toInt() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      promocodeDescription: json['promocode_description'] as String? ?? "",
      promocodeName: json['promocode_name'] as String? ?? "",
    );

Map<String, dynamic> _$PromoCodeListItemToJson(PromoCodeListItem instance) =>
    <String, dynamic>{
      'promocode_id': instance.promocodeId,
      'discount_amount': instance.discountAmount,
      'discount_type': instance.discountType,
      'min_order_amount': instance.minOrderAmount,
      'promocode_description': instance.promocodeDescription,
      'promocode_name': instance.promocodeName,
    };

PlaceOrderPojo _$PlaceOrderPojoFromJson(Map<String, dynamic> json) =>
    PlaceOrderPojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderNo: json['order_no'] as String? ?? "",
      paymentIntent: json['payment_intent'] ?? Null,
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0.0,
      inActiveProductIds: json['in_active_product_ids'] as String? ?? "",
      message: json['message'] as String? ?? "",
      successUrl: json['success_url'] as String? ?? "",
      failedUrl: json['failed_url'] as String? ?? "",
      redirectUrl: json['redirect_url'] as String? ?? "",
    );

Map<String, dynamic> _$PlaceOrderPojoToJson(PlaceOrderPojo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'order_id': instance.orderId,
      'total_pay': instance.totalPay,
      'payment_intent': ?instance.paymentIntent,
      'message': instance.message,
      'order_no': instance.orderNo,
      'in_active_product_ids': instance.inActiveProductIds,
      'success_url': instance.successUrl,
      'failed_url': instance.failedUrl,
      'redirect_url': instance.redirectUrl,
    };

CurrentAddressPojo _$CurrentAddressPojoFromJson(Map<String, dynamic> json) =>
    CurrentAddressPojo(
      address: json['address'] as String? ?? "",
      lat: json['lat'] as String? ?? "",
      lng: json['lng'] as String? ?? "",
      flatNo: json['flat_no'] as String? ?? "",
      landmark: json['landmark'] as String? ?? "",
    );

Map<String, dynamic> _$CurrentAddressPojoToJson(CurrentAddressPojo instance) =>
    <String, dynamic>{
      'address': instance.address,
      'lat': instance.lat,
      'lng': instance.lng,
      'flat_no': instance.flatNo,
      'landmark': instance.landmark,
    };
