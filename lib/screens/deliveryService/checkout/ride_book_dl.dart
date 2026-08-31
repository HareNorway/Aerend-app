/// status : 1
/// message : "Success"
/// message_code : 1
/// service_type : [{"id":8,"service_name":"Scooter","image":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/transport-service-type/145111420200710.png","cost_per_km":8,"weight_limit":0,"dimension_limit":"","base_fare":50,"cost_per_min":0,"width_limit":0,"height_limit":0,"min_fare_amount":100,"currency_ratio":1,"service_status":1},{"id":6,"service_name":"Cruiser","image":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/transport-service-type/144121420200710.png","cost_per_km":10,"weight_limit":0,"dimension_limit":"","base_fare":75,"cost_per_min":0,"width_limit":0,"height_limit":0,"min_fare_amount":125,"currency_ratio":1,"service_status":0},{"id":5,"service_name":"Street","image":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/transport-service-type/113241120192506.png","cost_per_km":20,"weight_limit":0,"dimension_limit":"","base_fare":100,"cost_per_min":0,"width_limit":0,"height_limit":0,"min_fare_amount":150,"currency_ratio":1,"service_status":0},{"id":7,"service_name":"Sports","image":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/transport-service-type/154111420200710.png","cost_per_km":50,"weight_limit":0,"dimension_limit":"","base_fare":12,"cost_per_min":1,"width_limit":0,"height_limit":0,"min_fare_amount":40,"currency_ratio":1,"service_status":0}]
library;

class ServiceTypeModel {
  int? _status;
  String? _message;
  int? _messageCode;
  List<ServiceTypeItem>? _serviceType;

  int? get status => _status;

  String? get message => _message;

  int? get messageCode => _messageCode;

  List<ServiceTypeItem>? get serviceType => _serviceType;

  ServiceTypeModel({int? status, String? message, int? messageCode, List<ServiceTypeItem>? serviceType}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _serviceType = serviceType;
  }

