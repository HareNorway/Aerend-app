import 'package:json_annotation/json_annotation.dart';

part 'rides_history_dl.g.dart';

/// status : 1
/// message : "Success"
/// message_code : 1
/// current_page : 1
/// last_page : 6
/// total : 51
/// rides : [{"ride_id":593,"booking_no":3111312202117051,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/courier-service-128.png","category_name":"Courier Service","service_category_id":4,"ride_status":9,"total_pay":157.04,"pickup_date":"17 May, 2021","pickup_time":"12:13 PM","service_date_time":"2021-05-17 12:13:11","schedule_order_date_time":"2021-05-17 12:13:11","pickup_address":"Chandravada Road, Raval, Gujarat 361325, India","destination_address":"Mahajan Vadi Rd, Jam Raval, Gujarat 361325, India"},{"ride_id":565,"booking_no":7123307202129043,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/courier-service-128.png","category_name":"Courier Service","service_category_id":4,"ride_status":9,"total_pay":120,"pickup_date":"29 Apr, 2021","pickup_time":"07:33 AM","service_date_time":"2021-04-29 07:33:12","schedule_order_date_time":"2021-04-29 07:33:12","pickup_address":"Unnamed Road, Madhav Park, Punit Nagar, Mavdi, Rajkot, Gujarat 360004, India","destination_address":"Unnamed Road, Pal, Gujarat, India"},{"ride_id":548,"booking_no":4473005202121041,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/courier-service-128.png","category_name":"Courier Service","service_category_id":4,"ride_status":4,"total_pay":112,"pickup_date":"21 Apr, 2021","pickup_time":"05:30 AM","service_date_time":"2021-04-21 05:30:47","schedule_order_date_time":"2021-04-21 05:30:47","pickup_address":"The Spire – 1305, 150 Feet Ring Rd, near Shital Park, Sheetal Park, Manharpura 1, Dharam Nagar Society, Rajkot, Gujarat 360006, India","destination_address":"150-ft. Ring Road, near Sterling Hospital, Radhika Park, Rajkot, Gujarat 360005, India"},{"ride_id":157,"booking_no":2004804202110027,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/bike-ride-128.png","category_name":"Bike Ride","service_category_id":1,"ride_status":9,"total_pay":112,"pickup_date":"10 Feb, 2021","pickup_time":"04:48 PM","service_date_time":"2021-02-10 16:48:00","schedule_order_date_time":"2021-02-10 16:48:00","pickup_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","destination_address":"150-ft. Ring Road, near Sterling Hospital, Radhika Park, Rajkot, Gujarat 360005, India"},{"ride_id":71,"booking_no":1342109202030129,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/bike-ride-128.png","category_name":"Bike Ride","service_category_id":1,"ride_status":9,"total_pay":142947.15,"pickup_date":"30 Dec, 2020","pickup_time":"09:21 PM","service_date_time":"2020-12-30 21:21:34","schedule_order_date_time":"2020-12-30 21:21:34","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"Gaytri Nagar 9 Khandheriya Mension, Gayatri Nagar, Gondal, Gujarat 360311, India"},{"ride_id":70,"booking_no":4384108202030126,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/taxi-ride-128.png","category_name":"Taxi Ride","service_category_id":2,"ride_status":4,"total_pay":324.8,"pickup_date":"30 Dec, 2020","pickup_time":"08:41 PM","service_date_time":"2020-12-30 20:41:38","schedule_order_date_time":"2020-12-30 20:41:38","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"5, 150 Feet Ring Rd Jivan Nagar, 150 Feet Ring Rd, Jivan Nagar, Tirupati Nagar, Rajkot, Gujarat 360007, India"},{"ride_id":65,"booking_no":5123308202028124,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/taxi-ride-128.png","category_name":"Taxi Ride","service_category_id":2,"ride_status":9,"total_pay":336,"pickup_date":"28 Dec, 2020","pickup_time":"08:33 PM","service_date_time":"2020-12-28 20:33:12","schedule_order_date_time":"2020-12-28 20:33:12","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"5, 150 Feet Ring Rd Jivan Nagar, 150 Feet Ring Rd, Jivan Nagar, Tirupati Nagar, Rajkot, Gujarat 360007, India"},{"ride_id":64,"booking_no":7575306202028129,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/courier-service-128.png","category_name":"Courier Service","service_category_id":4,"ride_status":9,"total_pay":89.82,"pickup_date":"28 Dec, 2020","pickup_time":"06:53 PM","service_date_time":"2020-12-28 18:53:57","schedule_order_date_time":"2020-12-28 18:53:57","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"5, 150 Feet Ring Rd Jivan Nagar, 150 Feet Ring Rd, Jivan Nagar, Tirupati Nagar, Rajkot, Gujarat 360007, India"},{"ride_id":63,"booking_no":9553906202028128,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/bike-ride-128.png","category_name":"Bike Ride","service_category_id":1,"ride_status":4,"total_pay":112,"pickup_date":"28 Dec, 2020","pickup_time":"06:39 PM","service_date_time":"2020-12-28 18:39:55","schedule_order_date_time":"2020-12-28 18:39:55","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"5, 150 Feet Ring Rd Jivan Nagar, 150 Feet Ring Rd, Jivan Nagar, Tirupati Nagar, Rajkot, Gujarat 360007, India"},{"ride_id":62,"booking_no":2003706202028127,"category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/bike-ride-128.png","category_name":"Bike Ride","service_category_id":1,"ride_status":4,"total_pay":112,"pickup_date":"28 Dec, 2020","pickup_time":"06:37 PM","service_date_time":"2020-12-28 18:37:00","schedule_order_date_time":"2020-12-28 18:37:00","pickup_address":"Sheetal Park, Puneet Nagar, Bajrang Wadi, Rajkot, Gujarat 360006, India","destination_address":"5, 150 Feet Ring Rd Jivan Nagar, 150 Feet Ring Rd, Jivan Nagar, Tirupati Nagar, Rajkot, Gujarat 360007, India"}]

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class RidesHistoryPojo {
  int status = 0;
  int messageCode = 0;
  int currentPage = 0;
  int lastPage = 0;
  int total = 0;
  String message = "";
  List<RidesItem> rides = [];

  RidesHistoryPojo({
    this.status = 0,
    this.messageCode = 0,
    this.currentPage = 0,
    this.lastPage = 0,
    this.total = 0,
    this.message = "",
    List<RidesItem>? rides,
  }) {
    this.rides = rides ?? [];
  }

  factory RidesHistoryPojo.fromJson(Map<String, dynamic> json) => _$RidesHistoryPojoFromJson(json);

  Map<String, dynamic> toJson() => _$RidesHistoryPojoToJson(this);
}

