class HistoryFilterModel {
  int filterType;
  String filterName;

  HistoryFilterModel(this.filterType, this.filterName);
}

class OrderHistoryListPojo {
  int? _status;
  String? _message;
  List<OrderHistoryListItem>? _orderHistoryList;
  int? _messageCode;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<OrderHistoryListItem> get orderHistoryList => _orderHistoryList ?? [];

  OrderHistoryListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["order_list"] != null) {
      _orderHistoryList = [];
      json["order_list"].forEach((v) {
        _orderHistoryList?.add(OrderHistoryListItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_orderHistoryList != null) {
      map["order_list"] = _orderHistoryList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

class OrderHistoryListItem {
  int? _orderId;
  int? _orderNo;
  int? _categoryId;
  String? _categoryName;
  String? _categoryIcon;
  String? _storeName;
  String? _storeImage;
  String? _serviceDate;
  String? _serviceTime;
  String? _serviceDateTime;
  String? _scheduleOrderDateTime;
  String? _orderDateTime;
  String? _deliveryAddress;
  double? _totalPay;
  int? _orderStatus;
  int? _userTakenType;
  int? _allowReorder;

  int get orderId => _orderId ?? 0;

  int get orderNo => _orderNo ?? 0;

  int get categoryId => _categoryId ?? 0;

  String get categoryName => _categoryName ?? "";

  String get categoryIcon => _categoryIcon ?? "";

  String get storeName => _storeName ?? "";

  String get storeImage => _storeImage ?? "";

  String get serviceDate => _serviceDate ?? "";

  String get serviceTime => _serviceTime ?? "";

  String get serviceDateTime => _serviceDateTime ?? "";

  String get scheduleOrderDateTime => _scheduleOrderDateTime ?? "";

  String get orderDateTime => _orderDateTime ?? "";

  String get deliveryAddress => _deliveryAddress ?? "";

  double get totalPay => _totalPay ?? 0.0;

  int get orderStatus => _orderStatus ?? 0;

  int get userTakenType => _userTakenType ?? 0;

  int get allowReorder => _allowReorder ?? 0;

  OrderHistoryListItem({
    int? orderId,
    int? orderNo,
    int? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? storeName,
    String? storeImage,
    String? serviceDate,
    String? serviceTime,
    String? serviceDateTime,
    String? scheduleOrderDateTime,
    String? orderDateTime,
    String? deliveryAddress,
    double? totoalPay,
    int? orderStatus,
    int? userTakenType,
    int? allowReorder,
  }) {
    _orderId = orderId;
    _orderNo = orderNo;
    _categoryId = categoryId;
    _categoryName = categoryName;
    _categoryIcon = categoryIcon;
    _storeName = storeName;
    _storeImage = storeImage;
    _serviceDate = serviceDate;
    _serviceTime = serviceTime;
    _serviceDateTime = serviceDateTime;
    _scheduleOrderDateTime = scheduleOrderDateTime;
    _orderDateTime = orderDateTime;
    _deliveryAddress = deliveryAddress;
    _totalPay = totoalPay;
    _orderStatus = orderStatus;
    _userTakenType = userTakenType;
    _allowReorder = allowReorder;
  }

  OrderHistoryListItem.fromJson(dynamic json) {
    _orderId = json["order_id"];
    _orderNo = json["order_no"];
    _categoryId = json["category_id"];
    _categoryName = json["category_name"];
    _categoryIcon = json["category_icon"];
    _storeName = json["store_name"];
    _storeImage = json["store_image"];
    _serviceDate = json["service_date"];
    _serviceTime = json["service_time"];
    _serviceDateTime = json["service_date_time"];
    _scheduleOrderDateTime = json["schedule_order_date_time"];
    _orderDateTime = json["order_date_time"];
    _deliveryAddress = json["delivery_address"];
    _totalPay = (json['total_pay'] as num?)?.toDouble() ?? 0.0;
    _orderStatus = json["order_status"];
    _userTakenType = json["user_taken_type"];
    _allowReorder = json["allow_reorder"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["order_id"] = _orderId;
    map["order_no"] = _orderNo;
    map["category_id"] = _categoryId;
    map["category_name"] = _categoryName;
    map["category_icon"] = _categoryIcon;
    map["store_name"] = _storeName;
    map["store_image"] = _storeImage;
    map["service_date"] = _serviceDate;
    map["service_date_time"] = _serviceTime;
    map["schedule_order_date_time"] = _scheduleOrderDateTime;
    map["order_date_time"] = _orderDateTime;
    map["delivery_address"] = _deliveryAddress;
    map["total_pay"] = _totalPay;
    map["order_status"] = _orderStatus;
    map["user_taken_type"] = _userTakenType;
    return map;
  }
}
