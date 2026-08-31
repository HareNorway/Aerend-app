/// status : 1
/// message : "success!"
/// message_code : 1
/// pages : [{"id":1,"page_name":"about- us","page_title":"About  Us","description":"<div style=\"padding: 0px 50px;\">\r\n<p><strong>What personal information do we collect?</strong></p>\r\n<p>When you place an order or complete a customer survey, we may collect personal information about you which may include name, email address, telephone number, location etc when voluntarily given by you. We collect this information to carry out the services offered by our app and to provide you offers and information about other services you may be interested in.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Who will see my personal information?</strong></p>\r\n<p>Your privacy is of the utmost importance to us and no sensitive data will be shared without your consent.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Is my personal information secure with food delivery?</strong></p>\r\n<p>Food Delivery will endeavor to protect your personal information from interference, modification, disclosure, misuse, loss, and unauthorized access. You are responsible for the confidentiality of your password and we strongly recommend against sharin</p>\r\n</div>"},{"id":2,"page_name":"Faq","page_title":"Faq","description":"<div style=\"padding: 0px 50px;\">\r\n<p><strong>What personal information do we collect?</strong></p>\r\n<p>When you place an order or complete a customer survey, we may collect personal information about you which may include name, email address, telephone number, location etc when voluntarily given by you. We collect this information to carry out the services offered by our app and to provide you offers and information about other services you may be interested in.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Who will see my personal information?</strong></p>\r\n<p>Your privacy is of the utmost importance to us and no sensitive data will be shared without your consent.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Is my personal information secure with food delivery?</strong></p>\r\n<p>Food Delivery will endeavor to protect your personal information from interference, modification, disclosure, misuse, loss, and unauthorized access. You are responsible for the confidentiality of your password and we strongly recommend against sharin</p>\r\n</div>"},{"id":3,"page_name":"Terms And Conditions","page_title":"Terms And Conditions","description":"<div style=\"padding: 0px 50px;\">\r\n<p><strong>What personal information do we collect?</strong></p>\r\n<p>When you place an order or complete a customer survey, we may collect personal information about you which may include name, email address, telephone number, location etc when voluntarily given by you. We collect this information to carry out the services offered by our app and to provide you offers and information about other services you may be interested in.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Who will see my personal information?</strong></p>\r\n<p>Your privacy is of the utmost importance to us and no sensitive data will be shared without your consent.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Is my personal information secure with food delivery?</strong></p>\r\n<p>Food Delivery will endeavor to protect your personal information from interference, modification, disclosure, misuse, loss, and unauthorized access. You are responsible for the confidentiality of your password and we strongly recommend against sharin</p>\r\n</div>"}]
library;

class SupportPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  List<Pages>? _pages;

  int get status => _status ?? 0;

  String get message => _message ?? "";

  int get messageCode => _messageCode ?? 0;

  List<Pages> get pages => _pages ?? [];

  SupportPojo({int? status, String? message, int? messageCode, List<Pages>? pages}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _pages = pages;
  }

  SupportPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["pages"] != null) {
      _pages = [];
      json["pages"].forEach((v) {
        _pages?.add(Pages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_pages != null) {
      map["pages"] = _pages?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 1
/// page_name : "about- us"
/// page_title : "About  Us"
/// description : "<div style=\"padding: 0px 50px;\">\r\n<p><strong>What personal information do we collect?</strong></p>\r\n<p>When you place an order or complete a customer survey, we may collect personal information about you which may include name, email address, telephone number, location etc when voluntarily given by you. We collect this information to carry out the services offered by our app and to provide you offers and information about other services you may be interested in.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Who will see my personal information?</strong></p>\r\n<p>Your privacy is of the utmost importance to us and no sensitive data will be shared without your consent.</p>\r\n<p>&nbsp;</p>\r\n<p><strong>Is my personal information secure with food delivery?</strong></p>\r\n<p>Food Delivery will endeavor to protect your personal information from interference, modification, disclosure, misuse, loss, and unauthorized access. You are responsible for the confidentiality of your password and we strongly recommend against sharin</p>\r\n</div>"

class Pages {
  int? _id;
  String? _pageName;
  String? _pageTitle;
  String? _description;

  int get id => _id ?? 0;

  String get pageName => _pageName ?? "";

  String get pageTitle => _pageTitle ?? "";

  String get description => _description ?? "";

  Pages({int? id, String? pageName, String? pageTitle, String? description}) {
    _id = id;
    _pageName = pageName;
    _pageTitle = pageTitle;
    _description = description;
  }

  Pages.fromJson(dynamic json) {
    _id = json["id"];
    _pageName = json["page_name"];
    _pageTitle = json["page_title"];
    _description = json["description"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["page_name"] = _pageName;
    map["page_title"] = _pageTitle;
    map["description"] = _description;
    return map;
  }
}

class SupportPagesItem {
  int id;
  String pageTitle, pageName, description;

  SupportPagesItem(this.id, this.pageTitle, this.pageName, this.description);
}
