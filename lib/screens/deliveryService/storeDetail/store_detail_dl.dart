import '../../../networking/api_constant.dart';

/// Resolves API [product_image] values that may be full URLs or site-relative paths.
String normalizeStoreProductImageUrl(dynamic raw) {
  if (raw == null) return '';
  final String s = raw.toString().trim();
  if (s.isEmpty || s == 'null') return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('//')) return 'https:$s';
  final String base = BaseUrl.domain.endsWith('/')
      ? BaseUrl.domain.substring(0, BaseUrl.domain.length - 1)
      : BaseUrl.domain;
  final String path = s.startsWith('/') ? s : '/$s';
  return '$base$path';
}

/// status : 1
/// message : "Success!"
/// message_code : 1
/// store_id : 1
/// is_subcat_flow : 0
/// store_name : "Mc'd"
/// store_banner : "https://fox-food.startuptrinity.com/assets/images/store-images/7080439202012184.jpg"
/// store_status : 1
/// open_time : "00:01"
/// close_time : "23:59"
/// average_rating : 4.88
/// description : "“I'm Lovin' It”"
/// delivery_time : 60
/// order_min_amount : 10
/// offer : ""
/// offer_min_amount : 0
/// offer_percentage : 0
/// carts_selected_store_cate_id : 5
/// address : "Hardcastle Restaurants Pvt Ltd, McDonalds Family Restaurants Reliance Mall, Nana Mava, Rajkot, Gujarat 360005, India"
/// latitude : "22.2794211"
/// longitude : "70.77696279999999"
/// packaging_charges : 5
/// tax_in_percentage : 10
/// delivery_charges : 0
/// product_category : "Desserts,Cafe,Fast Food"
/// is_fav_store : 0
/// taken_away_type : 0
/// user_to_store_dist : 0
/// category_wise_product_list : [{"category_id":9,"category_name":"Desserts","product_count":2,"is_show_more":true,"product_list":[{"product_id":1,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6015907202018124.jpg","product_name":"Mcflurry Oreo Small","food_type":1,"product_amount":68.6,"discount_amount":70,"offer_discount":1.4,"description":"Taste the clouds with the soft vanilla serve, topped with creamy Oreo.","customize_list":[{"category_name":"Quantity","selection_type":1,"customize_type":1,"options":[{"id":1,"name":"50 Gram","amount":98,"discount_price":100,"category_name":"Quantity","selection_type":1},{"id":2,"name":"100 Gram","amount":166.6,"discount_price":170,"category_name":"Quantity","selection_type":1}]},{"category_name":"Choice of Sauce","selection_type":2,"customize_type":3,"options":[{"id":69,"name":"Choice Of Sauce","amount":10,"category_name":"Choice of Sauce","selection_type":2}]}]},{"product_id":2,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6471108202018124.jpg","product_name":"Choco Marble Slice Cake","food_type":2,"product_amount":101,"discount_amount":106,"offer_discount":5,"description":"Choco Marble Slice Cake","customize_list":[]}]},{"category_id":5,"category_name":"Cafe","product_count":2,"is_show_more":true,"product_list":[{"product_id":4,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6091309202018123.png","product_name":"Mcaloo Tikki Burger With Whole Wheat Bun","food_type":1,"product_amount":41,"discount_amount":0,"offer_discount":0,"description":"McAloo Tikki Burger with Whole Wheat Bun","customize_list":[{"category_name":"tomato sauce","selection_type":1,"customize_type":2,"options":[{"id":95,"name":"Tomato Sauce","amount":1,"category_name":"tomato sauce","selection_type":1}]},{"category_name":"mayonnaise sauce","selection_type":2,"customize_type":3,"options":[{"id":34,"name":"Mayonnaise Sauce","amount":10,"category_name":"mayonnaise sauce","selection_type":2}]}]},{"product_id":5,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6321609202018123.jpg","product_name":"Masala Wedges","food_type":2,"product_amount":35,"discount_amount":40,"offer_discount":5,"description":"Masala Wedges","customize_list":[{"category_name":"tomato sauce","selection_type":1,"customize_type":2,"options":[{"id":93,"name":"Tomato Sauce","amount":1,"category_name":"tomato sauce","selection_type":1}]},{"category_name":"mayonnaise sauce","selection_type":2,"customize_type":3,"options":[{"id":30,"name":"Mayonnaise Sauce - Small","amount":20,"category_name":"mayonnaise sauce","selection_type":2},{"id":32,"name":"Mayonnaise Sauce - Large","amount":30,"category_name":"mayonnaise sauce","selection_type":2}]}]}]},{"category_id":10,"category_name":"Fast Food","product_count":2,"is_show_more":false,"product_list":[{"product_id":110,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/7012239202010288.jpeg","product_name":"Pizza","food_type":2,"product_amount":55,"discount_amount":0,"offer_discount":0,"description":"","customize_list":[]},{"product_id":118,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/5101239202011027.jpg","product_name":"Mexican Passion Pizza","food_type":1,"product_amount":8.99,"discount_amount":9.99,"offer_discount":1,"description":"Sweet corn, olives, tomato, capsicum with harisa sauce","customize_list":[{"category_name":"Quantity","selection_type":1,"customize_type":1,"options":[{"id":72,"name":"Small [7 Inch]","amount":8.99,"discount_price":9.99,"category_name":"Quantity","selection_type":1},{"id":73,"name":"Medium [9 Inch]","amount":10.79,"discount_price":11.99,"category_name":"Quantity","selection_type":1},{"id":74,"name":"Large [12 Inch]","amount":13.49,"discount_price":14.99,"category_name":"Quantity","selection_type":1}]},{"category_name":"Topping","selection_type":2,"customize_type":3,"options":[{"id":53,"name":"Tomato","amount":0.5,"category_name":"Topping","selection_type":2},{"id":54,"name":"Capsicum","amount":0.5,"category_name":"Topping","selection_type":2},{"id":55,"name":"Onion","amount":0.5,"category_name":"Topping","selection_type":2},{"id":56,"name":"Cheese","amount":2,"category_name":"Topping","selection_type":2}]},{"category_name":"Extras","selection_type":2,"customize_type":3,"options":[{"id":57,"name":"Cold Drinks","amount":3,"category_name":"Extras","selection_type":2},{"id":58,"name":"Sauce","amount":0,"category_name":"Extras","selection_type":2}]}]}]}]
/// "store_open_close_time":[{"id":29,"day":"SUN","display_day":"Sun","store_open_time":"00:07:00","store_close_time":"23:07:00"},{"id":30,"day":"MON","display_day":"Mon","store_open_time":"00:00:00","store_close_time":"23:07:00"},{"id":31,"day":"TUE","display_day":"Tue","store_open_time":"00:00:00","store_close_time":"23:08:00"},{"id":32,"day":"WED","display_day":"Wed","store_open_time":"00:00:00","store_close_time":"23:08:00"},{"id":33,"day":"THU","display_day":"Thu","store_open_time":"00:00:00","store_close_time":"23:08:00"},{"id":34,"day":"FRI","display_day":"Fri","store_open_time":"00:00:00","store_close_time":"23:08:00"},{"id":35,"day":"SAT","display_day":"Sat","store_open_time":"00:00:00","store_close_time":"23:08:00"}],

class StoreDetailsPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _storeId;
  int? _isSubCatFlow;
  String? _storeName;
  String? _storeBanner;
  String? _storeLogo;
  String? _storeCatName;
  String? _storeCatIcon;
  String? _storeEmail;
  String? _storeContactNumber;
  int? _storeStatus;
  int? _cartsSelectedStoreCateId;
  String? _openTime;
  String? _closeTime;
  dynamic _averageRating;
  String? _description;
  dynamic _deliveryTime;
  dynamic _orderMinAmount;
  String? _offer;
  dynamic _offerMinAmount;
  dynamic _offerPercentage;
  String? _address;
  String? _latitude;
  String? _longitude;
  dynamic _serviceRadius;
  dynamic _packagingCharges;
  dynamic _taxInPercentage;
  dynamic _deliveryCharges;
  dynamic _userToStoreDist;
  String? _productCategory;
  int? _isFavourite;
  int? _takenAwayType;
  List<CategoryWiseProductListItem>? _categoryWiseProductList;
  List<StoreOpenCloseTime>? _storeOpenCloseTime;

  int get status => _status ?? 0;

  int get isFavourite => _isFavourite ?? 0;

  int get takenAwayType => _takenAwayType ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get storeId => _storeId ?? 0;

  int get isSubCatFlow => _isSubCatFlow ?? 0;

  int get storeStatus => _storeStatus ?? 0;

  int get cartsSelectedStoreCateId => _cartsSelectedStoreCateId ?? 0;

  String get message => _message ?? "";

  String get storeName => _storeName ?? "";

  String get storeBanner => _storeBanner ?? "";

  String get storeLogo => _storeLogo ?? "";

  String get storeCatName => _storeCatName ?? "";

  String get storeCatIcon => _storeCatIcon ?? "";

  String get storeEmail => _storeEmail ?? "";

  String get storeContactNumber => _storeContactNumber ?? "";

  String get openTime => _openTime ?? "";

  String get closeTime => _closeTime ?? "";

  String get address => _address ?? "";

  String get latitude => _latitude ?? "";

  String get longitude => _longitude ?? "";

  dynamic get serviceRadius => _serviceRadius;

  String get description => _description ?? "";

  String get offer => _offer ?? "";

  String get productCategory => _productCategory ?? "";

  dynamic get averageRating => _averageRating;

  dynamic get deliveryTime => _deliveryTime;

  dynamic get orderMinAmount => _orderMinAmount;

  dynamic get offerMinAmount => _offerMinAmount;

  dynamic get offerPercentage => _offerPercentage;

  dynamic get packagingCharges => _packagingCharges;

  dynamic get taxInPercentage => _taxInPercentage;

  dynamic get deliveryCharges => _deliveryCharges;

  dynamic get userToStoreDist => _userToStoreDist;

  setIsFavourite(int isFav) {
    _isFavourite = isFav;
  }

  setCartsSelectedStoreCateId(int cartsSelectedStoreCateId) {
    _cartsSelectedStoreCateId = cartsSelectedStoreCateId;
  }

  setStoreCatName(String storeCatName) {
    _storeCatName = storeCatName;
  }

  setStoreCatIcon(String storeCatIcon) {
    _storeCatIcon = storeCatIcon;
  }

  List<CategoryWiseProductListItem> get categoryWiseProductList =>
      _categoryWiseProductList ?? [];

  List<StoreOpenCloseTime> get storeOpenCloseTime => _storeOpenCloseTime ?? [];

  setCategoryWiseProductList(
      List<CategoryWiseProductListItem> categoryWiseProductList) {
    _categoryWiseProductList = categoryWiseProductList;
  }

  StoreDetailsPojo(
      {int? status,
      String? message,
      int? messageCode,
      int? storeId,
      int? isSubCatFlow,
      String? storeName,
      String? storeBanner,
      String? storeLogo,
      int? storeStatus,
      int? cartsSelectedStoreCateId,
      String? storeCatName,
      String? storeCatIcon,
      String? storeEmail,
      String? storeContactNumber,
      String? openTime,
      String? closeTime,
      dynamic averageRating,
      String? description,
      dynamic deliveryTime,
      dynamic orderMinAmount,
      String? offer,
      dynamic offerMinAmount,
      dynamic offerPercentage,
      String? address,
      String? latitude,
      String? longitude,
      dynamic serviceRadius,
      dynamic packagingCharges,
      dynamic taxInPercentage,
      dynamic deliveryCharges,
      dynamic userToStoreDist,
      String? productCategory,
      int? isFavourite,
      int? takenAwayType,
      List<CategoryWiseProductListItem>? categoryWiseProductList,
      List<StoreOpenCloseTime>? storeOpenCloseTime}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _storeId = storeId;
    _isSubCatFlow = isSubCatFlow;
    _storeName = storeName;
    _storeBanner = storeBanner;
    _storeLogo = storeLogo;
    _storeStatus = storeStatus;
    _cartsSelectedStoreCateId = cartsSelectedStoreCateId;
    _storeCatName = storeCatName;
    _storeCatIcon = storeCatIcon;
    _storeEmail = storeEmail;
    _storeContactNumber = storeContactNumber;
    _openTime = openTime;
    _closeTime = closeTime;
    _averageRating = averageRating;
    _description = description;
    _deliveryTime = deliveryTime;
    _orderMinAmount = orderMinAmount;
    _offer = offer;
    _offerMinAmount = offerMinAmount;
    _offerPercentage = offerPercentage;
    _address = address;
    _latitude = latitude;
    _longitude = longitude;
    _serviceRadius = serviceRadius;
    _packagingCharges = packagingCharges;
    _taxInPercentage = taxInPercentage;
    _deliveryCharges = deliveryCharges;
    _userToStoreDist = userToStoreDist;
    _productCategory = productCategory;
    _isFavourite = isFavourite;
    _takenAwayType = takenAwayType;
    _categoryWiseProductList = categoryWiseProductList;
    _storeOpenCloseTime = storeOpenCloseTime;
  }

  StoreDetailsPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _storeId = json["store_id"];
    _isSubCatFlow = json["is_subcat_flow"];
    _storeName = json["store_name"];
    _storeBanner = json["store_banner"];
    _storeLogo = json["store_logo"];
    _storeStatus = json["store_status"];
    _cartsSelectedStoreCateId = json["carts_selected_store_cate_id"];
    _storeCatName = json["store_cat_name"];
    _storeCatIcon = json["store_cat_icon"];
    _storeEmail = json["store_email"];
    _storeContactNumber = json["store_contact_number"];
    _openTime = json["open_time"];
    _closeTime = json["close_time"];
    _averageRating = json["average_rating"];
    _description = json["description"];
    _deliveryTime = json["delivery_time"];
    _orderMinAmount = json["order_min_amount"];
    _offer = json["offer"];
    _offerMinAmount = json["offer_min_amount"];
    _offerPercentage = json["offer_percentage"];
    _address = json["address"];
    _latitude = json["latitude"];
    _longitude = json["longitude"];
    _serviceRadius = json["service_radius"];
    _packagingCharges = json["packaging_charges"];
    _taxInPercentage = json["tax_in_percentage"];
    _deliveryCharges = json["delivery_charges"];
    _userToStoreDist = json["user_to_store_dist"];
    _productCategory = json["product_category"];
    _isFavourite = json["is_fav_store"];
    _takenAwayType = json["taken_away_type"];
    if (json["category_wise_product_list"] != null) {
      _categoryWiseProductList = [];
      json["category_wise_product_list"].forEach((v) {
        _categoryWiseProductList?.add(CategoryWiseProductListItem.fromJson(v));
      });
    }
    if (json['store_open_close_time'] != null) {
      _storeOpenCloseTime = [];
      json['store_open_close_time'].forEach((v) {
        _storeOpenCloseTime?.add(StoreOpenCloseTime.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["store_id"] = _storeId;
    map["is_subcat_flow"] = _isSubCatFlow;
    map["store_name"] = _storeName;
    map["store_banner"] = _storeBanner;
    map["store_logo"] = _storeLogo;
    map["store_status"] = _storeStatus;
    map["carts_selected_store_cate_id"] = _cartsSelectedStoreCateId;
    map["store_cat_name"] = _storeCatName;
    map["store_cat_icon"] = _storeCatIcon;
    map["store_email"] = _storeEmail;
    map["store_contact_number"] = _storeContactNumber;
    map["open_time"] = _openTime;
    map["close_time"] = _closeTime;
    map["average_rating"] = _averageRating;
    map["description"] = _description;
    map["delivery_time"] = _deliveryTime;
    map["order_min_amount"] = _orderMinAmount;
    map["offer"] = _offer;
    map["offer_min_amount"] = _offerMinAmount;
    map["offer_percentage"] = _offerPercentage;
    map["address"] = _address;
    map["latitude"] = _latitude;
    map["longitude"] = _longitude;
    map["packaging_charges"] = _packagingCharges;
    map["tax_in_percentage"] = _taxInPercentage;
    map["delivery_charges"] = _deliveryCharges;
    map["user_to_store_dist"] = _userToStoreDist;
    map["product_category"] = _productCategory;
    map["is_fav_store"] = _isFavourite;
    map["taken_away_type"] = _takenAwayType;
    if (_categoryWiseProductList != null) {
      map["category_wise_product_list"] =
          _categoryWiseProductList?.map((v) => v.toJson()).toList();
    }
    if (_storeOpenCloseTime != null) {
      map['store_open_close_time'] =
          _storeOpenCloseTime?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 29
/// day : "SUN"
/// display_day : "Sun"
/// store_open_time : "00:07:00"
/// store_close_time : "23:07:00"

class StoreOpenCloseTime {
  StoreOpenCloseTime({
    int? id,
    String? day,
    String? displayDay,
    String? storeOpenTime,
    String? storeCloseTime,
  }) {
    _id = id;
    _day = day;
    _displayDay = displayDay;
    _storeOpenTime = storeOpenTime;
    _storeCloseTime = storeCloseTime;
  }

  StoreOpenCloseTime.fromJson(dynamic json) {
    _id = json['id'];
    _day = json['day'];
    _displayDay = json['display_day'];
    _storeOpenTime = json['store_open_time'];
    _storeCloseTime = json['store_close_time'];
  }

  int? _id;
  String? _day;
  String? _displayDay;
  String? _storeOpenTime;
  String? _storeCloseTime;

  int get id => _id ?? 0;

  String get day => _day ?? "";

  String get displayDay => _displayDay ?? "";

  String get storeOpenTime => _storeOpenTime ?? "";

  String get storeCloseTime => _storeCloseTime ?? "";

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['day'] = _day;
    map['display_day'] = _displayDay;
    map['store_open_time'] = _storeOpenTime;
    map['store_close_time'] = _storeCloseTime;
    return map;
  }
}

/// category_id : 9
/// category_name : "Desserts"
/// product_count : 2
/// is_show_more : true
/// product_list : [{"product_id":1,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6015907202018124.jpg","product_name":"Mcflurry Oreo Small","food_type":1,"product_amount":68.6,"discount_amount":70,"offer_discount":1.4,"description":"Taste the clouds with the soft vanilla serve, topped with creamy Oreo.","customize_list":[{"category_name":"Quantity","selection_type":1,"customize_type":1,"options":[{"id":1,"name":"50 Gram","amount":98,"discount_price":100,"category_name":"Quantity","selection_type":1},{"id":2,"name":"100 Gram","amount":166.6,"discount_price":170,"category_name":"Quantity","selection_type":1}]},{"category_name":"Choice of Sauce","selection_type":2,"customize_type":3,"options":[{"id":69,"name":"Choice Of Sauce","amount":10,"category_name":"Choice of Sauce","selection_type":2}]}]},{"product_id":2,"product_image":"https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6471108202018124.jpg","product_name":"Choco Marble Slice Cake","food_type":2,"product_amount":101,"discount_amount":106,"offer_discount":5,"description":"Choco Marble Slice Cake","customize_list":[]}]

class CategoryWiseProductListItem {
  int? _categoryId;
  String? _categoryName;
  String? _categoryIcon;
  bool? _isShowMore;
  List<SubCategoryWiseProductListItem>? _subCategoryList;

  int get categoryId => _categoryId ?? 0;

  String get categoryName => _categoryName ?? "";

  String get categoryIcon => _categoryIcon ?? "";

  bool get isShowMore => _isShowMore ?? false;

  List<SubCategoryWiseProductListItem> get subCategoryList =>
      _subCategoryList ?? [];

  setProductList(List<SubCategoryWiseProductListItem> subCategoryList) {
    _subCategoryList = subCategoryList;
  }

  CategoryWiseProductListItem(
      {int? categoryId,
      String? categoryName,
      String? categoryIcon,
      bool? isShowMore,
      List<SubCategoryWiseProductListItem>? productList}) {
    _categoryId = categoryId;
    _categoryName = categoryName;
    _categoryIcon = categoryIcon;
    _isShowMore = isShowMore;
    _subCategoryList = subCategoryList;
  }

  CategoryWiseProductListItem.fromJson(dynamic json) {
    _categoryId = json["category_id"];
    _categoryName = json["category_name"];
    _categoryIcon = json["category_icon"];
    _isShowMore = json["is_show_more"];
    if (json["sub_category_list"] != null) {
      _subCategoryList = [];
      json["sub_category_list"].forEach((v) {
        _subCategoryList?.add(SubCategoryWiseProductListItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["category_id"] = _categoryId;
    map["category_name"] = _categoryName;
    map["category_icon"] = _categoryIcon;
    map["is_show_more"] = _isShowMore;
    if (_subCategoryList != null) {
      map["sub_category_list"] =
          _subCategoryList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class SubCategoryWiseProductListItem {
  int? _subCategoryId;
  String? _subCategoryName;
  String? _subCategoryIcon;
  bool? _isShowMore;
  List<ProductListItem>? _productList;

  int get subCategoryId => _subCategoryId ?? 0;

  String get subCategoryName => _subCategoryName ?? "";

  String get subCategoryIcon => _subCategoryIcon ?? "";

  bool get isShowMore => _isShowMore ?? false;

  List<ProductListItem> get productList => _productList ?? [];

  setProductList(List<ProductListItem> productList) {
    _productList = productList;
  }

  SubCategoryWiseProductListItem(
      {int? subCategoryId,
      String? subCategoryName,
      String? subCategoryIcon,
      bool? isShowMore,
      List<ProductListItem>? productList}) {
    _subCategoryId = subCategoryId;
    _subCategoryName = subCategoryName;
    _subCategoryIcon = subCategoryIcon;
    _isShowMore = isShowMore;
    _productList = productList;
  }

  SubCategoryWiseProductListItem.fromJson(dynamic json) {
    _subCategoryId = json["sub_category_id"];
    _subCategoryName = json["sub_category_name"];
    _subCategoryIcon = json["sub_category_icon"];
    _isShowMore = json["is_show_more"];
    if (json["product_list"] != null) {
      _productList = [];
      json["product_list"].forEach((v) {
        _productList?.add(ProductListItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["sub_category_id"] = _subCategoryId;
    map["sub_category_name"] = _subCategoryName;
    map["sub_category_icon"] = _subCategoryIcon;
    map["is_show_more"] = _isShowMore;
    if (_productList != null) {
      map["product_list"] = _productList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_id : 1
/// product_image : "https://fox-food.startuptrinity.com/assets/images/store-images/product-images/6015907202018124.jpg"
/// product_name : "Mcflurry Oreo Small"
/// food_type : 1
/// product_amount : 68.6
/// discount_amount : 70
/// offer_discount : 1.4
/// description : "Taste the clouds with the soft vanilla serve, topped with creamy Oreo."
/// customize_list : [{"category_name":"Quantity","selection_type":1,"customize_type":1,"options":[{"id":1,"name":"50 Gram","amount":98,"discount_price":100,"category_name":"Quantity","selection_type":1},{"id":2,"name":"100 Gram","amount":166.6,"discount_price":170,"category_name":"Quantity","selection_type":1}]},{"category_name":"Choice of Sauce","selection_type":2,"customize_type":3,"options":[{"id":69,"name":"Choice Of Sauce","amount":10,"category_name":"Choice of Sauce","selection_type":2}]}]

class ProductListItem {
  int? _productId;
  String? _productImage;
  List<dynamic>? _productImageList;
  String? _productName;
  int? _categoryId;
  String? _categoryName;
  int? _brandId;
  int? _foodType;
  int? _sizeOptional;
  int? _colorOptional;
  dynamic _productAmount;
  dynamic _originalAmount;
  dynamic _discountAmount;
  int? _discountPercent;
  dynamic _offerDiscount;
  String? _description;
  int? _rateSum;
  int? _rateCount;
  List<CustomizeItem>? _customizeList;

  int get productId => _productId ?? 0;

  int get foodType => _foodType ?? 0;

  int get sizeOptional => _sizeOptional ?? 0;

  int get colorOptional => _colorOptional ?? 0;

  String get productImage => _productImage ?? "";

  List<dynamic> get productImageList => _productImageList ?? [];

  String get productName => _productName ?? "";

  int get categoryId => _categoryId ?? 0;

  String get categoryName => _categoryName ?? "";

  int get brandId => _brandId ?? 0;

  String get description => _description ?? "";

  dynamic get productAmount => _productAmount;

  dynamic get originalAmount => _originalAmount;

  dynamic get discountAmount => _discountAmount;

  int get discountPercent => _discountPercent ?? 0;

  int get rateSum => _rateSum ?? 0;

  int get rateCount => _rateCount ?? 0;

  dynamic get offerDiscount => _offerDiscount;

  List<CustomizeItem> get customizeList => _customizeList ?? [];

  /// Whether the API returned at least one non-empty image URL (after normalization).
  bool get hasProductImage {
    if (productImage.trim().isNotEmpty) return true;
    for (final dynamic e in productImageList) {
      if (normalizeStoreProductImageUrl(e).isNotEmpty) return true;
    }
    return false;
  }

  ProductListItem(
      {int? productId,
      String? productImage,
      String? productName,
      int? categoryId,
      String? categoryName,
      int? brandId,
      int? foodType,
      int? sizeOptional,
      int? colorOptional,
      List<dynamic>? productImageList,
      dynamic productAmount,
      dynamic originalAmount,
      dynamic discountAmount,
      dynamic offerDiscount,
      String? description,
      int? discountPercent,
      int? rateSum,
      int? rateAmount,
      List<CustomizeItem>? customizeList}) {
    _productId = productId;
    _productImage = productImage;
    _productImageList = productImageList;
    _productName = productName;
    _categoryId = categoryId;
    _categoryName = categoryName;
    _brandId = brandId;
    _foodType = foodType;
    _sizeOptional = sizeOptional;
    _colorOptional = colorOptional;
    _productAmount = productAmount;
    _originalAmount = originalAmount;
    _discountAmount = discountAmount;
    _discountPercent = discountPercent;
    _offerDiscount = offerDiscount;
    _description = description;
    _rateSum = rateSum;
    _rateCount = rateCount;
    _customizeList = customizeList;
  }

  ProductListItem.fromJson(dynamic json) {
    _productId = json["product_id"];
    final dynamic rawImage =
        json["product_image"] ?? json["image"] ?? json["productImage"];
    _productImage = normalizeStoreProductImageUrl(rawImage);
    final dynamic rawList = json["product_image_list"] ?? json["productImageList"];
    if (rawList is List) {
      _productImageList = rawList
          .map((e) => normalizeStoreProductImageUrl(e))
          .where((String s) => s.isNotEmpty)
          .toList();
    } else {
      _productImageList = json["product_image_list"];
    }
    if ((_productImage ?? '').isEmpty &&
        _productImageList != null &&
        _productImageList!.isNotEmpty) {
      _productImage = _productImageList![0].toString();
    }
    _productName = json["product_name"];
    _categoryId = json["category_id"];
    _categoryName = json["category_name"];
    _brandId = json["brand_id"];
    _foodType = json["food_type"];
    _sizeOptional = json["size_optoinal"];
    _colorOptional = json["color_optional"];
    _productAmount = json["product_amount"];
    _originalAmount = json["original_amount"];
    _discountAmount = json["discount_amount"];
    _discountPercent = json["discount_percent"];
    _offerDiscount = json["offer_discount"];
    _description = json["description"];
    _rateSum = json["rate_sum"];
    _rateCount = json["rate_count"];
    if (json["customize_list"] != null) {
      _customizeList = [];
      json["customize_list"].forEach((v) {
        _customizeList?.add(CustomizeItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["product_id"] = _productId;
    map["product_image"] = _productImage;
    map["product_image_list"] = _productImageList;
    map["product_name"] = _productName;
    map["brand_id"] = _brandId;
    map["food_type"] = _foodType;
    map["product_amount"] = _productAmount;
    map["original_amount"] = _originalAmount;
    map["discount_amount"] = _discountAmount;
    map["discount_percent"] = _discountPercent;
    map["offer_discount"] = _offerDiscount;
    map["description"] = _description;
    map["rate_sum"] = _rateSum;
    map["rate_count"] = _rateCount;
    if (_customizeList != null) {
      map["customize_list"] = _customizeList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// category_name : "Quantity"
/// selection_type : 1
/// customize_type : 1
/// options : [{"id":1,"name":"50 Gram","amount":98,"discount_price":100,"category_name":"Quantity","selection_type":1},{"id":2,"name":"100 Gram","amount":166.6,"discount_price":170,"category_name":"Quantity","selection_type":1}]

class CustomizeItem {
  String? _categoryName;
  int? _selectionType;
  int? _customizeType;
  List<OptionsItem>? _options;
  String selected = "";
  double totalAmount = 0;

  String get categoryName => _categoryName ?? "";

  int get selectionType => _selectionType ?? 0;

  int get customizeType => _customizeType ?? 0;

  List<OptionsItem> get options => _options ?? [];

  CustomizeItem(
      {String? categoryName,
      int? selectionType,
      int? customizeType,
      List<OptionsItem>? options}) {
    _categoryName = categoryName;
    _selectionType = selectionType;
    _customizeType = customizeType;
    _options = options;
  }

  CustomizeItem.fromJson(dynamic json) {
    _categoryName = json["category_name"];
    _selectionType = json["selection_type"];
    _customizeType = json["customize_type"];
    if (json["options"] != null) {
      _options = [];
      json["options"].forEach((v) {
        _options?.add(OptionsItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["category_name"] = _categoryName;
    map["selection_type"] = _selectionType;
    map["customize_type"] = _customizeType;
    if (_options != null) {
      map["options"] = _options?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 1
/// name : "50 Gram"
/// amount : 98
/// discount_price : 100
/// category_name : "Quantity"
/// selection_type : 1

class OptionsItem {
  int? _id;
  String? _name;
  dynamic _amount;
  dynamic _discountPrice;
  String? _categoryName;
  int? _selectionType;
  int? selectedId = 0;

  int get id => _id ?? 0;

  int get selectionType => _selectionType ?? 0;

  String get name => _name ?? "";

  String get categoryName => _categoryName ?? "";

  dynamic get amount => _amount;

  dynamic get discountPrice => _discountPrice;

  OptionsItem(
      {int? id,
      String? name,
      dynamic amount,
      dynamic discountPrice,
      String? categoryName,
      int? selectionType}) {
    _id = id;
    _name = name;
    _amount = amount;
    _discountPrice = discountPrice;
    _categoryName = categoryName;
    _selectionType = selectionType;
  }

  OptionsItem.fromJson(dynamic json) {
    _id = json["id"];
    _name = json["name"];
    _amount = json["amount"];
    _discountPrice = json["discount_price"];
    _categoryName = json["category_name"];
    _selectionType = json["selection_type"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["name"] = _name;
    map["amount"] = _amount;
    map["discount_price"] = _discountPrice;
    map["category_name"] = _categoryName;
    map["selection_type"] = _selectionType;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// is_favourite : 1

class ModelAddFavourite {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _isFavourite;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get isFavourite => _isFavourite ?? 0;

  ModelAddFavourite(
      {int? status, String? message, int? messageCode, int? isFavourite}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _isFavourite = isFavourite;
  }

  ModelAddFavourite.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _isFavourite = json["is_favourite"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["is_favourite"] = _isFavourite;
    return map;
  }
}

/// status : 1
/// message : "success!"
/// store_rating_list : [{"id":115,"rating":5,"comment":null,"first_name":"John","last_name":"Doe"},{"id":42,"rating":5,"comment":"very good","first_name":"Kevin","last_name":"Kaneriya"},{"id":37,"rating":4.5,"comment":"very good store","first_name":"Ft","last_name":"Urmish"},{"id":7,"rating":5,"comment":null,"first_name":"Ft","last_name":"Kamlesh"}]
/// message_code : 1

class StoreReviewListPojo {
  int? _status;
  String? _message;
  List<StoreRatingListItem>? _storeRatingList;
  int? _messageCode;

  String get message => _message ?? "";

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  List<StoreRatingListItem> get storeRatingList => _storeRatingList ?? [];

  StoreReviewListPojo(
      {int? status,
      String? message,
      List<StoreRatingListItem>? storeRatingList,
      int? messageCode}) {
    _status = status;
    _message = message;
    _storeRatingList = storeRatingList;
    _messageCode = messageCode;
  }

  StoreReviewListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    if (json["store_rating_list"] != null) {
      _storeRatingList = [];
      json["store_rating_list"].forEach((v) {
        _storeRatingList?.add(StoreRatingListItem.fromJson(v));
      });
    }
    _messageCode = json["message_code"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    if (_storeRatingList != null) {
      map["store_rating_list"] =
          _storeRatingList?.map((v) => v.toJson()).toList();
    }
    map["message_code"] = _messageCode;
    return map;
  }
}

/// id : 115
/// rating : 5
/// comment : null
/// first_name : "John"
/// last_name : "Doe"

class StoreRatingListItem {
  int? _id;
  dynamic _rating;
  dynamic _comment;
  String? _firstName;
  String? _lastName;

  int get id => _id ?? 0;

  dynamic get rating => _rating;

  dynamic get comment => _comment;

  String get firstName => _firstName ?? "";

  String get lastName => _lastName ?? "";

  StoreRatingListItem(
      {int? id,
      dynamic rating,
      dynamic comment,
      String? firstName,
      String? lastName}) {
    _id = id;
    _rating = rating;
    _comment = comment;
    _firstName = firstName;
    _lastName = lastName;
  }

  StoreRatingListItem.fromJson(dynamic json) {
    _id = json["id"];
    _rating = json["rating"];
    _comment = json["comment"];
    _firstName = json["first_name"];
    _lastName = json["last_name"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["rating"] = _rating;
    map["comment"] = _comment;
    map["first_name"] = _firstName;
    map["last_name"] = _lastName;
    return map;
  }
}

class UserOrderCartPojo {
  int? _status;
  int? _countOrder;
  double? _orderAmount;
  int? _messageCode;
  String? _message;

  int get countOrder => _countOrder ?? 0;
  double get orderAmount => _orderAmount ?? 0.0;
  int get status => _status ?? 0;
  int get messageCode => _messageCode ?? 0;
  String get message => _message ?? "";

  UserOrderCartPojo({
    int? status,
    int? countOrder,
    double? orderAmount,
    int? messageCode,
    String? message,
  }) {
    _status = status;
    _countOrder = countOrder;
    _orderAmount = orderAmount;
    _messageCode = messageCode;
    _message = message;
  }

  UserOrderCartPojo.fromJson(dynamic json) {
    _status = json["status"];
    _countOrder = json["count_order"];
    _orderAmount = (json["order_amount"] as num?)?.toDouble() ?? 0.0;
    _messageCode = json["message_code"];
    _message = json["message"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["count_order"] = _countOrder;
    map["orderAmount"] = _orderAmount;
    map["messageCode"] = _messageCode;
    map["message"] = _message;
    return map;
  }
}
