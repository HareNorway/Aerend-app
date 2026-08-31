// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_book_dl.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceTypeModel _$ServiceTypeModelFromJson(Map<String, dynamic> json) =>
    ServiceTypeModel(
      status: (json['status'] as num?)?.toInt() ?? 0,
      messageCode: (json['message_code'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? "",
      serviceType: (json['service_type'] as List<dynamic>?)
          ?.map((e) => ServiceTypeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServiceTypeModelToJson(ServiceTypeModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message_code': instance.messageCode,
      'message': instance.message,
      'service_type': instance.serviceType.map((e) => e.toJson()).toList(),
    };

ServiceTypeItem _$ServiceTypeItemFromJson(Map<String, dynamic> json) =>
    ServiceTypeItem(
      serviceName: json['service_name'] as String? ?? "",
      image: json['image'] as String? ?? "",
      dimensionLimit: json['dimension_limit'] as String? ?? "",
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceStatus: (json['service_status'] as num?)?.toInt() ?? 0,
      costPerKm: (json['cost_per_km'] as num?)?.toDouble() ?? 0,
      rentalAmount: (json['rental_amount'] as num?)?.toDouble() ?? 0,
      weightLimit: (json['weight_limit'] as num?)?.toDouble() ?? 0,
      lengthLimit: (json['length_limit'] as num?)?.toDouble() ?? 0,
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
      costPerMin: (json['cost_per_min'] as num?)?.toDouble() ?? 0,
      widthLimit: (json['width_limit'] as num?)?.toDouble() ?? 0,
      heightLimit: (json['height_limit'] as num?)?.toDouble() ?? 0,
      minFareAmount: (json['min_fare_amount'] as num?)?.toDouble() ?? 0,
      currencyRatio: (json['currency_ratio'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$ServiceTypeItemToJson(ServiceTypeItem instance) =>
    <String, dynamic>{
      'service_name': instance.serviceName,
      'image': instance.image,
      'dimension_limit': instance.dimensionLimit,
      'id': instance.id,
      'service_status': instance.serviceStatus,
      'cost_per_km': instance.costPerKm,
      'rental_amount': instance.rentalAmount,
      'weight_limit': instance.weightLimit,
      'length_limit': instance.lengthLimit,
      'base_fare': instance.baseFare,
      'cost_per_min': instance.costPerMin,
      'width_limit': instance.widthLimit,
      'height_limit': instance.heightLimit,
      'min_fare_amount': instance.minFareAmount,
      'currency_ratio': instance.currencyRatio,
    };
