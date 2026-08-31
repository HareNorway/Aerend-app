/// status : 1
/// message : "success!"
/// message_code : 1
/// order_id : 595
/// order_no : "Booking Id #7452806202125054"
/// additional_remark : ""
/// category_name : "FOOD DELIVERY"
/// category_icon : "https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png"
/// cancel_by : ""
/// cancel_reason : ""
/// cancel_charge : 0
/// store_id : 140
/// store_contact_no : "38"
/// store_name : "Food Store"
/// store_image : "https://fox-jek-staging.startuptrinity.com/assets/images/store-images/5473207202122043.jpg"
/// store_average_ratings : 4.2
/// delivery_address : "Mochi Bazaar Rd, Raval, Gujarat 361325, India"
/// flat_no : ""
/// landmark : ""
/// service_date_time : "2021-05-25 06:28:45"
/// schedule_order_date_time : "2021-05-25 06:28:45"
/// delivery_people_name : "Driver Jek"
/// total_item_cost : 670
/// discount_cost : 0
/// tax_cost : 84.96
/// refer_discount : 0
/// delivery_cost : 29.4
/// packaging_cost : 10
/// total_pay : 792.96
/// payment_type : 1
/// order_status : 9
/// user_rating_status : 0
/// user_taken_type : 1
/// prescription : ""
/// promo_code_discount : 0
/// used_promo_code_name : ""
/// delivery_person_image : ""
/// delivery_person_contact_no : "77"
/// driver_selected_service_string : "Ride Service, Courier Delivery, Store Delivery"
/// driver_fcm_token : null
/// driver_id : 136
/// delivery_person_rating : 3.8
/// delivery_person_name : "Driver Jek Driver Jek"
/// product_list : [{"product_name":"Pani Puri","food_type":1,"product_quantity":1,"product_price_for_one":50,"add_ons":""},{"product_name":"Manchurian","food_type":2,"product_quantity":4,"product_price_for_one":620,"add_ons":"Half, Pepsi"}]
library;

class DeliveriesOrderDetailPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  int? _orderId;
  String? _orderNo;
  String? _additionalRemark;
  String? _categoryName;
  String? _categoryIcon;
  String? _cancelBy;
  String? _cancelReason;
  dynamic _cancelCharge;
  int? _storeId;
  String? _storeContactNo;
  String? _storeName;
  String? _storeImage;
  String? _otp;
  dynamic _storeAverageRatings;
  String? _deliveryAddress;
  String? _flatNo;
  String? _landmark;
  String? _serviceDateTime;
  String? _scheduleOrderDateTime;
  String? _deliveryPeopleName;
  dynamic _totalItemCost;
  dynamic _discountCost;
  dynamic _taxCost;
  dynamic _referDiscount;
  dynamic _deliveryCost;
  dynamic _packagingCost;
  dynamic _totalPay;
  dynamic tip;
  int? _paymentType;
  int? _orderStatus;
  int? _userRatingStatus;
  int? _userTakenType;
  String? _prescription;
  dynamic _promoCodeDiscount;
  String? _usedPromoCodeName;
  String? _deliveryPersonImage;
  String? _deliveryPersonContactNo;
  String? _driverSelectedServiceString;
  dynamic _driverFcmToken;
  int? _driverId;
  dynamic _deliveryPersonRating;
  String? _deliveryPersonName;
  List<ProductListItem>? _productList;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  int get orderId => _orderId ?? 0;

  int get storeId => _storeId ?? 0;

  int get paymentType => _paymentType ?? 0;

  int get orderStatus => _orderStatus ?? 0;

  int get userRatingStatus => _userRatingStatus ?? 0;

  int get userTakenType => _userTakenType ?? 0;

  int get driverId => _driverId ?? 0;

  String get message => _message ?? "";

  String get orderNo => _orderNo ?? "";

  String get additionalRemark => _additionalRemark ?? "";

  String get categoryName => _categoryName ?? "";

  String get categoryIcon => _categoryIcon ?? "";

  String get cancelBy => _cancelBy ?? "";

  String get cancelReason => _cancelReason ?? "";

  String get storeContactNo => _storeContactNo ?? "";

  String get storeName => _storeName ?? "";

  String get storeImage => _storeImage ?? "";

  String get otp => _otp ?? "";

  String get deliveryAddress => _deliveryAddress ?? "";

  String get flatNo => _flatNo ?? "";

  String get landmark => _landmark ?? "";

  String get serviceDateTime => _serviceDateTime ?? "";

  String get scheduleOrderDateTime => _scheduleOrderDateTime ?? "";

  String get deliveryPeopleName => _deliveryPeopleName ?? "";

  String get prescription => _prescription ?? "";

  String get usedPromoCodeName => _usedPromoCodeName ?? "";

  String get deliveryPersonImage => _deliveryPersonImage ?? "";

  String get deliveryPersonContactNo => _deliveryPersonContactNo ?? "";

  String get driverSelectedServiceString => _driverSelectedServiceString ?? "";

  String get deliveryPersonName => _deliveryPersonName ?? "";

  List<ProductListItem> get productList => _productList ?? [];

  dynamic get cancelCharge => _cancelCharge;

  dynamic get storeAverageRatings => _storeAverageRatings;

  dynamic get totalItemCost => _totalItemCost;

  dynamic get discountCost => _discountCost;

  dynamic get taxCost => _taxCost;

  dynamic get referDiscount => _referDiscount;

  dynamic get deliveryCost => _deliveryCost;

  dynamic get packagingCost => _packagingCost;

  dynamic get totalPay => _totalPay;

  dynamic get promoCodeDiscount => _promoCodeDiscount;

  dynamic get driverFcmToken => _driverFcmToken;

  dynamic get deliveryPersonRating => _deliveryPersonRating;

  DeliveriesOrderDetailPojo(
      {int? status,
      String? message,
      int? messageCode,
      int? orderId,
      String? orderNo,
      String? additionalRemark,
      String? categoryName,
      String? categoryIcon,
      String? cancelBy,
      String? cancelReason,
      dynamic cancelCharge,
      int? storeId,
      String? storeContactNo,
      String? storeName,
      String? storeImage,
      String? otp,
      dynamic storeAverageRatings,
      String? deliveryAddress,
      String? flatNo,
      String? landmark,
      String? serviceDateTime,
      String? scheduleOrderDateTime,
      String? deliveryPeopleName,
      dynamic totalItemCost,
      dynamic discountCost,
      dynamic taxCost,
      dynamic referDiscount,
      dynamic deliveryCost,
      dynamic packagingCost,
      dynamic totalPay,
      this.tip,
      int? paymentType,
      int? orderStatus,
      int? userRatingStatus,
      int? userTakenType,
      String? prescription,
      dynamic promoCodeDiscount,
      String? usedPromoCodeName,
      String? deliveryPersonImage,
      String? deliveryPersonContactNo,
      String? driverSelectedServiceString,
      dynamic driverFcmToken,
      int? driverId,
      dynamic deliveryPersonRating,
      String? deliveryPersonName,
      List<ProductListItem>? productList}) {
    _status = status;
    _message = message;
    _messageCode = messageCode;
    _orderId = orderId;
    _orderNo = orderNo;
    _additionalRemark = additionalRemark;
    _categoryName = categoryName;
    _categoryIcon = categoryIcon;
    _cancelBy = cancelBy;
    _cancelReason = cancelReason;
    _cancelCharge = cancelCharge;
    _storeId = storeId;
    _storeContactNo = storeContactNo;
    _storeName = storeName;
    _storeImage = storeImage;
    _otp = otp;
    _storeAverageRatings = storeAverageRatings;
    _deliveryAddress = deliveryAddress;
    _flatNo = flatNo;
    _landmark = landmark;
    _serviceDateTime = serviceDateTime;
    _scheduleOrderDateTime = scheduleOrderDateTime;
    _deliveryPeopleName = deliveryPeopleName;
    _totalItemCost = totalItemCost;
    _discountCost = discountCost;
    _taxCost = taxCost;
    _referDiscount = referDiscount;
    _deliveryCost = deliveryCost;
    _packagingCost = packagingCost;
    _totalPay = totalPay;
    _paymentType = paymentType;
    _orderStatus = orderStatus;
    _userRatingStatus = userRatingStatus;
    _userTakenType = userTakenType;
    _prescription = prescription;
    _promoCodeDiscount = promoCodeDiscount;
    _usedPromoCodeName = usedPromoCodeName;
    _deliveryPersonImage = deliveryPersonImage;
    _deliveryPersonContactNo = deliveryPersonContactNo;
    _driverSelectedServiceString = driverSelectedServiceString;
    _driverFcmToken = driverFcmToken;
    _driverId = driverId;
    _deliveryPersonRating = deliveryPersonRating;
    _deliveryPersonName = deliveryPersonName;
    _productList = productList;
  }

  DeliveriesOrderDetailPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    _orderId = json["order_id"];
    _orderNo = json["order_no"];
    _additionalRemark = json["additional_remark"];
    _categoryName = json["category_name"];
    _categoryIcon = json["category_icon"];
    _cancelBy = json["cancel_by"];
    _cancelReason = json["cancel_reason"];
    _cancelCharge = json["cancel_charge"];
    _storeId = json["store_id"];
    tip = json["tip"];
    _storeContactNo = json["store_contact_no"];
    _storeName = json["store_name"];
    _storeImage = json["store_image"];
    _otp = json["otp"];
    _storeAverageRatings = json["store_average_ratings"];
    _deliveryAddress = json["delivery_address"];
    _flatNo = json["flat_no"];
    _landmark = json["landmark"];
    _serviceDateTime = json["service_date_time"];
    _scheduleOrderDateTime = json["schedule_order_date_time"];
    _deliveryPeopleName = json["delivery_people_name"];
    _totalItemCost = json["total_item_cost"];
    _discountCost = json["discount_cost"];
    _taxCost = json["tax_cost"];
    _referDiscount = json["refer_discount"];
    _deliveryCost = json["delivery_cost"];
    _packagingCost = json["packaging_cost"];
    _totalPay = json["total_pay"];
    _paymentType = json["payment_type"];
    _orderStatus = json["order_status"];
    _userRatingStatus = json["user_rating_status"];
    _userTakenType = json["user_taken_type"];
    _prescription = json["prescription"];
    _promoCodeDiscount = json["promo_code_discount"];
    _usedPromoCodeName = json["used_promo_code_name"];
    _deliveryPersonImage = json["delivery_person_image"];
    _deliveryPersonContactNo = json["delivery_person_contact_no"];
    _driverSelectedServiceString = json["driver_selected_service_string"];
    _driverFcmToken = json["driver_fcm_token"];
    _driverId = json["driver_id"];
    _deliveryPersonRating = json["delivery_person_rating"];
    _deliveryPersonName = json["delivery_person_name"];
    if (json["product_list"] != null) {
      _productList = [];
      json["product_list"].forEach((v) {
        _productList?.add(ProductListItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    map["order_id"] = _orderId;
    map["order_no"] = _orderNo;
    map["additional_remark"] = _additionalRemark;
    map["category_name"] = _categoryName;
    map["category_icon"] = _categoryIcon;
    map["cancel_by"] = _cancelBy;
    map["cancel_reason"] = _cancelReason;
    map["cancel_charge"] = _cancelCharge;
    map["store_id"] = _storeId;
    map["store_contact_no"] = _storeContactNo;
    map["store_name"] = _storeName;
    map["store_image"] = _storeImage;
    map["tip"] = tip;
    map["otp"] = _otp;
    map["store_average_ratings"] = _storeAverageRatings;
    map["delivery_address"] = _deliveryAddress;
    map["flat_no"] = _flatNo;
    map["landmark"] = _landmark;
    map["service_date_time"] = _serviceDateTime;
    map["schedule_order_date_time"] = _scheduleOrderDateTime;
    map["delivery_people_name"] = _deliveryPeopleName;
    map["total_item_cost"] = _totalItemCost;
    map["discount_cost"] = _discountCost;
    map["tax_cost"] = _taxCost;
    map["refer_discount"] = _referDiscount;
    map["delivery_cost"] = _deliveryCost;
    map["packaging_cost"] = _packagingCost;
    map["total_pay"] = _totalPay;
    map["payment_type"] = _paymentType;
    map["order_status"] = _orderStatus;
    map["user_rating_status"] = _userRatingStatus;
    map["user_taken_type"] = _userTakenType;
    map["prescription"] = _prescription;
    map["promo_code_discount"] = _promoCodeDiscount;
    map["used_promo_code_name"] = _usedPromoCodeName;
    map["delivery_person_image"] = _deliveryPersonImage;
    map["delivery_person_contact_no"] = _deliveryPersonContactNo;
    map["driver_selected_service_string"] = _driverSelectedServiceString;
    map["driver_fcm_token"] = _driverFcmToken;
    map["driver_id"] = _driverId;
    map["delivery_person_rating"] = _deliveryPersonRating;
    map["delivery_person_name"] = _deliveryPersonName;
    if (_productList != null) {
      map["product_list"] = _productList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// product_name : "Pani Puri"
/// food_type : 1
/// product_quantity : 1
/// product_price_for_one : 50
/// add_ons : ""

class ProductListItem {
  String? _productName;
  int? _foodType;
  int? _productQuantity;
  dynamic _productPriceForOne;
  dynamic _productPrice;
  String? _addOns;

  int get foodType => _foodType ?? 0;

  int get productQuantity => _productQuantity ?? 0;

  dynamic get productPriceForOne => _productPriceForOne;

  dynamic get productPrice => _productPrice;

  String get addOns => _addOns ?? "";

  String get productName => _productName ?? "";

  ProductListItem({String? productName, int? foodType, int? productQuantity, dynamic productPriceForOne, dynamic productPrice, String? addOns}) {
    _productName = productName;
    _foodType = foodType;
    _productQuantity = productQuantity;
    _productPriceForOne = productPriceForOne;
    _productPrice = productPrice;
    _addOns = addOns;
  }

  ProductListItem.fromJson(dynamic json) {
    _productName = json["product_name"];
    _foodType = json["food_type"];
    _productQuantity = json["product_quantity"];
    _productPriceForOne = json["product_price_for_one"];
    _productPrice = json["product_price"];
    _addOns = json["add_ons"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["product_name"] = _productName;
    map["food_type"] = _foodType;
    map["product_quantity"] = _productQuantity;
    map["product_price_for_one"] = _productPriceForOne;
    map["product_price"] = _productPrice;
    map["add_ons"] = _addOns;
    return map;
  }
}
