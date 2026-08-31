import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../blocs/bloc.dart';
import '../../../dialogs/ride_common_dialog.dart';
import '../../../dialogs/vehicle_info_dialog.dart';
import '../../../services/push_notification_service.dart';
import '../../../utils/get_route_utils.dart';
import '../../../utils/utils.dart';
import '../../common/base_dl.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../rideDetail/ride_detail_dl.dart';
import '../rideDetail/ride_detail_repo.dart';
import 'running_ride.dart';
import 'running_ride_repo.dart';

class RunningRideBloc extends Bloc {
  String tag = "RunningRideBloc>>>";
  BuildContext context;
  int orderId, orderStatus;
  GoogleMapController? googleMapController;
  LatLng? pickUpLatLng, destinationLatLng, driverPreviousLatLng, driverCurrentLatLong;
  Marker? markerDriver;
  FirebaseDatabase? firebaseDatabase;
  DatabaseReference? _reference;
  String currentAddress = "";
  bool isOpenFromNotificationClick;
  final RideDetailRepo _rideDetailRepo = RideDetailRepo();
  final RunningRideRepo _runningRideRepo = RunningRideRepo();

  State<RunningRide> state;

  RunningRideBloc(this.context, this.orderId, this.orderStatus, this.isOpenFromNotificationClick, this.state) {
    firebaseDatabase = FirebaseDatabase.instance;
    setToolbarTitle();
    rideReceiptDetailsApi();
    manageNotification();
    getCurrentLocation(isFocus: false);
  }

  final _rotateMarkerListController = BehaviorSubject<List<Marker>>();
  final _toolbarTitleController = BehaviorSubject<String>();
  final _markersListController = BehaviorSubject<List<Marker>>();
  final _subjectRideDetail = BehaviorSubject<ApiResponse<RideDetailPojo>>();
  final _subjectRideCancel = BehaviorSubject<ApiResponse<BaseModel>>();
  final _polyLinesController = BehaviorSubject<Map<PolylineId, Polyline>>();

  BehaviorSubject<ApiResponse<RideDetailPojo>> get subjectRideDetail => _subjectRideDetail;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectRideCancel => _subjectRideCancel;

  Stream<List<Marker>> get rotateMarkers => _rotateMarkerListController.stream;

  Stream<String> get toolbarTitle => _toolbarTitleController.stream;

  Stream<List<Marker>> get markersList => _markersListController.stream;

  Stream<Map<PolylineId, Polyline>> get polyLines => _polyLinesController.stream;

  Function(List<Marker>) get changeMarkerList => _markersListController.sink.add;

  Function(List<Marker>) get changeRotateMarker => _rotateMarkerListController.sink.add;

  Function(String) get changeToolbarTitle => _toolbarTitleController.sink.add;

  Function(Map<PolylineId, Polyline>) get changePolyLines => _polyLinesController.sink.add;

