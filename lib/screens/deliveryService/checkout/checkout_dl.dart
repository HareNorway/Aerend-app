import 'package:json_annotation/json_annotation.dart';

part 'checkout_dl.g.dart';

/// status : 1
/// message : "success!"
/// message_code : 1
/// store_id : 1
/// store_name : "Mc'd"
/// required_prescription : 0
/// store_rating : 4.88
/// store_banner : "https://fox-food.startuptrinity.com/assets/images/store-images/7080439202012184.jpg"
/// total_item_cost : 150
/// discount_cost : 0
/// apply_promocode_amount : 155
/// packaging_cost : 5
/// delivery_cost : 0
/// tax_cost : 15.5
/// tip : 15.5
/// total_pay : 170.5
/// promocode_discount : 0
/// promo_message_code : 0
/// promo_code_message : ""
/// product_list : [{"product_id":4,"product_name":"Mcaloo Tikki Burger With Whole Wheat Bun","product_total_quantity":1,"product_total_amount":52,"product_discount":0,"product_quantity_list":[{"product_quantity":1,"product_amount":52,"product_discount":0,"product_add_ons":"Tomato Sauce, Mayonnaise Sauce","product_size":0,"product_options":[95],"product_toppings":[34]}]}]
/// unavailable_products : ""

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class OrderPreviewPojo {
  int status = 0;
  int messageCode = 0;
  int storeId = 0;
  int requiredPrescription = 0;
  int userTakenStatus = 0;
  int promoMessageCode = 0;
  int storeStatus = 0;
  double storeRating = 0;
  double totalItemCost = 0;
  double discountCost = 0;
  double applyPromocodeAmount = 0;
  double packagingCost = 0;
  double deliveryCost = 0;
  double taxCost = 0;
  double totalPay = 0;
  double promocodeDiscount = 0;
  double tip = 0;
  double referDiscount = 0;
  double minOrderAmount = 0;
  String message = "";
  String storeName = "";
  String? storeAddress;

  String storeBanner = "";
  String promocodeName = "";
  String promoCodeMessage = "";
  String unavailableProducts = "";
  List<COProductListItem> productList = [];

  OrderPreviewPojo({
    this.status = 0,
    this.messageCode = 0,
    this.storeId = 0,
    this.requiredPrescription = 0,
    this.userTakenStatus = 0,
    this.promoMessageCode = 0,
    this.storeStatus = 0,
    this.storeRating = 0,
    this.totalItemCost = 0,
    this.discountCost = 0,
    this.applyPromocodeAmount = 0,
    this.packagingCost = 0,
    this.deliveryCost = 0,
    this.taxCost = 0,
    this.totalPay = 0,
    this.promocodeDiscount = 0,
    this.tip = 0,
    this.referDiscount = 0,
    this.minOrderAmount = 0,
    this.promocodeName = "",
    this.promoCodeMessage = "",
    this.message = "",
    this.storeBanner = "",
    this.storeName = "",
    this.storeAddress,
    this.unavailableProducts = "",
    List<COProductListItem>? productList,
  }) {
    this.productList = productList ?? [];
  }

  factory OrderPreviewPojo.fromJson(Map<String, dynamic> json) =>
      _$OrderPreviewPojoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderPreviewPojoToJson(this);
}

/// product_id : 4
/// product_name : "Mcaloo Tikki Burger With Whole Wheat Bun"
/// product_total_quantity : 1
/// product_total_amount : 52
/// product_discount : 0
/// product_quantity_list : [{"product_quantity":1,"product_amount":52,"product_discount":0,"product_add_ons":"Tomato Sauce, Mayonnaise Sauce","product_size":0,"product_options":[95],"product_toppings":[34]}]

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class COProductListItem {
  int productId = 0;
  int productTotalQuantity = 0;
  double productTotalAmount = 0;
  double productDiscount = 0;
  String productName = "";
  List<ProductQuantityListItem> productQuantityList = [];

  COProductListItem({
    this.productId = 0,
    this.productTotalQuantity = 0,
    this.productTotalAmount = 0,
    this.productDiscount = 0,
    this.productName = "",
    List<ProductQuantityListItem>? productQuantityList,
  }) {
    this.productQuantityList = productQuantityList ?? [];
  }

  factory COProductListItem.fromJson(Map<String, dynamic> json) =>
      _$COProductListItemFromJson(json);

  Map<String, dynamic> toJson() => _$COProductListItemToJson(this);
}

