/// status : 1
/// message : "success!"
/// message_code : 1
/// transfer_user_list : [{"transfer_id":3,"name":"Vrl","email":"vrl@gmail.com","profile_image":"","country_code":"+1","contact_number":"25802580","wallet_provider_type":0}]
library;

class UserSearchModel {
  UserSearchModel({
    int? status,
    String? message,
    int? messageCode,
    List<TransferUserList>? transferUserList,
  }) {
    _status = status!;
    _message = message!;
    _messageCode = messageCode!;
    _transferUserList = transferUserList!;
  }

  UserSearchModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    if (json['transfer_user_list'] != null) {
      _transferUserList = [];
      json['transfer_user_list'].forEach((v) {
        _transferUserList?.add(TransferUserList.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  List<TransferUserList>? _transferUserList;

  UserSearchModel copyWith({
    int? status,
    String? message,
    int? messageCode,
    List<TransferUserList>? transferUserList,
  }) =>
      UserSearchModel(
        status: status ?? _status,
        message: message ?? _message,
        messageCode: messageCode ?? _messageCode,
        transferUserList: transferUserList ?? _transferUserList,
      );

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<TransferUserList> get transferUserList => _transferUserList ?? [];

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    if (_transferUserList != null) {
      map['transfer_user_list'] = _transferUserList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// transfer_id : 3
/// name : "Vrl"
/// email : "vrl@gmail.com"
/// profile_image : ""
/// country_code : "+1"
/// contact_number : "25802580"
/// wallet_provider_type : 0

class TransferUserList {
  TransferUserList({
    int? transferId,
    String? name,
    String? email,
    String? profileImage,
    String? countryCode,
    String? contactNumber,
    int? walletProviderType,
  }) {
    _transferId = transferId!;
    _name = name!;
    _email = email!;
    _profileImage = profileImage!;
    _countryCode = countryCode!;
    _contactNumber = contactNumber!;
    _walletProviderType = walletProviderType!;
  }

  TransferUserList.fromJson(dynamic json) {
    _transferId = json['transfer_id'];
    _name = json['name'];
    _email = json['email'];
    _profileImage = json['profile_image'];
    _countryCode = json['country_code'];
    _contactNumber = json['contact_number'];
    _walletProviderType = json['wallet_provider_type'];
  }

  int? _transferId;
  String? _name;
  String? _email;
  String? _profileImage;
  String? _countryCode;
  String? _contactNumber;
  int? _walletProviderType;

  TransferUserList copyWith({
    int? transferId,
    String? name,
    String? email,
    String? profileImage,
    String? countryCode,
    String? contactNumber,
    int? walletProviderType,
  }) =>
      TransferUserList(
        transferId: transferId ?? _transferId,
        name: name ?? _name,
        email: email ?? _email,
        profileImage: profileImage ?? _profileImage,
        countryCode: countryCode ?? _countryCode,
        contactNumber: contactNumber ?? _contactNumber,
        walletProviderType: walletProviderType ?? _walletProviderType,
      );

  int get transferId => _transferId ?? 0;

  int get walletProviderType => _walletProviderType ?? 0;

  String get name => _name ?? "";

  String get email => _email ?? "";

  String get profileImage => _profileImage ?? "";

  String get countryCode => _countryCode ?? "";

  String get contactNumber => _contactNumber ?? "";

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['transfer_id'] = _transferId;
    map['name'] = _name;
    map['email'] = _email;
    map['profile_image'] = _profileImage;
    map['country_code'] = _countryCode;
    map['contact_number'] = _contactNumber;
    map['wallet_provider_type'] = _walletProviderType;
    return map;
  }
}
