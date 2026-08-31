class ChatHistoryListPojo {
  int? _status;
  String? _message;
  List<ChatHistoryListItem>? _chatHistoryList;
  int? _messageCode;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<ChatHistoryListItem> get chatHistoryList => _chatHistoryList ?? [];

  ChatHistoryListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["chat_history"] != null) {
      _chatHistoryList = [];
      json["chat_history"].forEach((v) {
        _chatHistoryList?.add(ChatHistoryListItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_chatHistoryList != null) {
      map["chat_history"] = _chatHistoryList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

class ChatHistoryListItem {
  bool? _isProvider;
  int? _status;
  String? _spentAt;
  String? _content;

  bool get isProvider => _isProvider ?? false;

  int get status => _status ?? 0;

  String get spentAt => _spentAt ?? "";

  String get content => _content ?? "";

  ChatHistoryListItem({
    bool? isProvider,
    int? status,
    String? spentAt,
    String? content,
  }) {
    _isProvider = isProvider;
    _status = status;
    _spentAt = spentAt;
    _content = content;
  }

  ChatHistoryListItem.fromJson(dynamic json) {
    _isProvider = json["is_provider"];
    _status = json["status"];
    _spentAt = json["spent_at"];
    _content = json["content"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["is_provider"] = _isProvider;
    map["status"] = _status;
    map["spent_at"] = _spentAt;
    map["content"] = _content;
    return map;
  }
}