/// product_quantity : 1
/// product_amount : 52
/// product_discount : 0
/// product_add_ons : "Tomato Sauce, Mayonnaise Sauce"
/// product_size : 0
/// product_options : [95]
/// product_toppings : [34]

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class ProductQuantityListItem {
  int productQuantity = 0;
  double productAmount = 0;
  double priceForOne = 0;
  double productDiscount = 0;
  String productAddOns = "";
  int productSize = 0;
  List<int> productOptions = [];
  List<int> productToppings = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isLoading = false;

  ProductQuantityListItem({
    this.productQuantity = 0,
    this.productAmount = 0,
    this.priceForOne = 0,
    this.productDiscount = 0,
    this.productSize = 0,
    this.productAddOns = "",
    List<int>? productOptions,
    List<int>? productToppings,
  }) {
    this.productOptions = productOptions ?? [];
    this.productToppings = productToppings ?? [];
  }

  factory ProductQuantityListItem.fromJson(Map<String, dynamic> json) =>
      _$ProductQuantityListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ProductQuantityListItemToJson(this);
}

class ProductListForOPParam {
  int productId = 0;
  List<ProductQuantityItemForOPParam> productQuantity = [];

  ProductListForOPParam();

  Map toJson() => {
        'product_id': productId,
        'product_quantity': productQuantity,
      };
}

class ProductQuantityItemForOPParam {
  int quantity = 0, size = 0;
  List<int> options = [], toppings = [];

  ProductQuantityItemForOPParam();

  Map toJson() => {
        'quantity': quantity,
        'size': size,
        'options': options,
        'toppings': toppings,
      };
}

/// status : 1
/// message : "success!"
/// promocode_list : [{"promocode_id":1,"promocode_name":"PRO123","discount_amount":60,"discount_type":1,"min_order_amount":0,"promocode_description":"Use code PRO123 & get discount $60 per order"}]
/// message_code : 1

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class PromoCodePojo {
  int status = 0;
  int messageCode = 0;
  String message = "";
  List<PromoCodeListItem> promocodeList = [];

  PromoCodePojo(
      {this.status = 0,
      this.message = "",
      List<PromoCodeListItem>? promocodeList,
      this.messageCode = 0}) {
    this.promocodeList = promocodeList ?? [];
  }

  factory PromoCodePojo.fromJson(Map<String, dynamic> json) =>
      _$PromoCodePojoFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodePojoToJson(this);
}

/// promocode_id : 1
/// promocode_name : "PRO123"
/// discount_amount : 60
/// discount_type : 1
/// min_order_amount : 0
/// promocode_description : "Use code PRO123 & get discount $60 per order"

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class PromoCodeListItem {
  int promocodeId = 0;
  double discountAmount = 0;
  int discountType = 0;
  double minOrderAmount = 0;
  String promocodeDescription = "";
  String promocodeName = "";

  PromoCodeListItem({
    this.promocodeId = 0,
    this.discountAmount = 0,
    this.discountType = 0,
    this.minOrderAmount = 0,
    this.promocodeDescription = "",
    this.promocodeName = "",
  });

  factory PromoCodeListItem.fromJson(Map<String, dynamic> json) =>
      _$PromoCodeListItemFromJson(json);

  Map<String, dynamic> toJson() => _$PromoCodeListItemToJson(this);
}

/// status : 1
/// message : "success!"
/// message_code : 1
/// order_id : 652
/// order_no : "4422407202101044"
/// unavailable_products : ""

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class PlaceOrderPojo {
  int status = 0;
  int messageCode = 0;
  int orderId = 0;
  double totalPay = 0.0;
  dynamic paymentIntent;
  String message = "";
  String orderNo = "";
  String inActiveProductIds = "";
  String successUrl = "";
  String failedUrl = "";
  String redirectUrl = "";

  PlaceOrderPojo({
    this.status = 0,
    this.messageCode = 0,
    this.orderId = 0,
    this.orderNo = "",
    this.paymentIntent = Null,
    this.totalPay = 0.0,
    this.inActiveProductIds = "",
    this.message = "",
    this.successUrl = "",
    this.failedUrl = "",
    this.redirectUrl = "",
  });

  factory PlaceOrderPojo.fromJson(Map<String, dynamic> json) =>
      _$PlaceOrderPojoFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceOrderPojoToJson(this);
}

@JsonSerializable(
    createToJson: true,
    includeIfNull: false,
    fieldRename: FieldRename.snake,
    explicitToJson: true)
class CurrentAddressPojo {
  String address = "";
  String lat = "";
  String lng = "";
  String flatNo = "";
  String landmark = "";

  CurrentAddressPojo(
      {this.address = "",
      this.lat = "",
      this.lng = "",
      this.flatNo = "",
      this.landmark = ""});

  factory CurrentAddressPojo.fromJson(Map<String, dynamic> json) =>
      _$CurrentAddressPojoFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentAddressPojoToJson(this);
}

//Command: flutter pub run build_runner build --delete-conflicting-outputs