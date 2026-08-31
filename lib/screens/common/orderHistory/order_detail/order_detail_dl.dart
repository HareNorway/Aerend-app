class OrderDetailPojo {
  int? _status;
  String? _message;
  double? _totalDistance;
  double? _subTotal;
  double? _deliveryFee;
  double? _orderFee;
  double? _tip;
  List<OrderSummaryItem>? _orderSummaryList;
  int? _messageCode;

  double get totalDistance => _totalDistance ?? 0.0;

  double get subTotal => _subTotal ?? 0.0;

  double get deliveryFee => _deliveryFee ?? 0.0;

  double get orderFee => _orderFee ?? 0.0;

  double get tip => _tip ?? 0.0;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<OrderSummaryItem> get orderSummaryList => _orderSummaryList ?? [];

  OrderDetailPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _totalDistance = (json['total_distance'] as num?)?.toDouble() ?? 0.0;
    _subTotal = (json['sub_total'] as num?)?.toDouble() ?? 0.0;
    _deliveryFee = (json['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    _orderFee = (json['order_fee'] as num?)?.toDouble() ?? 0.0;
    _tip = (json['tip'] as num?)?.toDouble() ?? 0.0;
    if (json["order_list"] != null) {
      _orderSummaryList = [];
      json["order_list"].forEach((v) {
        _orderSummaryList?.add(OrderSummaryItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["total_distance"] = _totalDistance;
    map["sub_total"] = _subTotal;
    map["delivery_fee"] = _deliveryFee;
    map["order_fee"] = _orderFee;
    map["tip"] = _tip;
    if (_orderSummaryList != null) {
      map["order_list"] = _orderSummaryList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

class OrderSummaryItem {
  int? _productId;
  int? _productQuantity;
  double? _productAmount;
  double? _discountAmount;
  String? _productName;
  String? _productImage;
  String? _description;

  int get productId => _productId ?? 0;

  int get productQuantity => _productQuantity ?? 0;

  double get productAmount => _productAmount ?? 0.0;

  double get discountAmount => _discountAmount ?? 0.0;

  String get productName => _productName ?? "";

  String get productImage => _productImage ?? "";

  String get description => _description ?? "";

  OrderSummaryItem({
    int? productId,
    int? productQuantity,
    double? productAmount,
    double? discountAmount,
    String? productName,
    String? productImage,
    String? description,
  }) {
    _productId = productId;
    _productQuantity = productQuantity;
    _productAmount = productAmount;
    _discountAmount = discountAmount;
    _productName = productName;
    _productImage = productImage;
    _description = description;
  }

  OrderSummaryItem.fromJson(dynamic json) {
    _productId = json["product_id"];
    _productQuantity = json["quantity"];
    _productAmount = (json['product_amount'] as num?)?.toDouble() ?? 0.0;
    _discountAmount = (json['discount_amount'] as num?)?.toDouble() ?? 0.0;
    _productName = json["product_name"];
    _productImage = json["product_image"];
    _description = json["description"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["product_id"] = _productId;
    map["quantity"] = _productQuantity;
    map["product_amount"] = _productAmount;
    map["discount_amount"] = _discountAmount;
    map["product_name"] = _productName;
    map["product_image"] = _productImage;
    map["description"] = _description;
    return map;
  }
}
