// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deliveries_history_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveriesHistoryPojo _$DeliveriesHistoryPojoFromJson(
  Map<String, dynamic> json,
) => DeliveriesHistoryPojo(
  status: (json['status'] as num?)?.toInt() ?? 0,
  messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
  currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
  lastPage: (json['last_page'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
  message: json['message'] as String? ?? "",
  orderList: (json['order_list'] as List<dynamic>?)
      ?.map((e) => DeliveriesHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeliveriesHistoryPojoToJson(
  DeliveriesHistoryPojo instance,
) => <String, dynamic>{
  'status': instance.status,
  'message_code': instance.messageCode,
  'current_page': instance.currentPage,
  'last_page': instance.lastPage,
  'total': instance.total,
  'message': instance.message,
  'order_list': instance.orderList.map((e) => e.toJson()).toList(),
};

DeliveriesHistoryItem _$DeliveriesHistoryItemFromJson(
  Map<String, dynamic> json,
) => DeliveriesHistoryItem(
  orderId: (json['order_id'] as num?)?.toInt() ?? 0,
  orderNo: (json['order_no'] as num?)?.toInt() ?? 0,
  categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
  allowReorder: (json['allow_reorder'] as num?)?.toInt() ?? 0,
  totalPay: (json['total_pay'] as num?)?.toDouble() ?? 0,
  orderStatus: (json['order_status'] as num?)?.toInt() ?? 0,
  userTakenType: (json['user_taken_type'] as num?)?.toInt() ?? 0,
  categoryName: json['category_name'] as String? ?? "",
  categoryIcon: json['category_icon'] as String? ?? "",
  storeName: json['store_name'] as String? ?? "",
  serviceDateTime: json['service_date_time'] as String? ?? "",
  scheduleOrderDateTime: json['schedule_order_date_time'] as String? ?? "",
  deliveryAddress: json['delivery_address'] as String? ?? "",
);

Map<String, dynamic> _$DeliveriesHistoryItemToJson(
  DeliveriesHistoryItem instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'order_no': instance.orderNo,
  'category_id': instance.categoryId,
  'allow_reorder': instance.allowReorder,
  'total_pay': instance.totalPay,
  'order_status': instance.orderStatus,
  'user_taken_type': instance.userTakenType,
  'category_name': instance.categoryName,
  'category_icon': instance.categoryIcon,
  'store_name': instance.storeName,
  'service_date_time': instance.serviceDateTime,
  'schedule_order_date_time': instance.scheduleOrderDateTime,
  'delivery_address': instance.deliveryAddress,
};
