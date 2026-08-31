import '../storeDetail/store_detail_dl.dart';

/// status : 1
/// message : "Success!"
/// message_code : 1
/// store_id : 1
/// category_id : 9
/// current_page : 1
/// last_page : 1
/// total : 3
/// product_list : [{"product_id":1,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6015907202018124.jpg","product_name":"Mcflurry Oreo Small","food_type":1,"product_amount":68.6,"discount_amount":70,"offer_discount":1.4,"description":"Taste the clouds with the soft vanilla serve, topped with creamy Oreo.","customize_list":[{"category_name":"Quantity","selection_type":1,"customize_type":1,"options":[{"id":1,"name":"50 Gram","amount":98,"discount_price":100,"category_name":"Quantity","selection_type":1},{"id":2,"name":"100 Gram","amount":166.6,"discount_price":170,"category_name":"Quantity","selection_type":1}]},{"category_name":"Choice of Sauce","selection_type":2,"customize_type":3,"options":[{"id":69,"name":"Choice Of Sauce","amount":10,"category_name":"Choice of Sauce","selection_type":2}]}]},{"product_id":2,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6471108202018124.jpg","product_name":"Choco Marble Slice Cake","food_type":2,"product_amount":101,"discount_amount":106,"offer_discount":5,"description":"Choco Marble Slice Cake","customize_list":[]},{"product_id":3,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/4401208202018123.jpg","product_name":"Mccafe-chocolate Express Cake","food_type":1,"product_amount":179,"discount_amount":0,"offer_discount":0,"description":"McCafe-Chocolate Express cake","customize_list":[]}]

class StoreProductList {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _storeId;
  int? _categoryId;
  int? _currentPage;
  int? _lastPage;
  int? _total;
  List<ProductListItem>? _productList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get storeId => _storeId ?? 0;

  int get categoryId => _categoryId ?? 0;

  int get currentPage => _currentPage ?? 0;

  int get lastPage => _lastPage ?? 0;

  int get total => _total ?? 0;

  List<ProductListItem> get productList => _productList ?? [];

  StoreProductList(
      {int? status, String? message, int? messageCode, int? storeId, int? categoryId, int? currentPage, int? lastPage, int? total, List<ProductListItem>? productList}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _storeId = storeId;
    _categoryId = categoryId;
    _currentPage = currentPage;
    _lastPage = lastPage;
    _total = total;
    _productList = productList;
  }

  StoreProductList.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _storeId = json["store_id"];
    _categoryId = json["category_id"];
    _currentPage = json["current_page"];
    _lastPage = json["last_page"];
    _total = json["total"];
    if (json["product_list"] != null) {
      _productList = [];
      json["product_list"].forEach((v) {
        _productList?.add(ProductListItem.fromJson(v));
      });
    }
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["store_id"] = _storeId;
    map["category_id"] = _categoryId;
    map["current_page"] = _currentPage;
    map["last_page"] = _lastPage;
    map["total"] = _total;
    if (_productList != null) {
      map["product_list"] = _productList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
