/// status : 1
/// message : "success!"
/// message_code : 1
/// card_list : [{"card_id":68,"card_holder_name":"ghjh","card_number":"4111111111111111"}]
library;

class CardModel {
  int? _status;
  String? _message;
  int? _messageCode;
  List<CardListItem>? _cardList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<CardListItem> get cardList => _cardList ?? [];

  CardModel({int? status, String? message, int? messageCode, List<CardListItem>? cardList}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _cardList = cardList;
  }

  CardModel.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["card_list"] != null) {
      _cardList = [];
      json["card_list"].forEach((v) {
        _cardList?.add(CardListItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_cardList != null) {
      map["card_list"] = _cardList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// card_id : 68
/// card_holder_name : "ghjh"
/// card_number : "4111111111111111"

class CardListItem {
  int? _cardId;
  String? _cardHolderName;
  String? _cardNumber;

  int get cardId => _cardId ?? 0;

  String get cardHolderName => _cardHolderName ?? "";

  String get cardNumber => _cardNumber ?? "";

  CardListItem({int? cardId, String? cardHolderName, String? cardNumber}) {
    _cardId = cardId;
    _cardHolderName = cardHolderName;
    _cardNumber = cardNumber;
  }

  CardListItem.fromJson(dynamic json) {
    _cardId = json["card_id"];
    _cardHolderName = json["card_holder_name"];
    _cardNumber = json["card_number"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["card_id"] = _cardId;
    map["card_holder_name"] = _cardHolderName;
    map["card_number"] = _cardNumber;
    return map;
  }
}
