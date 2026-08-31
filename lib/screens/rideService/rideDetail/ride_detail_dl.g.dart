// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_detail_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideDetailPojo _$RideDetailPojoFromJson(Map<String, dynamic> json) =>
    RideDetailPojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? "",
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      rideId: (json['ride_id'] as num?)?.toInt() ?? 0,
      surchargeCost: (json['surcharge_cost'] as num?)?.toDouble() ?? 0,
      additionalRemark: json['additional_remark'] as String?,
      rideServiceCategoryId:
          (json['ride_service_category_id'] as num?)?.toInt() ?? 0,
      bookingType: (json['booking_type'] as num?)?.toInt() ?? 0,
      cancelByAdmin: (json['cancel_by_admin'] as num?)?.toInt() ?? 0,
      bookingNo: json['booking_no'] as String?,
      pickupDateTime: json['pickup_date_time'] as String?,
      serviceDateTime: json['service_date_time'] as String?,
      rideStatus: (json['ride_status'] as num?)?.toInt() ?? 0,
      cancelBy: json['cancel_by'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      driverSelectedServiceCatId:
          (json['driver_selected_service_cat_id'] as num?)?.toInt() ?? 0,
      driverSelectedServiceString:
          json['driver_selected_service_string'] as String?,
      driverFcmToken: json['driver_fcm_token'] as String?,
      vehicleManufactureName: json['vehicle_manufacture_name'] as String?,
      vehiclePlatNo: json['vehicle_plat_no'] as String?,
      vehicleModelYear: (json['vehicle_model_year'] as num?)?.toInt() ?? 0,
      vehicleModelName: json['vehicle_model_name'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      otp: json['otp'] as String?,
      costPerKm: (json['cost_per_km'] as num?)?.toDouble() ?? 0,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
      costPerMin: (json['cost_per_min'] as num?)?.toDouble() ?? 0,
      timeFareAmount: (json['time_fare_amount'] as num?)?.toDouble() ?? 0,
      totalDistance: json['total_distance'] as String?,
      estimatedTime: json['estimated_time'] as String?,
      rideFare: (json['ride_fare'] as num?)?.toDouble() ?? 0,
      referDiscount: (json['refer_discount'] as num?)?.toDouble() ?? 0,
      minAdjustmentAmount:
          (json['min_adjustment_amount'] as num?)?.toDouble() ?? 0,
      promocodeDiscount: (json['promocode_discount'] as num?)?.toDouble() ?? 0,
      promocodeName: json['promocode_name'] as String?,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
      payment: (json['payment'] as num?)?.toInt() ?? 0,
      paymentStatus: (json['payment_status'] as num?)?.toInt() ?? 0,
      driverName: json['driver_name'] as String?,
      driverImage: json['driver_image'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 0,
      serviceType: json['service_type'] as String?,
      serviceTypeIcon: json['service_type_icon'] as String?,
      driverContactNumber: json['driver_contact_number'] as String?,
      waypointMessage: json['waypoint_message'] as String?,
      userRatingStatus: (json['user_rating_status'] as num?)?.toDouble() ?? 0,
      waypointMsgCode: (json['waypoint_msg_code'] as num?)?.toInt() ?? 0,
      addressList: (json['address_list'] as List<dynamic>?)
          ?.map((e) => AddressListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      courierDetails: json['courier_details'] == null
          ? null
          : CourierDetails.fromJson(
              json['courier_details'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$RideDetailPojoToJson(RideDetailPojo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'ride_id': instance.rideId,
      'ride_service_category_id': instance.rideServiceCategoryId,
      'booking_type': instance.bookingType,
      'payment': instance.payment,
      'payment_status': instance.paymentStatus,
      'waypoint_msg_code': instance.waypointMsgCode,
      'vehicle_model_year': instance.vehicleModelYear,
      'ride_status': instance.rideStatus,
      'driver_id': instance.driverId,
      'driver_selected_service_cat_id': instance.driverSelectedServiceCatId,
      'cancel_by_admin': instance.cancelByAdmin,
      'message': instance.message,
      'additional_remark': ?instance.additionalRemark,
      'booking_no': ?instance.bookingNo,
      'pickup_date_time': ?instance.pickupDateTime,
      'service_date_time': ?instance.serviceDateTime,
      'cancel_by': ?instance.cancelBy,
      'cancel_reason': ?instance.cancelReason,
      'driver_selected_service_string': ?instance.driverSelectedServiceString,
      'driver_fcm_token': ?instance.driverFcmToken,
      'vehicle_manufacture_name': ?instance.vehicleManufactureName,
      'vehicle_plat_no': ?instance.vehiclePlatNo,
      'vehicle_model_name': ?instance.vehicleModelName,
      'vehicle_color': ?instance.vehicleColor,
      'otp': ?instance.otp,
      'total_distance': ?instance.totalDistance,
      'estimated_time': ?instance.estimatedTime,
      'promocode_name': ?instance.promocodeName,
      'service_type': ?instance.serviceType,
      'service_type_icon': ?instance.serviceTypeIcon,
      'driver_contact_number': ?instance.driverContactNumber,
      'waypoint_message': ?instance.waypointMessage,
      'driver_name': ?instance.driverName,
      'driver_image': ?instance.driverImage,
      'surcharge_cost': instance.surchargeCost,
      'cost_per_km': instance.costPerKm,
      'base_fare': instance.baseFare,
      'cost_per_min': instance.costPerMin,
      'time_fare_amount': instance.timeFareAmount,
      'ride_fare': instance.rideFare,
      'refer_discount': instance.referDiscount,
      'min_adjustment_amount': instance.minAdjustmentAmount,
      'promocode_discount': instance.promocodeDiscount,
      'tax': instance.tax,
      'tip': instance.tip,
      'subtotal': instance.subtotal,
      'discount': instance.discount,
      'total_pay': instance.totalPay,
      'driver_rating': instance.driverRating,
      'user_rating_status': instance.userRatingStatus,
      'address_list': instance.addressList.map((e) => e.toJson()).toList(),
      'courier_details': ?instance.courierDetails?.toJson(),
    };

CourierDetails _$CourierDetailsFromJson(Map<String, dynamic> json) =>
    CourierDetails(
      shopName: json['shop_name'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientContactNumber: json['recipient_contact_number'] as String?,
      recipientHouseName: json['recipient_house_name'] as String?,
      recipientLandmark: json['recipient_landmark'] as String?,
      parcelName: json['parcel_name'] as String?,
      senderName: json['sender_name'] as String?,
      senderContactNumber: json['sender_contact_number'] as String?,
      shopLandmark: json['shop_landmark'] as String?,
      description: json['description'] as String?,
      deliveryInstruction: json['delivery_instruction'] as String?,
      weightCloseLimit: (json['weight_close_limit'] as num?)?.toDouble() ?? 0,
      estimatePrice: (json['estimate_price'] as num?)?.toDouble() ?? 0,
      goodsHeight: (json['goods_height'] as num?)?.toDouble() ?? 0,
      goodsWidth: (json['goods_width'] as num?)?.toDouble() ?? 0,
      goodsLength: (json['goods_length'] as num?)?.toDouble() ?? 0,
      goodsWeight: (json['goods_weight'] as num?)?.toDouble() ?? 0,
      weightStartLimit: (json['weight_start_limit'] as num?)?.toDouble() ?? 0,
      courierType: (json['courier_type'] as num?)?.toInt() ?? 0,
      purchaseItemList: (json['purchase_item_list'] as List<dynamic>?)
          ?.map((e) => PurchaseItemList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourierDetailsToJson(CourierDetails instance) =>
    <String, dynamic>{
      'sender_name': ?instance.senderName,
      'sender_contact_number': ?instance.senderContactNumber,
      'shop_name': ?instance.shopName,
      'shop_landmark': ?instance.shopLandmark,
      'recipient_name': ?instance.recipientName,
      'recipient_contact_number': ?instance.recipientContactNumber,
      'recipient_landmark': ?instance.recipientLandmark,
      'recipient_house_name': ?instance.recipientHouseName,
      'parcel_name': ?instance.parcelName,
      'description': ?instance.description,
      'delivery_instruction': ?instance.deliveryInstruction,
      'weight_close_limit': instance.weightCloseLimit,
      'estimate_price': instance.estimatePrice,
      'goods_height': instance.goodsHeight,
      'goods_weight': instance.goodsWeight,
      'goods_width': instance.goodsWidth,
      'goods_length': instance.goodsLength,
      'weight_start_limit': instance.weightStartLimit,
      'courier_type': instance.courierType,
      'purchase_item_list': instance.purchaseItemList
          .map((e) => e.toJson())
          .toList(),
    };

PurchaseItemList _$PurchaseItemListFromJson(Map<String, dynamic> json) =>
    PurchaseItemList(
      itemName: json['item_name'] as String?,
      itemValue: json['item_value'] as String?,
    );

Map<String, dynamic> _$PurchaseItemListToJson(PurchaseItemList instance) =>
    <String, dynamic>{
      'item_name': ?instance.itemName,
      'item_value': ?instance.itemValue,
    };

AddressListItem _$AddressListItemFromJson(Map<String, dynamic> json) =>
    AddressListItem(
      address: json['address'] as String?,
      addressLat: json['address_lat'] as String?,
      addressLong: json['address_long'] as String?,
    );

Map<String, dynamic> _$AddressListItemToJson(AddressListItem instance) =>
    <String, dynamic>{
      'address': ?instance.address,
      'address_lat': ?instance.addressLat,
      'address_long': ?instance.addressLong,
    };
