// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_order_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackOrderPojo _$TrackOrderPojoFromJson(Map<String, dynamic> json) =>
    TrackOrderPojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      storeRatting: (json['store_ratting'] as num?)?.toDouble() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderNo: (json['order_no'] as num?)?.toInt() ?? 0,
      orderStatus: (json['order_status'] as num?)?.toInt() ?? 0,
      storeId: (json['store_id'] as num?)?.toInt() ?? 0,
      storeDetailsId: (json['store_details_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      userTakenType: (json['user_taken_type'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
      cancelCharge: (json['cancel_charge'] as num?)?.toDouble() ?? 0,
      orderCurrentStatus: (json['order_current_status'] as num?)?.toInt() ?? 0,
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      paymentType: (json['payment_type'] as num?)?.toInt() ?? 0,
      storeImage: json['store_image'] as String? ?? "",
      storeBanner: json['store_banner'] as String? ?? "",
      message: json['message'] as String? ?? "",
      orderTime: json['order_time'] as String? ?? "",
      cancelBy: json['cancel_by'] as String? ?? "",
      cancelReason: json['cancel_reason'] as String? ?? "",
      serviceCategoryName: json['service_category_name'] as String? ?? "",
      contactNumber: json['contact_number'] as String? ?? "",
      storeContactNumber: json['store_contact_number'] as String? ?? "",
      driverContactNumber: json['driver_contact_number'] as String? ?? "",
      deliveryPeopleName: json['delivery_people_name'] as String? ?? "",
      scheduleOrderDateTime: json['schedule_order_date_time'] as String? ?? "",
      acceptOrderTime: json['accept_order_time'] as String? ?? "",
      prepareOrderTime: json['prepare_order_time'] as String? ?? "",
      sendOrderTime: json['send_order_time'] as String? ?? "",
      arriveOrderTime: json['arrive_order_time'] as String? ?? "",
      driverFcmToken: json['driver_fcm_token'] as String? ?? "",
      storeFcmToken: json['store_fcm_token'] as String? ?? "",
      customerFcmToken: json['customer_fcm_token'] as String? ?? "",
      otp: json['otp'] as String? ?? "",
      storeName: json['store_name'] as String? ?? "",
      pickupAddress: json['pickup_address'] as String? ?? "",
      pickupLatLong: json['pickup_lat_long'] as String? ?? "",
      destinationAddress: json['destination_address'] as String? ?? "",
      destinationLatLong: json['destination_lat_long'] as String? ?? "",
      orderCancelRejectTitle:
          json['order_cancel_reject_title'] as String? ?? "",
      orderStatusList: (json['order_status_list'] as List<dynamic>?)
          ?.map((e) => OrderStatusListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrackOrderPojoToJson(
  TrackOrderPojo instance,
) => <String, dynamic>{
  'status': instance.status,
  'order_id': instance.orderId,
  'order_no': instance.orderNo,
  'order_status': instance.orderStatus,
  'store_id': instance.storeId,
  'store_details_id': instance.storeDetailsId,
  'store_ratting': instance.storeRatting,
  'total_items': instance.totalItems,
  'driver_id': instance.driverId,
  'total_pay': instance.totalPay,
  'user_taken_type': instance.userTakenType,
  'cancel_charge': instance.cancelCharge,
  'order_current_status': instance.orderCurrentStatus,
  'message_code': instance.messageCode,
  'payment_type': instance.paymentType,
  'message': instance.message,
  'store_image': instance.storeImage,
  'store_banner': instance.storeBanner,
  'order_time': instance.orderTime,
  'cancel_by': instance.cancelBy,
  'cancel_reason': instance.cancelReason,
  'service_category_name': instance.serviceCategoryName,
  'contact_number': instance.contactNumber,
  'store_contact_number': instance.storeContactNumber,
  'driver_contact_number': instance.driverContactNumber,
  'delivery_people_name': instance.deliveryPeopleName,
  'schedule_order_date_time': instance.scheduleOrderDateTime,
  'accept_order_time': instance.acceptOrderTime,
  'prepare_order_time': instance.prepareOrderTime,
  'send_order_time': instance.sendOrderTime,
  'arrive_order_time': instance.arriveOrderTime,
  'driver_fcm_token': instance.driverFcmToken,
  'store_fcm_token': instance.storeFcmToken,
  'customer_fcm_token': instance.customerFcmToken,
  'otp': instance.otp,
  'store_name': instance.storeName,
  'pickup_address': instance.pickupAddress,
  'pickup_lat_long': instance.pickupLatLong,
  'destination_address': instance.destinationAddress,
  'destination_lat_long': instance.destinationLatLong,
  'order_cancel_reject_title': instance.orderCancelRejectTitle,
  'order_status_list': instance.orderStatusList.map((e) => e.toJson()).toList(),
};

OrderStatusListItem _$OrderStatusListItemFromJson(Map<String, dynamic> json) =>
    OrderStatusListItem(
      orderStatus: (json['order_status'] as num?)?.toInt() ?? 0,
      updateStatusTime: json['update_status_time'] as String? ?? "",
    );

Map<String, dynamic> _$OrderStatusListItemToJson(
  OrderStatusListItem instance,
) => <String, dynamic>{
  'order_status': instance.orderStatus,
  'update_status_time': instance.updateStatusTime,
};
