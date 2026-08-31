import 'package:json_annotation/json_annotation.dart';

part 'track_order_dl.g.dart';

/// status : 1
/// message : "success!"
/// order_id : 565
/// order_no : 6273006202119049
/// store_id : 190
/// store_image : "https://fox-delivery-staging.startuptrinity.com/assets/images/profile-images/provider/19046150520200812.jpg"
/// store_banner : "https://fox-delivery-staging.startuptrinity.com/assets/images/store-images/3105423202010147.jpg"
/// store_ratting : 4.88
/// store_contact_number : "+911234567891"
/// order_time : "Mon 19 Apr, 06:30PM"
/// total_items : 2
/// service_category_name : "FOOD DELIVERY"
/// driver_contact_number : ""
/// driver_selected_service_String? : ""
/// delivery_people_name : ""
/// driver_id : 0
/// driver_fcm_token : ""
/// driver_image : ""
/// driver_rating : 0
/// cancel_charge : 0
/// total_pay : 275
/// schedule_order_date_time : ""
/// store_name : "Desi Dhaba"
/// pickup_address : "#1306, The Spire Near Sheetal Park BRTS Stop, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Dharam Nagar Society, Rajkot, Gujarat 360007, India"
/// pickup_lat_long : "22.31880139999999,70.7671488"
/// destination_address : "The Spire, 303, 3rd Floor, Near Shital Park BRTS Stop, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Dharam Nagar Society, Rajkot, Gujarat 360006, India"
/// destination_lat_long : "22.31896075274243,70.7670958712697"
/// order_current_status : 1
/// order_cancel_reject_title : ""
/// order_status_list : [{"order_status":1,"update_status_time":"06:30 PM"}]
/// message_code : 1

@JsonSerializable(
  createToJson: true,
  includeIfNull: false,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class TrackOrderPojo {
  int status = 0;
  int orderId = 0;
  int orderNo = 0;
  int orderStatus = 0;
  int storeId = 0;
  int storeDetailsId = 0;
  double storeRatting = 0;
  int totalItems = 0;
  int driverId = 0;
  // double driverRating = 0;
  double totalPay = 0;
  int userTakenType = 0;
  double cancelCharge = 0;
  int orderCurrentStatus = 0;
  int messageCode = 0;
  int paymentType = 0;
  String message = "";
  String storeImage = "";
  String storeBanner = "";
  String orderTime = "";
  String cancelBy = "";
  String cancelReason = "";
  String serviceCategoryName = "";
  String contactNumber = "";
  String storeContactNumber = "";
  String driverContactNumber = "";
  // String driverSelectedServiceString = "";
  String deliveryPeopleName = "";
  String scheduleOrderDateTime = "";
  String acceptOrderTime = "";
  String prepareOrderTime = "";
  String sendOrderTime = "";
  String arriveOrderTime = "";
  String driverFcmToken = "";
  String storeFcmToken = "";
  String customerFcmToken = "";
  // String driverImage = "";
  String otp = "";
  String storeName = "";
  String pickupAddress = "";
  String pickupLatLong = "";
  String destinationAddress = "";
  String destinationLatLong = "";
  String orderCancelRejectTitle = "";
  List<OrderStatusListItem> orderStatusList = [];

  TrackOrderPojo({
    this.status = 0,
    this.storeRatting = 0,
    this.orderId = 0,
    this.orderNo = 0,
    this.orderStatus = 0,
    this.storeId = 0,
    this.storeDetailsId = 0,
    this.driverId = 0,
    this.userTakenType = 0,
    this.totalItems = 0,
    // this.driverRating = 0,
    this.totalPay = 0,
    this.cancelCharge = 0,
    this.orderCurrentStatus = 0,
    this.messageCode = 0,
    this.paymentType = 0,
    this.storeImage = "",
    this.storeBanner = "",
    this.message = "",
    this.orderTime = "",
    this.cancelBy = "",
    this.cancelReason = "",
    this.serviceCategoryName = "",
    this.contactNumber = "",
    this.storeContactNumber = "",
    this.driverContactNumber = "",
    // this.driverSelectedServiceString = "",
    this.deliveryPeopleName = "",
    this.scheduleOrderDateTime = "",
    this.acceptOrderTime = "",
    this.prepareOrderTime = "",
    this.sendOrderTime = "",
    this.arriveOrderTime = "",
    this.driverFcmToken = "",
    this.storeFcmToken = "",
    this.customerFcmToken = "",
    // this.driverImage = "",
    this.otp = "",
    this.storeName = "",
    this.pickupAddress = "",
    this.pickupLatLong = "",
    this.destinationAddress = "",
    this.destinationLatLong = "",
    this.orderCancelRejectTitle = "",
    List<OrderStatusListItem>? orderStatusList,
  }) {
    this.orderStatusList = orderStatusList ?? [];
  }

  factory TrackOrderPojo.fromJson(Map<String, dynamic> json) =>
      _$TrackOrderPojoFromJson(json);

  Map<String, dynamic> toJson() => _$TrackOrderPojoToJson(this);
}

/// order_status : 1
/// update_status_time : "06:30 PM"

@JsonSerializable(
  createToJson: true,
  includeIfNull: false,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class OrderStatusListItem {
  int orderStatus = 0;
  String updateStatusTime = "";

  OrderStatusListItem({this.orderStatus = 0, this.updateStatusTime = ""});

  factory OrderStatusListItem.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusListItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusListItemToJson(this);
}

//Command: flutter pub run build_runner build --delete-conflicting-outputs
