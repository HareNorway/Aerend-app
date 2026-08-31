/// status : 1
/// message : "Success!"
/// message_code : 1
/// current_page : 1
/// last_page : 1
/// total : 2
/// product_list : [{"product_id":29,"product_image":"https://fox-jekapp.startuptrinity.com/assets/images/store-images/product-images/8262021202009117.jpg","product_name":"Aloo Tikki Burger","food_type":1,"product_amount":49,"discount_amount":50,"offer_discount":1,"store_id":9,"store_name":"Hardik Store"},{"product_id":30,"product_image":"https://fox-jekapp.startuptrinity.com/assets/images/store-images/product-images/7165019202003128.jpg","product_name":"Aloo Tikki Burger","food_type":1,"product_amount":78.4,"discount_amount":80,"offer_discount":1.6,"store_id":10,"store_name":"Mcd"}]
library;

class SearchProductPojo {
  SearchProductPojo({
    int? status,
    String? message,
    int? messageCode,
    int? currentPage,
    int? lastPage,
    int? total,
    List<ProductList>? productList,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _currentPage = currentPage;
    _lastPage = lastPage;
    _total = total;
    _productList = productList;
  }

  SearchProductPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    _currentPage = json['current_page'];
    _lastPage = json['last_page'];
    _total = json['total'];
    if (json['product_list'] != null) {
      _productList = [];
      json['product_list'].forEach((v) {
        _productList?.add(ProductList.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  int? _currentPage;
  int? _lastPage;
  int? _total;
  List<ProductList>? _productList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get currentPage => _currentPage ?? 0;

  int get lastPage => _lastPage ?? 0;

  int get total => _total ?? 0;

  List<ProductList> get productList => _productList ?? [];

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    map['current_page'] = _currentPage;
    map['last_page'] = _lastPage;
    map['total'] = _total;
    if (_productList != null) {
      map['product_list'] = _productList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_id : 29
/// product_image : "https://fox-jekapp.startuptrinity.com/assets/images/store-images/product-images/8262021202009117.jpg"
/// product_name : "Aloo Tikki Burger"
/// food_type : 1
/// product_amount : 49
/// discount_amount : 50
/// offer_discount : 1
/// store_id : 9
/// store_name : "Hardik Store"

class ProductList {
  ProductList({
    int? productId,
    String? productImage,
    String? productName,
    int? foodType,
    dynamic productAmount,
    dynamic discountAmount,
    dynamic offerDiscount,
    int? storeId,
    String? storeName,
  }) {
    _productId = productId;
    _productImage = productImage;
    _productName = productName;
    _foodType = foodType;
    _productAmount = productAmount;
    _discountAmount = discountAmount;
    _offerDiscount = offerDiscount;
    _storeId = storeId;
    _storeName = storeName;
  }

  ProductList.fromJson(dynamic json) {
    _productId = json['product_id'];
    _productImage = json['product_image'];
    _productName = json['product_name'];
    _foodType = json['food_type'];
    _productAmount = json['product_amount'];
    _discountAmount = json['discount_amount'];
    _offerDiscount = json['offer_discount'];
    _storeId = json['store_id'];
    _storeName = json['store_name'];
  }

  int? _productId;
  String? _productImage;
  String? _productName;
  int? _foodType;
  dynamic _productAmount;
  dynamic _discountAmount;
  dynamic _offerDiscount;
  int? _storeId;
  String? _storeName;

  int get productId => _productId ?? 0;

  int get foodType => _foodType ?? 0;

  int get storeId => _storeId ?? 0;

  String get productImage => _productImage ?? "";

  String get productName => _productName ?? "";

  String get storeName => _storeName ?? "";

  dynamic get productAmount => _productAmount;

  dynamic get discountAmount => _discountAmount;

  dynamic get offerDiscount => _offerDiscount;

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['product_id'] = _productId;
    map['product_image'] = _productImage;
    map['product_name'] = _productName;
    map['food_type'] = _foodType;
    map['product_amount'] = _productAmount;
    map['discount_amount'] = _discountAmount;
    map['offer_discount'] = _offerDiscount;
    map['store_id'] = _storeId;
    map['store_name'] = _storeName;
    return map;
  }
}
