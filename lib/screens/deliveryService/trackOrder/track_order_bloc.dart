import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../blocs/bloc.dart';
import '../../../constant/constant.dart';
import '../../../utils/shared_pref_utill.dart';
import '../../../utils/utils.dart';
import '../../../utils/get_route_utils.dart';
import '../storeDetail/store_detail_repo.dart';
import '../../common/base_dl.dart';
import '../../common/homeMainV1/home_main_v1.dart';
import '../../common/orderCart/order_cart_repo.dart';
import 'track_order_dl.dart';
import 'track_order_repo.dart';

class TrackOrderBloc extends Bloc {
  String tag = "TrackOrderBloc>>>";
  BuildContext context;
  final TrackOrderRepo _trackOrderRepo = TrackOrderRepo();
  final StoreDetailRepo _storeDetailRepo = StoreDetailRepo();
  bool _storeContactHydrateInFlight = false;
  int orderId;
  GoogleMapController? googleMapController;
  CameraUpdate? cameraUpdate;
  LatLngBounds? bound;
  LatLng? centerBounds, driverPreviousLatLng, driverCurrentLatLong;
  FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
  DatabaseReference? _reference;
  StreamSubscription<DatabaseEvent>? _driverLocationSubscription;
  Marker? markerDriver;
  bool? isFromPlacedOrder;
  bool _isTrackOrderApiInFlight = false;
  bool _isCartCleanupInFlight = false;
  Timer? _otpFollowUpTimer;
  bool _hasInitializedRoute = false;
  String _lastPickupLatLong = '';
  String _lastDestinationLatLong = '';

  /// Previous API order status — used to refresh map when crossing into >= 8 (driver picked up).
  int? _previousOrderCurrentStatus;

  /// Avoid map / Firebase callbacks after [dispose].
  bool _disposed = false;

  State<StatefulWidget> state;

  TrackOrderBloc(
    this.context,
    this.orderId,
    this.isFromPlacedOrder,
    this.state,
  );

  final _subject = BehaviorSubject<ApiResponse<TrackOrderPojo>>();
  final _subjectCancelOrder = BehaviorSubject<ApiResponse<BaseModel>>();
  final _orderNoController = BehaviorSubject<String>.seeded(
    "order########".toUpperCase(),
  );
  final _orderDetailsController = BehaviorSubject<String>.seeded(
    "TIME#########".toUpperCase(),
  );

  final _estimateTimeController = BehaviorSubject<Duration>();
  final _orderStatusController = BehaviorSubject<int>();
  final _userTakenTypeController = BehaviorSubject<int>();

  final _titleController = BehaviorSubject<String>.seeded("");
  final _msgController = BehaviorSubject<String>.seeded("");
  final _imgController = BehaviorSubject<String>.seeded("");
  final _nameController = BehaviorSubject<String>.seeded("");
  final _ratingController = BehaviorSubject<String>.seeded("");
  final _titleColorController = BehaviorSubject<Color>.seeded(colorPrimary);
  final _markersListController = BehaviorSubject<List<Marker>>();
  final _polylinesListController = BehaviorSubject<Map<PolylineId, Polyline>>();
  final _rotateMarkerListController = BehaviorSubject<List<Marker>>();
  final subjectDriverImage = BehaviorSubject<bool>();

  Stream<String> get orderNo => _orderNoController.stream;

  Stream<String> get orderDetail => _orderDetailsController.stream;

  Stream<Duration> get estimateTime => _estimateTimeController.stream;

  Stream<int> get orderStatus => _orderStatusController.stream;

  Stream<int> get userTakenType => _userTakenTypeController.stream;

  Stream<String> get title => _titleController.stream;

  Stream<String> get msg => _msgController.stream;

  Stream<String> get img => _imgController.stream;

  Stream<String> get name => _nameController.stream;

  Stream<String> get rating => _ratingController.stream;

  Stream<Color> get titleColor => _titleColorController.stream;

  Stream<List<Marker>> get markersList => _markersListController.stream;

  Stream<Map<PolylineId, Polyline>> get polylinesList =>
      _polylinesListController.stream;

