import 'package:json_annotation/json_annotation.dart';

part 'deliveries_history_dl.g.dart';

/// status : 1
/// message : "success!"
/// message_code : 1
/// current_page : 1
/// last_page : 3
/// total : 30
/// order_list : [{"order_id":592,"order_no":4492111202122052,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Sat 22 May ,2021","service_time":"11:21","service_date_time":"2021-05-22 11:21:49","schedule_order_date_time":"2021-05-22 11:21:49","delivery_address":"Unnamed Road, Swaminarayan Nagar, Diya Nagar, Samrat Industrial Area, Rajkot, Gujarat 360004, India","total_pay":138.77,"order_status":2,"user_taken_type":1},{"order_id":591,"order_no":1544710202122053,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Sat 22 May ,2021","service_time":"10:47","service_date_time":"2021-05-22 10:47:54","schedule_order_date_time":"2021-05-22 10:47:54","delivery_address":"Unnamed Road, Swaminarayan Nagar, Diya Nagar, Samrat Industrial Area, Rajkot, Gujarat 360004, India","total_pay":205.97,"order_status":2,"user_taken_type":1},{"order_id":571,"order_no":5093411202106059,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Thu 06 May ,2021","service_time":"11:34","service_date_time":"2021-05-06 11:34:09","schedule_order_date_time":"2021-05-06 11:34:09","delivery_address":"Unnamed Road, Swaminarayan Nagar, Diya Nagar, Samrat Industrial Area, Rajkot, Gujarat 360004, India","total_pay":204.85,"order_status":3,"user_taken_type":1},{"order_id":458,"order_no":6383609202123038,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Tue 23 Mar ,2021","service_time":"09:36","service_date_time":"2021-03-23 09:36:38","schedule_order_date_time":"2021-03-23 09:36:38","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":204.85,"order_status":1,"user_taken_type":1},{"order_id":457,"order_no":1412909202123034,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Hardik Store","service_date":"Tue 23 Mar ,2021","service_time":"09:29","service_date_time":"2021-03-23 09:29:41","schedule_order_date_time":"2021-03-23 09:29:41","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":141.12,"order_status":1,"user_taken_type":1},{"order_id":456,"order_no":7342709202123036,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Tue 23 Mar ,2021","service_time":"09:27","service_date_time":"2021-03-23 09:27:34","schedule_order_date_time":"2021-03-23 09:27:34","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":143.25,"order_status":1,"user_taken_type":1},{"order_id":455,"order_no":5372209202123039,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Tue 23 Mar ,2021","service_time":"09:22","service_date_time":"2021-03-23 09:22:37","schedule_order_date_time":"2021-03-23 09:22:37","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":204.85,"order_status":1,"user_taken_type":1},{"order_id":454,"order_no":5292209202123031,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Tue 23 Mar ,2021","service_time":"09:22","service_date_time":"2021-03-23 09:22:29","schedule_order_date_time":"2021-03-23 09:22:29","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":204.85,"order_status":10,"user_taken_type":1},{"order_id":448,"order_no":1174112202119031,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Fox Jek","service_date":"Fri 19 Mar ,2021","service_time":"12:41","service_date_time":"2021-03-19 12:41:17","schedule_order_date_time":"2021-03-19 13:41:43","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":228.48,"order_status":3,"user_taken_type":1},{"order_id":446,"order_no":7113812202119035,"category_id":5,"category_name":"FOOD DELIVERY","category_icon":"https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png","store_name":"Desi Dhaba","service_date":"Fri 19 Mar ,2021","service_time":"12:38","service_date_time":"2021-03-19 12:38:11","schedule_order_date_time":"2021-03-19 13:38:34","delivery_address":"602, 150 Feet Ring Rd, Sheetal Park, Manharpura 1, Chowk, Rajkot, Gujarat 360007, India","total_pay":91.73,"order_status":1,"user_taken_type":1}]
@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class DeliveriesHistoryPojo {
  int status = 0;
  int messageCode = 0;
  int currentPage = 0;
  int lastPage = 0;
  int total = 0;
  String message = "";
  @JsonKey(name: "order_list")
  List<DeliveriesHistoryItem> orderList = [];

  DeliveriesHistoryPojo({
    this.status = 0,
    this.messageCode = 0,
    this.currentPage = 0,
    this.lastPage = 0,
    this.total = 0,
    this.message = "",
    List<DeliveriesHistoryItem>? orderList,
  }) {
    this.orderList = orderList ?? [];
  }

  factory DeliveriesHistoryPojo.fromJson(Map<String, dynamic> json) => _$DeliveriesHistoryPojoFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveriesHistoryPojoToJson(this);
}

/// order_id : 592
/// order_no : 4492111202122052
/// category_id : 5
/// category_name : "FOOD DELIVERY"
/// category_icon : "https://fox-jek-staging.startuptrinity.com/assets/images/service-category/food-delivery-128.png"
/// store_name : "Desi Dhaba"
/// service_date : "Sat 22 May ,2021"
/// service_time : "11:21"
/// service_date_time : "2021-05-22 11:21:49"
/// schedule_order_date_time : "2021-05-22 11:21:49"
/// delivery_address : "Unnamed Road, Swaminarayan Nagar, Diya Nagar, Samrat Industrial Area, Rajkot, Gujarat 360004, India"
/// total_pay : 138.77
/// order_status : 2
/// user_taken_type : 1

@JsonSerializable(createToJson: true, includeIfNull: false, fieldRename: FieldRename.snake, explicitToJson: true)
class DeliveriesHistoryItem {
  int orderId = 0;
  int orderNo = 0;
  int categoryId = 0;
  int allowReorder = 0;
  double totalPay = 0;
  int orderStatus = 0;
  int userTakenType = 0;
  String categoryName = "";
  String categoryIcon = "";
  String storeName = "";
  String serviceDateTime = "";
  String scheduleOrderDateTime = "";
  String deliveryAddress = "";

  DeliveriesHistoryItem({
    this.orderId = 0,
    this.orderNo = 0,
    this.categoryId = 0,
    this.allowReorder = 0,
    this.totalPay = 0,
    this.orderStatus = 0,
    this.userTakenType = 0,
    this.categoryName = "",
    this.categoryIcon = "",
    this.storeName = "",
    this.serviceDateTime = "",
    this.scheduleOrderDateTime = "",
    this.deliveryAddress = "",
  });

  factory DeliveriesHistoryItem.fromJson(Map<String, dynamic> json) => _$DeliveriesHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveriesHistoryItemToJson(this);
}
