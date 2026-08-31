/// status : 1
/// message : "success!"
/// message_code : 1
/// wallet_balance : 0
library;

class WalletBalancePojo {
  int? _status;
  String? _message;
  int? _messageCode;
  dynamic _walletBalance;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  dynamic get walletBalance => _walletBalance;

  setWalletBalance(dynamic walletBalance) {
    _walletBalance = walletBalance;
  }

  WalletBalancePojo({int? status, String? message, int? messageCode, dynamic walletBalance}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _walletBalance = walletBalance;
  }

  WalletBalancePojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _walletBalance = json["wallet_balance"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["wallet_balance"] = _walletBalance;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// transactions : [{"id":177,"transaction_type":1,"amount":10,"subject":"credit by user","remaining_balance":10,"date_time":"2021-03-25 11:25:06"}]

class WalletTransactionPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  List<TransactionsItem>? _transactions;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<TransactionsItem> get transactions => _transactions ?? [];

  WalletTransactionPojo({int? status, String? message, int? messageCode, List<TransactionsItem>? transactions}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _transactions = transactions;
  }

  WalletTransactionPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["transactions"] != null) {
      _transactions = [];
      json["transactions"].forEach((v) {
        _transactions?.add(TransactionsItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_transactions != null) {
      map["transactions"] = _transactions?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 177
/// transaction_type : 1
/// amount : 10
/// subject : "credit by user"
/// remaining_balance : 10
/// date_time : "2021-03-25 11:25:06"

class TransactionsItem {
  int? _id;
  int? _transactionType;
  dynamic _amount;
  String? _subject;
  dynamic _remainingBalance;
  String? _dateTime;

  int get id => _id ?? 0;

  int get transactionType => _transactionType ?? 0;

  dynamic get amount => _amount;

  dynamic get remainingBalance => _remainingBalance;

  String get subject => _subject ?? "";

  String get dateTime => _dateTime ?? "";

  TransactionsItem({int? id, int? transactionType, dynamic amount, String? subject, dynamic remainingBalance, String? dateTime}) {
    _id = id;
    _transactionType = transactionType;
    _amount = amount;
    _subject = subject;
    _remainingBalance = remainingBalance;
    _dateTime = dateTime;
  }

  TransactionsItem.fromJson(dynamic json) {
    _id = json["id"];
    _transactionType = json["transaction_type"];
    _amount = json["amount"];
    _subject = json["subject"];
    _remainingBalance = json["remaining_balance"];
    _dateTime = json["date_time"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["transaction_type"] = _transactionType;
    map["amount"] = _amount;
    map["subject"] = _subject;
    map["remaining_balance"] = _remainingBalance;
    map["date_time"] = _dateTime;
    return map;
  }
}
