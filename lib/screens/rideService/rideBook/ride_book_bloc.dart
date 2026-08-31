import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../commonView/common_view.dart';
import '../../../dialogs/ride_common_dialog.dart';
import '../../../utils/get_route_utils.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/selectPaymentMethod/select_payment_method.dart';
import '../../common/wallet/my_wallet_repo.dart';
import '../../common/wallet/wallet_dl.dart';
import '../../deliveryService/checkout/checkout_dl.dart';
import '../../deliveryService/checkout/checkout_repo.dart';
import '../searched_location_dl.dart';
import 'ride_book.dart';
import 'ride_book_dl.dart';
import 'ride_book_repo.dart';
import 'ride_request_bottom_sheet.dart';

class RideBookBloc extends Bloc {
  String tag = "RideBookBloc>>>";
  BuildContext context;

  bool? isSchedule = false;
  int promoCodeAppliedID = 0, rideId = 0;
  GoogleMapController? googleMapController;
  late List<SearchedLocation> locationList;
  double walletBalance = 0, rideCost = 0;
  Map<String, dynamic> courierData;
  Timer? _timer;
  String? scheduleDate;
  ServiceTypeItem? selectedServiceType;
  final RideBookRepo _rideBookRepo = RideBookRepo();
  final MyWalletRepo _myWalletRepo = MyWalletRepo();
  final CheckoutRepo _checkoutRepo = CheckoutRepo();

  State<RideBook> state;

  RideBookBloc(this.context, this.locationList, this.courierData, this.state) {
    getWalletAmount();
    getPromoCode();
  }

  final _polyLinesController = BehaviorSubject<Map<PolylineId, Polyline>>();
  final _distanceController = BehaviorSubject<double>();
  final _timeController = BehaviorSubject<int>();
  final dimensionAndWeightLimitSubject = BehaviorSubject<String?>();
  // final weightLimitSubject = BehaviorSubject<String?>();
  final _amountController = BehaviorSubject<double>();
  final _requestTimeOutController = BehaviorSubject<bool>.seeded(false);
  final _markersListController = BehaviorSubject<List<Marker>>();
  final _selectedPromoCodeController = BehaviorSubject<PromoCodeListItem?>();
  final _selectedPaymentMethodController = BehaviorSubject<int>.seeded(1);
  final _promoCodeListController = BehaviorSubject<List<PromoCodeListItem>?>();
  final _subjectServiceData = BehaviorSubject<ApiResponse<ServiceTypeModel>>();
  final _subjectApplyPromoCode = BehaviorSubject<ApiResponse<ApplyPromoCodePojo>>();
  final _subjectRideBook = BehaviorSubject<ApiResponse<RideBookPojo>>();
  final _subjectScheduleRideBook = BehaviorSubject<ApiResponse<RideBookPojo>>();
  final _subjectCancelRide = BehaviorSubject<ApiResponse<BaseModel>>();
  final _subjectSurgeCharge = BehaviorSubject<ApiResponse<SurgeChargePojo>>();

  BehaviorSubject<ApiResponse<ServiceTypeModel>> get subjectServiceData => _subjectServiceData;

  BehaviorSubject<ApiResponse<ApplyPromoCodePojo>> get subjectApplyPromoCode => _subjectApplyPromoCode;

  BehaviorSubject<ApiResponse<RideBookPojo>> get subjectRideBook => _subjectRideBook;

  BehaviorSubject<ApiResponse<RideBookPojo>> get subjectScheduleRideBook => _subjectScheduleRideBook;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectCancelRide => _subjectCancelRide;

  BehaviorSubject<ApiResponse<SurgeChargePojo>> get subjectSurgeCharge => _subjectSurgeCharge;

  Stream<List<Marker>> get markersList => _markersListController.stream;

  Stream<double> get distance => _distanceController.stream;

  Stream<bool> get requestTimeOut => _requestTimeOutController.stream;

  Stream<int> get time => _timeController.stream;

  Stream<double> get amount => _amountController.stream;

  Stream<PromoCodeListItem?> get selectedPromoCode => _selectedPromoCodeController.stream;

  Stream<int> get selectedPaymentMethod => _selectedPaymentMethodController.stream;

  Stream<Map<PolylineId, Polyline>> get polyLines => _polyLinesController.stream;

  Stream<List<PromoCodeListItem>?> get promoCodeList => _promoCodeListController.stream;

  Function(List<Marker>) get changeMarkerList => _markersListController.sink.add;

