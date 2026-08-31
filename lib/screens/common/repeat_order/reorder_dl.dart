/// status : 1
/// message : "success!"
/// message_code : 1
/// reorder_id : 211
/// store_id : 7
/// service_category_id : 5
/// store_name : "Food Zone"
/// store_banner : "https://fox-jekapp.startuptrinity.com/assets/images/store-images/5500012202212022.jpg"
/// store_status : 1
/// average_rating : 4.4
/// product_category : "Pizza,Burger,Sandwich,Italian"
/// description : ""
/// delivery_time : 10
/// order_min_amount : 100
/// offer : "Get $50 off on orders above $50"
/// offer_min_amount : 50
/// offer_amount : 50
/// offer_type : 1
/// offer_percentage : 50
/// is_fav_store : 1
/// taken_away_type : 2
/// address : "Bus Stop, 150 Feet Ring Rd, near Sheetalpark, Sheetal Park, Manharpura 1, Madhapar, Rajkot, Gujarat 360007, India"
/// latitude : "22.3188969"
/// longitude : "70.7671579"
/// packaging_charges : 10
/// order_detail : [{"product_id":58,"product_name":"Mexican Mcaloo Tikki Burger","product_amount":12,"product_total_amount":15.77,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":"4,5,6"},{"product_id":282,"product_name":"Cheese Lava American Veg Burger","product_amount":5,"product_total_amount":7,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":"7"},{"product_id":285,"product_name":"Mcaloo Tikki Burger","product_amount":7,"product_total_amount":7,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":""},{"product_id":283,"product_name":"Two Mcveggie Burger","product_amount":10,"product_total_amount":11.8,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":"8,9"},{"product_id":294,"product_name":"Cheese Pineapple Sandwich","product_amount":15,"product_total_amount":22,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":"14,15,16,18"},{"product_id":301,"product_name":"Mexican Club Sandwich","product_amount":11,"product_total_amount":11,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":""},{"product_id":84,"product_name":"Spaghetti Alla Carbonara","product_amount":30,"product_total_amount":30,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"","product_toppings_ids":""},{"product_id":31,"product_name":"Fresh Veggie Pizza","product_amount":60,"product_total_amount":100,"product_food_type":2,"product_quantity":1,"product_size_ids":0,"product_option_ids":"1","product_toppings_ids":"1,3"}]
library;

