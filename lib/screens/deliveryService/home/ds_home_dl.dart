/// status : 1
/// message : "Success!"
/// no_of_store : 15
/// filter_int?_key : []
/// filter_String?_key : [""]
/// store_list : [{"store_id":1,"store_name":"Mc'd","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/7080439202012184.jpg","store_products":"Desserts,Cafe,Fast Food","average_ratings":4.88,"offer":"","order_delivery_time":60,"order_min_amount":10,"store_status":1},{"store_id":3,"store_name":"Chill Out","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/8094527202012187.png","store_products":"American,Italian,Beverages","average_ratings":0,"offer":"Get $200 off on orders above $10","order_delivery_time":30,"order_min_amount":100,"store_status":1},{"store_id":5,"store_name":"Kfc","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/8095746202012183.png","store_products":"Combo,Fast Food","average_ratings":4.5,"offer":"Get 25% off on orders above $150","order_delivery_time":30,"order_min_amount":100,"store_status":1},{"store_id":6,"store_name":"City Cafe ( A To Z Food )","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/1103434202012181.png","store_products":"American,Bakery,Beverages","average_ratings":4.62,"offer":"Get $15 off on orders above $150","order_delivery_time":30,"order_min_amount":80,"store_status":1},{"store_id":34,"store_name":"Food Set Go","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/9110906202012182.png","store_products":"Fast Food,Italian,Chinese,American","average_ratings":4.88,"offer":"Get $15.02 off on orders above $80","order_delivery_time":60,"order_min_amount":50,"store_status":1},{"store_id":41,"store_name":"Katak Batak","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/9270511202028101.jpg","store_products":"Fast Food,Beverages","average_ratings":3.42,"offer":"","order_delivery_time":60,"order_min_amount":50,"store_status":1},{"store_id":45,"store_name":"Rv's Café","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/5111644202012188.png","store_products":"Chinese","average_ratings":5,"offer":"Get $100 off on orders above $200","order_delivery_time":30,"order_min_amount":100,"store_status":1},{"store_id":48,"store_name":"Dns","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/2203107202018125.jpeg","store_products":"Italian","average_ratings":4,"offer":"","order_delivery_time":60,"order_min_amount":20,"store_status":1},{"store_id":49,"store_name":"Test","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/5391107202019125.jpg","store_products":"Bakery","average_ratings":4.5,"offer":"","order_delivery_time":20,"order_min_amount":1,"store_status":0},{"store_id":53,"store_name":"Boga Boga","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/7412523202118013.png","store_products":"Fast Food","average_ratings":0,"offer":"","order_delivery_time":20,"order_min_amount":0,"store_status":0},{"store_id":54,"store_name":"Big Bang","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/1413923202118014.jpg","store_products":"Fast Food","average_ratings":0,"offer":"","order_delivery_time":10,"order_min_amount":0,"store_status":1},{"store_id":55,"store_name":"Xyz","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/7410906202104028.PNG","store_products":"American","average_ratings":5,"offer":"","order_delivery_time":30,"order_min_amount":100,"store_status":1},{"store_id":56,"store_name":"Tgm","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/6570909202104029.PNG","store_products":"Italian,Fast Food,Desserts","average_ratings":4.15,"offer":"Get $10 off on orders above $100","order_delivery_time":15,"order_min_amount":100,"store_status":1},{"store_id":58,"store_name":"Mcdonald's","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/3334707202117021.jpg","store_products":"Fast Food","average_ratings":4.5,"offer":"Get 10% off on orders above $60","order_delivery_time":30,"order_min_amount":10,"store_status":0},{"store_id":59,"store_name":"Johns Carter","store_banner":"https://fox-food.startuptrinity.com/assets/images/store-images/7361609202117028.jpg","store_products":"Fast Food","average_ratings":3.5,"offer":"Get 10% off on orders above $100","order_delivery_time":15,"order_min_amount":10,"store_status":0}]
/// message_code :
/// service_slider_data : [{"id":1,"store_id":1,"service_category_id":5,"store_name":"Rone Store","banner_image":"https://fox-jekapp.startuptrinity.com/assets/images/service-slider-banner/5503210202225011.jpg"}]
library;

class DsHomeStoreListPojo {
  int? _status;
  String? _message;
  int? _noOfStore;
  List<StoreListItem>? _storeList;
  List<ServiceSliderData>? _serviceSliderData;
  int? _messageCode;

  int get status => _status ?? 0;

  int get noOfStore => _noOfStore ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  List<StoreListItem> get storeList => _storeList ?? [];

  List<ServiceSliderData> get serviceSliderData => _serviceSliderData ?? [];