  Function(Map<PolylineId, Polyline>) get changePolyLines => _polyLinesController.sink.add;

  Function(double) get changeDistance => _distanceController.sink.add;

  Function(bool) get changeRequestTimeOut => _requestTimeOutController.sink.add;

  Function(int) get changeTime => _timeController.sink.add;

  Function(double) get changeAmount => _amountController.sink.add;

  Function(PromoCodeListItem?) get changeSelectedPromoCode => _selectedPromoCodeController.sink.add;

  Function(int) get changeSelectedPaymentMethod => _selectedPaymentMethodController.sink.add;

  Function(List<PromoCodeListItem>?) get changePromoCodeList => _promoCodeListController.sink.add;

  serviceDataApiCall(double? currentLat, double? currentLong) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectServiceData.sink.add(ApiResponse.loading());
      try {
        var response = ServiceTypeModel.fromJson(
          await _rideBookRepo.serviceDataApi(
            currentLat,
            currentLong,
            courierData[ApiParam.paramGoodsWeight],
            courierData[ApiParam.paramCourierType],
            courierData[ApiParam.paramEstimatePrice],
          ),
        );

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          _subjectServiceData.sink.add(ApiResponse.completed(response));
          if (response.serviceType.isNotEmpty) {
            int index = response.serviceType.indexWhere((element) => element.serviceStatus == 1);
            int selectedIndex = response.serviceType.indexWhere((element) => element.isSelected);
            if (index >= 0 && selectedIndex == -1) {
              vehicleSelect(index, false);
            }
          }
        } else {
          _subjectServiceData.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectServiceData.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  applyPromoCodeApiCall(PromoCodeListItem selectedPromoCodeItem) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectApplyPromoCode.sink.add(ApiResponse.loading());
      try {
        var response = ApplyPromoCodePojo.fromJson(await _rideBookRepo.applyPromoCodeApi(selectedPromoCodeItem.promocodeName, rideCost));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectApplyPromoCode.sink.add(ApiResponse.completed(response));
          changeSelectedPromoCode(selectedPromoCodeItem);
          double discountAmount = rideCost - getDoubleFromDynamic(response.discountAmount ?? 0);
          changeAmount(discountAmount);
        } else {
          _subjectApplyPromoCode.sink.add(ApiResponse.error(message));
        }
        Navigator.pop(context, true);
      } catch (e) {
        logd(tag, e.toString());
        _subjectApplyPromoCode.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  rideBookingApiCall(
    bool isLoading,
    bool isSchedule,
    String? scheduleDate, {
    int? rideID = 0,
    int paymentType = paymentTypeCash,
    int cardId = 0,
  }) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      changeRequestTimeOut(false);
      if (isLoading) {
        if (isSchedule) {
          _subjectScheduleRideBook.sink.add(ApiResponse.loading());
        } else {
          _subjectRideBook.sink.add(ApiResponse.loading());
        }
      }
      try {
        courierData.addAll({
          ApiParam.paramUserId: prefGetInt(prefUserId),
          ApiParam.paramAccessToken: prefGetString(prefAccessToken),
          ApiParam.paramServiceCatId: 4,
          ApiParam.paramRideId: rideID,
          ApiParam.paramEstimatedTime: "${_timeController.value} ${languages.min}",
          ApiParam.paramPaymentType: /*_selectedPaymentMethodController.valueOrNull ?? PAYMENT_TYPE_CASH*/ paymentType,
          ApiParam.paramCardId: cardId,
          ApiParam.paramTotalDistance: "${_distanceController.value} ${languages.km.toLowerCase()}",
          ApiParam.paramServiceTypeId: selectedServiceType?.id ?? 0,
          ApiParam.paramPickupDateTime: scheduleDate,
          ApiParam.paramPromoCode: _selectedPromoCodeController.value?.promocodeName ?? "",
        });

        var response = RideBookPojo.fromJson(await _rideBookRepo.courierBookApi(courierData));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectScheduleRideBook.sink.add(ApiResponse.completed(response));
          _subjectRideBook.sink.add(ApiResponse.completed(response));
          rideId = response.rideId!;
          // logd(tag,"Accept TImeout : ${response?.acceptTimeOut}");
          showRequestTimeOut(response.acceptTimeOut ?? 30);
          showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              enableDrag: false,
              isDismissible: false,
              builder: (context) {
                return WillPopScope(
                  onWillPop: () async => false,
                  child: RideRequestBottomSheet(
                    bloc: this,
                  ),
                );
              });
        } else {
          _subjectScheduleRideBook.sink.add(ApiResponse.error(message));
          _subjectRideBook.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectScheduleRideBook.sink.add(ApiResponse.error(e.toString()));
        _subjectRideBook.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  cancelRideBookingApi() async {
    FocusManager.instance.primaryFocus!.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectCancelRide.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _rideBookRepo.cancelRideBookingApi(rideId.toString()));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectCancelRide.sink.add(ApiResponse.completed(response));
          Navigator.pop(context, true);
          Navigator.pop(context);
        } else {
          _subjectCancelRide.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectCancelRide.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subjectCancelRide.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      if (!state.mounted) return;
      openSimpleSnackbar( languages.internetConnLostTitle);
    }
  }

  mapApiCall(String origin, String destination, List<LatLng> wayPoints) async {
    await GetRoutesUtils().getRoutes(origin, destination, wayPoints, (polyLines, duration, distance) async {
      changePolyLines(polyLines);
      changeDistance(getDoubleFromDynamic((distance / 1000).toStringAsFixed(2)));
      changeTime((duration / 60).round());
      // getCurrentLocation();
      serviceDataApiCall(locationList.first.lat, locationList.first.lng);

      //Animate Map
      // LatLng startLatLng, endLatLng, southwestLatLng, northeastLatLng;
      // startLatLng = LatLng(locationList[0].lat, locationList[0].lng);
      // endLatLng = LatLng(locationList[(locationList.length - 1)].lat, locationList[(locationList.length - 1)].lng);
      // if (startLatLng.latitude <= endLatLng.latitude) {
      //   southwestLatLng = startLatLng;
      //   northeastLatLng = endLatLng;
      // } else {
      //   southwestLatLng = endLatLng;
      //   northeastLatLng = startLatLng;
      // }
      // LatLngBounds bound = LatLngBounds(southwest: southwestLatLng, northeast: northeastLatLng);
      // LatLng centerBounds =
      //     LatLng((bound.northeast.latitude + bound.southwest.latitude) / 2, (bound.northeast.longitude + bound.southwest.longitude) / 2);
      // await zoomToFit(googleMapController, bound, centerBounds);
      setMapFitToTour(Set<Polyline>.of(polyLines.values), googleMapController!);
    });
  }

  requestAgain() {
    rideBookingApiCall(false, false, null, rideID: rideId);
  }

  bookRidePrepare(bool isSchedule, String? scheduleDate) {
    /*if (_selectedPaymentMethodController.value == 3 && !(walletBalance >= _amountController.value)) {
      openSimpleSnackbar( languages.apiMsg109);
      return;
    }
*/
    openSelectPaymentMethod(isSchedule, scheduleDate);
  }

  openSelectPaymentMethod(bool isSchedule, String? scheduleTime) {
    openScreenWithResult(
        context,
        SelectPaymentMethod(
          payTo: deliveries,
          totalPay: _amountController.value,
        )).then((value) {
      if (value != null && value["paymentType"] != null) {
        rideBookingApiCall(true, isSchedule, scheduleDate, paymentType: value["paymentType"]);
      }
    });
  }

  onClickBookRide(bool isSchedule) {
    if (selectedServiceType != null) {
      this.isSchedule = isSchedule;
      openRequiredInfoDialog(context, () {
        if (isSchedule) {
          showDateAndTimePicker();
        } else {
          bookRidePrepare(false, null);
        }
      });
    } else {
      openSimpleSnackbar( languages.vehicleNotAvailable);
    }
  }

  getPromoCode() async {
    try {
      var response = PromoCodePojo.fromJson(await _checkoutRepo.callPromoCodeApi());

      if (!state.mounted) return;
      String message = getApiMsg(context, response.messageCode, response.message);
      if (isApiStatus(context, response.status, message, true, showMess: false)) {
        changePromoCodeList(response.promocodeList);
      }
    } catch (e) {
      logd(tag, e.toString());
    }
  }

  getWalletAmount() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var response = WalletBalancePojo.fromJson(await _myWalletRepo.getWalletBalance());

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true, showMess: false)) {
          walletBalance = getDoubleFromDynamic(response.walletBalance ?? 0);
        }
      } catch (e) {
        logd(tag, e.toString());
      }
    }
  }

  selectPaymentMethodDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RideCommonDialog(
            dialogImg: "assets/images/dialog_payment_img.png",
            title: languages.changePaymentMethod,
            spinnerList: [languages.cash, languages.card, languages.wallet],
            defaultSpinnerSelectionPos: (_selectedPaymentMethodController.valueOrNull ?? 1) - 1,
            positiveBtnTxt: languages.done,
            negativeBtnTxt: languages.cancel,
            positiveBtnOnClick: (spinnerPos, textFieldValue) {
              changeSelectedPaymentMethod(spinnerPos + 1);
              Navigator.pop(context, true);
            },
            negativeBtnOnClick: () {
              Navigator.pop(context, true);
            },
          );
        });
  }

  promoCodeDialog() {
    if (_promoCodeListController.valueOrNull != null && _promoCodeListController.value!.isNotEmpty) {
      List<String> promoCodeNameList = [];
      for (var element in _promoCodeListController.value!) {
        promoCodeNameList.add(element.promocodeName);
      }
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StreamBuilder<ApiResponse<ApplyPromoCodePojo>>(
                stream: subjectApplyPromoCode,
                builder: (context, snapLoading) {
                  var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
                  return RideCommonDialog(
                    isLoading: isLoading,
                    dialogImg: "assets/images/dialog_promo_code_image.png",
                    title: languages.selectPromoCode,
                    spinnerList: promoCodeNameList,
                    positiveBtnTxt: languages.apply,
                    negativeBtnTxt: languages.cancel,
                    positiveBtnOnClick: (spinnerPos, textFieldValue) {
                      if (_promoCodeListController.value!.length > spinnerPos) {
                        if (rideCost != 0) {
                          applyPromoCodeApiCall(_promoCodeListController.value![spinnerPos]);
                        }
                      }
                    },
                    negativeBtnOnClick: () {
                      Navigator.pop(context, true);
                    },
                  );
                });
          });
    } else {
      openSimpleSnackbar( languages.promoCodeNotAvailable);
    }
  }

  cancelRideDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StreamBuilder<ApiResponse<BaseModel>>(
              stream: subjectCancelRide,
              builder: (context, snapLoading) {
                var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
                return RideCommonDialog(
                  isLoading: isLoading,
                  dialogImg: "assets/images/dialog_cancel_img.png",
                  title: languages.cancelRequest,
                  msg: languages.doYouWantToCancel,
                  positiveBtnTxt: languages.yes,
                  negativeBtnTxt: languages.no,
                  positiveBtnOnClick: (spinnerPos, textFieldValue) {
                    cancelRideBookingApi();
                  },
                  negativeBtnOnClick: () {
                    Navigator.pop(context, true);
                  },
                );
              });
        });
  }

  showDateAndTimePicker() {
    selectDate(context, 1, 4).then((date) {
      if (date != null) {
        selectTime(context).then((time) {
          if (time != null) {
            DateTime dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            bool isAfter = dateTime.isAfter(DateTime.now().add(const Duration(hours: 1)));
            if (isAfter) {
              scheduleDate = convertTimeToServerTime(dateTime);
              bookRidePrepare(true, scheduleDate);
            } else {
              openSimpleSnackbar( languages.invalidScheduleTime);
            }
          }
        });
      }
    });
  }

  vehicleSelect(int position, bool onTap) {
    selectedServiceType = _subjectServiceData.value.data!.serviceType[position];
    removeAppliedPromoCode(false);
    int selectedPos = _subjectServiceData.value.data!.serviceType.indexWhere((element) => element.isSelected == true);
    if (selectedPos >= 0) {
      _subjectServiceData.value.data!.serviceType[selectedPos].isSelected = false;
    }
    _subjectServiceData.value.data!.serviceType[position].isSelected = true;
    if (_distanceController.valueOrNull != null) {
      double costPerKm = getDoubleFromDynamic(selectedServiceType?.costPerKm ?? 1);
      double costPerMin = getDoubleFromDynamic(selectedServiceType?.costPerMin ?? 1);
      double baseFare = getDoubleFromDynamic(selectedServiceType?.baseFare ?? 1);

      double cost = costPerKm * _distanceController.value;
      double costTime = costPerMin * _timeController.value;
      double finalRideCost = cost.round() + baseFare + costTime;
      setRideCost(finalRideCost);

      String dimensionAndWeightLimit = "${selectedServiceType?.lengthLimit} x ${selectedServiceType?.widthLimit} x ${selectedServiceType?.heightLimit} ${languages.cm}, ${languages.upTo} ${selectedServiceType?.weightLimit} ${languages.kg}";
      dimensionAndWeightLimitSubject.add(dimensionAndWeightLimit);
      // weightLimitSubject.add("${languages.upTo} ${selectedServiceType?.weightLimit} ${languages.kg}");
    }
    _subjectServiceData.sink.add(ApiResponse.completed(_subjectServiceData.value.data));
  }

  setRideCost(double rideCost) {
    double minFareAmount = getDoubleFromDynamic(selectedServiceType?.minFareAmount ?? 0);
    this.rideCost = max(rideCost, minFareAmount);
    changeAmount(this.rideCost);
  }

  removeAppliedPromoCode(bool isSetPriceAgain) {
    changeSelectedPromoCode(null);
    if (isSetPriceAgain) {
      setRideCost(rideCost);
    }
  }

  setMarkers() async {
    _subjectServiceData.sink.add(ApiResponse.loading());
    String origin = "${locationList[0].lat},${locationList[0].lng}";
    String destination = "${locationList[(locationList.length - 1)].lat},${locationList[(locationList.length - 1)].lng}";
    List<Marker>? markerList = [];
    List<LatLng> latLngs = [];
    int locationListLength = locationList.length;

    BitmapDescriptor pickUpMarkerIcon =
        await getBitmapDescriptorFromAssetBytes('assets/images/ic_user_location.png', (deviceAverageSize * 0.15).toInt());

    BitmapDescriptor stop1MarkerIcon = await getBitmapDescriptorFromAssetBytes('assets/images/stop_1.png', (deviceAverageSize * 0.15).toInt());

    BitmapDescriptor stop2MarkerIcon = await getBitmapDescriptorFromAssetBytes('assets/images/stop_2.png', (deviceAverageSize * 0.15).toInt());

    BitmapDescriptor stop3MarkerIcon = await getBitmapDescriptorFromAssetBytes('assets/images/stop_3.png', (deviceAverageSize * 0.15).toInt());

    BitmapDescriptor destinationMarkerIcon =
        await getBitmapDescriptorFromAssetBytes('assets/images/ic_pin_destination_location.png', (deviceAverageSize * 0.15).toInt());
    for (int i = 0; i < locationListLength; i++) {
      String title = "${languages.stop} $i";
      LatLng stopLatLng = LatLng(locationList[i].lat, locationList[i].lng);
      // String name = locationList[i].name;
      BitmapDescriptor? markerIcon;

      if (i != 0 && i != (locationListLength - 1)) latLngs.add(stopLatLng);

      if (i == 0) {
        markerIcon = pickUpMarkerIcon;
        title = languages.pickup;
      }
      if (i == 1) {
        markerIcon = stop1MarkerIcon;
      }
      if (i == 2) {
        markerIcon = stop2MarkerIcon;
      }
      if (i == 3) {
        markerIcon = stop3MarkerIcon;
      }
      if (i == (locationListLength - 1)) {
        markerIcon = destinationMarkerIcon;
        title = languages.destination;
      }

      markerList.add(Marker(markerId: MarkerId(title), position: stopLatLng, icon: markerIcon!, infoWindow: InfoWindow(title: title)));
    }
    changeMarkerList(markerList);

    await mapApiCall(origin, destination, latLngs);
  }

  onMapCreated(GoogleMapController googleMapController) async {
    this.googleMapController = googleMapController;
    this.googleMapController!.setMapStyle(await rootBundle.loadString('assets/mapStyle/map_style.txt'));
    await setMarkers();
  }

  getCurrentLocation() async {
    getLocationUtils.getLocationUtils((locationData) {
      serviceDataApiCall(locationData.latitude, locationData.longitude);
    }, (locationData, address) {}, isGetAddress: false);
  }

  showRequestTimeOut(int requestTimeOut) {
    changeRequestTimeOut(false);
    _timer = Timer(Duration(seconds: requestTimeOut), () {
      changeRequestTimeOut(true);
    });
  }

  @override
  void dispose() {
    _polyLinesController.close();
    _distanceController.close();
    _amountController.close();
    _timeController.close();
    _requestTimeOutController.close();
    _markersListController.close();
    _promoCodeListController.close();
    _selectedPaymentMethodController.close();
    _selectedPromoCodeController.close();
    _subjectServiceData.close();
    _subjectApplyPromoCode.close();
    _subjectRideBook.close();
    _subjectScheduleRideBook.close();
    _subjectSurgeCharge.close();
    _subjectCancelRide.close();
    dimensionAndWeightLimitSubject.close();
    // weightLimitSubject.close();
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }
}