class ReorderDl {
  ReorderDl({
    int? status,
    String? message,
    int? messageCode,
    int? reorderId,
    int? storeId,
    int? serviceCategoryId,
    String? serviceCategoryName,
    String? serviceCategoryIcon,
    String? storeName,
    String? serviceCateName,
    String? serviceCateIcon,
    String? storeBanner,
    int? storeStatus,
    dynamic averageRating,
    String? productCategory,
    String? description,
    int? deliveryTime,
    int? orderMinAmount,
    String? offer,
    int? offerMinAmount,
    int? offerAmount,
    int? offerType,
    int? offerPercentage,
    int? isFavStore,
    int? takenAwayType,
    String? address,
    String? latitude,
    String? longitude,
    int? packagingCharges,
    List<OrderDetail>? orderDetail,
  }) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _reorderId = reorderId;
    _storeId = storeId;
    _serviceCategoryName = serviceCategoryName;
    _serviceCategoryIcon = serviceCategoryIcon;
    _serviceCategoryId = serviceCategoryId;
    _storeName = storeName;
    _storeBanner = storeBanner;
    _storeStatus = storeStatus;
    _averageRating = averageRating;
    _productCategory = productCategory;
    _description = description;
    _deliveryTime = deliveryTime;
    _orderMinAmount = orderMinAmount;
    _offer = offer;
    _offerMinAmount = offerMinAmount;
    _offerAmount = offerAmount;
    _offerType = offerType;
    _offerPercentage = offerPercentage;
    _isFavStore = isFavStore;
    _takenAwayType = takenAwayType;
    _address = address;
    _latitude = latitude;
    _longitude = longitude;
    _packagingCharges = packagingCharges;
    _orderDetail = orderDetail;
  }

  ReorderDl.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _messageCode = json['message_code'];
    _reorderId = json['reorder_id'];
    _storeId = json['store_id'];
    _serviceCategoryId = json['service_category_id'];
    _serviceCategoryName = json['service_category_name'];
    _serviceCategoryIcon = json['service_category_icon'];
    _storeName = json['store_name'];
    _storeBanner = json['store_banner'];
    _storeStatus = json['store_status'];
    _averageRating = json['average_rating'];
    _productCategory = json['product_category'];
    _description = json['description'];
    _deliveryTime = json['delivery_time'];
    _orderMinAmount = json['order_min_amount'];
    _offer = json['offer'];
    _offerMinAmount = json['offer_min_amount'];
    _offerAmount = json['offer_amount'];
    _offerType = json['offer_type'];
    _offerPercentage = json['offer_percentage'];
    _isFavStore = json['is_fav_store'];
    _takenAwayType = json['taken_away_type'];
    _address = json['address'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _packagingCharges = json['packaging_charges'];
    if (json['order_detail'] != null) {
      _orderDetail = [];
      json['order_detail'].forEach((v) {
        _orderDetail?.add(OrderDetail.fromJson(v));
      });
    }
  }

  int? _status;
  String? _message;
  int? _messageCode;
  int? _reorderId;
  int? _storeId;
  int? _serviceCategoryId;
  String? _serviceCategoryName;
  String? _serviceCategoryIcon;
  String? _storeName;
  String? _storeBanner;
  int? _storeStatus;
  dynamic _averageRating;
  String? _productCategory;
  String? _description;
  int? _deliveryTime;
  int? _orderMinAmount;
  String? _offer;
  int? _offerMinAmount;
  int? _offerAmount;
  int? _offerType;
  int? _offerPercentage;
  int? _isFavStore;
  int? _takenAwayType;
  String? _address;
  String? _latitude;
  String? _longitude;
  int? _packagingCharges;
  List<OrderDetail>? _orderDetail;

  dynamic get averageRating => _averageRating;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get reorderId => _reorderId ?? 0;

  int get storeId => _storeId ?? 0;

  int get serviceCategoryId => _serviceCategoryId ?? 0;

  int get storeStatus => _storeStatus ?? 0;

  int get deliveryTime => _deliveryTime ?? 0;

  int get orderMinAmount => _orderMinAmount ?? 0;

  int get offerMinAmount => _offerMinAmount ?? 0;

  int get offerAmount => _offerAmount ?? 0;

  int get offerType => _offerType ?? 0;

  int get offerPercentage => _offerPercentage ?? 0;

  int get isFavStore => _isFavStore ?? 0;

  int get takenAwayType => _takenAwayType ?? 0;

  int get packagingCharges => _packagingCharges ?? 0;

  List<OrderDetail> get orderDetail => _orderDetail ?? [];

  String get message => _message ?? "";

  String get address => _address ?? "";

  String get latitude => _latitude ?? "";

  String get longitude => _longitude ?? "";

  String get offer => _offer ?? "";

  String get productCategory => _productCategory ?? "";

  String get description => _description ?? "";

  String get storeName => _storeName ?? "";

  String get serviceCategoryName => _serviceCategoryName ?? "";

  String get serviceCategoryIcon => _serviceCategoryIcon ?? "";

  String get storeBanner => _storeBanner ?? "";

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['message_code'] = _messageCode;
    map['reorder_id'] = _reorderId;
    map['store_id'] = _storeId;
    map['service_category_id'] = _serviceCategoryId;
    map['store_name'] = _storeName;
    map['service_category_name'] = _serviceCategoryName;
    map['service_category_icon'] = _serviceCategoryIcon;
    map['store_banner'] = _storeBanner;
    map['store_status'] = _storeStatus;
    map['average_rating'] = _averageRating;
    map['product_category'] = _productCategory;
    map['description'] = _description;
    map['delivery_time'] = _deliveryTime;
    map['order_min_amount'] = _orderMinAmount;
    map['offer'] = _offer;
    map['offer_min_amount'] = _offerMinAmount;
    map['offer_amount'] = _offerAmount;
    map['offer_type'] = _offerType;
    map['offer_percentage'] = _offerPercentage;
    map['is_fav_store'] = _isFavStore;
    map['taken_away_type'] = _takenAwayType;
    map['address'] = _address;
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    map['packaging_charges'] = _packagingCharges;
    if (_orderDetail != null) {
      map['order_detail'] = _orderDetail?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_id : 58
/// product_name : "Mexican Mcaloo Tikki Burger"
/// product_amount : 12
/// product_total_amount : 15.77
/// product_food_type : 2
/// product_quantity : 1
/// product_size_ids : 0
/// product_option_ids : ""
/// product_toppings_ids : "4,5,6"

class OrderDetail {
  OrderDetail({
    int? productId,
    String? productName,
    int? productAmount,
    dynamic productTotalAmount,
    int? productFoodType,
    int? productQuantity,
    int? productSizeIds,
    String? productOptionIds,
    String? productToppingsIds,
  }) {
    _productId = productId;
    _productName = productName;
    _productAmount = productAmount;
    _productTotalAmount = productTotalAmount;
    _productFoodType = productFoodType;
    _productQuantity = productQuantity;
    _productSizeIds = productSizeIds;
    _productOptionIds = productOptionIds;
    _productToppingsIds = productToppingsIds;
  }

  OrderDetail.fromJson(dynamic json) {
    _productId = json['product_id'];
    _productName = json['product_name'];
    _productAmount = json['product_amount'];
    _productTotalAmount = json['product_total_amount'];
    _productFoodType = json['product_food_type'];
    _productQuantity = json['product_quantity'];
    _productSizeIds = json['product_size_ids'];
    _productOptionIds = json['product_option_ids'];
    _productToppingsIds = json['product_toppings_ids'];
  }

  int? _productId;
  String? _productName;
  int? _productAmount;
  dynamic _productTotalAmount;
  int? _productFoodType;
  int? _productQuantity;
  int? _productSizeIds;
  String? _productOptionIds;
  String? _productToppingsIds;

  dynamic get productTotalAmount => _productTotalAmount;

  int get productId => _productId ?? 0;

  int get productAmount => _productAmount ?? 0;

  int get productFoodType => _productFoodType ?? 0;

  int get productQuantity => _productQuantity ?? 0;

  int get productSizeIds => _productSizeIds ?? 0;

  String get productOptionIds => _productOptionIds ?? "";

  String get productToppingsIds => _productToppingsIds ?? "";

  String get productName => _productName ?? "";

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['product_id'] = _productId;
    map['product_name'] = _productName;
    map['product_amount'] = _productAmount;
    map['product_total_amount'] = _productTotalAmount;
    map['product_food_type'] = _productFoodType;
    map['product_quantity'] = _productQuantity;
    map['product_size_ids'] = _productSizeIds;
    map['product_option_ids'] = _productOptionIds;
    map['product_toppings_ids'] = _productToppingsIds;
    return map;
  }
}