  Stream<List<Marker>> get rotateMarkers => _rotateMarkerListController.stream;

  BehaviorSubject<ApiResponse<TrackOrderPojo>> get subject => _subject;

  BehaviorSubject<ApiResponse<BaseModel>> get subjectCancelOrder =>
      _subjectCancelOrder;

  Function(String) get changeOrderNo => _orderNoController.sink.add;

  Function(String) get changeOrderDetail => _orderDetailsController.sink.add;

  Function(Duration) get changeEstimateTime => _estimateTimeController.sink.add;

  Function(int) get changeOrderStatus => _orderStatusController.sink.add;

  Function(String) get changeTitle => _titleController.sink.add;

  Function(String) get changeMsg => _msgController.sink.add;

  Function(String) get changeImg => _imgController.sink.add;

  Function(String) get changeName => _nameController.sink.add;

  Function(String) get changeRating => _ratingController.sink.add;

  Function(Color) get changeTitleColor => _titleColorController.sink.add;

  Function(List<Marker>) get changeMarkerList =>
      _markersListController.sink.add;

  Function(Map<PolylineId, Polyline>) get changePolyLineList =>
      _polylinesListController.sink.add;

  Function(List<Marker>) get changeRotateMarker =>
      _rotateMarkerListController.sink.add;

