import 'package:json_annotation/json_annotation.dart';

part 'ride_detail_dl.g.dart';

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class RideDetailPojo {
  int status = 0;
  int messageCode = 0;
  int rideId = 0;
  int rideServiceCategoryId = 0;
  int bookingType = 0;
  int payment = 0;
  int paymentStatus = 0;
  int waypointMsgCode = 0;
  int vehicleModelYear = 0;
  int rideStatus = 0;
  int driverId = 0;
  int driverSelectedServiceCatId = 0;
  int cancelByAdmin = 0;
  String message = "";
  String? additionalRemark;
  String? bookingNo;
  String? pickupDateTime;
  String? serviceDateTime;
  String? cancelBy;
  String? cancelReason;
  String? driverSelectedServiceString;
  String? driverFcmToken;
  String? vehicleManufactureName;
  String? vehiclePlatNo;
  String? vehicleModelName;
  String? vehicleColor;
  String? otp;
  String? totalDistance;
  String? estimatedTime;
  String? promocodeName;
  String? serviceType;
  String? serviceTypeIcon;
  String? driverContactNumber;
  String? waypointMessage;
  String? driverName;
  String? driverImage;

  double surchargeCost = 0;
  double costPerKm = 0;
  double baseFare = 0;
  double costPerMin = 0;
  double timeFareAmount = 0;
  double rideFare = 0;
  double referDiscount = 0;
  double minAdjustmentAmount = 0;
  double promocodeDiscount = 0;
  double tax = 0;
  double tip = 0;
  double subtotal = 0;
  double discount = 0;
  double totalPay = 0;
  double driverRating = 0;
  double userRatingStatus = 0;

  List<AddressListItem> addressList = [];
  CourierDetails? courierDetails;

  RideDetailPojo({
    this.status = 0,
    this.message = "",
    this.messageCode = 0,
    this.rideId = 0,
    this.surchargeCost = 0,
    this.additionalRemark,
    this.rideServiceCategoryId = 0,
    this.bookingType = 0,
    this.cancelByAdmin = 0,
    this.bookingNo,
    this.pickupDateTime,
    this.serviceDateTime,
    this.rideStatus = 0,
    this.cancelBy,
    this.cancelReason,
    this.driverId = 0,
    this.driverSelectedServiceCatId = 0,
    this.driverSelectedServiceString,
    this.driverFcmToken,
    this.vehicleManufactureName,
    this.vehiclePlatNo,
    this.vehicleModelYear = 0,
    this.vehicleModelName,
    this.vehicleColor,
    this.otp,
    this.costPerKm = 0,
    this.baseFare = 0,
    this.costPerMin = 0,
    this.timeFareAmount = 0,
    this.totalDistance,
    this.estimatedTime,
    this.rideFare = 0,
    this.referDiscount = 0,
    this.minAdjustmentAmount = 0,
    this.promocodeDiscount = 0,
    this.promocodeName,
    this.tax = 0,
    this.tip = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.totalPay = 0,
    this.payment = 0,
    this.paymentStatus = 0,
    this.driverName,
    this.driverImage,
    this.driverRating = 0,
    this.serviceType,
    this.serviceTypeIcon,
    this.driverContactNumber,
    this.waypointMessage,
    this.userRatingStatus = 0,
    this.waypointMsgCode = 0,
    List<AddressListItem>? addressList,
    this.courierDetails,
  }) {
    this.addressList = addressList ?? [];
  }

  factory RideDetailPojo.fromJson(Map<String, dynamic> json) => _$RideDetailPojoFromJson(json);

  Map<String, dynamic> toJson() => _$RideDetailPojoToJson(this);
}

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class CourierDetails {
  String? senderName;
  String? senderContactNumber;
  String? shopName;
  String? shopLandmark;
  String? recipientName;
  String? recipientContactNumber;
  String? recipientLandmark;
  String? recipientHouseName;
  String? parcelName;
  String? description;
  String? deliveryInstruction;
  double weightCloseLimit = 0;
  double estimatePrice = 0;
  double goodsHeight = 0;
  double goodsWeight = 0;
  double goodsWidth = 0;
  double goodsLength = 0;
  double weightStartLimit = 0;
  int courierType = 0;

  List<PurchaseItemList> purchaseItemList = [];

  CourierDetails({
    this.shopName,
    this.recipientName,
    this.recipientContactNumber,
    this.recipientHouseName,
    this.recipientLandmark,
    this.parcelName,
    this.senderName,
    this.senderContactNumber,
    this.shopLandmark,
    this.description,
    this.deliveryInstruction,
    this.weightCloseLimit = 0,
    this.estimatePrice = 0,
    this.goodsHeight = 0,
    this.goodsWidth = 0,
    this.goodsLength = 0,
    this.goodsWeight = 0,
    this.weightStartLimit = 0,
    this.courierType = 0,
    List<PurchaseItemList>? purchaseItemList,
  }) {
    this.purchaseItemList = purchaseItemList ?? [];
  }

  factory CourierDetails.fromJson(Map<String, dynamic> json) => _$CourierDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$CourierDetailsToJson(this);
}

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class PurchaseItemList {
  String? itemName;
  String? itemValue;

  PurchaseItemList({this.itemName, this.itemValue});

  factory PurchaseItemList.fromJson(Map<String, dynamic> json) => _$PurchaseItemListFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseItemListToJson(this);
}

/// address : "Unnamed Road, Madhav Park, Punit Nagar, Mavdi, Rajkot, Gujarat 360004, India"
/// address_lat : "22.255638333333"
/// address_long : "70.785095"

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class AddressListItem {
  String? address;
  String? addressLat;
  String? addressLong;

  AddressListItem({this.address, this.addressLat, this.addressLong});

  factory AddressListItem.fromJson(Map<String, dynamic> json) => _$AddressListItemFromJson(json);

  Map<String, dynamic> toJson() => _$AddressListItemToJson(this);
}