  ServiceTypeModel.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["service_type"] != null) {
      _serviceType = [];
      json["service_type"].forEach((v) {
        _serviceType?.add(ServiceTypeItem.fromJson(v));
      });
    }
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_serviceType != null) {
      map["service_type"] = _serviceType?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 8
/// service_name : "Scooter"
/// image : "https://fox-jek-staging.startuptrinity.com/assets/images/service-category/transport-service-type/145111420200710.png"
/// cost_per_km : 8
/// weight_limit : 0
/// dimension_limit : ""
/// base_fare : 50
/// cost_per_min : 0
/// width_limit : 0
/// height_limit : 0
/// min_fare_amount : 100
/// currency_ratio : 1
/// service_status : 1

class ServiceTypeItem {
  int? _id;
  String? _serviceName;
  String? _image;
  dynamic _costPerKm;
  dynamic _rentalAmount;
  dynamic _weightLimit;
  String? _dimensionLimit;
  dynamic _baseFare;
  dynamic _costPerMin;
  dynamic _widthLimit;
  dynamic _heightLimit;
  dynamic _minFareAmount;
  dynamic _currencyRatio;
  int? _serviceStatus;
  bool isSelected = false;

  int? get id => _id;

  String? get serviceName => _serviceName;

  String? get image => _image;

  dynamic get costPerKm => _costPerKm;

  dynamic get rentalAmount => _rentalAmount;

  dynamic get weightLimit => _weightLimit;

  String? get dimensionLimit => _dimensionLimit;

  dynamic get baseFare => _baseFare;

  dynamic get costPerMin => _costPerMin;

  dynamic get widthLimit => _widthLimit;

  dynamic get heightLimit => _heightLimit;

  dynamic get minFareAmount => _minFareAmount;

  dynamic get currencyRatio => _currencyRatio;

  int? get serviceStatus => _serviceStatus;

  ServiceTypeItem(
      {int? id,
      String? serviceName,
      String? image,
      dynamic costPerKm,
      dynamic rentalAmount,
      dynamic weightLimit,
      String? dimensionLimit,
      dynamic baseFare,
      dynamic costPerMin,
      dynamic widthLimit,
      dynamic heightLimit,
      dynamic minFareAmount,
      dynamic currencyRatio,
      int? serviceStatus}) {
    _id = id;
    _serviceName = serviceName;
    _image = image;
    _costPerKm = costPerKm;
    _rentalAmount = rentalAmount;
    _weightLimit = weightLimit;
    _dimensionLimit = dimensionLimit;
    _baseFare = baseFare;
    _costPerMin = costPerMin;
    _widthLimit = widthLimit;
    _heightLimit = heightLimit;
    _minFareAmount = minFareAmount;
    _currencyRatio = currencyRatio;
    _serviceStatus = serviceStatus;
  }

  ServiceTypeItem.fromJson(dynamic json) {
    _id = json["id"];
    _serviceName = json["service_name"];
    _image = json["image"];
    _costPerKm = json["cost_per_km"];
    _rentalAmount = json["rental_amount"];
    _weightLimit = json["weight_limit"];
    _dimensionLimit = json["dimension_limit"];
    _baseFare = json["base_fare"];
    _costPerMin = json["cost_per_min"];
    _widthLimit = json["width_limit"];
    _heightLimit = json["height_limit"];
    _minFareAmount = json["min_fare_amount"];
    _currencyRatio = json["currency_ratio"];
    _serviceStatus = json["service_status"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["id"] = _id;
    map["service_name"] = _serviceName;
    map["image"] = _image;
    map["cost_per_km"] = _costPerKm;
    map["rental_amount"] = _rentalAmount;
    map["weight_limit"] = _weightLimit;
    map["dimension_limit"] = _dimensionLimit;
    map["base_fare"] = _baseFare;
    map["cost_per_min"] = _costPerMin;
    map["width_limit"] = _widthLimit;
    map["height_limit"] = _heightLimit;
    map["min_fare_amount"] = _minFareAmount;
    map["currency_ratio"] = _currencyRatio;
    map["service_status"] = _serviceStatus;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// discount_amount : 10
/// total_pay : 97
/// promocode_id : 5
/// promocode_name : "PRO123"
/// min_order_amount : 0

class ApplyPromoCodePojo {
  int? _status;
  String? _message;
  int? _messageCode;
  dynamic _discountAmount;
  dynamic _totalPay;
  int? _promocodeId;
  String? _promocodeName;
  dynamic _minOrderAmount;

  int? get status => _status;

  String? get message => _message;

  int? get messageCode => _messageCode;

  dynamic get discountAmount => _discountAmount;

  dynamic get totalPay => _totalPay;

  int? get promocodeId => _promocodeId;

  String? get promocodeName => _promocodeName;

  dynamic get minOrderAmount => _minOrderAmount;

  ApplyPromoCodePojo(
      {int? status,
      String? message,
      int? messageCode,
      dynamic discountAmount,
      dynamic totalPay,
      int? promocodeId,
      String? promocodeName,
      dynamic minOrderAmount}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _discountAmount = discountAmount;
    _totalPay = totalPay;
    _promocodeId = promocodeId;
    _promocodeName = promocodeName;
    _minOrderAmount = minOrderAmount;
  }

  ApplyPromoCodePojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _discountAmount = json["discount_amount"];
    _totalPay = json["total_pay"];
    _promocodeId = json["promocode_id"];
    _promocodeName = json["promocode_name"];
    _minOrderAmount = json["min_order_amount"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["discount_amount"] = _discountAmount;
    map["total_pay"] = _totalPay;
    map["promocode_id"] = _promocodeId;
    map["promocode_name"] = _promocodeName;
    map["min_order_amount"] = _minOrderAmount;
    return map;
  }
}

/// status : 1
/// message : "Ride Booking Successfully!"
/// message_code : 1
/// ride_id : 696
/// booking_no : "4234910202101073"
/// pickup_date_time : "01 Jul, 2021"
/// pickup_address : "1206, The Spire, 150 Feet Ring Rd, near Shital park, Sheetal Park, Manharpura 1, Dharam Nagar Society, Rajkot, Gujarat 360006, India"
/// destination_address : "Astha Apartment, Gandhi gram 7/11 corner Opp radhe traders, Gautamnagar, Gandhigram, Rajkot, Gujarat 360007, India"
/// ride_status : 0
/// accept_time_out : 30

class RideBookPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _rideId;
  dynamic _bookingNo;
  String? _pickupDateTime;
  String? _pickupAddress;
  String? _destinationAddress;
  int? _rideStatus;
  int? _acceptTimeOut;

  int? get status => _status;

  String? get message => _message;

  int? get messageCode => _messageCode;

  int? get rideId => _rideId;

  dynamic get bookingNo => _bookingNo;

  String? get pickupDateTime => _pickupDateTime;

  String? get pickupAddress => _pickupAddress;

  String? get destinationAddress => _destinationAddress;

  int? get rideStatus => _rideStatus;

  int? get acceptTimeOut => _acceptTimeOut;

  RideBookPojo(
      {int? status,
      String? message,
      int? messageCode,
      int? rideId,
      dynamic bookingNo,
      String? pickupDateTime,
      String? pickupAddress,
      String? destinationAddress,
      int? rideStatus,
      int? acceptTimeOut}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _rideId = rideId;
    _bookingNo = bookingNo;
    _pickupDateTime = pickupDateTime;
    _pickupAddress = pickupAddress;
    _destinationAddress = destinationAddress;
    _rideStatus = rideStatus;
    _acceptTimeOut = acceptTimeOut;
  }

  RideBookPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _rideId = json["ride_id"];
    _bookingNo = json["booking_no"];
    _pickupDateTime = json["pickup_date_time"];
    _pickupAddress = json["pickup_address"];
    _destinationAddress = json["destination_address"];
    _rideStatus = json["ride_status"];
    _acceptTimeOut = json["accept_time_out"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["ride_id"] = _rideId;
    map["booking_no"] = _bookingNo;
    map["pickup_date_time"] = _pickupDateTime;
    map["pickup_address"] = _pickupAddress;
    map["destination_address"] = _destinationAddress;
    map["ride_status"] = _rideStatus;
    map["accept_time_out"] = _acceptTimeOut;
    return map;
  }
}

/// status : 1
/// message : "success"
/// surcharge_charge_status : 1
/// surcharge_cost : 5
/// message_code : 1

class SurgeChargePojo {
  SurgeChargePojo({
    int? status,
    String? message,
    int? surchargeChargeStatus,
    dynamic surchargeCost,
    int? messageCode,
  }) {
    _status = status;
    _message = message;
    _surchargeChargeStatus = surchargeChargeStatus;
    _surchargeCost = surchargeCost;
    _messageCode = messageCode;
  }

  SurgeChargePojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _surchargeChargeStatus = json['surcharge_charge_status'];
    _surchargeCost = json['surcharge_cost'];
    _messageCode = json['message_code'];
  }

  int? _status;
  String? _message;
  int? _surchargeChargeStatus;
  dynamic _surchargeCost;
  int? _messageCode;

  SurgeChargePojo copyWith({
    int? status,
    String? message,
    int? surchargeChargeStatus,
    dynamic surchargeCost,
    int? messageCode,
  }) =>
      SurgeChargePojo(
        status: status ?? _status,
        message: message ?? _message,
        surchargeChargeStatus: surchargeChargeStatus ?? _surchargeChargeStatus,
        surchargeCost: surchargeCost ?? _surchargeCost,
        messageCode: messageCode ?? _messageCode,
      );

  int? get status => _status;

  String? get message => _message;

  int? get surchargeChargeStatus => _surchargeChargeStatus;

  dynamic get surchargeCost => _surchargeCost;

  int? get messageCode => _messageCode;

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['surcharge_charge_status'] = _surchargeChargeStatus;
    map['surcharge_cost'] = _surchargeCost;
    map['message_code'] = _messageCode;
    return map;
  }
}
