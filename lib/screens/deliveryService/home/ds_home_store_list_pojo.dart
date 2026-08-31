/// status : 1
/// message : "Success!"
/// message_code : 1
/// no_of_store : 36
/// filter_int_key : []
/// filter_string_key : [""]
/// category_list : [{"category_id":1,"category_name":"Chinese"},{"category_id":2,"category_name":"Combo"},{"category_id":3,"category_name":"Continental"},{"category_id":4,"category_name":"Sweets & Desserts"},{"category_id":5,"category_name":"Fast Food"},{"category_id":6,"category_name":"Local Food"},{"category_id":7,"category_name":"Fresh Food"}]
/// store_list : [{"store_id":48,"store_name":"Brooklyn Good","store_banner":"https://fox-jek.startuptrinity.com/assets/images/store-images/2191001202116084.jpg","store_products":"Combo","average_ratings":null,"total_reviews":100,"store_open_time":"","offer":"get $15 off on orders above $10","order_delivery_time":10,"order_min_amount":null,"store_status":1,"distance":null}]
library;

class DsHomeStoreListPojo {
  DsHomeStoreListPojo({
    int? status,
    String? message,
    int? messageCode,
    int? noOfStore,
    List<dynamic>? filterIntKey,
    List<String>? filterStringKey,
    List<CategoryListItem>? categoryList,
    List<StoreListItem>? storeList,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _noOfStore = noOfStore;
    _filterIntKey = filterIntKey;
    _filterStringKey = filterStringKey;
    _categoryList = categoryList;
    _storeList = storeList;
  }

  DsHomeStoreListPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    _noOfStore = json['no_of_store'];
    if (json['filter_int_key'] != null) {
      _filterIntKey = [];
      // json['filter_int_key'].forEach((v) {
      //   _filterIntKey.add(dynamic.fromJson(v));
      // });
    }
    _filterStringKey = json['filter_string_key'] != null ? json['filter_string_key'].cast<String>() : [];
    if (json['category_list'] != null) {
      _categoryList = [];
      json['category_list'].forEach((v) {
        _categoryList?.add(CategoryListItem.fromJson(v));
      });
    }
    if (json['store_list'] != null) {
      _storeList = [];
      json['store_list'].forEach((v) {
        _storeList?.add(StoreListItem.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  int? _noOfStore;
  List<dynamic>? _filterIntKey;
  List<String>? _filterStringKey;
  List<CategoryListItem>? _categoryList;
  List<StoreListItem>? _storeList;

  int? get status => _status;

  String? get message => _message;

  int? get messageCode => _messageCode;

  int? get noOfStore => _noOfStore;

  List<dynamic>? get filterIntKey => _filterIntKey;

  List<String>? get filterStringKey => _filterStringKey;

  List<CategoryListItem>? get categoryList => _categoryList;

  List<StoreListItem>? get storeList => _storeList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    map['no_of_store'] = _noOfStore;
    if (_filterIntKey != null) {
      map['filter_int_key'] = _filterIntKey?.map((v) => v.toJson()).toList();
    }
    map['filter_string_key'] = _filterStringKey;
    if (_categoryList != null) {
      map['category_list'] = _categoryList?.map((v) => v.toJson()).toList();
    }
    if (_storeList != null) {
      map['store_list'] = _storeList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// store_id : 48
/// store_name : "Brooklyn Good"
/// store_banner : "https://fox-jek.startuptrinity.com/assets/images/store-images/2191001202116084.jpg"
/// store_products : "Combo"
/// average_ratings : null
/// total_reviews : 100
/// store_open_time : ""
/// offer : "get $15 off on orders above $10"
/// order_delivery_time : 10
/// order_min_amount : null
/// store_status : 1
/// distance : null

class StoreListItem {
  StoreListItem({
    int? storeId,
    String? storeName,
    String? storeBanner,
    String? storeProducts,
    dynamic averageRatings,
    int? totalReviews,
    String? storeOpenTime,
    String? offer,
    int? orderDeliveryTime,
    dynamic orderMinAmount,
    int? storeStatus,
    dynamic distance,
  }) {
    _storeId = storeId;
    _storeName = storeName;
    _storeBanner = storeBanner;
    _storeProducts = storeProducts;
    _averageRatings = averageRatings;
    _totalReviews = totalReviews;
    _storeOpenTime = storeOpenTime;
    _offer = offer;
    _orderDeliveryTime = orderDeliveryTime;
    _orderMinAmount = orderMinAmount;
    _storeStatus = storeStatus;
    _distance = distance;
  }

  StoreListItem.fromJson(dynamic json) {
    _storeId = json['store_id'];
    _storeName = json['store_name'];
    _storeBanner = json['store_banner'];
    _storeProducts = json['store_products'];
    _averageRatings = json['average_ratings'];
    _totalReviews = json['total_reviews'];
    _storeOpenTime = json['store_open_time'];
    _offer = json['offer'];
    _orderDeliveryTime = json['order_delivery_time'];
    _orderMinAmount = json['order_min_amount'];
    _storeStatus = json['store_status'];
    _distance = json['distance'];
  }

  int? _storeId;
  String? _storeName;
  String? _storeBanner;
  String? _storeProducts;
  dynamic _averageRatings;
  int? _totalReviews;
  String? _storeOpenTime;
  String? _offer;
  int? _orderDeliveryTime;
  dynamic _orderMinAmount;
  int? _storeStatus;
  dynamic _distance;

  int? get storeId => _storeId;

  String? get storeName => _storeName;

  String? get storeBanner => _storeBanner;

  String? get storeProducts => _storeProducts;

  dynamic get averageRatings => _averageRatings;

  int? get totalReviews => _totalReviews;

  String? get storeOpenTime => _storeOpenTime;

  String? get offer => _offer;

  int? get orderDeliveryTime => _orderDeliveryTime;

  dynamic get orderMinAmount => _orderMinAmount;

  int? get storeStatus => _storeStatus;

  dynamic get distance => _distance;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['store_id'] = _storeId;
    map['store_name'] = _storeName;
    map['store_banner'] = _storeBanner;
    map['store_products'] = _storeProducts;
    map['average_ratings'] = _averageRatings;
    map['total_reviews'] = _totalReviews;
    map['store_open_time'] = _storeOpenTime;
    map['offer'] = _offer;
    map['order_delivery_time'] = _orderDeliveryTime;
    map['order_min_amount'] = _orderMinAmount;
    map['store_status'] = _storeStatus;
    map['distance'] = _distance;
    return map;
  }
}

/// category_id : 1
/// category_name : "Chinese"

class CategoryListItem {
  CategoryListItem({
    int? categoryId,
    String? categoryName,
  }) {
    _categoryId = categoryId;
    _categoryName = categoryName;
  }

  CategoryListItem.fromJson(dynamic json) {
    _categoryId = json['category_id'];
    _categoryName = json['category_name'];
  }

  int? _categoryId;
  String? _categoryName;

  int? get categoryId => _categoryId;

  String? get categoryName => _categoryName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['category_id'] = _categoryId;
    map['category_name'] = _categoryName;
    return map;
  }
}
