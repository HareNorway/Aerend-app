import '../../rideService/searched_location_dl.dart';

class CourierBookingDetailData {
  List<SearchedLocation>? locationList;
  int? paymentType;
  int? serviceId;
  int? promoCodeId;
  String? rideEst;
  String? rideDistance;
  String? scheduleDate;
  dynamic weightLimit;
  dynamic widthLimit;
  dynamic heightLimit;

  CourierBookingDetailData(
    this.locationList,
    this.paymentType,
    this.serviceId,
    this.promoCodeId,
    this.rideEst,
    this.rideDistance,
    this.scheduleDate,
    this.weightLimit,
    this.widthLimit,
    this.heightLimit,
  );
}

enum ParcelType { transport, purchase }