  rideReceiptDetailsApi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectRideDetail.sink.add(ApiResponse.loading());
      try {
        var response = RideDetailPojo.fromJson(await _rideDetailRepo.rideReceiptDetailApi(orderId));

        if (!state.mounted) return;
        if (isApiStatus(context, response.status, response.message, true, showMess: false)) {
          _subjectRideDetail.sink.add(ApiResponse.completed(response));
          orderStatus = response.rideStatus;
          setMarkers(response);
          createFirebaseDataBase(response);
          if (isOpenFromNotificationClick) {
            openOrderStatusDialog(orderStatus);
          }
        } else {
          _subjectRideDetail.sink.add(ApiResponse.error(response.message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectRideDetail.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      Future.sync(() {
        openSimpleSnackbar( languages.internetConnLostTitle);
      });
    }
  }

  cancelRideBookingApi(String cancellationReason) async {
    FocusManager.instance.primaryFocus?.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectRideCancel.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(await _runningRideRepo.cancelRideBookingApi(orderId.toString(), cancellationReason));

        if (!state.mounted) return;
        String message = getApiMsg(context, response.messageCode, response.message);
        if (isApiStatus(context, response.status, message, true)) {
          _subjectRideCancel.sink.add(ApiResponse.completed(response));
          Navigator.pop(context, true);
          pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
          openScreenWithClearPrevious(context, const HomeMainV1());
        } else {
          _subjectRideCancel.sink.add(ApiResponse.error(message));
        }
      } catch (e) {
        logd(tag, e.toString());
        _subjectRideCancel.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      _subjectRideCancel.sink.add(ApiResponse.error(languages.internetConnLostTitle));
      Future.sync(() {
        openSimpleSnackbar( languages.internetConnLostTitle);
      });
    }
  }

  setMarkers(RideDetailPojo data) async {
    List<Marker> markerList = [];
    if (data.addressList.isNotEmpty) {
      pickUpLatLng = LatLng(getDoubleFromDynamic(data.addressList[0].addressLat), getDoubleFromDynamic(data.addressList[0].addressLong));
      destinationLatLng = LatLng(getDoubleFromDynamic(data.addressList[data.addressList.length - 1].addressLat),
          getDoubleFromDynamic(data.addressList[data.addressList.length - 1].addressLong));

      BitmapDescriptor pickUpMarkerIcon = await getBitmapDescriptorFromAssetBytes('assets/images/ic_user_location.png', (deviceAverageSize * 0.18).toInt());
      BitmapDescriptor destinationMarkerIcon =
          await getBitmapDescriptorFromAssetBytes('assets/images/ic_pin_destination_location.png', (deviceAverageSize * 0.18).toInt());
      markerList.add(Marker(
        markerId: const MarkerId("PickUpMarker"),
        position: pickUpLatLng ?? const LatLng(0, 0),
        icon: pickUpMarkerIcon,
        infoWindow: const InfoWindow(title: ""),
      ));
      markerList.add(Marker(
        markerId: const MarkerId("DestinationMarker"),
        position: destinationLatLng ?? const LatLng(0, 0),
        icon: destinationMarkerIcon,
        infoWindow: const InfoWindow(title: ""),
      ));
      changeMarkerList(markerList);
      mapApiCall();

      //Animate Map
      // LatLng southwestLatLng, northeastLatLng;
      // if (pickUpLatLng.latitude <= destinationLatLng.latitude) {
      //   southwestLatLng = pickUpLatLng;
      //   northeastLatLng = destinationLatLng;
      // } else {
      //   southwestLatLng = destinationLatLng;
      //   northeastLatLng = pickUpLatLng;
      // }
      // LatLngBounds bound = LatLngBounds(southwest: southwestLatLng, northeast: northeastLatLng);
      // LatLng centerBounds =
      //     LatLng((bound.northeast.latitude + bound.southwest.latitude) / 2, (bound.northeast.longitude + bound.southwest.longitude) / 2);
      // await zoomToFit(googleMapController, bound, centerBounds);
    }
  }

  mapApiCall() async {
    String startLocation = "${pickUpLatLng?.latitude.toString()},${pickUpLatLng?.longitude}";
    String endLocation = "${destinationLatLng?.latitude},${destinationLatLng?.longitude}";
    await GetRoutesUtils().getRoutes(startLocation, endLocation, [], (polyLines, duration, distance) async {
      changePolyLines(polyLines);
      if (!state.mounted) return;
      setMapFitToTour(Set<Polyline>.of(polyLines.values), googleMapController);
    });
  }

  createFirebaseDataBase(RideDetailPojo data) {
    _reference = firebaseDatabase!.ref().child(ChatConstant.chat).child(ChatConstant.courier).child(data.bookingNo ?? "");
    _reference?.onValue.listen((event) async {
      var snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<String, dynamic> result = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        driverCurrentLatLong = LatLng(double.parse(result[ChatConstant.latitude].toString()), double.parse(result[ChatConstant.longitude].toString()));
        if (markerDriver == null) {
          List<Marker> markerList = _rotateMarkerListController.valueOrNull ?? [];

          BitmapDescriptor driverMarkerIcon =  await getBitmapDescriptorFromAssetBytes('assets/images/ic_delivery_bike.png', (deviceAverageSize * 0.15).toInt());
          markerDriver = Marker(
              markerId: const MarkerId("DriverMarker"),
              position: driverCurrentLatLong!,
              icon: driverMarkerIcon,
              infoWindow: InfoWindow(title: data.driverName));
          markerList.add(markerDriver!);
          changeRotateMarker(markerList);
        }
        if (driverPreviousLatLng != null) {
          updateDriverMarker();
        }
        driverPreviousLatLng = driverCurrentLatLong;
      }
    });
  }

  updateDriverMarker() {
    List<Marker> markers = _rotateMarkerListController.value;
    int pos = markers.indexWhere((item) => item.markerId == const MarkerId("DriverMarker"));
    if (pos >= 0) {
      Marker driverMarker = markers[pos];
      Marker driverNewMarker = Marker(markerId: driverMarker.markerId, position: driverCurrentLatLong!, icon: driverMarker.icon, infoWindow: driverMarker.infoWindow);
      markers[pos] = driverNewMarker;
      changeRotateMarker(markers);
    }
  }

