/// status : 1
/// message : "success!"
/// address_list : [{"address_id":219,"type":"home","address":"Bharti Nagar Main Rd, Shyam Nagar, Bharti Nagar, Bajrang Wadi, Rajkot, Gujarat 360007, India","lat":"22.312608249651323","long":"70.76852951198816","flat_no":"ftt","landmark":"dffu"}]
/// message_code : 1
library;

class AddressListPojo {
  int? _status;
  String? _message;
  List<AddressListItem>? _addressList;
  int? _messageCode;
  int? _maxAddressLimit;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get maxAddressLimit => _maxAddressLimit ?? 0;

  List<AddressListItem> get addressList => _addressList ?? [];

  AddressListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _maxAddressLimit = json["max_address_limit"];
    if (json["address_list"] != null) {
      _addressList = [];
      json["address_list"].forEach((v) {
        _addressList?.add(AddressListItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["max_address_limit"] = _maxAddressLimit;
    if (_addressList != null) {
      map["address_list"] = _addressList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

/// address_id : 219
/// type : "home"
/// address : "Bharti Nagar Main Rd, Shyam Nagar, Bharti Nagar, Bajrang Wadi, Rajkot, Gujarat 360007, India"
/// lat : "22.312608249651323"
/// long : "70.76852951198816"
/// flat_no : "ftt"
/// landmark : "dffu"

class AddressListItem {
  int? _addressId;
  String? _type;
  String? _address;
  String? _lat;
  String? _long;
  String? _flatNo;
  String? _landmark;

  int get addressId => _addressId ?? 0;

  String get type => _type ?? "";

  String get address => _address ?? "";

  String get lat => _lat ?? "";

  String get long => _long ?? "";

  String get flatNo => _flatNo ?? "";

  String get landmark => _landmark ?? "";

  AddressListItem({int? addressId, String? type, String? address, String? lat, String? long, String? flatNo, String? landmark}) {
    _addressId = addressId;
    _type = type;
    _address = address;
    _lat = lat;
    _long = long;
    _flatNo = flatNo;
    _landmark = landmark;
  }

  AddressListItem.fromJson(dynamic json) {
    _addressId = json["address_id"];
    _type = json["type"];
    _address = json["address"];
    _lat = json["lat"];
    _long = json["long"];
    _flatNo = json["flat_no"];
    _landmark = json["landmark"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["address_id"] = _addressId;
    map["type"] = _type;
    map["address"] = _address;
    map["lat"] = _lat;
    map["long"] = _long;
    map["flat_no"] = _flatNo;
    map["landmark"] = _landmark;
    return map;
  }

  setType(String value) {
    _type = value;
  }

  setAddress(String value) {
    _address = value;
  }

  setLat(String value) {
    _lat = value;
  }

  setLong(String value) {
    _long = value;
  }

  setFlatNo(String value) {
    _flatNo = value;
  }

  setLandmark(String value) {
    _landmark = value;
  }
}