/// ride_id : 593
/// booking_no : 3111312202117051
/// category_icon : "https://fox-jek-staging.startuptrinity.com/assets/images/service-category/courier-service-128.png"
/// category_name : "Courier Service"
/// service_category_id : 4
/// ride_status : 9
/// total_pay : 157.04
/// pickup_date : "17 May, 2021"
/// pickup_time : "12:13 PM"
/// service_date_time : "2021-05-17 12:13:11"
/// schedule_order_date_time : "2021-05-17 12:13:11"
/// pickup_address : "Chandravada Road, Raval, Gujarat 361325, India"
/// destination_address : "Mahajan Vadi Rd, Jam Raval, Gujarat 361325, India"

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class RidesItem {
  int rideId = 0;
  int bookingNo = 0;
  int serviceCategoryId = 0;
  int rideStatus = 0;
  double totalPay = 0;
  String categoryIcon = "";
  String categoryName = "";
  String serviceDateTime = "";
  String scheduleOrderDateTime = "";
  String pickupAddress = "";
  String destinationAddress = "";

  RidesItem({
    this.rideId = 0,
    this.bookingNo = 0,
    this.serviceCategoryId = 0,
    this.rideStatus = 0,
    this.totalPay = 0,
    this.categoryIcon = "",
    this.categoryName = "",
    this.serviceDateTime = "",
    this.scheduleOrderDateTime = "",
    this.pickupAddress = "",
    this.destinationAddress = "",
  });

  factory RidesItem.fromJson(Map<String, dynamic> json) => _$RidesItemFromJson(json);

  Map<String, dynamic> toJson() => _$RidesItemToJson(this);
}
