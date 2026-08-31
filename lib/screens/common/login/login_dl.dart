/// status : 1
/// message : "Success!"
/// message_code : 1
/// user_id : 56
/// user_verified : 0
/// first_name : "Hardik"
/// last_name : "Talaviya"
/// access_token : "68524409202123069"
/// email : "hat1@gmail.com"
/// login_type : "email"
/// profile_image : null
/// gender : null
/// contact_number : "98765432101"
/// referral_code : "HAR112"
/// select_country_code : "+1"
/// select_currency : "$"
/// select_language : "en"
/// emergency_contact : ""
/// server_time_zone : "UTC"
library;

class LoginPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _userId;
  int? _userVerified;
  String? _userName;
  String? _accessToken;
  String? _email;
  String? _loginType;
  String? _profileImage;
  dynamic _gender;
  String? _contactNumber;
  String? _referralCode;
  dynamic _credit;
  String? _selectCountryCode;
  String? _selectCurrency;
  String? _selectLanguage;
  String? _emergencyContact;
  String? _serverTimeZone;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get userId => _userId ?? 0;

  int get userVerified => _userVerified ?? 0;

  String get message => _message ?? "";

  String get userName => _userName ?? "";

  String get accessToken => _accessToken ?? "";

  String get email => _email ?? "";

  String get loginType => _loginType ?? "";

  String get profileImage => _profileImage ?? "";

  String get contactNumber => _contactNumber ?? "";

  String get referralCode => _referralCode ?? "";

  String get selectCountryCode => _selectCountryCode ?? "";

  String get selectCurrency => _selectCurrency ?? "";

  String get selectLanguage => _selectLanguage ?? "";

  String get emergencyContact => _emergencyContact ?? "";

  String get serverTimeZone => _serverTimeZone ?? "";

  dynamic get gender => _gender ?? "";

  dynamic get credit => _credit ?? 0;

  LoginPojo(
      {int? status,
      String? message,
      int? messageCode,
      int? userId,
      int? userVerified,
      String? firstName,
      String? lastName,
      String? accessToken,
      String? email,
      String? loginType,
      String? profileImage,
      dynamic gender,
      dynamic credit,
      String? contactNumber,
      String? referralCode,
      String? selectCountryCode,
      String? selectCurrency,
      String? selectLanguage,
      String? emergencyContact,
      String? serverTimeZone}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _userId = userId;
    _userVerified = userVerified;
    _userName = userName;
    _accessToken = accessToken;
    _email = email;
    _loginType = loginType;
    _profileImage = profileImage;
    _gender = gender;
    _credit = credit;
    _contactNumber = contactNumber;
    _referralCode = referralCode;
    _selectCountryCode = selectCountryCode;
    _selectCurrency = selectCurrency;
    _selectLanguage = selectLanguage;
    _emergencyContact = emergencyContact;
    _serverTimeZone = serverTimeZone;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  LoginPojo.fromJson(dynamic json) {
    _status = _asInt(json["status"]);
    _message = json["message"];
    _messageCode = _asInt(json["message_code"]);
    _userId = _asInt(json["user_id"]);
    _userVerified = _asInt(json["user_verified"]);
    _userName = json["user_name"]?.toString();
    // Always persist as string — numeric JSON tokens must not become ints.
    _accessToken = json["access_token"]?.toString();
    _email = json["email"]?.toString();
    _loginType = json["login_type"];
    _profileImage = json["profile_image"];
    _gender = json["gender"];
    _credit = json["credit"];
    _contactNumber = json["contact_number"];
    _referralCode = json["referral_code"];
    _selectCountryCode = json["select_country_code"];
    _selectCurrency = json["select_currency"];
    _selectLanguage = json["select_language"];
    _emergencyContact = json["emergency_contact"];
    _serverTimeZone = json["server_time_zone"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["user_id"] = _userId;
    map["user_verified"] = _userVerified;
    map["user_name"] = _userName;
    map["access_token"] = _accessToken;
    map["email"] = _email;
    map["login_type"] = _loginType;
    map["profile_image"] = _profileImage;
    map["gender"] = _gender;
    map["credit"] = _credit;
    map["contact_number"] = _contactNumber;
    map["referral_code"] = _referralCode;
    map["select_country_code"] = _selectCountryCode;
    map["select_currency"] = _selectCurrency;
    map["select_language"] = _selectLanguage;
    map["emergency_contact"] = _emergencyContact;
    map["server_time_zone"] = _serverTimeZone;
    return map;
  }
}

/// status : 1
/// message : "OTP has been sent to your registered Contact Number!"
/// user_id : 57
/// message_code : 1

class ForgotPassReqPojo {
  int? _status;
  String? _message;
  int? _userId;
  int? _messageCode;

  int? get status => _status;

  String? get message => _message;

  int? get userId => _userId;

  int? get messageCode => _messageCode;

  ForgotPassReqPojo(
      {int? status, String? message, int? userId, int? messageCode}) {
    _status = status;
    _message = message;
    _userId = userId;
    _messageCode = messageCode;
  }

  ForgotPassReqPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _userId = json["user_id"];
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["user_id"] = _userId;
    map["message_code"] = _messageCode;
    return map;
  }
}