  DsHomeStoreListPojo(
      {int? status,
      String? message,
      int? noOfStore,
      List<int>? filterintKey,
      List<String>? filterStringKey,
      List<StoreListItem>? storeList,
      // List<CategoryList> categoryList,
      List<ServiceSliderData>? serviceSliderData,
      int? messageCode}) {
    _status = status;
    _message = message;
    _noOfStore = noOfStore;
    _storeList = storeList;
    // _categoryList = categoryList;
    _serviceSliderData = serviceSliderData;
    _messageCode = messageCode;
  }

  DsHomeStoreListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _noOfStore = json["no_of_store"];
    if (json["store_list"] != null) {
      _storeList = [];
      json["store_list"].forEach((v) {
        _storeList?.add(StoreListItem.fromJson(v));
      });
    }
    // if (json['category_list'] != null) {
    //   _categoryList = [];
    //   json['category_list'].forEach((v) {
    //     _categoryList.add(CategoryList.fromJson(v));
    //   });
    // }
    if (json['service_slider_data'] != null) {
      _serviceSliderData = [];
      json['service_slider_data'].forEach((v) {
        _serviceSliderData?.add(ServiceSliderData.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["no_of_store"] = _noOfStore;
    if (_storeList != null) {
      map["store_list"] = _storeList?.map((v) => v.toJson()).toList();
    }
    // if (_categoryList != null) {
    //   map['category_list'] = _categoryList.map((v) => v.toJson()).toList();
    // }
    if (_serviceSliderData != null) {
      map['service_slider_data'] =
          _serviceSliderData?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

/// store_id : 1
/// store_name : "Mc'd"
/// store_banner : "https://fox-food.startuptrinity.com/assets/images/store-images/7080439202012184.jpg"
/// store_products : "Desserts,Cafe,Fast Food"
/// average_ratings : 4.88
/// offer : ""
/// order_delivery_time : 60
/// order_min_amount : 10
/// store_status : 1

class StoreListItem {
  int? _storeId;
  String? _storeName;
  String? _storeBanner;
  String? _storeProducts;
  String? _averageRatings;
  String? _offer;
  String? _description;
  dynamic _orderDeliveryTime;
  dynamic _orderMinAmount;
  double? _productMinAmount;
  double? _productMaxAmount;
  int? _storeStatus;

  int get storeId => _storeId ?? 0;

  int get storeStatus => _storeStatus ?? 0;

  String get storeName => _storeName ?? "";

  String get storeBanner => _storeBanner ?? "";

  String get storeProducts => _storeProducts ?? "";

  String get offer => _offer ?? "";

  String get description => _description ?? storeName;

  String get averageRatings => _averageRatings ?? "0.0";

  dynamic get orderDeliveryTime => _orderDeliveryTime;

  dynamic get orderMinAmount => _orderMinAmount;

  double get productMinAmount => _productMinAmount ?? 0.0;

  double get productMaxAmount => _productMaxAmount ?? 0.0;

  StoreListItem(
      {int? storeId,
      String? storeName,
      String? storeBanner,
      String? storeProducts,
      String? averageRatings,
      String? offer,
      String? description,
      dynamic orderDeliveryTime,
      dynamic orderMinAmount,
      double? productMinAmount,
      double? productMaxAmount,
      int? storeStatus}) {
    _storeId = storeId;
    _storeName = storeName;
    _storeBanner = storeBanner;
    _storeProducts = storeProducts;
    _averageRatings = averageRatings;
    _offer = offer;
    _description = description;
    _orderDeliveryTime = orderDeliveryTime;
    _orderMinAmount = orderMinAmount;
    _productMinAmount = productMinAmount;
    _productMaxAmount = productMaxAmount;
    _storeStatus = storeStatus;
  }

  StoreListItem.fromJson(dynamic json) {
    _storeId = json["store_id"];
    _storeName = json["store_name"];
    _storeBanner = json["store_banner"];
    _storeProducts = json["store_products"];
    _averageRatings = json["average_ratings"];
    _offer = json["offer"];
    _description = json["description"];
    _orderDeliveryTime = json["order_delivery_time"];
    _orderMinAmount = json["order_min_amount"];
    _productMinAmount = ((json["min_product_value"] ?? 0.0) as num).toDouble();
    _productMaxAmount = ((json["max_product_value"] ?? 0.0) as num).toDouble();
    _storeStatus = json["store_status"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["store_id"] = _storeId;
    map["store_name"] = _storeName;
    map["store_banner"] = _storeBanner;
    map["store_products"] = _storeProducts;
    map["average_ratings"] = _averageRatings;
    map["offer"] = _offer;
    map["description"] = _description;
    map["order_delivery_time"] = _orderDeliveryTime;
    map["order_min_amount"] = _orderMinAmount;
    map["min_product_value"] = _productMinAmount;
    map["max_product_value"] = _productMaxAmount;
    map["store_status"] = _storeStatus;
    return map;
  }
}

/// id : 1
/// store_id : 1
/// service_category_id : 5
/// store_name : "Rone Store"
/// banner_image : "https://fox-jekapp.startuptrinity.com/assets/images/service-slider-banner/5503210202225011.jpg"

class ServiceSliderData {
  ServiceSliderData({
    int? id,
    int? storeId,
    int? serviceCategoryId,
    String? storeName,
    String? bannerImage,
  }) {
    _id = id;
    _storeId = storeId;
    _serviceCategoryId = serviceCategoryId;
    _storeName = storeName;
    _bannerImage = bannerImage;
  }

  ServiceSliderData.fromJson(dynamic json) {
    _id = json['id'];
    _storeId = json['store_id'];
    _serviceCategoryId = json['service_category_id'];
    _storeName = json['store_name'];
    _bannerImage = json['banner_image'];
  }

  int? _id;
  int? _storeId;
  int? _serviceCategoryId;
  String? _storeName;
  String? _bannerImage;

  int get id => _id ?? 0;

  int get storeId => _storeId ?? 0;

  int get serviceCategoryId => _serviceCategoryId ?? 0;

  String get storeName => _storeName ?? "";

  String get bannerImage => _bannerImage ?? "";

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['id'] = _id;
    map['store_id'] = _storeId;
    map['service_category_id'] = _serviceCategoryId;
    map['store_name'] = _storeName;
    map['banner_image'] = _bannerImage;
    return map;
  }
}

class SortFilterItem {
  int? id;
  String? name, value;
  bool isSelected;

  SortFilterItem(this.id, this.name, this.isSelected, this.value);
}

/// status : 1
/// message : "success!"
/// product_category_list : [{"product_category_id":1,"product_category_name":"American"},{"product_category_id":2,"product_category_name":"Bakery"},{"product_category_id":3,"product_category_name":"Beverages"},{"product_category_id":4,"product_category_name":"Italian"},{"product_category_id":5,"product_category_name":"Cafe"},{"product_category_id":6,"product_category_name":"Chinese"},{"product_category_id":7,"product_category_name":"Combo"},{"product_category_id":8,"product_category_name":"Continental"},{"product_category_id":9,"product_category_name":"Desserts"},{"product_category_id":10,"product_category_name":"Fast Food"}]
/// message_code : 1

class StoreProductListPojo {
  int? _status;
  String? _message;
  List<DsProductCategoryListItem>? _productCategoryList;
  int? _messageCode;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  List<DsProductCategoryListItem> get productCategoryList =>
      _productCategoryList ?? [];

  StoreProductListPojo(
      {int? status,
      String? message,
      List<DsProductCategoryListItem>? productCategoryList,
      int? messageCode}) {
    _status = status;
    _message = message;
    _productCategoryList = productCategoryList;
    _messageCode = messageCode;
  }

  StoreProductListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["product_category_list"] != null) {
      _productCategoryList = [];
      json["product_category_list"].forEach((v) {
        _productCategoryList?.add(DsProductCategoryListItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_productCategoryList != null) {
      map["product_category_list"] =
          _productCategoryList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

/// product_category_id : 1
/// product_category_name : "American"

class DsProductCategoryListItem {
  int? _productCategoryId;
  String? _productCategoryName;
  bool isSelected = false;

  int get productCategoryId => _productCategoryId ?? 0;

  String get productCategoryName => _productCategoryName ?? "";

  DsProductCategoryListItem(
      {int? productCategoryId, String? productCategoryName}) {
    _productCategoryId = productCategoryId;
    _productCategoryName = productCategoryName;
  }

  DsProductCategoryListItem.fromJson(dynamic json) {
    _productCategoryId = json["product_category_id"];
    _productCategoryName = json["product_category_name"];
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["product_category_id"] = _productCategoryId;
    map["product_category_name"] = _productCategoryName;
    return map;
  }
}

class CategoryList {
  CategoryList({
    int? categoryId,
    String? categoryName,
  }) {
    _categoryId = categoryId;
    _categoryName = categoryName;
  }

  CategoryList.fromJson(dynamic json) {
    _categoryId = json['category_id'];
    _categoryName = json['category_name'];
  }

  int? _categoryId;
  String? _categoryName;

  int get categoryId => _categoryId ?? 0;

  String get categoryName => _categoryName ?? "";

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['category_id'] = _categoryId;
    map['category_name'] = _categoryName;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// service_category_id : 5
/// service_category_name : "توصيل طلبات الطعام"
/// service_category_icon : "https://fox-jekapp.startuptrinity.com/assets/images/service-category/food-delivery-128.png?v=0.3"
/// display_title_name : "ar-favorite "
/// store_lists : [{"id":1,"store_id":1,"service_category_id":5,"store_name":"Rone Store","store_products":"Chinese,Combo","average_ratings":0,"eta_delivery_time":60,"store_image":"https://fox-jekapp.startuptrinity.com/assets/images/store-images/1571410202227017.png","offer":"","order_min_amount":10,"store_status":0}]
/// view_all_btn : 0
/// total_page : 1
/// per_page : 1
/// current_page : 1

class FavouriteStorePojo {
  FavouriteStorePojo({
    int? status,
    String? message,
    int? messageCode,
    int? serviceCategoryId,
    String? serviceCategoryName,
    String? serviceCategoryIcon,
    String? displayTitleName,
    List<StoreListItem>? storeLists,
    int? viewAllBtn,
    int? totalPage,
    int? perPage,
    int? currentPage,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _serviceCategoryId = serviceCategoryId;
    _serviceCategoryName = serviceCategoryName;
    _serviceCategoryIcon = serviceCategoryIcon;
    _displayTitleName = displayTitleName;
    _storeLists = storeLists;
    _viewAllBtn = viewAllBtn;
    _totalPage = totalPage;
    _perPage = perPage;
    _currentPage = currentPage;
  }

  FavouriteStorePojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    _serviceCategoryId = json['service_category_id'];
    _serviceCategoryName = json['service_category_name'];
    _serviceCategoryIcon = json['service_category_icon'];
    _displayTitleName = json['display_title_name'];
    if (json['store_lists'] != null) {
      _storeLists = [];
      json['store_lists'].forEach((v) {
        _storeLists?.add(StoreListItem.fromJson(v));
      });
    }
    _viewAllBtn = json['view_all_btn'];
    _totalPage = json['total_page'];
    _perPage = json['per_page'];
    _currentPage = json['current_page'];
  }

  int? _status;
  String? _message;
  int? _messageCode;
  int? _serviceCategoryId;
  String? _serviceCategoryName;
  String? _serviceCategoryIcon;
  String? _displayTitleName;
  List<StoreListItem>? _storeLists;
  int? _viewAllBtn;
  int? _totalPage;
  int? _perPage;
  int? _currentPage;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get serviceCategoryId => _serviceCategoryId ?? 0;

  int get viewAllBtn => _viewAllBtn ?? 0;

  int get totalPage => _totalPage ?? 0;

  int get perPage => _perPage ?? 0;

  int get currentPage => _currentPage ?? 0;

  String get message => _message ?? "";

  String get serviceCategoryName => _serviceCategoryName ?? "";

  String get serviceCategoryIcon => _serviceCategoryIcon ?? "";

  String get displayTitleName => _displayTitleName ?? "";

  List<StoreListItem> get storeLists => _storeLists ?? [];

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    map['service_category_id'] = _serviceCategoryId;
    map['service_category_name'] = _serviceCategoryName;
    map['service_category_icon'] = _serviceCategoryIcon;
    map['display_title_name'] = _displayTitleName;
    if (_storeLists != null) {
      map['store_lists'] = _storeLists?.map((v) => v.toJson()).toList();
    }
    map['view_all_btn'] = _viewAllBtn;
    map['total_page'] = _totalPage;
    map['per_page'] = _perPage;
    map['current_page'] = _currentPage;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// product_category_list : [{"product_category_id":1,"product_category_name":"Chinese"},{"product_category_id":2,"product_category_name":"Combo"},{"product_category_id":3,"product_category_name":"Continental"},{"product_category_id":4,"product_category_name":"Sweets & Desserts"},{"product_category_id":5,"product_category_name":"Fast Food"},{"product_category_id":6,"product_category_name":"Local Food"},{"product_category_id":7,"product_category_name":"Fresh Food"}]

class ProductCategoryPojo {
  ProductCategoryPojo({
    int? status,
    String? message,
    int? messageCode,
    List<ProductCategoryList>? productCategoryList,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _productCategoryList = productCategoryList;
  }

  ProductCategoryPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    if (json['product_category_list'] != null) {
      _productCategoryList = [];
      json['product_category_list'].forEach((v) {
        _productCategoryList?.add(ProductCategoryList.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  List<ProductCategoryList>? _productCategoryList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<ProductCategoryList> get productCategoryList =>
      _productCategoryList ?? [];

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    if (_productCategoryList != null) {
      map['product_category_list'] =
          _productCategoryList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_category_id : 1
/// product_category_name : "Chinese"
/// product_category_icon : ""

class ProductCategoryList {
  ProductCategoryList({
    int? productCategoryId,
    String? productCategoryName,
    String? productCategoryIcon,
  }) {
    _productCategoryId = productCategoryId;
    _productCategoryName = productCategoryName;
    _productCategoryIcon = productCategoryIcon;
  }

  ProductCategoryList.fromJson(dynamic json) {
    _productCategoryId = json['product_category_id'];
    _productCategoryName = json['product_category_name'];
    _productCategoryIcon = json['category_icon'];
  }

  int? _productCategoryId;
  String? _productCategoryName;
  String? _productCategoryIcon;

  int get productCategoryId => _productCategoryId ?? 0;

  String get productCategoryName => _productCategoryName ?? "";

  String get productCategoryIcon => _productCategoryIcon ?? "";

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['product_category_id'] = _productCategoryId;
    map['product_category_name'] = _productCategoryName;
    map['category_icon'] = _productCategoryIcon;
    return map;
  }
}

class StoreCategoryPojo {
  StoreCategoryPojo({
    int? status,
    String? message,
    int? messageCode,
    List<StoreCategoryList>? storeCategoryList,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _storeCategoryList = storeCategoryList;
  }

  StoreCategoryPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    if (json['store_category_list'] != null) {
      _storeCategoryList = [];
      json['store_category_list'].forEach((v) {
        _storeCategoryList?.add(StoreCategoryList.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  List<StoreCategoryList>? _storeCategoryList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<StoreCategoryList> get storeCategoryList => _storeCategoryList ?? [];

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    if (_storeCategoryList != null) {
      map['store_category_list'] =
          _storeCategoryList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_category_id : 1
/// product_category_name : "Chinese"
/// product_category_icon : ""

class StoreCategoryList {
  StoreCategoryList({
    int? storeCategoryId,
    String? storeCategoryName,
    String? storeCategoryIcon,
  }) {
    _storeCategoryId = storeCategoryId;
    _storeCategoryName = storeCategoryName;
    _storeCategoryIcon = storeCategoryIcon;
  }

  StoreCategoryList.fromJson(dynamic json) {
    _storeCategoryId = json['category_id'];
    _storeCategoryName = json['category_name'];
    _storeCategoryIcon = json['category_icon'];
  }

  int? _storeCategoryId;
  String? _storeCategoryName;
  String? _storeCategoryIcon;

  int get storeCategoryId => _storeCategoryId ?? 0;

  String get storeCategoryName => _storeCategoryName ?? "";

  String get storeCategoryIcon => _storeCategoryIcon ?? "";

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['category_id'] = _storeCategoryId;
    map['category_name'] = _storeCategoryName;
    map['category_icon'] = _storeCategoryIcon;
    return map;
  }
}

class BrandCategoryPojo {
  BrandCategoryPojo({
    int? status,
    String? message,
    int? messageCode,
    List<BrandCategoryList>? brandCategoryList,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _brandCategoryList = brandCategoryList;
  }

  BrandCategoryPojo.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    if (json['brand_list'] != null) {
      _brandCategoryList = [];
      json['brand_list'].forEach((v) {
        _brandCategoryList?.add(BrandCategoryList.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  List<BrandCategoryList>? _brandCategoryList;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<BrandCategoryList> get brandCategoryList => _brandCategoryList ?? [];

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    if (_brandCategoryList != null) {
      map['brand_list'] = _brandCategoryList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_category_id : 1
/// product_category_name : "Chinese"
/// product_category_icon : ""

class BrandCategoryList {
  BrandCategoryList({
    int? brandId,
    String? brandName,
    String? brandIcon,
  }) {
    _brandId = brandId;
    _brandName = brandName;
    _brandIcon = brandIcon;
  }

  BrandCategoryList.fromJson(dynamic json) {
    _brandId = json['brand_id'];
    _brandName = json['brand_name'];
    _brandIcon = json['brand_icon'];
  }

  int? _brandId;
  String? _brandName;
  String? _brandIcon;

  int get brandId => _brandId ?? 0;

  String get brandName => _brandName ?? "";

  String get brandIcon => _brandIcon ?? "";

  Map<String?, dynamic> toJson() {
    final map = <String?, dynamic>{};
    map['brand_id'] = _brandId;
    map['brand_name'] = _brandName;
    map['brand_icon'] = _brandIcon;
    return map;
  }
}
