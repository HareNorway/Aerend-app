import '../../../networking/api_constant.dart';

String normalizeSwipeProductImageUrl(dynamic raw) {
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

class HareSwipeListPojo {
  int? _status;
  String? _message;
  int? _messageCode;
  List<SwipeCardModel>? _swipeList;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  List<SwipeCardModel> get swipeList => _swipeList ?? [];

  HareSwipeListPojo(
      {int? status,
      String? message,
      List<SwipeCardModel>? swipeList,
      int? messageCode}) {
    _status = status;
    _message = message;
    _swipeList = swipeList;
    _messageCode = messageCode;
  }

  HareSwipeListPojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["swipe_list"] != null) {
      _swipeList = [];
      json["swipe_list"].forEach((v) {
        _swipeList?.add(SwipeCardModel.fromJson(v));
      });
    }
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_swipeList != null) {
      map["store_list"] = _swipeList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class SwipeCardModel {
  int? _productId;
  String? _productName;
  String? _productImage;
  List<dynamic>? _productImageList;
  String? _description;
  double? _amount;
  double? _originalAmount;
  double? _discountAmount;
  int? _discountPercent;
  int? _discountType;
  int? _storeId;
  int? _serviceCategoryId;
  String? _storeName;
  double? _serviceRadius;
  String? _storeLogo;
  int? _foodType;
  int? _sizeOptional;
  int? _colorOptional;
  double? _distance;

  int get productId => _productId ?? 0;

  String get productName => _productName ?? "";

  String get productImage => _productImage ?? "";

  List<dynamic> get productImageList => _productImageList ?? [];

  String get storeName => _storeName ?? "";

  String get description => _description ?? "";

  double get distance => _distance ?? 0.0;

  int get storeId => _storeId ?? 0;

  int get serviceCategoryId => _serviceCategoryId ?? 0;

  int get discountPercent => _discountPercent ?? 0;

  int get discountType => _discountType ?? 0;

  int get foodType => _foodType ?? 0;

  int get sizeOptional => _sizeOptional ?? 0;

  int get colorOptional => _colorOptional ?? 0;

  double get discountAmount => _discountAmount ?? 0.0;

  double get amount => _amount ?? 0.0;

  double get originalAmount => _originalAmount ?? 0.0;

  double get serviceRadius => _serviceRadius ?? 0.0;

  String get storeLogo => _storeLogo ?? "";

  SwipeCardModel(
      {int? productId,
      String? productName,
      String? productImage,
      List<dynamic>? productImageList,
      String? description,
      double? amount,
      double? originalAmount,
      double? discountAmount,
      int? discountPercent,
      int? discountType,
      int? storeId,
      int? serviceCategoryId,
      String? storeName,
      double? serviceRadius,
      String? storeLogo,
      int? foodType,
      int? sizeOptional,
      int? colorOptional,
      double? distance}) {
    _productId = productId;
    _productName = productName;
    _productImage = productImage;
    _productImageList = productImageList;
    _description = description;
    _amount = amount;
    _originalAmount = originalAmount;
    _discountAmount = discountAmount;
    _discountPercent = discountPercent;
    _discountType = discountType;
    _storeId = storeId;
    _storeName = storeName;
    _serviceCategoryId = serviceCategoryId;
    _serviceRadius = serviceRadius;
    _storeLogo = storeLogo;
    _foodType = foodType;
    _sizeOptional = sizeOptional;
    _colorOptional = colorOptional;
    _distance = distance;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  SwipeCardModel.fromJson(dynamic json) {
    _productId = _asInt(json["product_id"]);
    _productName = json["product_name"];
    _productImage = normalizeSwipeProductImageUrl(json["product_image"]);
    final dynamic rawList = json["product_image_list"];
    if (rawList is List) {
      _productImageList = rawList
          .map((e) => normalizeSwipeProductImageUrl(e))
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      _productImageList = [];
    }
    if ((_productImage == null || _productImage!.isEmpty) &&
        _productImageList != null &&
        _productImageList!.isNotEmpty) {
      _productImage = _productImageList!.first.toString();
    }
    _description = json["description"];
    _foodType = json["food_type"];
    _sizeOptional = json["size_optional"];
    _colorOptional = json["color_optional"];
    _amount = (json["amount"] as num).toDouble();
    _originalAmount = (json["original_amount"] as num).toDouble();
    _discountAmount = (json["discount_amount"] as num).toDouble();
    _discountPercent = _asInt(json["discount_percent"]);
    _discountType = _asInt(json["discount_type"]);
    _storeId = _asInt(json["store_id"]);
    _storeName = json["store_name"];
    _serviceCategoryId = _asInt(json["service_cat_id"]);
    _serviceRadius = (json["service_radius"] as num).toDouble();
    _storeLogo = json["store_logo"];
    _distance = (json["distance"] as num).toDouble();
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["product_id"] = _productId;
    map["product_name"] = _productName;
    map["product_image"] = _productImage;
    map["product_image_list"] = _productImageList;
    map["description"] = _description;
    map["food_type"] = _foodType;
    map["amount"] = _amount;
    map["original_amount"] = _originalAmount;
    map["discount_percent"] = _discountPercent;
    map["discount_amount"] = _discountAmount;
    map["discount_type"] = _discountType;
    map["store_id"] = _storeId;
    map["store_name"] = _storeName;
    map["service_cat_id"] = _serviceCategoryId;
    map["service_radius"] = _serviceRadius;
    map["store_logo"] = _storeLogo;
    map["distance"] = _distance;
    return map;
  }
}

class HareExplorePojo {
  int? _status;
  String? _message;
  int? _messageCode;
  List<HareStoreListItems>? _lunchList;
  List<HareStoreListItems>? _fastList;

  int get status => _status ?? 0;

  int get messageCode => _messageCode ?? 0;

  String get message => _message ?? "";

  List<HareStoreListItems> get lunchList => _lunchList ?? [];

  List<HareStoreListItems> get fastList => _fastList ?? [];

  HareExplorePojo(
      {int? status,
      String? message,
      List<HareStoreListItems>? lunchList,
      List<HareStoreListItems>? fastList,
      int? messageCode}) {
    _status = status;
    _message = message;
    _lunchList = lunchList;
    _fastList = fastList;
    _messageCode = messageCode;
  }

  HareExplorePojo.fromJson(dynamic json) {
    _status = json["status"];
    _message = json["message"];
    _messageCode = json["message_code"];
    if (json["lunch_list"] != null) {
      _lunchList = [];
      json["lunch_list"].forEach((v) {
        _lunchList?.add(HareStoreListItems.fromJson(v));
      });
    }
    if (json["fast_list"] != null) {
      _fastList = [];
      json["fast_list"].forEach((v) {
        _fastList?.add(HareStoreListItems.fromJson(v));
      });
    }
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["status"] = _status;
    map["message"] = _message;
    map["message_code"] = _messageCode;
    if (_lunchList != null) {
      map["lunch_list"] = _lunchList?.map((v) => v.toJson()).toList();
    }
    if (_fastList != null) {
      map["fast_list"] = _fastList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class HareStoreListItems {
  int? _storeId;
  String? _storeName;
  String? _storeImage;
  String? _description;
  double? _storeRating;
  double? _serviceRadius;
  double? _productMinAmount;
  double? _productMaxAmount;
  int? _deliveryTime;

  int get storeId => _storeId ?? 0;

  String get storeName => _storeName ?? "";

  String get storeImage => _storeImage ?? "";

  String get description => _description ?? "";

  double get serviceRadius => _serviceRadius ?? 0.0;

  int get deliveryTime => _deliveryTime ?? 0;

  double get storeRating => _storeRating ?? 0.0;

  double get productMinAmount => _productMinAmount ?? 0.0;

  double get productMaxAmount => _productMaxAmount ?? 0.0;

  HareStoreListItems(
      {int? storeId,
      String? storeName,
      String? storeImage,
      String? description,
      double? amount,
      double? discountAmount,
      int? discountType,
      double? serviceRadius,
      String? storeLogo,
      int? foodType,
      double? distance}) {
    _storeId = storeId;
    _storeName = storeName;
    _storeImage = storeImage;
    _description = description;
    _serviceRadius = serviceRadius;
    _deliveryTime = deliveryTime;
    _storeRating = discountAmount;
    _productMinAmount = productMinAmount;
    _productMaxAmount = productMaxAmount;
  }

  HareStoreListItems.fromJson(dynamic json) {
    _storeId = json["store_id"];
    _storeName = json["store_name"];
    _storeImage = json["store_image"];
    _description = json["description"];
    _storeRating = ((json["store_rating"] ?? 0.0) as num).toDouble();
    _deliveryTime = json["delivery_time"];
    _serviceRadius = ((json["service_radius"] ?? 0.0) as num).toDouble();
    _productMinAmount = ((json["min_product_value"] ?? 0.0) as num).toDouble();
    _productMaxAmount = ((json["max_product_value"] ?? 0.0) as num).toDouble();
  }

  Map<String?, dynamic> toJson() {
    var map = <String?, dynamic>{};
    map["store_id"] = _storeId;
    map["store_name"] = _storeName;
    map["store_image"] = _storeImage;
    map["description"] = _description;
    map["store_rating"] = _storeRating;
    map["delivery_time"] = _deliveryTime;
    map["service_radius"] = _serviceRadius;
    map["min_product_value"] = _productMinAmount;
    map["max_product_value"] = _productMaxAmount;
    return map;
  }
}

// List<SwipeCardModel> candidates = [
//   SwipeCardModel(
//       name: "Healthy's Day",
//       description: 'Get your special discount today 💸',
//       endTime: 'Ends in 12:22:01',
//       price: 'NOK 100',
//       distance: '1km',
//       etaTime: '10 min',
//       image: 'assets/images/swipe-card/card1.png'),
//   SwipeCardModel(
//       name: 'Fitness Fiesta',
//       description: 'Join us for a day of fitness fun!',
//       endTime: 'Ends in 10:15:30',
//       price: 'NOK 150',
//       distance: '2km',
//       etaTime: '15 min',
//       image: 'assets/images/swipe-card/card2.png'),
//   SwipeCardModel(
//       name: 'Yoga Retreat',
//       description: 'Relax and rejuvenate with yoga',
//       endTime: 'Ends in 14:45:00',
//       price: 'NOK 200',
//       distance: '3km',
//       etaTime: '20 min',
//       image: 'assets/images/swipe-card/card1.png'),
//   SwipeCardModel(
//       name: 'Healthy Cooking',
//       description: 'Learn to cook healthy meals',
//       endTime: 'Ends in 08:30:00',
//       price: 'NOK 120',
//       distance: '1.5km',
//       etaTime: '12 min',
//       image: 'assets/images/swipe-card/card2.png'),
//   SwipeCardModel(
//       name: 'Mindfulness Meditation',
//       description: 'Find peace and tranquility',
//       endTime: 'Ends in 09:00:00',
//       price: 'NOK 80',
//       distance: '500m',
//       etaTime: '5 min',
//       image: 'assets/images/swipe-card/card1.png'),
//   SwipeCardModel(
//       name: 'Cardio Blast',
//       description: 'Boost your cardio with intense workouts',
//       endTime: 'Ends in 11:45:30',
//       price: 'NOK 180',
//       distance: '2.5km',
//       etaTime: '18 min',
//       image: 'assets/images/swipe-card/card2.png'),
//   SwipeCardModel(
//       name: 'Strength Training',
//       description: 'Build strength and muscle',
//       endTime: 'Ends in 13:30:45',
//       price: 'NOK 140',
//       distance: '1km',
//       etaTime: '10 min',
//       image: 'assets/images/swipe-card/card1.png'),
//   SwipeCardModel(
//       name: 'Cycling Adventure',
//       description: 'Join us for a cycling tour',
//       endTime: 'Ends in 07:50:30',
//       price: 'NOK 160',
//       distance: '4km',
//       etaTime: '25 min',
//       image: 'assets/images/swipe-card/card2.png'),
//   SwipeCardModel(
//       name: 'Zumba Dance',
//       description: 'Dance your way to fitness',
//       endTime: 'Ends in 06:45:00',
//       price: 'NOK 130',
//       distance: '3.5km',
//       etaTime: '22 min',
//       image: 'assets/images/swipe-card/card1.png'),
//   SwipeCardModel(
//       name: 'Pilates Session',
//       description: 'Improve your flexibility and strength',
//       endTime: 'Ends in 10:10:10',
//       price: 'NOK 170',
//       distance: '2km',
//       etaTime: '15 min',
//       image: 'assets/images/swipe-card/card1.png'),
// ];