  getNearestDriverMarkerBitmap() async {

    return await getBitmapDescriptorFromAssetBytes('assets/images/ic_truck.png', (deviceAverageSize * 0.2).toInt());
  }

  openCancelRideDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StreamBuilder<ApiResponse<BaseModel>>(
            stream: subjectRideCancel,
            builder: (context, snapLoading) {
              var isLoading = snapLoading.hasData && snapLoading.data?.status == Status.loading;
              return RideCommonDialog(
                isLoading: isLoading,
                dialogImg: "assets/images/dialog_cancel_img.png",
                title: languages.cancelBooking,
                msg: languages.enterReason,
                positiveBtnTxt: languages.submit,
                negativeBtnTxt: languages.cancel,
                textFieldHint: languages.reason,
                textFieldEmptyErrorMsg: languages.enterCancelReason,
                positiveBtnOnClick: (spinnerPos, textFieldValue) {
                  cancelRideBookingApi(textFieldValue);
                },
                negativeBtnOnClick: () {
                  Navigator.pop(context, true);
                },
              );
            },
          );
        });
  }

  openVehicleInfoDialog(RideDetailPojo data) {
    List<KeyValueModel> vehicleList = [];
    setKeyValuePair(vehicleList, false, false, languages.vehicleColor, data.vehicleColor);
    setKeyValuePair(vehicleList, false, false, languages.vehicleManufactureName, data.vehicleManufactureName);
    setKeyValuePair(vehicleList, false, false, languages.vehicleModelName, data.vehicleModelName);
    setKeyValuePair(vehicleList, false, false, languages.vehicleModelYear, data.vehicleModelYear.toString(), setValueWithCurrency: false);
    setKeyValuePair(vehicleList, false, false, languages.vehiclePlatNo, data.vehiclePlatNo);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return VehicleInfoDialog(
          vehicleList: vehicleList,
        );
      },
    );
  }

  shareRide(RideDetailPojo? data) {
    if (currentAddress.trim().isNotEmpty) {
      String pickupLatLong = '${data?.addressList.first.addressLat},${data?.addressList.first.addressLong}';
      String dropLatLong = '${data?.addressList.last.addressLat},${data?.addressList.last.addressLong}';
      // String text = "https://maps.google.com?q=${currentAddress.trim()}";
      String text =
          "${languages.followMeAt(languages.appName)}\nhttps://www.google.com/maps/dir/?api=1&origin=$pickupLatLong&destination=$dropLatLong&travelmode=driving&dir_action=navigate";
      final box = context.findRenderObject() as RenderBox?;
      Share.share(text, subject: languages.appName, sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
    }
  }

  navigateTo() async {
    if (_subjectRideDetail.value.data != null) {
      String latLong = _subjectRideDetail.value.data!.rideStatus < 5
          ? '${subjectRideDetail.value.data?.addressList.first.addressLat},${subjectRideDetail.value.data?.addressList.first.addressLong}'
          : '${subjectRideDetail.value.data?.addressList.last.addressLat},${subjectRideDetail.value.data?.addressList.last.addressLong}';
      var uri = Uri.parse("google.navigation:q=$latLong&mode=d");
      String url = "https://www.google.com/maps/dir/?api=1&destination=$latLong&travelmode=driving&dir_action=navigate";
      try {
        await launchUrl(uri);
      } catch (e) {
        logd("launchUrl>>>", e.toString());
        openUrl(url);
      }
    }
  }

  setToolbarTitle() {
    if (orderStatus < 3) {
      changeToolbarTitle(languages.arriving);
    } else if (orderStatus == 3) {
      changeToolbarTitle(languages.enRoute);
    } else {
      changeToolbarTitle(languages.running);
    }
  }

  openOrderStatusDialog(int orderStatus, {int msgCode = 0, String msg = ""}) {
    String dialogImg = "assets/images/dialog_driver_arrived_img.png";
    String title = "";
    String message = "";

    switch (orderStatus) {
      case 3:
        dialogImg = getArrivedImage();
        title = getArrivedTitleMsg(isTitle: true);
        message = getArrivedTitleMsg(isTitle: false);
        break;
      case 4:
        dialogImg = "assets/images/dialog_cancel_img.png";
        title = getCancelTitleMsg(isTitle: true);
        message = getCancelTitleMsg(isTitle: false);
        break;
      case 5:
        if (msgCode == 272) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else if (msgCode == 273) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else if (msgCode == 274) {
          dialogImg = getRideStartedImg();
          title = getApiMsg(context, msgCode, msg);
          message = "";
        } else {
          dialogImg = getRideStartedImg();
          title = getRideStartedTitleMsg(isTitle: true);
          message = getRideStartedTitleMsg(isTitle: false);
        }
        break;
      case 6:
        dialogImg = getRideFinish();
        title = getRideFinishTitleMsg(isTitle: true);
        message = getRideFinishTitleMsg(isTitle: false);
        break;
      case 7:
        dialogImg = getRideFinish();
        title = getRideFinishTitleMsg(isTitle: true);
        message = getRideFinishTitleMsg(isTitle: false);
        // openScreenWithClearPrevious(context, RideInvoice(rideId: orderId, : ));
        Navigator.pop(context, true);
        break;
      case 9:
        dialogImg = getRideSuccessFinish();
        title = getRideSuccessTitleMsg(isTitle: true);
        message = getRideSuccessTitleMsg(isTitle: false);
        break;
    }
    if (orderStatus >= 3) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RideCommonDialog(
            isLoading: false,
            dialogImg: dialogImg,
            title: title,
            msg: message,
            positiveBtnTxt: languages.done,
            positiveBtnOnClick: (spinnerPos, textFieldValue) {
              Navigator.pop(context, true);
              pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
              if (orderStatus == 4) {
                openScreenWithClearPrevious(this.context, const HomeMainV1());
              } else if (orderStatus == 6) {
                Navigator.pop(context, true);
                // openScreenWithClearPrevious(this.context, RideInvoice(rideId: orderId, : ));
              } else if (orderStatus == 9) {
                openScreenWithClearPrevious(this.context, const HomeMainV1());
              }
            },
            negativeBtnOnClick: () {},
          );
        },
      );
    }
  }

  manageNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (!state.mounted) return;

      Map<String, dynamic> notificationData = message.data;
      int notificationType = int.parse((notificationData[NotificationConstant.notificationType] ?? 0).toString());
      int msgCode = int.parse((notificationData[NotificationConstant.messageCode] ?? 0).toString());
      String msg = (notificationData[NotificationConstant.message]).toString();
      int orderStatus = int.parse((notificationData[NotificationConstant.orderStatus] ?? 0).toString());
      int orderId = int.parse((notificationData[NotificationConstant.orderId] ?? 0).toString());
      int serviceCategoryId = int.parse((notificationData[NotificationConstant.serviceCategoryId] ?? 0).toString());
      int bookingType = int.parse((notificationData[NotificationConstant.bookingType] ?? 0).toString());

      if (notificationType == 1) {
        if (serviceCategoryId == 4) {
          if (bookingType == 0) {
            if (orderStatus > 1 && orderStatus <= 9) {
              this.orderStatus = orderStatus;
              this.orderId = orderId;
              RideDetailPojo? data = _subjectRideDetail.value.data;
              data?.rideStatus = (orderStatus);
              _subjectRideDetail.sink.add(ApiResponse.completed(data));
              openOrderStatusDialog(orderStatus, msgCode: msgCode, msg: msg);
              setToolbarTitle();
            }
          } else {
            if (orderStatus > 2 && orderStatus < 9) {
              this.orderStatus = orderStatus;
              this.orderId = orderId;
              RideDetailPojo? data = _subjectRideDetail.value.data;
              data?.rideStatus = (orderStatus);
              _subjectRideDetail.sink.add(ApiResponse.completed(data));

              openOrderStatusDialog(orderStatus, msgCode: msgCode, msg: msg);
              setToolbarTitle();
            }
          }
        }
      }
    });
  }

  onMapCreated(GoogleMapController googleMapController) async {
    this.googleMapController = googleMapController;
    this.googleMapController?.setMapStyle(await rootBundle.loadString('assets/mapStyle/map_style.txt'));
  }

  getCurrentLocation({bool isFocus = false, bool forcefullyGetLocation = false}) async {
    getLocationUtils.getLocationUtils((locationData) {
      if (!state.mounted) return;
      if (isFocus) {
        focusInMap(googleMapController, locationData.latitude ?? 0, locationData.longitude ?? 0, true);
      }
    }, (locationData, address) {
      currentAddress = address;
    }, getForceFully: forcefullyGetLocation);
  }

  @override
  void dispose() {
    _toolbarTitleController.close();
    _rotateMarkerListController.close();
    _markersListController.close();
    _subjectRideDetail.close();
    _subjectRideCancel.close();
    _polyLinesController.close();
  }
}
