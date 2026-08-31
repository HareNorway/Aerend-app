/// status : 1
/// message : "success!"
/// message_code : 1
/// contact_number: "123456789999"
/// select_country_code: "+91"
library;

class EditNumberPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  String? _contactNumber;
  String? _selectCountryCode;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  String get contactNumber => _contactNumber ?? "";

  String get selectCountryCode => _selectCountryCode ?? "";

  EditNumberPojo({int? status, String? message, int? messageCode, String? contactNumber, String? selectCountryCode}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _contactNumber = contactNumber;
    _selectCountryCode = selectCountryCode;
  }

  EditNumberPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _contactNumber = json["contact_number"];
    _selectCountryCode = json["select_country_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["contact_number"] = _contactNumber;
    map["select_country_code"] = _selectCountryCode;
    return map;
  }
}
