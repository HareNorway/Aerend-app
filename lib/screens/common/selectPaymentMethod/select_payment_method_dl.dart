import 'package:flutter/cupertino.dart';

import '../manageCard/manage_card_dl.dart';

class SelectPaymentMethodModel {
  String title;
  bool showAddCard;
  List<SelectPaymentMethodItem> selectPaymentMethodList;

  SelectPaymentMethodModel({required this.title, required this.selectPaymentMethodList, this.showAddCard = false});
}

class SelectPaymentMethodItem {
  int type;
  int id;
  String name;
  IconData icon;
  CardListItem? cardListItem;

  SelectPaymentMethodItem({required this.id, required this.type, required this.name, required this.icon, this.cardListItem});
}

class PaymentBaseModel {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _rideStatus;
  String? _redirectUrl;
  String? _successUrl;
  String? _failedUrl;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get rideStatus => _rideStatus ?? 0;

  String get message => _message ?? "";

  String get redirectUrl => _redirectUrl ?? "";

  String get successUrl => _successUrl ?? "";

  String get failedUrl => _failedUrl ?? "";

  PaymentBaseModel({int? status, String? message, int? messageCode, int? rideStatus, String? redirectUrl, String? successUrl, String? failedUrl}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _rideStatus = rideStatus;
    _redirectUrl = redirectUrl;
    _successUrl = successUrl;
    _failedUrl = failedUrl;
  }

  PaymentBaseModel.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _rideStatus = json["ride_status"];
    _redirectUrl = json["redirect_url"];
    _successUrl = json["success_url"];
    _failedUrl = json["failed_url"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["ride_status"] = _rideStatus;
    map["redirect_url"] = _redirectUrl;
    map["success_url"] = _successUrl;
    map["failed_url"] = _failedUrl;
    return map;
  }
}
