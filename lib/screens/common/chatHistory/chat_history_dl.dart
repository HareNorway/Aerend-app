import 'package:firebase_database/firebase_database.dart';

import '../../../constant/constant.dart';

class ModelChatList {
  String? _userId,
      _userName,
      _userProfile,
      _lastMsg,
      _lastMsgTime,
      _userServicesName,
      _userFCMToken,
      _userDateTime;
  int? _userType;

  ModelChatList(
      this._userId,
      this._userName,
      this._userProfile,
      this._lastMsg,
      this._lastMsgTime,
      this._userServicesName,
      this._userFCMToken,
      this._userDateTime);

  int get userType => _userType ?? -1;

  String get userId => _userId ?? "0";

  String get userName => _userName ?? "";

  String get userProfile => _userProfile ?? "";

  String get lastMsg => _lastMsg ?? "";

  String get lastMsgTime => _lastMsgTime ?? "";

  String get userServicesName => _userServicesName ?? "";

  String get userFCMToken => _userFCMToken ?? "";

  String get userDateTime => _userDateTime ?? "";

  ModelChatList.fromSnapshot(DataSnapshot snapshot) {
    Map<String, dynamic> result =
        Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
    _userId = result[ChatConstant.userId];
    _userName = result[ChatConstant.userName];
    _userProfile = result[ChatConstant.userProfile];
    _lastMsg = result[ChatConstant.userLastMessage];
    _lastMsgTime = result[ChatConstant.userDateTime];
    _userServicesName = result[ChatConstant.userServicesName];
    _userDateTime = result[ChatConstant.userDateTime];
    _userType = result[ChatConstant.userType];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map[ChatConstant.userDateTime] = _lastMsgTime;
    map[ChatConstant.userLastMessage] = _lastMsg;
    map[ChatConstant.userProfile] = _userProfile;
    map[ChatConstant.userId] = _userId;
    map[ChatConstant.userName] = _userName;
    map[ChatConstant.userServicesName] = _userServicesName;
    map[ChatConstant.userType] = _userType;
    return map;
  }
}

class ModelChatting {
  String? _message, _senderId, _senderName, _date;

  ModelChatting(this._message, this._senderId, this._senderName, this._date);

  String? get message => _message;

  String? get senderId => _senderId;

  String? get senderName => _senderName;

  String? get date => _date;

  ModelChatting.fromSnapshot(DataSnapshot snapshot) {
    Map<String, dynamic> result =
        Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
    _message = result[ChatConstant.fbMessage];
    _senderId = result[ChatConstant.fbSenderId];
    _senderName = result[ChatConstant.fbSenderName];
    _date = result[ChatConstant.fbMessageTime];
  }

  ModelChatting.fromJson(dynamic json) {
    _message = json[ChatConstant.fbMessage];
    _senderId = json[ChatConstant.fbSenderId];
    _senderName = json[ChatConstant.fbSenderName];
    _date = json[ChatConstant.fbMessageTime];
  }
}