  callTrackOrderApi(bool isLoading) async {
    if (_isTrackOrderApiInFlight || _disposed) return;
    _isTrackOrderApiInFlight = true;
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        if (isLoading) {
          _subject.sink.add(ApiResponse.loading());
        }
        try {
          final dynamic trackOrderRaw =
              await _trackOrderRepo.callTrackOrderApi(orderId);
          var response = TrackOrderPojo.fromJson(trackOrderRaw);
          _applyTrackOrderContactFromPayload(response, trackOrderRaw);
          await _hydrateStoreContactIfNeeded(response);

          if (!state.mounted) return;
          String message = getApiMsg(
            context,
            response.messageCode,
            response.message,
          );
          if (isApiStatus(
            context,
            response.status,
            message,
            true,
            showMess: false,
          )) {
            if (_shouldRefreshMap(response)) {
              await addMarker(response);
            }
            setTrackOrderData(response);
            _enqueueTrackOrderChatFcmTokensToRtdb(response);
            _subject.sink.add(ApiResponse.completed(response));
          } else {
            _subject.sink.add(ApiResponse.error(message));
          }
        } catch (e) {
          logd(tag, e.toString());
          if (!state.mounted) return;
          openSimpleSnackbar(e.toString());
          _subject.sink.add(ApiResponse.error(e.toString()));
        }
      } else {
        _subject.sink.add(ApiResponse.error(languages.internetConnLostTitle));
        if (!state.mounted) return;
        openSimpleSnackbar(languages.internetConnLostTitle);
      }
    } finally {
      _isTrackOrderApiInFlight = false;
    }
  }

  /// Laravel track-order returns driver/store/customer FCM tokens. Chat sends
  /// read peers from RTDB `hareshop-no/fcmToken/...` — mirror API tokens so all
  /// parties can notify each other without relying only on each app writing RTDB.
  void _enqueueTrackOrderChatFcmTokensToRtdb(TrackOrderPojo data) {
    Future<void> run() async {
      if (_disposed) return;
      if (data.driverId > 0 && data.driverFcmToken.trim().isNotEmpty) {
        await syncChatPeerFcmTokenToRtdb(
          ChatConstant.providerIdCode + data.driverId.toString(),
          data.driverFcmToken,
        );
      }
      if (data.storeId > 0 && data.storeFcmToken.trim().isNotEmpty) {
        await syncChatPeerFcmTokenToRtdb(
          ChatConstant.providerIdCode + data.storeId.toString(),
          data.storeFcmToken,
        );
      }
      final int uid = prefGetInt(prefUserId);
      if (uid > 0 && data.customerFcmToken.trim().isNotEmpty) {
        await syncChatPeerFcmTokenToRtdb(
          ChatConstant.userIdCode + uid.toString(),
          data.customerFcmToken,
        );
      }
    }

    run().catchError((Object e, _) {
      logd(tag, "_enqueueTrackOrderChatFcmTokensToRtdb: $e");
    });
  }

  bool _shouldRefreshMap(TrackOrderPojo data) {
    final String pickupCoords = data.pickupLatLong.trim();
    final String destinationCoords = data.destinationLatLong.trim();
    final int status = data.orderCurrentStatus;
    final bool homeDelivery = data.userTakenType != pickup;
    final int prevStatus = _previousOrderCurrentStatus ?? -1;
    _previousOrderCurrentStatus = status;

    if (!_hasInitializedRoute) {
      _hasInitializedRoute = true;
      _lastPickupLatLong = pickupCoords;
      _lastDestinationLatLong = destinationCoords;
      return true;
    }
    if (_lastPickupLatLong != pickupCoords ||
        _lastDestinationLatLong != destinationCoords) {
      _lastPickupLatLong = pickupCoords;
      _lastDestinationLatLong = destinationCoords;
      return true;
    }
    // Backend sets customer order status to 8 when driver confirms pickup (driver ride_status / order_delivery_status 5).
    // Refresh map so we attach the Firebase listener only after that transition (not before).
    if (homeDelivery && prevStatus < 8 && status >= 8) {
      return true;
    }
    return false;
  }

  /// While the order is out for delivery, OTP may appear on the server shortly
  /// after status moves to 7/8. Poll faster than the main 10s timer so the UI
  /// updates without leaving the screen.
  void _updateOtpFollowUpPolling(TrackOrderPojo data) {
    _otpFollowUpTimer?.cancel();
    _otpFollowUpTimer = null;
    if (_disposed) return;
    if (data.userTakenType == 2) return;
    if (data.orderCurrentStatus != 7 && data.orderCurrentStatus != 8) return;
    if (data.otp.trim().isNotEmpty) return;

    _otpFollowUpTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || !state.mounted) return;
      callTrackOrderApi(false);
    });
  }

  cancelOrderApi(String reason) async {
    FocusManager.instance.primaryFocus?.unfocus();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      _subjectCancelOrder.sink.add(ApiResponse.loading());
      try {
        var response = BaseModel.fromJson(
          await _trackOrderRepo.callOrderCancelsApi(reason, orderId),
        );

        if (!state.mounted) return;
        String message = getApiMsg(
          context,
          response.messageCode,
          response.message,
        );
        _subjectCancelOrder.sink.add(ApiResponse.completed(response));
        if (isApiStatus(context, response.status, message, true)) {
          /*Navigator.pop(context, true);
          if (isFromPlacedOrder || !Navigator.canPop(context)) {
            openScreenWithClearPrevious(context, DSHome());
          } else {
            Navigator.pop(context, true);
          }*/
          openScreenWithClearPrevious(context, const HomeMainV1());
          pushNotificationService.flutterLocalNotificationsPlugin.cancelAll();
        } else {
          if (response.status != 3) openSimpleSnackbar(message);
        }
      } catch (e) {
        if (!state.mounted) return;
        openSimpleSnackbar(e.toString());
        _subjectCancelOrder.sink.add(ApiResponse.error(e.toString()));
      }
    } else {
      if (!state.mounted) return;
      openSimpleSnackbar(languages.internetConnLostTitle);
    }
  }

  String formatDurationToString(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  getEstimateTime(String scheduleOrderDateTime) {
    DateTime orderTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).parse(scheduleOrderDateTime);
    Duration differnce = orderTime.difference(DateTime.now());
    if (differnce.inSeconds < 0) differnce = Duration.zero;
    return differnce;
  }

  setTrackOrderData(TrackOrderPojo data) {
    String orderNo = "${languages.order} #${data.orderNo}";
    changeOrderNo(orderNo.toUpperCase());
    String orderDetails = data.scheduleOrderDateTime;
    changeOrderDetail(orderDetails.toUpperCase());

    // Duration estimateTime = getEstimateTime(data.scheduleOrderDateTime);
    // changeEstimateTime(estimateTime);
    changeOrderStatus(data.orderCurrentStatus);
    _userTakenTypeController.sink.add(data.userTakenType);

    // switch (data.orderStatusList.length) {
    //   case 1:
    //   case 2:
    //   case 3:
    //   case 5:
    //     setStoreDetails(data);
    //     break;
    //   case 4:
    //     if (data.userTakenType == 2) {
    //       setStoreDetails(data);
    //     } else {
    //       setDriverDetails(data);
    //     }
    //     break;
    // }

    setTitleAndMessage(data);

    _updateOtpFollowUpPolling(data);

    _clearCompletedOrderCartIfNeeded(data.orderCurrentStatus);

    if (data.orderCurrentStatus == 3 ||
        data.orderCurrentStatus == 4 ||
        data.orderCurrentStatus == 9 ||
        data.orderCurrentStatus == 10) {
      finishChatWithStore(data);
      finishChatWithDriver(data);
    }
  }

  Future<void> _clearCompletedOrderCartIfNeeded(int orderCurrentStatus) async {
    if (orderCurrentStatus != 9 || _isCartCleanupInFlight || _disposed) return;

    _isCartCleanupInFlight = true;
    try {
      final response = await OrderCartRepo().callOrderCartApi();
      if (response is Map && response['status'] == 1) {
        final dynamic rawOrderList = response['order_list'];
        final List orderList = rawOrderList is List ? rawOrderList : [];

        for (final dynamic cartItem in orderList) {
          if (_disposed) break;
          final dynamic cartId = cartItem is Map<String, dynamic>
              ? cartItem['id']
              : null;
          if (cartId != null) {
            await OrderCartRepo().deleteOrderCartApi(cartId);
          }
        }
      }

      prefSetInt(prefCartCount, 0);
      prefSetString(prefSelectedStoreFullResponse, '');

      if (!state.mounted) return;
      HomeMainV1State? homeState = context
          .findAncestorStateOfType<HomeMainV1State>();
      if (homeState != null) {
        homeState.badgeCountNotifier.value = 0;
      }
    } catch (e) {
      logd(tag, 'cart cleanup after completion failed: $e');
    } finally {
      _isCartCleanupInFlight = false;
    }
  }

  setTitleAndMessage(TrackOrderPojo data) {
    // 1 => request pending,
    // 2 => approved by store,
    // 3 => rejected,
    // 4 => cancelled,
    // 5 => processing,
    // 6 => approved-by-driver,
    // 7 => arrived-driver,
    // 8 => ongoing,
    // 9 => completed,
    // 10 => failed
    changeTitleColor(colorPrimary);

    String title = "";
    String message = "";
    setStoreDetails(data);
    switch (data.orderCurrentStatus) {
      case 1:
        title = languages.orderPlaced;
        message = languages.orderPlacedMsgTo;
        break;
      case 2:
        title = languages.acceptedByStore;
        message =
            "${languages.store} ${data.storeName} ${languages.confirmYourOrder}";
        break;
      case 3:
        changeTitleColor(colorRed);
        title = data.orderCancelRejectTitle;
        message = data.cancelReason;
        break;
      case 4:
        changeTitleColor(colorRed);
        title = data.orderCancelRejectTitle;
        message = data.cancelReason;
        break;
      case 5:
        title = languages.processing;
        message = languages.orderProcessingMsg;

        // setYellowLayout(languages.processing);
        break;
      case 6:
        title = languages.acceptedByDeliveryMan;
        message = "${languages.yourOrderAcceptedBy} ${data.deliveryPeopleName}";
        break;
      case 7:
        title = languages.arriving;
        message = "${data.deliveryPeopleName} ${languages.arriving}";
        break;
      case 8:
        title = languages.orderPickUp;
        message = "${languages.orderPickUpBy} ${data.deliveryPeopleName}";
        if (data.userTakenType == 2) {
          title = languages.orderReadyForPickup;
          message = languages.orderReadyForPickupMsg;
        } else {
          setDriverDetails(data);
        }
        // setYellowLayout(languages.onGoing);
        break;
      case 9:
        title = languages.delivered;
        message = languages.deliveredMsg;
        if (data.userTakenType == 2) {
          title = languages.orderPickedUp;
          message = "";
        }
        // setGreenLayout(languages.completed);
        break;
    }
    logd(tag, "title $title message $message");
    changeTitle(title);
    changeMsg(message);
  }

  void _applyTrackOrderContactFromPayload(
    TrackOrderPojo data,
    dynamic raw,
  ) {
    if (raw is! Map) return;
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);

    final String storeNumber =
        (map['store_contact_number'] ?? '').toString().trim();
    if (storeNumber.isNotEmpty) {
      data.storeContactNumber = storeNumber;
    }

    final String driverNumber =
        (map['driver_contact_number'] ?? '').toString().trim();
    if (driverNumber.isNotEmpty) {
      data.driverContactNumber = driverNumber;
    }

    final String statusAwareNumber =
        (map['contact_number'] ?? '').toString().trim();
    if (statusAwareNumber.isNotEmpty) {
      data.contactNumber = statusAwareNumber;
    }
  }

  String? _storeContactFromSelectedStorePref() {
    final String pref = prefGetString(prefSelectedStoreFullResponse).trim();
    if (pref.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(pref);
      if (decoded is! Map) return null;
      final String phone =
          (decoded['store_contact_number'] ?? '').toString().trim();
      return phone.isNotEmpty ? phone : null;
    } catch (_) {
      return null;
    }
  }

  int _storeDetailsIdForContactLookup(TrackOrderPojo data) {
    if (data.storeDetailsId > 0) return data.storeDetailsId;
    final String pref = prefGetString(prefSelectedStoreFullResponse).trim();
    if (pref.isEmpty) return 0;
    try {
      final dynamic decoded = jsonDecode(pref);
      if (decoded is! Map) return 0;
      return (decoded['store_id'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool _trackOrderStoreCallNumberEmpty(TrackOrderPojo data) {
    return data.storeContactNumber.trim().isEmpty &&
        data.contactNumber.trim().isEmpty;
  }

  Future<void> _hydrateStoreContactIfNeeded(TrackOrderPojo data) async {
    if (!_trackOrderStoreCallNumberEmpty(data)) return;
    if (_storeContactHydrateInFlight || _disposed) return;

    final String? cachedContact = _storeContactFromSelectedStorePref();
    if (cachedContact != null) {
      data.storeContactNumber = cachedContact;
      data.contactNumber = cachedContact;
      return;
    }

    final int storeDetailsId = _storeDetailsIdForContactLookup(data);
    if (storeDetailsId <= 0) return;

    _storeContactHydrateInFlight = true;
    try {
      final LatLng latLng = prefGetLatLngForStoreSearch();
      final dynamic rawDetails = await _storeDetailRepo.callStoreDetailsApi(
        storeDetailsId,
        0,
        latLng.latitude,
        latLng.longitude,
      );
      if (rawDetails is! Map || rawDetails['status'] != 1) return;

      final String phone =
          (rawDetails['store_contact_number'] ?? '').toString().trim();
      if (phone.isEmpty) return;

      data.storeContactNumber = phone;
      data.contactNumber = phone;
    } catch (e) {
      logd(tag, 'store contact hydrate failed: $e');
    } finally {
      _storeContactHydrateInFlight = false;
    }
  }

  setStoreDetails(TrackOrderPojo data) {
    changeName(data.storeName);
    changeRating(data.storeRatting.toString());
    changeImg(data.storeBanner);
    final String callNumber = data.storeContactNumber.trim().isNotEmpty
        ? data.storeContactNumber
        : data.contactNumber;
    prefSetString("order_contact_number", callNumber);
    subjectDriverImage.add(false);
  }

  setDriverDetails(TrackOrderPojo data) {
    changeName(data.deliveryPeopleName);
    // changeRating(data.driverRating.toString());
    // changeImg(data.driverImage);
    prefSetString(
      "order_contact_number",
      data.driverContactNumber.trim().isNotEmpty
          ? data.driverContactNumber
          : data.contactNumber,
    );
    subjectDriverImage.add(true);
  }

  isOrderCancelled(TrackOrderPojo data) {
    int orderCurrentStatus = data.orderCurrentStatus;
    if (orderCurrentStatus == 3 || orderCurrentStatus == 4) {
      // changeTitleColor(colorRed);
      // changeTitle(data.orderCancelRejectTitle);
      // changeMsg("");
      return true;
    }
    // changeTitleColor(colorPrimary);
    return false;
  }

  addMarker(TrackOrderPojo data) async {
    String pickupLatLong = data.pickupLatLong;
    String destinationLatLong = data.destinationLatLong;
    await GetRoutesUtils().getRoutes(pickupLatLong, destinationLatLong, [], (
      polyLines,
      duration,
      distance,
    ) async {
      if (!_disposed) changePolyLineList(polyLines);
    });
    if (_disposed || !state.mounted) return;
    BitmapDescriptor pickUpMarkerIcon = await getBitmapDescriptorFromAssetBytes(
      'assets/images/location.png',
      (deviceAverageSize * 0.1).toInt(),
    );
    BitmapDescriptor destinationMarkerIcon =
        await getBitmapDescriptorFromAssetBytes(
          'assets/images/location.png',
          (deviceAverageSize * 0.1).toInt(),
        );
    if (_disposed || !state.mounted) return;

    if ((data.userTakenType) == pickup && pickupLatLong.trim().isNotEmpty) {
      List<Marker> markerList = [];
      List<String> arPickUpLatLong = pickupLatLong.split(',');
      LatLng pickUpLatLong = LatLng(
        double.parse(arPickUpLatLong[0]),
        double.parse(arPickUpLatLong[1]),
      );
      markerList.add(
        Marker(
          markerId: const MarkerId("PickUpMarker"),
          position: pickUpLatLong,
          icon: pickUpMarkerIcon,
          infoWindow: InfoWindow(title: data.pickupAddress),
        ),
      );
      changeMarkerList(markerList);
      focusInMap(
        googleMapController,
        pickUpLatLong.latitude,
        pickUpLatLong.longitude,
        true,
      );
    } else if (pickupLatLong.trim().isNotEmpty &&
        destinationLatLong.trim().isNotEmpty) {
      List<Marker> markerList = [];
      List<String> arPickUpLatLong = pickupLatLong.split(',');
      List<String> arDestinationLatLong = destinationLatLong.split(',');
      LatLng pickUpLatLong = LatLng(
        double.parse(arPickUpLatLong[0]),
        double.parse(arPickUpLatLong[1]),
      );
      LatLng destinationLatLng = LatLng(
        double.parse(arDestinationLatLong[0]),
        double.parse(arDestinationLatLong[1]),
      );
      markerList.add(
        Marker(
          markerId: const MarkerId("PickUpMarker"),
          position: pickUpLatLong,
          icon: pickUpMarkerIcon,
          infoWindow: InfoWindow(title: data.pickupAddress),
        ),
      );
      markerList.add(
        Marker(
          markerId: const MarkerId("DestinationMarker"),
          position: destinationLatLng,
          icon: destinationMarkerIcon,
          infoWindow: InfoWindow(title: data.destinationAddress),
        ),
      );
      changeMarkerList(markerList);
      //Animate Map
      LatLng southwestLatLng, northeastLatLng;
      if (pickUpLatLong.latitude <= destinationLatLng.latitude) {
        southwestLatLng = pickUpLatLong;
        northeastLatLng = destinationLatLng;
      } else {
        southwestLatLng = destinationLatLng;
        northeastLatLng = pickUpLatLong;
      }
      bound = LatLngBounds(
        southwest: southwestLatLng,
        northeast: northeastLatLng,
      );
      centerBounds = LatLng(
        (bound!.northeast.latitude + bound!.southwest.latitude) / 2,
        (bound!.northeast.longitude + bound!.southwest.longitude) / 2,
      );
      cameraUpdate = CameraUpdate.newCameraPosition(
        CameraPosition(target: centerBounds!, zoom: 15),
      );
      if (googleMapController != null) {
        await animateMap();
      }
      // Live driver marker only after store pickup (API status >= 8). Matches driver ride_status 5 + no RTDB writes before then.
      final bool showLiveDriver =
          data.userTakenType != pickup && data.orderCurrentStatus >= 8;
      if (showLiveDriver) {
        createFireBaseDatabase(data);
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<BitmapDescriptor> getBitmapDescriptorFromAssetBytes(
    String path,
    int width,
  ) async {
    final Uint8List imageData = await getBytesFromAsset(path, width);
    return BitmapDescriptor.fromBytes(imageData);
  }

  onMapCreated(
    GoogleMapController googleMapController, [
    Brightness brightness = Brightness.light,
  ]) async {
    if (_disposed) return;
    this.googleMapController = googleMapController;
    // Platform view may not be ready on first frame; swallow pigeon channel errors.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (_disposed) return;
    await setMapStyleForBrightness(brightness);
    if (_disposed) return;
    await animateMap();
  }

  Future<void> configureExternalMap(
    GoogleMapController controller, [
    Brightness brightness = Brightness.light,
  ]) async {
    if (_disposed) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (_disposed) return;
    await _setMapStyle(controller, brightness);
    if (_disposed ||
        cameraUpdate == null ||
        bound == null ||
        centerBounds == null) {
      return;
    }
    try {
      await controller.moveCamera(cameraUpdate!);
      await zoomToFit(controller, bound!, centerBounds!);
    } on PlatformException catch (e, st) {
      debugPrint('$tag configureExternalMap: $e\n$st');
    }
  }

  /// Call when app theme changes so the map matches light/dark mode.
  Future<void> setMapStyleForBrightness(Brightness brightness) async {
    if (_disposed || googleMapController == null) return;
    await _setMapStyle(googleMapController!, brightness);
  }

  Future<void> _setMapStyle(
    GoogleMapController controller,
    Brightness brightness,
  ) async {
    final String path = brightness == Brightness.dark
        ? 'assets/mapStyle/map_style_dark.txt'
        : 'assets/mapStyle/map_style.txt';
    try {
      final style = await rootBundle.loadString(path);
      await controller.setMapStyle(style);
    } on PlatformException catch (e, st) {
      debugPrint('$tag setMapStyle: $e\n$st');
      try {
        await controller.setMapStyle(
          await rootBundle.loadString('assets/mapStyle/map_style.txt'),
        );
      } on PlatformException catch (e2, st2) {
        debugPrint('$tag setMapStyle fallback: $e2\n$st2');
      }
    } catch (e, st) {
      debugPrint('$tag setMapStyle: $e\n$st');
    }
  }

  Future<void> animateMap() async {
    if (_disposed ||
        cameraUpdate == null ||
        bound == null ||
        centerBounds == null) {
      return;
    }
    final c = googleMapController;
    if (c == null) return;
    try {
      await c.moveCamera(cameraUpdate!);
      await zoomToFit(c, bound!, centerBounds!);
    } on PlatformException catch (e, st) {
      debugPrint('$tag animateMap: $e\n$st');
    }
  }

  createFireBaseDatabase(TrackOrderPojo data) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _reference = firebaseDatabase
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.deliveries)
        .child(data.orderNo.toString());
    _driverLocationSubscription = _reference?.onValue.listen(
      (event) async {
        if (_disposed) return;
        if (event.snapshot.value != null) {
          Map<String, dynamic> result = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>,
          );
          try {
            final lat = result[ChatConstant.latitude];
            final lng = result[ChatConstant.longitude];
            if (lat == null || lng == null) return;
            driverCurrentLatLong = LatLng(
              double.parse(lat.toString()),
              double.parse(lng.toString()),
            );
          } catch (e, st) {
            logd(tag, 'driver RTDB parse error: $e\n$st');
            return;
          }
          if (markerDriver == null) {
            if (_disposed) return;
            List<Marker> markerList =
                _rotateMarkerListController.valueOrNull ?? [];
            BitmapDescriptor driverMarkerIcon =
                await getBitmapDescriptorFromAssetBytes(
                  'assets/images/ic_delivery_bike.png',
                  (deviceAverageSize * 0.15).toInt(),
                );
            if (_disposed) return;
            markerDriver = Marker(
              markerId: const MarkerId("DriverMarker"),
              position: driverCurrentLatLong!,
              // anchor: Offset(0.5, 0.5),
              icon: driverMarkerIcon,
              infoWindow: InfoWindow(title: data.destinationAddress),
            );
            markerList.add(markerDriver!);
            changeRotateMarker(markerList);
          }
          if (driverPreviousLatLng != null) {
            updateDriverMarker();
          }
          driverPreviousLatLng = driverCurrentLatLong;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        logd(tag, 'driver RTDB listen error: $error\n$stackTrace');
      },
      cancelOnError: false,
    );
  }

  updateDriverMarker() {
    List<Marker> markers = _rotateMarkerListController.valueOrNull ?? [];
    int pos = markers.indexWhere(
      (item) => item.markerId == const MarkerId("DriverMarker"),
    );
    if (pos >= 0) {
      Marker driverMarker = markers[pos];
      Marker driverNewMarker = Marker(
        markerId: driverMarker.markerId,
        position: driverCurrentLatLong!,
        icon: driverMarker.icon,
        infoWindow: driverMarker.infoWindow,
      );
      markers[pos] = driverNewMarker;
      changeRotateMarker(markers);
    }
  }

  finishChatWithStore(TrackOrderPojo? orderDetailsPojo) {
    String storeIdCode =
        ChatConstant.providerIdCode +
        (orderDetailsPojo?.storeId ?? 0).toString();
    String userIdCode =
        ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

    DatabaseReference referenceMessage = firebaseDatabase
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.messages)
        .child("${userIdCode}_$storeIdCode");
    referenceMessage.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        referenceMessage.remove();
      }
    });

    DatabaseReference referenceUser = firebaseDatabase
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.users)
        .child(userIdCode);
    referenceUser
        .orderByChild(ChatConstant.userId)
        .equalTo(storeIdCode)
        .once()
        .then((dataSnapshot) {
          if (dataSnapshot.snapshot.value != null) {
            Map<dynamic, dynamic>? data = dataSnapshot.snapshot.value as Map?;
            data?.forEach((key, value) {
              referenceUser.child(key.toString()).remove();
            });
          }
          return;
        });
  }

  finishChatWithDriver(TrackOrderPojo? orderDetailsPojo) {
    String driverIdCode =
        ChatConstant.providerIdCode +
        (orderDetailsPojo?.driverId ?? 0).toString();
    String userIdCode =
        ChatConstant.userIdCode + prefGetInt(prefUserId).toString();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

    DatabaseReference referenceMessage = firebaseDatabase
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.messages)
        .child("${userIdCode}_$driverIdCode");
    referenceMessage.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        referenceMessage.remove();
      }
      return;
    });

    DatabaseReference referenceUser = firebaseDatabase
        .ref()
        .child(ChatConstant.chat)
        .child(ChatConstant.users)
        .child(userIdCode);
    referenceUser
        .orderByChild(ChatConstant.userId)
        .equalTo(driverIdCode)
        .once()
        .then((dataSnapshot) {
          if (dataSnapshot.snapshot.value != null) {
            Map? data = dataSnapshot.snapshot.value as Map?;
            data?.forEach((key, value) {
              referenceUser.child(key.toString()).remove();
            });
          }
          return;
        });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _otpFollowUpTimer?.cancel();
    _otpFollowUpTimer = null;
    _disposed = true;
    // Do not call googleMapController.dispose() — the GoogleMap widget owns the
    // platform view; disposing here causes pigeon channel-error on async map calls.
    googleMapController = null;
    _subject.close();
    _subjectCancelOrder.close();
    _orderNoController.close();
    _orderDetailsController.close();
    _titleController.close();
    _msgController.close();
    _imgController.close();
    _nameController.close();
    _ratingController.close();
    _titleColorController.close();
    _markersListController.close();
    _rotateMarkerListController.close();
    subjectDriverImage.close();
  }
}
