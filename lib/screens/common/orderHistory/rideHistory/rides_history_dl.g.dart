// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_history_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RidesHistoryPojo _$RidesHistoryPojoFromJson(Map<String, dynamic> json) =>
    RidesHistoryPojo(
      status: (json['status'] as num?)?.toInt() ?? 0,
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? "",
      rides: (json['rides'] as List<dynamic>?)
          ?.map((e) => RidesItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RidesHistoryPojoToJson(RidesHistoryPojo instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'total': instance.total,
      'message': instance.message,
      'rides': instance.rides.map((e) => e.toJson()).toList(),
    };

RidesItem _$RidesItemFromJson(Map<String, dynamic> json) => RidesItem(
  rideId: (json['ride_id'] as num?)?.toInt() ?? 0,
  bookingNo: (json['booking_no'] as num?)?.toInt() ?? 0,
  serviceCategoryId: (json['service_category_id'] as num?)?.toInt() ?? 0,
  rideStatus: (json['ride_status'] as num?)?.toInt() ?? 0,
  totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
  categoryIcon: json['category_icon'] as String? ?? "",
  categoryName: json['category_name'] as String? ?? "",
  serviceDateTime: json['service_date_time'] as String? ?? "",
  scheduleOrderDateTime: json['schedule_order_date_time'] as String? ?? "",
  pickupAddress: json['pickup_address'] as String? ?? "",
  destinationAddress: json['destination_address'] as String? ?? "",
);

Map<String, dynamic> _$RidesItemToJson(RidesItem instance) => <String, dynamic>{
  'ride_id': instance.rideId,
  'booking_no': instance.bookingNo,
  'service_category_id': instance.serviceCategoryId,
  'ride_status': instance.rideStatus,
  'total_pay': instance.totalPay,
  'category_icon': instance.categoryIcon,
  'category_name': instance.categoryName,
  'service_date_time': instance.serviceDateTime,
  'schedule_order_date_time': instance.scheduleOrderDateTime,
  'pickup_address': instance.pickupAddress,
  'destination_address': instance.destinationAddress,
};
