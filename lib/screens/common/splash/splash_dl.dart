/// status : 1
/// message : "success!"
/// order_id : 672
/// order_status : 1
/// service_cat_id : 5
/// message_code : 1
library;

class GetRunningServicePojo {
  int? _status;
  String? _message;
  int? _orderId;
  int? _orderStatus;
  int? _serviceCatId;
  int? _messageCode;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get orderId => _orderId ?? 0;

  int get orderStatus => _orderStatus ?? 0;

  int get serviceCatId => _serviceCatId ?? 0;

  int get messageCode => _messageCode ?? 0;

  GetRunningServicePojo({int? status, String? message, int? orderId, int? orderStatus, int? serviceCatId, int? messageCode}) {
    _status = status;
    _message = message;
    _orderId = orderId;
    _orderStatus = orderStatus;
    _serviceCatId = serviceCatId;
    _messageCode = messageCode;
  }

  GetRunningServicePojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _orderId = json["order_id"];
    _orderStatus = json["order_status"];
    _serviceCatId = json["service_cat_id"];
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["order_id"] = _orderId;
    map["order_status"] = _orderStatus;
    map["service_cat_id"] = _serviceCatId;
    map["message_code"] = _messageCode;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// app_version : "1.0"
/// is_forcefully_update : 0

class AppVersionCheckPojo {
  AppVersionCheckPojo({
    int? status,
    String? message,
    int? messageCode,
    String? appVersion,
    int? isForcefullyUpdate,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _appVersion = appVersion;
    _isForcefullyUpdate = isForcefullyUpdate;
  }

  AppVersionCheckPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    _appVersion = json['app_version'];
    _isForcefullyUpdate = json['is_forcefully_update'];
  }

  int? _status;
  String? _message;
  int? _messageCode;
  String? _appVersion;
  int? _isForcefullyUpdate;

  String get message => _message ?? "";

  String get appVersion => _appVersion ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get isForcefullyUpdate => _isForcefullyUpdate ?? 0;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    map['app_version'] = _appVersion;
    map['is_forcefully_update'] = _isForcefullyUpdate;
    return map;
  }
}
